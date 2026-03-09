module auth;

import std.string : strip, startsWith, split, representation;
import std.datetime : SysTime, Clock, UTC, dur;
import std.conv : to;
import std.digest.sha : SHA256;
import std.digest.hmac : HMAC;
import std.array : array;
import std.format : format;
import std.algorithm : map;
import std.range : chain;
import std.ascii : LetterCase;
import std.process : environment;
import std.random : Random, unpredictableSeed, uniform;

import vibe.http.server : HTTPServerRequest, HTTPServerResponse, HTTPStatusException;
import vibe.http.status : HTTPStatus;
import vibe.core.log : logInfo, logWarn;
import vibe.data.json : Json, parseJsonString;
import vibe.data.bson : Bson;

import db : getMongoCollection;
import types : AuthInfo;

@safe:

/// JWT expiry duration
private enum JWT_EXPIRY_HOURS = 24;

/// Get JWT secret from env or generate one
private string jwtSecret;
private string adminUsername;
private string adminPasswordDefault;

shared static this()
{
    jwtSecret = environment.get("JWT_SECRET", null);
    if (jwtSecret is null || jwtSecret.length == 0)
    {
        jwtSecret = generateRandomSecret();
    }
    adminUsername = environment.get("ADMIN_USERNAME", "admin");
    adminPasswordDefault = environment.get("ADMIN_PASSWORD", "changeme");
}

/// Generate a random hex string for JWT secret
private string generateRandomSecret() @trusted
{
    auto rng = Random(unpredictableSeed);
    char[] result;
    result.length = 64;
    foreach (i; 0 .. 64)
    {
        enum chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        result[i] = chars[uniform(0, chars.length, rng)];
    }
    return result.idup;
}

/// Initialize admin account in MongoDB if not present
void initAdmin()
{
    auto col = getMongoCollection("admin");
    auto count = col.countDocuments(Bson.emptyObject);
    if (count == 0)
    {
        logInfo("Seeding admin account: %s", adminUsername);
        auto passwordHash = hashPassword(adminPasswordDefault);
        auto now = Clock.currTime(UTC()).toISOExtString();
        col.insertOne([
            "username": Bson(adminUsername),
            "passwordHash": Bson(passwordHash),
            "createdAt": Bson(now),
            "modifiedAt": Bson(now)
        ]);
    }
}

/// Hash password with salt using SHA-256
string hashPassword(string password) @trusted
{
    auto rng = Random(unpredictableSeed);
    char[] salt;
    salt.length = 32;
    foreach (i; 0 .. 32)
    {
        enum chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        salt[i] = chars[uniform(0, chars.length, rng)];
    }
    return hashPasswordWithSalt(password, salt.idup);
}

/// Hash password with a given salt
string hashPasswordWithSalt(string password, string salt) @trusted
{
    auto input = salt ~ password;
    ubyte[32] hash = sha256Of(cast(const(ubyte)[]) input.representation);
    return salt ~ "$" ~ digestToHex(hash);
}

/// Verify password against stored hash
bool verifyPassword(string password, string storedHash) @trusted
{
    auto parts = storedHash.split("$");
    if (parts.length != 2) return false;
    auto salt = parts[0];
    auto expected = hashPasswordWithSalt(password, salt);
    return expected == storedHash;
}

/// Compute SHA-256 digest
private ubyte[32] sha256Of(const(ubyte)[] data) @trusted
{
    SHA256 hasher;
    hasher.start();
    hasher.put(data);
    return hasher.finish();
}

/// Convert digest bytes to hex string
private string digestToHex(ubyte[32] data) @trusted
{
    char[] result;
    result.length = 64;
    foreach (i, b; data)
    {
        enum hexDigits = "0123456789abcdef";
        result[i * 2] = hexDigits[b >> 4];
        result[i * 2 + 1] = hexDigits[b & 0x0F];
    }
    return result.idup;
}

/// Base64url encode (no padding)
string base64urlEncode(const(ubyte)[] data) @trusted
{
    import std.base64 : Base64;
    auto encoded = Base64.encode(data);
    char[] result;
    result.length = 0;
    result.reserve(encoded.length);
    foreach (c; encoded)
    {
        if (c == '+') result ~= '-';
        else if (c == '/') result ~= '_';
        else if (c == '=') {}
        else result ~= c;
    }
    return result.idup;
}

/// Base64url decode
ubyte[] base64urlDecode(string data) @trusted
{
    import std.base64 : Base64;
    char[] padded;
    padded.reserve(data.length + 4);
    foreach (c; data)
    {
        if (c == '-') padded ~= '+';
        else if (c == '_') padded ~= '/';
        else padded ~= c;
    }
    while (padded.length % 4 != 0)
        padded ~= '=';
    return Base64.decode(padded).dup;
}

/// HMAC-SHA256 sign
ubyte[32] hmacSha256(string data, string secret) @trusted
{
    auto hmac = HMAC!SHA256(cast(const(ubyte)[]) secret.representation);
    hmac.put(cast(const(ubyte)[]) data.representation);
    return hmac.finish();
}

/// Generate JWT token for a username
string generateJWT(string username) @trusted
{
    auto now = Clock.currTime(UTC());
    auto exp = now + dur!"hours"(JWT_EXPIRY_HOURS);

    auto header = `{"alg":"HS256","typ":"JWT"}`;
    auto payload = format!`{"sub":"%s","iat":%d,"exp":%d}`(
        username,
        now.toUnixTime(),
        exp.toUnixTime()
    );

    auto headerB64 = base64urlEncode(cast(const(ubyte)[]) header.representation);
    auto payloadB64 = base64urlEncode(cast(const(ubyte)[]) payload.representation);
    auto sigInput = headerB64 ~ "." ~ payloadB64;
    ubyte[32] signature = hmacSha256(sigInput, jwtSecret);
    auto sigB64 = base64urlEncode(signature);

    return sigInput ~ "." ~ sigB64;
}

/// Validate JWT token and return the username, or null if invalid
string validateJWT(string token) @trusted
{
    auto parts = token.split(".");
    if (parts.length != 3) return null;

    // verify signature
    auto sigInput = parts[0] ~ "." ~ parts[1];
    ubyte[32] expectedSig = hmacSha256(sigInput, jwtSecret);
    auto actualSig = base64urlDecode(parts[2]);
    if (actualSig.length != 32) return null;
    if (expectedSig[] != actualSig[0..32]) return null;

    // decode payload
    try
    {
        auto payloadBytes = base64urlDecode(parts[1]);
        auto payloadStr = cast(string) payloadBytes;
        auto payload = parseJsonString(payloadStr);

        // check expiry
        auto exp = payload["exp"].get!long;
        auto now = Clock.currTime(UTC()).toUnixTime();
        if (now > exp) return null;

        return payload["sub"].get!string;
    }
    catch (Exception)
    {
        return null;
    }
}

/// Validate API key from Authorization header (JWT-based)
AuthInfo authenticateRequest(HTTPServerRequest req, HTTPServerResponse res) @safe
{
    auto authHeader = "Authorization" in req.headers;
    if (!authHeader)
    {
        logWarn("Missing Authorization header.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Missing Authorization header");
    }

    auto authValue = (*authHeader).strip();

    if (!authValue.startsWith("Bearer "))
    {
        logWarn("Invalid Authorization header format.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Invalid Authorization header format. Expected: Bearer <token>");
    }

    auto token = authValue[7..$].strip();
    auto username = () @trusted { return validateJWT(token); }();
    if (username is null)
    {
        logWarn("Invalid or expired JWT token.");
        throw new HTTPStatusException(HTTPStatus.unauthorized, "Invalid or expired token");
    }

    return AuthInfo(true);
}

/// Authenticate login credentials, return JWT on success
string authenticateLogin(string username, string password)
{
    auto col = getMongoCollection("admin");

    auto doc = col.findOne(["username": username]);
    if (doc.type == Bson.Type.null_) return null;

    auto storedHash = doc["passwordHash"].get!string;
    if (!(() @trusted { return verifyPassword(password, storedHash); })())
        return null;

    return () @trusted { return generateJWT(username); }();
}

/// Change admin password
bool changePassword(string username, string currentPassword, string newPassword)
{
    auto col = getMongoCollection("admin");

    auto doc = col.findOne(["username": username]);
    if (doc.type == Bson.Type.null_) return false;

    auto storedHash = doc["passwordHash"].get!string;
    if (!(() @trusted { return verifyPassword(currentPassword, storedHash); })())
        return false;

    auto newHash = () @trusted { return hashPassword(newPassword); }();
    auto now = Clock.currTime(UTC()).toISOExtString();
    col.updateOne(
        ["username": username],
        [
            "$set": Bson([
                "passwordHash": Bson(newHash),
                "modifiedAt": Bson(now)
            ])
        ]
    );
    return true;
}
