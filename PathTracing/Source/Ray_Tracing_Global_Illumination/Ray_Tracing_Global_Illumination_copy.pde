// potential todo:
// add ability to save scene
// add ability to upload texture map
// figure out if ReSTIR is compatible and implement it
// add photorealistic bloom
// add normal maps

import java.util.concurrent.atomic.AtomicBoolean;

Camera Cam = new Camera(new PVector(10, 10, 5), new PVector(0,0,0), PI/4);//PI/5*2
//Camera Cam = new Camera(new PVector(1.68, 2.115, 1.33), new PVector(1.885, 2.253, 2.299), PI/4); // new PVector(5, 5, 2.5), new PVector(0,0,0), PI/4
ArrayList<Object> Objs = new ArrayList<Object>(); // list of scene objects

// 2524 lines, 53.88% GUI, 46.11% Ray Tracer
// 3052 lines 11/1
// 3481 lines 11/8 (after adding quaternions, translation, and rotation)
// 4304 lines 11/13 (after adding mesh & KD Tree)

PVector preResLightDir = new PVector(0.5, 0.75, 1).normalize(); // direcition light comes from in preres mode

float goldenConj = 2 / (sqrt(5) + 1);               // reciprocal of the golden ratio
float plasticConj = 1 / 1.324717957244746025960909; // reciprocal of the plastic constant

int Res = 3;          // size of a render pixel in screen space pixels (higher = faster but lower resolution)
int samples = 20;     // number of samples taken from non-specular surfaces (lower = faster but slower convergence)

int drawWidth = 600;  // width of the view screen
int drawHeight = 600; // height of the view screen

int guiWidth = 300;   // width of the GUI

int maxBounces = 8;   // maximum number of bounces for a ray in the sceen (lower is faster but worse quality)

int ImageWidth, ImageHeight; // width and height of the image (not the same as size of view screen because image resolution is dynamic)

Color[] image;        // stores raw data accumulated from ray tracer (no post processing)
Color[] finalRender;  // postprocessed image that is drawn to the screen

float bloomStrength = 2; // strength of bloom
float bloomThreshold = 1;  // minimum threshold for bloom to begin
int bloomSize = 5;        // size / spread of bloom effect
float exposure = 1;       // increases image brightness
float contrast = 0;       // increases image contrast
int pixelsDrawn = 0;      // stores the number of pixels drawn for the current frame (used for progress bar)

Color skyColor = new Color(0.7, 0.8, 1);
float skyBrightness = 0.8;

int tileSplit = 4;          // how many sub-regions to break the image up into (# regions = tileSplit ^ 2)

int guiHeight;              // height of the GUI (should always equal Applet height but I pulled it out just incase I want to change it later)

float apertureSize = 0;     // size of the camera's aperture (leads to depth of field effect if non-zero)
float focalLength = 5;      // world space distance to focal point (objects around this distance will be in focus, others will be out of focus)

PImage imgToSave;           // stores image that will be saved until it is saved, this is done because image might update after save button is pressed

PVector cameraAngle = new PVector(3.88, -0.3);//new PVector(3.733, -0.25);

boolean drawingDepthBuffer = false; // should depth buffer be drawn or not?
float[] depthBuffer;                // stores the current depth buffer (not currently used, mostly for debug purposes)
boolean[] selObjectBuffer;          // boolean array telling if the currently selected object was hit at this pixel locaiton, used for drawing object outline

void settings(){
  size(drawWidth + guiWidth, drawHeight);
  //size(displayWidth, displayHeight - 136);
}

void setup(){
  // inital setup
  setupKeys();
  initalizeBars();
  Cam.UpdateCamera();
  resetBuffers();
  
  guiHeight = height;
  
  // rest of setup function is default scene construction (all for debug purposes)
  
  Objs.add(new Mesh(new PVector(0, 0, 0), "monke.obj", true, true, new Diffuse(new Color(1))));
  
  Objs.add(new Sphere(new PVector(0, 0, 4), 1.95, new Transparent(1.5, new Color(1, 1, 1), 0, 0)));
  Objs.add(new Plane(new PVector(0,0,0), new PVector(0,0,1), 10, 10, 0, new Diffuse(new Color(0.676, 0.852, 0.889))));
  
  Objs.add(new Disc(new PVector(0,0,15), new PVector(0, 0, 1), 5, new Emissive(new Color(1, 1, 1), 7)));
  Objs.add(new Box(new PVector(-2, -4, 2), new PVector(2, 2, 2), new Diffuse(new Color(1, 0.5, 0.5))));
  Objs.add(new Box(new PVector(0.5, -5.5, 0.5), new PVector(0.5, 0.5, 0.5), new Diffuse(new Color(1, 0.8, 0.5))));
  Objs.get(Objs.size() - 1).SetRotation(GetRotationTo(new PVector(0.5, 0.3, 1), 0.4));
  Objs.add(new Sphere(new PVector(1.2, -0.4, 0.5), 0.5, new Metal(new Color(0.8, 0.8, 0.8))));
}

int fibA, fibB;

boolean bloomToggle = true;      // controls if bloom is active or not
AtomicBoolean threadFinished = new AtomicBoolean(true);   // CHANGE TO ATOMIC BOOLEAN!
boolean pkeyPressed = false;    // was a key pressed on the previous frame?
boolean pmousePressed = false;  // was mouse pressed on the previous frame?
int StartTime = 0;        // time when render was last started/resumed (in ms since start of applet)
boolean paused = false;   // is final render paused
boolean drawing = false;  // is render actively being worked on
                          // drawing and paused are broken up because a render may be paused but the current frame will still finish drawing (so drawing ≠ !paused)

boolean imageUpdated = false; // if true redraw render (on new frame or change of settings)

Table preferences;
int timeLastFrame = 0;     // time spent rendering the previous frame
int totalRenderTime = 0;   // total time spent on this render
int raysThisFrame = 0;     // # rays traced so far this 'frame'
long totalTracedRays = 0;  // # rays traced since starting this render
int raysLastFrame = 0; // # rays traced in the previous 'frame'

boolean preRes = true;         // tells program whether to draw preres mode or render mode
boolean preresUpdate = true;   // if true redraws the preres then sets itself to false

boolean draggingCamera = false;// tells if camera is being dragged (panned) or if the user is just clicking
PVector pressLocation = new PVector(0,0); // used for tracking where the mouseDown event was

void draw(){
  keyboardStartFrame();
  drawGUI();
  
  if(imageUpdated){
    Blit();
    imageUpdated = false;
  }
  
  if(mousePressed && !pmousePressed){ // if mousePressed down store press location
    pressLocation.x = mouseX;
    pressLocation.y = mouseY;
  }
  
  if(preRes && mousePressed && (draggingCamera || pressLocation.x < drawWidth) && (abs(mouseX - pressLocation.x) > 2 || abs(mouseY - pressLocation.y) > 2)){
    // if the mouse is pressed, and in the view window, and has moved by more than 2 pixels in any direction then set mouse as being dragged
    draggingCamera = true;
  }else if(!mousePressed){
    draggingCamera = false; // if mouse not pressed then reset camera dragged
  }
  
  if(preRes && focused){ // manage camera movement if in preRes and Applet has focus
    Cam.Move();
  }
  
  if(preRes){
    moveObjects();
  }
  
  if(preRes && preresUpdate){ // redraw preres if there was an update
    preresUpdate = false;
    drawPreRes();
    Blit();
    DrawAxes();
  }else if(!preRes && threadFinished.get() && (drawing || !paused)){ // at the start of each frame update stats
    if(drawing){
      timeLastFrame = millis() - StartTime;
      totalRenderTime += timeLastFrame;
      totalTracedRays += raysThisFrame;
      raysLastFrame = raysThisFrame;
      raysThisFrame = 0;
      pixelsDrawn = 0;
      FrameNum++;
      
      for(int i = 0; i < image.length; i++){
        image[i].add(buffer[i]);
      }
      
      imageUpdated = true;
    }
    drawing = !paused;
    if(!paused){
      StartTime = millis();
      threadFinished.set(false);
      thread("DrawFrameMT"); // call the function 'DrawFrameMT' in a seperate thread
    }
  }
  
  if(tileDivisionsBar.locked){ // if tileDivisions bar is being interacted with draw tile divisions
    stroke(0);
    strokeWeight(1);
    for(int i = 0; i < tileSplit-1; i++){
      line((float)(i + 1) / (tileSplit) * drawWidth, 0, (float)(i + 1) / (tileSplit) * drawWidth, drawHeight);
      line(0, (float)(i + 1) / (tileSplit) * drawHeight, drawWidth, (float)(i + 1) / (tileSplit) * drawHeight);
    }
    preresUpdate = true;
  }
  
  pkeyPressed = keyPressed;
  pmousePressed = mousePressed;
  keyboardEndFrame();
}
