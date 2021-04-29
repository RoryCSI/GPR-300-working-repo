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

#define MAX_LIGHTS 1024

//in vbVertexData {
//	mat4 vTangentBasis_view;
//	vec4 vTexcoord_atlas;
//};

in vec4 vTexcoord_atlas;

struct sPointLight
{
	vec4 viewPos, worldPos, color, radiusInfo;
};

uniform ubLight
{
	sPointLight uPointLight[MAX_LIGHTS];
};

uniform int uCount;

uniform vec4 uColor;

uniform sampler2D uImage04; //Depth
uniform sampler2D uImage05; //Normals
uniform sampler2D uImage06; //Color
uniform sampler2D uImage07; //Diffuse
uniform sampler2D uImage08; //Specular


const vec4 kEyePos = vec4(0.0, 0.0, 0.0, 1.0);

layout (location = 0) out vec4 rtFragColor;
layout (location = 1) out vec4 rtFragNormal;

uniform mat4 uP;
uniform mat4 uP_inv;

void calcPhongPoint(out vec4 diffuseColor, out vec4 specularColor, in vec4 eyeVec,
	in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor);

struct RayTraceOutput
{
	bool Hit;
	vec2 UV;
};

RayTraceOutput raytrace(in vec4 reflPosition, in vec4 reflDir)
{
	// The Current Position in 3D
	vec4 curPos = vec4(0);
 
	// The Current UV
	vec4 curUV = vec4(0);
 
	// The Current Length
	float curLength = 1;

	RayTraceOutput ray;
	ray.Hit = false;
	ray.UV = curUV.xy;

	// Now loop
	int loops = 64;
    for (int i = 0; i < loops; i++)
    {
        // Has it hit anything yet
        if (ray.Hit == false)
        {
            // Update the Current Position of the Ray
           curPos = reflPosition + reflDir * curLength ;
            // Get the UV Coordinates of the current Ray
            curUV = uP * curPos;
            // The Depth of the Current Pixel
            float curDepth = texture(uImage04, curUV.xy).r;
			int SAMPLE_COUNT = 64;
			int RAND_SAMPLES[] = {1,1,1,1,1,1,1};
			int DepthCheckBias = 64;
			for (int i = 0; i < SAMPLE_COUNT; i++)
            {
                if (abs(curUV .z - curDepth) < DepthCheckBias)
                {
                    // If it's hit something, then return the UV position
                    ray.Hit = true;
                    ray.UV = curUV.xy;
                    break;
                }
                //curDepth = texture(uImage04, curUV.xy + (RAND_SAMPLES[i])).r;
            }

            // Get the New Position and Vector
            vec4 newPos = texture(uImage08, curUV.xy);// curDepth );
			newPos.z = curDepth;
            curLength = length(reflPosition - newPos);
        }
    }
	return ray;
}

void main() 
{
	float depth = texture(uImage04, vTexcoord_atlas.xy).z;
	
	//vec4 reflPosition = texture(uImage08, vTexcoord_atlas.xy);
	//reflPosition = reflPosition/reflPosition.w;
	vec4 reflPosition = vTexcoord_atlas * uP;
	reflPosition.z = texture(uImage04, vTexcoord_atlas.xy).r;
	reflPosition = reflPosition/reflPosition.w;

	vec4 normal = texture(uImage05, vTexcoord_atlas.xy);
	//normal = 2.0 * normal - 1.0;

	vec4 viewDir = normalize(reflPosition - kEyePos);
	vec4 reflectDir = normalize(reflect(viewDir, normalize(normal)));

	RayTraceOutput ray = raytrace(reflPosition, reflectDir);
	
		if (ray.Hit == true)
		{
            // Fade at edges
			int EdgeCutOff = 4;
			float amount = 1;
			if (ray.UV.y < EdgeCutOff * 2)
				amount *= (ray.UV.y / EdgeCutOff / 2);

			rtFragColor = vec4(ray.UV.xy, 0, amount);
		}

	//rtFragColor = normal;// * vec4(1,0,0,1);
	//rtFragColor = reflPosition;
}