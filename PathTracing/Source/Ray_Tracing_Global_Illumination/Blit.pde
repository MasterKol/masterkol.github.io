void Blit(){
  if(bloomToggle){
    // bloom works by subtracting threshold 
    for(int i = 0; i < image.length; i++){ // add bloom
      bloom[i] = image[i].copy().sub(contrast).div(FrameNum / exposure * (1 - contrast)).sub(bloomThreshold);
    }
    
    Blur(bloom, bloom, ImageWidth, ImageHeight, bloomSize);
    
    for(int i = 0; i < image.length; i++){
      finalRender[i].copy(image[i]).div(FrameNum);
      finalRender[i].sub(contrast).mult(exposure / (1 - contrast)).add(bloom[i].mult(bloomStrength));
      //finalRender[i].sub(0.5).mult(contrast).add(0.5 + exposure);
    }
  }else{
    for(int i = 0; i < image.length; i++){
      finalRender[i].copy(image[i]).div(FrameNum);
      finalRender[i].sub(contrast).mult(exposure / (1 - contrast));
      //finalRender[i].sub(0.5).mult(contrast).add(0.5 + exposure);
    }
  }
  
  if(drawingDepthBuffer && preRes){
    //println("X");
    /*for(int i = 0; i < image.length; i++){
      finalRender[i] = new Color(1 / (depthBuffer[i] + 0.1));
    }*/
    for(int i = 0; i < image.length; i++){
      if(depthBuffer[i] > focalLength + 0.1 / (0.0001 + apertureSize)){
        finalRender[i] = dot(finalRender[i], new Color(1, 0.6, 0.6));
      }else if(depthBuffer[i] > focalLength - 0.1 / (0.0001 + apertureSize)){
        finalRender[i] = dot(finalRender[i], new Color(0.6, 1, 0.6));
      }
    }
    drawingDepthBuffer = false;
  }
  
  loadPixels();
  
  if(preRes && objectSelected){
    int n = 0;
    for(int j = 0; j < ImageHeight; j++){
      for(int i = 0; i < ImageWidth; i++){
        if(!selObjectBuffer[n] &&
              ((i > 0 && selObjectBuffer[n-1]) || (i < ImageWidth-1 && selObjectBuffer[n+1]) ||
              (j > 0 && selObjectBuffer[n-ImageWidth]) || (j < ImageHeight - 1 && selObjectBuffer[n+ImageWidth]))){
          finalRender[n] = new Color(0.988, 0.729, 0);
        }else{
          finalRender[n] = ACESFitted(finalRender[n]);
        }
        n++;
      }
    }
  }else{
    for(int i = 0; i < image.length; i++){
      finalRender[i] = ACESFitted(finalRender[i]);
    }
  }
  
  color c;
  int n = 0;
  Color C, B;
  for(int j = 0; j < ImageHeight; j++){
    for(int i = 0; i < ImageWidth; i++){
      c = finalRender[n++].getcolor();
      for(int a = 0; a < Res; a++){
        for(int b = 0; b < Res; b++){
          pixels[i*Res + a + (j*Res + b)*width] = c;
        }
      }
    }
  }
  
  updatePixels();
}

void resetBuffers(){
  ImageWidth = floor((float)drawWidth / Res);
  ImageHeight = floor((float)drawHeight / Res);
  
  image = new Color[ImageWidth * ImageHeight];
  bloom = new Color[image.length];
  finalRender = new Color[image.length];
  buffer = new Color[image.length];
  depthBuffer = new float[image.length];
  selObjectBuffer = new boolean[image.length];
  
  for(int i = 0; i < image.length; i++){
    image[i] = new Color(0);
    bloom[i] = new Color(0);
    finalRender[i] = new Color(0);
    //depthBuffer[i] = 0;
    buffer[i] = new Color(0);
  }
}

Color[] ACESInputMat = new Color[]{
    new Color(0.59719, 0.35458, 0.04823),
    new Color(0.07600, 0.90834, 0.01566),
    new Color(0.02840, 0.13383, 0.83777)
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
Color[] ACESOutputMat = new Color[]{
    new Color( 1.60475, -0.53108, -0.07367),
    new Color(-0.10208,  1.10813, -0.00605),
    new Color(-0.00327, -0.07276,  1.07602)
};

Color RRTAndODTFit(Color v)
{
    //Color a = v * (v + 0.0245786f) - 0.000090537;
    //Color b = v * (0.983729f * v + 0.4329510f) + 0.238081;
    //return a / b;
    Color a = v.copy().add(0.0245786).mult(v).sub(0.000090537);
    Color b = v.copy().mult(0.983729).add(0.4329510).mult(v).add(0.238081);
    return a.div(b);
}

Color ACESFitted(Color c)
{
    c = matMul(c, ACESInputMat);

    // Apply RRT and ODT
    c = RRTAndODTFit(c);

    c = matMul(c, ACESOutputMat);

    // Clamp to [0, 1]
    c.r = constrain(c.r, 0, 1);
    c.g = constrain(c.g, 0, 1);
    c.b = constrain(c.b, 0, 1);

    return c;
}
