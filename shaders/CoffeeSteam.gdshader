
shader_type canvas_item;

uniform vec4 steam_color : source_color = vec4(0.78, 0.80, 0.82, 0.65);
uniform float thickness : hint_range(0.02, 0.3) = 0.12;
uniform float wave_amplitude : hint_range(0.0, 0.3) = 0.13;
uniform float wave_frequency : hint_range(2.0, 20.0) = 8.0;
uniform float rise_speed : hint_range(0.0, 5.0) = 1.2;
uniform float edge_softness : hint_range(0.001, 0.08) = 0.018;
uniform float top_fade : hint_range(0.01, 0.5) = 0.22;

void fragment() {
    vec2 uv = UV;

    // A thick, winding S-shaped ribbon.
    float phase = uv.y * wave_frequency + TIME * rise_speed;

    float center = 0.5
        + sin(phase) * wave_amplitude
        + sin(phase * 0.5 + 1.2) * wave_amplitude * 0.35;

    // Slowly vary the thickness as the steam moves.
    float width = thickness
        * (0.8 + 0.2 * sin(phase * 0.7));

    // Smooth edges for a soft cartoon appearance.
    float distance_from_center = abs(uv.x - center);

    float ribbon = 1.0 - smoothstep(
        width,
        width + edge_softness,
        distance_from_center
    );

    // Fade out towards the top.
    float fade = smoothstep(0.0, top_fade, uv.y);

    float alpha = ribbon * fade * steam_color.a;

    // Transparent background outside the steam.
    COLOR = vec4(steam_color.rgb, alpha);
}
