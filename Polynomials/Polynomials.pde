Complex[] coeffs = new Complex[7];//{new Complex(-1, 0), new Complex(2, 0), new Complex(10, 0), new Complex(5, 0)};
Complex[] points = new Complex[coeffs.length-1];
Complex[] npoints = new Complex[coeffs.length-1];

int[] PolyBuffer;

float upper = 0;
float lower = 0;
int upScale = 4;
int bufferWidth;
int bufferHeight;

var degreeInput = document.getElementById("input-degree");
var coeffBox = document.getElementById("coeffs");
var randomizeButton = document.getElementById("input-randomize");
var viewInput = document.getElementById("input-view-option");
var rootRestButton = document.getElementById("input-search-reset");
var rootBox = document.getElementById("roots");
var viewDescription = document.getElementById("view-description");

boolean converged = false;

void setup(){
	size(700, 700);
	PolyBuffer = new int[width * height / (upScale * upScale)];
	bufferWidth = width / upScale;
	bufferHeight = width / upScale;
	frameRate(30);
	
	Randomize();
	
	//points[0] = new Complex(0.33333, 0);
	//points[1] = new Complex(-2, 0.5);
	//println(upper, lower);
	degreeInput.value = coeffs.length-1;
	
	noCursor();
	setViewDescription();

	/*Complex a = new Complex(1, 1);
	Complex b = new Complex(2, 2);
	Complex c = func(a);

	println(str(a));
	println(str(b));
	println(str(c));
	println(c.real + ", " + c.imag);

	println("--------");*/
}

boolean pkeyPressed = keyPressed;

PVector center = new PVector(350, 350);
float t = 0;
float zoom = 1;
boolean redraw = true;

int df = 1;
float log4 = log(4);
int choice = 1;
int accumOffX = 0, accumOffY = 0; // accumulates the change in position of the screen that doesn't result in a shift of the background

void draw(){
	background(255);
	if(redraw){
		df = 1;
		redraw = false;
	}

	/*if(df == 17){
		colorMode(RGB, 255);
		color c00, c10, c01, c11;
		for(int x = 0; x < bufferWidth-2; x+=2){
			for(int y = 0; y < bufferHeight-2; y+=2){
				c00 = PolyBuffer[y * bufferWidth + x];
				c10 = PolyBuffer[y * bufferWidth + x + 2];
				c01 = PolyBuffer[(y + 2) * bufferWidth + x];
				c11 = PolyBuffer[(y + 2) * bufferWidth + x + 2];
				PolyBuffer[y * bufferWidth + x + 1] = lerpColor(c00, c10, 0.5);
				PolyBuffer[(y+1) * bufferWidth + x] = lerpColor(c00, c01, 0.5);
				PolyBuffer[(y+1) * bufferWidth+x+1] = BiLerp(c00, c10, c01, c11, 0.5, 0.5);
			}
		}
		df++;
	}*/
	
	if(df <= 16){
		accumOffX = 0; // full redraws reset the offset
		accumOffY = 0;
		//println(df);
		colorMode(HSB, 400);
		color c = color(0);
		//float tx, ty, a=0, l=0;
		//Complex v;
		int res, offx, offy;
		/*if(df == 1){
			res = 8;
			offx = 0;
			offy = 0;
		}else if(df <= 4){
			res = 4;
			offx = 4 * ((df-1)%2);
			offy = 4 * Math.floor((df-1)/2);
		}else{
			res = 2;
			offx = Math.floor((df+1)/3)%2 * 4 + abs((df+1)%3 - 1)*2;
			offy = Math.floor((df-5)/6)   * 4 + (1 - Math.floor((df - 3)%3 / 2))*2;
		}*/
		if(df == 1){
			res = 4;
			offx = 0;
			offy = 0;
		}else if(df <= 4){
			res = 2;
			offx = 2 * ((df-1)%2);
			offy = 2 * floor((df-1)/2);
		}else{
			res = 1;
			offx = floor((df+1)/3)%2 * 2 + abs((df+1)%3 - 1);
			offy = floor((df-5)/6) * 2 + 1 - floor((df - 3)%3 / 2);
		}
		//println(df + ", " + res + ", " + offx + ", " + offy);
		//println(df, res, offx, offy);
		//int res = 2 - floor(log((float)df-0.01) / log4);
		//int offx = 2 * ((df-1)%2);
		//int offy = 2 * ((df-1)/2);
		for(int x = offx; x < bufferWidth; x+=4){
			for(int y = offy; y < bufferHeight; y+=4){
				c = getPixelColor(x, y);
				for(int dx = x; dx < res+x; dx++){
					for(int dy = y; dy < res+y; dy++){
						if(dy >= bufferHeight || dx >= bufferWidth){continue;}
						PolyBuffer[dy * bufferWidth + dx] = c;
					}
				}
			}
		}
		df++;
	}
	


	loadPixels();
	//arrayCopy(PolyBuffer, 0, pixels, 0, 700*700);
	//pixels = PolyBuffer.slice();
	int usc = upScale * upScale;
	for(int i = 0; i < width * height / usc; i++){
		int x = (i * upScale) % width;
		int y = floor(i / bufferWidth) * upScale;
		//pixels[i*upScale + floor(i / width * upScale) * width] = PolyBuffer[i];
		//pixels[x + y * width * upScale] = PolyBuffer[i];
		for(int dx = 0; dx < upScale; dx++){
			for(int dy = 0; dy < upScale; dy++){
				pixels[x + dx + (y + dy) * width] = PolyBuffer[i];
				//pixels[i * usc + dx + dy * width] = PolyBuffer[i];
				//pixels[i*upScale + dx + (Math.floor(i / width) * upScale + dy) * width] = PolyBuffer[i];
				//pixels[i*upScale + dx + (Math.floor(i / width * upScale) + dy) * width] = PolyBuffer[i];
			}
		}
	}
	updatePixels();
	if(Math.round(t * 1000) % 1000 == 0 || npoints[0] == null){
		getNextPoints();
		//println("X");
	}
	
	translate(center.x + accumOffX, center.y + accumOffY);
	scale(zoom);
	colorMode(RGB, 255);
	fill(255);
	stroke(0);
	strokeWeight(0.4);
	//ellipse((p.real + 3.5) * 100, (p.imag + 3.5) * 100, 5, 5);
	for(int i = 0; i < points.length; i++){
		Complex p = Lerp(points[i], npoints[i], constrain((t+0.00001)%1, 0, 1));
		ellipse(p.real * 100, -p.imag * 100, 5, 5);
	}
	
	strokeWeight(1);
	noFill();
	stroke(0);
	ellipse(0, 0, upper*200, upper*200);
	ellipse(0, 0, lower*200-2, lower*200-2);
	stroke(255);
	ellipse(0, 0, upper*200-2, upper*200-2);
	ellipse(0, 0, lower*200, lower*200);
	
	resetMatrix();
	
	Complex m = new Complex((mouseX - center.x) / 100.0 / zoom, -(mouseY - center.y) / 100.0 / zoom);
	
	stroke(0);
	Complex d = Div(func(m), derv(m)).norm();
	//println(str(func(m)));
	//exit();
	line(mouseX, mouseY, mouseX - d.real * 20, mouseY + d.imag * 20);
	
	stroke(255);
	fill(255);
	text(str(Round(m, 2)), mouseX+2, mouseY-3);
	line(mouseX - 5, mouseY, mouseX + 5, mouseY);
	line(mouseX, mouseY - 5, mouseX, mouseY + 5);
	
	if(keyPressed && !pkeyPressed){
		if(key == 'r'){
			regen();
		}else if(key == 'p'){
			for(int i = 0; i < points.length; i++){
				println(i, str(points[i]));
			}
		}else if(key == 't'){
			Randomize();
		}else if(key == '1' && choice != 0){
			choice = 0;
			redraw = true;
		}else if(key == '2' && choice != 1){
			choice = 1;
			redraw = true;
		}else if(key == '3' && choice != 2){
			choice = 2;
			redraw = true;
		}
	}
	
	if(mousePressed && df == 17){
		int mouseMoveX = constrain(mouseX - pmouseX, -40, 40);
		int mouseMoveY = constrain(mouseY - pmouseY, -40, 40);
		center.x += mouseMoveX;
		center.y += mouseMoveY;
		if(mouseMoveX != 0 || mouseMoveY != 0){
			//redraw = true;
			//println(accumOffX, pmouseX - mouseX);
			int minX = 0, maxX = bufferWidth;
			int changeX = floor(-(mouseMoveX - accumOffX) / upScale);
			accumOffX -= mouseMoveX + changeX * upScale;
			if(changeX > 0){
				minX = bufferWidth - changeX;
				for(int x = 0; x < bufferWidth - changeX; x++){
					for(int y = 0; y < bufferHeight; y++){
						PolyBuffer[y * bufferWidth + x] = PolyBuffer[y * bufferWidth + x + changeX];
					}
				}
			}else if(changeX < 0){
				maxX = -changeX;
				for(int x = bufferWidth + changeX - 1; x >= 0; x--){
					for(int y = 0; y < bufferHeight; y++){
						PolyBuffer[y * bufferWidth + x - changeX] = PolyBuffer[y * bufferWidth + x];
					}
				}
			}else{
				maxX = 0;
			}

			int minY = 0, maxY = bufferHeight;
			int changeY = floor(-(mouseMoveY - accumOffY) / upScale);
			accumOffY -= mouseMoveY + changeY * upScale;
			if(changeY > 0){
				minY = bufferHeight - changeY;
				for(int y = 0; y < bufferHeight - changeY; y++){
					for(int x = 0; x < bufferWidth; x++){
						PolyBuffer[y * bufferWidth + x] = PolyBuffer[(y + changeY) * bufferWidth + x];
					}
				}
			}else if(changeY < 0){
				maxY = -changeY;
				for(int y = bufferHeight + changeY - 1; y >= 0; y--){
					for(int x = 0; x < bufferWidth; x++){
						PolyBuffer[(y - changeY) * bufferWidth + x] = PolyBuffer[y * bufferWidth + x];
					}
				}
			}else{
				maxY = 0;
			}
			//println(changeX, changeY);

			colorMode(HSB, 400);
			for(int x = minX; x < maxX; x++){
				for(int y = 0; y < bufferHeight; y++){
					PolyBuffer[y * bufferWidth + x] = getPixelColor(x - accumOffX / upScale, y - accumOffY / upScale);
				}
			}
			for(int x = max(0, -changeX); x < bufferWidth + min(0, -changeX); x++){
				for(int y = minY; y < maxY; y++){
					PolyBuffer[y * bufferWidth + x] = getPixelColor(x - accumOffX / upScale, y - accumOffY / upScale);
				}
			}
		}
	}
	
	pkeyPressed = keyPressed;
	t = round(t * 1000 + 10) / 1000.0;
}

class Complex{
	float real, imag;
	Complex(float real, float imag){
		this.real = real;
		this.imag = imag;
	}
	
	Complex(){this.real = 0; this.imag = 0;}
	
	float len(){
		return sqrt(real * real + imag * imag);
	}
	
	float angle(){
		return atan2(imag, real) + PI;
	}
	
	Complex Add(Complex b){
		real += b.real;
		imag += b.imag;
		return this;
	}
	
	Complex Mult(Complex b){
		float r = real;
		real = real * b.real - imag * b.imag;
		imag = r * b.imag + imag * b.real;
		return this;
	}
	
	Complex Multv(float b){
		real *= b;
		imag *= b;
		return this;
	}
	
	Complex copy(){
		return new Complex(real, imag);
	}
	
	Complex limit(float v){
		float l = real * real + imag * imag;
		if(l > v * v){
			l = sqrt(l);
			real *= v / l;
			imag *= v / l;
		}
		return this;
	}
	
	Complex norm(){
		float l = len();
		real /= l;
		imag /= l;
		return this;
	}
	
	Complex neg(){
		real *= -1;
		imag *= -1;
		return this;
	}
}

Complex Add(Complex a, Complex b){
	return new Complex(a.real + b.real, a.imag + b.imag);
}
/*
Complex Add(Complex a, float b){
	return new Complex(a.real + b, a.imag);
}*/

Complex Sub(Complex a, Complex b){
	return new Complex(a.real - b.real, a.imag - b.imag);
}

Complex Mult(Complex a, Complex b){
	return new Complex(a.real * b.real - a.imag * b.imag, a.real * b.imag + a.imag * b.real);
}

Complex Multv(Complex a, float b){
	return new Complex(a.real * b, a.imag * b);
}

Complex Div(Complex a, Complex b){
	float d = b.real * b.real + b.imag * b.imag;
	return new Complex((a.real * b.real + a.imag * b.imag) / d, (a.imag * b.real - a.real * b.imag) / d);
}

Complex Lerp(Complex a, Complex b, float y){
	return new Complex(a.real * (1-y) + b.real * y, a.imag * (1-y) + b.imag * y);
}

Complex Round(Complex a, int dec){
	float p = pow(10, dec);
	return new Complex(Math.round(a.real * p) / p, Math.round(a.imag * p) / p);
}

String str(Complex a){
	return "(" + a.real + (a.imag >= 0 ? " + " : " - ") + abs(a.imag) + "i)";
}

Complex func(Complex v){
	Complex o = coeffs[0].copy();
	Complex x = v.copy();

	for(int i = 1; i < coeffs.length; i++){
		o.Add(Mult(x, coeffs[i]));
		x.Mult(v);
	}
	
	return o;
}

Complex derv(Complex v){
	Complex o = coeffs[1].copy();
	
	Complex x = v.copy();
	for(int i = 2; i < coeffs.length; i++){
		o.Add(Mult(x, coeffs[i]).Multv(i));
		x.Mult(v);
	}
	
	return o;
}

Complex ratio(Complex v){
	Complex n = coeffs[0].copy();
	Complex d = coeffs[1].copy();
	Complex x = v.copy();
	n.Add(Mult(x, coeffs[1]));

	for(int i = 2; i < coeffs.length; i++){
		d.Add(Mult(x, coeffs[i]).Multv(i));
		x.Mult(v);
		n.Add(Mult(x, coeffs[i]));
	}
	
	return Div(n, d);
}

void polyReset(){
	float ma = 3.5;
	for(int i = 0; i < coeffs.length; i++){
		coeffs[i] = new Complex(random(-ma, ma), random(-ma, ma));
		if(i == coeffs.length - 1){
			coeffs[i] = new Complex(1, 0);
		}
		//print(str(coeffs[i]) + "x^" + i + " + ");
	}
	//println();
	
	upper = 0;
	lower = 0;
	
	for(int i = 0; i < coeffs.length-1; i++){
		upper = max(upper, coeffs[i].len());
	}
	
	for(int i = 1; i < coeffs.length; i++){
		lower = max(lower, coeffs[i].len());
	}
	upper = 1 + upper / coeffs[coeffs.length-1].len();
	lower = coeffs[0].len() / (coeffs[0].len() + lower);
}

void regen(){
	for(int i = 0; i < points.length; i++){
		float r = random(lower, upper);
		float a = random(0, 2*PI);
		points[i] = new Complex(cos(a) * r, sin(a) * r);
		npoints[i] = null;
	}
	getNextPoints();
}

void getNextPoints(){
	if(npoints[0] != null){
		for(int i = 0; i < points.length; i++){
			points[i] = npoints[i];
		}
	}
	
	converged = true;

	for(int i = 0; i < points.length; i++){
		Complex r = Div(func(points[i]), derv(points[i]));
		
		Complex s = new Complex(0, 0);
		for(int j = 0; j < points.length; j++){
			if(i == j){continue;}
			s.Add(Div(new Complex(1,0), Sub(points[i], points[j])));
		}
		
		Complex w = Div(r, Sub(new Complex(1,0), Mult(r, s) ) );

		if(abs(w.real) > 0.00001 || abs(w.imag) > 0.00001){
			converged = false;
		}
		
		npoints[i] = Add(points[i], w.neg()).limit(upper);
		/*if(npoints[i].real != npoints[i].real){
			println(i, str(points[i]), str(r), str(s), str(w), str(func(points[i])), str(derv(points[i])));
			exit();
		}*/
	}
	updateRoots();
}

color BiLerp(color c00, color c10, color c01, color c11, float px, float py){
  return lerpColor( lerpColor(c00, c10, px), lerpColor(c01, c11, px) , py);
}

color getPixelColor(float x, float y){
	Complex p = new Complex((x*upScale - center.x) / 100.0 / zoom, -(y*upScale - center.y) / 100.0 / zoom);
	float a = 0, l = 0;
	if(choice == 0){
		a = p.angle() * 400 / 6.28;
		l = p.len() * 100;
	}else if(choice == 1){
		Complex v = func(p);
		a = v.angle() * 400 / 6.28;
		l = v.len() * 100;
	}else if(choice == 2){
		Complex v = ratio(p).neg();
		a = v.angle() * 400 / 6.28;
		l = 600 - v.len() * 300;
	}
	return color(a, 400, l);
}

function updateDegree(){
	int newDegree = max(round(degreeInput.value), 1);
	degreeInput.value = newDegree;
	int oldDegree = coeffs.length-1; // the constant "coefficent" doesn't count towards the degree
	if(newDegree == oldDegree){return;} // degree didn't change
	if(newDegree < oldDegree){
		Complex[] newCoeffs = new Complex[newDegree+1];
		for(int i = 0; i < newDegree+1; i++){
			newCoeffs[i] = coeffs[i];
		}
		coeffs = newCoeffs;
	} else {
		for(int i = 0; i < newDegree - oldDegree; i++){
			coeffs.push(new Complex(1, 0));
		}
	}

	Complex[] nP = new Complex[newDegree];
	points = nP;
	Complex[] nnP = new Compelx[newDegree];
	nPoints = nnP;

	regen();
	/*for(int i = 0; i < points.legth; i++){
		println(i + str(points[i]));
	}*/
	//getNextPoints();
	setCoeffs();
	redraw = true;
}

getCoeff = function(num){
	float realPart = parseFloat(document.getElementById("input-coeff" + num + "-real").value);
	float imagPart = parseFloat(document.getElementById("input-coeff" + num + "-imag").value);
	//println(round(num) + ", " + realPart + ", " + imagPart);

	//var x = realPart + 1;
	//println(x);

	coeffs[round(num)] = new Complex(realPart, imagPart);
	//var x = coeffs[round(num)].real + 1;
	//println(x);
	//println(str(func(new Complex(1, 1))));
	//println(str(coeffs[round(num)]));
	redraw = true;

	upper = 0;
	lower = 0;
	
	for(int i = 0; i < coeffs.length-1; i++){
		upper = max(upper, coeffs[i].len());
	}
	
	for(int i = 1; i < coeffs.length; i++){
		lower = max(lower, coeffs[i].len());
	}
	upper = 1 + upper / coeffs[coeffs.length-1].len();
	lower = coeffs[0].len() / (coeffs[0].len() + lower);

	regen();
};

scroll = function(event) {
	float e = constrain(event.deltaY, -50, 50);

	float zoomFactor = 1 + (float)e/200;
	oldzoom = zoom;
	zoom = constrain(zoom / zoomFactor, 0.1, 10);
	if(oldzoom != zoom){
		redraw = true;
		return true;
	}

	return false;
};

String getInput(float val, int num, bool ri){
	return '<input type="number" class="input-coeff" id="input-coeff' + num + "-" + (ri ? "real" : "imag") + '" style="width: 50px;" value="' + round(val*1000)/1000 + '" onchange="getCoeffMain(' + num + ')"/>';
}

function setCoeffs(){
	coeffBox.innerHTML = '';
	for(int i = 0; i < coeffs.length; i++){
		var lbl = document.createElement("label");
		lbl.className = "entry";
		var html = "(" + getInput(coeffs[i].real, i, true) + ' + ' + getInput(coeffs[i].imag, i, false) + 'i)';
		if(i == 0){
			html += " &nbsp;&nbsp;&nbsp;";
		}else if(i == 1){
			html += "x &nbsp;";
		}else{
			html += "x<sup>" + i + "</sup>";
		}
		if(i != coeffs.length-1){
			html += " +"
		}
		lbl.innerHTML = html + '<br>';
		coeffBox.appendChild(lbl);
	}
}

function updateRoots() {
	if(converged){
		rootBox.style.color = "#00ff00";
	} else {
		rootBox.style.color = "red";
	}

	rootBox.innerHTML = '';
	for(int i = 0; i < points.length; i++){
		rootBox.innerHTML += '<span class="entry">' + str(Round(points[i], 5)) + "</span><br>";
	}
}

function Randomize(){
	redraw = true;
	polyReset();
	regen();
	setCoeffs();
}

function setViewDescription(){
	if(choice == 0){
		viewDescription.innerHTML = "The default complex plane";
	} else if(choice == 1){
		viewDescription.innerHTML = "Graph of the polynomial below";
	} else if(choice == 2){
		viewDescription.innerHTML = "Shows the potential field that the points follow";
	}
}

viewInput.onchange = function(){
	//println(viewInput.selectedIndex);
	choice = viewInput.selectedIndex;
	redraw = true;
	setViewDescription();
};

rootRestButton.onclick = function(){regen()};

randomizeButton.onclick = Randomize;

degreeInput.onchange = updateDegree;