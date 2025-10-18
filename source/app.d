module app;

import std.stdio;
import vibe.vibe;

import api;
import routes;
import config: getAddress, getPort;

void main()
{
    // configure server settings
    auto settings = new HTTPServerSettings;
    settings.port = getPort();
    settings.bindAddresses = [getAddress()];
    settings.maxRequestSize = 10_000_000; // 10MB
    settings.errorPageHandler = (HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) @safe {
        res.writeJsonBody([
            "success": Json(false),
            "error": Json(error.message),
            "code": Json(error.code)
        ]);
    };
    
    // add routing
    auto router = new URLRouter;
    router.get("/", &routes.getHomePage);
    router.get("/blog", &routes.getBlogPage);
    router.get("/blog/:title", &routes.getBlogPostPage);
    router.get("/cv", &routes.getCVPage);
    router.get("*", serveStaticFiles("public/"));

    // configure REST-specific settings
    auto restSettings = new RestInterfaceSettings;
    restSettings.errorHandler = (HTTPServerRequest req, HTTPServerResponse res, RestErrorInformation error) @safe {
        res.writeJsonBody([
            "success": Json(false),
            "error": Json(error.exception.msg)
        ]);
    };

    // add REST API
    router.registerRestInterface(new api.BlogImpl(), restSettings);
    router.registerRestInterface(new api.InternalImpl(), restSettings);

    // init listener
    auto listener = listenHTTP(settings, router);
    scope (exit) listener.stopListening();

    // run the application
    runApplication();
}
