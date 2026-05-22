#pragma body
float stormMix = smoothstep(0.05, 0.85, _surface.normal.y);
_surface.diffuse.rgb = mix(float3(0.04, 0.10, 0.19), float3(0.14, 0.22, 0.30), stormMix);
_surface.emission.rgb += float3(0.02, 0.03, 0.04) * (1.0 - _surface.normal.y);
