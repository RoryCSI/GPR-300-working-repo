# GPR-300 Project 3
Using normal mapping and deferred shading and deferred lighting

Majority contribution by Daniel Buckstein.  
Minor (instructed) contribution by Rory Beebout.

---

Typical distributed a3D demo.  
Instructions for accessing:  
1. Open "LAUNCH_VS.bat"  
2. Build and Run in Visual Studio  
3. File -> DEBUG: Demo project hot build & load... -> Quick build & load OR Full rebuild & load  

Controls and information are shown within the demo.

---

- Completed Pipeline.  
- Implemented:
  * passTangentBasis_ubo_transform_vs4x 
  * passClipBiased_transform_instanced_vs4x 
  * postDeferredLightingComposite_fs4x 
  * postDeferredShading_fs4x 
  * !drawPhongPointLight_fs4x! -> incorrect normal and position sampling
  * drawGBuffers_fs4x 
  * drawPhongNM_fs4x 
