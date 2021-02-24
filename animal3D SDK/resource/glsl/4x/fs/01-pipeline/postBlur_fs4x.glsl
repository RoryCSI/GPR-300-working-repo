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

	postBlur_fs4x.glsl
	Gaussian blur.
*/

#version 450

// ****TO-DO:
//	-> declare texture coordinate varying and input texture
//	-> declare sampling axis uniform (see render code for clue)
//	-> declare Gaussian blur function that samples along one axis
//		(hint: the efficiency of this is described in class)

//layout (binding = 0) uniform sampler2D uTex_dm;
layout (binding = 0) uniform sampler2D hdr_image;
//layout (binding = 1) uniform sampler2D bloom_image;


in vec2 vTexcoord;
//uniform sampler2D uTex_dm;
uniform vec2 uAxis;

uniform float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

layout (location = 0) out vec4 rtFragColor;

void main()
{

	vec4 c = vec4(0.0);
	c = texture2D(hdr_image, vTexcoord) * weight[0];
	for (int i = 1; i < 5; i++)
	{
		c += texture2D(hdr_image, vTexcoord + uAxis*i) * weight[i];
		c += texture2D(hdr_image, vTexcoord - uAxis*i) * weight[i];
	}

	rtFragColor = c;
}
