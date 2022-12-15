class Key {
  int code;
  boolean held;
  boolean pressed, released;
  boolean pressed_buffer, released_buffer;
  int holdDuration = 0;
  
  Key(int code){
    this.code = code;
  }
  
  void startFrameUpdate(){
    pressed = pressed_buffer;
    pressed_buffer = false;
    released = released_buffer; // if button is not being held then this buffered released is faux
    released_buffer = false;
    
    if(pressed){
      held = true;
      holdDuration = 0;
    }
  }
  
  void endFrameUpdate(){
    if(released){
      held = false;
    }
    
    pressed = false;
    released = false;
    
    if(held){
      holdDuration++;
    }
  }
}

void keyboardStartFrame(){
  if(!focused){ // stops the program from thinking keys are held after clicking out of program
    for(int i : trackedKeys){
      keyState.get(i).released_buffer = true;
    }
  }
  
  for(int k : trackedKeys){
    keyState.get(k).startFrameUpdate();
  }
}

void keyboardEndFrame(){
  for(int k : trackedKeys){
    keyState.get(k).endFrameUpdate();
  }
}

Key getKey(int code){
  return keyState.get(code);
}

//HashMap<Integer, Boolean> heldKeys = new HashMap<Integer, Boolean>();
HashMap<Integer, Key> keyState = new HashMap<Integer, Key>();
int[] trackedKeys = {'W', 'A', 'S', 'D', SHIFT, ' ', ESC, ENTER, RETURN, 'G', 'R', 'X', 'Y', 'Z', CONTROL};

void setupKeys(){
  for(int k : trackedKeys){
    keyState.put(k, new Key(k));
  }
}

void keyPressed(){
  if(keyState.containsKey(keyCode)){
    //heldKeys.put(keyCode, true);
    keyState.get(keyCode).pressed_buffer = true;
  }
  
  if(keyCode == ESC){ // stop escape from quitting the program
    key = 0;
  }
}

void keyReleased(){
  keyEvents.append(keyCode);
  
  if(keyState.containsKey(keyCode)){
    keyState.get(keyCode).released_buffer = true;
  }
}
