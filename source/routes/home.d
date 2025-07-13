module routes.home;

import std.json;
import std.file;
import vibe.vibe;

struct AboutInfo {
    string name;
    string bio;
    string email_user;
    string email_domain;
    string linkedin;
    string github;
}

void getHomePage(HTTPServerRequest req, HTTPServerResponse res)
{
    // load config
    auto configText = readText("config/config.json");
    auto config = parseJSON(configText);

    // init
    AboutInfo about;
    try 
    {
        about = AboutInfo(
            name: config["about"]["name"].str,
            bio: config["about"]["bio"].str,
            email_user: config["about"]["social"]["email-user"].str,
            email_domain: config["about"]["social"]["email-domain"].str,
            linkedin: config["about"]["social"]["linkedin"].str,
            github: config["about"]["social"]["github"].str,
        );
    } 
    catch (Exception e) about = AboutInfo();

    res.render!("index.dt", about);
}
