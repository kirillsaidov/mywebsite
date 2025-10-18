module tools.security;

import std.file : read;

ubyte[] validateGetFile(in string extension, in string path) @trusted
{
    switch (extension)
    {
        case ".pdf":
            return validateGetPDF(path);
        case ".png":
        case ".jpg":
        case ".jpeg":
            return validateGetImage(path);
        case ".ico":
            return validateGetFavicon(path);
        default: return null;
    }
}

private:

ubyte[] validateGetPDF(in string path)
{
    /// validate PDF file by checking magic bytes
    bool isPDF(const ubyte[] data)
    {
        // PDF files start with "%PDF" (0x25 0x50 0x44 0x46)
        if (data.length < 4) return false;
        return data[0] == 0x25 && data[1] == 0x50 &&
               data[2] == 0x44 && data[3] == 0x46;
    }

    // read file
    auto fileData = cast(ubyte[])read(path);
    return isPDF(fileData) ? fileData : null;
}

ubyte[] validateGetImage(in string path)
{
    /// validate image file by checking magic bytes
    bool isImage(const ubyte[] data)
    {
        if (data.length < 4) return false;
        
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (data.length >= 8 &&
            data[0] == 0x89 && data[1] == 0x50 && 
            data[2] == 0x4E && data[3] == 0x47 &&
            data[4] == 0x0D && data[5] == 0x0A && 
            data[6] == 0x1A && data[7] == 0x0A)
        {
            return true;
        }
        
        // JPEG: FF D8 FF
        if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF)
        {
            return true;
        }
        
        return false;
    }

    // read file
    auto fileData = cast(ubyte[])read(path);
    return isImage(fileData) ? fileData : null;
}

ubyte[] validateGetFavicon(in string path)
{
    /// validate ICO file by checking magic bytes
    bool isICO(const ubyte[] data)
    {
        // ICO files start with: 00 00 01 00
        if (data.length < 4) return false;
        return data[0] == 0x00 && data[1] == 0x00 &&
               data[2] == 0x01 && data[3] == 0x00;
    }

    // read file
    auto fileData = cast(ubyte[])read(path);
    return isICO(fileData) ? fileData : null;
}



