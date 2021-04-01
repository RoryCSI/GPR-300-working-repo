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
	
	tessTriTangentBasis_tcs4x.glsl
	Tessellation control passing tangent basis (pass-thru).
*/

#version 450

// ****Done: 
//	-> declare inbound and outbound varyings to pass along vertex data
//		(hint: inbound matches VS naming but is now an array)
//		(hint: outbound matches TES naming and is also an array)
//	-> copy varying data from input to output
//		(hint: read the documentation for tessellation for key terms)
//	-> set tessellation levels, adjust as needed
//		(hint: feel free to ignore the uniforms and experiment)

layout (vertices = 3) out;

//Vertex -> *Tess Control* -> Tess Eval -> Fragment
in vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData[];

//Vertex -> *Tess Control* -> Tess Eval -> Fragment
out vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData_tess[];


uniform vec3 uLevelOuter;
uniform float uLevelInner;

void main()
{

	//Pass on vertexData
	vVertexData_tess[gl_InvocationID].vTangentBasis_view = vVertexData[gl_InvocationID].vTangentBasis_view;
	vVertexData_tess[gl_InvocationID].vTexcoord_atlas = vVertexData[gl_InvocationID].vTexcoord_atlas;

	//output
	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

	//set tesselation levels
	gl_TessLevelOuter[0] = uLevelOuter[0];
	gl_TessLevelOuter[1] = uLevelOuter[1];
	gl_TessLevelOuter[2] = uLevelOuter[2];
	gl_TessLevelInner[0] = uLevelInner;
}
