module tools.image;

import std.conv : to;
import std.math : isNaN;
import gamut : Image, PixelType, LOAD_RGB, LOAD_ALPHA, LOAD_8BIT, LOAD_NO_PREMUL;
import stb_image_resize2;

public import gamut : ImageFormat;

/// Image dimentions
struct ImageSize
{
    int width;
    int height;
    float scale;
}

/// Convert and resize image
bool imageConvertResizeSave(
    in string inPath,
    in string outPath,
    in ImageSize imageSize,
    in ImageFormat format = ImageFormat.PNG,
    in bool removeAlpha = false)
{
    // load image
    Image img;
    img.loadFromFile(inPath, LOAD_RGB | LOAD_ALPHA | LOAD_8BIT | LOAD_NO_PREMUL);
    if (img.isError)
    {
        return false;
    }

    // calculate target width and height
    int targetWidth, targetHeight;
    if (!imageSize.scale.isNaN)
    {
        targetWidth = (imageSize.scale * img.width).to!int;
        targetHeight = (imageSize.scale * img.height).to!int;
    }
    else if (imageSize.width && imageSize.height)
    {
        targetWidth = imageSize.width;
        targetHeight = imageSize.height;
    }
    else
    {
        targetWidth = img.width;
        targetHeight = img.height;
    }
    
    // create output image
    Image outimg;
    outimg.create(targetWidth, targetHeight, PixelType.rgba8);
    
    // resize using stb_image_resize2
    void* res = stbir_resize(
        img.scanptr(0), img.width, img.height, img.pitchInBytes,
        outimg.scanptr(0), outimg.width, outimg.height, outimg.pitchInBytes,
        STBIR_RGBA,
        STBIR_TYPE_UINT8_SRGB,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_DEFAULT
    );

    // check if successful
    if (res is null)
    {
        return false;
    }

    // alpha channel settings
    // handle format-specific conversions
    final switch (format)
    {
        // these formats don't support alpha - convert to RGB
        case ImageFormat.JPEG:
        case ImageFormat.SQZ:
            outimg.convertTo(PixelType.rgb8);
            break;
    
        // these support alpha - keep rgba8 (unless disabled)
        case ImageFormat.PNG:
        case ImageFormat.TGA:
        case ImageFormat.GIF:
        case ImageFormat.QOI:
        case ImageFormat.QOIX:
        case ImageFormat.DDS:
        case ImageFormat.BMP:
            if (removeAlpha)
            {
                outimg.convertTo(PixelType.rgb8);
            }
            break;

        // JPEG XL in Gamut has no alpha support
        case ImageFormat.JXL:
            outimg.convertTo(PixelType.rgb8);
            break;

        case ImageFormat.unknown:
            break;
    }
    
    // save image
    immutable success = outimg.saveToFile(format, outPath);
    if (!success)
    {
        return false;
    }
    
    return true;
}

/// Convert and resize image from memory, return as ubyte array
ubyte[] imageConvertResize(
    const ubyte[] inputData,
    in ImageSize imageSize,
    in ImageFormat format = ImageFormat.PNG,
    in bool removeAlpha = false)
{
    // load image from memory
    Image img;
    img.loadFromMemory(inputData, LOAD_RGB | LOAD_ALPHA | LOAD_8BIT | LOAD_NO_PREMUL);
    if (img.isError)
    {
        return null;
    }

    // calculate target width and height
    int targetWidth, targetHeight;
    if (!imageSize.scale.isNaN)
    {
        targetWidth = (imageSize.scale * img.width).to!int;
        targetHeight = (imageSize.scale * img.height).to!int;
    }
    else if (imageSize.width && imageSize.height)
    {
        targetWidth = imageSize.width;
        targetHeight = imageSize.height;
    }
    else
    {
        targetWidth = img.width;
        targetHeight = img.height;
    }
    
    // create output image
    Image outimg;
    outimg.create(targetWidth, targetHeight, PixelType.rgba8);
    
    // resize using stb_image_resize2
    void* res = stbir_resize(
        img.scanptr(0), img.width, img.height, img.pitchInBytes,
        outimg.scanptr(0), outimg.width, outimg.height, outimg.pitchInBytes,
        STBIR_RGBA,
        STBIR_TYPE_UINT8_SRGB,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_DEFAULT
    );

    // check if successful
    if (res is null)
    {
        return null;
    }

    // alpha channel settings
    // handle format-specific conversions
    final switch (format)
    {
        // these formats don't support alpha - convert to RGB
        case ImageFormat.JPEG:
        case ImageFormat.SQZ:
            outimg.convertTo(PixelType.rgb8);
            break;
    
        // these support alpha - keep rgba8 (unless disabled)
        case ImageFormat.PNG:
        case ImageFormat.TGA:
        case ImageFormat.GIF:
        case ImageFormat.QOI:
        case ImageFormat.QOIX:
        case ImageFormat.DDS:
        case ImageFormat.BMP:
            if (removeAlpha)
            {
                outimg.convertTo(PixelType.rgb8);
            }
            break;

        // JPEG XL in Gamut has no alpha support
        case ImageFormat.JXL:
            outimg.convertTo(PixelType.rgb8);
            break;

        case ImageFormat.unknown:
            break;
    }
    
    // save image to memory and return as ubyte array
    ubyte[] outputData = outimg.saveToMemory(format);
    if (outputData is null)
    {
        return null;
    }
    
    return outputData;
}


