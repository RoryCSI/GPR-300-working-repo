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
	
	ComputeOrbitParticles.glsl
	Calculate particle new positions with velocity and write over buffer.
*/

#version 450

layout(local_size_x = 128, local_size_y = 1,local_size_y = 1) in;

uniform float uTime;

layout (std430, binding = 0) buffer PositionBuffer {
	vec3 positions[];
};

void main() 
{
	// work group divisions -> offset is just .x, since workgroups are 128, 1,1
	uint index = gl_GlobalInvocationID.x;


	// Physics calculations 
	//	-> Incomplete, unable to successfully read from buffer.
	vec3 computedPosition = positions[index];

	//output
	positions[index] = computedPosition + vec3(0,0.1,0)*uTime;
}