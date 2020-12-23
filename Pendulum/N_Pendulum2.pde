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
float TAU = 2*PI;

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
    background(0);
    noStroke();
    textSize(12);
    
    fill(255);
    text("Number of Links", 50, 45);
    if(n.currentValue < 30){fill(50,200,50);}else if(n.currentValue < 40){fill(200,200,50);}else{fill(200,50,50);}
    text((int)n.currentValue, 165, 65);
    n.draw();
    
    fill(255);
    text("Spring Constant", 250, 45);
    text((int)sq(k.currentValue), 365, 65);
    k.draw();
    
    fill(255);
    text("Friction Coefficent", 50, 245);
    text(f.currentValue/1000, 165, 265);
    f.draw();
    
    fill(255);
    text("Initial Angle", 250, 245);
    text(thetai.currentValue, 365, 265);
    thetai.draw();
    
    fill(255);
    text("Initial Velocity", 50, 445);
    text(vthetai.currentValue, 165, 465);
    vthetai.draw();
    
    fill(255);
    text("Total Length", 250, 445);
    text((int)len.currentValue, 365, 465);
    len.draw();
    
    fill(255);
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

float sign(float v){
  if(v == 0){return 0;}
  else if(v > 0){return 1;}
  return -1;
}

float polyCos(float v){
  //v = (v+TAU)%TAU;
  if(v >= PI){v -= TAU;}
  else if(v <= -PI){v += TAU;}
  float vs = v*v;
  return 1 - vs/2 + vs*vs/24 - vs*vs*vs/720 + vs*vs*vs*vs/40320;
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
  float mass, L;
  Pendulum(int nt, PVector Centert, float angle, float da, float _mass, float _L){
    mass = _mass;
    L = _L;
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
    float[][] Matrix = new float[n][n+1];
    int k;
    float m, da;
    float d = 0;
    float cda;
    for(int w = 0; w < n; w++){
      for(k = 0; k < n; k++){
        if(w == k){Matrix[w][k] = mass*(n - w); continue;}
        m = mass*(n - max(w,k));
        da = (Angs[k] - Angs[w] + TAU)%TAU - PI;
        cda = polyCos(Angs[k] - Angs[w]);
        Matrix[w][k] = cda*m;
        Matrix[w][n] += -Vels[k]*Vels[k]*m*sqrt(1-cda*cda)*sign(da);
      }
      Matrix[w][n] -= mass*(n-w)*g*sin(Angs[w]);
      Matrix[w][n] += 2 * Springk * d;//((w == 0) ? 0 : (n-w)*(Angs[w-1] - Angs[w]));
      d = mass*(n-w)*(Angs[w] - Angs[min(w+1, n-1)]);//sqrt(sq(cos(Angs[w]) - cos(Angs[min(w+1, n-1)])) - sq(sin(Angs[w]) - sin(Angs[min(w+1, n-1)])));
      Matrix[w][n] -= 2 * Springk * d;
    }
    
    //for(int i = 0; i < n; i++){for(int j = 0; j < n+1; j++){print(Matrix[i][j]," ");}println();}
    //println("----------");
    float ratio;
    int i, r;
    for(int c = 0; c < n-1; c++){
      for(r = c+1; r < n; r++){
        ratio = Matrix[r][c]/Matrix[c][c];
        for(i = c+1; i < n+1; i++){
          Matrix[r][i] -= ratio*Matrix[c][i];
        }
        Matrix[r][c] = 0;
      }
    }
    //for(int i = 0; i < n; i++){for(int j = 0; j < n+1; j++){print(Matrix[i][j]," ");}println();}
    
    float[] acc = new float[n];
    for(i = n-1; i >= 0; i--){
      for(int j = i+1; j < n; j++){
        Matrix[i][n] -= acc[j]*Matrix[i][j];
      }
      acc[i] = Matrix[i][n]/Matrix[i][i];
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
