//
//  GLESUtils.h
//  OpenGLStudy
//
//  Created by xxb on 2018/10/18.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLESUtils : NSObject

+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString;

+ (GLuint)loadShader:(GLenum)type withFilePath:(NSString *)shaderFilePath;

+ (BOOL)validateProgram:(GLuint)prog;

@end

NS_ASSUME_NONNULL_END
