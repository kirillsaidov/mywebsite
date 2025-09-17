module routes.cv;

import vibe.vibe;

void getCV(HTTPServerRequest req, HTTPServerResponse res)
{
    res.render!("cv.dt");
}


