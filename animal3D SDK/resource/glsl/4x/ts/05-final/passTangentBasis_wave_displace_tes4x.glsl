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
	
	passTangentBasis_displace_tes4x.glsl
	Pass interpolated and displaced tangent basis.
*/

#version 450

// ****Done: 
//	-> declare inbound and outbound varyings to pass along vertex data
//		(hint: inbound matches TCS naming and is still an array)
//		(hint: outbound matches GS/FS naming and is singular)
//	-> copy varying data from input to output
//	-> displace surface along normal using height map, project result
//		(hint: start by testing a "pass-thru" shader that only copies 
//		gl_Position from the previous stage to get the hang of it)

layout (triangles, equal_spacing) in;

//Vertex -> Tess Control -> *Tess Eval* -> Fragment
in vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData_tess[];

out vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
} vVertexData;

uniform sampler2D uTex_hm;

uniform float uTime;

const float waveAmplitude = 2;
const float waveSpeed = 0.5;
const float waveLength = 0.5;
void main()
{
	//References	- https://stackoverflow.com/questions/24166446/glsl-tessellation-displacement-mapping
	//				- Blue book
	//				- http://ogldev.atspace.co.uk/www/tutorial30/tutorial30.html
	//				- https://web.engr.oregonstate.edu/~mjb/cs519/Handouts/tessellation.1pp.pdf
	// get weighted sum position of three input coordinates
	vec4 p0 = gl_TessCoord.x * gl_in[0].gl_Position;
    vec4 p1 = gl_TessCoord.y * gl_in[1].gl_Position;
    vec4 p2 = gl_TessCoord.z * gl_in[2].gl_Position;
    vec4 pos = p0 + p1 + p2;

	// get weighted sum of tangent
	vec4 tan0 = gl_TessCoord.x * vVertexData_tess[0].vTangentBasis_view[0];
    vec4 tan1 = gl_TessCoord.y * vVertexData_tess[1].vTangentBasis_view[0];
    vec4 tan2 = gl_TessCoord.z * vVertexData_tess[2].vTangentBasis_view[0];
    vec4 tangent = normalize(tan0 + tan1 + tan2);

	// get weighted sum of bitangent
	vec4 bit0 = gl_TessCoord.x * vVertexData_tess[0].vTangentBasis_view[1];
    vec4 bit1 = gl_TessCoord.y * vVertexData_tess[1].vTangentBasis_view[1];
    vec4 bit2 = gl_TessCoord.z * vVertexData_tess[2].vTangentBasis_view[1];
    vec4 bitangent = normalize(bit0 + bit1 + bit2);

	// get weighted sum of normal
	vec4 nrm0 = gl_TessCoord.x * vVertexData_tess[0].vTangentBasis_view[2];
    vec4 nrm1 = gl_TessCoord.y * vVertexData_tess[1].vTangentBasis_view[2];
    vec4 nrm2 = gl_TessCoord.z * vVertexData_tess[2].vTangentBasis_view[2];
    vec4 normal = normalize(nrm0 + nrm1 + nrm2);

	// get weighted sum of pos_view - might not make mathematical sense
	vec4 pos_view0 = gl_TessCoord.x * vVertexData_tess[0].vTangentBasis_view[3];
    vec4 pos_view1 = gl_TessCoord.y * vVertexData_tess[1].vTangentBasis_view[3];
    vec4 pos_view2 = gl_TessCoord.z * vVertexData_tess[2].vTangentBasis_view[3];
    vec4 pos_view = pos_view0 + pos_view1 + pos_view2;

	// get weighted sum of texcoord to pass on
    vec4 tc0 = gl_TessCoord.x * vVertexData_tess[0].vTexcoord_atlas;
    vec4 tc1 = gl_TessCoord.y * vVertexData_tess[1].vTexcoord_atlas;
    vec4 tc2 = gl_TessCoord.z * vVertexData_tess[2].vTexcoord_atlas;
    vec4 tessTexCoord = tc0 + tc1 + tc2;

	//calculate pos displacement
    float heightmapDisplaceY = texture(uTex_hm, tessTexCoord.xy).r;
	pos += normal * (heightmapDisplaceY * 0.3f);

	//calculate wave pos displacement
	float k = 2 * 3.14 / waveLength;
	float f = k * (gl_TessCoord.x - waveSpeed * uTime);
    //float waveHeight = 2 * sin(k * ((pos.x/pos_view.x) - 1 * uTime));
	float waveDisplaceY = waveAmplitude * sin(f);

    //pos += normal * (heightmapDisplaceY * 0.3f) * (waveDisplaceY * 0.6f);

	pos += normal * (waveDisplaceY * 0.6f);

	//TO-DO:
	// -> Correct Tangent, Bitangent, Normal for wave positions.

	//vec3 waveTangent = normalize(vec3(1, k * waveAmplitude * cos(f),0));
	normal = normalize(vec4(-waveAmplitude * waveSpeed * cos(f),0.0,1.0,1.0));
	bitangent = normalize(vec4(1,0, waveAmplitude * waveSpeed * cos(f),0.0));
	tangent = vec4(cross(normal.xyz, bitangent.xyz), 0);
	//tangent = normalize(vec4(1,0, waveAmplitude * waveSpeed * cos(f),0.0));

	//Pass data
	vVertexData.vTangentBasis_view = mat4(tangent,bitangent,normal,pos_view);
	vVertexData.vTexcoord_atlas = tessTexCoord;

	//output
	gl_Position = pos;   
}