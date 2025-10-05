module api.blog;

import std.array : array, empty;
import std.string : strip, startsWith;
import std.datetime : SysTime, Clock, UTC;
import std.algorithm : map;

import vibe.web.rest : rootPathFromName,
    path,
    method,
    before;
import vibe.data.json : Json, serializeToJson;
import vibe.data.serialization : optional;
import vibe.http.server : HTTPMethod,
    HTTPServerRequest,
    HTTPServerResponse,
    HTTPStatusException;
import vibe.http.status : HTTPStatus;
import vibe.core.log : logInfo, logError, logWarn;

import db : getMongoCollection;
import config : getAPIKey;

@safe:

/// Blog post metadata structure
struct BlogMetadata
{
    string title;
    string[] tags;
    string description;
    SysTime createdAt;
    SysTime modifiedAt;

    this(in string title, in string description, string[] tags, in SysTime createdAt, in SysTime modifiedAt)
    {
        this.title = title;
        this.description = description;
        this.tags = tags;
        this.createdAt = createdAt;
        this.modifiedAt = modifiedAt;
    }
}

/// Complete blog post structure
struct BlogPost
{
    BlogMetadata metadata;
    string content; // markdown
}

// -------------------------------//
//     IMPLEMENTATION DETAILS     //
// -------------------------------//

/// Response for operations status
struct ResponseStatus
{
    bool success;
    string message;
    Json data;
}

/// Request body for creating/updating blog posts
struct BlogPostRequest
{
    @optional string title = "";
    @optional string[] tags = [];
    @optional string content = "";
    @optional string description = "";
}

/// Authentication information passed from @before handler
struct AuthInfo
{
    bool authenticated;
}

/// Validate API key from Authorization header
AuthInfo authenticateRequest(HTTPServerRequest req, HTTPServerResponse res) @safe
{
    auto authHeader = "Authorization" in req.headers;
    if (!authHeader)
    {
        logWarn("Missing Authorization header.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Missing Authorization header");
    }
    
    // Expected format: "Bearer your-api-key"
    auto authValue = (*authHeader).strip();
    
    if (!authValue.startsWith("Bearer "))
    {
        logWarn("Invalid Authorization header format.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Invalid Authorization header format. Expected: Bearer <api-key>");
    }
    
    auto providedKey = authValue[7..$].strip(); // Remove "Bearer " prefix
    if (providedKey != getAPIKey())
    {
        logWarn("Unauthorized API access attempt with invalid key.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Invalid API key");
    }

    return AuthInfo(true);
}

@rootPathFromName
interface BlogAPI
{
    // GET /blog_api/posts/metadata - Get all blog metadata
    @path("/posts")
    @method(HTTPMethod.GET)
    BlogMetadata[] getMetadata();

    // GET /blog_api/posts/:title - Get specific blog post by title
    @path("/posts/:title")
    @method(HTTPMethod.GET)
    BlogPost getPost(string _title);
    
    // POST /blog_api/posts - Create new blog post (requires Authorization header)
    @path("/posts")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postPosts(BlogPostRequest blogPost, AuthInfo auth);
    
    // PUT /blog_api/posts/:title - Update blog post (requires Authorization header)
    @path("/posts/:title")
    @method(HTTPMethod.PUT)
    @before!authenticateRequest("auth")
    ResponseStatus putPost(string _title, BlogPostRequest blogPost, AuthInfo auth);
    
    // DELETE /blog_api/posts/:title - Delete blog post (requires Authorization header)
    @path("/posts/:title")
    @method(HTTPMethod.DELETE)
    @before!authenticateRequest("auth")
    ResponseStatus deletePost(string _title, AuthInfo auth);    
}

class BlogImpl : BlogAPI
{
    override BlogMetadata[] getMetadata()
    {
        // get mongo collection and find all blog metadata
        auto col = getMongoCollection("blog");
        auto posts = col.find!BlogPost().array;
        if (!posts.length) return [];

        // convert to metadata
        auto metadata = posts.map!(post => post.metadata).array;

        return metadata;
    }

    override BlogPost getPost(string _title)
    {
        // get mongo collection
        auto col = getMongoCollection("blog");

        // find blog post
        auto blogPost = col.findOne!BlogPost(["metadata.title": _title]);
        if (blogPost.isNull)
        {
            throw new HTTPStatusException(HTTPStatus.notFound, "Blog post not found: " ~ _title);
        }
        
        return blogPost.get;
    }

    override ResponseStatus postPosts(BlogPostRequest blogPost, AuthInfo auth)
    {
        // validate all required fields are provided
        if (blogPost.title.empty || blogPost.description.empty || 
            blogPost.tags.empty || blogPost.content.empty)
        {
            return ResponseStatus(false, "All fields (title, description, tags, content) are required when creating a post!");
        }
        
        // create blog record
        auto record = BlogPost(
            BlogMetadata(
                blogPost.title,
                blogPost.description,
                blogPost.tags,
                Clock.currTime(UTC()),
                Clock.currTime(UTC())
            ),
            blogPost.content
        );

        // get mongo collection
        auto col = getMongoCollection("blog");

        // check if it already exists
        auto count = col.countDocuments(["metadata.title": record.metadata.title]);
        if (count)
        {
            return ResponseStatus(false, "Blog post already exists!");
        }

        // save blog post to database
        col.insertOne!BlogPost(record);
        
        return ResponseStatus(true, "Blog post created successfully!", record.serializeToJson);
    }

    override ResponseStatus putPost(string _title, BlogPostRequest blogPost, AuthInfo auth)
    {
        // get mongo collection
        auto col = getMongoCollection("blog");

        // check if it already exists
        auto record = col.findOne!BlogPost(["metadata.title": _title]);
        if (record.isNull)
        {
            return ResponseStatus(false, "Blog post not found: " ~ _title);
        }

        // create blog record
        auto newRecord = BlogPost(
            BlogMetadata(
                blogPost.title.empty ? record.get.metadata.title : blogPost.title,
                blogPost.description.empty ? record.get.metadata.description : blogPost.description,
                blogPost.tags.empty ? record.get.metadata.tags : blogPost.tags,
                record.get.metadata.createdAt,
                Clock.currTime(UTC())
            ),
            blogPost.content.empty ? record.get.content : blogPost.content,
        );

        // update database
        col.replaceOne(["metadata.title": _title], newRecord);
        
        return ResponseStatus(true, "Blog post updated successfully!", newRecord.serializeToJson);
    }

    override ResponseStatus deletePost(string _title, AuthInfo auth)
    {
        // get mongo collection
        auto col = getMongoCollection("blog");

        // find blog post
        auto count = col.countDocuments(["metadata.title": _title]);
        if (!count)
        {
            throw new HTTPStatusException(HTTPStatus.notFound, "Blog post not found: " ~ _title);
        }

        // delete blog post
        col.deleteOne(["metadata.title": _title]);
        
        return ResponseStatus(true, "Blog post deleted successfully!");
    }
}




