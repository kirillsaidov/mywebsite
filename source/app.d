module app;

import std.stdio;
import std.file : exists, read;
import vibe.vibe;

import api;
import config : getAddress, getPort;
import auth : initAdmin;
import api.public_ : seedAboutInfo;
import cors : addCORSHeaders, handleCORSPreflight;

void main()
{
    // initialize admin account and seed data
    initAdmin();
    seedAboutInfo();

    // configure server settings
    auto settings = new HTTPServerSettings;
    settings.port = getPort();
    settings.bindAddresses = [getAddress()];
    settings.maxRequestSize = 10_000_000; // 10MB
    settings.errorPageHandler = (HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) @safe {
        addCORSHeaders(res);
        res.writeJsonBody([
            "success": Json(false),
            "error": Json(error.message),
            "code": Json(error.code)
        ]);
    };

    // add routing
    auto router = new URLRouter;

    // CORS preflight handler
    router.match(HTTPMethod.OPTIONS, "*", &handleCORSPreflight);

    // add CORS headers to all responses
    router.any("*", delegate void(HTTPServerRequest req, HTTPServerResponse res) @safe {
        addCORSHeaders(res);
    });

    // static file serving for uploads (avatar, cv, favicon)
    router.get("*", serveStaticFiles("public/"));

    // configure REST-specific settings
    auto restSettings = new RestInterfaceSettings;
    restSettings.errorHandler = (HTTPServerRequest req, HTTPServerResponse res, RestErrorInformation error) @safe {
        addCORSHeaders(res);
        res.writeJsonBody([
            "success": Json(false),
            "error": Json(error.exception.msg)
        ]);
    };

    // add REST API
    router.registerRestInterface(new api.BlogImpl(), restSettings);
    router.registerRestInterface(new api.PublicImpl(), restSettings);
    router.registerRestInterface(new api.InternalImpl(), restSettings);
    router.registerRestInterface(new api.AuthImpl(), restSettings);
    router.registerRestInterface(new api.AdminImpl(), restSettings);

    // serve Vue.js dist/ static assets
    router.get("*", serveStaticFiles("dist/"));

    // SPA fallback: serve index.html for any unmatched GET
    router.get("*", delegate void(HTTPServerRequest req, HTTPServerResponse res) @safe {
        try
        {
            auto indexPath = "dist/index.html";
            if (exists(indexPath))
            {
                auto content = () @trusted { return cast(string) read(indexPath); }();
                res.writeBody(content, "text/html; charset=utf-8");
            }
            else
            {
                res.writeJsonBody([
                    "success": Json(false),
                    "error": Json("Frontend not built. Run 'npm run build' in mywebsite-frontend/.")
                ]);
            }
        }
        catch (Exception e)
        {
            res.writeJsonBody([
                "success": Json(false),
                "error": Json("Internal server error")
            ]);
        }
    });

    // init listener
    auto listener = listenHTTP(settings, router);
    scope (exit) listener.stopListening();

    // run the application
    runApplication();
}
