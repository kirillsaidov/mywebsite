module routes.home;

import std.array : array;
import std.algorithm.iteration : map;

import vibe.vibe;
import config;

void getHomePage(HTTPServerRequest req, HTTPServerResponse res)
{
    struct AboutInfo {
        string name;
        string[] bio;
        string email_user;
        string email_domain;
        string linkedin;
        string github_ks, github_rk;
    }
    
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
            github_ks: data["social"]["github_ks"].str,
            github_rk: data["social"]["github_rk"].str,
        );
    } 
    catch (Exception e) about = AboutInfo();

    res.render!("index.dt", about);
}
