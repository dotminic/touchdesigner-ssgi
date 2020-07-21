#include <packing>

uniform sampler2D	uColorBuffer;
uniform sampler2D	uDepthTexture;
uniform mat4		uInvProjMatrix;
uniform float		uGIAmount;
uniform int			uKernelSize;
uniform vec2		uViewportSize;
uniform float		cameraNear;
uniform float		cameraFar;

varying vec2		vUv;

float readDepth( sampler2D depthSampler, vec2 coord, float lod )
{
	float fragCoordZ = textureLod(depthSampler, coord, lod).x;
	float viewZ = perspectiveDepthToViewZ(fragCoordZ, cameraNear, cameraFar);
	return viewZToOrthographicDepth(viewZ, cameraNear, cameraFar);
}

vec3 getLightPosition( vec2 uv, float d )
{
	vec4 pos_s = vec4(uv.x * 2.0f - 1.0f, (1.0f - uv.y) * 2.0f - 1.0f, d, 1.0f);
	vec4 pos_v = uInvProjMatrix * pos_s;
	return pos_v.xyz / pos_v.w;
}

vec3	getFragWorldPosition( sampler2D tex, vec2 coord, float lod )
{
	float depth = readDepth(tex, coord, lod);

	vec3 pixel_pos_ndc = vec3(coord.x * 2.0f - 1.0f, coord.y * 2.0f - 1.0f, depth * 2.0f - 1.0f);
	vec4 pixel_pos_clip = uInvProjMatrix * vec4(pixel_pos_ndc, 1.0f);
	return pixel_pos_clip.xyz / pixel_pos_clip.w;
}

vec3	getFragNormal( sampler2D tex, vec2 coord, float lod )
{
	float pW = 1.0f / uViewportSize.x;
	float pH = 1.0f / uViewportSize.y;

	vec3 p1 = getFragWorldPosition(tex, coord + vec2(pW, 0.0), lod);
	vec3 p2 = getFragWorldPosition(tex, coord + vec2(0.0, pH), lod);
	vec3 p3 = getFragWorldPosition(tex, coord + vec2(-pW, 0.0), lod);
	vec3 p4 = getFragWorldPosition(tex, coord + vec2(0.0, -pH), lod);
	vec3 vP = getFragWorldPosition(tex, coord, lod);

	vec3 dx = vP - p1;
	vec3 dy = p2 - vP;
	vec3 dx2 = p3 - vP;
	vec3 dy2 = vP - p4;

	if (length(dx2) < length(dx) && coord.x - pW >= 0.0 || coord.x + pW > 1.0)
		dx = dx2;

	if (length(dy2) < length(dy) && coord.y - pH >= 0.0 || coord.y + pH > 1.0)
		dy = dy2;

	return normalize(cross(dy, dx).xyz);
}

float lenSq( vec3 vector )
{
	return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z;
}

vec3 lightSample( vec2 coord, vec2 lightCoord, vec3 fragWPosition, vec3 fragWNormal )
{
	vec3 lightWPosition = getLightPosition(lightCoord, texture(uDepthTexture, coord).r);
	vec3 lightWNormal = getFragNormal(uDepthTexture, lightCoord, 8.0f).rgb;
	vec3 lightColor = textureLod(uColorBuffer, lightCoord, 8.0).rgb;

	vec3 lightRay = lightWPosition - fragWPosition;
	vec3 lightDir = normalize(lightRay);

	float cosemit = max(dot(lightDir, -lightWNormal), 0.0f);
	float coscatch = max(dot(lightDir, fragWNormal) * 0.5 + 0.5, 0.0);
	float distfall = pow(lenSq(lightRay), 0.1) + 1.0;

	return (lightColor * cosemit * coscatch / distfall) / (float(uKernelSize * uKernelSize));
}

void main()
{
	vec3 direct = texture(uColorBuffer, vUv).rgb;
	vec3 fragWPosition = getFragWorldPosition(uDepthTexture, vUv, 0.0f);
	vec3 fragWNormal = getFragNormal(uDepthTexture, vUv, 0.0f);
	vec3 gi = vec3(0);

	float step = 1.0f / float(uKernelSize);
	vec2 s = vec2(step * 0.5, 1.0f - step * 0.5f);

	for (int i = 0; i < uKernelSize; i++)
	{
		for (int j = 0; j < uKernelSize; j++)
		{
			gi += lightSample(vUv, s, fragWPosition, fragWNormal);
			s.y -= step;
		}
		s.x += step;
		s.y = 1.0f - step * 0.5f;
	}

	vec4 albedo = vec4(direct + (gi / float(uKernelSize * uKernelSize) * uGIAmount), 1.0);
	if (vUv.x > 0.5)
		albedo = vec4(direct.rgb, 1.0f);
	gl_FragColor = albedo;
}
