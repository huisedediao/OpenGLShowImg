//
//  OpenGLView_img.m
//  OpenGLStudy
//
//  Created by xxb on 2018/10/24.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "OpenGLView_img.h"
#import "png_decoder.h"
#import "rgba_frame.h"
#import "GLESUtils.h"
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "ImageDecoder.h"

@interface OpenGLView_img ()
{
    EAGLContext *                           _context;
    GLuint                                  _displayFramebuffer;
    GLuint                                  _renderbuffer;
    GLint                                   _backingWidth;
    GLint                                   _backingHeight;
    
    BOOL                                    _stopping;
    RGBAFrame *                             _frame;
    
    
    GLuint                              _filterProgram;
    GLint                               _filterPositionAttribute;
    GLint                               _filterTextureCoordinateAttribute;
    GLint                               _filterInputTextureUniform;
    
    GLuint                              _inputTexture;
}

@property (atomic) BOOL readyToRender;
@property (nonatomic, assign) BOOL shouldEnableOpenGL;
@property (nonatomic, strong) NSLock *openGLLock;

@end

@implementation OpenGLView_img

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame filePath:(NSString *)filePath
{
    if (self = [super initWithFrame:frame])
    {
        _openGLLock = [NSLock new];
        [_openGLLock lock];
        _shouldEnableOpenGL = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
        [_openGLLock unlock];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        _frame = [ImageDecoder getPngRGBAFrameFromPath:filePath];
        
        [self setupFun];
    }
    return self;
}
- (void)setupFun
{
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupTexture];
    self.readyToRender = YES;
}

- (void)destroy
{
   _stopping = true;

    if (_displayFramebuffer) {
        glDeleteFramebuffers(1, &_displayFramebuffer);
        _displayFramebuffer = 0;
    }
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_filterProgram) {
        glDeleteProgram(_filterProgram);
        _filterProgram = 0;
    }
    if(_inputTexture) {
        glDeleteTextures(1, &_inputTexture);
    }
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _context = nil;
}


#pragma mark - 方法调用
- (void)setupLayer;
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    //CALayer默认是透明的，x必须将它设置为不透明才能让其可见
    eaglLayer.opaque = YES;
    
    //设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    //设置 kEAGLDrawablePropertyRetainedBacking 为FALSE，表示不想保持呈现的内容，因此在下一次呈现时，应用程序必须完全重绘一次。将该设置为 TRUE 对性能和资源影像较大，因此只有当renderbuffer需要保持其内容不变时，我们才设置 kEAGLDrawablePropertyRetainedBacking  为 TRUE
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @(NO),
                                     kEAGLDrawablePropertyRetainedBacking,
                                     kEAGLColorFormatRGBA8,
                                     kEAGLDrawablePropertyColorFormat,
                                     nil];
}
- (void)setupContext
{
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        NSLog(@"Failed to initialie OpenGLES 2.0 context");
        exit(1);
    }
    //设置当前的context
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}
- (void)setupRenderBuffer
{
    glGenRenderbuffers(1, &_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    //为colorRenderBuffer分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    //获取绘制缓冲区的宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    //获取绘制缓冲区的高度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
}

- (void)setupFrameBuffer
{
    //framebuffer object 通常也被称之为 FBO，它相当于 buffer(color, depth, stencil)的管理者，三大buffer 可以附加到一个 FBO 上,我们是用 FBO 来在 off-screen buffer上进行渲染
    glGenFramebuffers(1, &_displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    
    //将_colorRenderBuffer装配到GL_COLOR_ATTACHMENT0这个装配点上
    //参数 attachment 是指定 renderbuffer 被装配到那个装配点上，其值是GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT, GL_STENCIL_ATTACHMENT中的一个，分别对应 color，depth和 stencil三大buffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderbuffer);
}
- (void)setupProgram
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    //创建显卡可执行程序的容器
    _filterProgram = glCreateProgram();
    
    //编译vertexShader（顶点着色器）
    NSString *vertexShaderFilePath = [[NSBundle mainBundle] pathForResource:@"VertexShader_img" ofType:@"glsl"];
    vertShader = [GLESUtils loadShader:GL_VERTEX_SHADER withFilePath:vertexShaderFilePath];
    
    //编译fragmentShader（片元着色器）
    NSString *fragmentShaderFilePath = [[NSBundle mainBundle] pathForResource:@"FragmentShader_img" ofType:@"glsl"];
    fragShader = [GLESUtils loadShader:GL_FRAGMENT_SHADER withFilePath:fragmentShaderFilePath];
    
    if (!vertShader || !fragShader)
    {
        goto exit;
    }
    
    //把两个着色器附到上面的显卡可执行程序的容器中
    glAttachShader(_filterProgram, vertShader);
    glAttachShader(_filterProgram, fragShader);
    
    //链接程序
    glLinkProgram(_filterProgram);
    
    _filterPositionAttribute = glGetAttribLocation(_filterProgram, "position");
    _filterTextureCoordinateAttribute = glGetAttribLocation(_filterProgram, "texcoord");
    _filterInputTextureUniform = glGetUniformLocation(_filterProgram, "inputImageTexture");
    
    GLint status;
    glGetProgramiv(_filterProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Failed to link program %d", _filterProgram);
        goto exit;
    }
    result = [GLESUtils validateProgram:_filterProgram];
exit:
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        NSLog(@"OK setup GL programm");
    } else {
        glDeleteProgram(_filterProgram);
        _filterProgram = 0;
    }
    //    return result;
}

- (void)setupTexture
{
    //创建一个纹理对象
    glGenTextures(1, &_inputTexture);
    //绑定纹理对象（告诉openGL ES具体操作的是哪一个纹理对象）
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    
    //设置放大和缩小时像素是如何填充的（设置放大或者缩小时的过滤方式）
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //将s轴和t轴的坐标设置为GL_CLAMP_TO_EDGE类型，所有大于1的都设置为1，所有小于0的都设置为0
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //将RGBA的数据放到上面创建的纹理对象上，这里最有一个参数传递是uint8_t数组类型的pixels，这里还没有渲染，传0
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)_frame->width, (GLsizei)_frame->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void) render;
{
    if(_stopping){
        return;
    }

    if(self->_frame) {
        [self.openGLLock lock];
        if (!self.readyToRender || !self.shouldEnableOpenGL) {
            glFinish();
            [self.openGLLock unlock];
            return;
        }
        [self.openGLLock unlock];
        
        //绑定操作的上下文
        [EAGLContext setCurrentContext:self->_context];
        glBindFramebuffer(GL_FRAMEBUFFER, self->_displayFramebuffer);
        
        //规定窗口的大小
        glViewport(0, self->_backingHeight - self->_backingWidth - 75, self->_backingWidth, self->_backingWidth);
        //渲染数据
        [self renderFrame:self->_frame->pixels];
        
        glBindRenderbuffer(GL_RENDERBUFFER, self->_renderbuffer);
        
        //马上显示
        [self->_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (void)renderFrame:(uint8_t *)rgbaFrame;
{
    //使用显卡绘制程序
    glUseProgram(_filterProgram);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)_frame->width, (GLsizei)_frame->height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, rgbaFrame);
    
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    //设置物体坐标
    glVertexAttribPointer(_filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glEnableVertexAttribArray(_filterPositionAttribute);
    
    //设置纹理坐标
    glVertexAttribPointer(_filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    glEnableVertexAttribArray(_filterTextureCoordinateAttribute);
    
    //指定将要绘制的纹理图像并且传递给对应的FragmentShader
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    glUniform1i(_filterInputTextureUniform, 0);
    
    //执行绘制操作
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.openGLLock lock];
    self.shouldEnableOpenGL = NO;
    [self.openGLLock unlock];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.openGLLock lock];
    self.shouldEnableOpenGL = YES;
    [self.openGLLock unlock];
}

@end
