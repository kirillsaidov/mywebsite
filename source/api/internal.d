module api.internal;

import std.file : write, read, exists, mkdirRecurse;
import std.path : dirName, extension;
import std.string : toLower;

import vibe.web.rest : rootPathFromName, path, method, before;
import vibe.http.server : HTTPMethod, HTTPServerRequest, HTTPServerResponse;
import vibe.core.log : logInfo, logError;
import vibe.core.core : Task;

import api.blog : ResponseStatus, AuthInfo, authenticateRequest;

@safe:

/// File upload context passed from @before handler
struct FileUploadContext
{
    bool authenticated;
    HTTPServerRequest request;
}

/// Authenticate and pass request context
FileUploadContext authenticateFileUpload(HTTPServerRequest req, HTTPServerResponse res) @safe
{
    // reuse authentication logic
    auto authInfo = authenticateRequest(req, res);
    
    // return context with both auth status and request
    return FileUploadContext(authInfo.authenticated, req);
}

@rootPathFromName
interface InternalAPI
{
    // POST /internal_api/cv - Upload CV PDF
    @path("/cv")
    @method(HTTPMethod.POST)
    @before!authenticateFileUpload("ctx")
    ResponseStatus postCv(FileUploadContext ctx);
    
    // POST /internal_api/avatar - Upload avatar image
    @path("/avatar")
    @method(HTTPMethod.POST)
    @before!authenticateFileUpload("ctx")
    ResponseStatus postAvatar(FileUploadContext ctx);
}

class InternalImpl : InternalAPI
{
    override ResponseStatus postCv(FileUploadContext ctx)
    {
        // get the current HTTP request from task-local storage
        auto req = ctx.request;
        
        // get the uploaded file
        auto file = "file" in req.files;
        if (!file)
        {
            return ResponseStatus(false, "No file provided. Use 'file' as the field name.");
        }
            
        // validate file type
        auto ext = file.filename.name.extension.toLower;
        if (ext != ".pdf")
        {
            return ResponseStatus(false, "Invalid file type. Only PDF files are allowed.");
        }

        // ensure public directory exists
        immutable targetPath = "public/cv.pdf";
        auto dir = dirName(targetPath);
        if (!exists(dir))
        {
            mkdirRecurse(dir);
        }
            
        // read and save file
        auto fileData = () @trusted { return cast(ubyte[])read(file.tempPath.toString()); }();
        write(targetPath, fileData);

        return ResponseStatus(true, "CV updated!");
    }

    override ResponseStatus postAvatar(FileUploadContext ctx)
    {
        // get the current HTTP request from task-local storage
        auto req = ctx.request;
            
        // get the uploaded file
        auto file = "file" in req.files;
        if (!file)
        {
            return ResponseStatus(false, "No file provided. Use 'file' as the field name.");
        }
            
        // validate file type (accept common image formats)
        auto ext = file.filename.name.extension.toLower;
        if (ext != ".jpg" && ext != ".jpeg" && ext != ".png")
        {
            return ResponseStatus(false, "Invalid file type. Only JPEG and PNG images are allowed.");
        }
            
        // determine extension based on file extension
        string extension = ext == ".png" ? ".png" : ".jpg";
            
        // save as avatar with appropriate extension
        immutable targetPath = "public/avatar" ~ extension;
        auto dir = dirName(targetPath);
        if (!exists(dir))
        {
            mkdirRecurse(dir);
        }
            
        // read and save file
        auto fileData = () @trusted { return cast(ubyte[])read(file.tempPath.toString()); }();
        write(targetPath, fileData);
            
        return ResponseStatus(true, "Avatar updated!");
    }
}


