module app;

import std.stdio;
import vibe.vibe;

// routes
import api;
import routes;


void main()
{
    // configure server settings
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];

    // configure routing
    auto router = new URLRouter;
    router.get("/", &routes.getHomePage);
    router.get("/blog", &routes.getBlogPage);
    router.get("/cv", &routes.getCVPage);
    router.get("*", serveStaticFiles("public/"));
    router.registerRestInterface(new api.BlogImpl());

    // init listener
    auto listener = listenHTTP(settings, router);
    scope (exit) listener.stopListening();

    // run the application
    runApplication();
}
