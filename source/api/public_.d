module api.public_;

import std.datetime : Clock, UTC;

import vibe.web.rest : rootPathFromName, path, method;
import vibe.data.json : Json, parseJsonString;
import vibe.data.bson : Bson, BsonObjectID;
import vibe.http.server : HTTPMethod;
import vibe.core.log : logInfo;

import vibe.data.bson : Bson, BsonObjectID;

import db : getMongoCollection;
import config : getConfig;

@safe:

/// Seed about info from config.json to MongoDB if settings collection is empty
void seedAboutInfo()
{
    auto col = getMongoCollection("settings");
    auto count = col.countDocuments(["key": "about"]);
    if (count == 0)
    {
        logInfo("Seeding about info from config.json to MongoDB.");
        auto configData = getConfig();
        import std.json : JSONType;
        if (configData.type != JSONType.null_)
        {
            import std.json : parseJSON;
            import std.file : readText;
            // Read the about section from config and insert as Bson
            auto aboutJson = configData["about"];
            // Convert std.json to string and then to Bson via Json
            auto aboutStr = aboutJson.toString();
            auto vibeJson = parseJsonString(aboutStr);
            col.insertOne([
                "key": Bson("about"),
                "value": Bson.fromJson(vibeJson)
            ]);
        }
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
interface PublicAPI
{
    // GET /public_api/about - Return "About" information from MongoDB
    @path("/about")
    @method(HTTPMethod.GET)
    Json getAbout();

    // GET /public_api/banners - Return active banners
    @path("/banners")
    @method(HTTPMethod.GET)
    Json getBanners();

    // GET /public_api/color-scheme - Return color scheme settings
    @path("/color-scheme")
    @method(HTTPMethod.GET)
    Json getColorScheme();

    // GET /public_api/projects - Return all projects sorted by order
    @path("/projects")
    @method(HTTPMethod.GET)
    Json getProjects();
}

class PublicImpl : PublicAPI
{
    override Json getAbout()
    {
        auto col = getMongoCollection("settings");
        auto doc = col.findOne(["key": "about"]);
        if (doc.type == Bson.Type.null_)
        {
            return Json.emptyObject;
        }
        return bsonToJson(doc["value"]);
    }

    override Json getColorScheme()
    {
        auto col = getMongoCollection("settings");
        auto doc = col.findOne(["key": "colorScheme"]);
        if (doc.type == Bson.Type.null_)
        {
            return Json.emptyObject;
        }
        return bsonToJson(doc["value"]);
    }

    override Json getBanners()
    {
        auto col = getMongoCollection("banners");
        auto allBanners = col.find(["active": Bson(true)]);

        auto now = Clock.currTime(UTC()).toISOExtString();
        Json[] activeBanners;
        foreach (banner; allBanners)
        {
            auto startDate = banner["startDate"].get!string;
            auto endDate = banner["endDate"].get!string;
            if (now >= startDate && now <= endDate)
            {
                activeBanners ~= Json([
                    "id": Json(banner["_id"].get!BsonObjectID.toString()),
                    "message": Json(banner["message"].get!string),
                    "type": Json(banner["type"].get!string),
                    "startDate": Json(startDate),
                    "endDate": Json(endDate),
                    "active": Json(banner["active"].get!bool)
                ]);
            }
        }
        return Json(activeBanners);
    }

    override Json getProjects()
    {
        import std.algorithm : sort;

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
        projects.sort!((a, b) => a["order"].get!int < b["order"].get!int);
        return Json(projects);
    }
}
