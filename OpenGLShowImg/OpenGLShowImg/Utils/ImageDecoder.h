//
//  ImageDecoder.h
//  OpenGLStudy
//
//  Created by xxb on 2018/10/23.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rgba_frame.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageDecoder : NSObject
///解码png
+ (RGBAFrame *)getPngRGBAFrameFromPath:(NSString*) pngFilePath;
@end

NS_ASSUME_NONNULL_END
