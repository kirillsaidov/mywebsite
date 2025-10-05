module api.blog;

import std.string : strip, startsWith;
import std.datetime : SysTime, Clock;

import vibe.web.rest : rootPathFromName,
    path,
    method,
    before;
import vibe.data.json : Json, serializeToJson;
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
    string title;
    string[] tags;
    string content;
    string description;
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
    @path("/posts/metadata")
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
        return [];
    }

    override BlogPost getPost(string _title)
    {
        return BlogPost();
    }

    override ResponseStatus postPosts(BlogPostRequest blogPost, AuthInfo auth)
    {
        // create blog record
        auto record = BlogPost(
            BlogMetadata(
                blogPost.title,
                blogPost.description,
                blogPost.tags,
                Clock.currTime(),
                Clock.currTime()
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
        
        return ResponseStatus(true, "Blog post successfully created!", record.serializeToJson);
    }

    override ResponseStatus putPost(string _title, BlogPostRequest blogPost, AuthInfo auth)
    {
        return ResponseStatus();
    }

    override ResponseStatus deletePost(string _title, AuthInfo auth)
    {
        return ResponseStatus();
    }
}




