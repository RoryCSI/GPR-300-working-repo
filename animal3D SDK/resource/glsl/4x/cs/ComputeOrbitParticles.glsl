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
uniform mat4 uPB_inv;
uniform mat4 uMVPB_other;
uniform mat4 uAtlas;

void calcPhongPoint(out vec4 diffuseColor, out vec4 specularColor, in vec4 eyeVec,
	in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor);

//refs
// - https://community.khronos.org/t/screen-space-reflections/69987
// - https://stackoverflow.com/questions/53457581/screen-space-reflections-artifacts
// - https://gamedev.stackexchange.com/questions/138717/screen-space-reflections-not-tracing-correctly-glsl

const int binarySearchCount = 10;
const int rayMarchCount = 30;
const float step = 0.05;
const float LLimiter = 0.2;
const float minRayStep = 0.2;

vec3 getPosition(in vec2 texCoord) {
    float z = texture(uImage04, texCoord).w;

    return vec3(texCoord, texture(uImage04, texCoord).z);
}

vec2 binarySearch(inout vec3 dir, inout vec3 hitCoord, inout float dDepth) {
    float depth;

    vec4 projectedCoord;

    for(int i = 0; i < binarySearchCount; i++) {
        projectedCoord = uP * vec4(hitCoord, 1.0);
        projectedCoord.xy /= projectedCoord.w;
        projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5;

        depth = getPosition(projectedCoord.xy).z;

        dDepth = hitCoord.z - depth;

        dir *= 0.5;
        if(dDepth > 0.0)
            hitCoord += dir;
        else
            hitCoord -= dir;    
    }

    projectedCoord = uP * vec4(hitCoord, 1.0);
    projectedCoord.xy /= projectedCoord.w;
    projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5;

    return vec2(projectedCoord.xy);
}

vec2 rayCast(vec3 dir, inout vec3 hitCoord, out float dDepth) {
    dir *= step;

    for (int i = 0; i < rayMarchCount; i++) {
        hitCoord += dir;

        vec4 projectedCoord = uP * vec4(hitCoord, 1.0);
        projectedCoord.xy /= projectedCoord.w;
        projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5; 

        float depth = getPosition(projectedCoord.xy).z;
        dDepth = hitCoord.z - depth;

        if((dir.z - dDepth) < 1.2 && dDepth <= 0.0) return binarySearch(dir, hitCoord, dDepth);
    }

    return vec2(-1.0);
}

void main() {
    vec2 texCoord = (inverse(uAtlas) * vTexcoord_atlas).xy;

    float reflectionStrength = texture(uImage08, texCoord).r;
    //reflectionStrength = 0.5;

    if (reflectionStrength == 0) {
        rtFragColor = texture(uImage06, texCoord);
        return;
    }

    vec3 normal = texture(uImage05, texCoord).xyz;
    vec3 viewPos = -getPosition(texCoord);


    // Reflection vector
    vec3 reflected = normalize(reflect(normalize(viewPos), normalize(normal)));

    // Ray cast
    vec3 hitPos = viewPos;
    float dDepth; 
    vec2 coords = rayCast(reflected * max(-viewPos.z, minRayStep), hitPos, dDepth);

    //float L = length(getPosition(coords) - viewPos);
    //L = clamp(L * LLimiter, 0, 1);
    float error = 1;// - L;

    vec4 blueColor = vec4(0,0.1,0.2,1);
    vec3 color = texture(uImage06, coords.xy).rgb * error;

    if (coords.xy != vec2(-1.0)) {
        rtFragColor = mix(texture(uImage06, texCoord), vec4(color, 1.0), reflectionStrength);
        return;
    }
    //rtFragColor = mix(texture(uImage06, texCoord), blueColor, reflectionStrength);
    //rtFragColor = texture(uImage08, vTexcoord_atlas.xy);
    
}