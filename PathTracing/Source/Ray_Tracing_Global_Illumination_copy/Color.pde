class Color{
  float r, g, b;
  
  Color(float r, float g, float b){
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  Color(float v){
    r = v;
    g = v;
    b = v;
  }
  
  Color(Color c){
    r = c.r;
    g = c.g;
    b = c.b;
  }
  
  color getcolor(){
    return color(r*255, g*255, b*255);
  }
  
  Color add(float v){
    r += v;
    g += v;
    b += v;
    return this;
  }
  
  Color add(Color c){
    r += c.r;
    g += c.g;
    b += c.b;
    return this;
  }
  
  Color div(float v){
    r /= v;
    g /= v;
    b /= v;
    return this;
  }
  
  Color div(Color v){
    r /= v.r;
    g /= v.g;
    b /= v.b;
    return this;
  }
  
  Color mult(float v){
    r *= v;
    g *= v;
    b *= v;
    return this;
  }
  
  Color mult(Color v){
    r *= v.r;
    g *= v.g;
    b *= v.b;
    return this;
  }
  
  Color copy(){
    return new Color(r, g, b);
  }
  
  Color copy(Color s){
    r = s.r;
    g = s.g;
    b = s.b;
    return this;
  }
  
  Color sub(float v){
    r = max(r - v, 0);
    g = max(g - v, 0);
    b = max(b - v, 0);
    return this;
  }
  
  Color sub(Color v){
    r = max(r - v.r, 0);
    g = max(g - v.g, 0);
    b = max(b - v.b, 0);
    return this;
  }
  
  String toString(){
    return str(r) + ", " + str(g) + ", " + str(b);
  }
  
  Color Log(){
    r = log(r);
    g = log(g);
    b = log(b);
    return this;
  }
  
  Color Sq(){
    r *= r;
    g *= g;
    b *= b;
    return this;
  }
  
  float maxValue(){
    return max(max(r, g), b);
  }
  
  Color Relu(){
    r = max(r, 0);
    g = max(g, 0);
    b = max(b, 0);
    return this;
  }
}

/*Color dot(Color a, Color b){
  return new Color(a.r * b.r / 255, a.g * b.g / 255, a.b * b.b / 255);
}*/

Color dot(Color a, Color b){
  return new Color(a.r * b.r, a.g * b.g, a.b * b.b);
}

Color add(Color a, Color b){
  return new Color(a.r * b.r, a.g * b.g, a.b * b.b);
}

Color matMul(Color c, Color[] mat){
  assert(mat.length == 3);
  /*float r = mat[0].r * c.r + mat[0].g * c.g + mat[0].b * c.b;
  float g = mat[1].r * c.r + mat[1].g * c.g + mat[1].b * c.b;
  c.b = mat[2].r * c.r + mat[2].g * c.g + mat[2].b * c.b;
  c.g = g;
  c.r = r;
  return c;*/
  return new Color(
      mat[0].r * c.r + mat[0].g * c.g + mat[0].b * c.b,
      mat[1].r * c.r + mat[1].g * c.g + mat[1].b * c.b,
      mat[2].r * c.r + mat[2].g * c.g + mat[2].b * c.b
  );
}

Color lerpColor(Color a, Color b, float v){
  float vm1 = 1 - v;
  v = constrain(v, 0, 1);
  return new Color(a.r * vm1 + b.r * v, a.g * vm1 + b.g * v, a.b * vm1 + b.b * v);
}

Color toColor(color c){
  Color o = new Color(0);
  
  o.r = (float)((c >> 16) & 0xFF) / 255;
  o.g = (float)((c >> 8) & 0xFF) / 255;
  o.b = (float)(c & 0xFF) / 255;
  
  return o;
}
