Cell root;
ArrayList<ArrayList<Cell>> levels = new ArrayList<ArrayList<Cell>>();
int limit = 10;

ArrayList<Cell> base = new ArrayList<Cell>();

void setup(){
  size(700, 700);
  background(0);
  root = new Cell();
  
  levels.add(new ArrayList<Cell>());
  levels.get(0).add(root);
  base.add(root);
  
  extend(50);
}

PVector center = new PVector(50, 350);
boolean pmousePressed = false;
float Scale = 1;
float Len = 20;
float evenAngle = 8 * PI / 180;
float oddAngle = -20 * PI / 180;

PVector evenVals = new PVector(cos(evenAngle), sin(evenAngle));
PVector oddVals = new PVector(cos(oddAngle), sin(oddAngle));

void draw(){
  background(0);
  
  if(mousePressed && mouseButton == LEFT){
    center.x += mouseX - pmouseX;
    center.y += mouseY - pmouseY;
  }
  
  translate(center.x, center.y);
  scale(Scale);
  root.Draw();
  
  if(mousePressed && mouseButton == RIGHT){
    limit = (int)ceil(1.01 * limit);
    extend(10);
  }
  pmousePressed = mousePressed;
}

class Cell {
  int num;
  Cell parent;
  Cell evenChild = null;
  Cell oddChild = null;
  PVector pos;
  int stoppingNum;
  //float angle;
  int Color;
  PVector angle;
  
  Cell(){
    this.num = 1;
    this.parent = null;
    this.stoppingNum = 0;
    this.pos = new PVector(0,0);
    Color = color(0,150,255);
    angle = new PVector(1, 0);
  }
  
  Cell(int num, Cell parent, int stoppingNum, PVector offset){
    this.num = num;
    this.parent = parent;
    this.stoppingNum = stoppingNum;
    this.pos = PVector.add(parent.pos, PVector.mult(offset, Len));
    levels.get(stoppingNum).add(this);
    base.add(this);
    this.angle = offset;
    
    int pc = parent.Color;
    Color = color(0, constrain(green(pc) + random(-20, 20), 0, 255), constrain(blue(pc) + random(-20, 20), 0, 255));
  }
  
  void calculateChildren() {
    PVector d = (num % 2 == 0) ? evenVals : oddVals;
    //println("angle " + angle.x + ", " + angle.y);
    //println("d " + d.x + ", " + d.y);
    //println("x");
    PVector offsets = new PVector(angle.x * d.x - angle.y * d.y, angle.y * d.x + angle.x * d.y);
    offsets.normalize();
    //println("x");
    //println(offsets.x + ", " + offsets.y);
    //println(num, ";", angle);
    evenChild = new Cell(num * 2, this, stoppingNum + 1, new PVector(offsets.x, offsets.y));
    
    int nv = (num - 1) / 3;
    if(num % 3 == 1 && nv % 2 == 1 && !pathHasValue(nv)){
      oddChild = new Cell(nv, this, stoppingNum + 1, new PVector(offsets.x, offsets.y));
    }
  }
  
  void Draw(){
    if(sq((mouseX - center.x) / Scale - pos.x) + sq((mouseY - center.y) / Scale - pos.y) < 16){
      noStroke();
      fill(255);
      ellipse(pos.x, pos.y, 5, 5);
      
      if(mousePressed && !pmousePressed){
        print("start: ");
        printP();
        println();
      }
    }
    
    try {
      stroke(Color);
      line(pos.x, pos.y, evenChild.pos.x, evenChild.pos.y);
      evenChild.Draw();
      
      line(pos.x, pos.y, oddChild.pos.x, oddChild.pos.y);
      oddChild.Draw();
    } catch (Exception ignored){}
  }
  
  void printP(){
    print(num + ", ");
    
    if(parent != null){
      parent.printP();
    }
  }
  
  boolean pathHasValue(int v){
    if(parent == null){
      return v == 1 || v == 0;
    }
    return num == v || parent.pathHasValue(v);
  }
}

void extend(int amount){
  for(int i = 0; i < amount; i++){
    extend();
  }
}

void extend(){
  int depth = levels.size();
  levels.add(new ArrayList<Cell>());
  /*for(Cell c : levels.get(depth-1)){
    c.calculateChildren();
  }*/
  Cell B;
  for(int b = base.size()-1; b >= 0; b--){
    B = base.get(b);
    if(B.num < limit){
      B.calculateChildren();
      base.remove(b);
    }
  }
}

scroll = function(event) {
  float e = event.deltaY;
  //println(e);
  //y = (1 + e/100)*x;
  float zoomFactor = 1 + (float)e/100;
  Scale /= zoomFactor;
  center.x += ( - width/2)*zoomFactor + width/2;
  center.y += ( - height/2)*zoomFactor + height/2;
}