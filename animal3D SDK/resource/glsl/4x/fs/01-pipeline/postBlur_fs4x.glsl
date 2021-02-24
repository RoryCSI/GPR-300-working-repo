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

layout (binding = 0) uniform sampler2D uTex_dm;
//layout (binding = 0) uniform sampler2D hdr_image;
//layout (binding = 1) uniform sampler2D bloom_image;


in vec2 vTexcoord;
//uniform sampler2D uTex_dm;
uniform vec2 uAxis;

uniform float exposure = 0.9;
uniform float bloom_factor = 1.0;
uniform float scene_factor = 1.0;

layout (location = 0) out vec4 rtFragColor;

void main()
{
	// DUMMY OUTPUT: all fragments are OPAQUE AQUA
	//rtFragColor = vec4(0.0, 1.0, 0.5, 1.0);

	vec4 c = vec4(0.0);
	c += texture2D(uTex_dm, vTexcoord);
	c += texture2D(uTex_dm, vTexcoord+uAxis);
	c += texture2D(uTex_dm, vTexcoord-uAxis);
	c = c/3.0;

	rtFragColor = c;

	//rtFragColor = (texture(uTex_dm, vTexcoord) + texture(uTex_dm, vTexcoord+uAxis)/2.0f);
}
