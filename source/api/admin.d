module api.admin;

import std.array : empty;
import std.datetime : Clock, UTC;

import vibe.web.rest : rootPathFromName, path, method, before;
import vibe.data.json : Json;
import vibe.data.bson : Bson, BsonObjectID;
import vibe.http.server : HTTPMethod, HTTPServerRequest, HTTPServerResponse;
import vibe.core.log : logInfo;

import db : getMongoCollection;
import types : ResponseStatus, AuthInfo, PasswordChangeRequest, AboutRequest, BannerRequest, ColorSchemeRequest, ProjectRequest;
import auth : authenticateRequest, changePassword;

@safe:

/// Convert Json to Bson recursively
private Bson jsonToBson(Json json)
{
    switch (json.type)
    {
        case Json.Type.null_: return Bson(null);
        case Json.Type.bool_: return Bson(json.get!bool);
        case Json.Type.int_: return Bson(json.get!long);
        case Json.Type.float_: return Bson(json.get!double);
        case Json.Type.string: return Bson(json.get!string);
        case Json.Type.array:
            Bson[] arr;
            foreach (elem; json.byValue)
                arr ~= jsonToBson(elem);
            return Bson(arr);
        case Json.Type.object:
            Bson[string] obj;
            foreach (key, val; json.byKeyValue)
                obj[key] = jsonToBson(val);
            return Bson(obj);
        default: return Bson(null);
    }
}

/// Convert Bson to Json recursively
private Json bsonToJson(Bson bson)
{
    switch (bson.type)
    {
        case Bson.Type.null_: return Json(null);
        case Bson.Type.bool_: return Json(bson.get!bool);
        case Bson.Type.int_: return Json(bson.get!int);
        case Bson.Type.long_: return Json(bson.get!long);
        case Bson.Type.double_: return Json(bson.get!double);
        case Bson.Type.string: return Json(bson.get!string);
        case Bson.Type.array:
            Json[] arr;
            foreach (elem; bson.byValue)
                arr ~= bsonToJson(elem);
            return Json(arr);
        case Bson.Type.object:
            auto obj = Json.emptyObject;
            foreach (key, val; bson.byKeyValue)
                obj[key] = bsonToJson(val);
            return obj;
        case Bson.Type.objectID: return Json(bson.toString());
        default: return Json(null);
    }
}

@rootPathFromName
interface AdminAPI
{
    // POST /admin_api/password - Change admin password (auth required)
    @path("/password")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postPassword(PasswordChangeRequest passwordChangeRequest, AuthInfo auth);

    // PUT /admin_api/about - Update about info (auth required)
    @path("/about")
    @method(HTTPMethod.PUT)
    @before!authenticateRequest("auth")
    ResponseStatus putAbout(AboutRequest aboutRequest, AuthInfo auth);

    // GET /admin_api/banners - List all banners (auth required)
    @path("/banners")
    @method(HTTPMethod.GET)
    @before!authenticateRequest("auth")
    Json getBanners(AuthInfo auth);

    // POST /admin_api/banners - Create banner (auth required)
    @path("/banners")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postBanners(BannerRequest bannerRequest, AuthInfo auth);

    // PUT /admin_api/banners/:id - Update banner (auth required)
    @path("/banners/:id")
    @method(HTTPMethod.PUT)
    @before!authenticateRequest("auth")
    ResponseStatus putBanner(string _id, BannerRequest bannerRequest, AuthInfo auth);

    // DELETE /admin_api/banners/:id - Delete banner (auth required)
    @path("/banners/:id")
    @method(HTTPMethod.DELETE)
    @before!authenticateRequest("auth")
    ResponseStatus deleteBanner(string _id, AuthInfo auth);

    // PUT /admin_api/color-scheme - Update color scheme (auth required)
    @path("/color-scheme")
    @method(HTTPMethod.PUT)
    @before!authenticateRequest("auth")
    ResponseStatus putColorScheme(ColorSchemeRequest colorSchemeRequest, AuthInfo auth);

    // GET /admin_api/projects - List all projects (auth required)
    @path("/projects")
    @method(HTTPMethod.GET)
    @before!authenticateRequest("auth")
    Json getProjects(AuthInfo auth);

    // POST /admin_api/projects - Create project (auth required)
    @path("/projects")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postProjects(ProjectRequest projectRequest, AuthInfo auth);

    // PUT /admin_api/projects/:id - Update project (auth required)
    @path("/projects/:id")
    @method(HTTPMethod.PUT)
    @before!authenticateRequest("auth")
    ResponseStatus putProject(string _id, ProjectRequest projectRequest, AuthInfo auth);

    // DELETE /admin_api/projects/:id - Delete project (auth required)
    @path("/projects/:id")
    @method(HTTPMethod.DELETE)
    @before!authenticateRequest("auth")
    ResponseStatus deleteProject(string _id, AuthInfo auth);
}

class AdminImpl : AdminAPI
{
    override ResponseStatus postPassword(PasswordChangeRequest passwordChangeRequest, AuthInfo auth)
    {
        if (passwordChangeRequest.currentPassword.empty || passwordChangeRequest.newPassword.empty)
        {
            return ResponseStatus(false, "Current password and new password are required.");
        }

        if (passwordChangeRequest.newPassword.length < 6)
        {
            return ResponseStatus(false, "New password must be at least 6 characters.");
        }

        auto success = changePassword("admin", passwordChangeRequest.currentPassword, passwordChangeRequest.newPassword);
        if (!success)
        {
            return ResponseStatus(false, "Current password is incorrect.");
        }

        return ResponseStatus(true, "Password changed successfully.");
    }

    override ResponseStatus putAbout(AboutRequest aboutRequest, AuthInfo auth)
    {
        auto col = getMongoCollection("settings");

        // build updates
        Bson[string] value;
        if (!aboutRequest.name.empty) value["name"] = Bson(aboutRequest.name);
        if (aboutRequest.bio.length > 0)
        {
            Bson[] bioArr;
            foreach (b; aboutRequest.bio)
                bioArr ~= Bson(b);
            value["bio"] = Bson(bioArr);
        }
        if (aboutRequest.social.type != Json.Type.undefined &&
            aboutRequest.social.type != Json.Type.null_ &&
            aboutRequest.social != Json.emptyObject)
        {
            value["social"] = jsonToBson(aboutRequest.social);
        }

        // merge with existing
        auto existing = col.findOne(["key": "about"]);
        if (existing.type != Bson.Type.null_)
        {
            auto existingValue = existing["value"];
            // Build $set operations for each field
            Bson[string] setOps;
            foreach (key, val; value)
            {
                setOps["value." ~ key] = val;
            }
            if (setOps.length > 0)
            {
                col.updateOne(
                    ["key": "about"],
                    ["$set": Bson(setOps)]
                );
            }
        }
        else
        {
            col.insertOne([
                "key": Bson("about"),
                "value": Bson(value)
            ]);
        }

        return ResponseStatus(true, "About info updated successfully.");
    }

    override Json getBanners(AuthInfo auth)
    {
        auto col = getMongoCollection("banners");
        Json[] banners;
        foreach (doc; col.find(Bson.emptyObject))
        {
            banners ~= Json([
                "id": Json(doc["_id"].get!BsonObjectID.toString()),
                "message": Json(doc["message"].get!string),
                "type": Json(doc["type"].get!string),
                "startDate": Json(doc["startDate"].get!string),
                "endDate": Json(doc["endDate"].get!string),
                "active": Json(doc["active"].get!bool),
                "createdAt": Json(doc["createdAt"].get!string)
            ]);
        }
        return Json(banners);
    }

    override ResponseStatus postBanners(BannerRequest bannerRequest, AuthInfo auth)
    {
        if (bannerRequest.message.empty)
        {
            return ResponseStatus(false, "Banner message is required.");
        }
        if (bannerRequest.startDate.empty || bannerRequest.endDate.empty)
        {
            return ResponseStatus(false, "Start date and end date are required.");
        }

        auto col = getMongoCollection("banners");
        auto now = Clock.currTime(UTC()).toISOExtString();
        col.insertOne([
            "message": Bson(bannerRequest.message),
            "type": Bson(bannerRequest.type),
            "startDate": Bson(bannerRequest.startDate),
            "endDate": Bson(bannerRequest.endDate),
            "active": Bson(bannerRequest.active),
            "createdAt": Bson(now)
        ]);

        return ResponseStatus(true, "Banner created successfully.");
    }

    override ResponseStatus putBanner(string _id, BannerRequest bannerRequest, AuthInfo auth)
    {
        auto col = getMongoCollection("banners");

        Bson[string] updates;
        if (!bannerRequest.message.empty) updates["message"] = Bson(bannerRequest.message);
        if (!bannerRequest.type.empty) updates["type"] = Bson(bannerRequest.type);
        if (!bannerRequest.startDate.empty) updates["startDate"] = Bson(bannerRequest.startDate);
        if (!bannerRequest.endDate.empty) updates["endDate"] = Bson(bannerRequest.endDate);
        updates["active"] = Bson(bannerRequest.active);

        col.updateOne(
            ["_id": Bson(BsonObjectID.fromString(_id))],
            ["$set": Bson(updates)]
        );

        return ResponseStatus(true, "Banner updated successfully.");
    }

    override ResponseStatus deleteBanner(string _id, AuthInfo auth)
    {
        auto col = getMongoCollection("banners");
        col.deleteOne(["_id": Bson(BsonObjectID.fromString(_id))]);

        return ResponseStatus(true, "Banner deleted successfully.");
    }

    override ResponseStatus putColorScheme(ColorSchemeRequest colorSchemeRequest, AuthInfo auth)
    {
        auto col = getMongoCollection("settings");

        Bson[string] value;
        if (!colorSchemeRequest.preset.empty) value["preset"] = Bson(colorSchemeRequest.preset);
        if (!colorSchemeRequest.primary.empty) value["primary"] = Bson(colorSchemeRequest.primary);
        if (!colorSchemeRequest.secondary.empty) value["secondary"] = Bson(colorSchemeRequest.secondary);

        auto existing = col.findOne(["key": "colorScheme"]);
        if (existing.type != Bson.Type.null_)
        {
            col.updateOne(
                ["key": "colorScheme"],
                ["$set": Bson(["value": Bson(value)])]
            );
        }
        else
        {
            col.insertOne([
                "key": Bson("colorScheme"),
                "value": Bson(value)
            ]);
        }

        return ResponseStatus(true, "Color scheme updated successfully.");
    }

    override Json getProjects(AuthInfo auth)
    {
        auto col = getMongoCollection("projects");
        Json[] projects;
        foreach (doc; col.find(Bson.emptyObject))
        {
            projects ~= Json([
                "id": Json(doc["_id"].get!BsonObjectID.toString()),
                "title": Json(doc["title"].get!string),
                "description": Json(doc["description"].get!string),
                "link": Json(doc["link"].get!string),
                "icon": Json(doc["icon"].get!string),
                "order": Json(doc["order"].get!int)
            ]);
        }
        return Json(projects);
    }

    override ResponseStatus postProjects(ProjectRequest projectRequest, AuthInfo auth)
    {
        if (projectRequest.title.empty)
        {
            return ResponseStatus(false, "Project title is required.");
        }

        auto col = getMongoCollection("projects");
        col.insertOne([
            "title": Bson(projectRequest.title),
            "description": Bson(projectRequest.description),
            "link": Bson(projectRequest.link),
            "icon": Bson(projectRequest.icon),
            "order": Bson(projectRequest.order)
        ]);

        return ResponseStatus(true, "Project created successfully.");
    }

    override ResponseStatus putProject(string _id, ProjectRequest projectRequest, AuthInfo auth)
    {
        auto col = getMongoCollection("projects");

        Bson[string] updates;
        if (!projectRequest.title.empty) updates["title"] = Bson(projectRequest.title);
        if (!projectRequest.description.empty) updates["description"] = Bson(projectRequest.description);
        if (!projectRequest.link.empty) updates["link"] = Bson(projectRequest.link);
        if (!projectRequest.icon.empty) updates["icon"] = Bson(projectRequest.icon);
        updates["order"] = Bson(projectRequest.order);

        col.updateOne(
            ["_id": Bson(BsonObjectID.fromString(_id))],
            ["$set": Bson(updates)]
        );

        return ResponseStatus(true, "Project updated successfully.");
    }

    override ResponseStatus deleteProject(string _id, AuthInfo auth)
    {
        auto col = getMongoCollection("projects");
        col.deleteOne(["_id": Bson(BsonObjectID.fromString(_id))]);

        return ResponseStatus(true, "Project deleted successfully.");
    }
}
