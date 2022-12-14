void Blur(Color[] I, Color[] trgt, int w, int h, int r){
  Color[] inter = new Color[I.length];
  for(int i = 0; i < inter.length; i++){
    inter[i] = new Color(0);
  }
  
  boxBlurH(I, inter, w, h, r);
  boxBlurT(inter, I, w, h, r);
  boxBlurH(I, inter, w, h, r);
  boxBlurT(inter, I, w, h, r);
  boxBlurH(I, inter, w, h, r);
  boxBlurT(inter, I, w, h, r);
  
  for(int i = 0; i < inter.length; i++){
    trgt[i].copy(I[i]);
  }
}

void boxBlurH(Color[] I, Color[] trgt, int w, int h, int r){
  float scf = 1.0 / (r+r+1);
  int ti, li, ri;
  Color fv, lv, val;
  for(int i = 0; i < h; i++){
    ti = i * w;
    li = ti;
    ri = ti + r;
    
    fv = I[ti];
    lv = I[ti + w - 1];
    val = fv.copy().mult(r+1);
    for(int j = 0; j < r; j++){val.add(I[ti + j]);}
    for(int j = 0; j <= r; j++){
      val.add(I[ri++]).sub(fv);
      trgt[ti++].copy(val).mult(scf);
    }
    for(int j = r+1; j < w-r; j++){
      val.add(I[ri++]).sub(I[li++]);
      trgt[ti++].copy(val).mult(scf);
    }
    for(int j = w-r; j < w; j++){
      val.add(lv).sub(I[li++]);
      trgt[ti++].copy(val).mult(scf);
    }
  }
}

void boxBlurT(Color[] I, Color[] trgt, int w, int h, int r){
  float scf = 1.0 / (r+r+1);
  int ti, li, ri;
  Color fv, lv, val;
  for(int i = 0; i < w; i++){
    ti = i;
    li = ti;
    ri = ti + r * w;
    
    fv = I[ti];
    lv = I[ti + w * (h-1)];
    val = fv.copy().mult(r+1);
    for(int j = 0; j < r; j++){val.add(I[ti + j*w]);}
    for(int j = 0; j <= r; j++){
      val.add(I[ri]).sub(fv); ri += w;
      trgt[ti].copy(val).mult(scf); ti += w;
    }
    for(int j = r+1; j < h-r; j++){
      val.add(I[ri]).sub(I[li]); ri += w; li += w;
      trgt[ti].copy(val).mult(scf); ti += w;
    }
    for(int j = w-r; j < w; j++){
      val.add(lv).sub(I[li]); li += w;
      trgt[ti].copy(val).mult(scf); ti += w;
    }
  }
}
