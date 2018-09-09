//Shader.vsh

attribute vec4 position;
attribute vec4 color;
varying vec4 vcolor;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    vcolor = color;
    gl_Position = modelViewProjectionMatrix * position;
    
    //ポイントのサイズをここで設定する
    gl_PointSize = 8.0;
}
