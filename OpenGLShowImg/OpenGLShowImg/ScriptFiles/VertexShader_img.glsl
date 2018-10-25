attribute vec4 position;
attribute vec2 texcoord;
varying vec2 v_texcoord;

void main()
{
    gl_Position = position;
    v_texcoord = texcoord.xy;
}

/* 如果不是以文件的形式，而是以宏的形式，写法如下
 #define STRINGIZE(x) #x
 #define STRINGIZE2(x) STRINGIZE(x)
 #define SHADER_STRING(text) @ STRINGIZE2(text)
 
 NSString *const vertexShaderString = SHADER_STRING
 (
 attribute vec4 position;
 attribute vec2 texcoord;
 varying vec2 v_texcoord;
 
 void main()
 {
 gl_Position = position;
 v_texcoord = texcoord.xy;
 }
 );
 );
 */
