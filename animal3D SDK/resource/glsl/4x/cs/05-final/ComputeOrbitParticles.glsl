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

layout(local_size_x = 128, local_size_y = 1,local_size_y = 1) in;

uniform float uTime;

layout (std430, binding = 0) buffer PositionBuffer {
	vec3 positions[];
};

void main() 
{
    const uint offset = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y;
	uint index = gl_GlobalInvocationID.x;
	vec3 computedPosition = positions[index];
	//vec4 computedVelocity = transforms[offset][1];

	 positions[index] = vec3(1,1,1);//computedPosition + vec3(0,555.1,0)*uTime;
	//transforms[offset][1] = vec4(0,sin(uTime),0,1);
}