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
	
	drawPhongPointLight_fs4x.glsl
	Output Phong shading components while drawing point light volume.
*/

#version 450

#define MAX_LIGHTS 1024

// ****TO-DO:
//	-> declare biased clip coordinate varying from vertex shader
//	-> declare point light data structure and uniform block
//	-> declare pertinent samplers with geometry data ("g-buffers")
//	-> calculate screen-space coordinate from biased clip coord
//		(hint: perspective divide)
//	-> use screen-space coord to sample g-buffers
//	-> calculate view-space fragment position using depth sample
//		(hint: same as deferred shading)
//	-> calculate final diffuse and specular shading for current light only

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

flat in int vInstanceID;

//layout (location = 0) out vec4 rtFragColor;
layout (location = 0) out vec4 rtDiffuseLight;
layout (location = 1) out vec4 rtSpecularLight;

in vec4 vBiasedClipPosition;

uniform sampler2D uImage00; //Diffuse atlas
uniform sampler2D uImage01; //Specular atlas
uniform sampler2D uImage02;
uniform sampler2D uImage04; //Scene texcoord
uniform sampler2D uImage05; //Scene normal
uniform sampler2D uImage07; //Scene depth

void calcPhongPoint(
	out vec4 diffuseColor, out vec4 specularColor,
	in vec4 eyeVec, in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor
);

uniform mat4 uPB_inv;


void main()
{
	vec4 screenSpaceCoord =  vBiasedClipPosition / vBiasedClipPosition.w;

	//vec4 sceneTexcoord = texture(uImage04, screenSpaceCoord.xy);

	vec4 diffuseSample = texture(uImage00, screenSpaceCoord.xy); //Grab diffuse color using just calculated sceneTexcoord
	vec4 specularSample = texture(uImage01, screenSpaceCoord.xy); //Grab specular color using just calculated sceneTexcoord

	//rebuilding screen position to avoid precision loss
	vec4 position_screen = screenSpaceCoord; //get texture xy
	position_screen.z = texture(uImage07, screenSpaceCoord.xy).r; //fill in z from the depth buffer to complete the position

	vec4 position_view = uPB_inv * position_screen; //undo bias projection
	position_view /= position_view.w; //perspective divide - still division

	vec4 normal_view = texture(uImage05, screenSpaceCoord.xy); //pull normals from texture
	normal_view = (normal_view - 0.5) * 2.0; //restore from color(0,1) to normal (-1,1) range
	//normal_view = vec4(1,1,1,1);

	vec4 diffuse;// = vec4(0.0);
	vec4 specular;// = vec4(0.0);

	//CommonUtil Phong Function 
	calcPhongPoint(diffuse, specular, //Output results into diffuse, specular
	normalize(uPointLightData[vInstanceID].position - position_view), position_view, normal_view, diffuseSample,//eyeVec, fragPos, fragNrm, fragColor
	uPointLightData[vInstanceID].position, //light pos,
	vec4(uPointLightData[vInstanceID].radius, uPointLightData[vInstanceID].radiusSq, uPointLightData[vInstanceID].radiusInv, uPointLightData[vInstanceID].radiusInvSq),//light radius
	uPointLightData[vInstanceID].color);//light color
	
	rtDiffuseLight = diffuse;
	rtSpecularLight = specular;

}
