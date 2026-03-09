module cors;

import vibe.http.server : HTTPServerRequest, HTTPServerResponse;

@safe:

/// Add CORS headers to a response
void addCORSHeaders(HTTPServerResponse res)
{
    res.headers["Access-Control-Allow-Origin"] = "*";
    res.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS";
    res.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization";
    res.headers["Access-Control-Max-Age"] = "86400";
}

/// Handle OPTIONS preflight request
void handleCORSPreflight(HTTPServerRequest req, HTTPServerResponse res)
{
    addCORSHeaders(res);
    res.writeBody("");
}
