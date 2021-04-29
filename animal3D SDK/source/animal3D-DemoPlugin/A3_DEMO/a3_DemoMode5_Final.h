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

	a3_DemoMode5_Final.h
	Demo mode interface: animated objects scene.

	********************************************
	*** THIS IS ONE DEMO MODE'S HEADER FILE  ***
	********************************************
*/

#ifndef __ANIMAL3D_DEMOMODE5_FINAL_H
#define __ANIMAL3D_DEMOMODE5_FINAL_H


//-----------------------------------------------------------------------------

#include "_a3_demo_utilities/a3_DemoSceneObject.h"

#include "_animation/a3_Hierarchy.h"


//-----------------------------------------------------------------------------

#ifdef __cplusplus
extern "C"
{
#else	// !__cplusplus
typedef struct a3_DemoMode5_Final						a3_DemoMode5_Final;
typedef enum a3_DemoMode5_Final_RenderMode			a3_DemoMode5_Final_RenderMode;
typedef enum a3_DemoMode5_Final_RenderPipeline		a3_DemoMode5_Final_RenderPipeline;
typedef enum a3_DemoMode5_Final_RenderPass			a3_DemoMode5_Final_RenderPass;
typedef enum a3_DemoMode5_Final_RenderTarget			a3_DemoMode5_Final_RenderTarget;
#endif	// __cplusplus


//-----------------------------------------------------------------------------

// render modes
enum a3_DemoMode5_Final_RenderMode
{
	final_renderModeDefault,

	final_renderMode_max
};


// render pipelines
enum a3_DemoMode5_Final_RenderPipeline
{
	final_renderPipeForward,		// forward pipeline

	final_renderPipe_max
};


// render passes
enum a3_DemoMode5_Final_RenderPass
{
	final_renderPassScene,
	final_renderPassLights,
	final_renderPassComposite,

	final_renderPassBright2,
	final_renderPassBlurH2,
	final_renderPassBlurV2,
	final_renderPassBright4,
	final_renderPassBlurH4,
	final_renderPassBlurV4,
	final_renderPassBright8,
	final_renderPassBlurH8,
	final_renderPassBlurV8,
	final_renderPassBlurFinal,
	final_renderPassDisplay,

	final_renderPass_max
};


// render targets
enum a3_DemoMode5_Final_RenderTarget
{
	// scene targets
	final_renderTargetSceneColor = 0,
	final_renderTargetSceneNormal,
	final_renderTargetSceneDiffuseSample,
	final_renderTargetSceneSpecularSample,
	final_renderTargetSceneDepth,
	final_renderTargetScene_max,
	
	// lighting targets
	final_renderTargetLightDiffuseShading = 0,
	final_renderTargetLightSpecularShading,
	final_renderTargetLight_max,

	// post-processing targets
	final_renderTargetPostColor = 0,

	final_renderTargetPost_max,
};


// maximum unique objects
enum a3_DemoMode5_Final_ObjectMaxCount
{
	finalMaxCount_sceneObject = 9,
	finalMaxCount_projector = 1,	// how many of the above behave as projectors
	finalMaxCount_pointLight = 1,	// how many of the above behave as lights

	finalMaxCount_skeletonPose = 4,
	finalMaxCount_skeletonJoint = 128,
};


//-----------------------------------------------------------------------------

typedef struct a3_Final_KeyframeController
{
	a3f32 duration, durationInv;
	a3f32 time, param;
	a3ui32 index, count;
} a3_Final_KeyframeController;

typedef enum a3_Final_TransformChannel
{
	f_channel_none = 0x0000,
	f_channel_rotate_x = 0x0001,
	f_channel_rotate_y = 0x0002,
	f_channel_rotate_z = 0x0004,
	f_channel_rotate_w = 0x0008,
	f_channel_rotate_xy = f_channel_rotate_x | f_channel_rotate_y,
	f_channel_rotate_yz = f_channel_rotate_y | f_channel_rotate_z,
	f_channel_rotate_zx = f_channel_rotate_z | f_channel_rotate_x,
	f_channel_rotate_xyz = f_channel_rotate_xy | f_channel_rotate_z,
	f_channel_translate_x = 0x0010,
	f_channel_translate_y = 0x0020,
	f_channel_translate_z = 0x0040,
	f_channel_translate_w = 0x0080,
	f_channel_translate_xy = f_channel_translate_x | f_channel_translate_y,
	f_channel_translate_yz = f_channel_translate_y | f_channel_translate_z,
	f_channel_translate_zx = f_channel_translate_z | f_channel_translate_x,
	f_channel_translate_xyz = f_channel_translate_xy | f_channel_translate_z,
	f_channel_scale_x = 0x0100,
	f_channel_scale_y = 0x0200,
	f_channel_scale_z = 0x0400,
	f_channel_scale_w = 0x0800,
	f_channel_scale_xy = f_channel_scale_x | f_channel_scale_y,
	f_channel_scale_yz = f_channel_scale_y | f_channel_scale_z,
	f_channel_scale_zx = f_channel_scale_z | f_channel_scale_x,
	f_channel_scale_xyz = f_channel_scale_xy | f_channel_scale_z,
} a3_Final_TransformChannel;


//-----------------------------------------------------------------------------

// demo mode for basic shading
struct a3_DemoMode5_Final
{
	// render mode
	a3_DemoMode5_Final_RenderMode renderMode;

	// render pipeline
	a3_DemoMode5_Final_RenderPipeline renderPipeline;

	// render pass
	a3_DemoMode5_Final_RenderPass renderPass;

	// render targets
	a3_DemoMode5_Final_RenderTarget renderTarget[final_renderPass_max], renderTargetCount[final_renderPass_max];

	// scene hierarchy and data
	a3_Hierarchy hierarchy_scene[1];

	// animation data
	a3_Final_KeyframeController animMorphTeapot[1], animPoseSkel[1];
	a3_Hierarchy hierarchy_skel[1];
	a3ui32 hierarchyDepth_skel[finalMaxCount_skeletonJoint];
	a3_SceneObjectData skeletonPose[finalMaxCount_skeletonPose][finalMaxCount_skeletonJoint];
	a3_Final_TransformChannel skeletonChannel[finalMaxCount_skeletonJoint];
	a3mat4 skeletonPose_local[finalMaxCount_skeletonJoint], skeletonPose_object[finalMaxCount_skeletonJoint],
		skeletonPose_render[finalMaxCount_skeletonJoint], skeletonPose_renderAxes[finalMaxCount_skeletonJoint];

	// scene object components and related data
	union {
		a3_SceneObjectComponent sceneObject[finalMaxCount_sceneObject];
		struct {
			a3_SceneObjectComponent
				objgroup_world_root[1],
				obj_light_main[1],
				obj_camera_main[1];
			a3_SceneObjectComponent
				obj_skybox[1],
				obj_skeleton[1],
				obj_teapot[1],
				obj_ground[1],
				obj_torus[1];
		};
	};
	a3_SceneObjectData sceneObjectData[finalMaxCount_sceneObject];
	a3_ModelMatrixStack modelMatrixStack[finalMaxCount_sceneObject];

	// projector components and related data
	union {
		a3_ProjectorComponent projector[finalMaxCount_projector];
		struct {
			a3_ProjectorComponent
				proj_camera_main[1];
		};
	};
	a3_ProjectorData projectorData[finalMaxCount_projector];
	a3_ProjectorMatrixStack projectorMatrixStack[finalMaxCount_projector];

	// light components and related data
	union {
		a3_PointLightComponent pointLight[finalMaxCount_pointLight];
		struct {
			a3_PointLightComponent
				light_point_main[1];
		};
	};
	a3_PointLightData pointLightData[finalMaxCount_pointLight];
};


//-----------------------------------------------------------------------------


#ifdef __cplusplus
}
#endif	// __cplusplus


#endif	// !__ANIMAL3D_DEMOMODE5_FINAL_H