//
//  ImageDecoder.m
//  OpenGLStudy
//
//  Created by xxb on 2018/10/23.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "ImageDecoder.h"
#import "png_decoder.h"

@implementation ImageDecoder
///解码png
+ (RGBAFrame *)getPngRGBAFrameFromPath:(NSString*) pngFilePath
{
    PngPicDecoder* decoder = new PngPicDecoder();
    char* pngPath = (char*)[pngFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    decoder->openFile(pngPath);
    RawImageData data = decoder->getRawImageData();
    RGBAFrame* frame = new RGBAFrame();
    frame->width = data.width;
    frame->height = data.height;
    int expectLength = data.width * data.height * 4;
    uint8_t * pixels = new uint8_t[expectLength];
    memset(pixels, 0, sizeof(uint8_t) * expectLength);
    int pixelsLength = MIN(expectLength, data.size);
    memcpy(pixels, (byte*) data.data, pixelsLength);
    frame->pixels = pixels;
    decoder->releaseRawImageData(&data);
    decoder->closeFile();
    delete decoder;
    return frame;
}
@end
