interface Material {
  int getType(); // 0 = emissive, 1 = diffuse, 2 = glossy, 3 = transparent, 4 = metal, 5 = texture / diffuse
  
  float getGuiSize();
  void drawGui();
  String getTypeName();
}

HScrollbar RBar = new HScrollbar(120, 0, 120, 12); // used for all colors to save bars
HScrollbar GBar = new HScrollbar(120, 20, 120, 12);
HScrollbar BBar = new HScrollbar(120, 40, 120, 12);

HScrollbar StrengthBar = new HScrollbar(120, 60, 120, 12);

class Emissive implements Material {
  Color c;
  float strength;
  
  Emissive(Color c, float strength){
    this.c = c;
    this.strength = strength;
  }
  
  int getType(){
    return 0;
  }
  
  void drawGui(){
    RBar.mouseOverText = "Red part of the light that is emitted";
    GBar.mouseOverText = "Green part of the light that is emitted";
    BBar.mouseOverText = "Blue part of the light that is emitted";
    drawColorBars(c, "Red", "Green", "Blue");
    
    StrengthBar.mouseOverText = "Strength of the light that is emitted";
    NormBar(StrengthBar, "Strength", strength, 0, 20, false, new barInter(){public void onChange(float v){
      strength = max(v, 0);
      preresUpdate = true;
    }});
  }
  
  float getGuiSize(){
    return 80;
  }
  
  String getTypeName(){
    return "Emissive";
  }
}

class Diffuse implements Material {
  Color albedo;
  
  Diffuse(Color albedo){
    this.albedo = albedo;
  }
  
  Diffuse(){
    albedo = new Color(0);
  }
  
  int getType(){
    return 1;
  }
  
  void drawGui(){
    RBar.mouseOverText = "Amount of red light that's absorbed";
    GBar.mouseOverText = "Amount of green light that's absorbed";
    BBar.mouseOverText = "Amount of blue light that's absorbed";
    drawColorBars(albedo, "Red Albedo", "Green Albedo", "Blue Albedo");
  }
  
  Color getAlbedo(UV uv){
    return albedo.copy();
  }
  
  float getGuiSize(){
    return 60;
  }
  
  String getTypeName(){
    return "Diffuse";
  }
}

class Glossy implements Material {
  Color albedo;
  float roughness;
  
  Glossy(Color albedo, float roughness){
    this.albedo = albedo;
    this.roughness = roughness;
  }
  
  int getType(){
    return 2;
  }
  
  void drawGui(){
    RBar.mouseOverText = "Amount of red light that's absorbed";
    GBar.mouseOverText = "Amount of green light that's absorbed";
    BBar.mouseOverText = "Amount of blue light that's absorbed";
    drawColorBars(albedo, "Red Albedo", "Green Albedo", "Blue Albedo");
    
    StrengthBar.mouseOverText = "Amount of light thats being scattered off of a pure reflection";
    roughness = Bar01(StrengthBar, "Roughness", roughness);
  }
  
  float getGuiSize(){
    return 80;
  }
  
  String getTypeName(){
    return "Glossy";
  }
}

HScrollbar IORBar = new HScrollbar(120, 80, 120, 12, "Index of refraction of the material");
class Transparent implements Material {
  float ior;
  Color absorbance; // percentage of each type of light that is allowed to pass through (1 means all passes, 0 means none passes)
  float absorbanceStrength; // multiplier for amount of light absorbed (multiplied by distance to get final value)
  float roughness;
  
  Transparent(float ior, Color absorb, float absorbStren, float roughness){
    this.ior = ior;
    absorbance = absorb;
    absorbanceStrength = absorbStren;
    this.roughness = roughness;
  }
  
  int getType(){
    return 3;
  }
  
  void drawGui(){
    RBar.mouseOverText = "Amount of red light that's transmitted";
    GBar.mouseOverText = "Amount of green light that's transmitted";
    BBar.mouseOverText = "Amount of blue light that's transmitted";
    drawColorBars(absorbance, "R Transmittance", "G Transmittance", "B Transmittance");
    
    StrengthBar.mouseOverText = "Proportion of light thats transmitted per cm of material";
    NormBar(StrengthBar, "Strength", absorbanceStrength * 10, 0, 2, false, new barInter(){public void onChange(float v){
      absorbanceStrength = max(v/10, 0);
      preresUpdate = true;
    }});
    
    NormBar(IORBar, "IOR", ior, 0, 3, false, new barInter(){public void onChange(float v){
      ior = max(v, 0);
      preresUpdate = true;
    }});
  }
  
  float getGuiSize(){
    return 100;
  }
  
  String getTypeName(){
    return "Transparent";
  }
}

class Metal implements Material {
  Color col;
  
  Metal(Color col){
    this.col = col;
  }
  
  int getType(){
    return 4;
  }
  
  void drawGui(){
    RBar.mouseOverText = "Amount of red light that's absorbed";
    GBar.mouseOverText = "Amount of green light that's absorbed";
    BBar.mouseOverText = "Amount of blue light that's absorbed";
    drawColorBars(col, "Red", "Green", "Blue");
  }
  
  float getGuiSize(){
    return 60;
  }
  
  String getTypeName(){
    return "Metal";
  }
}

Texture textureToSet;
Button setTextureButton = new Button(50, 0, 200, 30, "Select Texture");
class Texture extends Diffuse implements Material {
  PImage img;
  
  Texture(){
    //img = 
  }
  
  Texture(String fileName){
    img = loadImage(fileName);
    img.loadPixels();
  }
    
  int getType(){
    return 5;
  }
  
  Color getAlbedo(UV uv){
    if(img == null || uv.u < 0 || uv.v < 0){
      return new Color(0);
    }
    float y = constrain(round((1 - uv.v) * img.height), 0, img.height - 1);
    return toColor(img.pixels[round((y + constrain(uv.u, 0, 1)) * img.width)]);
  }
  
  void drawGui(){
    setTextureButton.display();
    setTextureButton.update();
    if(!setTextureButton.state){
      setTextureButton.state = true;
      textureToSet = this;
      selectInput("Select texture:", "setImage");
    }
  }
  
  void setImage(File newImg){
    if(newImg == null){return;}
    img = loadImage(newImg.getAbsolutePath());
    img.loadPixels();
    preresUpdate = true;
  }
  
  float getGuiSize(){
    return 60;
  }
  
  String getTypeName(){
    return "Texture";
  }
}

void setImage(File newImg){
  textureToSet.setImage(newImg);
}

void drawColorBars(Color c, String RedText, String GreenText, String BlueText){
  c.r = Bar01(RBar, RedText, c.r);
  c.g = Bar01(GBar, GreenText, c.g);
  c.b = Bar01(BBar, BlueText, c.b);
}
