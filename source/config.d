module config;

import std.file : readText;
import std.json : JSONValue, parseJSON;
import std.process : environment;

/// Website-wide config
private JSONValue config;

/// API key for website operations that require authentication
private string apiKey;

static this() 
{
    // load config
    auto configText = readText("config/config.json");
    config = parseJSON(configText);

    // get api key
    apiKey = environment.get("API_KEY", null);
}

@safe:

JSONValue getConfig()
{
    return config;
}

string getAPIKey()
{
    return apiKey;
}


