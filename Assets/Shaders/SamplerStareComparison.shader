Shader "Unlit/SamplerStareComparison"{
    Properties{
        _MainTex ("Main Texture (No Sampler)", 2D) = "white" {}
        _tex1 ("Texture1 (has Sampler)", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f{
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            //資料：https://docs.unity3d.com/ja/2019.4/Manual/SL-SamplerStates.html
            //SamplerState:テクスチャサンプリングする際の、WrapMode,FilterModeを決める存在。
            //SamplerStateは一般的にはTextureのimport Settingsで設定される。
            //Samper2D _MainTex;のように宣言すると、テクスチャとSamplerStateの両方が暗黙的に宣言される。
            //この時に宣言されているSamplerStateはimportSettingsで設定されたものになる。
            //tex2D(_MainTex, uv)のようにサンプリングすると、自動で対応するSamplerStateでテクスチャサンプリングが行われる。
            
            //問題
            //一つのシェーダーが扱えるSamplerStateには上限数がある。
            //逆に一つのシェーダーが扱えるテクスチャの上限数はSamplerStateの上限より多い。
            //なので一つのシェーダーで多くのテクスチャを利用したい場合、SamplerStateは再利用しないといけないことになる。
            //SamplerStateの宣言とテクスチャの宣言とサンプリング時に使うのSamplerStateの指定を明示的にする記述もある。
            //それが
            //SamplerState サンプラーステートの変数名;
            //UNITY_DECLARE_TEX2D(テクスチャ変数名);//この記述だと再利用可能なサンプラーステートとテクスチャを同時に宣言できるっぽい
            //UNITY_DECLARE_TEX2D_NOSAMPLER(テクスチャ変数名);//この記述でテクスチャを宣言した場合はSamplerStateを持たないテクスチャを宣言できるので、上限数を圧迫しない。
            //UNITY_SAMPLE_TEX2D_SAMPLER(テクスチャ変数名, サンプラーを持つテクスチャ変数名, uv);
            //テクスチャ変数名.Sampler(サンプラーステートの変数名, uv)
            //サンプラーを指定してサンプリングする場合は、importsettingsの

            //SamplerStateの変数名にpoint/liner/trilinear,clamp/repeat/mirror/mirroronceの文字列があれば、
            //それに対応したならSamplerStateとして機能してくれるっぽい。（大文字小文字は区別しない）（他にもUとVで個別のWrapModeを指定するとかもできる）
            SamplerState linearmirror;
            UNITY_DECLARE_TEX2D(_tex1);
            UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
            float4 _MainTex_ST;
            
            v2f vert (float4 vertex : POSITION, float2 uv : TEXCOORD0){
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.uv = TRANSFORM_TEX(uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target{
                // sample the texture
                // サンプリングした値を最終出力に貢献するようにしないとマクロで宣言されたはずの
                // SamplerStateがコンパイル時の最適化で削除されてコンパイルエラーになるので注意。
                fixed4 c0 = _MainTex.Sample(linearmirror, i.uv);
                fixed4 c1 = UNITY_SAMPLE_TEX2D_SAMPLER(_MainTex, _tex1, (i.uv));//何故かエラーになる
                fixed4 c2 = _tex1.Sample(linearmirror, (i.uv+_Time.x));//これは大丈夫
                fixed4 c3 = _MainTex.Sample(sampler_tex1, i.uv);//これは大丈夫
                return c0 + c1 + c2 + c3;
            }
            ENDCG
        }
    }
}
