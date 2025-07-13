module app;

import std.stdio;
import vibe.vibe;

// routes
import routes.home;


void main()
{
    // configure server settings
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];

    // configure routing
    auto router = new URLRouter;
    router.get("/", &getHomePage);
    router.get("*", serveStaticFiles("public/"));

    // init listener
    auto listener = listenHTTP(settings, router);
    scope (exit) listener.stopListening();

    // run the application
    runApplication();
}
