module types;

import vibe.data.json : Json;
import vibe.data.serialization : optional;

@safe:

/// Response for operations status
struct ResponseStatus
{
    bool success;
    string message;
    Json data = Json.emptyObject;
}

/// Authentication information passed from @before handler
struct AuthInfo
{
    bool authenticated;
}

/// Request body for creating/updating blog posts
struct BlogPostRequest
{
    @optional string title = "";
    @optional string[] tags = [];
    @optional string content = "";
    @optional string description = "";
}

/// Request body for login
struct LoginRequest
{
    @optional string username = "";
    @optional string password = "";
}

/// Request body for password change
struct PasswordChangeRequest
{
    @optional string currentPassword = "";
    @optional string newPassword = "";
}

/// Request body for about info update
struct AboutRequest
{
    @optional string name = "";
    @optional string[] bio = [];
    @optional Json social = Json.emptyObject;
}

/// Banner request body
struct BannerRequest
{
    @optional string message = "";
    @optional string type = "info"; // "info", "warning", "danger"
    @optional string startDate = "";
    @optional string endDate = "";
    @optional bool active = true;
}

/// Banner stored in DB
struct Banner
{
    string id;
    string message;
    string type;
    string startDate;
    string endDate;
    bool active;
    string createdAt;
}

/// Request body for color scheme update
struct ColorSchemeRequest
{
    @optional string preset = "";
    @optional string primary = "";
    @optional string secondary = "";
}

/// Request body for creating/updating projects
struct ProjectRequest
{
    @optional string title = "";
    @optional string description = "";
    @optional string link = "";
    @optional string icon = "";
    @optional int order = 0;
}
