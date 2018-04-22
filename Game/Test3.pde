void setup() {
  size(1650, 950);
  background(255,255,255);
}

var pmousePressed = false;

function roundedRectangle(x,y,width,height,rad){
	rectMode(CORNER);
	ellipseMode(CENTER);
	ellipse(x+rad, y+rad, rad*2, rad*2);
	ellipse(x+width-rad, y+rad, rad*2, rad*2);
	ellipse(x+rad, y+height-rad, rad*2, rad*2);
	ellipse(x+width-rad, y+height-rad, rad*2, rad*2);

	rect(x+rad, y, width-rad*2, height);
	rect(x, y+rad, width, height-rad*2);
}

function slider(x,y,Width,Height,minvalue,maxvalue,currentValue) {
	this.pos = new PVector(x,y);
	this.Width = Width;
	this.Height = Height;
	this.range = [minvalue,maxvalue];
	this.value = currentValue || minvalue;
	this.clicked = false;
}

slider.prototype.draw = function() {
	pushMatrix();
	translate(this.pos.x,this.pos.y);

	var sliderX = constrain(this.Width*14/20,this.Width-20)*((this.value-this.range[0])/(this.range[1]-this.range[0])) + (this.Width-constrain(this.Width*14/20,this.Width-20))/2;

	fill(100);
	roundedRectangle(0,0,this.Width,this.Height,5);
	fill(150);
	roundedRectangle(constrain(this.Width/20,0,2),constrain(this.Width/20,0,2),constrain(this.Width*16/20,this.Width-4,this.Width),constrain(this.Height*14/20,this.Height-4,this.Height),5);

	fill(50);
	rectMode(CENTER);
	rect(this.Width/2, this.Height/2, constrain(this.Width*14/20,this.Width-20), this.Height/10);

	ellipseMode(CENTER);
	fill(25);
	ellipse(sliderX,this.Height/2,this.Height*8/20,this.Height*8/20);

	popMatrix();

	if(mousePressed && mouseX >= this.pos.x && mouseX <= this.pos.x+this.Width && mouseY >= this.pos.y && mouseY <= this.pos.y+this.Height && mousePressed !== pmousePressed){
		this.clicked = true;
	}else if(mousePressed === false){
		this.clicked = false;
	}

	if(this.clicked === true){
		this.value = round(constrain((mouseX-this.pos.x)*((this.range[1]-this.range[0])/constrain(this.Width*14/20,this.Width-20)), this.range[0], this.range[1])*10)/10;
	}
};

function button(x,y,width,height,text,textsize,textcolor,rad) {
	this.pos = new PVector(x,y);
	//this.textoffset = new PVector(textoffsetx,textoffsety);
	this.textsize = textsize;
	this.width = width;
	this.height = height;
	this.text = text;
	this.textcolor = textcolor;
	this.rad = rad;
}

button.prototype.draw = function() {
	pushMatrix();
	translate(this.pos.x,this.pos.y);
	roundedRectangle(0,0,this.width,this.height,this.rad);

	fill(this.textcolor[0],this.textcolor[1],this.textcolor[2]);
	textAlign(CENTER, CENTER);
	textSize(this.textsize);
	text(this.text, this.width/2, this.height/2);
	popMatrix();
};

button.prototype.detectClick = function(click) {
	if(mousePressed && mouseX >= this.pos.x && mouseX <= this.pos.x+this.width && mouseY >= this.pos.y && mouseY <= this.pos.y+this.height && (mousePressed !== pmousePressed || click === false)){
		return true;
	}else{
		return false;
	}
};

var LightSliderVertical = new slider(width*57/64,100,width*3/32*16.5,20,0.0,0.4,0.2);
var LightSliderHorizontal = new slider(width*57/64,160,width*3/32*16.5,20,0.0,0.4,0.2);

var temp = new button(50,250,300,100,"Instructions",75,[50,50,255],5);

var button1 = new button(700,700,150,50,"Play",50,[50,50,255],5);

var test = [0,1,2,3,4,5];

void draw() {
	background(255);
	noStroke();
	fill(255,0,0);
	LightSliderHorizontal.draw();
	LightSliderVertical.draw();

	fill(100);
	button1.draw();
	if(button1.detectClick(true) === true){
		println("hi");
	}
	test = [0,1,2,3,4,5];
	fill(255,0,0);
	textSize(20);
	text(test,500,500);
	
	test.splice(4,1);

	textSize(20);
	text(test,500,550);	

	fill(100);
	temp.draw();
	if(temp.detectClick(true) === true){

	}

	fill(100,100,100,100);
	rect(400,400,400,400,10);

	pmousePressed = mousePressed; // must be at the below all code using this varible, put at bottom of draw function if possible
}