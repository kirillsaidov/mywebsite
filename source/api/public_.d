module api.public_;

import vibe.web.rest : rootPathFromName, path, method;
import vibe.data.json: Json, serializeToJson;
import vibe.http.server : HTTPMethod;

import config : getConfig;
//import api.blog : ResponseStatus;

@safe:

@rootPathFromName
interface PublicAPI
{
    // POST /public_api/about - Return "About" information containing name, about, social media, email
    @path("/about")
    @method(HTTPMethod.GET)
    Json getAbout();
}

class PublicImpl : PublicAPI
{
    override Json getAbout()
    {
        return getConfig()["about"].serializeToJson;
    }
}



