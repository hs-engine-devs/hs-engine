package shaders;

import flixel.system.FlxAssets.FlxShader;

class SelectionShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header
        uniform float uTime;
        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            if (color.a > 0.0) {
                float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
                float pulse = 0.6 + sin(uTime * 5.0) * 0.2; 
                gl_FragColor = vec4(vec3(0.0, 0.4, 0.9) * (gray + pulse), color.a);
            } else {
                gl_FragColor = color;
            }
        }
    ')
    public function new()
    {
        super();
    }
}
