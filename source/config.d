module config;

import std.file : readText;
import std.json : JSONValue, parseJSON;

/// Website-wide config
private JSONValue config;

static this() 
{
    // load config
    auto configText = readText("config/config.json");
    config = parseJSON(configText);
}

JSONValue getConfig()
{
    return config;
}

