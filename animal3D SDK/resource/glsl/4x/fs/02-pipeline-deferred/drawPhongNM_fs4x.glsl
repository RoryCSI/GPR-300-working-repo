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
	
	drawPhongNM_fs4x.glsl
	Output Phong shading with normal mapping.
*/

#version 450

#define MAX_LIGHTS 1024

// ****TO-DO:
//	-> declare view-space varyings from vertex shader
//	-> declare point light data structure and uniform block
//	-> declare uniform samplers (diffuse, specular & normal maps)
//	-> calculate final normal by transforming normal map sample
//	-> calculate common view vector
//	-> declare lighting sums (diffuse, specular), initialized to zero
//	-> implement loop in main to calculate and accumulate light
//	-> calculate and output final Phong sum

//Lighting data
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
//Lighting Block
uniform ubLight
{
	sPointLightData uPointLightData[MAX_LIGHTS];
};

layout (location = 0) out vec4 rtFragColor;
layout (location = 1) out vec4 rtNormal;
layout (location = 2) out vec4 rtDiffuse;
layout (location = 3) out vec4 rtSpecular;

uniform int uCount;

// location of viewer in its own space is the origin
const vec4 kEyePos_view = vec4(0.0, 0.0, 0.0, 1.0);

//View-space varyings
in vec4 vPosition;
in vec4 vNormal;
in vec4 vTexcoord;
in vec3 vTangent; //unused -> TBN
in vec4 vBiTangent; //unused -> TBN
in mat3 vTBN; //Tangent, bitanget, normal mat for converting tangent normal

//uniform samplers
uniform sampler2D uTex_dm;
uniform sampler2D uTex_sm;
uniform sampler2D uTex_nm;

// declaration of Phong shading model
//	(implementation in "utilCommon_fs4x.glsl")
//		param diffuseColor: resulting diffuse color (function writes value)
//		param specularColor: resulting specular color (function writes value)
//		param eyeVec: unit direction from surface to eye
//		param fragPos: location of fragment in target space
//		param fragNrm: unit normal vector at fragment in target space
//		param fragColor: solid surface color at fragment or of object
//		param lightPos: location of light in target space
//		param lightRadiusInfo: description of light size from struct
//		param lightColor: solid light color
void calcPhongPoint(
	out vec4 diffuseColor, out vec4 specularColor,
	in vec4 eyeVec, in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor
);

void main()
{
	vec3 tangentNormal = texture(uTex_nm, vTexcoord.xy).xyz * 2.0 - 1.0; //Pull normal from normal map (Tangent space)
	vec4 finalNormal = vec4(vTBN * tangentNormal, 0.0); //Convert to view space;

	//To accumulate value in the FOR loop below
	vec4 finalPhong = vec4(0.0);
	vec4 finalDiffuse = vec4(0.0);
	vec4 finalSpecular = vec4(0.0);

	vec4 diffuse = vec4(0.0);
	vec4 specular = vec4(0.0);

	for(int i = 0; i < MAX_LIGHTS; i++)
	{
		//CommonUtil Phong Function 
		calcPhongPoint(diffuse, specular, //Output results into diffuse, specular
		-normalize(vPosition), vPosition, finalNormal, texture(uTex_dm, vTexcoord.xy),//eyeVec, fragPos, fragNrm, fragColor
		uPointLightData[i].position, //light pos,
		vec4(uPointLightData[i].radius, uPointLightData[i].radiusSq, uPointLightData[i].radiusInv, uPointLightData[i].radiusInvSq),//light radius
		uPointLightData[i].color);//light color

		finalPhong += (diffuse + specular);//sum calculations for final
		finalDiffuse += diffuse;
		finalSpecular += specular;
	}

	//Output for all buffers
	rtNormal = finalNormal * 0.5 + 0.5;
	rtDiffuse = texture(uTex_dm, vTexcoord.xy);
	rtSpecular = texture(uTex_sm, vTexcoord.xy);
	rtFragColor = vec4(finalPhong.xyz, 1.0);//set ALPHA to 1.0 to avoid phantom menace
}
