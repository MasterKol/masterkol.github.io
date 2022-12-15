class Quaternion {
  float w, i, j, k;
  Quaternion(float w, float i, float j, float k){
    this.w = w;
    this.i = i;
    this.j = j;
    this.k = k;
    normalize();
  }
  
  Quaternion(float w, float i, float j, float k, boolean norm){
    this.w = w;
    this.i = i;
    this.j = j;
    this.k = k;
    if(norm){normalize();}
  }
  
  void normalize(){
    float l = sqrt(w * w + i * i + j * j + k * k);
    w /= l;
    i /= l;
    j /= l;
    k /= l;
  }
  
  PVector getVector(){
    Quaternion o = new Quaternion(-i, w, k, -j);
    Quaternion inv = new Quaternion(w, -i, -j, -k);
    o = Mult(o, inv);
    return new PVector(o.i, o.j, o.k);
  }
  
  float getAngle(){
    Quaternion o = new Quaternion(-i, w, k, -j);
    Quaternion inv = new Quaternion(w, -i, -j, -k);
    o = Mult(o, inv);
    return acos(o.w) * 2;
  }
  
  Quaternion PostMultiply(float aw, float ai, float aj, float ak){ // rotates about global axis
    float tw = w * aw - i * ai - j * aj - k * ak;
    float ti = w * ai + i * aw + j * ak - k * aj;
    float tj = w * aj - i * ak + j * aw + k * ai;
          k  = w * ak + i * aj - j * ai + k * aw;
    w = tw;
    i = ti;
    j = tj;
    return this;
  }
  
  Quaternion PostMultiply(Quaternion A){ // rotates about global axis
    PostMultiply(A.w, A.i, A.j, A.k);
    return this;
  }
  
  Quaternion PreMultiply(float aw, float ai, float aj, float ak){ // rotates about local axis
    float tw = aw * w - ai * i - aj * j - ak * k;
    float ti = aw * i + ai * w + aj * k - ak * j;
    float tj = aw * j - ai * k + aj * w + ak * i;
          k  = aw * k + ai * j - aj * i + ak * w;
    w = tw;
    i = ti;
    j = tj;
    return this;
  }
  
  Quaternion PreMultiply(Quaternion A){ // rotates about local axis
    PreMultiply(A.w, A.i, A.j, A.k);
    return this;
  }
  
  Quaternion Rotate(float aw, float ai, float aj, float ak){
    PreMultiply(aw, ai, aj, ak);
    PostMultiply(aw, -ai, -aj, -ak);
    return this;
  }
  
  Quaternion copy(){
    return new Quaternion(w, i, j, k);
  }
  
  String toString(){
    return "(" + w + ", " + i + ", " + j + ", " + k + ")";
  }
  
  PVector ApplyTo(PVector v){
    PVector q = new PVector(i, j, k);
    PVector t = q.cross(v).mult(2);
    return PVector.mult(t, w).add(v).add(q.cross(t));
  }
  
  void Invert(){
    i *= -1;
    j *= -1;
    k *= -1;
  }
}

Quaternion Mult(Quaternion A, Quaternion B){
  return new Quaternion(A.w * B.w - A.i * B.i - A.j * B.j - A.k * B.k,
                        A.w * B.i + A.i * B.w + A.j * B.k - A.k * B.j,
                        A.w * B.j - A.i * B.k + A.j * B.w + A.k * B.i,
                        A.w * B.k + A.i * B.j - A.j * B.i + A.k * B.w, false);
}

Quaternion GetRotationTo(PVector vector, float angle){
  PVector v = vector.copy().normalize();
  Quaternion out;
  if(v.z < -0.9999){
    PVector ov = orthVector(v);
    out = new Quaternion(0, ov.x, ov.y, ov.z);
  }else{
    out = new Quaternion(1 + v.z, -v.y, v.x, 0);
  }
  //Quaternion out = GetRotationBetween(new PVector(0, 0, 1), v);
  float sa = sin(angle / 2);
  out.PreMultiply(cos(angle / 2), sa * v.x, sa * v.y, sa * v.z);
  return out;
}

Quaternion GetRotationAbout(PVector vector, float angle){
  PVector v = vector.copy().normalize();
  float sa = sin(angle / 2);
  v.mult(sa);
  return new Quaternion(cos(angle / 2), v.x, v.y, v.z, false);
}

Quaternion GetRotationBetween(PVector V1, PVector V2){ // returns the quaternions that maps V1 to V2 using the minimum rotation angle
  float tl = sqrt(V1.magSq() * V2.magSq());
  if(V1.dot(V2) < -0.999999 * tl){
    PVector ov = orthVector(V1).normalize();
    return new Quaternion(0, ov.x, ov.y, ov.z);
  }
  PVector a = V1.cross(V2);
  return new Quaternion(tl + V1.dot(V2), a.x, a.y, a.z);
}
