//
//  PerlinNoise.metal
//  CSAI1
//
//  Created by DM on 3/25/25.
//

#include <metal_stdlib>
using namespace metal;

// A small set of permutations & gradients for simple 2D Perlin noise
// For more advanced, consider 3D Simplex or improved Perlin code.

constant short perm[256] = {
    151,160,137,91,90,15, // ...
    // (Truncated for brevity; you'd typically store 256 values, e.g. from reference code)
    // ... repeat or store a known permutation set ...
};

inline float2 fade(float2 t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

inline float grad2(int hash, float x, float y) {
    switch(hash & 0x3) {
        case 0: return  x + y;
        case 1: return -x + y;
        case 2: return  x - y;
        case 3: return -x - y;
    }
    return 0.0;
}

// A simple 2D Perlin function
float perlinNoise2D(float2 P) {
    int xi = (int)floor(P.x) & 255;
    int yi = (int)floor(P.y) & 255;

    float xf = P.x - floor(P.x);
    float yf = P.y - floor(P.y);

    int aa = perm[xi + perm[yi]] & 255;
    int ab = perm[xi + perm[yi + 1]] & 255;
    int ba = perm[xi + 1 + perm[yi]] & 255;
    int bb = perm[xi + 1 + perm[yi + 1]] & 255;

    float2 f = fade(float2(xf, yf));

    float v1 = grad2(aa, xf,     yf);
    float v2 = grad2(ba, xf-1.0, yf);
    float v3 = grad2(ab, xf,     yf-1.0);
    float v4 = grad2(bb, xf-1.0, yf-1.0);

    float l1 = mix(v1, v2, f.x);
    float l2 = mix(v3, v4, f.x);
    return mix(l1, l2, f.y); // range ~ [-1,1]
}

// Uniform data passed from Swift code
struct Uniforms {
    float time;
    float2 resolution;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut v_main(
    uint vid [[vertex_id]],
    constant Uniforms& u [[buffer(1)]])
{
    VertexOut out;

    // Full-screen triangle approach
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    out.position = float4(pos[vid], 0.0, 1.0);
    
    // uv from [-1..1] → [0..1]
    float2 uv = (pos[vid] * 0.5 + 0.5) * float2(u.resolution.x / u.resolution.y, 1.0);
    out.uv = uv;
    return out;
}

fragment half4 f_main(VertexOut in [[stage_in]],
                      constant Uniforms& u [[buffer(0)]])
{
    // Scale the uv so noise doesn't look too zoomed
    float2 coords = in.uv * 3.0;
    // Animate by adding time as a z offset
    coords += float2(0.0, u.time * 0.2);
    
    float n = perlinNoise2D(coords);
    // map from [-1..1] to [0..1]
    float shade = 0.5 + 0.5 * n;

    // Optionally apply color shift
    float3 color = float3(shade, shade, shade);
    // Explicitly convert to half3 and half(1.0)
    half3 hColor = half3(color);
    return half4(hColor, half(1.0));
}
