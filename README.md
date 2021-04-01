# GPR-300 Project 4
Using Parallax Occlusion Mapping, and tessellation/geometry

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
- * Animated teapot along a spline
- Implemented:
  * POM in drawPhongPOM_fs4x
  * drawTangentBasis_gs4x
  * passColor_interp_tes4x
  * passTangentBasis_displace_tes4x
  * tessIso_tcs4x
  * tessTriTangentBasis_tcs4x
