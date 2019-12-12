float dt = 0.001;
float AcceptableError = 0.0001;

Pendulum Pen;// = new Pendulum(80, new PVector(350, 350), PI/2, 0, 1000, 300)
//Pendulum Pen2 = new Pendulum(26, new PVector(350, 350), PI/2, 0, 100, 300);

float FR = 100;

void setup(){
  background(0);
  size(700, 700);
  frameRate(FR);
  //Pen.Center.x = 350;
  //Pen.Center.y = 350;
  //Pen.xvel = 0;
  //float[][] a = {{3,2,1}, {2,1,-3}, {4,0,1}};
  //println(Determinate(a));
  //Pen.Simulate(0.001, 5);
  //Pen.Angs[19] += 0.001;
}

boolean InitialPrint = false;
boolean started = false;

boolean pmousePressed = false;

Slider n = new Slider(new PVector(50,50), new PVector(100, 20), 1, 50, 20);
Slider k = new Slider(new PVector(250,50), new PVector(100, 20), 0, 50, 6, false);
Slider f = new Slider(new PVector(50,250), new PVector(100, 20), 0, 100, 10, false);
Slider thetai = new Slider(new PVector(250,250), new PVector(100, 20), -180, 180, -70, false);
Slider vthetai = new Slider(new PVector(50,450), new PVector(100, 20), -1, 1, 0, false);
Slider len = new Slider(new PVector(250,450), new PVector(100, 20), 50, 400, 300);
Slider g = new Slider(new PVector(450,50), new PVector(100, 20), -30, 30, 9.81, false);

void draw(){
  //println(frameRate);
  //if(time == 0){Pen.Angs[Pen.Angs.length-1] = PI-0.01;}
  background(0);
  //noStroke();
  //fill(255,255,255,10);
  //rect(-1,-1,701,701);
  if(!started){
    background(255);
    noStroke();
    textSize(12);
    
    fill(0);
    text("Number of Links", 50, 45);
    if(n.currentValue < 30){fill(50,200,50);}else if(n.currentValue < 40){fill(200,200,50);}else{fill(200,50,50);}
    text((int)n.currentValue, 165, 65);
    n.draw();
    
    fill(0);
    text("Spring Constant", 250, 45);
    text((int)sq(k.currentValue), 365, 65);
    k.draw();
    
    fill(0);
    text("Friction Coefficent", 50, 245);
    text(f.currentValue/1000, 165, 265);
    f.draw();
    
    fill(0);
    text("Initial Angle", 250, 245);
    text(thetai.currentValue, 365, 265);
    thetai.draw();
    
    fill(0);
    text("Initial Velocity", 50, 445);
    text(vthetai.currentValue, 165, 465);
    vthetai.draw();
    
    fill(0);
    text("Total Length", 250, 445);
    text((int)len.currentValue, 365, 465);
    len.draw();
    
    fill(0);
    text("Gravitational Constant", 450, 45);
    text(g.currentValue, 565, 65);
    g.draw();
    
    fill(50,200,50);
    rect(200, 565, 100, 30);
    fill(255);
    textSize(30);
    text("Start", 167, 575);
    
    textSize(12);
    if(pmousePressed && !mousePressed && mouseX >= 150 && mouseX <= 250 && mouseY >= 550 && mouseY <= 580){
      Pen = new Pendulum((int)n.currentValue, new PVector(350, 350), -thetai.currentValue/180*PI, vthetai.currentValue, 1000, (int)len.currentValue);
      Pen.g = g.currentValue;
      Pen.Springk = sq(k.currentValue);
      Pen.friction = f.currentValue/1000;
      
      started = true;
    }
  }else{
    for(int i = 0; i < (3/FR)/dt; i++){
      Pen.Step(dt);
    }
    Pen.Draw();
  }
  
  pmousePressed = mousePressed;
}

float Determinate(float[][] A){
  if(A.length == 2){
    return A[0][0]*A[1][1] - A[1][0]*A[0][1];
  }
  
  float D = 0;
  for(int i = 0; i < A.length; i++){
    D += A[0][i] * Determinate(MatrixRemove(A,i,0)) * ((i%2 == 0) ? 1 : -1);
  }
  
  return D;
}

float[][] MatrixRemove(float[][] A, float i, float j){
  float[][] An = new float[A.length-1][A.length-1];
  for(int x = 0; x < An.length; x++){
    for(int y = 0; y < An.length; y++){
      An[y][x] = A[(y < j) ? y : y+1][(x < i) ? x : x+1];
    }
  }
  return An;
}

class Slider{
  PVector pos, dims;
  float currentValue;
  float[] range = {0,0};
  boolean rnd = true;
  Slider(PVector tpos, PVector tdims, float minvalue, float maxvalue, float tcurrentValue){
    pos = tpos;
    dims = tdims;
    range[0] = minvalue;
    range[1] = maxvalue;
    currentValue = tcurrentValue;
  }
  
  Slider(PVector tpos, PVector tdims, float minvalue, float maxvalue, float tcurrentValue, boolean trnd){
    pos = tpos;
    dims = tdims;
    range[0] = minvalue;
    range[1] = maxvalue;
    currentValue = tcurrentValue;
    rnd = trnd;
  }
  
  boolean clicked = false;
  void draw(){
    pushMatrix();
    translate(this.pos.x,this.pos.y);
    float sliderX = dims.x*14/20*((currentValue-range[0])/(this.range[1]-range[0])) + (dims.x-dims.x*14/20)/2;
  
    fill(100);
    rectMode(CORNER);
    rect(0,0,dims.x,dims.y,5);
    fill(150);
    rectMode(CORNER);
    rect(constrain(dims.x/20,0,2),constrain(dims.x/20,0,2),constrain(dims.x*16/20,dims.x-4,dims.x),constrain(dims.y*14/20,dims.y-4,dims.y),5);
  
    fill(50);
    rectMode(CENTER);
    rect(dims.x/2, dims.y/2, dims.x*14/20, dims.y/10);
  
    ellipseMode(CENTER);
    fill(25);
    ellipse(sliderX,dims.y/2,dims.y*8/20,dims.y*8/20);
  
    popMatrix();
  
    if(mousePressed && mouseX >= pos.x && mouseX <= pos.x+dims.x && mouseY >= pos.y && mouseY <= pos.y+dims.y && mousePressed != pmousePressed){
      clicked = true;
    }else if(mousePressed == false){
      clicked = false;
    }
  
    if(clicked == true){
      if(rnd){
        currentValue = round(constrain((mouseX-pos.x-15)*((range[1]-range[0])/(dims.x*14/20))+range[0], range[0], range[1])*10)/10;
      }else{
        currentValue = constrain((mouseX-pos.x-15)*((range[1]-range[0])/(dims.x*14/20))+range[0], range[0], range[1]);
      }
    }
  }
}

class Pendulum{
  float[] Angs, Vels, Masses, Lengths;
  float[][] Ang;
  //float hMax;
  float[] MPartialSum;
  int n;
  float g = 9.81;
  PVector Center;
  float Springk = 40;
  float[] pAccs;
  boolean simplify = false;
  float friction = 0.01;
  Pendulum(int nt, PVector Centert, float angle, float da, float mass, float L){
    n = nt;
    Center = Centert;
    float[] tAngs = new float[n], tVels = new float[n], tMasses = new float[n], tLengths = new float[n], MPS = new float[n], tpAccs = new float[n];
    Angs = tAngs; Vels = tVels; Masses = tMasses; Lengths = tLengths; MPartialSum = MPS; pAccs = tpAccs;
    //float c = mass/((n)*(n+1));
    //println((n)*(n+1));
    //println(c);
    for(int i = 0; i < n; i++){
      Angs[i] = angle;//+(0.1*i);
      //Angs[i] = (i%2 == 0) ? angle : PI+angle;
      Vels[i] = da;
      Masses[i] = mass/n;//2*i*c;
      //if(i == n-1){Masses[i] *= 50;}
      Lengths[i] = L/n;
      //hMax += Lengths[i];
    }
    MPartialSum[n-1] = Masses[n-1];
    for(int i = n-2; i >= 0; i--){
      MPartialSum[i] = Masses[i] + MPartialSum[i+1];
    }
    simplify = true;
    for(int i = 1; i < n; i++){
      if(Masses[i-1] != Masses[i] || Lengths[i-1] != Lengths[i]){
        simplify = false;
        break;
      }
    }
    //simplify = false;
  }
  
  void Step(float dt){
    float[] b = new float[n];
    float[][] coeffs = new float[n][n];
    /*for(int w = 0; w < n; w++){
      for(int j = w; j < n; j++){
        float z = 0;
        for(int k = 0; k <= j; k++){
          z += Lengths[k] * sq(Vels[k]) * sin(Angs[k] - Angs[w]);
          coeffs[w][k] += Masses[j] * Lengths[k] * cos(Angs[k] - Angs[w]);
        }
        b[w] -= Masses[j] * g * sin(Angs[w]) - Masses[j]*z;
      }
      //b[w] -= 2 * Springk * ( ((w == n-1) ? 0 : Masses[w]*(Angs[w] - Angs[w+1])) - ((w == 0) ? 0 : Masses[w]*(Angs[w-1] - Angs[w])) );
    }*/
    for(int w = 0; w < n; w++){
      for(int k = 0; k < n; k++){
        float r = cos(Angs[k] - Angs[w]);
        coeffs[w][k] += MPartialSum[max(k,w)] * Lengths[k] * r;
        b[w] += MPartialSum[max(k,w)] * Lengths[k] * sq(Vels[k]) * sqrt(1 - sq(r)) * (floor(((Angs[k] - Angs[w])/PI)) % 2 == 0 ? 1 : -1);
      }
      b[w] -= MPartialSum[w] * g * sin(Angs[w]) + 2 * Springk * ( ((w == n-1) ? 0 : (n-w)*(Angs[w] - Angs[w+1])) - ((w == 0) ? 0 : (n-w)*(Angs[w-1] - Angs[w])) );
      //b[w] -= ;
    }
    /*for(int w = 0; w < n; w++){
      for(int k = 0; k < n; k++){
        b[w] += sq(Vels[k]) * sin(Angs[k] - Angs[w]);
        coeffs[w][k] += cos(Angs[k] - Angs[w]);
      }
      b[w] -= g * sin(Angs[w]);
    }*/

    float w = 1;
    //float[] acc = new float[n];
    float[] acc = pAccs;
    for(int k = 0; k < 1000; k++){
      boolean Converged = true;
      for(int i = 0; i < n; i++){
        float m = 0;
        for(int j = 0; j < n; j++){
          if(j == i){continue;}
          m += coeffs[i][j] * acc[j];
        }
        float pacc = (1-w)*acc[i] + w/coeffs[i][i] * (b[i] - m);
        if(k < 20 || (abs(pacc - acc[i])/acc[i] > AcceptableError && abs(acc[i]) > AcceptableError/10)){
          Converged = false;
        }
        acc[i] = pacc;
      }
      if(Converged){break;}//println("loop broken after", k, "Iterations"); 
    }
    
    for(int i = 0; i < n; i++){
      Vels[i] += acc[i]*dt;
      /*float F = 0;
      for(int j = 0; j < w; j++){
      //  F += Lengths[j] * Vels[j] * cos(Angs[j] - Angs[i]);
      }
      
      //Vels[i] -= a * Lengths[i] * F / Masses[i] * dt;*/
      Angs[i] += Vels[i]*dt;
      //Angs[i] = (Angs[i] + 2*PI)%(2*PI);
      //Angs[i] += (pAccs[i] + 2*acc[i])/2 * sq(dt) + Vels[i]*dt;
      //Vels[i] += (pAccs[i] + acc[i])/2 * dt;
      
      Vels[i] *= (1-friction*dt);
    }
    pAccs = acc;
    
  }
  
  float initialEnergy = -1;
  void Draw(){
    PVector p = new PVector(Center.x, Center.y);
    strokeWeight(1.4);
    stroke(255,0,0);
    for(int i = 0; i < n; i++){
      //if(i%2==0){stroke(255,0,0);}else{stroke(0,0,255);}
      PVector t = new PVector(Lengths[i] * cos(Angs[i]+PI/2), Lengths[i] * sin(Angs[i]+PI/2));
      line(p.x, p.y, p.x+t.x, p.y+t.y);
      p.x += t.x; p.y += t.y;
    }
    
    float Energy = 0;
    for(int i = 0; i < n; i++){
      float h = 0;
      float hMax = 0;
      PVector vel = new PVector(0, 0);
      for(int k = 0; k <= i; k++){
        h     += Lengths[k] * cos(Angs[k]);
        hMax  += Lengths[k];
        vel.x += Lengths[k]*Vels[k]*cos(Angs[k]);
        vel.y += Lengths[k]*Vels[k]*sin(Angs[k]);
      }
      Energy += -Masses[i]*g*(h-hMax) + 0.5*Masses[i]*(sq(vel.x) + sq(vel.y)) + Springk * ( ((i == n-1) ? 0 : Masses[i]*sq(Angs[i] - Angs[i+1])) + ((i == 0) ? 0 : Masses[i]*sq(Angs[i-1] - Angs[i])) );
    }
    Energy*=1000;
    if(initialEnergy == -1){initialEnergy = Energy;}
    fill(255);
    text(Energy, 50, 50);
  }
}