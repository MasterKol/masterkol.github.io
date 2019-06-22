
// Double_Pendulum class

void setup(){
  size(400, 400);
  background(50);
}

float t1 = PI, t2 = PI+0.01;
//float t1 = 0.1, t2 = 0;

Pendulum[] Pens = {};
boolean init = true;

void draw(){
  background(50);
  if(init){
    for(int i = 0; i < 10; i++){
      Pens = (Pendulum[])append(Pens, new Pendulum(t1+random(-0.000001,0.000001), t2, 50, 100, 2, 1));
    }
    init = false;
  }
  
  translate(width/2,height/2);
  scale(1);
  
  for(int i = 0; i < Pens.length; i++){
    int n = 10;
    int s = 1;
    for(int w = 0; w < n*s; w++){
      Pens[i].step(0.02/n);
    }
    stroke(255,0,0);
    Pens[i].Draw();
  }
  
  //println(sqrt(sq(Pens[i].
  
  //Pens[0].step(0.02);
  //stroke(255,0,0);
  //Pens[0].Draw();
  
  /*int n = 100;
  for(int i = 0; i < n; i++){
    Pens[1].step(0.02/n);
  }
  stroke(0,0,255);
  Pens[1].Draw();*/
  
  /*for(int i = 0; i < Pens.length; i++){
    Pens[i].step(0.02);
    Pens[i].Draw();
  }*/
  
  resetMatrix();
}

// Pendulum class

class Pendulum{
  float t1, t2;
  float vt1 = 0, vt2 = 0;
  float l1, l2;
  float pt1, pt2;
  float m1, m2;
  PVector O;
  PVector[] Trace1 = {}, Trace2 = {};
  float max = 0;
  Pendulum(float t1i, float t2i, float l1i, float l2i, float m1i, float m2i) {
    t1 = t1i;
    t2 = t2i;
    
    l1 = l1i;
    l2 = l2i;
    
    m1 = m1i;
    m2 = m2i;
    
    pt1 = (m1 + m2)*sq(l1)*vt1 + m2*l1*l2*vt2*cos(t1-t2);
    pt2 = m2*sq(l2)*vt2 + m2*l1*l2*vt1*cos(t1-t2);
  }
  
  void step(float dt){
    float g = 9.81;
    
    float C1 = pt1*pt2*sin(t1-t2)/(l1*l2*(m1+m2*sq(sin(t1 - t2))));
    float C2 = (sq(l2)*m2*sq(pt1) + sq(l1)*(m1+m2)*sq(pt2) - l1*l2*m2*pt1*pt2*cos(t1 - t2))*sin(2*(t1-t2))/(2*sq(l1)*sq(l2)*sq(m1 + m2*sq(sin(t1-t2))));
    
    pt1 += (-(m1+m2)*g*l1*sin(t1) - C1 + C2)*dt;
    pt2 += (-m2*g*l2*sin(t2) + C1 - C2)*dt;
    
    vt1 = (l2*pt1 - l1*pt2*cos(t1-t2))/(sq(l1)*l1*(m1 + m2*sq(sin(t1-t2))));
    vt2 = (l1*(m1+m2)*pt2 - l2*m2*pt1*cos(t1-t2))/(l1*sq(l2)*m2*(m1 + m2*sq(sin(t1-t2))));
    
    t1 += vt1*dt;
    t2 += vt2*dt;
    
    //println("PE: " + -(m1*g*cos(t1)*l1 + m2*g*(cos(t1)*l1 + cos(t2)*l2)));
    //println("KE: " + (0.5*m1*sq(l1)*sq(vt1) + 0.5*m2*(sq(l1)*sq(vt1) + 2*l1*l2*abs(vt1)*abs(vt2)*cos(t1-t2))));
    //println("Total: " + ((0.5*m1*sq(l1)*sq(vt1) + 0.5*m2*(sq(l1)*sq(vt1) + 2*l1*l2*abs(vt1)*abs(vt2)*cos(t1-t2)))+(m1*g*cos(t1)*l1 + m2*g*(cos(t1)*l1 + cos(t2)*l2))));
  }
  
  void Draw(){
    //stroke(0,0,255);
    for(int i = 0; i < Trace1.length; i++){
      point(Trace1[i].x, Trace1[i].y);
      //point(width/max*Trace1[i].x/2, height/max*Trace1[i].y/2);
    }
    
    //stroke(255,0,0);
    for(int i = 0; i < Trace2.length; i++){
      point(Trace2[i].x, Trace2[i].y);
    }
    
    PVector p1 = new PVector(l1*cos(t1+PI/2), l1*sin(t1+PI/2));
    PVector p2 = new PVector(p1.x + l2*cos(t2+PI/2), p1.y + l2*sin(t2+PI/2));
    
    //Trace1 = (PVector[])append(Trace1, p1);
    Trace2 = (PVector[])append(Trace2, p2);
    if(Trace2.length > 200){
      PVector[] temp = {};
      for(int i = 1; i < Trace2.length; i++){
        temp = (PVector[])append(temp, Trace2[i]);
      }
      Trace2 = temp;
    }
    
    /*if(t1 > 2*PI){
      t1 -= 2*PI;
    }
    if(t1 < 0){
      t1 += 2*PI;
    }
    
    if(t2 > 2*PI){
      t2 -= 2*PI;
    }
    if(t2 < 0){
      t2 += 2*PI;
    }*/
    
    if(max < abs(t1)){
      max = abs(t1);
    }
    if(max < abs(t2)){
      max = abs(t2);
    }
    
    //Trace1 = (PVector[])append(Trace1, new PVector(width/(2*PI)*(t1%PI) + width/2*-floor(t1/PI), height/(2*PI)*(t2%PI) + height/2*-floor(t2/PI)));
    //Trace1 = (PVector[])append(Trace1, new PVector(t1, t2));
    
    stroke(0);
    strokeWeight(1);
    line(0, 0, p1.x, p1.y);
    line(p1.x, p1.y, p2.x, p2.y);
    
    fill(255,0,0);
    noStroke();
    ellipse(p1.x, p1.y, 5, 5);
    ellipse(p2.x, p2.y, 5, 5);
  }
}