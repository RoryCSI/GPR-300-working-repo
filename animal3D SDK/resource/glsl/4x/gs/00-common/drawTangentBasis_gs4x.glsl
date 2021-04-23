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
	
	drawTangentBases_gs4x.glsl
	Draw tangent bases of vertices and/or faces, and/or wireframe shapes, 
		determined by flag passed to program.
*/

#version 450

// ****Done: 
//	-> declare varying data to read from vertex shader
//		(hint: it's an array this time, one per vertex in primitive)
//	-> use vertex data to generate lines that highlight the input triangle
//		-> wireframe: one at each corner, then one more at the first corner to close the loop
//		-> vertex tangents: for each corner, new vertex at corner and another extending away 
//			from it in the direction of each basis (tangent, bitangent, normal)
//		-> face tangents: ditto but at the center of the face; need to calculate new bases
//	-> call "EmitVertex" whenever you're done with a vertex
//		(hint: every vertex needs gl_Position set)
//	-> call "EndPrimitive" to finish a new line and restart
//	-> experiment with different geometry effects

// (2 verts/axis * 3 axes/basis * (3 vertex bases + 1 face basis) + 4 to 8 wireframe verts = 28 to 32 verts)
#define MAX_VERTICES 32

layout (triangles) in;

layout (line_strip, max_vertices = MAX_VERTICES) out;

uniform int uFlag;
uniform float uSize;
uniform mat4 uP;

in vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData[];

out vec4 vColor;

void drawWireframe()
{
	//Line segment from 0 to 1 in yellow
	vColor = vec4(1.0,1.0,0.0,1.0);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[1].gl_Position;
	EmitVertex();
	EndPrimitive();

	//Line segment from 1 to 2 in magenta
	vColor = vec4(1.0,0.0,1.0,1.0);
	gl_Position = gl_in[1].gl_Position;
	EmitVertex();
	gl_Position = gl_in[2].gl_Position;
	EmitVertex();
	EndPrimitive();

	//Line segment from 2 to 0 in yellow, completing loop
	vColor = vec4(1.0,1.0,0.0,1.0);
	gl_Position = gl_in[2].gl_Position;
	EmitVertex();
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	EndPrimitive();
}

void drawVertexTangent()
{
	//declarations
	vec4 tan_view;
	vec4 bit_view;
	vec4 nrm_view;

	//Color red, draw line from vertex position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(1.0,0.0,0.0,1.0);
	tan_view = normalize(vVertexData[0].vTangentBasis_view[0]);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[0].gl_Position + uSize *  uP * tan_view;
	EmitVertex();
	EndPrimitive();

	//Color green, draw line from vertex position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(0.0,1.0,0.0,1.0);
	bit_view = normalize(vVertexData[0].vTangentBasis_view[1]);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[0].gl_Position + uSize *  uP * bit_view;
	EmitVertex();
	EndPrimitive();

	//Color blue, draw line from vertex position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(0.0,0.0,1.0,1.0);
	nrm_view = normalize(vVertexData[0].vTangentBasis_view[2]);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[0].gl_Position + uSize * uP * nrm_view;
	EmitVertex();
	EndPrimitive();
}
void drawFaceTangent()
{
	//Declarations
	vec4 tan_view;
	vec4 bit_view;
	vec4 nrm_view;

	//Calculate center of triangle
	vec4 faceCenterPos = (gl_in[0].gl_Position + gl_in[1].gl_Position + gl_in[2].gl_Position)/3;

	//Color red, draw line from center face position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(1.0,0.0,0.0,1.0);
	tan_view = normalize(vVertexData[0].vTangentBasis_view[0]);
	gl_Position = faceCenterPos;
	EmitVertex();
	gl_Position = faceCenterPos + uSize *  uP * tan_view;
	EmitVertex();
	EndPrimitive();

	//Color green, draw line from center face position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(0.0,1.0,0.0,1.0);
	bit_view = normalize(vVertexData[0].vTangentBasis_view[1]);
	gl_Position = faceCenterPos;
	EmitVertex();
	gl_Position = faceCenterPos + uSize *  uP * bit_view;
	EmitVertex();
	EndPrimitive();

	//Color blue, draw line from center face position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(0.0,0.0,1.0,1.0);
	nrm_view = normalize(vVertexData[0].vTangentBasis_view[2]);
	gl_Position = faceCenterPos;
	EmitVertex();
	gl_Position = faceCenterPos + uSize * uP * nrm_view;
	EmitVertex();
	EndPrimitive();

	//Color red, draw line from center face position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(1.0,0.0,0.0,1.0);
	tan_view = normalize(vVertexData[1].vTangentBasis_view[0]);
	gl_Position = faceCenterPos;
	EmitVertex();
	gl_Position = faceCenterPos + uSize *  uP * tan_view;
	EmitVertex();
	EndPrimitive();

	//Color green, draw line from center face position to position at end of tan vector, multiply uSize and uP to shrink and convert to clip
	vColor = vec4(0.0,1.0,0.0,1.0);
	bit_view = normalize(vVertexData[2].vTangentBasis_view[1]);
	gl_Position = faceCenterPos;
	EmitVertex();
	gl_Position = faceCenterPos + uSize *  uP * bit_view;
	EmitVertex();
	EndPrimitive();
}
void main()
{
	//There's a cleverer way to math this, given the way uFlag is setup
	//uFlag is n * 4 for wireframe
	if (uFlag % 4 == 0)
	{
		drawWireframe();
	}
	//uFlag is n * 3 for tangent
	if (uFlag % 3 == 0)
	{
		drawFaceTangent();
		drawVertexTangent();
	}
	//uFlag must be both tangent and wireframe
	if (uFlag >= 7)
	{
		drawWireframe();
		drawVertexTangent();
		drawFaceTangent();
	}
	
}