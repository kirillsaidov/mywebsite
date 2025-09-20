module routes.cv;

import vibe.vibe;

void getCVPage(HTTPServerRequest req, HTTPServerResponse res)
{
    res.render!("cv.dt");
}


