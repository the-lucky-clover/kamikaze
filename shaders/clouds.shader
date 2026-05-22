#pragma body
float density = saturate(1.0 - _surface.normal.y);
_surface.diffuse.rgb = mix(float3(0.24, 0.26, 0.28), float3(0.72, 0.72, 0.74), density);
_surface.transparency = 0.32 + (density * 0.24);
