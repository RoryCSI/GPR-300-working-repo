/*
	Copyright 2011-2021 Daniel S. Buckstein

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

/*
	animal3D SDK: Minimal 3D Animation Framework
	By Daniel S. Buckstein

	///////Modified by Rory Beebout///////
	
	drawPhong_shadow_fs4x.glsl
	Output Phong shading with shadow mapping.
*/

#version 450

// ****Done:
// 1) Phong shading
//	-> identical to outcome of last project
// 2) shadow mapping
//	-> declare shadow map texture
//	-> declare shadow coordinate varying
//	-> perform manual "perspective divide" on shadow coordinate
//	-> perform "shadow test" (explained in class)

layout (location = 0) out vec4 rtFragColor;
layout (binding = 0) uniform sampler2D uTex_shadow;

uniform int uCount;

in vec4 vView;
in vec4 vNormal;
in vec4 vPosition;
in vec2 vTexcoord;
in vec4 vShadowCoord;

uniform vec4 uColor;
uniform sampler2D uSampler;

struct sPointLightData
{
	vec4 position;						// position in rendering target space
	vec4 worldPos;						// original position in world space
	vec4 color;							// RGB color with padding
	float radius;						// radius (distance of effect from center)
	float radiusSq;						// radius squared (if needed)
	float radiusInv;					// radius inverse (attenuation factor)
	float radiusInvSq;					// radius inverse squared (attenuation factor)
};

uniform ubLight
{
	sPointLightData uPointLightData[4];
};

void main()
{
	vec4 phongColor = vec4(0);//To store each light pass's results to later be combined

	//normalize vectors
	vec4 N = normalize(vNormal);
	vec4 V = normalize(vView);

	for(int i = 0; i < uCount; i++)
	{
		vec4 lightVector = uPointLightData[i].position - vPosition; //calculate view-space light vector - Blue Book p.617
		vec4 L = normalize(lightVector); //Also needs to be normalized - Blue Book p.617
		vec4 R = reflect(-L, N);//reflect -L off the normalized normal

		vec4 diffuse = max(dot(N, L), 0.0) * texture2D(uSampler, vTexcoord) *uPointLightData[i].color; //Calculate diffuse(lambert) by lightcolor, also throw in texture Blue Book p.617
		vec4 specular = pow(max(dot(V, R), 0.0), 128.0) * uPointLightData[i].color; //calculate specular
		float attenuation = smoothstep(uPointLightData[i].radius, 0, length(lightVector)); //Diminish lighting over distance

		phongColor += vec4(attenuation*(diffuse+specular));

	}

	//Shadow test - http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-16-shadow-mapping/#basic-shadowmap
	vec4 shadow = vec4(1.0); //Does nothing when out of shadow
	if ( textureProj(uTex_shadow, vShadowCoord ).z  <  (vShadowCoord.z)/vShadowCoord.w ) //Perspective divide - compares depth from light and from shader to calc shadows
	{
		shadow = vec4(0.3); //Darken shadows
	}

	rtFragColor = shadow * phongColor; //Combine, output all above
}

