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
	
	drawPhongPOM_fs4x.glsl
	Output Phong shading with parallax occlusion mapping (POM).
*/

#version 450

#define MAX_LIGHTS 1024

in vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
};

struct sPointLight
{
	vec4 viewPos, worldPos, color, radiusInfo;
};

uniform ubLight
{
	sPointLight uPointLight[MAX_LIGHTS];
};

uniform int uCount;

uniform vec4 uColor;

uniform float uSize;

uniform sampler2D uTex_dm, uTex_sm, uTex_nm, uTex_hm;

const vec4 kEyePos = vec4(0.0, 0.0, 0.0, 1.0);

layout (location = 0) out vec4 rtFragColor;
layout (location = 1) out vec4 rtFragNormal;
layout (location = 2) out vec4 rtFragDiffuse;
//layout (location = 3) out vec4 rtFragSpecular;
layout (location = 3) out vec4 rtFragPosition;

void calcPhongPoint(out vec4 diffuseColor, out vec4 specularColor, in vec4 eyeVec,
	in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor);
	
vec3 calcParallaxCoord(in vec3 coord, in vec3 viewVec, const int steps)
{
	// ****Done:
	//	-> step along view vector until intersecting height map
	//	-> determine precise intersection point, return resulting coordinate

	//referencing Buckstein POM presentation
	//This is probably more accurate than the uncommented method below - using lerps for exact positioning.
	////////////////////////////////////////////////////////////////////
	/*
	float dt = 1.0/steps;
	int currentStep = 0;
	vec3 coordEnd = coord - normalize(viewVec)/viewVec.z;
	//coordEnd = coord - viewVec;
	vec3 currentCheckPos;
	float currentHeightSample;
	vec3 lastCoord;
	float lastHeightSample;
	
	float x;
	while (currentStep < steps)
	{
		currentCheckPos = mix(vec3(coord.xy,1), vec3(coordEnd.xy,0), dt*currentStep);
		currentHeightSample = texture(uTex_hm, vTexcoord_atlas.xy).r;
		if (currentHeightSample > currentCheckPos.y)
		{
			x = (lastCoord.y - lastHeightSample) /
			((lastHeightSample - currentHeightSample) - (lastCoord.y - currentCheckPos.y ));
			currentStep = steps + 1;
		}
		else
		{
			lastHeightSample = currentHeightSample;
			lastCoord = currentCheckPos;
		}
		currentStep++;
		coord = mix(lastCoord, currentCheckPos, x);
	}
	
	return coord;
	*/
	///////////////////////////////////////////////////////////////////
	
	
	//References - https://learnopengl.com/Advanced-Lighting/Parallax-Mapping
	//			 - https://www.gamedev.net/tutorials/programming/graphics/a-closer-look-at-parallax-occlusion-mapping-r3262/
	//		     - "nm pom" presentation in Canvas

	//setup step values
	float dt = 1.0/steps; // size of each step
	float currentStepDepth = 1.0; // current step depth
	vec3 offsetDir = viewVec * coord.z * 2.5; // offset direction, scaled down by tangent basis size
	vec3 deltaTexCoords = offsetDir / steps; // offset per step

	vec3 currentTexCoords = coord; // initialize currentTexCoords
	float currentDepthMapValue = texture(uTex_hm, currentTexCoords.xy).r; //get height_map sample

	while (currentStepDepth > currentDepthMapValue)
	{
		currentTexCoords -= deltaTexCoords; //step coord towards end position

		currentDepthMapValue = texture(uTex_hm, currentTexCoords.xy).r; // update height_map sample for new currentTexCoords

		currentStepDepth -= dt; //update currentStepDepth for next comparison
	}
	//set coord
	coord = currentTexCoords;

	//Try using lerp technique - bit broken
	/*
	float x = ((currentTexCoords + deltaTexCoords).y - (currentDepthMapValue + dt)) /
			 (((currentDepthMapValue + dt) - currentDepthMapValue) - ((currentTexCoords + deltaTexCoords).y - currentTexCoords.y ));
	coord = mix(currentTexCoords + deltaTexCoords, currentTexCoords, x);
	*/
	
	// done
	return coord;
}

void main()
{
	// DUMMY OUTPUT: all fragments are OPAQUE GREEN
//	rtFragColor = vec4(0.0, 1.0, 0.0, 1.0);

	vec4 diffuseColor = vec4(0.0), specularColor = diffuseColor, dd, ds;
	
	// view-space tangent basis
	vec4 tan_view = normalize(vTangentBasis_view[0]);
	vec4 bit_view = normalize(vTangentBasis_view[1]);
	vec4 nrm_view = normalize(vTangentBasis_view[2]);
	vec4 pos_view = vTangentBasis_view[3];
	
	// view-space view vector
	vec4 viewVec = normalize(kEyePos - pos_view);
	
	// ****Done:
	//	-> convert view vector into tangent space
	//		(hint: the above TBN bases convert tangent to view, figure out 
	//		an efficient way of representing the required matrix operation)
	// tangent-space view vector
	vec3 viewVec_tan = vec3( 0.0, 0.0, 0.0 );

	//convert viewVec to tangent space - .xyz and right to left order important!
	viewVec_tan = transpose(mat3(tan_view.xyz,
							     bit_view.xyz,
							     nrm_view.xyz)) * viewVec.xyz;
	
	// parallax occlusion mapping
	vec3 texcoord = vec3(vTexcoord_atlas.xy, uSize);
	texcoord = calcParallaxCoord(texcoord, viewVec_tan, 256);
	
	// read and calculate view normal
	vec4 sample_nm = texture(uTex_nm, texcoord.xy);
	nrm_view = mat4(tan_view, bit_view, nrm_view, kEyePos)
		* vec4((sample_nm.xyz * 2.0 - 1.0), 0.0);
	
	int i;
	for (i = 0; i < uCount; ++i)
	{
		calcPhongPoint(dd, ds, viewVec, pos_view, nrm_view, uColor, 
			uPointLight[i].viewPos, uPointLight[i].radiusInfo,
			uPointLight[i].color);
		diffuseColor += dd;
		specularColor += ds;
	}

	vec4 sample_dm = texture(uTex_dm, texcoord.xy);
	vec4 sample_sm = texture(uTex_sm, texcoord.xy);
	rtFragColor = sample_dm * diffuseColor + sample_sm * specularColor;
	rtFragColor.a = sample_dm.a;
	
	// MRT
	rtFragNormal = vec4(nrm_view.xyz * 0.5 + 0.5, 1.0);
	rtFragDiffuse = sample_dm * diffuseColor;
	//rtFragSpecular = sample_sm * specularColor;
	rtFragPosition = vec4(pos_view.xyz/pos_view.w, 1.0);
	
	// DEBUGGING
	//rtFragColor.rgb = texcoord;
}