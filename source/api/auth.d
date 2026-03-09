module api.auth;

import std.array : empty;

import vibe.web.rest : rootPathFromName, path, method;
import vibe.data.json : Json;
import vibe.http.server : HTTPMethod;

import types : ResponseStatus, LoginRequest;
import auth : authenticateLogin;

@safe:

@rootPathFromName
interface AuthAPI
{
    // POST /auth_api/login - Login and get JWT token
    @path("/login")
    @method(HTTPMethod.POST)
    ResponseStatus postLogin(LoginRequest loginRequest);
}

class AuthImpl : AuthAPI
{
    override ResponseStatus postLogin(LoginRequest loginRequest)
    {
        if (loginRequest.username.empty || loginRequest.password.empty)
        {
            return ResponseStatus(false, "Username and password are required.");
        }

        auto token = authenticateLogin(loginRequest.username, loginRequest.password);
        if (token is null)
        {
            return ResponseStatus(false, "Invalid username or password.");
        }

        return ResponseStatus(true, "Login successful.", Json(["token": Json(token)]));
    }
}
