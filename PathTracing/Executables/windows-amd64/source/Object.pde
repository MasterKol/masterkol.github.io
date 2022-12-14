HScrollbar RxBar = new HScrollbar(120, 10, 120, 12, "Rotation about axis");
HScrollbar RyBar = new HScrollbar(120, 30, 120, 12, "Vertical rotation");
HScrollbar RzBar = new HScrollbar(120, 50, 120, 12, "Horizontal rotation");

abstract class Object{
  Material mat;
  PVector pos;
  boolean invertNormals = false;
  Quaternion Q = new Quaternion(1, 0, 0, 0);
  PVector[] basisMatrix = new PVector[]{new PVector(1, 0, 0), new PVector(0, 1, 0), new PVector(0, 0, 1)};
  PVector scale = new PVector(1, 1, 1);
  PVector invScale = new PVector(1, 1, 1);
  
  Object(PVector pos, Material mat){
    this.mat = mat;
    this.pos = pos;
  }
  
  //boolean testIntersection(Ray r);
  abstract boolean Trace(Ray r, Hit h);
  abstract void drawGui();
  abstract float getGuiSize();
  abstract PVector getUVCords(PVector hpos);
  
  Material getMaterial(){
    return mat;
  }
  
  void setMaterial(Material m){
    mat = m;
  }
  
  void DrawRotationGUI(float offset){ // convert quaternion to roll, pitch, yaw then back...peak efficiency
    translate(0, offset);
    float oroll = (atan2(2 * (Q.w * Q.i + Q.j * Q.k), 1 - 2 *(Q.i * Q.i + Q.j * Q.j)) + TAU) % TAU;
    float opitch = asin(2 * (Q.w * Q.j - Q.i * Q.k));
    float oyaw = (atan2(2 * (Q.w * Q.k + Q.i * Q.j), 1 - 2 *(Q.j * Q.j + Q.k * Q.k)) + TAU) % TAU;
    float roll  = HDiffBar(RxBar, "Roll" , oroll , 0.2);
    float pitch = HDiffBar(RyBar, "Pitch", opitch, 0.2);
    float yaw   = HDiffBar(RzBar, "Yaw"  , oyaw  , 0.2);
    //NormBar(HScrollbar bar, String txt, float val, float min, float max, boolean Constrain)
    if(roll != oroll || pitch != opitch || yaw != oyaw){
      roll /= 2;
      pitch = constrain(pitch, -PI/2 + 0.001, PI/2 - 0.001) / 2;
      yaw /= 2;
      Q.w = cos(roll) * cos(pitch) * cos(yaw) + sin(roll) * sin(pitch) * sin(yaw);
      Q.i = sin(roll) * cos(pitch) * cos(yaw) - cos(roll) * sin(pitch) * sin(yaw);
      Q.j = cos(roll) * sin(pitch) * cos(yaw) + sin(roll) * cos(pitch) * sin(yaw);
      Q.k = cos(roll) * cos(pitch) * sin(yaw) - sin(roll) * sin(pitch) * cos(yaw);
      UpdateBasisMatrix();
      preresUpdate = true;
    }
    translate(0, -offset);
  }
  
  void Rotate(Quaternion q){
    Q.PreMultiply(q);
    UpdateBasisMatrix();
  }
  
  void RotatePost(Quaternion q){
    Q.PostMultiply(q);
    UpdateBasisMatrix();
  }
  
  void SetRotation(Quaternion q){
    Q = q.copy();
    UpdateBasisMatrix();
  }
  
  void setScale(PVector scale){
    this.scale = new PVector(1 / scale.x, 1 / scale.y, 1 / scale.z);
    this.invScale = scale.copy();
  }
  
  void setScale(float scale){
    float is = 1 / scale;
    this.scale = new PVector(is, is, is);
    invScale = new PVector(scale, scale, scale);
  }
  
  void UpdateBasisMatrix(){
    basisMatrix[0] = Q.ApplyTo(new PVector(1, 0, 0));
    basisMatrix[1] = Q.ApplyTo(new PVector(0, 1, 0));
    basisMatrix[2] = Q.ApplyTo(new PVector(0, 0, 1));
  }
  
  PVector ApplyBasisMatrixScaled(PVector v){
    return new PVector(v.dot(basisMatrix[0]) * scale.x, v.dot(basisMatrix[1]) * scale.y, v.dot(basisMatrix[2]) * scale.z);
  }
  
  PVector ApplyBasisMatrix(PVector v){
    return new PVector(v.dot(basisMatrix[0]), v.dot(basisMatrix[1]), v.dot(basisMatrix[2]));
  }
  
  PVector ApplyInverseBasisMatrix(PVector v){
    return new PVector(v.x * basisMatrix[0].x + v.y * basisMatrix[1].x + v.z * basisMatrix[2].x,
                       v.x * basisMatrix[0].y + v.y * basisMatrix[1].y + v.z * basisMatrix[2].y,
                       v.x * basisMatrix[0].z + v.y * basisMatrix[1].z + v.z * basisMatrix[2].z);
  }
  
  PVector ApplyInverseBasisMatrixScaled(PVector vec){
    PVector v = multEle(vec, invScale);
    return new PVector(v.x * basisMatrix[0].x + v.y * basisMatrix[1].x + v.z * basisMatrix[2].x,
                       v.x * basisMatrix[0].y + v.y * basisMatrix[1].y + v.z * basisMatrix[2].y,
                       v.x * basisMatrix[0].z + v.y * basisMatrix[1].z + v.z * basisMatrix[2].z);
  }
}

HScrollbar radiusBar = new HScrollbar(120, 10, 120, 12);
class Sphere extends Object{
  float rad;
  
  Sphere(PVector pos, float rad, Material mat){
    super(pos, mat);
    this.rad = rad;
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = PVector.sub(r.pos, pos);
    float Dot = r.dir.dot(rpos);
    float del = Dot * Dot - rpos.dot(rpos) + rad * rad;
    
    if(del < 0){
      return false;
    }
    del = sqrt(del);
    float d = min(-Dot + del, -Dot - del);
    if(d < 0){
      d = max(-Dot + del, -Dot - del);
    }

    if(d < 0 || d > h.dist){
      return false;
    }
    
    h.dist = d;
    PVector hpos = PVector.mult(r.dir, d).add(r.pos);
    h.normal = PVector.sub(hpos, pos).normalize();
    h.shadedNormal = h.normal;
    h.object = this;
    if(invertNormals){
      h.normal.mult(-1);
    }
    return true;
  }
  
  float getGuiSize(){
    return 30;
  }
  
  PVector getUVCords(PVector hpos){
    PVector rpos = PVector.sub(hpos, pos).normalize();
    return new PVector((atan2(rpos.y, rpos.x) / TAU + 1.5) % 1, acos(rpos.z) / PI);
  }
  
  void drawGui(){
    rad = max(HDiffBar(radiusBar, "Radius", rad, 0.2), 0);
  }
}

HScrollbar sxBar = new HScrollbar(120, 80, 120, 12);
HScrollbar syBar = new HScrollbar(120, 100, 120, 12);
class Plane extends Object{
  float w, h;
  
  Plane(PVector pos, PVector norm, float w, float h, float angle, Material mat){
    super(pos, mat);
    this.w = w;
    this.h = h;
    SetRotation(GetRotationTo(norm, angle));
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = PVector.sub(r.pos, pos);
    
    if(rpos.dot(basisMatrix[2]) * r.dir.dot(basisMatrix[2]) > 0){
      return false;
    }
    
    float d = -rpos.dot(basisMatrix[2]) / r.dir.dot(basisMatrix[2]);
    if(d > h.dist || d < 0){
      return false;
    }
    
    //PVector hpos = PVector.mult(r.dir, d).add(r.pos);
    PVector rhpos = PVector.mult(r.dir, d).add(rpos);//PVector.sub(hpos, pos);
    if(abs(rhpos.dot(basisMatrix[0])) > this.w || abs(rhpos.dot(basisMatrix[1])) > this.h){
      return false;
    }
    
    //h.pos = hpos;
    h.object = this;
    h.dist = d;
    h.uv.u = 0.5 * (rhpos.dot(basisMatrix[0]) + this.w) / this.w;
    h.uv.v = 0.5 * (rhpos.dot(basisMatrix[1]) + this.h) / this.h;
    CopyTo(h.normal, basisMatrix[2]);
    h.shadedNormal = h.normal;
    
    return true;
  }
  
  float getGuiSize(){
    return 120;
  }
  
  void drawGui(){
    DrawRotationGUI(0);
    
    w = max(HDiffBar(sxBar, "Width", w, 0.2), 0);
    h = max(HDiffBar(syBar, "Height", h, 0.2), 0);
  }
  
  PVector getUVCords(PVector hpos){
    PVector p = ApplyBasisMatrix(PVector.sub(hpos, pos));
    p.x -= w;
    p.y -= h;
    p.z = max(w, h);
    return p;
  }
}

class Disc extends Object{
  float rad;
  
  Disc(PVector pos, PVector norm, float rad, Material mat){
    super(pos, mat);
    this.rad = rad;
    SetRotation(GetRotationTo(norm, 0));
    //println(pointing);
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = PVector.sub(r.pos, pos);
    
    if(rpos.dot(basisMatrix[2]) * r.dir.dot(basisMatrix[2]) > 0){
      return false;
    }
    
    float d = -rpos.dot(basisMatrix[2]) / r.dir.dot(basisMatrix[2]);
    if(d > h.dist || d < 0){
      return false;
    }
    
    //PVector hpos = PVector.mult(r.dir, d).add(r.pos);
    PVector rhpos = PVector.mult(r.dir, d).add(rpos);//PVector.sub(hpos, pos);
    if(rhpos.cross(basisMatrix[2]).magSq() > rad * rad){
      return false;
    }
    
    //h.pos = hpos;
    h.object = this;
    h.dist = d;
    
    CopyTo(h.normal, basisMatrix[2]);
    h.shadedNormal = h.normal;
    
    return true;
  }
  
  float getGuiSize(){
    return 100;
  }
  
  void drawGui(){
    rad = max(HDiffBar(radiusBar, "Radius", rad, 0.2), 0);
    
    DrawRotationGUI(30);
  }
  
  PVector getUVCords(PVector hpos){
    PVector p = ApplyBasisMatrix(PVector.sub(hpos, pos));
    p.x -= rad;
    p.y -= rad;
    p.z = rad;
    return p;
  }
}

HScrollbar sizeXBar = new HScrollbar(120, 10, 120, 12);
HScrollbar sizeYBar = new HScrollbar(120, 30, 120, 12);
HScrollbar sizeZBar = new HScrollbar(120, 50, 120, 12);
class Box extends Object {
  PVector dims;
  
  Box(PVector pos, PVector dims, Material mat){
    super(pos, mat);
    this.dims = dims;
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = PVector.sub(r.pos, pos);
    
    rpos = ApplyBasisMatrix(rpos);
    PVector rdir = ApplyBasisMatrix(r.dir);
    
    float  tmin = (-dims.x * Sign(rdir.x) - rpos.x) / rdir.x;
    float  tmax = ( dims.x * Sign(rdir.x) - rpos.x) / rdir.x;
    float tymin = (-dims.y * Sign(rdir.y) - rpos.y) / rdir.y;
    float tymax = ( dims.y * Sign(rdir.y) - rpos.y) / rdir.y;
    
    if(tmin > tymax || tymin > tmax){
      return false;
    }
    
    tmin = max(tmin, tymin);
    tmax = min(tmax, tymax);
    
    float tzmin = (-dims.z * Sign(rdir.z) - rpos.z) / rdir.z;
    float tzmax = ( dims.z * Sign(rdir.z) - rpos.z) / rdir.z;
    
    if(tmin > tzmax || tzmin > tmax){
      return false;
    }
    
    tmin = max(tzmin, tmin);
    tmax = min(tzmax, tmax);
    
    if(tmin < 0){
      tmin = tmax;
    }
    if(tmin < 0 || tmin > h.dist){
      return false;
    }
    
    h.dist = tmin;
    //h.pos = PVector.mult(r.dir, tmin).add(r.pos);
    h.object = this;
    
    rpos.add(PVector.mult(rdir, tmin));//PVector.sub(h.pos, pos);
    
    h.normal = new PVector(rpos.x / dims.x, rpos.y / dims.y, rpos.z / dims.z);
    if(abs(h.normal.x) > abs(h.normal.y) && abs(h.normal.x) > abs(h.normal.z)){
      h.normal = PVector.mult(basisMatrix[0], Sign(rpos.x));
    }else if(abs(h.normal.y) > abs(h.normal.z)){
      h.normal = PVector.mult(basisMatrix[1], Sign(rpos.y));
    }else{
      h.normal = PVector.mult(basisMatrix[2], Sign(rpos.z));
    }
    h.shadedNormal = h.normal;
    
    //h.normal
    
    return true;
  }
  
  float getGuiSize(){
    return 140;
  }
  
  void drawGui(){
    dims.x = max(HDiffBar(sizeXBar, "X Size", dims.x, 0.2), 0.0001);
    dims.y = max(HDiffBar(sizeYBar, "Y Size", dims.y, 0.2), 0.0001);
    dims.z = max(HDiffBar(sizeZBar, "Z Size", dims.z, 0.2), 0.0001);
    
    DrawRotationGUI(70);
  }
  
  PVector getUVCords(PVector hpos){
    PVector p = ApplyBasisMatrix(PVector.sub(hpos, pos));
    float maxp = max(max(p.x, p.y), p.z);
    if(maxp == p.x){
      p.x = p.y;
      p.y = p.z;
      p.z = max(dims.y, dims.z);
    }else if(maxp == p.y){
      p.y = p.z;
      p.z = max(dims.x, dims.z);
    }else if(maxp == p.z){
      p.z = max(dims.x, dims.y);
    }
    return p;
  }
}

class Triangle extends Object implements Primitive{
  private final PVector[] Vs = new PVector[3];
  //private float minX, maxX;
  PVector norm; // 'local' normal will always be 0,0,1 as all rotation will be handeled by the 'global' object rotation
  
  Triangle(PVector pos, PVector V1, PVector V2, PVector V3, Material mat){
    super(pos, mat);
    Vs[0] = V1;
    Vs[1] = V2;
    Vs[2] = V3;
    UpdateNormal();
  }
  
  Triangle(PVector pos, PVector[] verts, Material mat){
    super(pos, mat);
    assert(verts.length >= 3);
    for(int i = 0; i < 3; i++){
      Vs[i] = verts[i].copy();
    }
    UpdateNormal();
  }
  
  PVector normal;
  void UpdateNormal(){
    /*for(int i = 0; i < 3; i++){
      Vs[i].add(pos);
    }
    normal = PVector.sub(Vs[1], Vs[0]).cross(PVector.sub(Vs[2], Vs[0])).normalize();*/
    
    boolean verbose = false;
    pos.add(Vs[0]);
    for(int i = 1; i < 3; i++){
      Vs[i].sub(Vs[0]);
    }
    Vs[0] = new PVector(0, 0, 0);
    
    if(verbose){
      println("======");
      for(int i = 0; i < 3; i++){
        println(Vs[i], Vs[i].mag(), PVector.sub(Vs[i], Vs[(i + 1)%3]).mag());
      }
    }
    
    PVector norm = Vs[1].cross(Vs[2]);
    Quaternion Nrot = GetRotationTo(norm, 0);
    Nrot.Invert();
    for(int i = 1; i < 3; i++){
      Vs[i] = Nrot.ApplyTo(Vs[i]);
      //Vs[i].z = 0;
    }
    Nrot.Invert();
    Rotate(Nrot);
    //println("norm: ",  norm);
    
    if(verbose){
      println("A");
      for(int i = 0; i < 3; i++){
        println(Vs[i], Vs[i].mag(), PVector.sub(Vs[i], Vs[(i + 1)%3]).mag());
      }
    }
    
    if(Vs[1].cross(Vs[2]).z < 0){
      PVector t = Vs[1];
      Vs[1] = Vs[2];
      Vs[2] = t;
    }
    
    //Vs[1].x *= -1;
    //Vs[2].mult(-1);
    if(verbose){
      println("B");
      for(int i = 0; i < 3; i++){
        println(Vs[i], Vs[i].mag(), PVector.sub(Vs[i], Vs[(i + 1)%3]).mag());
      }
    }
    
    //float co = abs(Vs[1].x) / Vs[1].mag();
    Quaternion Q = new Quaternion(Vs[1].mag() + abs(Vs[1].x), 0, 0, -Vs[1].y * Sign(Vs[1].x));
    //println(Q);
    Vs[1] = Q.ApplyTo(Vs[1]);
    Vs[2] = Q.ApplyTo(Vs[2]);
    Q.Invert();
    RotatePost(Q);
    
    if(verbose){
      println("===C===");
      for(int i = 0; i < 3; i++){
        println(Vs[i], Vs[i].mag(), PVector.sub(Vs[i], Vs[(i + 1)%3]).mag());
      }
    }
    
    if(Vs[2].y < 0){
      Quaternion Q2 = new Quaternion(0, 1, 0, 0); // 180 deg rotation around the X axis
      RotatePost(Q2);
      Vs[2].y *= -1;
    }
    
    if(Vs[1].x < 0){
      Quaternion Q2 = new Quaternion(0, 0, 1, 0); // 180 deg rotation around the Y axis
      RotatePost(Q2);
      Vs[1].x *= -1;
      Vs[2].x *= -1;
    }
    norm = basisMatrix[2].copy();
    basisMatrix[0].div(Vs[1].x);
    
    Vs[2].x /= Vs[1].x;
    Vs[1].x = 1;
    
    basisMatrix[1].div(Vs[2].y);
    Vs[2].y = 1;
    
    //minX = min(0, Vs[2].x);
    //maxX = max(Vs[1].x, Vs[2].x);
    
    if(verbose){
      println("===D===");
      for(int i = 0; i < 3; i++){
        println(Vs[i], Vs[i].mag(), PVector.sub(Vs[i], Vs[(i + 1)%3]).mag());
      }
    }
  }
  
  void getBoundingBox(PVector TL, PVector BR){
    PVector T = ApplyInverseBasisMatrix(Vs[0]);
    CopyTo(TL, T);
    CopyTo(BR, T);
    for(int i = 1; i < 3; i++){
      T = ApplyInverseBasisMatrix(Vs[i]);
      TL.x = min(TL.x, T.x); BR.x = max(BR.x, T.x);
      TL.y = min(TL.y, T.y); BR.y = max(BR.y, T.y);
      TL.z = min(TL.z, T.z); BR.z = max(BR.z, T.z);
    }
    TL.add(pos);
    BR.add(pos);
  }
  
  boolean Trace(Ray r, Hit h){
    /*PVector v0v1 = PVector.sub(Vs[1], Vs[0]); // copied from scratch-a-pixel
    PVector v0v2 = PVector.sub(Vs[2], Vs[0]);
    
    PVector pvec = r.dir.cross(v0v2);
    float invDet = 1.0 / v0v1.dot(pvec);
    
    //float invDet = 1.0 / det;
    PVector tvec = PVector.sub(r.pos, Vs[0]);
    float u = tvec.dot(pvec) * invDet;
    if(u < 0 || u > 1){return false;}
    
    PVector qvec = tvec.cross(v0v1);
    float v = r.dir.dot(qvec) * invDet;
    if(v < 0 || v + u > 1){return false;}
    
    float d = v0v2.dot(qvec) * invDet;
    
    if(d < 0 || h.dist < d){return false;}
    
    h.normal = normal.copy();
    h.dist = d;
    h.pos = PVector.mult(r.dir, d).add(r.pos);
    h.object = this;
    
    return true;*/
    
    PVector rpos = PVector.sub(r.pos, pos);
    
    float rpz = rpos.dot(basisMatrix[2]);
    float rdz = r.dir.dot(basisMatrix[2]);
    
    if((rpz < 0) == (rdz < 0)){
      return false;
    }

    float d = -rpz / rdz;
    if(h.dist < d){
      return false;
    }
    
    //PVector hpos = PVector.mult(r.dir, d).add(r.pos);
    PVector lhpos = PVector.mult(r.dir, d).add(rpos);//PVector.sub(hpos, pos);
    float hy = lhpos.dot(basisMatrix[1]);
    if(hy < 0 || 1 < hy){//(Vs[2].y < 0 || hy > Vs[2].y) ^ (hy < 0)){// 
      return false;
    }
    float hx = lhpos.dot(basisMatrix[0]) - Vs[2].x * hy;
    if(/*hx < minX || maxX < hx ||
          (Vs[2].y * hx - Vs[2].x * hy) < 0 ||
          (Vs[2].y * (Vs[1].x - hx) + hy * (Vs[2].x - Vs[1].x)) < 0*/ hx < 0 || hx + hy > 1){
      return false;
    }
    
    //h.pos = hpos;
    h.object = this;
    h.dist = d;
    
    CopyTo(h.normal, basisMatrix[2]);
    h.shadedNormal = h.normal;
    
    return true;
  }
  
  float getGuiSize(){
    return 120;
  }
  
  void drawGui(){
    DrawRotationGUI(0);
  }
  
  PVector getUVCords(PVector hpos){
    PVector p = ApplyBasisMatrix(PVector.sub(hpos, pos));
    return p;
  }
}

HScrollbar objectScaleBar = new HScrollbar(120, 0, 120, 12);
CheckBox objectSmoothShadeCheckbox = new CheckBox(30, 15, 100, 12, "Smooth Shade");

class Mesh extends Object {
  PVector[] verts;
  int[] faces;
  
  PVector[] vertNorms;
  int[] vnInds;
  
  UV[] vertUVs;
  int[] uvInds;
  
  float radSq;
  KDTree tree;
  boolean smoothShading = true;
  boolean useUVs = true;
  MeshTriangle[] mesh;
  
  Mesh(PVector pos, String fileName, boolean trySmoothShade, boolean tryUseUVs, Material mat){
    super(pos, mat);
    radSq = 0;
    smoothShading = trySmoothShade;
    useUVs = tryUseUVs;
    LoadTris(ReadOBJ(fileName));
  }
  
  void LoadTris(ObjParts objprts){
    verts = objprts.verts;
    vertNorms = objprts.vertNorms;
    vnInds = objprts.vnInds;
    vertUVs = objprts.vertUVs;
    uvInds = objprts.uvInds;
    
    useUVs &= uvInds != null;
    smoothShading &= vnInds != null;
    
    mesh = new MeshTriangle[objprts.faces.length / 3];
    
    for(int i = 0; i < mesh.length; i++){
      mesh[i] = new MeshTriangle(i, objprts.faces[i * 3], objprts.faces[i * 3 + 1], objprts.faces[i * 3 + 2]);
    }
    
    tree = new KDTree(mesh);
    println("Nodes: " + tree.nodes.length + " ; Faces: " + mesh.length);
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = PVector.sub(r.pos, pos);
    
    PVector trpos = ApplyBasisMatrixScaled(rpos);
    PVector trdir = ApplyBasisMatrix(r.dir);
    Ray transRay = new Ray(trpos, trdir);
    Hit localHit = new Hit();
    localHit.dist = h.dist * scale.x;
    
    if(!tree.Trace(transRay, localHit)){
      return false;
    }
    
    h.dist = localHit.dist / scale.x;
    
    //h.pos = ApplyInverseBasisMatrixScaled(localHit.pos).add(pos);
    //h.pos = PVector.mult(r.dir, h.dist).add(r.pos);
    h.object = this;
    
    int hitInd = (int)localHit.normal.x;
    h.normal = mesh[hitInd].getNormal();
    if(smoothShading){
      h.shadedNormal = mesh[hitInd].getShadedNormal(localHit.normal.y, localHit.normal.z);
    }else{
      h.shadedNormal = h.normal.copy();
    }
    h.uv = mesh[hitInd].getUV(localHit.normal.y, localHit.normal.z);
    //h.normal = ApplyInverseBasisMatrix(h.normal).normalize();
    
    return true;
  }
  
  void drawGui(){
    float change = HDiffBar(objectScaleBar, "Scale", 1 / scale.x, 0.1); // +- 0.1
    setScale(max(change, 0.00001));
    
    objectSmoothShadeCheckbox.setEnabled(vertNorms != null);
    objectSmoothShadeCheckbox.setState(smoothShading);
    objectSmoothShadeCheckbox.display();
    objectSmoothShadeCheckbox.update();
    if(objectSmoothShadeCheckbox.state != smoothShading){ // changed
      smoothShading = !smoothShading;
      preresUpdate = true;
    }
  }
  
  float getGuiSize(){
      return 50;
  }
  
  PVector getUVCords(PVector hpos){
    return new PVector(0, 0);
  }
  
  private class MeshTriangle implements Primitive {
    int v0, v1, v2;
    int ind;
    MeshTriangle(int ind, int v0, int v1, int v2){
      this.ind = ind;
      this.v0 = v0;
      this.v1 = v1;
      this.v2 = v2;
    }
    
    void getBoundingBox(PVector TL, PVector BR){
      CopyTo(TL, verts[v0]);
      CopyTo(BR, verts[v0]);
      
      TL.x = min(TL.x, verts[v1].x); TL.y = min(TL.y, verts[v1].y); TL.z = min(TL.z, verts[v1].z);
      BR.x = max(BR.x, verts[v1].x); BR.y = max(BR.y, verts[v1].y); BR.z = max(BR.z, verts[v1].z);
      
      TL.x = min(TL.x, verts[v2].x); TL.y = min(TL.y, verts[v2].y); TL.z = min(TL.z, verts[v2].z);
      BR.x = max(BR.x, verts[v2].x); BR.y = max(BR.y, verts[v2].y); BR.z = max(BR.z, verts[v2].z);
    }
    
    boolean Trace(Ray r, Hit h){
      PVector v0v1 = PVector.sub(verts[v1], verts[v0]); // Moller-Trombore alorithm, copied from scratch-a-pixel
      PVector v0v2 = PVector.sub(verts[v2], verts[v0]);
      
      PVector pvec = r.dir.cross(v0v2);
      float invDet = 1.0 / v0v1.dot(pvec);
      
      //float invDet = 1.0 / det;
      PVector tvec = PVector.sub(r.pos, verts[v0]);
      float u = tvec.dot(pvec) * invDet;
      if(u < 0 || u > 1){return false;}
      
      PVector qvec = tvec.cross(v0v1);
      float v = r.dir.dot(qvec) * invDet;
      if(v < 0 || v + u > 1){return false;}
      
      float d = v0v2.dot(qvec) * invDet;
      
      if(d < 0 || h.dist < d){return false;}
      
      h.dist = d;
      h.normal.x = ind;
      h.normal.y = u;
      h.normal.z = v;
      
      return true;
    }
    
    PVector getNormal(){
      return ApplyInverseBasisMatrix(PVector.sub(verts[v1], verts[v0]).cross(PVector.sub(verts[v2], verts[v0])).normalize());
    }
    
    PVector getShadedNormal(float u, float v){
      int b = ind * 3;
      PVector sn = PVector.mult(vertNorms[vnInds[b]], 1 - u - v).add(PVector.mult(vertNorms[vnInds[b+1]], u)).add(PVector.mult(vertNorms[vnInds[b+2]], v));
      sn = ApplyInverseBasisMatrix(sn);
      //PVector tn = ApplyInverseBasisMatrix(PVector.sub(verts[v1], verts[v0]).cross(PVector.sub(verts[v2], verts[v0])));
      /*if((tn.dot(r.dir) * sn.dot(r.dir) < 0)){
        //sn.mult(-1);
        return tn.normalize();
      }*/
      return sn.normalize();
    }
    
    UV getUV(float u, float v){
      if(!useUVs){
        return new UV(u, v);
      }
      int b = ind * 3;
      UV uv0 = vertUVs[uvInds[  b  ]];
      UV uv1 = vertUVs[uvInds[b + 1]];
      UV uv2 = vertUVs[uvInds[b + 2]];
      return new UV(uv0.u * (1 - u - v) + uv1.u * u + uv2.u * v,
                    uv0.v * (1 - u - v) + uv1.v * u + uv2.v * v);
    }
  }
}

class Instance extends Object {
  Object obj;
  Instance(Object obj, PVector pos, Material mat){
    super(pos, mat);
    this.obj = obj;
  }
  
  void drawGui(){
    obj.drawGui();
  }
  
  float getGuiSize(){
    return obj.getGuiSize();
  }
  
  boolean Trace(Ray r, Hit h){
    PVector rpos = obj.ApplyInverseBasisMatrixScaled(ApplyBasisMatrixScaled(PVector.sub(r.pos, pos))).add(obj.pos);
    PVector rdir = obj.ApplyInverseBasisMatrix(ApplyBasisMatrix(r.dir));
    Ray localRay = new Ray(rpos, rdir);
    
    if(!obj.Trace(localRay, h)){return false;}
    
    h.normal = ApplyInverseBasisMatrix(obj.ApplyBasisMatrix(h.normal));
    //h.pos = ApplyInverseBasisMatrixScaled(obj.ApplyBasisMatrixScaled(PVector.sub(h.pos, obj.pos))).add(pos);
    h.object = this;
    return true;
  }
  
  PVector getUVCords(PVector hpos){
    return obj.getUVCords(hpos);
  }
}
