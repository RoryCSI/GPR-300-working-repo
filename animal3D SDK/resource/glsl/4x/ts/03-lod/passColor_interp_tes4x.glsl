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
	
	passColor_interp_tes4x.glsl
	Pass color, outputting result of interpolation.
*/

#version 450

// ****Done: 
//	-> declare uniform block for spline waypoint and handle data
//	-> implement spline interpolation algorithm based on scene object's path
//	-> interpolate along curve using correct inputs and project result

layout (isolines, equal_spacing) in;

uniform ubCurve
{
	vec4 uCurveWaypoint[32];
	vec4 uCurveTangentp[32];
};

uniform int uCount;

uniform mat4 uP;

out vec4 vColor;

void main()
{
	// gl_TessCoord for isolines:
	// [0] = which line [0, 1)
	// [1] = subdivision [0, 1]

	// in this example:
	// gl_Tesscord[0] = interpolation parameter
	// gl_TessCoord[1] = 0

	int v0 = gl_PrimitiveID; // index for current waypoint
	int vPrev = (v0 + uCount - 1) % uCount; // index for previous waypoint
	int v1 = (v0 + 1) % uCount; // index for next waypoint
	int vNext = (v0 + 2) % uCount; // index for next-next waypoint
	float u = gl_TessCoord[0]; //hold interpolation parameter
	
	//interpolate but not *splinely*
	//vec4 p = mix(uCurveWaypoint[v0],
	//			uCurveWaypoint[v1],
	//			u);

	//prepare u^n's for equation
	float u2 = u * u;
    float u3 = u2 * u;

	//calculate point modifier coefficients
	//using	integrated mat4 M (0, 2, 0, 0
	//						  -1, 0, 1, 0
	//						   2, -5, 4, -1
	//						  -1, 3, -3, 1)
	//credit to https://www.codeproject.com/Articles/30838/Overhauser-Catmull-Rom-Splines-for-Camera-Animatio
	//          https://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
	//			https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
	//for catmullRom assistance
    float c1 = 0.5 * (  -u3 + 2*u2 - u);
    float c2 = 0.5 * ( 3*u3 - 5*u2 + 2);
    float c3 = 0.5 * (-3*u3 + 4*u2 + u);
    float c4 = 0.5 * (   u3 -   u2    );

	//calculate final position
	vec4 p = c1 * uCurveWaypoint[vPrev] +
			 c2 * uCurveWaypoint[v0] + 
			 c3 * uCurveWaypoint[v1] + 
			 c4 * uCurveWaypoint[vNext];

	gl_Position = uP * p;

	vColor = vec4(0.5, 1.0 - u, u, 1.0);
}
