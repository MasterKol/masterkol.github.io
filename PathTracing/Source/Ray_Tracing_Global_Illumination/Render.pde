int FrameNum = 1;
Color[] bloom;
float log255 = log(255);

void drawPreRes(){
  int st = millis();
  int iy;
  //Color c;
  Hit dummyHit = new Hit();
  //dummyHit.dist = 0;
  for(int j = 0; j < ImageHeight; j++){
    iy = j * ImageWidth;
    boolean lastInter = false;
    for(int i = 0; i < ImageWidth; i++){
      PVector x = Cam.Pos.copy();
      PVector dir = Cam.getRay(i, j);//PVector.add(PVector.add(Cam.p1m, PVector.mult(Cam.qx, (float)i-1)), PVector.mult(Cam.qy, (float)j-1)).normalize();
      //if(i == 300 && j == 300){println(Mult(Cam.qx, (float)i*Res-1), Mult(Cam.qy, (float)j*Res-1), Cam.p1m);}
      Ray r = new Ray(x, dir);
      
      dummyHit.dist = 10000;
      if(objectSelected){
        selObjectBuffer[iy + i] = selectedObject.Trace(r, dummyHit);
      }
      /*if(objectSelected && selectedObject.Trace(r, null) != lastInter){
        println("X");
        lastInter = !lastInter;
        image[iy + i] = new Color(0.988, 0.729, 0);
        continue;
      }*/
      
      image[iy + i] = getColor(r, 8, 1, i == mouseX/Res && j == mouseY/Res, true);
      
      if(drawingDepthBuffer){
        Hit h = new Hit();
        tracePath(r, h);
        depthBuffer[iy + i] = h.dist;
      }
      /*Hit h = new Hit();
      if(tracePath(r, h)){
        image[iy + i] = new Color((h.normal.x + 1) / 2, (h.normal.y + 1) / 2, (h.normal.z + 1) / 2);
      }else{
        image[iy + i] = new Color(0);
      }*/
      
      //image[iy + j].add(c);
      //buffer[iy + j] = c;
      //finalRender[iy + j] = c;
      /*for(int a = 0; a < Res; a++){
        for(int b = 0; b < Res; b++){
          pixels[i*Res + a + (j*Res + b)*width] = c;
        }
      }*/
    }
  }
  println("Draw Time: " + (millis() - st));
}

Color[] buffer;

void DrawFrameMT(){ // thread needs to check if preRes is true once in a while incase it needs to terminate itself
  //Time = millis();
  //int i = floor(width/2);
  //int j = floor(height/2);
  RenderTile[] tileArr = new RenderTile[tileSplit * tileSplit];
  int tilePxx = ceil((float)ImageWidth / tileSplit);
  int tilePxy = ceil((float)ImageWidth / tileSplit);
  //println("------");
  for(int ty = 0; ty < tileSplit; ty++){
    for(int tx = 0; tx < tileSplit; tx++){
      tileArr[ty * tileSplit + tx] = new RenderTile(tilePxx * tx, min(tilePxx * (tx+1), ImageWidth), tilePxy * ty, min(tilePxy * (ty+1), ImageHeight));
      //tileArr[ty * tileSplit + tx].start();
      //println(tilePxx * tx, min(tilePxx * (tx+1), ImageWidth), tilePxy * ty, min(tilePxy * (ty+1), ImageHeight));
    }
  }
  
  int[] running = new int[8];
  int next = 0;
  for(int i = 0; i < running.length; i++){running[i] = -1;}
  
  //boolean allDone = false;
  int numFinished = 0;
  while(numFinished < tileArr.length){
    for(int i = 0; i < running.length; i++){
      if(running[i] != -1 && tileArr[running[i]].finished){
        try{
          tileArr[running[i]].join();
        }catch(InterruptedException e){}
        running[i] = -1;
        numFinished++;
      }
      
      if(running[i] == -1 && next < tileArr.length){
        tileArr[next].start();
        running[i] = next++;
      }
    }
  }
  
  //println("X");
  /*for(int i = 0; i < tileArr.length; i++){
    //tileArr[i].join();
    //println(i);
    try{
      tileArr[i].join();
    }catch(InterruptedException e){
      //exit();
    }
    //println(tileArr[i].totalTraces);
    //totalTracedRays += tileArr[i].totalTraces;
  }*/
  
  //println("X");
  threadFinished.set(true);
  //println("Y");
}

PVector SampleAperature(float size){
  return PVector.random2D().mult(random(0, size)); // circle
}

class RenderTile extends Thread {
  int imin, imax, jmin, jmax;
  boolean finished;
  
  RenderTile(int imin, int imax, int jmin, int jmax){
    this.imin = imin;
    this.imax = imax;
    this.jmin = jmin;
    this.jmax = jmax;
    finished = false;
  }
  
  public void run(){
    int iy;
    PVector dir, x, focalPoint;
    //float dx, dy;
    PVector newPos, offset;
    for(int j = jmin; j < jmax; j++){
      iy = j * ImageWidth;
      for(int i = imin; i < imax; i++){
        x = Cam.Pos.copy();
        dir = PVector.add(PVector.add(Cam.p1m, PVector.mult(Cam.qx, (float)i-1+random(-0.5, 0.5))), PVector.mult(Cam.qy, (float)j-1+random(-0.5, 0.5))).normalize();
        //if(i == 300 && j == 300){println(Mult(Cam.qx, (float)i*Res-1), Mult(Cam.qy, (float)j*Res-1), Cam.p1m);}
        Ray r;
        if(apertureSize > 0){
          focalPoint = PVector.mult(dir, focalLength).add(Cam.Pos);
          offset = SampleAperature(apertureSize);//PVector.random2D().mult(random(0, apertureSize));
          //offset = new PVector(random(-1, 1), random(-1, 1)).mult(apertureSize);
          x = PVector.mult(Cam.b, offset.x).add(PVector.mult(Cam.v, offset.y)).add(Cam.Pos);
          
          dir = PVector.sub(focalPoint, x).normalize();
          r = new Ray(x, dir);
        }else{
          r = new Ray(Cam.Pos.copy(), dir);
        }
        
        buffer[iy + i] = getColor(r, maxBounces, 1, /*i == mouseX/Res && j == mouseY/Res*/ /*i == 82 && j == 77*/false, false);
        
        //image[iy + j].add(c);
        pixelsDrawn++;
      }
      if(preRes){finished = true;return;}
    }
    finished = true;
  }
}

int[] getObjectMap(){
  int[] out = new int[ImageHeight * ImageWidth];
  int iy;
  for(int j = 0; j < ImageHeight; j++){
    iy = j * ImageWidth;
    for(int i = 0; i < ImageWidth; i++){
      PVector x = Cam.Pos.copy();
      PVector dir = PVector.add(PVector.add(Cam.p1m, PVector.mult(Cam.qx, (float)i-1)), PVector.mult(Cam.qy, (float)j-1)).normalize();
      Ray r = new Ray(x, dir);
            
      Hit h = new Hit();
      if(tracePath(r, h)){
        out[iy + i] = Objs.indexOf(h.object);
      }else{
        out[iy + i] = -1;
      }
    }
  }
  
  return out;
}

int[] getNormalMap(){
  int[] out = new int[ImageHeight * ImageWidth];
  int iy;
  for(int j = 0; j < ImageHeight; j++){
    iy = j * ImageWidth;
    for(int i = 0; i < ImageWidth; i++){
      PVector x = Cam.Pos.copy();
      PVector dir = PVector.add(PVector.add(Cam.p1m, PVector.mult(Cam.qx, (float)i-1)), PVector.mult(Cam.qy, (float)j-1)).normalize();
      Ray r = new Ray(x, dir);
      
      Hit h = new Hit();
      if(tracePath(r, h)){
        out[iy + i] = (0xFF << 24) | ((int)((h.normal.x + 1) / 2) << 16) | ((int)((h.normal.y + 1) / 2) << 8) | (int)((h.normal.z + 1) / 2);
      }else{
        out[iy + i] = -1;
      }
    }
  }
  
  return out;
}
