module routes.home;

import vibe.vibe;

void getHomePage(HTTPServerRequest req, HTTPServerResponse res)
{
    res.render!("index.dt");
}



