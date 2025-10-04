module api.blog;

import std.datetime : DateTime;

import vibe.http.server : HTTPMethod;
import vibe.web.rest : rootPathFromName, 
                       path, 
                       method;

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

@safe:

@rootPathFromName
interface BlogAPI
{
    string getApiTest1();

    @path("test2") @method(HTTPMethod.GET)
    string apiTest2();

    @path("list") @method(HTTPMethod.GET)
    Blog[] list();
}

class BlogImpl : BlogAPI
{
    override string getApiTest1()
    {
        return "test1";
    }

    override string apiTest2() 
    {
        return "test2";
    }

    override Blog[] list() 
    {
        return [Blog(BlogMetadata(1)), Blog(BlogMetadata(2))];
    }
}
