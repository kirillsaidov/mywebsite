module api.blog;

import std.datetime : DateTime;
import vibe.web.rest;

struct BlogMetadata
{
    uint id;
    string name;
    string desc;
    DateTime created_at;
    DateTime modified_at;
}

struct Blog 
{
    BlogMetadata metadata;
    string content;
}

interface BlogAPI
{
    @get @path("/list")
    BlogMetadata[] list();

    @get @path("/get/:id")
    Blog get(in uint id);    
}
