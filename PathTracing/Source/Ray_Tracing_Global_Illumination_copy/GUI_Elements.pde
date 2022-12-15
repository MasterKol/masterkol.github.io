class DrawOverlayCallback { // hacky way to get the overlay for certain gui elements to be drawn last and thus ontop of the other bars
  float offx, offy;
  DrawOverlayCallback(float offx, float offy){
    this.offx = offx;
    this.offy = offy;
  }
  void Draw(){}
}

class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;
  TextBox T;
  String mouseOverText;

  HScrollbar (float xp, float yp, int sw, int sh) {
    Setup(xp, yp, sw, sh, null);
  }
  
  HScrollbar (float xp, float yp, int sw, int sh, String mouseOverText) {
    Setup(xp, yp, sw, sh, mouseOverText);
  }
  
  void Setup(float xp, float yp, int sw, int sh, String mouseOverText){
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    //loose = l;
    
    T = new TextBox(xpos + sw + 5, ypos - 1, 50, sh + 2, 7);
    this.mouseOverText = mouseOverText;
  }

  void update() {
    over = overEvent();
    if (!pmousePressed && mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      spos = sposMin + constrain(mouseX - screenX(xpos, ypos) - sheight/2, 0, sposMax - sposMin);
    }
    T.update();
  }

  boolean overEvent() {
    return mouseX > screenX(xpos, ypos) && mouseX < screenX(xpos + swidth, ypos) && mouseY > screenY(xpos, ypos) && mouseY < screenY(xpos, ypos+sheight);
  }

  void display(String aboveText, String rightText) {
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(12); textLeading(14);
    text(aboveText, (5 + xpos) / 2, ypos + sheight/2 - 2);
    
    // decide whether to display mouse over text
    if(mouseOverText != null && mouseX > screenX(0, ypos) && mouseX < screenX(xpos, ypos) && mouseY > screenY(0, ypos) && mouseY < screenY(xpos, ypos + sheight)){
      float xoff = screenX(0, 0), yoff = screenY(0, 0);
      overlayCallback = new DrawOverlayCallback(xoff, yoff){public void Draw(){
        textSize(12); textLeading(14);
        String toDisplay = breakText(mouseOverText, xpos - 20);
        fill(140);
        noStroke();
        rect(offx + 10, offy + ypos + sheight, xpos - 10, 10 + 14 * numLines(toDisplay));
        
        fill(0);
        textAlign(LEFT, TOP);
        text(toDisplay, offx + 15, offy + 5 + ypos + sheight);
      }};
    }
    
    textAlign(LEFT);
    
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if ((over && !mousePressed) || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(constrain(round(spos), sposMin, sposMax), round(ypos), sheight, sheight);
    if(!T.selected){
      T.setValue(rightText);
    }
    T.display();
  }

  float getValue() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return (spos - xpos) * ratio / swidth;
  }
  
  void setSliderPos(float value) {
    spos = value * swidth / ratio + xpos;
    newspos = spos;
  }
}

float HDiffBar(HScrollbar bar, String txt, float val, float speed){
  return HDiffBar(bar, txt, val, speed, null);
}

float HDiffBar(HScrollbar bar, String txt, float val, float speed, barInter b){
  bar.display(txt, nf(val, 0, 0));
  bar.update();
  if(bar.T.selected){
    val = bar.T.getNumValue();
    preresUpdate = true;
    if(b != null){b.onChange(val);}
  }
  if(bar.locked){
    val = val + (bar.getValue() - 0.5) * speed;
    preresUpdate = true;
    if(b != null){b.onChange(val);}
  }else{
    bar.setSliderPos(0.5);
  }
  return val;
}

float Bar01(HScrollbar bar, String txt, float val){
  bar.setSliderPos(val);
  bar.display(txt, nf(val, 0, 0));
  bar.update();
  if(bar.T.selected){
    val = constrain(bar.T.getNumValue(), 0, 1);
  }
  if(bar.locked){
    val = bar.getValue();
  }
  preresUpdate |= bar.locked || bar.T.selected;
  
  return val;
}

float NormBar(HScrollbar bar, String txt, float val, float min, float max, boolean Constrain){
  return NormBar(bar, txt, val, min, max, Constrain, null);
}

float NormBar(HScrollbar bar, String txt, float val, float min, float max, boolean Constrain, barInter b){
  float iv = val;
  bar.setSliderPos((val - min) / (max - min));
  bar.display(txt, nf(val, 0, 0));
  bar.update();
  if(bar.T.selected){
    val = bar.T.getNumValue();
    val = Constrain ? constrain(val, min, max) : val;
    if(b != null){b.onPress(val);}
  }
  if(bar.locked){
    val = bar.getValue() * (max - min) + min;
    val = Constrain ? constrain(val, min, max) : val;
    if(b != null){b.onPress(val);}
  }
  val = Constrain ? constrain(val, min, max) : val;
  if(iv != val && b != null && (bar.T.selected || bar.locked)){
    b.onChange(val);
  }
  return val;
}

class barInter {
  void onChange(float val){};
  void onPress(float val){};
}

class Button {
  boolean state;
  float xpos, ypos, w, h;
  boolean over, pressed;
  float borderSize;
  String btnText;
  
  Button(float xp, float yp, float w, float h, String txt){
    this.xpos = xp;
    this.ypos = yp;
    this.w = w;
    this.h = h;
    this.state = true;
    btnText = txt;
    
    borderSize = min(w * 0.06, h * 0.06);
  }
  
  void update(){
    over = overEvent();
    if(mousePressed && !pmousePressed && over){
      pressed = true;
    }
    if(pressed && !mousePressed){
      state = !state;
      pressed = false;
    }
  }
  
  boolean overEvent() {
    if (mouseX > screenX(xpos, ypos) && mouseX < screenX(xpos + w, ypos) &&
       mouseY > screenY(xpos, ypos) && mouseY < screenY(xpos, ypos + h)) {
      return true;
    } else {
      return false;
    }
  }
  
  void display(){
    noStroke();
    
    fill(150);
    rect(xpos, ypos, w, h, 3);
    
    if(pressed){
      fill(80);
    }else if(state){
      fill(200);
    }else{
      fill(140);
    }
    
    rect(xpos + borderSize, ypos + borderSize, w - borderSize * 2, h - borderSize * 2, 3);
    
    fill(0);
    textAlign(CENTER, CENTER);
    text(btnText, xpos + w/2, ypos + h/2 - 2);
    textAlign(LEFT);
  }
  
  void setState(boolean newState){
    state = newState;
  }
  
  boolean getState(){
    return state;
  }
}

IntList keyEvents = new IntList();
class TextBox { // only allows numbers and periods by default because rn I only need it for numbers
  String currentValue;
  float xpos, ypos, w, h;
  int maxLen;
  boolean over, selected;
  int flashTimer = 0;
  int flashLength = 60;
  boolean intOnly = false;
  int cursorPos;
  
  TextBox(float xp, float yp, float w, float h, int maxLen, String defaultVal){
    this.xpos = xp;
    this.ypos = yp;
    this.w = w;
    this.h = h;
    
    if(maxLen > 0){
      this.maxLen = maxLen;
    }else{
      this.maxLen = 100;
    }
    currentValue = defaultVal;
  }
  
  TextBox(float xp, float yp, float w, float h, int maxLen){
    this.xpos = xp;
    this.ypos = yp;
    this.w = w;
    this.h = h;
    
    if(maxLen > 0){
      this.maxLen = maxLen;
    }else{
      this.maxLen = 100;
    }
    currentValue = "0";
  }
  
  void update(){
    over = overEvent();
    if(mousePressed && !pmousePressed && over && selected){
      flashTimer = flashLength/2;
      int tl = currentValue.length();
      cursorPos = 0;
      for(int i = tl; i >= 0; i--){
        if(mouseX - screenX(xpos+2 + textWidth(currentValue.substring(0, i)), ypos) > 0){
          cursorPos = i;
          
          if(i != tl && abs(mouseX - screenX(xpos+2 + textWidth(currentValue.substring(0, i+1)), ypos)) < abs(mouseX - screenX(xpos+2 + textWidth(currentValue.substring(0, i)), ypos))){
            cursorPos++;
          }
          
          break;
        }
      }
    }
    if(over && mousePressed && !pmousePressed && !selected){
      cursorPos = currentValue.length();
      selected = true;
      flashTimer = flashLength/2;
      keyEvents.clear();
    }
    if(mousePressed && !pmousePressed && !over){
      deselect();
    }
    if(selected){
      flashTimer = (flashTimer + 1) % flashLength;
    }
    
    if(selected){
      for(int e : keyEvents){
        if(e == 8 && currentValue.length() > 0 && cursorPos > 0){
          //currentValue = currentValue.substring(0, currentValue.length() - 1);
          currentValue = currentValue.substring(0, cursorPos - 1) + currentValue.substring(cursorPos, currentValue.length());
          cursorPos--;
        }else if(e >= 48 && e <= 57 && currentValue.length() < maxLen){
          cursorPos++;
          currentValue = currentValue.substring(0, cursorPos-1) + str(e - 48) + currentValue.substring(cursorPos-1, currentValue.length());
        }else if(e == 46 && !currentValue.contains(".") && !intOnly && currentValue.length() < maxLen){
          cursorPos++;
          currentValue = currentValue.substring(0, cursorPos-1) + "." + currentValue.substring(cursorPos-1, currentValue.length());
        }else if(e == 10){
          deselect();
          break;
        }else if(e == 37){
          cursorPos = max(0, cursorPos-1);
        }else if(e == 39){
          cursorPos = min(currentValue.length(), cursorPos+1);
        }else if(e == 38){
          cursorPos = currentValue.length();
        }else if(e == 40){
          cursorPos = 0;
        }else if(e == 45 && cursorPos == 0 && (currentValue.length() == 0 || currentValue.charAt(0) != '-')){
          currentValue = "-" + currentValue;
          cursorPos++;
        }
      }
      keyEvents.clear();
    }
  }
  
  void deselect(){
    selected = false;
    flashTimer = 0;
    if(currentValue.length() == 0){
      currentValue = "0";
    }
    
    if(currentValue.charAt(currentValue.length()-1) == '.'){
      currentValue = currentValue.substring(0, currentValue.length()-1);
    }
    while(currentValue.length() > 1 && currentValue.charAt(0) == '0' && currentValue.charAt(1) != '.'){
      currentValue = currentValue.substring(1, currentValue.length());
    }
    if(currentValue.length() == 0){
      currentValue = "0";
    }
  }
  
  void display(){
    textSize(10);
    fill(200);
    stroke((over || selected) ? 0 : 150);
    strokeWeight(1);
    rect(xpos, ypos, w, h);
    
    fill(0);
    textAlign(LEFT, CENTER);
    text(currentValue, xpos + 2, ypos + h/2 - 1);
    if(flashTimer > flashLength/2){
      float cx = xpos + 2 + textWidth(currentValue.substring(0, cursorPos));
      line(cx, ypos + h/2 - g.textSize/2, cx, ypos + h/2 + g.textSize/2);
      //text("|", , );
    }
  }
  
  boolean overEvent() {
    if (mouseX > screenX(xpos, ypos) && mouseX < screenX(xpos + w, ypos) &&
       mouseY > screenY(xpos, ypos) && mouseY < screenY(xpos, ypos + h)) {
      return true;
    } else {
      return false;
    }
  }
  
  void setValue(String newVal){
    currentValue = newVal;
  }
  
  float getNumValue(){
    //String processed = currentValue;
    /*if(processed.charAt(processed.length()-1) == '.'){
      processed = processed.substring(0, processed.length()-1);
    }*/
    if(currentValue.length() == 0 || currentValue.equals(".") || currentValue.equals("-") || currentValue.equals("-.")){
      return 0;
    }
    return float(currentValue);
  }
  
  String getValue(){
    return currentValue;
  }
}

ArrayList<MouseEvent> scrollEvents = new ArrayList<MouseEvent>();
class ScrollArea {
  float currentScroll, minScroll, maxScroll;
  float xpos, ypos, w, h;
  boolean over;
  VScrollbar bar;
  
  ScrollArea(float xp, float yp, int w, int h){
    xpos = xp;
    ypos = yp;
    this.w = w;
    this.h = h;
    
    minScroll = 0;
    maxScroll = w;
    bar = new VScrollbar(xp, yp, 10, h, 50);
    bar.barSize = h / (maxScroll - minScroll) * bar.sheight;
  }
  
  void update(){
    over = overEvent();
    if(bar.locked){
      currentScroll = constrain(bar.getValue() * (max(maxScroll - h, 0) - minScroll) + minScroll, minScroll, max(maxScroll - h, 0));
    }else{
      MouseEvent e;
      for(int i = scrollEvents.size()-1; i >= 0; i--){
        e = scrollEvents.get(i);
        if(abs(round(e.getCount())) > 0 && inBox(e.getX(), e.getY())){
          scrollEvents.remove(i);
          currentScroll = constrain(currentScroll + e.getCount(), minScroll, max(maxScroll - h, 0));
        }
      }
      //println((currentScroll - minScroll) / (max(maxScroll - h, 0) - minScroll));
      bar.setSliderPos((currentScroll - minScroll) / (max(maxScroll - h, 0) - minScroll));
    }
    //println(currentScroll, minScroll, max(maxScroll - h, 0));
    if(maxScroll > h){
      bar.barSize = h / (maxScroll - minScroll) * bar.sheight;
      bar.update();
    }
    currentScroll = constrain(currentScroll, minScroll, max(maxScroll - h, 0));
    //println(bar.getValue());
  }
  
  boolean overEvent() {
    if (mouseX > screenX(xpos, ypos) && mouseX < screenX(xpos + w, ypos) &&
       mouseY > screenY(xpos, ypos) && mouseY < screenY(xpos, ypos + h)) {
      return true;
    } else {
      return false;
    }
  }
  
  boolean inBox(float X, float Y) {
    if (X > screenX(xpos, ypos) && X < screenX(xpos + w, ypos) &&
       Y > screenY(xpos, ypos) && Y < screenY(xpos, ypos + h)) {
      return true;
    } else {
      return false;
    }
  }
  
  void display(){
    if(maxScroll > h){
      bar.display();
    }
  }
}

void mouseWheel(MouseEvent event) {
  scrollEvents.add(event);
}

class VScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;
  float barSize;

  VScrollbar (float xp, float yp, int sw, int sh, float barSize) {
    this.barSize = barSize;
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp;
    spos = ypos;
    sposMin = ypos;
    sposMax = ypos + sheight - barSize;
  }

  void update() {
    sposMax = ypos + sheight - barSize;
    over = overEvent();
    if (!pmousePressed && mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      spos = constrain(spos + mouseY - pmouseY, sposMin, sposMax);
    }
  }

  boolean overEvent() {
    if (mouseX > screenX(xpos, ypos) && mouseX < screenX(xpos + swidth, ypos) &&
       mouseY > screenY(xpos, ypos) && mouseY < screenY(xpos, ypos+sheight)) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if ((over && !mousePressed) || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(round(xpos), constrain(round(spos), sposMin, sposMax), swidth, barSize);
  }

  float getValue() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return (spos - ypos) / (sheight - barSize);
  }
  
  void setSliderPos(float value) {
    spos = value * (sheight - barSize) + ypos;
  }
}

class CheckBox {
  int xpos, ypos;
  int xoffset;
  boolean enabled = false;
  boolean state = true;
  boolean over;
  String label;
  int size;
  
  CheckBox(int xpos, int ypos, int xoffset, int size, String label){
    this.xpos = xpos;
    this.ypos = ypos;
    this.size = size;
    this.label = label;
    this.xoffset = xoffset;
  }
  
  void display(){
    textAlign(LEFT, CENTER);
    textSize(12); textLeading(14);
    
    fill(enabled ? 0 : 100);
    
    text(label, xpos, ypos + size / 2 - 2);
    
    pushMatrix();
    translate(xpos + xoffset - size, ypos);
    strokeWeight(1);
    if(enabled){
      fill(150);
      stroke(50);
    }else{
      fill(200);
      stroke(150);
    }
    rect(0, 0, size, size, 5);
    
    if(state){
      strokeWeight(1);
      if(enabled){
        stroke(0);
      }else{
        stroke(100);
      }
      
      line(3, 3, size-3, size-3);
      line(3, size-3, size-3, 3);
    }
    popMatrix();
  }
  
  void update(){
    if(!enabled){return;}
    updateOver();
    
    state ^= over && !mousePressed && pmousePressed;
  }
  
  void updateOver(){
    int lx = xpos + xoffset - size;
    over = screenX(lx, ypos) < mouseX && mouseX < screenX(lx + size, ypos + size) && screenY(lx, ypos) < mouseY && mouseY < screenY(lx + size, ypos + size);
  }
  
  void setEnabled(boolean newEnabled){
    enabled = newEnabled;
  }
  
  void setState(boolean newState){
    state = newState;
  }
}
