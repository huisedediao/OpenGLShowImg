//
//  GLESUtils.m
//  OpenGLStudy
//
//  Created by xxb on 2018/10/18.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "GLESUtils.h"

@implementation GLESUtils

+ (GLuint)loadShader:(GLenum)type withFilePath:(NSString *)shaderFilePath
{
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        NSLog(@"Error:loading shader file:%@ %@",shaderFilePath,error.localizedDescription);
        return 0;
    }
    return [self loadShader:type withString:shaderString];
}

+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString
{
    //create the shader object
    GLuint shader = glCreateShader(type);
    if (shader == 0)
    {
        NSLog(@"Error:failed to create shader.");
        return 0;
    }
    
    //给shader提供shader源码
    const char *shaderStringUTF8 = [shaderString UTF8String];
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    
    //编译指定的shader对象
    glCompileShader(shader);
    
    //check the compile status
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (!compiled)
    {
        GLint infolen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolen);
        
        if (infolen > 1)
        {
            char *infolog = malloc(sizeof(char) * infolen);
            glGetShaderInfoLog(shader, infolen, NULL, infolog);
            NSLog(@"Error compiling shader:\n%s\n",infolog);
            free(infolog);
        }
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}


+ (BOOL)validateProgram:(GLuint)prog
{
    GLint status;
    
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
    
    return YES;
}

@end
