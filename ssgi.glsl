uniform sampler2D	uDepthTexture;
uniform mat4		uInvProjMatrix;
uniform float		uGIAmount;
uniform int			uKernelSize;

out vec4 fragColor;

vec3 getLightPosition( vec2 uv, float d )
{
	vec4 pos_s = vec4(uv.x * 2.0f - 1.0f, (1.0f - uv.y) * 2.0f - 1.0f, d, 1.0f);
	vec4 pos_v = uInvProjMatrix * pos_s;
	return pos_v.xyz / pos_v.w;
}

vec3	getFragWorldPosition( vec2 coord, float lod )
{
	float depth = textureLod(sTD2DInputs[1], coord, lod).r;

	vec3 pixel_pos_ndc = vec3(coord.x * 2.0f - 1.0f, coord.y * 2.0f - 1.0f, depth * 2.0f - 1.0f);
	vec4 pixel_pos_clip = uInvProjMatrix * vec4(pixel_pos_ndc, 1.0f);
	return pixel_pos_clip.xyz / pixel_pos_clip.w;
}

vec3	getFragNormal( vec2 coord, float lod )
{
	float pW = uTD2DInfos[0].res.x;
	float pH = uTD2DInfos[0].res.y;

	vec3 p1 = getFragWorldPosition(coord + vec2(pW, 0.0), lod);
	vec3 p2 = getFragWorldPosition(coord + vec2(0.0, pH), lod);
	vec3 p3 = getFragWorldPosition(coord + vec2(-pW, 0.0), lod);
	vec3 p4 = getFragWorldPosition(coord + vec2(0.0, -pH), lod);
	vec3 vP = getFragWorldPosition(coord, lod);

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
	vec3 lightWPosition = getLightPosition(lightCoord, texture(sTD2DInputs[1], coord).r);
	vec3 lightWNormal = getFragNormal(lightCoord, 8.0f).rgb;
	vec3 lightColor = textureLod(sTD2DInputs[0], lightCoord, 8.0).rgb;

	vec3 lightPath = lightWPosition - fragWPosition;
	vec3 lightDir = normalize(lightPath);

	float emitAmount = max(dot(lightDir, -lightWNormal), 0.0f);
	float receiveAmount = clamp(dot(lightDir, fragWNormal) * 0.5f + 0.5f, 0.0f, 1.0f);
	float distfall = pow(lenSq(lightPath), 0.1f) + 1.0f;

	return (lightColor * emitAmount * receiveAmount / distfall) / float(uKernelSize * uKernelSize);
}

void main()
{
	vec3 direct = texture(sTD2DInputs[0], vUV.st).rgb;
	vec3 fragWPosition = getFragWorldPosition(vUV.st, 0.0f);
	vec3 fragWNormal = getFragNormal(vUV.st, 0.0f);
	vec3 gi = vec3(0);

	float step = 1.0f / float(uKernelSize);
	vec2 s = vec2(step * 0.5, 1.0f - step * 0.5f);

	for (int i = 0; i < uKernelSize; i++)
	{
		for (int j = 0; j < uKernelSize; j++)
		{
			gi += lightSample(vUV.st, s, fragWPosition, fragWNormal);
			s.y -= step;
		}
		s.x += step;
		s.y = 1.0f - step * 0.5f;
	}

	vec4 albedo = vec4(direct + (gi / float(uKernelSize * uKernelSize) * uGIAmount), 1.0);
	if (vUV.st.x > 0.5)
		albedo = vec4(direct.rgb, 1.0f);
	fragColor = TDOutputSwizzle(vec4(albedo));
}
