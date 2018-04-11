void setup() {
  size(1650, 950);
  background(255,255,255);
}


//(cos(((12/60)-12)/180*PI)+1)*60
var x = 0;
void draw() {
	stroke(0,0,0);
	point(x, (cos(x/3.8)+1)*120);
	//println(x);
	x+=0.5;

	for(var i = 0; i < round(height/24); i++){
		stroke(255,0,0);
		line(i*24, -1, i*24, 1000);
	}
}