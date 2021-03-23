float[][] points = {};
float[][] FourierValues = {};

PVector imageOffset = new PVector(0,0);
float imageScale = 1;
int minSamples = (int)pow(2, 12);

void setup(){
	size(window.innerWidth, 500);
	
	background(50);
	frameRate(20);

	center = new PVector(width/2, height/2);
}

float t = 0;
float dt = 0.0001;
var resolutionSelector = document.getElementById("input-resolution");
var StepSelector = document.getElementById("input-step");
vaar colorSelector = document.getElementById("input-color");
int stepsPerFrame = document.getElementById("input-speed").value;
float[][] dPoints;// = new float[ceil(1/dt)+1][2];
PVector center;
float Scale = 1;
int Res = -1;
color Linecolor = color(255, 0, 0);

float[] ei(float x){
	float[] out = {cos(x), sin(x)};
	return out;
}

float[] imMult(float[] a, float[] b){
	float[] out = {a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]};
	return out;
}

float[] imScl(float[] a, float b){
	float[] out = {a[0] * b, a[1] * b};
	return out;
}

float[] imAdd(float[] a, float[] b){
	float[] out = {a[0] + b[0], a[1] + b[1]};
	return out;
}

PVector getPoint(PVector[] a, int x){
	if(x < 0){
		return a[(abs(x)-1)%a.length];
	}
	return a[x%a.length];
}

float log2 = log(2);
float[][] fft(float[][] P){
	float[][] x = fftr(P, 1, 0, P.length, (int)round(log(P.length)/log2-1), -1);
	
	float[][] out = new float[P.length][2];
	for(int i = 0; i < P.length/2; i++){
		out[i] = x[P.length/2 - i - 1];
		out[i][0] /= P.length;
		out[i][1] /= P.length;
		//out[i] = append(out[i], P.length/2 - i - 1);
		
		out[i + P.length/2] = x[P.length - i - 1];
		out[i + P.length/2][0] /= P.length;
		out[i + P.length/2][1] /= P.length;
		//out[i + P.length/2] = append(out[i + P.length/2], -i - 1);
	}
	
	out[P.length - 1][0] = 0;
	out[P.length - 1][1] = 0;
	//out[P.length - 1][2] = 0;
	
	return out;
}

ArrayList<float[][]> factors = new ArrayList<float[][]>();

float[][] fftr(float[][] P, int s, int o, int N, int f, int inv){
	float[][] out = new float[N][2];
	if(N <= 1){
		out[0] = P[o];
		return out;
	}
	
	float[][] Even = fftr(P, s*2, o, N/2, f-1, inv);
	float[][] Odd = fftr(P, s*2, o+s, N/2, f-1, inv);
	if(factors.size() <= f){
		float[][] F = new float[N/2][2];
		for(int i = 0; i < N/2; i++){
			F[i] = ei(2 * PI * (float)i / (float)N);
			//F[i][0] = cos(2 * PI * (float)i / (float)N);
			//F[i][1] = sin(2 * PI * (float)i / (float)N);
		}
		factors.add(F);
	}
	
	for(int i = 0; i < N/2; i++){
		float[] e1 = factors.get(f)[i];//{cos(-TAU * (float)i / (float)N), sin(-TAU * (float)i / (float)N)};
		float[] e = {e1[0] * Odd[i][0] - inv * e1[1] * Odd[i][1], e1[0] * Odd[i][1] + inv * e1[1] * Odd[i][0]};
		out[   i   ][0] = Even[i][0] + e[0];
		out[   i   ][1] = Even[i][1] + e[1];
		out[i + N/2][0] = Even[i][0] - e[0];
		out[i + N/2][1] = Even[i][1] - e[1];
	}
	
	return out;
}

void drawF(float[][] fValues, float t){
	int number = fValues.length;
	
	noFill();
	//PVector[] Pts = {};
	float[] end = {0,0};
	float[] cmplx;
	float[] pnt;
	stroke(255);
	for(int i = 0; i <= ((Res == -1) ? floor((number - 1)/2) : Res); i++){
		//noFill();
		int n = (number-i+number/2-2)%(number-1);
		cmplx = ei(2*PI * i * t);
		pnt = imMult(fValues[n], cmplx);
		end = imAdd(end, pnt);
		
		//float r = sqrt(sq(fValues[n][0])+sq(fValues[n][1]));
		//stroke(0,0,255,200);
		//ellipse(end[0]-pnt[0], end[1]-pnt[1], r*2, r*2);
		//stroke(255);
		line((end[0]-pnt[0])*Scale, (end[1]-pnt[1])*Scale, end[0]*Scale, end[1]*Scale);
		//Pts = (PVector[])append(Pts, new PVector(end[0]-pnt[0], end[1]-pnt[1]));
		if(i!=0){
			n = (number+i+number/2-2)%(number-1);
			cmplx[1] *= -1;
			pnt = imMult(fValues[n], cmplx);
			end = imAdd(end, pnt);
			
			//r = sqrt(sq(fValues[n][0])+sq(fValues[n][1]));
			//stroke(0,0,255,200);
			//ellipse(end[0]-pnt[0], end[1]-pnt[1], r*2, r*2);
			//stroke(255);
			line((end[0]-pnt[0])*Scale, (end[1]-pnt[1])*Scale, end[0]*Scale, end[1]*Scale);
			//Pts = (PVector[])append(Pts, new PVector(end[0]-pnt[0], end[1]-pnt[1]));
		}
	}
}

void addPoint(float[][] fValues, float t){
	int number = fValues.length;
	float[] end = {0,0};
	float[] cmplx;
	float[] pnt;
	for(int i = 0; i <= ((Res == -1) ? floor((number - 1)/2) : Res); i++){
		int n = (number-i+number/2-2)%(number-1);
		cmplx = ei(2 * PI * i * t);
		pnt = imMult(fValues[n], cmplx);
		//if(i == 0){println(imMult(fValues[n], ei(2 * PI * fValues[n][2] * t)));}
		end = imAdd(end, pnt);
		
		if(i!=0){
			n = (number+i+number/2-2)%(number-1);
			cmplx[1] *= -1;
			pnt = imMult(fValues[n], cmplx);
			end = imAdd(end, pnt);
		}
	}
	
	int tv = round((t%1)/dt);
	dPoints[tv] = end;
}

float DistSq(float x, float y){
	return x*x + y*y;
}

void drawPoints(float t){
	int tv = round((t%1)/dt);
	
	/*for(int i = 0; i < dPoints.length; i++){
		if(dPoints[i] == null){break;}
		stroke(255, 0, 0, 255); //350 - ((i < tv) ? tv - i : dPoints.length - i + tv)*255/dPoints.length
		point(dPoints[i][0]*Scale, dPoints[i][1]*Scale);
	}*/

	stroke(Linecolor);
	for(int i = 0; i < dPoints.length; i++){
		int j = (i+1)%dPoints.length;
		if(dPoints[j] == null){break;}
		if(DistSq(dPoints[i][0] - dPoints[j][0], dPoints[i][1] - dPoints[j][1]) < 400){
			line(dPoints[i][0]*Scale, dPoints[i][1]*Scale, dPoints[j][0]*Scale, dPoints[j][1]*Scale);
		}else{
			point(dPoints[i][0]*Scale, dPoints[i][1]*Scale);
		}
	}
}

void update(){
	if(SamplePoints.length == 0){return;}
	updateTimer = -1;
	float[][] Ps = new float[SamplePoints.length][2];
	//points = SamplePoints;
	arrayCopy(SamplePoints, Ps);
	points = Ps;

	PVector Min = new PVector(points[0][0], points[0][1]*-1);
	PVector Max = new PVector(points[0][0], points[0][1]*-1);

	for(int i = 0; i < points.length; i++){
		points[i][1] *= -1;
		Min.x = min(Min.x, points[i][0]);
		Min.y = min(Min.y, points[i][1]);
		Max.x = max(Max.x, points[i][0]);
		Max.y = max(Max.y, points[i][1]);
	}

	PVector size = new PVector(Max.x - Min.x, Max.y - Min.y);
	float imageScale = min(width/size.x*0.9, height/size.y*0.8);

	for(int i = 0; i < points.length; i++){
		points[i][0] += -Min.x - size.x/2;
		points[i][1] += -Min.y - size.y/2;
		points[i][0] *= imageScale;
		points[i][1] *= imageScale;
	}

	FourierValues = fft(points);

	t = 0;
	//dt = 1/(float)points.length;
	dt = StepSelector.value / (float)points.length;
	float[][] dPnts = new float[round(1/dt)][2];
	dPoints = dPnts;

	resolutionSelector.max = (int)(points.length / 2);
	resolutionSelector.value = resolutionSelector.max;
}

int updateTimer = 10;
void draw(){
	background(50);
	updateTimer--;
	if(updateTimer == 0){update();}

	translate(center.x, center.y);

	if(points.length > 0){
		stroke(0);
		strokeWeight(1);
		drawPoints(t);
		drawF(FourierValues, t);
		//t += dt*stepsPerFrame;
		for(int i = 0; i < stepsPerFrame; i++){
			addPoint(FourierValues, t);
			t+=dt;
		}
	}
	resetMatrix();

	//String c = colorSelector.value.substring(1);
	Linecolor = unhex("ff" + colorSelector.value.substring(1));
	document.getElementById("color-label").style.backgroundColor = colorSelector.value;
	document.getElementById("color-label").style.color = colorSelector.value;
}

document.getElementById("input-speed").onchange = function() {
	stepsPerFrame = document.getElementById("input-speed").value;
}

resolutionSelector.onchange = function() {
	resolutionSelector.value = max(min((int)resolutionSelector.max, (int)resolutionSelector.value), (int)resolutionSelector.min);
	Res = resolutionSelector.value;
	t = 0;
	float[][] dPnts = new float[round(1/dt)][2];
	dPoints = dPnts;
}

StepSelector.onchange = function(){
	StepSelector.value = max(min((float)StepSelector.max, (float)StepSelector.value), (float)StepSelector.min);
	dt = StepSelector.value / (float)points.length;
	t = 0;
	float[][] dPnts = new float[round(1/dt)][2];
	dPoints = dPnts;
}

/*document.getElementById("functions").Clicked = function() {
	println("x");
	update();
}*/

Clicked = function() {
	update();
}

Update = function() {
	updateTimer = 3;
}

/*document.getElementById("input-text").onkeyup = function() {
	updateTimer = 2;
};*/

/*
void mouseWheel(MouseEvent event) {
	float e = event.getCount();
	//println(e);
	//y = (1 + e/100)*x;
	float zoomFactor = 1 + (float)e/100;
	Scale /= zoomFactor;
}*/