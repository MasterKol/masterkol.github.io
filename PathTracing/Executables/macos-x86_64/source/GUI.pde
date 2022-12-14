HScrollbar bloomStrenBar =        new HScrollbar(120, 35, 120, 12, "Strength of the bloom effect in the final image");
HScrollbar bloomSizeBar =         new HScrollbar(120, 55, 120, 12, "Radius of blur of the bloom in the final image");
HScrollbar exposureBar =          new HScrollbar(120, 75, 120, 12);
HScrollbar contrastBar =          new HScrollbar(120, 95, 120, 12);
Button toggleRenderButton =       new Button(30, 115, 100, 30, "Pause Render");
Button restartRenderButton =      new Button(170, 115, 100, 30, "Restart Render");
Button saveImageButton =          new Button(30, 155, 100, 30, "Save Image");

HScrollbar cameraXBar =           new HScrollbar(120, 145, 120, 12);
HScrollbar cameraYBar =           new HScrollbar(120, 165, 120, 12);
HScrollbar cameraZBar =           new HScrollbar(120, 185, 120, 12);
HScrollbar cameraThetaBar =       new HScrollbar(120, 205, 120, 12, "Horizontal angle of the camera");
HScrollbar cameraPhiBar =         new HScrollbar(120, 225, 120, 12, "Vertical angle of the camera");
HScrollbar cameraFOVBar =         new HScrollbar(120, 245, 120, 12, "Field of view");
HScrollbar cameraFocalBar =       new HScrollbar(120, 265, 120, 12, "Focal length of camera (only matters if aperture is non 0)");
HScrollbar cameraApertureBar =    new HScrollbar(120, 285, 120, 12, "Radius of the camera's aperture (bigger = smaller region of focus)");
HScrollbar cameraResBar =         new HScrollbar(120, 305, 120, 12, "Size of each pixel, 1 is full res, 2 is half res, etc.");
HScrollbar samplesBar =           new HScrollbar(120, 325, 120, 12, "Number of samples for diffuse objects (currently bugged)");
HScrollbar tileDivisionsBar =     new HScrollbar(120, 345, 120, 12, "Breaks image up to be drawn by individual threads");

HScrollbar skyColorRBar =         new HScrollbar(120, 370, 120, 12);
HScrollbar skyColorGBar =         new HScrollbar(120, 390, 120, 12);
HScrollbar skyColorBBar =         new HScrollbar(120, 410, 120, 12);
HScrollbar skyBrightnessBar =     new HScrollbar(120, 430, 120, 12);

Button startRenderButton =        new Button(215, 10, 80, 20, "Start Render");

Button materialLeftButton =       new Button(60, 0, 20, 20, "<");
Button materialRightButton =      new Button(220, 0, 20, 20, ">");

HScrollbar objectXBar =           new HScrollbar(120, 345, 120, 12);
HScrollbar objectYBar =           new HScrollbar(120, 365, 120, 12);
HScrollbar objectZBar =           new HScrollbar(120, 385, 120, 12);

ScrollArea scrollArea =           new ScrollArea(0, 0, 300, drawHeight);

Button deleteObjectButton =       new Button(110, 340, 100, 20, "Delete Object");

Button addSphereButton =          new Button(110, 340, 100, 20, "Sphere");
Button addPlaneButton =           new Button(110, 365, 100, 20, "Plane");
Button addBoxButton =             new Button(110, 390, 100, 20, "Box");
Button addDiscButton =            new Button(110, 415, 100, 20, "Disc");
Button addMeshButton =            new Button(110, 440, 100, 20, "Mesh");


DrawOverlayCallback overlayCallback; // draws the current overlay in the global image reference frame

boolean objectSelected = false; // all information about object that is currently selected / being translated / rotated
Object selectedObject;
boolean objectGrabbed = false;
boolean objectRotating = false;
PVector originalPosition;
Quaternion originalAngle = new Quaternion(1,0,0,0);
int directions = 0;
PVector selPos = new PVector(0, 0);

void drawGUI(){
  overlayCallback = null;
  
  pushMatrix();
  translate(drawWidth, 0);
  
  fill(255);
  noStroke();
  rect(0, 0, guiWidth, guiHeight);
  
  scrollArea.update();
  scrollArea.display();
  translate(0, -scrollArea.currentScroll);
  scrollArea.maxScroll = 130 + 60;
  
  if(preRes){
    
    scrollArea.maxScroll += 280;
    
    textSize(10);
    textLeading(10);
    textAlign(LEFT, TOP);
    
    fill(0);
    text("Change the settings below before you start the render. If you click an object you can change its properties. "
      + "When you're ready click the button to the right.", 15, 5, 200, 50);
    
    startRenderButton.update();
    startRenderButton.display();
    if(!startRenderButton.getState()){ // stuff to do when rendering starts
      startRenderButton.setState(true);
      FrameNum = 0;
      StartTime = millis();
      preRes = false;
      for(int i = 0; i < image.length; i++){
        image[i] = new Color(0);
      }
      
      totalTracedRays = 0;
      raysLastFrame = 0;
      raysThisFrame = 0;
      timeLastFrame = 0;
      totalRenderTime = 0;
      pixelsDrawn = 0;
      
      int t;
      fibA = 1; fibB = 1;
      while(fibA + fibB < samples){
        t = fibA + fibB;
        fibA = fibB;
        fibB = t;
      }
    }
    
    translate(0, 50);
    
    ImageSettings();
    
    PreResGui();
  }else{
    ImageSettings();
    nonPreResGui();
  }
  
  if(!mousePressed && pmousePressed){
    writeSettings();
  }
  
  popMatrix();
  
  if(overlayCallback != null){
    overlayCallback.Draw();
  }
}

void PreResGui(){
  fill(0);
  textSize(16);
  textAlign(CENTER);
  text("Camera Settings", guiWidth / 2, 130);
  
  textAlign(LEFT);
  textSize(12);
  textLeading(14);
  
  HDiffBar(cameraXBar, "X Pos", Cam.Pos.x, 1, new barInter(){public void onChange(float v){
    Cam.Pos.x = v;
    Cam.UpdateCamera();
  }});
  
  HDiffBar(cameraYBar, "Y Pos", Cam.Pos.y, 1, new barInter(){public void onChange(float v){
    Cam.Pos.y = v;
    Cam.UpdateCamera();
  }});
  
  HDiffBar(cameraZBar, "Z Pos", Cam.Pos.z, 1, new barInter(){public void onChange(float v){
    Cam.Pos.z = v;
    Cam.UpdateCamera();
  }});
  
  HDiffBar(cameraThetaBar, "Theta", cameraAngle.x * 180 / PI, 6, new barInter(){public void onChange(float v){
    cameraAngle.x = ((v + 360) % 360) * PI / 180;
    Cam.UpdateCamera();
  }});
  
  NormBar(cameraPhiBar, "Phi", cameraAngle.y * 180 / PI, -89.5, 89.5, true, new barInter(){public void onChange(float v){
    cameraAngle.y = v * PI / 180;
    Cam.UpdateCamera();
    preresUpdate = true;
  }});
  
  NormBar(cameraFOVBar, "FOV", Cam.Fov, 0.01, PI/2, true, new barInter(){public void onChange(float v){
    Cam.Fov = v;
    Cam.UpdateCamera();
    preresUpdate = true;
  }});
  
  NormBar(cameraFocalBar, "Focal Length", focalLength, 1, 30, false, new barInter(){public void onChange(float v){
    focalLength = v;
    drawingDepthBuffer = true;
    preresUpdate = true;
  }});
  
  NormBar(cameraApertureBar, "Aperture Size", apertureSize, 0, 2, false, new barInter(){public void onChange(float v){
    apertureSize = v;
    drawingDepthBuffer = true;
    preresUpdate = true;
  }});
  
  NormBar(cameraResBar, "Pixel Size", Res, 1, 10, true, new barInter(){public void onChange(float v){
    Res = round(v);
    resetBuffers();
    Cam.UpdateCamera();
    preresUpdate = true;
  }});
  
  NormBar(samplesBar, "Samples", samples, 1, 100, true, new barInter(){public void onChange(float v){
    samples = round(v);
  }});
  
  tileSplit = round(NormBar(tileDivisionsBar, "Tile Divisions", tileSplit, 1, 6, true));
  
  NormBar(skyColorRBar, "Sky Color Red", skyColor.r, 0, 1, true, new barInter(){public void onChange(float v){
    skyColor.r = v;
    preresUpdate = true;
  }});
  
  NormBar(skyColorGBar, "Sky Color Green", skyColor.g, 0, 1, true, new barInter(){public void onChange(float v){
    skyColor.g = v;
    preresUpdate = true;
  }});
  
  NormBar(skyColorBBar, "Sky Color Blue", skyColor.b, 0, 1, true, new barInter(){public void onChange(float v){
    skyColor.b = v;
    preresUpdate = true;
  }});
  
  NormBar(skyBrightnessBar, "Sky Brightness", skyBrightness, 0, 5, false, new barInter(){public void onChange(float v){
    skyBrightness = max(0, v);
    preresUpdate = true;
  }});
  
  translate(0, 80);
  scrollArea.maxScroll += 80;
  
  if(objectSelected){ // draw information for selected object
    translate(0, 50);
    fill(0);
    textSize(16);
    textAlign(CENTER);
    text("Object Settings", guiWidth / 2, 330);
    
    textAlign(LEFT);
    textSize(12);
    textLeading(14);
    
    deleteObjectButton.update();
    deleteObjectButton.display();
    translate(0, 30);
    
    selectedObject.pos.x = HDiffBar(objectXBar, "X Pos", selectedObject.pos.x, 0.2);
    selectedObject.pos.y = HDiffBar(objectYBar, "Y Pos", selectedObject.pos.y, 0.2);
    selectedObject.pos.z = HDiffBar(objectZBar, "Z Pos", selectedObject.pos.z, 0.2);
    
    Material objectMat = selectedObject.getMaterial();
    
    scrollArea.maxScroll += 190 + selectedObject.getGuiSize() + objectMat.getGuiSize();
    //println(scrollArea.maxScroll);
    
    pushMatrix();
    translate(0, 405);
    selectedObject.drawGui();
    
    translate(0, selectedObject.getGuiSize());
    
    fill(0);
    textSize(16);
    textAlign(CENTER, TOP);
    text("Material Settings", guiWidth / 2, 0);
    
    textAlign(LEFT);
    
    translate(0, 30);
    
    textAlign(CENTER, CENTER);
    textSize(14);
    textLeading(14);
    text(objectMat.getTypeName(), 150, 7);
    
    textSize(12);
    textLeading(14);
    
    int newtype = objectMat.getType();
    materialLeftButton.display();
    materialLeftButton.update();
    if(!materialLeftButton.state){
      materialLeftButton.setState(true);
      newtype = (newtype - 1 + 6) % 6;
    }
    
    materialRightButton.display();
    materialRightButton.update();
    if(!materialRightButton.state){
      materialRightButton.setState(true);
      newtype = (newtype + 1) % 6;
      println(newtype);
    }
    
    if(objectMat.getType() != newtype){
      if(newtype == 0){
        selectedObject.setMaterial(new Emissive(new Color(1, 1, 1), 1));
      }else if(newtype == 1){
        selectedObject.setMaterial(new Diffuse(new Color(1, 1, 1)));
      }else if(newtype == 2){
        selectedObject.setMaterial(new Glossy(new Color(1, 1, 1), 0));
      }else if(newtype == 3){
        selectedObject.setMaterial(new Transparent(1.5, new Color(1, 1, 1), 0, 0));
      }else if(newtype == 4){
        selectedObject.setMaterial(new Metal(new Color(1, 1, 1)));
      }else if(newtype == 5){
        selectedObject.setMaterial(new Texture());
      }
      preresUpdate = true;
    }
    
    translate(0, 40);
    objectMat.drawGui();
    
    if(!deleteObjectButton.getState()){ // if delete object button is pressed then delete the object
      Objs.remove(selectedObject);
      selectedObject = null;
      objectSelected = false;
      preresUpdate = true;
      deleteObjectButton.setState(true);
    }
    
    popMatrix();
  }else{
    translate(0, 50);
    fill(0);
    textSize(16);
    textAlign(CENTER);
    text("Create Object", guiWidth / 2, 330);
    
    textAlign(LEFT);
    textSize(12);
    textLeading(14);
    
    scrollArea.maxScroll += 105;
    addSphereButton.display();
    addSphereButton.update();
    if(!addSphereButton.getState()){
      Objs.add(new Sphere(new PVector(0, 0, 0), 1, new Diffuse(new Color(1, 1, 1))));
      selectedObject = Objs.get(Objs.size() - 1);
      objectSelected = true;
      preresUpdate = true;
      addSphereButton.setState(true);
    }
    
    addPlaneButton.display();
    addPlaneButton.update();
    if(!addPlaneButton.getState()){
      Objs.add(new Plane(new PVector(0, 0, 0), new PVector(0, 0, 1), 1, 1, 0, new Diffuse(new Color(1, 1, 1))));
      selectedObject = Objs.get(Objs.size() - 1);
      objectSelected = true;
      preresUpdate = true;
      addPlaneButton.setState(true);
    }
    
    addBoxButton.display();
    addBoxButton.update();
    if(!addBoxButton.getState()){
      Objs.add(new Box(new PVector(0, 0, 0), new PVector(1, 1, 1), new Diffuse(new Color(1, 1, 1))));
      selectedObject = Objs.get(Objs.size() - 1);
      objectSelected = true;
      preresUpdate = true;
      addBoxButton.setState(true);
    }
    
    addDiscButton.display();
    addDiscButton.update();
    if(!addDiscButton.getState()){
      Objs.add(new Disc(new PVector(0, 0, 0), new PVector(0, 0, 1), 1, new Diffuse(new Color(1, 1, 1))));
      selectedObject = Objs.get(Objs.size() - 1);
      objectSelected = true;
      preresUpdate = true;
      addDiscButton.setState(true);
    }
    
    addMeshButton.display();
    addMeshButton.update();
    if(!addMeshButton.getState() && !selectingObject.get()){
      selectingObject.set(true);
      selectInput("Select an ObjFile:", "loadObjectGUI");
      addMeshButton.setState(true);
    }
  }
  
  if(!draggingCamera && !mousePressed && pmousePressed && pressLocation.x < drawWidth && pressLocation.y < drawHeight){
    if(objectGrabbed || objectRotating){
      objectGrabbed = false;
      objectRotating = false;
      preresUpdate = true;
    }else{
      PVector dir = Cam.getRay((float)mouseX/Res, mouseY/Res);
      Ray r = new Ray(Cam.Pos.copy(), dir);
      Hit h = new Hit();
      
      preresUpdate = true;
      objectSelected = tracePath(r, h);
      selectedObject = h.object;
    }
  }
}

void nonPreResGui(){
  toggleRenderButton.setState(!paused);
  toggleRenderButton.update();
  toggleRenderButton.display();
  paused = !toggleRenderButton.getState();
  
  restartRenderButton.update();
  restartRenderButton.display();
  if(!restartRenderButton.getState()){
    restartRenderButton.setState(true);
    
    preRes = true;
    paused = false;
    drawing = false;
    while(!threadFinished.get());
    
    FrameNum = 1;
    preresUpdate = true;
  }
  
  saveImageButton.update();
  saveImageButton.display();
  if(!saveImageButton.getState()){
    saveImageButton.setState(true);
    
    imgToSave = createImage(ImageWidth, ImageHeight, RGB);
    imgToSave.loadPixels();
    loadPixels();
    for(int x = 0; x < ImageWidth; x++){
      for(int y = 0; y < ImageHeight; y++){
        imgToSave.pixels[x + y * ImageWidth] = pixels[x * Res + y * width * Res];
      }
    }
    imgToSave.updatePixels();
        
    selectOutput("Select File location:", "SaveImage");
  }
  
  // progress bar
  float percentage = 0;
  if(FrameNum == 0){
    percentage = (float)pixelsDrawn / image.length;
  }else{
    percentage = 0.5 * (float)pixelsDrawn / image.length + 0.5 * raysThisFrame / ((float)totalTracedRays / max(FrameNum, 1));
  }
  noFill();
  stroke(0);
  strokeWeight(1);
  rect(10, guiHeight - 170, 140, 10);
  
  fill(0);
  noStroke();
  rect(10, guiHeight - 170, 140 * percentage, 10);
  
  // info
  fill(0);
  text("Frame Number: ", 10, guiHeight - 140);
  text(FrameNum, 140, guiHeight - 140);
  
  text("Total render time: ", 10, guiHeight - 125);
  text(nf(((float)totalRenderTime + (drawing ? (millis() - StartTime) : 0)) / 1000, 0, 3) + " s", 140, guiHeight - 125);
  
  text("Last frame time: ", 10, guiHeight - 110);
  text(timeLastFrame + " ms", 140, guiHeight - 110);
  
  text("Average frame time: ", 10, guiHeight - 95);
  text(totalRenderTime / max(FrameNum, 1) + " ms", 140, guiHeight - 95);
  
  text("Time on this frame: ", 10, guiHeight - 80);
  text((drawing ? (millis() - StartTime) : "0") + " ms", 140, guiHeight - 80);
  
  text("Total rays cast: ", 10, guiHeight - 65);
  text(commas(totalTracedRays + raysThisFrame), 140, guiHeight - 65);
  
  text("Last frame rays: ", 10, guiHeight - 50);
  text(commas(raysLastFrame), 140, guiHeight - 50);
  
  text("Average rays / frame: ", 10, guiHeight - 35);
  text(commas((int)((float)totalTracedRays / max(FrameNum, 1))), 140, guiHeight - 35);
  
  text("Average rays / sec: ", 10, guiHeight - 20);
  text(commas((int)((float)totalTracedRays / max(totalRenderTime/1000, 1))), 140, guiHeight - 20);
  
  text("Rays this frame: ", 10, guiHeight - 5);
  text(commas(raysThisFrame), 140, guiHeight - 5);
}

void ImageSettings(){
  fill(0);
  textSize(16);
  textAlign(CENTER);
  text("Image Settings", guiWidth / 2, 18);
  
  textAlign(LEFT);
  textSize(12);
  textLeading(14);
  
  NormBar(bloomStrenBar, "Bloom Strength", bloomStrength, 0, 4, false, new barInter(){public void onChange(float v){
    bloomStrength = max(v, 0);
    bloomToggle = bloomStrength != 0;
    imageUpdated = true;
  }});
  
  bloomSize = round(NormBar(bloomSizeBar, "Bloom Size", bloomSize, 0, 20, true, new barInter(){public void onChange(float v){
    imageUpdated = true;
  }}));
  
  exposure = NormBar(exposureBar, "Exposure", exposure, 0, 2, false, new barInter(){public void onChange(float v){
    imageUpdated = true;
  }});
  
  contrast = NormBar(contrastBar, "Contrast", contrast, -1, 1, false, new barInter(){public void onChange(float v){
    imageUpdated = true;
  }});
}

void initalizeBars(){ // extra code to configure scroll bars that will get called only once from the setup function
  bloomStrenBar.setSliderPos(bloomStrength / 4);
  bloomSizeBar.setSliderPos((float)bloomSize / 20);
  exposureBar.setSliderPos(exposure / 2);
  contrastBar.setSliderPos((contrast + 1) / 2);
  cameraFOVBar.setSliderPos(Cam.Fov / PI * 2 * (1.01) + 0.01);
  bloomSizeBar.T.intOnly = true;
  cameraResBar.T.intOnly = true;
  tileDivisionsBar.T.intOnly = true;
  cameraResBar.setSliderPos((float)(Res - 1) / 9);
  samplesBar.setSliderPos((float)(samples - 1) / 100);
  cameraPhiBar.setSliderPos((cameraAngle.y / (PI/2 - 0.01) + 1) / 2);
  scrollArea.maxScroll = 1000;
  
  if(bloomStrength == 0){
    bloomToggle = false;
  }else{
    bloomToggle = true;
  }
}

void moveObjects(){
  if(getKey(ESC).released && objectSelected){ // if escape is pressed set selected object to null
    if(objectGrabbed){
      objectGrabbed = false;
      selectedObject.pos = originalPosition;
    }else if(objectRotating){
      objectRotating = false;
      selectedObject.SetRotation(originalAngle);
    }else{
      selectedObject = null;
      objectSelected = false;
    }
    directions = 7;
    preresUpdate = true;
  }
  
  if(objectSelected && !objectGrabbed && getKey('G').released){
    if(objectRotating){
      selectedObject.SetRotation(originalAngle);
      objectRotating = false;
    }
    objectGrabbed = true;
    originalPosition = selectedObject.pos.copy();
    selPos.x = mouseX; selPos.y = mouseY;
    directions = 7;
  }
  
  if(objectSelected && !objectRotating && getKey('R').released){
    if(objectGrabbed){
      selectedObject.pos = originalPosition;
      objectGrabbed = false;
    }
    objectRotating = true;
    originalAngle = selectedObject.Q.copy();
    originalPosition = selectedObject.pos.copy();;
    selPos.x = mouseX; selPos.y = mouseY;
    directions = 7;
  }
  
  if(objectGrabbed){ // object is being translated
    int pdir = directions;
    if(getKey('X').pressed){
      directions = getKey(SHIFT).held ? 6 : 1;
    }else if(getKey('Y').pressed){
      directions = getKey(SHIFT).held ? 5 : 2;
    }else if(getKey('Z').pressed){
      directions = getKey(SHIFT).held ? 3 : 4;
    }
    
    PVector norm;
    if((directions == 1 || directions == 2 || directions == 4)){
      PVector Xdir = new PVector(directions&1, (directions>>1)&1, (directions>>2)&1);
      PVector Ydir = new PVector(0, 0, 1);
      if(directions == 4){Ydir = Cam.b;}
      norm = Xdir.cross(Ydir);
    }else if(directions == 7){
      norm = Cam.t;
    }else{
      int l = 0;
      if(directions == 4){l = 4;}else
      {l = ((directions + 1) % 2) + 1;}
      PVector Xdir = new PVector(l&1, (l&2)/2, (l&4)/4);
      l = directions - l;
      PVector Ydir = new PVector(l&1, (l&2)/2, (l&4)/4);
      
      norm = Xdir.cross(Ydir).normalize();
    }
    PVector rpos = PVector.sub(originalPosition, Cam.Pos);
    PVector rdir = Cam.getRay(mouseX / (float)Res, mouseY / (float)Res);
    
    float d = -rpos.dot(norm) / rdir.dot(norm);
    PVector hpos = PVector.mult(rdir, d).add(rpos);
    multEle(hpos, new PVector(directions&1, (directions>>1)&1, (directions>>2)&1));
    hpos.mult(-1).add(originalPosition);
    selectedObject.pos = hpos;
    preresUpdate = mouseX != pmouseX || mouseY != pmouseY || directions != pdir;
  }
  
  if(objectRotating){
    int pdir = directions;
    if(getKey('X').pressed){
      directions = getKey(SHIFT).held ? 6 : 1;
    }else if(getKey('Y').pressed){
      directions = getKey(SHIFT).held ? 5 : 2;
    }else if(getKey('Z').pressed){
      directions = getKey(SHIFT).held ? 3 : 4;
    }
    PVector axis;
    if(directions == 1 || directions == 2 || directions == 4){
      axis = new PVector(directions&1, (directions>>1)&1, (directions>>2)&1).mult(-1);
      multEle(axis, Sign(Cam.t));
    }else if(directions == 7){
      axis = PVector.mult(Cam.t, -1);
    }else{
      int d = ~directions;
      axis = originalAngle.ApplyTo(new PVector(d&1, (d>>1)&1, (d>>2)&1));
    }
    PVector objectPos = Cam.WorldToScreen(selectedObject.pos);
    
    float angle = atan2(objectPos.y - selPos.y, objectPos.x - selPos.x) - atan2(objectPos.y - mouseY, objectPos.x - mouseX);
    
    Quaternion newQuat = GetRotationAbout(axis, angle);
    newQuat.PostMultiply(originalAngle);
    selectedObject.SetRotation(newQuat);
    preresUpdate = mouseX != pmouseX || mouseY != pmouseY || directions != pdir;
  }
  
  if(getKey(ENTER).held || getKey(RETURN).held){
    objectGrabbed = false;
    objectRotating = false;
    preresUpdate = true;
  }
}

void DrawLine(PVector A, PVector B){
  PVector OPos = Cam.WorldToScreen(A);
  PVector X = Cam.WorldToScreen(B);
  PVector dir = PVector.sub(OPos, X).normalize();
  PVector dirP = new PVector(-dir.y, dir.x);
  
  PVector C = PVector.mult(dirP, dirP.dot(X));
  
  float lim = drawWidth + drawHeight;
  float lowExtent = constrain(-C.x / dir.x, -lim, lim);
  float highExtent = constrain((drawWidth - C.x) / dir.x, -lim, lim);
  line(C.x + dir.x * lowExtent, C.y + dir.y * lowExtent, C.x + dir.x * highExtent, C.y + dir.y * highExtent);
}

void DrawAxes(){
  if(!objectSelected){return;}
  strokeWeight(1);
  if(directions != 7 && (objectGrabbed || (objectRotating && (directions == 1 || directions == 2 || directions == 4)))){
    if((directions & 1) != 0){
      stroke(255, 0, 0);
      DrawLine(originalPosition, new PVector(1, 0, 0).add(originalPosition));
    }
    if((directions & 2) != 0){
      stroke(0, 255, 0);
      DrawLine(originalPosition, new PVector(0, 1, 0).add(originalPosition));
    }
    if((directions & 4) != 0){
      stroke(0, 0, 255);
      DrawLine(originalPosition, new PVector(0, 0, 1).add(originalPosition));
    }
  }else if(objectRotating){
    if((directions & 1) == 0){
      stroke(255, 0, 0);
      DrawLine(originalPosition, originalAngle.ApplyTo(new PVector(1, 0, 0)).add(originalPosition));
    }
    if((directions & 2) == 0){
      stroke(0, 255, 0);
      DrawLine(originalPosition, originalAngle.ApplyTo(new PVector(0, 1, 0)).add(originalPosition));
    }
    if((directions & 4) == 0){
      stroke(0, 0, 255);
      DrawLine(originalPosition, originalAngle.ApplyTo(new PVector(0, 0, 1)).add(originalPosition));
    }
  }
}
