module api.internal;

import std.file : write, read, exists, mkdirRecurse;
import std.path : dirName, extension;
import std.string : toLower;
import std.format : format;
import std.algorithm : among;

import vibe.web.rest : rootPathFromName, path, method, before;
import vibe.http.server : HTTPMethod, HTTPServerRequest, HTTPServerResponse;
import vibe.core.log : logInfo, logError;
import vibe.core.core : Task;

import config : UploadSizeLimit, buildPublicPath;
import api.blog : ResponseStatus, AuthInfo, authenticateRequest;
import tools.image : imageConvertResize, ImageFormat, ImageSize;
import tools.security : validateGetFile;

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

        // validate file contents
        auto fileData = validateGetFile(ext, file.tempPath.toString());
        if (!fileData)
        {
            return ResponseStatus(false, "Invalid file. File is not a valid PDF.");
        }

        // validate file size
        if (fileData.length > UploadSizeLimit.pdf)
        {
            return ResponseStatus(false,
                "File too large. Maximum size is %sMB.".format(UploadSizeLimit.pdf / 1_000_000));
        }
            
        // save to disk
        immutable targetPath = buildPublicPath("cv.pdf");
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
        if (!ext.among(".png", ".jpg", ".jpeg"))
        {
            return ResponseStatus(false, "Invalid file type. Only JPEG and PNG images are allowed.");
        }

        // validate file contents
        auto fileData = validateGetFile(ext, file.tempPath.toString());
        if (!fileData)
        {
            return ResponseStatus(false, "Invalid file. File is not a valid JPEG or PNG image.");
        }
            
        // validate file size
        if (fileData.length > UploadSizeLimit.image)
        {
            return ResponseStatus(false,
                "File too large. Maximum size is %sMB.".format(UploadSizeLimit.image / 1_000_000));
        }

        // convert to PNG (default format) and save
        immutable targetPath = buildPublicPath("avatar.png");
        auto imageData = () @trusted {
            return imageConvertResize(
                fileData, ImageSize(512), ImageFormat.PNG);
        }();
        write(targetPath, imageData);
        
        return ResponseStatus(true, "Avatar updated!");
    }
}



