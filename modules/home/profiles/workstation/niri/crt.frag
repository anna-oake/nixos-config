// CRT beam, shared by the window open and close animations.
//
// t = 0 is a dark tube, t = 1 is the settled picture. On the way up a hot
// red line sweeps out from the centre, the picture then opens vertically out
// of it, and the scanlines and red cast fade as the tube settles.
vec4 crt_beam(vec3 coords_geo, vec3 size_geo, float t) {
    float w = smoothstep(0.0, 0.35, t);
    float h = smoothstep(0.25, 1.0, t);
    float half_h = max(h, 2.0 / size_geo.y) * 0.5;

    vec2 c = coords_geo.xy - 0.5;
    if (abs(c.x) > w * 0.5 || abs(c.y) > half_h)
        return vec4(0.0);

    // Squash the picture into the lit band instead of cropping it.
    vec3 geo = vec3(0.5 + c.x / max(w, 0.001), 0.5 + c.y / (half_h * 2.0), 1.0);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * geo).st);

    float settle = 1.0 - h;
    float scan = step(0.5, fract(coords_geo.y * size_geo.y / 3.0));
    color.rgb *= 1.0 - 0.4 * settle * scan;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0, 0.45, 0.35), settle * 0.6);

    vec4 beam = vec4(0.980, 0.314, 0.235, 1.0);
    return mix(color, beam, smoothstep(0.3, 0.0, h));
}
