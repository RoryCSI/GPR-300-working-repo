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
	
	drawSSR.glsl
	Output appropriate screen space reflections using specular.
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

uniform sampler2D uImage04; //Depth
uniform sampler2D uImage05; //Normals
uniform sampler2D uImage06; //Color
uniform sampler2D uImage07; //Diffuse
uniform sampler2D uImage08; //Specular

layout (location = 0) out vec4 rtFragColor;
layout (location = 1) out vec4 rtFragNormal;

uniform int uCount;
uniform vec4 uColor;
uniform mat4 uP;
uniform mat4 uP_inv;
uniform mat4 uPB_inv;
uniform mat4 uMVPB_other;
uniform mat4 uAtlas;

//refs
// - https://community.khronos.org/t/screen-space-reflections/69987
// - https://stackoverflow.com/questions/53457581/screen-space-reflections-artifacts
// - https://gamedev.stackexchange.com/questions/138717/screen-space-reflections-not-tracing-correctly-glsl

const int binarySearchCount = 10;
const int rayMarchCount = 30;
const float step = 0.05;
const float LLimiter = 0.2;
const float minRayStep = 0.2;

void calcPhongPoint(out vec4 diffuseColor, out vec4 specularColor, in vec4 eyeVec,
	in vec4 fragPos, in vec4 fragNrm, in vec4 fragColor,
	in vec4 lightPos, in vec4 lightRadiusInfo, in vec4 lightColor);

// linearize depth for arbitrary distance to make depth map more diverse
//  -> Leads to a more interesting reflection when linearized a certain way
float linearize_depth(float d,float zNear,float zFar)
{
    return zNear * zFar / (zFar + d * (zNear - zFar));
}

// reconstructs a fragPosition from the depth map, undoes bias projection, output viewspace.
vec3 getPosition(in vec2 texCoord) {
    float z = texture(uImage04, texCoord).r;
    vec4 position_screen = vec4(texCoord, linearize_depth(z,0.1,1), 1);// reassemble position from texcoord and linearized depth
    vec4 position_view = uPB_inv * position_screen; // undo bias projection
	position_view.xyz /= position_view.w; // perspective divide

    return position_view.xyz;
}

// After an intersection is found, step the depth again using a binary search for better accuracy
vec2 binarySearch(inout vec3 dir, inout vec3 hitCoord, inout float dDepth) 
{

    //declarations 
    float depth;
    vec4 projectedCoord;

    for(int i = 0; i < binarySearchCount; i++) {
        projectedCoord = uP * vec4(hitCoord, 1.0); // project from view-space
        projectedCoord.xy /= projectedCoord.w; // perspective divide
        projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5; // convert from -1,1 to 0,1

        depth = getPosition(projectedCoord.xy).z; // get depth at the projectedCoord

        dDepth = hitCoord.z - depth; // calculate difference of depths

        dir *= 0.5; // step 
        if(dDepth > 0.0) // step in correct direction
            hitCoord += dir;
        else
            hitCoord -= dir;    
    }

    projectedCoord = uP * vec4(hitCoord, 1.0); // project from view-space
    projectedCoord.xy /= projectedCoord.w; // perspective divide
    projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5; // convert from -1,1 to 0,1

    // return final projectedCoord
    return vec2(projectedCoord.xy);
}

// march a ray into the scene until it hits, or return vec2(-1,-1)
vec2 rayCast(vec3 dir, inout vec3 hitCoord, out float dDepth) 
{
    dir *= step;

    for (int i = 0; i < rayMarchCount; i++) 
    {
        hitCoord += dir; // step forward

        vec4 projectedCoord = uP * vec4(hitCoord, 1.0); // project from view-space
        projectedCoord.xy /= projectedCoord.w; // perspective divide
        projectedCoord.xy = projectedCoord.xy * 0.5 + 0.5; // convert from -1,1 to 0,1

        float depth = getPosition(projectedCoord.xy).z; // get depth at the projectedCoord
        dDepth = hitCoord.z - depth; // calculate difference of depths

        // if hit, binarySearch for more precision
        if((dir.z - dDepth) < 1 && dDepth <= 0.0) return binarySearch(dir, hitCoord, dDepth);
    }

    // missed
    return vec2(-1.0);
}

void main() 
{
    // can actually just be vTexcoord_atlas.xy in this case.
    vec2 texCoord = (inverse(uAtlas) * vTexcoord_atlas).xy;

    // sample reflectionStrength from Specular map
    float reflectionStrength = texture(uImage08, texCoord).r;

    // no reflection, rtFragColor will just be scene color
    if (reflectionStrength == 0) {
        rtFragColor = texture(uImage06, texCoord);
        return;
    }

    // sample normal
    vec3 normal = texture(uImage05, texCoord).xyz;
    // get view vector
    vec3 viewPos = getPosition(texCoord);

    // Reflection vector
    vec3 reflected = normalize(reflect(normalize(viewPos), normalize(normal)));

    // Ray cast
    vec3 hitPos = viewPos; // cameraPos - FragPos, but since we're in view space, cameraPos = 0,0,0, so simplifies
    float dDepth; // depth difference
    vec2 coords = rayCast(reflected * max(-viewPos.z, minRayStep), hitPos, dDepth); // coords to reflect from

    // sample colors
    vec4 blueColor = vec4(0.3,0.5,0.7,1); // blue for water
    vec3 color = texture(uImage06, coords.xy).rgb; // reflected color

    // if coords are good, mix with reflected color
    if (coords.xy != vec2(-1.0)) {
        rtFragColor = mix(texture(uImage06, texCoord), vec4(color, 1.0), reflectionStrength);
        return;
    }
    // specular enough, but not reflecting -> blue;
    rtFragColor = mix(texture(uImage06, texCoord), blueColor, reflectionStrength);    
}