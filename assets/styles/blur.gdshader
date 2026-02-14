shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_radius : hint_range(1.0, 4.0) = 2.5;

void fragment() {
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 uv = SCREEN_UV;
	vec2 px = blur_radius / tex_size;

	vec4 col = vec4(0.0);

	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			col += texture(screen_texture, uv + px * vec2(float(x), float(y)));
		}
	}

	col /= 25.0;

	COLOR = mix(col, COLOR, COLOR.a);

}
