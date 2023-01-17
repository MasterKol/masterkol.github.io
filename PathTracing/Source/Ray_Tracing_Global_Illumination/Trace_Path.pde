class Hit{
  UV uv = new UV();
  PVector normal = new PVector(0,0,0);
  PVector shadedNormal = new PVector(0,0,0);
  float dist;
  Object object;
  Hit(){}
}

class Ray{
  PVector pos, dir;
  
  Ray(PVector pos, PVector dir){
    this.pos = pos;
    this.dir = dir;
  }
}

class UV {
  float u = -1, v = -1;
  UV(){}
  UV(float u, float v){
    this.u = u;
    this.v = v;
  }
}

boolean tracePath(Ray r, Hit h){
  h.dist = 1000;
  
  for(Object o : Objs){
    o.Trace(r, h);
  }
  
  if(h.dist < 1000){
    return true;
  }else{
    return false;
  }
}
