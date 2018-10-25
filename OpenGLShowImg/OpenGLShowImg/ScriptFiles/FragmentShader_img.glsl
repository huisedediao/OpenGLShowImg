varying highp vec2 v_texcoord;
uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, v_texcoord);
}

/* 如果不是以文件的形式，而是以宏的形式，写法如下
 #define STRINGIZE(x) #x
 #define STRINGIZE2(x) STRINGIZE(x)
 #define SHADER_STRING(text) @ STRINGIZE2(text)
 
 NSString *const rgbFragmentShaderString = SHADER_STRING
 (
 varying highp vec2 v_texcoord;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
 gl_FragColor = texture2D(inputImageTexture, v_texcoord);
 }
 );
 */
