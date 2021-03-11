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
	
	drawGBuffers_fs4x.glsl
	Output g-buffers for use in future passes.
*/

#version 450

// ****Done:
//	-> declare view-space varyings from vertex shader
//	-> declare MRT for pertinent surface data (incoming attribute info)
//		(hint: at least normal and texcoord are needed)
//	-> declare uniform samplers (at least normal map)
//	-> calculate final normal
//	-> output pertinent surface data

in vec4 vPosition;
in vec4 vNormal;
in vec4 vTexcoord;
in vec3 vTangent;
in vec4 vBiTangent;
in mat3 vTBN;

in vec4 vPosition_screen;

layout (location = 0) out vec4 rtTexcoord;
layout (location = 1) out vec4 rtNormal;
layout (location = 3) out vec4 rtPosition;

uniform sampler2D uTex_nm;

void main()
{
	rtTexcoord = vTexcoord;

	vec3 tangentNormal = texture(uTex_nm, vTexcoord.xy).xyz * 2.0 - 1.0; //Pull normal from normal map (Tangent space), stretch back to normal range (-1,1)
	vec4 finalNormal = vec4(vTBN * tangentNormal,0.0) * 0.5 + 0.5; //Convert to view space then squish again for proper g-buffer storage;
	rtNormal = finalNormal;

	rtPosition = vPosition_screen / vPosition_screen.w; //perspective divide
}
