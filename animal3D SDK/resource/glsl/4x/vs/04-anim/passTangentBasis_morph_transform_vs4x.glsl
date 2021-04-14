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
	
	passTangentBasis_morph_transform_vs4x.glsl
	Calculate and pass morphed tangent basis.
*/

#version 450

#define MAX_OBJECTS 128

#define MORPH_TARGETS 5

// ****Done: 
//	-> declare morph target attributes
//	-> declare and implement morph target interpolation algorithm
//	-> declare interpolation time/param/keyframe uniform
//	-> perform morph target interpolation using correct attributes
//		(hint: results can be stored in local variables named after the 
//		complete tangent basis attributes provided before any changes)


//layout (location = 0) in vec4 aPosition;
//layout (location = 2) in vec3 aNormal;
//layout (location = 8) in vec4 aTexcoord;
//layout (location = 10) in vec3 aTangent;
//layout (location = 11) in vec3 aBitangent;


struct sModelMatrixStack
{
	mat4 modelMat;						// model matrix (object -> world)
	mat4 modelMatInverse;				// model inverse matrix (world -> object)
	mat4 modelMatInverseTranspose;		// model inverse-transpose matrix (object -> world skewed)
	mat4 modelViewMat;					// model-view matrix (object -> viewer)
	mat4 modelViewMatInverse;			// model-view inverse matrix (viewer -> object)
	mat4 modelViewMatInverseTranspose;	// model-view inverse transpose matrix (object -> viewer skewed)
	mat4 modelViewProjectionMat;		// model-view-projection matrix (object -> clip)
	mat4 atlasMat;						// atlas matrix (texture -> cell)
};

struct sMorphTarget
{
	vec4 position;
	vec3 normal;//	float nPad;
	vec3 tangent;//	float tPad;
};

layout (location = 0) in sMorphTarget aMorphTarget[MORPH_TARGETS];
layout (location = 15) in vec4 aTexcoord; // -> Demostate load ~333 -> "the final attribute will be for texture coordinates"

uniform ubTransformStack
{
	sModelMatrixStack uModelMatrixStack[MAX_OBJECTS];
};

uniform int uIndex;
uniform float uTime;

out vbVertexData {
	mat4 vTangentBasis_view;
	vec4 vTexcoord_atlas;
};

flat out int vVertexID;
flat out int vInstanceID;

mat4 CreateLerpedMorphTargetTBN(sMorphTarget start, sMorphTarget goal, float param)
{
	//referenced https://en.cppreference.com/w/cpp/numeric/lerp for lerp equation ( a + t(b - a)

	//lerp tangent, normal, and get bitangent as their cross product.
	vec3 lerpTangent = start.tangent + param * (goal.tangent - start.tangent);
	vec3 lerpNormal = start.normal + param * (goal.normal - start.normal);
	vec3 lerpBitangent = cross(lerpTangent, lerpNormal);

	//assemble and output matrix
	mat4 lerpedMorphTarget = mat4(lerpTangent, 0.0,
								  lerpBitangent,0.0,
								  lerpNormal, 0.0,
								  vec4(0.0));
	return lerpedMorphTarget;
}

vec4 lerpVec4(vec4 start, vec4 goal, float param)
{
	vec4 lerpPosition = start + param * (goal - start);
	return lerpPosition;
}

void main()
{
	sModelMatrixStack t = uModelMatrixStack[uIndex];

	//recreate index and param from uTime
	// -> Animate-idle-render sends uTime as Index + Param on line ~252
	int index = int (uTime);
	float param = uTime - index;

	//lerp position
	vec4 aPosition = lerpVec4(aMorphTarget[index].position, aMorphTarget[(index + 1) % MORPH_TARGETS].position, param);

	//create Lerped TBN
	vTangentBasis_view = t.modelViewMatInverseTranspose * CreateLerpedMorphTargetTBN(aMorphTarget[index], aMorphTarget[(index + 1) % MORPH_TARGETS], param);

	//outputs
	vTangentBasis_view[3] = t.modelViewMat * aPosition;
	gl_Position = t.modelViewProjectionMat * aPosition;
	
	vTexcoord_atlas = t.atlasMat * aTexcoord;

	vVertexID = gl_VertexID;
	vInstanceID = gl_InstanceID;
}
