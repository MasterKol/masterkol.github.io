void setup(){
  size(screen.width-10, screen.height-85);
  background(50,50,50);
}

width = 1600;
height = 950;

var Distance_Scale = 9.461*pow(10,15)/5;

var Size = [2000,2000];

var leaves = 0;
var tolerence = 0.8;
var G = 6.67*pow(10, -11);
var offset = [0,0];
var Scale = 1;

var follow = false;
var viewNum = 0;
var cosmological_constant = 0;

var runsPerFrame = 1;

function dist(p1, p2) {
	return sqrt(sq(p1.x-p2.x) + sq(p1.y-p2.y));
}

function distSQ(p1, p2) {
	return sq(p1.x-p2.x) + sq(p1.y-p2.y);
}

function Point(x,y,vx,vy,mass,rad) {
	this.pos = new PVector(x*Distance_Scale,y*Distance_Scale);
	this.vel = new PVector(vx, vy);
	this.mass = mass;
	this.num = Points.length;
	this.rad = rad;
	var colors = [[255,255,255], [255,100,100], [100,100,255], [255,255,100]];
	this.color = colors[round(random(-0.4,3.49))];
}

Point.prototype.draw = function() {
	if(this.pos.x/Distance_Scale > (-offset[0]-this.rad-width/2)/Scale && this.pos.x/Distance_Scale < (-offset[0]+width-this.rad)/Scale && this.pos.y/Distance_Scale > (-offset[1]-this.rad-height/2)/Scale && this.pos.y/Distance_Scale < (-offset[1]+height-this.rad)/Scale){
		ellipseMode(CENTER);
		noStroke();
		if(this.num === viewNum){
			fill(0, 255, 0);
		}else{
			fill(this.color[0], this.color[1], this.color[2]);
		}
		ellipse(this.pos.x/Distance_Scale, this.pos.y/Distance_Scale, this.rad, this.rad);
	}
};

Point.prototype.move = function(){
	this.pos.x += this.vel.x;
	this.pos.y += this.vel.y;

	this.pos.x *= (1+cosmological_constant);
	this.pos.y *= (1+cosmological_constant);
};

Point.prototype.force = function(f,dir){
	this.vel.x += f*cos(dir)/this.mass;
	this.vel.y += f*sin(dir)/this.mass;
};

function ContainsPoint(list, Num) {
	for(var i = 0; i < list.length; i++){
		if(list[i].num === Num){
			return true;
		}
	}
	return false;
}

Point.prototype.gravitate = function(Tree) {
	var Dist = distSQ(Tree.COM, this.pos);
	if(Tree.children === null || sq(Tree.dim.x)/Dist <= sq(tolerence) || Tree.points.length === 1){
		if(ContainsPoint(Tree.points, this.num) === false){
			this.force(this.mass*Tree.mass*G/(Dist+2), atan2(Tree.COM.y-this.pos.y, Tree.COM.x-this.pos.x));
		}
	}else{
		for(var i = 0; i < Tree.children.length; i++){
			if(Tree.children[i].points.length > 0){
				this.gravitate(Tree.children[i]);
			}
		}
	}
};

function QNode(parent, points, x, y, width, height, max) {
	this.parent = parent;
	if(this.parent === null){
		this.parentList = concat([], points);
	}else{
		this.parentList = concat([], this.parent.points);
	}
	this.points = points;
	this.pos = new PVector(x,y);
	this.dim = new PVector(width,height);
	this.max = max;
	this.children = null;
	this.mass = 0;
	this.COM = new PVector(0,0);
	for(var i = 0; i < this.points.length; i++){
		this.mass += this.points[i].mass;
		this.COM.x += this.points[i].pos.x*this.points[i].mass;
		this.COM.y += this.points[i].pos.y*this.points[i].mass;
	}
	this.COM.x = this.COM.x/this.mass;
	this.COM.y = this.COM.y/this.mass;
	//println(this.COM);
}

QNode.prototype.Sort = function() {
	var nList = [];
	for(var i = 0; i < this.points.length; i++){
		if(this.points[i].pos.x >= this.pos.x && this.points[i].pos.x < this.pos.x+this.dim.x && this.points[i].pos.y >= this.pos.y && this.points[i].pos.y < this.pos.y+this.dim.y){
			nList.push(this.points[i]);
		}
	}
	this.points = nList;
};

QNode.prototype.Break = function() {
	if(this.points.length >= this.max && this.children === null){
		this.children = [];
		this.children.push(new QNode(this, this.points, this.pos.x, this.pos.y, this.dim.x/2, this.dim.y/2, this.max));
		this.children.push(new QNode(this, this.points, this.pos.x+this.dim.x/2, this.pos.y, this.dim.x/2, this.dim.y/2, this.max));
		this.children.push(new QNode(this, this.points, this.pos.x, this.pos.y+this.dim.y/2, this.dim.x/2, this.dim.y/2, this.max));
		this.children.push(new QNode(this, this.points, this.pos.x+this.dim.x/2, this.pos.y+this.dim.y/2, this.dim.x/2, this.dim.y/2, this.max));
		
		for(var i = 0; i < this.children.length; i++){
			this.children[i].Sort();
		}
	}
};

QNode.prototype.draw = function(){
	strokeWeight(0.1);
	rectMode(CORNER);
	noFill();
	stroke(255);

	rect(this.pos.x/Distance_Scale, this.pos.y/Distance_Scale, this.dim.x/Distance_Scale, this.dim.y/Distance_Scale);
};

QNode.prototype.Update = function() {
	/*if(this.parent !== null && this.parentList !== this.parent.list){
		this.parentList = concat([], this.parent.points);
		this.points = this.parentList;
		this.Sort();
	}else if(this.parent === null && this.parentList !== this.points){
		this.parentList = concat([], this.points);
		this.Sort();
	}*/
	
	if(this.points.length > this.max && this.children === null){
		this.Break();
	}else if(this.points.length <= this.max && this.children !== null){
		this.children = null;
	}

	if(this.children !== null){
		for(var i = 0; i < this.children.length; i++){
			this.children[i].Update();
		}
	}

	if(this.points === 0){
		this.mass = 0;
		this.COM = 0; 
	}else if(this.points === 1){
		this.mass = this.points[0].mass;
		this.COM = this.points[0].pos;
	}else{
		this.mass = 0;
		this.COM = new PVector(0,0);
		for(var i = 0; i < this.points.length; i++){
			this.mass += this.points[i].mass;
			this.COM.x += this.points[i].pos.x*this.points[i].mass;
			this.COM.y += this.points[i].pos.y*this.points[i].mass;
		}
		this.COM.x = this.COM.x/this.mass;
		this.COM.y = this.COM.y/this.mass;
	}
	if(this.children === null){
		//this.draw();
	}
};

function Galaxy(x,y,stars,m1,m2,vx,vy,MinDist,MaxDist,velScale,dir) {
	Points.push(new Point(x, y, vx, vy, m1, 2));
	for(var i = 0; i < stars; i++){
		var D = random(MinDist,MaxDist);
		var vel = sqrt(G*m1/(D*Distance_Scale))*velScale; //*random(0.9, 1.1)
		var ang = random(-PI,PI);
		Points.push(new Point(D*cos(ang)+x, D*sin(ang)+y, vel*cos(ang+(HALF_PI*dir))+vx, vel*sin(ang+(HALF_PI*dir))+vy, m2, 0.75));
	}
}

var Points = [];
//for(var i = 0; i < 2000; i++){
//	Points.push(new Point(random(-width/2,width/2), random(-height/2,height/2), 0, 0, 1000000000, 2));
//}
/*
Points.push(new Point(-700, 400, 0, 0, 1000000000000, 4));
for(var i = 0; i < 1000; i++){
	var D = random(10,150);
	var vel = sqrt(G*1000000000000/D); //*random(0.9, 1.1)
	var ang = random(-PI,PI);
	Points.push(new Point(D*cos(ang)-700, D*sin(ang)+400, vel*cos(ang+HALF_PI), vel*sin(ang+HALF_PI), 10, 2));
}

Points.push(new Point(100, -600, -0.1, 0, 1000000000000, 4));
for(var i = 0; i < 500; i++){
	var D = random(10,70);
	var vel = sqrt(G*1000000000000/D);
	var ang = random(-PI,PI);
	Points.push(new Point(D*cos(ang)+100, D*sin(ang)-600, vel*cos(ang-HALF_PI)-0.1, vel*sin(ang-HALF_PI), 10000, 2));
}*/

//Galaxy(0,0,1000,10000000000000,1000,0,0,10,100,1);
Galaxy(-400,-100,1000,2*pow(10,57),2*pow(10,35),pow(10,15)/2,0,25,250,1,1);
Galaxy(400,100,1000,2*pow(10,57),2*pow(10,35),-pow(10,15)/2,0,25,250,1,-1);

/*for(var x = -width/2; x < width/2; x+=25){
	for(var y = -height/2; y < height/2; y+=25){ //x,y,vx,vy,mass,rad
		Points.push(new Point(x, y, 0, 1, noise(x/100,y/100)*pow(10,11), 1));
	}
}*/

//for(var i = 0; i < 2000; i++){
//	Points.push(new Point(random(-Size[0]/2, Size[0]/2), random(-Size[1]/2, Size[1]/2), 0, 0, 10000000000, 2));
//}

//Points.push(new Point(50, 0, 0, 1.155, 10000, 2));
//Points.push(new Point(200, 0, 0, 0, 10000000000, 2));
//Points.push(new Point(60, 0, 0, 1.05, 10000, 2));
//Points.push(new Point(65, 0, 0, 1.01, 10000, 2));
//Points.push(new Point(70, 0, 0, 0.98, 10000, 2));

var QuadTree = new QNode(null, Points, -Size[0]/2, -Size[1]/2, Size[0], Size[1], 1);
var pkeyPressed = keyPressed;

void draw() {
	fill(50,50,50,255);
	rect(0,0,width,height);

	if(follow === true && viewNum >= 0 && viewNum < Points.length){
		offset[0] = -Points[viewNum].pos.x*Scale/Distance_Scale;
		offset[1] = -Points[viewNum].pos.y*Scale/Distance_Scale;
	}

	pushMatrix();
	translate(width/2+offset[0], height/2+offset[1]);
	scale(Scale);

	if(mousePressed){
		offset[0] += mouseX-pmouseX;
		offset[1] += mouseY-pmouseY;
	}

	for(var w = 0; w < runsPerFrame; w++){
		var greatest = Points[0].pos.x;
		var least = Points[0].pos.x;

		for(var i = 0; i < Points.length; i++){
			if(Points[i].pos.x > greatest){
				greatest = Points[i].pos.x;
			}
			if(Points[i].pos.y > greatest){
				greatest = Points[i].pos.y;
			}
			if(Points[i].pos.x < least){
				least = Points[i].pos.x;
			}
			if(Points[i].pos.y < least){
				least = Points[i].pos.y;
			}
		}

		greatest = ceil(greatest); least = floor(least);

		leaves = 0;
		QuadTree = new QNode(null, Points, least, least, abs(greatest-least), abs(greatest-least), 1);
		temp = 0;
		QuadTree.Update();

		for(var i = 0; i < Points.length; i++) {
			Points[i].gravitate(QuadTree);
		}

		for(var i = 0; i < Points.length; i++) {
			Points[i].move();
		}
	}

	//println(Points[0].vel);
	//println(dist(Points[0].pos, Points[1].pos));

	var centerPos = new PVector(-offset[0]/Scale, -offset[1]/Scale);

	//var temp = millis();
	for(var i = 0; i < Points.length; i++){
		Points[i].draw();
	}
	//println(millis()-temp);

	if(keyPressed && key === 'i'){
		Scale*=2;
		offset[0] = -centerPos.x*Scale;
		offset[1] = -centerPos.y*Scale;
		//background(50,50,50);
	}else if(keyPressed && key === 'o'){
		Scale/=2;
		offset[0] = -centerPos.x*Scale;
		offset[1] = -centerPos.y*Scale;
		//background(50,50,50);
	}

	if(keyPressed && key === 'f' && keyPressed !== pkeyPressed){
		if(follow === true){follow=false;}else{follow=true;}
		//background(50,50,50);
	}

	if(keyPressed && key === '=' && viewNum < Points.length){
		viewNum++;
		//background(50,50,50);
	}else if(keyPressed && key === "-" && viewNum > 0){
		viewNum--;
		//background(50,50,50);
	}

	//leaves = 0;
	//QuadTree.points = Points;
	//QuadTree.Update();

	/*if(random(0,1) > 0.5){
		Points.push(new Point(random(-1640/2,1640/2), random(-940/2,940/2), random(-1,1), random(-1,1)));
	}*/

	popMatrix();

	fill(255, 0, 0);
	text(Points.length, 20, 20);
	text(frameRate, width-40, 20);

	pkeyPressed = keyPressed;
}