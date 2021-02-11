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
	
	drawLambert_fs4x.glsl
	Output Lambertian shading.
*/
///////////////  Edited by Rory Beebout   ////////////////
#version 450

// ****TO-DO: 
//	-> declare varyings to receive lighting and shading variables
//	-> declare lighting uniforms
//		(hint: in the render routine, consolidate lighting data 
//		into arrays; read them here as arrays)
//	-> calculate Lambertian coefficient
//	-> implement Lambertian shading model and assign to output
//		(hint: coefficient * attenuation * light color * surface color)
//	-> implement for multiple lights
//		(hint: there is another uniform for light count)

layout (location = 0) out vec4 rtFragColor;

in vec4 vPosition;
in vec4 vNormal;
in vec2 vTexcoord;
uniform vec4 uLightPosition[];
uniform vec4 uLightColor[];
uniform float uLightRadius[];
uniform vec4 uColor;
uniform sampler2D uSampler;


void main()
{
	//calculate lambert coeffecient
	vec4 N = normalize(vNormal);
	vec4 L = normalize(uLightPosition[0] - vPosition);
	float kd = dot(N, L);
	kd = max(kd, 0.0);

	rtFragColor = kd * uLightColor[0] * texture2D(uSampler, vTexcoord) * uColor;
}