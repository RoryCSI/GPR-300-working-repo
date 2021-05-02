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

	a3_DemoMode5_Final-idle-update.c
	Demo mode implementations: animation scene.

	********************************************
	*** UPDATE FOR ANIMATION SCENE MODE      ***
	********************************************
*/

//-----------------------------------------------------------------------------

#include "../a3_DemoMode5_Final.h"

//typedef struct a3_DemoState a3_DemoState;
#include "../a3_DemoState.h"

#include "../_a3_demo_utilities/a3_DemoMacros.h"


//-----------------------------------------------------------------------------

inline int a3final_updateKeyframeController(a3_Final_KeyframeController* keyCtrl,
	a3f32 const dt)
{
	if (keyCtrl)
	{
		// update timer
		keyCtrl->time += dt;
		if (keyCtrl->time >= keyCtrl->duration)
		{
			keyCtrl->time -= keyCtrl->duration;
			keyCtrl->index = (keyCtrl->index + 1) % keyCtrl->count;
		}
		keyCtrl->param = keyCtrl->time * keyCtrl->durationInv;

		// done
		return 1;
	}
	return -1;
}

inline int a3final_updateSkeletonLocalSpace(a3_Hierarchy const* hierarchy,
	a3mat4* localSpaceArray,
	a3_SceneObjectData const keyPoseArray[finalMaxCount_skeletonPose][finalMaxCount_skeletonJoint],
	a3_Final_KeyframeController const* keyCtrl)
{
	if (hierarchy && localSpaceArray && keyPoseArray && keyCtrl)
	{
		a3ui32 j;
		a3ui32 const i0 = keyCtrl->index, i1 = (i0 + 1) % keyCtrl->count;
		a3f32 u = keyCtrl->param;
		a3_SceneObjectData const* p0 = keyPoseArray[i0 + 1], * p1 = keyPoseArray[i1 + 1], * pBase = keyPoseArray[0];
		a3_SceneObjectData tmpPose;
		
		for (j = 0;
			j < hierarchy->numNodes;
			++j, ++p0, ++p1, ++pBase, ++localSpaceArray)
		{
			// testing: copy base pose
			tmpPose = *pBase;

			// ****Done:
			// interpolate channels

			//intializations
			a3vec4 posePosition = {0,0,0,0};
			a3vec4 poseRotation = {0,0,0,0};
			a3vec3 poseScale = {0,0,0};

			//Interpolating pos, rot, and scale
			a3real4Lerp(posePosition.v, p0->position.v, p1->position.v, u);
			a3real4Lerp(poseRotation.v, p0->euler.v, p1->euler.v, u);
			a3real3Lerp(poseScale.v, p0->scale.v, p1->scale.v, u);

			// ****Done:
			// concatenate base pose

			//adding on to the base pose (multiplying for scale though)
			a3real4Add(tmpPose.position.v, posePosition.v);
			a3real4Add(tmpPose.euler.v, poseRotation.v);
			a3real3ProductComp(tmpPose.scale.v, poseScale.v, pBase->scale.v);

			// ****Done:
			// convert to matrix

			//Temp matrix to store final result
			// -> Already contains scale, and translation, needs rotation
			a3mat4 temp = {
				tmpPose.scale.x, 0.0f, 0.0f, 0.0f,
				0.0f, tmpPose.scale.y, 0.0f, 0.0f,
				0.0f, 0.0f, tmpPose.scale.z, 0.0f,
				tmpPose.position.x, tmpPose.position.y,tmpPose.position.z, 1.0f
			};

			//Get rotation matrix
			a3mat4 rotMat = a3mat4_identity; //initialize for storage
			a3real4x4SetRotateXYZ(rotMat.m, tmpPose.euler.x, tmpPose.euler.y, tmpPose.euler.z); //get appropriate rotation matrix, store it

			//combine transformations into one matrix
			a3real4x4Concat(rotMat.m, temp.m);

			//set localSpaceArray
			*localSpaceArray = temp; // same as -> localSpaceArray[j] = temp; but more effecient (probably).
			
		}
		// done
		return 1;
	}
	return -1;
}

inline int a3final_updateSkeletonObjectSpace(a3_Hierarchy const* hierarchy,
	a3mat4* const objectSpaceArray, a3mat4 const* const localSpaceArray)
{
	if (hierarchy && objectSpaceArray && localSpaceArray)
	{
		// ****Done: 
		// forward kinematics
		a3ui32 j = 0;
		a3i32 jp = 0;

		//From Buckstein's lecture9 skeletal intro.pdf, class concepting.
		for (j; j < hierarchy->numNodes; j++)
		{
			//get parrent index of current
			jp = hierarchy->nodes[j].parentIndex;

			//jp is -1 for root case
			if (jp < 0)
			{
				objectSpaceArray[j] = localSpaceArray[j];
			}
			//for all non-root cases
			else// if (jp < (a3i32) j)
			{
				//multiply objectSpace position of parent and local transformation to get objectSpace position
				// -> Order is important
				a3real4x4Product(objectSpaceArray[j].m, objectSpaceArray[jp].m, localSpaceArray[j].m);
			}
		}
		// done
		return 1;
	}
	return -1;
}

inline int a3final_updateSkeletonRenderMats(a3_Hierarchy const* hierarchy,
	a3mat4* renderArray, a3mat4* renderAxesArray, a3mat4 const* objectSpaceArray, a3mat4 const mvp_obj)
{
	if (hierarchy && renderArray && objectSpaceArray)
	{
		a3real3rk up;
		a3ui32 j;
		a3i32 jp;
		for (j = 0;
			j < hierarchy->numNodes;
			++j)
		{
			jp = hierarchy->nodes[j].parentIndex;
			if (jp >= 0)
			{
				renderArray[j] = a3mat4_identity;
				a3real3Diff(renderArray[j].m[2], objectSpaceArray[j].m[3], objectSpaceArray[jp].m[3]);
				up = (renderArray[j].m20 * renderArray[j].m21) ? a3vec3_z.v : a3vec3_y.v;
				a3real3MulS(a3real3CrossUnit(renderArray[j].m[0], up, renderArray[j].m[2]), 0.25f);
				a3real3MulS(a3real3CrossUnit(renderArray[j].m[1], renderArray[j].m[2], renderArray[j].m[0]), 0.25f);
				renderArray[j].v3 = objectSpaceArray[jp].v3;
			}
			else
			{
				// zero scale at root position
				a3real4x4SetScale(renderArray[j].m, 0.0f);
				renderArray[j].v3 = objectSpaceArray[j].v3;
			}
			a3real4x4Concat(mvp_obj.m, renderArray[j].m);

			// for joint axes rendering
			a3real4x4SetScale(renderAxesArray[j].m, 0.25f);
			a3real4x4Concat(objectSpaceArray[j].m, renderAxesArray[j].m);
			a3real4x4Concat(mvp_obj.m, renderAxesArray[j].m);
		}

		// done
		return 1;
	}
	return -1;
}


//-----------------------------------------------------------------------------
// UPDATE

void a3final_update_graphics(a3_DemoState* demoState, a3_DemoMode5_Final* demoMode)
{
	a3bufferRefillOffset(demoState->ubo_transform, 0, 0, sizeof(demoMode->modelMatrixStack), demoMode->modelMatrixStack);
	a3bufferRefillOffset(demoState->ubo_transform + 1, 0, 0, sizeof(demoMode->G_ComputePositions), demoMode->G_ComputePositions);
	a3bufferRefillOffset(demoState->ubo_light, 0, 0, sizeof(demoMode->pointLightData), demoMode->pointLightData);
	a3bufferRefillOffset(demoState->ubo_mvp, 0, 0, sizeof(demoMode->skeletonPose_render), demoMode->skeletonPose_render);
	a3bufferRefillOffset(demoState->ubo_mvp, 0, sizeof(demoMode->skeletonPose_render), sizeof(demoMode->hierarchyDepth_skel), demoMode->hierarchyDepth_skel);
	a3bufferRefillOffset(demoState->ubo_mvp + 1, 0, 0, sizeof(demoMode->skeletonPose_renderAxes), demoMode->skeletonPose_renderAxes);
}

void a3final_update_animation(a3_DemoState* demoState, a3_DemoMode5_Final* demoMode, a3f64 const dt)
{
	if (demoState->updateAnimation)
	{
		a3_SceneObjectData* sceneObjectData = demoMode->obj_sphere->dataPtr;

		// teapot follows curved path
		a3ui32 const i0 = demoMode->finalSegmentIndex,
			i1 = (i0 + 1) % demoMode->finalWaypointCount,
			iN = (i1 + 1) % demoMode->finalWaypointCount,
			iP = (i0 + demoMode->finalWaypointCount - 1) % demoMode->finalWaypointCount;

		//a3real3Lerp(sceneObjectData->position.v,
		//	demoMode->curveWaypoint[i0].v,
		//	demoMode->curveWaypoint[i1].v,
		//	demoMode->curveSegmentParam);
		a3real3CatmullRom(sceneObjectData->position.v,
			demoMode->finalWaypoint[iP].v,
			demoMode->finalWaypoint[i0].v,
			demoMode->finalWaypoint[i1].v,
			demoMode->finalWaypoint[iN].v,
			demoMode->finalSegmentParam);
		//a3real3HermiteTangent(sceneObjectData->position.v,
		//	demoMode->curveWaypoint[i0].v,
		//	demoMode->curveTangent[i0].v,
		//	demoMode->curveWaypoint[i1].v,
		//	demoMode->curveTangent[i1].v,
		//	demoMode->curveSegmentParam);

		// update timer
		demoMode->finalSegmentTime += (a3f32)dt;
		if (demoMode->finalSegmentTime >= demoMode->finalSegmentDuration)
		{
			demoMode->finalSegmentTime -= demoMode->finalSegmentDuration;
			demoMode->finalSegmentIndex = (demoMode->finalSegmentIndex + 1) % demoMode->finalWaypointCount;
		}
		demoMode->finalSegmentParam = demoMode->finalSegmentTime * demoMode->finalSegmentDurationInv;

		// keyframe controllers
		a3f32 const dt_flt = (a3f32)dt;
		a3final_updateKeyframeController(demoMode->animMorphTeapot, dt_flt);
		a3final_updateKeyframeController(demoMode->animPoseSkel, dt_flt);

		// skeletal poses and matrices
		a3final_updateSkeletonLocalSpace(demoMode->hierarchy_skel,
			demoMode->skeletonPose_local, demoMode->skeletonPose, demoMode->animPoseSkel);
		a3final_updateSkeletonObjectSpace(demoMode->hierarchy_skel,
			demoMode->skeletonPose_object, demoMode->skeletonPose_local);
	}

	// always update render data
	a3final_updateSkeletonRenderMats(demoMode->hierarchy_skel,
		demoMode->skeletonPose_render, demoMode->skeletonPose_renderAxes, demoMode->skeletonPose_object,
		demoMode->obj_skeleton->modelMatrixStackPtr->modelViewProjectionMat);
}

void a3final_update_scene(a3_DemoState* demoState, a3_DemoMode5_Final* demoMode, a3f64 const dt)
{
	void a3demo_update_defaultAnimation(a3f64 const dt, a3_SceneObjectComponent const* sceneObjectArray,
		a3ui32 const count, a3ui32 const axis, a3boolean const updateAnimation);
	void a3demo_update_bindSkybox(a3_SceneObjectComponent const* sceneObject_skybox,
		a3_ProjectorComponent const* projector_active);

	const a3mat4 bias = {
		0.5f, 0.0f, 0.0f, 0.0f,
		0.0f, 0.5f, 0.0f, 0.0f,
		0.0f, 0.0f, 0.5f, 0.0f,
		0.5f, 0.5f, 0.5f, 1.0f
	}, biasInv = {
		2.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 2.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 2.0f, 0.0f,
		-1.0f, -1.0f, -1.0f, 1.0f
	};

	a3_ProjectorComponent* projector = demoMode->proj_camera_main;

	a3_PointLightData* pointLightData;
	a3mat4* pointLightMVP;
	a3real const ratio = a3trigFaceToPointRatio(a3real_threesixty, a3real_oneeighty, 32, 24);
	a3ui32 i;

	// update camera
	a3demo_updateSceneObject(demoMode->obj_camera_main, 1);
	a3demo_updateSceneObjectStack(demoMode->obj_camera_main, projector);
	a3demo_updateProjector(projector);
	a3demo_updateProjectorViewMats(projector);
	a3demo_updateProjectorBiasMats(projector, bias, biasInv);

	// update light
	a3demo_updateSceneObject(demoMode->obj_light_main, 1);
	a3demo_updateSceneObjectStack(demoMode->obj_light_main, projector);

	// update skybox
	a3demo_updateSceneObject(demoMode->obj_skybox, 0);
	a3demo_update_bindSkybox(demoMode->obj_skybox, projector);
	a3demo_updateSceneObjectStack(demoMode->obj_skybox, projector);

	// update scene objects
	a3demo_update_defaultAnimation((dt * 15.0), demoMode->obj_teapot,
		(a3ui32)(demoMode->obj_ground - demoMode->obj_teapot), 2, demoState->updateAnimation);

	a3demo_updateSceneObject(demoMode->obj_skeleton, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_skeleton, projector);

	a3demo_updateSceneObject(demoMode->obj_teapot, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_teapot, projector);

	a3demo_updateSceneObject(demoMode->obj_torus, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_torus, projector);

	a3demo_updateSceneObject(demoMode->obj_sphere, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_sphere, projector);

	a3demo_updateSceneObject(demoMode->obj_ground, 0);
	a3demo_updateSceneObjectStack(demoMode->obj_ground, projector);

	// update light
	a3demo_updateSceneObject(demoMode->obj_light_second, 1);
	a3demo_updateSceneObjectStack(demoMode->obj_light_second, projector);

	// update light positions and transforms
	for (i = 0, pointLightData = demoMode->pointLightData, pointLightMVP = demoMode->pointLightMVP;
		i < finalMaxCount_pointLight;
		++i, ++pointLightData, ++pointLightMVP)
	{
		a3real4Real4x4Product(pointLightData->position.v,
			projector->sceneObjectPtr->modelMatrixStackPtr->modelMatInverse.m,
			pointLightData->worldPos.v);

		// update and transform light matrix
		a3real4x4SetScale(pointLightMVP->m, pointLightData->radius * ratio);
		pointLightMVP->v3 = pointLightData->position;
		a3real4x4Concat(projector->projectorMatrixStackPtr->projectionMat.m, pointLightMVP->m);
	}
}

void a3final_update(a3_DemoState* demoState, a3_DemoMode5_Final* demoMode, a3f64 const dt)
{
	// update scene objects and related data
	a3final_update_scene(demoState, demoMode, dt);

	// specific object animation
	a3final_update_animation(demoState, demoMode, dt);

	// prepare and upload graphics data
	a3final_update_graphics(demoState, demoMode);
}


//-----------------------------------------------------------------------------
