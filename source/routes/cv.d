module routes.cv;

import vibe.vibe;
import config;

void getCVPage(HTTPServerRequest req, HTTPServerResponse res)
{
    auto social = getConfig()["about"]["social"];
    immutable email_user = social["email-user"].str;
    immutable email_domain = social["email-domain"].str;
    res.render!("cv.dt", email_user, email_domain);
}


