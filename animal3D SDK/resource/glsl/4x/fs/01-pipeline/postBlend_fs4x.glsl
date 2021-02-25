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

	postBlend_fs4x.glsl
	Blending layers, composition.
*/

#version 450

// ****Done:
//	-> declare texture coordinate varying and set of input textures
//	-> implement some sort of blending algorithm that highlights bright areas
//		(hint: research some Photoshop blend modes)

uniform sampler2D uTex_dm;
uniform sampler2D uTex_sm;
uniform sampler2D uTex_nm;
uniform sampler2D uTex_hm;

uniform float exposure = 1.5;

in vec2 vTexcoord;

layout (location = 0) out vec4 rtFragColor;

void main()
{
	//Sample each finished stage of (Bright, Blur H, Blur V)
	vec3 original = texture(uTex_dm,vTexcoord).rgb;
	vec3 bloom = texture(uTex_hm,vTexcoord).rgb;
	vec3 bloom1 = texture(uTex_sm,vTexcoord).rgb;
	vec3 bloom2 = texture(uTex_nm,vTexcoord).rgb;

	//Simple additive;
	original += bloom + bloom1 + bloom2;

	vec3 result = vec3(1.0) - exp(-original * exposure); //Blue Book page 480
	rtFragColor = vec4(result,1.0);
}
