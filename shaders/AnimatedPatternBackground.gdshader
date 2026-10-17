shader_type canvas_item;

// Shader for creating an animated pattern background.
// Works well with kenney's pattern pack: https://kenney.nl/assets/pattern-pack-extra

// Assign this shader to a ColorRect node and set "Anchors Preset" to "Full Rect" to create a background.
// Works with other 2D nodes as well.

// Assign the pattern texture here.
// Should be a black and white square texture containing the base pattern.
uniform sampler2D pattern: repeat_enable;
// The color you want the pattern to appear as.
uniform vec4 pattern_color: source_color = vec4(1.0);

// Factor by which UVs are divided.
// Affects the size of each repeating pattern.
uniform float tiling = 100.0;
// How fast the background moves.
uniform vec2 speed = vec2(0.1, 0.5);
// Rotation of the base pattern in a range from -2pi to 2pi.
// You can also use a range from -360 to 360 degrees and convert to radians in the vertex shader.
uniform float rotation: hint_range(-6.28318530717959, 6.28318530717959) = 0.0;

// Compute UVs in the vertex shader and pass them to the fragment shader.
varying vec2 tiled_uv;

// Called for every vertex the material is visible on.
void vertex() {
	// Compute UVs to sample the pattern texture
	// We use VERTEX instead of UV to avoid stretching on rectangular backgrounds
	tiled_uv = VERTEX / tiling + TIME * speed;
	// Apply a rotation using a rotation matrix
	float c = cos(rotation);
	float s = sin(rotation);
	tiled_uv = mat2(vec2(c, -s), vec2(s, c)) * tiled_uv;
}

// Called for every pixel the material is visible on.
void fragment() {
	// Mix the color of the ColorRect with the color of the pattern based on the pattern texture
	// The third parameter is basically the value of the pattern and tells how much of each color to use in the mix
	COLOR = mix(COLOR, pattern_color, texture(pattern, tiled_uv));
}
