module api.blog;

import std.datetime : DateTime, Clock;

import vibe.http.server : HTTPMethod;
import vibe.web.rest : rootPathFromName, 
                       path, 
                       method;

import db;

@safe:

struct BlogMetadata
{
    string name;
    string desc;
    // DateTime created_at;
    // DateTime modified_at;

    // this(in string name, in string desc) 
    // {
    //     this.name = name;
    //     this.desc = desc;
    //     this.created_at = cast(DateTime)Clock.currTime();
    //     this.modified_at = cast(DateTime)Clock.currTime();
    // }

    // this(in string name, in string desc, in DateTime created_at, in DateTime modified_at) 
    // {
    //     this.name = name;
    //     this.desc = desc;
    //     this.created_at = created_at;
    //     this.modified_at = modified_at;
    // }
}

struct Blog 
{
    BlogMetadata metadata;
    string content;
}

@rootPathFromName
interface BlogAPI
{
    BlogMetadata[] getListBlogMetadata();

    // @path("blogMeta") @method(HTTPMethod.GET)
    // string apiTest2();

    // @path("list") @method(HTTPMethod.GET)
    // Blog[] list();
}

class BlogImpl : BlogAPI
{
    import std.conv : to;
    import std.array : array;

    import vibe.db.mongo.mongo;

    override BlogMetadata[] getListBlogMetadata()
    {
        auto d = BlogMetadata("", "");
        auto col = db.getCollection("blog");
        auto list = col.find!BlogMetadata().array;
        return list;
    }

    // override string apiTest2() 
    // {
    //     return "test2";
    // }

    // override Blog[] list() 
    // {
    //     return [Blog(BlogMetadata(1)), Blog(BlogMetadata(2))];
    // }
}
