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
	
	postDeferredLightingComposite_fs4x.glsl
	Composite results of light pre-pass in deferred pipeline.
*/

#version 450

// ****TO-DO:
//	-> declare samplers containing results of light pre-pass
//	-> declare samplers for texcoords, diffuse and specular maps
//	-> implement Phong sum with samples from the above
//		(hint: this entire shader is about sampling textures)

in vec4 vTexcoord_atlas;

layout (location = 0) out vec4 rtFragColor;

uniform sampler2D uImage00; //Diffuse texture atlas
uniform sampler2D uImage01; //Specular texture atlas

uniform sampler2D uImage02; //pre-pass diffuse output
uniform sampler2D uImage03; //pre-pass specular output

uniform sampler2D uImage04; //Texcoords
uniform sampler2D uImage05; //Normals
uniform sampler2D uImage07; //Depth texture

void main()
{
	
	vec4 sceneTexcoord = texture(uImage04, vTexcoord_atlas.xy);

	//vec4 scenePosition = vec4(texture(uImage04, vTexcoord_atlas.xy).xy, texture(uImage07, vTexcoord_atlas.xy).z, 1.0);

	//vec4 normal = texture(uImage05, vTexcoord_atlas.xy);

	vec4 diffuseColor = texture(uImage00, sceneTexcoord.xy);
	vec4 specularColor = texture(uImage01, sceneTexcoord.xy);

	vec4 rtDiffuseLight = texture(uImage02, sceneTexcoord.xy);
	vec4 rtSpecularLight = texture(uImage03, sceneTexcoord.xy);

	//(diffuse light)(diffuse color) + (specular light)(specular color) + (dim ambient constant color).
	rtFragColor = (diffuseColor * rtDiffuseLight) + (specularColor * rtSpecularLight) + vec4(0.1,0.1,0.1,1.0) ;
	//rtFragColor = diffuseColor * rtDiffuseLight;
	//rtFragColor = rtDiffuseLight;
	rtFragColor.a = diffuseColor.a;
}
