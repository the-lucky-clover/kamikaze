#pragma body
float horizon = saturate(_surface.position.y / 1200.0);
float3 ash = float3(0.18, 0.20, 0.24);
float3 sunset = float3(0.58, 0.26, 0.16);
_surface.diffuse.rgb = mix(sunset, ash, horizon);
