//Shader.fsh

precision mediump float;

uniform sampler2D s_texture;
varying vec4 vcolor;

void main()
{
    //サンプラで取り込んだテクスチャを、変数"baseColor"に格納
    vec4 baseColor = texture2D(s_texture, gl_PointCoord);
    
    //アルファ値が0.5未満である場合はフラグメントを破棄（アルファテスト）
    if(baseColor.a < 0.5){
        discard;
    }
    else{
        //元々のテクスチャの色に、各ポイントに設定された色を付けて出力する
        gl_FragColor = baseColor * vec4(vcolor);
    }
}
