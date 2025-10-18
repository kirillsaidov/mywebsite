module config;

import std.conv : to;
import std.file : readText, exists, mkdirRecurse;
import std.path : buildPath;
import std.json : JSONValue, parseJSON;
import std.process : environment;

/// Get address and port
private ushort port;
private string address;

/// Website-wide config
private JSONValue config;

/// API key for website operations that require authentication
private string apiKey;

/// Public directory where files are publicly accessable
private enum publicDir = "public";

static this() 
{
    // load config
    auto configText = readText("config/config.json");
    config = parseJSON(configText);

    // get api key
    port = environment.get("BIND_PORT", "8081").to!ushort;
    address = environment.get("BIND_ADDRESS", "0.0.0.0");

    // get api key
    apiKey = environment.get("API_KEY", null);

    // ensure public/ directory exists
    if (!exists(publicDir))
    {
        mkdirRecurse(publicDir);
    }
}

@safe:

/// File upload size limits
enum UploadSizeLimit : int
{
    image = 5_000_000,
    pdf = 5_000_000,
    favicon = 1_000_000,
}

/// Get config JSON
JSONValue getConfig()
{
    return config;
}

/// Get port
ushort getPort()
{
    return port;
}

/// Get address
string getAddress()
{
    return address;
}

/// Get API key
string getAPIKey()
{
    return apiKey;
}

/// Build path with public directory
string buildPublicPath(in string path)
{
    return publicDir.buildPath(path);
}



