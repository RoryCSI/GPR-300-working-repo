# GPR-300 Final Project

# Fireflies in Rain Scene

### Attribution

Framework, base project by Daniel Buckstein.  
Implementation by Rory Beebout
(See commits for specific contributions)

---

### Description

This demo consists of a single scene showing "fairies" over water in rain, with a tentacle reaching out of the water and thrashing. The water is a simple plane whose vertices are displaced in a gerstner wave pattern. The water also reflects objects above it using screen-space reflections. Above the water, there are “Fairies” which are simply lights, interpolating between waypoints using weighted curves. The fairies emit particles handled by a compute shader to produce a more interesting effect. Additionally, a compute shader calculates positions for rain particles. Finally, a tentacle constructed from a number of primitive cylinders/cones, will be extending out from the surface of the water, interpolating through a number of poses utilizing forward kinematics.

---

### Instructions

Typical distributed a3D demo.  
Instructions for accessing:  
1. Open "LAUNCH_VS.bat"  
2. Build and Run in Visual Studio  
3. File -> DEBUG: Demo project hot build & load... -> Quick build & load OR Full rebuild & load  

Controls and information are shown within the demo.

---
