module routes.home;

import std.array : array;
import std.algorithm.iteration : map;

import vibe.vibe;
import config;

struct AboutInfo {
    string name;
    string[] bio;
    string email_user;
    string email_domain;
    string linkedin;
    string github;
}

void getHomePage(HTTPServerRequest req, HTTPServerResponse res)
{
    // init
    AboutInfo about;
    try 
    {
        auto data = getConfig()["about"];
        about = AboutInfo(
            name: data["name"].str,
            bio: data["bio"].array.map!(item => item.str).array,
            email_user: data["social"]["email-user"].str,
            email_domain: data["social"]["email-domain"].str,
            linkedin: data["social"]["linkedin"].str,
            github: data["social"]["github"].str,
        );
    } 
    catch (Exception e) about = AboutInfo();

    res.render!("index.dt", about);
}
