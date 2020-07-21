# touchdesigner-ssgi

### Screen Space Global Illumination for TouchDesigner
GLSL implementation of screen space global illumination as a GLSL TOP for TouchDesigner.
The shader basically samples a grid of points that it treats as light sources. The colours for the light sources are based on the colour buffer at the light locations. Each light is then averaged out and blended with the current pixel value thus faking some sort of global illumination. 

### Usage
Just drop down a GLSL TOP and copy/paste the shader. The shader requires 4 parameters
- ```uInvProjMatrix``` is the inverse of the camera projection matrix, the ```getInvProjScript``` Execute DAT in the .toe has an example on how to get the matrix and send it to the GLSL TOP
- ```uGIAmount``` is the amount of GI to blend in the direct lighting
- ```uKernelSize``` is the size of the kernel to sample lighting information from
- A depth map from te Render TOP, check out [interactiveimmersive.io](https://interactiveimmersive.io/blog/3d/depth-of-field-in-touchdesigner/) or [docs.derivative.ca/Depth_TOP](https://docs.derivative.ca/Depth_TOP) for more information on how to set it up.

### Credit
[Martins Upitis](https://github.com/martinsh) and [Wicked Engine](https://wickedengine.net/2019/09/22/improved-normal-reconstruction-from-depth/) both provide good source/explanations about how to rebuild the normals from the depth map.

### Feedback
If you see anything that could be improved please feel free to share.
