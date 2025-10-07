module api.internal;

import std.file : write, exists, mkdirRecurse;
import std.path : dirName;

import vibe.web.rest : rootPathFromName, path, method, before;
import vibe.http.server : HTTPMethod, HTTPServerRequest, HTTPServerResponse;
import vibe.core.log : logInfo, logError;

import api.blog : ResponseStatus, AuthInfo, authenticateRequest;

@safe:

@rootPathFromName
interface InternalAPI
{
    // POST /internal_api/cv - Upload CV PDF
    @path("/cv")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postCv(HTTPServerRequest req, AuthInfo auth);
    
    // POST /internal_api/avatar - Upload avatar image
    @path("/avatar")
    @method(HTTPMethod.POST)
    @before!authenticateRequest("auth")
    ResponseStatus postAvatar(HTTPServerRequest req, AuthInfo auth);
}

class InternalImpl : InternalAPI
{
    override ResponseStatus postCv(HTTPServerRequest req, AuthInfo auth)
    {
        return ResponseStatus();
    }

    override ResponseStatus postAvatar(HTTPServerRequest req, AuthInfo auth)
    {
        return ResponseStatus();
    }
}

