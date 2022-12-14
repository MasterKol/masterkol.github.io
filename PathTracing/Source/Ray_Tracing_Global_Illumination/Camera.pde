class Camera{
  PVector w = new PVector(0, 0, -1); // world up
  PVector t/*forwards*/, b/*left/right*/, v/*up/down*/, g, qx, qy, p1m;
  PVector Pos, Target;
  float Fov;
  Camera(PVector CameraPos, PVector ViewTarget, float fov){
    Pos = CameraPos;
    Target = ViewTarget;
    Fov = fov;
    //UpdateCamera(CameraPos, ViewTarget, fov);
  }
  
  void UpdateCamera(PVector CameraPos, PVector ViewTarget, float fov){
    Pos = CameraPos;
    //Target = ViewTarget;
    //Target = PVector.add(Pos, new PVector(cos(cameraAngle.x) * cos(cameraAngle.y), sin(cameraAngle.x) * cos(cameraAngle.y), sin(cameraAngle.y)));
    Fov = fov;
    //t = PVector.sub(Target, Pos);
    //t.normalize();
    t = new PVector(sin(cameraAngle.x) * cos(cameraAngle.y), cos(cameraAngle.x) * cos(cameraAngle.y), sin(cameraAngle.y));
    b = w.cross(t);
    b.normalize();
    v = t.cross(b);
    v.normalize();
    g = new PVector(tan(fov/2), tan(fov/2)*drawHeight/drawWidth);
    qx = PVector.mult(b, 2*g.x/(floor(drawWidth/Res) -1));
    qy = PVector.mult(v, 2*g.y/(floor(drawHeight/Res) -1));
    //qx = Mult(b, 2*g.x/(width-1));
    //qy = Mult(v, 2*g.y/(height-1));
    p1m = PVector.sub(t, PVector.mult(b, g.x)).sub(PVector.mult(v, g.y));
    //println(g, qx, qy, p1m);
  }
  
  void UpdateCamera(){
    UpdateCamera(Pos, Target, Fov);
  }
  
  PVector getRay(float x, float y){
    return PVector.mult(qy, y - 1).add(PVector.mult(qx, x - 1).add(p1m)).normalize();
  }
  
  PVector WorldToScreen(PVector worldVector){
    PVector rpos = PVector.sub(Cam.Pos, worldVector);
    float iz = 1.0 / (t.dot(rpos) * tan(Cam.Fov/2));
    float x = (b.dot(rpos) * iz + 1) / 2 * drawWidth;
    float y = (v.dot(rpos) * iz + 1) / 2 * drawHeight;
    return new PVector(x, y);
  }
  
  void Move(){
    if(keyPressed){ // move camera around
      Shift('W', t,  0.1);    // move forwards
      Shift('S', t, -0.1);    // move backwards
      Shift('D', b,  0.1);    // move left
      Shift('A', b, -0.1);    // move right
      Shift(' ', w, -0.1);    // move up
      Shift(CONTROL, w, 0.1); // move down
    }
    
    if(draggingCamera && !objectGrabbed && !objectRotating){ // camera panning is disallowed while an object is being translated or rotated
      if(mouseButton == LEFT){ // pan camera
        cameraAngle.x = (cameraAngle.x + (float)(mouseX - pmouseX) / 100 + 2 * PI) % (2 * PI);
        cameraAngle.y = constrain(cameraAngle.y - (float)(mouseY - pmouseY) / 100, -PI/2 + 0.01, PI/2 - 0.01);
      }else if(mouseButton == CENTER){ // move camera in plane if middle mouse pressed
        Pos.add(PVector.mult(b, (pmouseX - mouseX) / 100.0));
        Pos.add(PVector.mult(v, (pmouseY - mouseY) / 100.0));
      }
      UpdateCamera();
      preresUpdate |= (mouseX != pmouseX) || (mouseY != pmouseY);
    }
  }
  
  // if key corrisponding to keyNum is held then camera is shifted in the direction of 'dir' multiplied by 'scale'
  void Shift(int keyNum, PVector dir, float scale){
    if(getKey(keyNum).held){
      Pos.add(PVector.mult(dir, scale));
      UpdateCamera();
      preresUpdate = true;
    }
  }
}
