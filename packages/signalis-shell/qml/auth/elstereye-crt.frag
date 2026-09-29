#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 viewportSize;
    vec2 noiseOffset;
    float pixelHeight;
};
layout(binding = 1) uniform sampler2D noiseTexture;

// Integral of the original 1px black stripe in each 3 logical pixels. This
// gives fractional-DPI edge coverage without aliasing the scanline spacing.
float stripeIntegral(float y) {
    return floor(y / 3.0) + clamp(mod(y, 3.0), 0.0, 1.0);
}

void main() {
    vec2 pixel = qt_TexCoord0 * viewportSize;
    float halfPixel = pixelHeight * 0.5;
    float scan = 0.15 * (stripeIntegral(pixel.y + halfPixel)
                      - stripeIntegral(pixel.y - halfPixel)) / pixelHeight;
    vec4 noise = texture(noiseTexture, fract((pixel - noiseOffset) / 256.0));
    float radius = length(pixel - viewportSize * 0.5);
    float vignette = 0.9 * clamp((radius - viewportSize.y / 3.0)
                              / (viewportSize.y * (2.0 / 3.0)), 0.0, 1.0);

    // Collapse black scanlines -> premultiplied white noise -> black vignette
    // into one source-over overlay. No background sampler or offscreen FBO.
    vec3 color = noise.rgb * (1.0 - vignette);
    float alpha = 1.0 - (1.0 - scan) * (1.0 - noise.a) * (1.0 - vignette);
    fragColor = vec4(color, alpha) * qt_Opacity;
}
