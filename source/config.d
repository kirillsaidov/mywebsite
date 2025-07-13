module config;

import std.file : readText;
import std.json : JSONValue, parseJSON;

JSONValue _config;
static this() 
{
    // load config
    auto configText = readText("config/config.json");
    _config = parseJSON(configText);
}

JSONValue getConfig()
{
    return _config;
}