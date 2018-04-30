void setup() {
  size(1650, 950);
  background(50,255,50);
}

randomSeed(1);

var useImages = true;
var averageSpeed = 0;

var carImages = [loadImage("./Images/Car1.jpg"),loadImage("./Images/Car2.jpg"),loadImage("./Images/Car3.jpg"),loadImage("./Images/Car4.jpg")];

var time = 12;
var FR = 60;

var quickCos = [1,0,-1,0];
var quickSin = [0,-1,0,1];

var AspectRatio = 2;
var Size = [round(16.5*AspectRatio),round(9.5*AspectRatio)];
var board_Scale = round(100/Size[0]*2*1.65)/2;
//var board_Scale = 14;
var board = [];
var board_Connections = [];
var offset = [50,50];
//var offset = [-1422, -792];
//var offset = [-35*(board_Scale-8)*2, -55*(board_Scale-8)*2];
//var offset = [0,0];
var trafficOverlay = false;
var edditing = null;
var pmousePressed = false;
var pkeyPressed = false;
var pkey = '';
var intersections = 0;
var screen = "MainMenu"; // can be "MainMenu", "MainGame", "GamePaused", "GameSetup", "Instructions"
var pscreen = "MainMenu";
var cars = [];
var spots = [];
var bestScore = 0;
var carPositions = [];
var centerPos = new PVector(0,0);
/*for(var x = 0; x < round(Size[0]*100/8); x++){
	carPositions.push([]);
	//for(var y = 0; y < round(Size[1]*100/))
}*/

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

	var sliderX = this.Width*14/20*((this.value-this.range[0])/(this.range[1]-this.range[0])) + (this.Width-this.Width*14/20)/2;

	fill(100);
	roundedRectangle(0,0,this.Width,this.Height,5);
	fill(150);
	roundedRectangle(constrain(this.Width/20,0,2),constrain(this.Width/20,0,2),constrain(this.Width*16/20,this.Width-4,this.Width),constrain(this.Height*14/20,this.Height-4,this.Height),5);

	fill(50);
	rectMode(CENTER);
	rect(this.Width/2, this.Height/2, this.Width*14/20, this.Height/10);

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
		this.value = round(constrain((mouseX-this.pos.x)*((this.range[1]-this.range[0])/(this.Width*14/20)),this.range[0], this.range[1])*10)/10;
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

function ArraysEqual(a,b) {
	if(a.length !== b.length){
		return false;
	}else{
		for(var i = 0; i < a.length; i++){
			if(a[i] !== b[i]){
				return false;
			}
		}
		return true;
	}
}

function ArrayOr(array1, array2){
	var newArr = [];
	var Len = 0;
	if(array1.length > array2.length){Len = array1.length;}else{Len = array2.length;}
	for(var i = 0; i < Len; i++){
		if(array1[i] === 1 || array2[i] === 1){
			newArr.push(1);
		}else{
			newArr.push(0);
		}
	}
	return newArr;
}

function Dist(x1,y1,x2,y2){
	return sqrt(sq(x1-x2)+sq(y1-y2));
}

function GetAdj(x,y) {
	return [board[x+1][y] || null, board[x][y+1] || null, board[x-1][y] || null, board[x][y-1] || null];
}

function GetAdjConnections(x,y) {
	var output = [0,0,0,0];

	if(x+1 < Size[0]){
		output[0] = board[x+1][y][2];
	}
	if(x-1 > 0){
		output[2] = board[x-1][y][0];
	}
	if(y+1 < Size[1]){
		output[1] = board[x][y+1][3];
	}
	if(y-1 > 0){
		output[3] = board[x][y-1][1];
	}

	return output;
}

function GenAdj(x,y,depth,maxDepth) {
	if(ArraysEqual(board[x][y], [0,0,0,0]) === false && depth < maxDepth && x >= 4 && x <= Size[0]-4 && y >= 4 && y <= Size[1]-4){
		var probability = 1.2;
		if(ArraysEqual(board[x+1][y], [0,0,0,0]) && board[x][y][0] === 1 && x < Size[0]-2){
			board[x+1][y] = [round(random(0,probability)), round(random(0,probability)), 1, round(random(0,probability))];
			GenAdj(x+1,y,depth+1,maxDepth);
		}
		if(ArraysEqual(board[x-1][y], [0,0,0,0]) && board[x][y][2] === 1 && x > 2){
			board[x-1][y] = [1, round(random(0,probability)), round(random(0,probability)), round(random(0,probability))];
			GenAdj(x-1,y,depth+1,maxDepth);
		}
		if(ArraysEqual(board[x][y+1], [0,0,0,0]) && board[x][y][1] === 1 && y < Size[1]-2){
			board[x][y+1] = [round(random(0,probability)), round(random(0,probability)), round(random(0,probability)), 1];
			GenAdj(x,y+1,depth+1,maxDepth);
		}
		if(ArraysEqual(board[x][y-1], [0,0,0,0]) && board[x][y][3] === 1 && y > 2){
			board[x][y-1] = [round(random(0,probability)), 1, round(random(0,probability)), round(random(0,probability))];
			GenAdj(x,y-1,depth+1,maxDepth);
		}
	}
}

function Connect(x,y){
	if(x >= 2 && x <= Size[0]-2 && y >= 2 && y <= Size[1]-2){
		var adj = GetAdjConnections(x,y);
		for(var i = 0; i < adj.length; i++){
			if(adj[i] === 1){
				board[x][y][i] = 1;
			}
		}
	}
}

function GenBuildings(connections){
	var out = [[0,0],[0,0],[0,0],[0,0]];
	var added = [0,0,0,0];
	for(var i = 0; i < connections.length; i++){
		out[i][1] = random(0,255);
		if(connections[i] === 1){
			if(round(random(0.3,1)) === 1 && added[i] === 0){
				out[i][0] = 1;
			}
			if(round(random(0.3,1)) === 1 && added[(i+1)%4] === 0){
				out[(i+1)%4][0] = 1;
			}
			added[i] = 1;
			added[(i+1)%4] = 1;
		}
	}
	return out;
}

function piece(x,y,connections){
	this.connections = connections;
	this.buildings = GenBuildings(this.connections);
	this.place = new PVector(x,y);
	this.pos = new PVector(x*10*board_Scale+(100/board_Scale), y*10*board_Scale+(100/board_Scale));
	this.cars = [];
	this.intersection = round(random(0,1)); // Can be "STOP" for a 4 way stop or "LIGHT" for a stop light. If there are only two roads there will be no intersection and the cars will just drive normally
	if(this.intersection===0){this.intersection="STOP";}else{this.intersection="LIGHT";}
	this.intTimeVert = round(random(5,10)); // time(in seconds) between the changing of the stop light from vertical to horizontal
	this.intTimeHori = round(random(5,10)); // time(in seconds) between the changing of the stop light from horizontal to vertical
	this.Dir = 0; // 0 is horizontal, 1 is vertical for lights to be on
	this.timer = 0;
	this.roadnum = 0;
	for(var i = 0; i < this.connections.length; i++){
		if(this.connections[i] === 1){
			this.roadnum++;
		}
	}
	this.trafficValue = 0;
	this.trafficValueHistory = [];
	for(var i=0;i<FR*10;i++){this.trafficValueHistory.push(10);}
}

function AdjCon(x,y){
	var output = [0,0,0,0];

	if(x+1 < Size[0]){
		output[0] = board[x+1][y].connections[2];
	}
	if(y+1 < Size[1]){
		output[1] = board[x][y+1].connections[3];
	}
	if(x-1 > 0){
		output[2] = board[x-1][y].connections[0];
	}
	if(y-1 > 0){
		output[3] = board[x][y-1].connections[1];
	}

	return output;
}

piece.prototype.Connect = function(){
	var adj = AdjCon(this.place.x,this.place.y);
	for(var i = 0; i < adj.length; i++){;
		if(adj[i] === 1 && this.connections[i] !== 1){
			this.connections[i] = 1;
		}
	}
};

piece.prototype.IntTick = function(){
	if(this.intersection === "LIGHT"){
		this.timer++;
		if((this.timer >= round(this.intTimeVert*FR) && this.Dir === 1) || (this.timer >= round(this.intTimeHori*FR) && this.Dir === 0)){
			if(this.Dir===0){this.Dir=1;}else{this.Dir=0;}
			this.timer=0;
		}
	}
};

piece.prototype.Spread = function(){
	if(ArraysEqual(this.connections, [0,0,0,0]) === false){
		var probability = 1.2-(Dist(this.place.x,this.place.y,origin[0],origin[1])/50);

		//extend if road is running toward something
		if(ArraysEqual(board[this.place.x+1][this.place.y].connections, [0,0,0,0]) && this.connections[0] === 1 && this.place.x < Size[0]-2){
			board[this.place.x+1][this.place.y].connections = [round(random(0,probability)), round(random(0,probability)), 1, round(random(0,probability))];
			board[this.place.x+1][this.place.y].buildings = GenBuildings(board[this.place.x+1][this.place.y].connections);
		}
		if(ArraysEqual(board[this.place.x-1][this.place.y].connections, [0,0,0,0]) && this.connections[2] === 1 && this.place.x > 2){
			board[this.place.x-1][this.place.y].connections = [1, round(random(0,probability)), round(random(0,probability)), round(random(0,probability))];
			board[this.place.x-1][this.place.y].buildings = GenBuildings(board[this.place.x-1][this.place.y].connections);
		}
		if(ArraysEqual(board[this.place.x][this.place.y+1].connections, [0,0,0,0]) && this.connections[1] === 1 && this.place.y < Size[1]-2){
			board[this.place.x][this.place.y+1].connections = [round(random(0,probability)), round(random(0,probability)), round(random(0,probability)), 1];
			board[this.place.x][this.place.y+1].buildings = GenBuildings(board[this.place.x][this.place.y+1].connections);
		}
		if(ArraysEqual(board[this.place.x][this.place.y-1].connections, [0,0,0,0]) && this.connections[3] === 1 && this.place.y > 2){
			board[this.place.x][this.place.y-1].connections = [round(random(0,probability)), 1, round(random(0,probability)), round(random(0,probability))];
			board[this.place.x][this.place.y-1].buildings = GenBuildings(board[this.place.x][this.place.y-1].connections);
		}

		//extend and add road
		if(round(random(0.2,1)) === 1){
			if(ArraysEqual(board[this.place.x+1][this.place.y].connections, [0,0,0,0]) && this.place.x < Size[0]-2 && round(random(0,1)) === 1){
				board[this.place.x+1][this.place.y].connections = [round(random(0,probability)), round(random(0,probability)), 1, round(random(0,probability))];
				board[this.place.x+1][this.place.y].buildings = GenBuildings(board[this.place.x+1][this.place.y].connections);
				this.connections[0] = 1;
			}
			if(ArraysEqual(board[this.place.x-1][this.place.y].connections, [0,0,0,0]) && this.place.x > 2 && round(random(0,1)) === 1){
				board[this.place.x-1][this.place.y].connections = [1, round(random(0,probability)), round(random(0,probability)), round(random(0,probability))];
				board[this.place.x-1][this.place.y].buildings = GenBuildings(board[this.place.x-1][this.place.y].connections);
				this.connections[2] = 1;
			}
			if(ArraysEqual(board[this.place.x][this.place.y+1].connections, [0,0,0,0]) && this.place.y < Size[1]-2 && round(random(0,1)) === 1){
				board[this.place.x][this.place.y+1].connections = [round(random(0,probability)), round(random(0,probability)), round(random(0,probability)), 1];
				board[this.place.x][this.place.y+1].buildings = GenBuildings(board[this.place.x][this.place.y+1].connections);
				this.connections[1] = 1;
			}
			if(ArraysEqual(board[this.place.x][this.place.y-1].connections, [0,0,0,0]) && this.place.y > 2 && round(random(0,1)) === 1){
				board[this.place.x][this.place.y-1].connections = [round(random(0,probability)), 1, round(random(0,probability)), round(random(0,probability))];
				board[this.place.x][this.place.y-1].buildings = GenBuildings(board[this.place.x][this.place.y-1].connections);
				this.connections[3] = 1;
			}
		}

		for(var x = this.place.x-3; x < this.place.x+3; x++){
			for(var y = this.place.y-3; y < this.place.y+3; y++){
				//println(x + ", " + y);
				board[x][y].Connect();
			}
		}
	}
};

function octagon(x,y,Scale) {
	pushMatrix();
	translate(x,y);
	scale(Scale);
	rectMode(CENTER);
	rect(0,0,4.14,10);
	rect(0,0,10,4.14);
	rotate(HALF_PI/2);
	rect(0,0,4.14,10);
	rect(0,0,10,4.14);
	popMatrix();
}

piece.prototype.Draw = function() {
	//reset position
	this.pos = new PVector(this.place.x*10*board_Scale+(100/board_Scale), this.place.y*10*board_Scale+(100/board_Scale));
	this.trafficValueHistory.splice(0,1);
	var temp = 0;
	for(var i = 0; i < this.cars.length; i++){
		temp+=cars[this.cars[i]].speed;
	}
	if(this.cars.length === 0){
		this.trafficValueHistory.push(10);
	}else{
		this.trafficValueHistory.push(temp/this.cars.length);
	}
	this.trafficValue=0;
	for(var i=0;i<this.trafficValueHistory.length;i++){
		this.trafficValue += this.trafficValueHistory[i];
	}
	this.trafficValue = this.trafficValue/this.trafficValueHistory.length;

	if(this.pos.x+offset[0] > -(50*(board_Scale/10)) && this.pos.x+offset[0] < width+(50*(board_Scale/10)) && this.pos.y+offset[1] > -(50*(board_Scale/10)) && this.pos.y+offset[1] < height+(50*(board_Scale/10))){
		var clickRad = 10;
		if(mousePressed && mouseX >= this.pos.x+offset[0]-clickRad*board_Scale/10 && mouseX <= this.pos.x+offset[0]+clickRad*board_Scale/10 && mouseY >= this.pos.y+offset[1]-clickRad*board_Scale/10 && mouseY <= this.pos.y+offset[1]+clickRad*board_Scale/10 && this.roadnum > 2){
			//if the center of the tile is clicked
			if(edditing === null || edditing !== null && mouseX < width*7/8){
				edditing = this.place;
			}
		}

		//translate and scale properly. Can draw between (-50,-50) and (50,50)

		pushMatrix();
		translate(this.pos.x, this.pos.y);
		scale(board_Scale/10);

		noStroke();
		fill(50,255,50);
		rect(0, 0, 100, 100);

		//if(this.place.x === origin[0] && this.place.y === origin[1]){
		//	fill(255,0,0);
		//	rect(0,0,40,40);
		//}

		//stroke(255,0,0);
		//line(0,-50,0,50);
		//line(-50,0,50,0);
		//noStroke();

		if(this.roadnum <= 2){
			this.roadnum = 0;
		}
		for(var i = 0; i < this.connections.length; i++){
			if(this.connections[i] === 1){
				fill(150);
				rect(21.5,0,57,14);
				fill(255,255,0);
				rect(12, 0, 10, 2);
				rect(37, 0, 10, 2);

				if(this.buildings[i][0] === 1){
					fill(this.buildings[i][1]);
					rect(32,-32,30,30);
				}
				
				if(this.roadnum > 2){
					if(this.intersection === "STOP"){
						fill(255,0,0);
						octagon(14, -10, 0.5);
						if(board_Scale > 20){
							rotate(-HALF_PI);
							textSize(1.5);
							fill(255);
							text("STOP",8,14.5);
							rotate(HALF_PI);
						}else{
							fill(255);
							rect(13.75,-10,1,3);
						}
					}

					if(this.intersection === "LIGHT"){
						if(this.Dir === i%2){
							fill(0, 128, 0);
						}else{
							fill(255, 0, 0);
						}
						rect(14,-10,4,4);
					}
				}else{
					this.roadnum++;
				}
			}
			rotate(HALF_PI);
		}

		if(trafficOverlay == true){
			if(this.cars.length !== 0){
				fill(255,0,0,constrain(100/this.trafficValue,0,200));
				rect(0,0,101,101);
			}
		}

		popMatrix();
		//fill(255,0,0);
		//rect(this.pos.x, this.pos.y, 14*board_Scale/10, 14*board_Scale/10);
	}
};

function FindCIF(that) { // CIF = Car in front
	var valid = board[that.tile.x][that.tile.y].cars;
	var nvalid = [];
	
	for(var i = 0; i < valid.length; i++){ // find all cars in the same tile that have the same rotation
		var a = cars[valid[i]];
		if(round(that.rotation) === round(a.rotation) && that.num !== cars[valid[i]].num){//(that.pos.x*cos(that.rotation) >= a.pos.x+abs(cos(a.rotation)+1)*4 && that.pos.x*cos(that.rotation) <= a.pos.x-abs(cos(a.rotation)+1)*4 && (that.rotation+180)%360 !== a.rotation) || (that.pos.y*sin(that.rotation) <= a.pos.y+abs(sin(a.rotation)+1)*4 && that.pos.y*sin(that.rotation) >= a.pos.y-abs(sin(a.rotation)+1)*4 && (that.rotation+180)%360 !== a.rotation) || 
			nvalid.push(valid[i]);
		}
	}
	valid = nvalid; nvalid = [];

	var CIF = [-1, 1000]; // car number then dist of car
	if(that.rotation === 0 || that.rotation === 180){
		var temp = round(cos(that.rotation/90*HALF_PI));
		for(var i = 0; i < valid.length; i++){
			var a = cars[valid[i]];
			var dist = (a.pos.x - that.pos.x)*temp;
			if(dist > 0 && dist < CIF[1]){
				CIF[0] = a.num;
				CIF[1] = dist;
			}
		}
		
		if(CIF[0] === -1){
			var valid = board[that.tile.x+temp][that.tile.y].cars;
			var nvalid = [];
			for(var i = 0; i < valid.length; i++){ // find all cars in the same tile that have the same rotation
				if(that.rotation === cars[valid[i]].rotation && that.num !== cars[valid[i]].num){
					nvalid.push(valid[i]);
				}
			}
			valid = nvalid; nvalid = [];

			for(var i = 0; i < valid.length; i++){
				var a = cars[valid[i]];
				var dist = (50-that.pos.x)+(50+a.pos.x*temp);
				if(dist < CIF[1]){
					CIF[0] = valid[i];
					CIF[1] = dist;
				}
			}
		}
	}else{
		var temp = round(sin(that.rotation/90*HALF_PI));
		for(var i = 0; i < valid.length; i++){
			var a = cars[valid[i]];
			var dist = (a.pos.y - that.pos.y)*temp;
			if(dist > 0 && dist < CIF[1]){
				CIF[0] = a.num;
				CIF[1] = dist;
			}
		}

		if(CIF[0] === -1){
			var valid = board[that.tile.x][that.tile.y+temp].cars;
			var nvalid = [];
			for(var i = 0; i < valid.length; i++){ // find all cars in the same tile that have the same rotation
				if(that.rotation === cars[valid[i]].rotation && that.num !== cars[valid[i]].num){
					nvalid.push(valid[i]);
				}
			}
			valid = nvalid; nvalid = [];

			for(var i = 0; i < valid.length; i++){
				var a = cars[valid[i]];
				var dist = (50-that.pos.y)+(50+a.pos.y*temp);
				if(dist < CIF[1]){
					CIF[0] = valid[i];
					CIF[1] = dist;
				}
			}
		}
	}

	return CIF;
}

function TurnPos(that) {
	if(that.road === (that.newRoad+1)%4){
		return [round(cos(that.rotation/180*PI)*4), round(sin(that.rotation/180*PI)*4)];
		println("left");
	}else if(that.road === (that.newRoad+3)%4){
		return [round(-cos(that.rotation/180*PI)*4), round(-sin(that.rotation/180*PI)*4)];
		println("right");
	}else{
		return [0,0];
		println("straight/turnaround");
	}
}

/*function FindCIF(that) {
	var CIF = -1;
	var temp = 1000;
	var valid = board[that.tile.x][that.tile.y].cars;
	var Turn = TurnPos(that);
	var nvalid = [];

	for(var i = 0; i < valid.length; i++){
		var a = cars[valid[i]];
		if(round(that.rotation) === round(a.rotation) && that.num !== cars[valid[i]].num && (a.pos.x+a.pos.y)*(quickSin[that.rotation/90]+quickCos[a.rotation/90]) > (Turn[0]+Turn[1])){
			nvalid.push(valid[i]);
		}
	}
	valid = nvalid;

	for(var i = 0; i < valid.length; i++){
		var dist = -((cars[valid[i]].pos.x+cars[valid[i]].pos.y)-(that.pos.x+that.pos.y));
		//println(that.num + ", " + dist);
		if(temp < dist && dist > 0){
			temp = dist;
			CIF = valid[i];
		}
	}

	return [CIF,temp];
}*/

function Car(x, y, road){
	this.tile = new PVector(x,y);
	this.pos = new PVector(0, 0);
	this.pos.x += round(random(0,50))*cos(road/2*PI);
	this.pos.y += round(random(0,50))*sin(road/2*PI);
	if(useImages === true){
		var ImageNum = round(random(0,carImages.length-1));
		this.Image = carImages[ImageNum];
		if(ImageNum === 0){
			this.Color = [255, 107, 2];
		}else if(ImageNum === 1){
			this.Color = [153, 1, 255];
		}else if(ImageNum === 2){
			this.Color = [25, 168, 0];
		}else if(ImageNum === 3){
			this.Color = [86, 86, 86];
		}
	}else{
		this.Color = [random(0,255), random(0,255), random(0,255)];
	}
	this.rotation = 90*road; //rotation in degrees
	this.road = road;
	this.newRoad = road;
	this.num = cars.length;
	board[this.tile.x][this.tile.y].cars.push(this.num);
	this.speed = 10; // max of 10 which is 1 pixel per tick
	this.maxSpeed = round(random(5,10)); // the maximum speed of the car
	this.timer = 0;
	this.turned = false;
	this.stopTime = round(random(0.1,1)*10)/10;
	this.stopTimer = 0;
	this.CIF = -1;
	this.turnpos = TurnPos(this);
}

Car.prototype.Draw = function(){
	this.absPos = new PVector(this.tile.x*10*board_Scale+(100/board_Scale) + (this.pos.x*board_Scale/10) + offset[0], this.tile.y*10*board_Scale+(100/board_Scale) + (this.pos.y*board_Scale/10) + offset[1]);
	this.timer--;

	if(this.absPos.x > -(8*(board_Scale/10)) && this.absPos.x < width+(8*(board_Scale/10)) && this.absPos.y > -(8*(board_Scale/10)) && this.absPos.y < height+(8*(board_Scale/10))){
		//var box = [new PVector(this.absPos.x-abs(constrain(cos(this.rotation/90*HALF_PI)*2,1,2)*2), this.absPos.y-abs(constrain(sin(this.rotation/90*HALF_PI)*2,1,2)*2)), new PVector(this.absPos.x+abs(constrain(cos(this.rotation/90*HALF_PI)*2,1,2)*2), this.absPos.y+abs(constrain(sin(this.rotation/90*HALF_PI)*2,1,2)*2))]; // top left cord then top right cord
		//if(this.num === 157){
			//fill(255,0,0);
			//textSize(12);
			//text("-------------\nInformation for car #" + this.num + "\npos: " + this.pos + "\nroad: " + this.road + ", " + this.newRoad + "\nspeed: " + this.speed + "\ntile: " + this.tile + "\nrotation: " + this.rotation, 0, 0);
		//}

		//fill(255,0,0);
		//rect(box[0].x, box[0].y, box[1].x, box[1].y);

		//if(this.num === 1){
			//println(abs(constrain(cos(this.rotation/90*HALF_PI)*2,1,2)*2));
		//}

		pushMatrix();
		translate(this.absPos.x-offset[0], this.absPos.y-offset[1]);
		//if(this.num === 157){
		//	fill(255,0,0);
		//	textSize(12);
		//	text("Information for car #" + this.num + "\npos: " + this.pos + "\nroad: " + this.road + ", " + this.newRoad + "\nspeed: " + this.speed + "\ntile: " + this.tile + "\nrotation: " + this.rotation + "\nnew Y: " + round((this.pos.y+sin(this.rotation/180*PI)*constrain(this.speed,0,this.maxSpeed)/10)*10)/10, 0, 0);
		//}

		//fill(255,0,0);
		//text(this.road + ", " + this.newRoad + ", " + (this.road === (this.newRoad+1)%4), 0, 0);

		rotate(this.rotation/180*PI);
		scale(board_Scale/10);
		//stroke(0,0,0);
		//line(2,3.5, 8,3.5)

		//noStroke();
		if(useImages === false || board_Scale/10 < 3){
			fill(this.Color[0], this.Color[1], this.Color[2]);
			rect(0,3.5,8,4);
		}else{
			image(this.Image, -4, 1.5, 8, 4);
		}

		rotate(-this.rotation/180*PI);

		//fill(255,0,0);
		//textSize(2);
		//text(this.num + ", " + this.CIF[0], -3.5*sin(this.rotation/180*PI), 3.5*cos(this.rotation/180*PI));
		
		popMatrix();
	}
};

function PickDir(x,y,road){
	var tile = board[x][y];
	var posibilies = tile.connections;
	var newP = [];
	for(var i = 0; i < posibilies.length; i++){
		if(posibilies[i] === 1 && (i+2)%4 !== road){
			newP.push(i);
		}
	}
	posibilies = newP;

	if(posibilies.length === 0){
		posibilies = [(road+2)%4];
	}

	out = posibilies[round(random(-0.5,posibilies.length-0.50001))];
	return out;
}

function RemoveInstances(value, array){
	var newArray = [];
	for(var i = 0; i < array.length; i++){
		if(array[i] !== value){
			newArray.push(array[i]);
		}
	}
	return newArray;
}

Car.prototype.Drive = function(){
	this.pos.x = round((this.pos.x+cos(this.rotation/180*PI)*constrain(this.speed,0,this.maxSpeed)/10)*10)/10;
	this.pos.y = round((this.pos.y+sin(this.rotation/180*PI)*constrain(this.speed,0,this.maxSpeed)/10)*10)/10;

	//fill(255,0,0);
	//rect(this.tile.x*10*board_Scale+(100/board_Scale), this.tile.y*10*board_Scale+(100/board_Scale),10,10);

	if(this.pos.x < -50){
		this.pos.x = 50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.x -= 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
		this.turnpos = TurnPos(this);
	}else if(this.pos.x > 50){
		this.pos.x = -50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.x += 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
		this.turnpos = TurnPos(this);
	}

	if(this.pos.y < -50){
		this.pos.y = 50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.y -= 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
		this.turnpos = TurnPos(this);
	}else if(this.pos.y > 50){
		this.pos.y = -50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.y += 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
		this.turnpos = TurnPos(this);
	}

	if(round(this.pos.x) === this.turnpos[0] && round(this.pos.y) === this.turnpos[1] && this.turned === false){
		//println(this.road + ", " + this.newRoad);
		this.turned = true;
		this.road = this.newRoad;
		this.rotation = 90*this.road;
		this.pos.x = this.turnpos[1];
		this.pos.y = -this.turnpos[0];
		this.stopTimer = 0;
	}
};

function FindInt(that) {
	var output = [0,0,0]; //[dist, type(null if there are only 2 roads), dir of the light if there is a light]
	output[0] = round(that.pos.x*-cos(that.rotation/90*HALF_PI) + that.pos.y*-sin(that.rotation/90*HALF_PI) - 14);
	var tile = board[that.tile.x][that.tile.y];
	if(tile.roadnum > 2){
		output[1] = tile.intersection;
	}else{
		output[1] = null;
	}
	if(tile.intersection === "LIGHT"){
		output[2] = tile.Dir;
	}
	return output;
}

Car.prototype.FindSpeed = function() {
	this.CIF = FindCIF(this); //stores the value of the car ahead of the current car 
	this.CIFdist = this.CIF[1];
	this.CIF = cars[this.CIF[0]];

	//println(this.CIF + ", " + this.CIFdist);

	if(this.CIFdist === -1){
		this.speed = constrain(this.speed+0.5,0,10);
	}else if(this.CIFdist < 5){
		this.speed = 0;
	}else if(this.CIFdist < 13){
		this.speed = constrain(constrain(this.CIF.speed,0,this.CIF.maxSpeed)-1,0,10);
	}else if(this.CIFdist < 15){
		this.speed = constrain(this.CIF.speed,0,this.CIF.maxSpeed);
	}else if(this.CIFdist < 50){
		this.speed = constrain(constrain(this.CIF.speed,0,this.CIF.maxSpeed)+ceil(this.CIFdist/5)/2,0,10);
	}else{
		this.speed = 10;
	}
	
	this.Int = FindInt(this);

	if(this.Int[1] !== null){
		if(this.Int[1] === "LIGHT"){
			if((this.Int[2] !== this.road%2 || this.road%2 !== (this.rotation/90)%2) && this.Int[0] >= 0 && this.Int[0] <= 2){
				this.speed = 0;
			}
		}else{
			if(this.Int[0] >= 0 && this.Int[0] <= 2 && this.stopTimer < this.stopTime*FR){
				this.stopTimer++;
				this.speed = 0;
			}
		}
	}

	averageSpeed += constrain(this.speed,0,this.maxSpeed)/this.maxSpeed*10;
};

function CreateCar(){
	var selection = spots[round(random(0,spots.length-1))];
	var tile = board[selection[0]][selection[1]];
	var valid = [];

	for(var a = 0; a < tile.connections.length; a++){
		if(tile.connections[a] === 1){
			valid.push(a);
		}
	}

	cars.push(new Car(selection[0],selection[1],valid[round(random(0,valid.length-1))]));
	//println(selection);
}

//cars.push(new Car(21,11,0));
//cars.push(new Car(22,11,0));

var timer = 1;
var dawn = true;

function regenCity(size, attempts, numCars, min, max) {
	Size = size;
	board = [];
	//board_Scale = 4;
	//offset = [0,0];
	intersections = 0;
	time = 12;
	cars = [];

	for(var x = 0; x < Size[0]; x++){
		board.push([]);
		for(var y = 0; y < Size[1]; y++){
			board[x].push([0,0,0,0]);
		}
	}
	origin = [floor(Size[0]/2), floor(Size[1]/2)];

	var seed = [0,0,0,0];

	var valid = [0,1,2,3];
	for(var i = 0; i < round(random(2,4)); i++){
		var choice = valid[round(random(0,valid.length))];
		seed[choice] = 1;
		valid.splice(choice, 1);
	}

	board[origin[0]][origin[1]] = seed;

	GenAdj(origin[0],origin[1],0,10);

	for(var x = 0; x < board.length; x++){
		for(var y = 0; y < board[x].length; y++){
 			Connect(x, y);
		}
	}

	for(var x = 0; x < board.length; x++){
		for(var y = 0; y < board[x].length; y++){
			board[x][y] = new piece(x,y,board[x][y]);
		}
	}

	spots = [];
	for(var x = 0; x < board.length; x++){
		for(var y = 0; y < board[x].length; y++){
			if(ArraysEqual(board[x][y].connections, [0,0,0,0]) === false){
				spots.push([x,y]);
			}
		}
	}

	for(var i = 0; i < 1000; i++){
		CreateCar();
	}

	//cars.push(new Car(12,12,0));
	//cars.push(new Car(12,12,0));

	var intersections = 0;
	for(var x = 0; x < board.length; x++){
		for(var y = 0; y < board[x].length; y++){
 			if(ArraysEqual(board[x][y].connections, [0,0,0,0]) === false){
				intersections++;
			}
		}
	}

	if(intersections < min && min !== null){
		regenCity(size, attempts, numCars, min, max);
	}else if(intersections > max && max !== null){
		regenCity(size, attempts, numCars, min, max);
	}
}

frameRate(FR);
frameRate(60);

var LightSliderVertical = new slider(100*57/64*16.5,140,100*3/32*16.5,20,2,10,2);
var LightSliderHorizontal = new slider(100*57/64*16.5,200,100*3/32*16.5,20,2,10,2);

function Tab() {
	pushMatrix();

	var TabWidth = width/8;
	var stop = board[edditing.x][edditing.y];

	translate(width-TabWidth,0);
	fill(100,100,100,200);
	rectMode(CORNER);
	rect(0,-1,TabWidth,height);

	//draw stop light button
	if(stop.intersection === "LIGHT"){fill(75);}else{fill(150);}
	rect(20,30,80,40);

	fill(0,0,0);
	rect(50,35,20,30);
	fill(255,0,0);
	ellipse(60,43,10,10);
	fill(0,255,0);
	ellipse(60,57,10,10);

	//draw stop sign button
	if(stop.intersection === "STOP"){fill(75);}else{fill(150);}
	rect(110,30,80,40);

	fill(255,0,0);
	octagon(150,50,3.5);
	fill(255,255,255);
	text("STOP", 134, 55);

	if(mousePressed && mouseX >= width-TabWidth+20 && mouseX <= width-TabWidth+100 && mouseY >= 30 && mouseY <= 80 && mousePressed !== pmousePressed){stop.intersection = "LIGHT";}
	if(mousePressed && mouseX >= width-TabWidth+110 && mouseX <= width-TabWidth+190 && mouseY >= 30 && mouseY <= 80 && mousePressed !== pmousePressed){stop.intersection = "STOP";}

	if(stop.intersection === "LIGHT"){
		//draw text for sliders
		fill(0,0,0,255);

		textSize(18);
		text("light wait times", width*7/256, 95);

		textSize(12);
		text("Vertical time = " + LightSliderVertical.value + "s", width/128, 135);
		text("Horizontal time = " + LightSliderHorizontal.value + "s", width/128, 185);
	}

	popMatrix();

	if(stop.intersection === "LIGHT"){
		LightSliderHorizontal.value = stop.intTimeHori;
		LightSliderVertical.value = stop.intTimeVert;
		LightSliderHorizontal.draw();
		LightSliderVertical.draw();
		stop.intTimeHori = LightSliderHorizontal.value;
		stop.intTimeVert = LightSliderVertical.value;
	}
}

//buttons for menus
var playbutton = new button(50,100,300,100,"Play",75,[50,50,255],5);
var instructionsbutton = new button(50,250,300,100,"Instructions",55,[50,50,255],5);
var startbutton = new button(50,800,300,100,"Start",75,[50,50,255],5);
var backbutton = new button(675,750,300,100,"Back",75, [50,50,255],5);

var pausebutton = new button(1630,0,20,20,"",30,[50,50,255],5);

//sliders for menus
var mincitysizeslider = new slider(50,140,300,20,0.1,0.5,0.3);
var maxcitysizeslider = new slider(50,200,300,20,0.1,0.5,0.3);
var GridSpaceSlider = new slider(50,260,300,20,1,5,1.5);
var latched = [mincitysizeslider.value, maxcitysizeslider.value, GridSpaceSlider.value];

var newCitySize = [0,0];
var GridSpace = 1;
var GridSpaceAspectRatio = [11*2,6.3*2];

regenCity(Size, 30, 500, 25, null);

void draw(){
	if(screen === "MainGame"){
		centerPos = new PVector((offset[0]-width/2)/board_Scale*10, (offset[1]-height/2)/board_Scale*10);
		//centerPos.x = centerPos.x*(100/board_Scale); centerPos.y = centerPos.y*(100/board_Scale);

		//offset = [0,0];
		background(50,255,50);
		//background(0);

		//println(mouseX);

		time+=0.01;
		if(round(time*100)/100 >= 24){
			time = 0;
		}
		if(round(time%1*100) >= 60){
			time = round(floor(time)+1);
		}

		//println(frameRate);

		pushMatrix();
		translate(offset[0], offset[1]);
		rectMode(CENTER);
		//println(board_Scale);
		//println(offset);
		//println(board_Scale);

		//(x-(100/board_Scale))/board_Scale/10 = tx, (y-(100/board_Scale))/board_Scale/10 = ty
		//var mouseTile = board[constrain(round(((mouseX-offset[0])-(100/board_Scale))/board_Scale/10),0,Size[0])][constrain(round(((mouseY-offset[1])-(100/board_Scale))/board_Scale/10),0,Size[1])];

		//println(round(mouseTile.intTime));

		//println(board[mouseTile[0]][mouseTile[1]].trafficValue);

		if(edditing === null && mousePressed){ //  || (edditing !== null && mouseX < width*7/8 && mousePressed && mousePressed !== pmousePressed)
			offset[0] += mouseX-pmouseX;
			offset[1] += mouseY-pmouseY;
		}

		if(timer%round((-0.001595*(Size[0]*Size[1])+11.00))*2 === 0){
			board[constrain(round(random(3,Size[0]-3)),3,Size[0]-3)][constrain(round(random(3,Size[1]-3)),3,Size[1]-3)].Spread();

			intersections = 0;
			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					if(board[x][y].roadnum > 2){
						intersections++;
					}
				}
			}
			//var tile = board[round(random(2,Size[0]-2))][round(random(2,Size[1]-2))];
			//var buildings = ArrayOr(tile.buildings,GenBuildings(tile.connections));
			//if(round(random(0,1)) === 1){
			//	println(tile.buildings + "     :     " + buildings);
			//	tile.buildings = buildings;
			//}
		}

		//println(board_Scale/10);

		//if(timer%20 === 0){
		//	println(frameRate);
		//}

		if(timer%20 === 0 && round(random(0,1)) === 1){
			CreateCar();
		}
		
		if(timer%1000 === 0){
			spots = [];
			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					if(ArraysEqual(board[x][y].connections, [0,0,0,0]) === false){
						spots.push([x,y]);
					}
				}
			}
		}

		if(mousePressed && mousePressed !== pmousePressed && mouseX < width*7/8){
			edditing = null;
		}

		for(var x = 0; x < board.length; x++){
			for(var y = 0; y < board[x].length; y++){
				board[x][y].Draw();
				board[x][y].IntTick();
			}
		}

		averageSpeed = 0;
		for(var i = 0; i < cars.length; i++){
			cars[i].FindSpeed();
		}
		averageSpeed = averageSpeed/cars.length;
		//println(averageSpeed/cars.length);

		noStroke();
		for(var i = 0; i < cars.length; i++){
			cars[i].Draw();
			cars[i].Drive();
		}

		popMatrix();

		rectMode(CENTER);
		fill(0, 0, 0, (cos(time/3.8)+1)*70);
		rect(width/2,height/2,width,height);

		if(edditing !== null){
			Tab();
		}

		timer++;

		fill(255,0,0);
		textSize(20);
		text(round(frameRate*100)/100, width-70, 20);

		fill(255,255,255);
		if(round(time%1*100) < 10){
			text(floor(time) + ":0" + round(time%1*100), 0, 20);
		}else{
			text(floor(time) + ":" + round(time%1*100), 0, 20);
		}
		text("Current Score " + round(averageSpeed*100), 0, 40); // Print Score
		if(round(averageSpeed*100) > bestScore){bestScore = round(averageSpeed*100);}
		text("Your Best is " + bestScore, 0, 60);

		//Pause button
		fill(220,220,255);
		pausebutton.draw();

		fill(0);
		rect(1635,3,3,13);
		rect(1641,3,3,13);

		if(pausebutton.detectClick(true) === true){
			pscreen = screen;
			screen = "pause";
		}

		//text(offset, 0, 100);
		//text(board_Scale, 0, 80);
		//text(centerPos, 0, 120);

		/*if(dawn === false){
			if(round((12.6-time)%1*100) < 10){
				text((floor(12.6-time) + ":0" + round((12.6-time)%1*100)), 0, 20);
			}else{
				text((floor(12.6-time) + ":" + round((12.6-time)%1*100)), 0, 20);
			}
		}else{
			if(round((time)%1*100) < 10){
				text((floor(time) + ":0" + round((time)%1*100)), 0, 20);
			}else{
				text((floor(time) + ":" + round((time)%1*100)), 0, 20);
			}
		}*/

		//println(width);
		//println();
		//text(board[mouseTile[0]][mouseTile[1]].cars,mouseX,mouseY);

		/*if(keyPressed && key === 's'){
			frameRate(10);
		}else if(keyPressed !== pkeyPressed && pkey === 's'){
			frameRate(60);
		}*/

		if(keyPressed && key === 'c'){
			offset = [0,0];
			board_Scale = round(100/(Size[0])*2*1.65)/2;
		}

		if(keyPressed && key === 'o' && keyPressed !== pkeyPressed){
			trafficOverlay = !trafficOverlay;
		}

		//if(keyPressed && keyPressed !== pkeyPressed && key === 'r'){
		//	regenCity(Size, 400, 1000, 20, null);
		//}

		var zoomOffsetChange = new PVector((board_Scale*centerPos.x+5*width)/10,(board_Scale*centerPos.y+5*height)/10);

		if(keyPressed && key === '='){
			board_Scale += 0.5;
			offset[0] = (board_Scale*centerPos.x+5*width)/10;
			offset[1] = (board_Scale*centerPos.y+5*height)/10;
		}else if(keyPressed && key === '-' && board_Scale > 2){
			board_Scale -= 0.5;
			offset[0] = (board_Scale*centerPos.x+(5*width))/10;
			offset[1] = (board_Scale*centerPos.y+(5*height))/10;
		}

		//stroke(0);
		//line(width/2, -1, width/2, height+1);
		//line(-1, height/2, width+1, height/2);
	}else if(screen === "MainMenu"){
		background(50,255,50);
		if(true===true){
			pushMatrix();
			translate(offset[0], offset[1]);
			rectMode(CENTER);
			time+=0.01;
			if(round(time*100)/100 >= 24){
				time = 0;
			}
			if(round(time%1*100) >= 60){
				time = round(floor(time)+1);
			}
			
			if(timer%20 === 0){
				board[constrain(round(random(3,Size[0]-3)),3,Size[0]-3)][constrain(round(random(3,Size[1]-3)),3,Size[1]-3)].Spread();
			}

			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					board[x][y].Draw();
					board[x][y].IntTick();
				}
			}

			for(var i = 0; i < cars.length; i++){
				cars[i].FindSpeed();
			}

			noStroke();
			for(var i = 0; i < cars.length; i++){
				cars[i].Draw();
				cars[i].Drive();
			}

			popMatrix();

			rectMode(CENTER);
			fill(0, 0, 0, (cos(time/3.8)+1)*70);
			rect(width/2,height/2,width,height);

			textSize(20);
			fill(255,255,255);
			if(round(time%1*100) < 10){
				text(floor(time) + ":0" + round(time%1*100), 0, 20);
			}else{
				text(floor(time) + ":" + round(time%1*100), 0, 20);
			}
		} // draw background game

		rectMode(CENTER);
		fill(150, 150, 150, 150);
		rect(200, height/2, 400, height);

		fill(50,50,255);
		textSize(50);
		text("City Simulator",25,60);

		fill(220,220,255);
		playbutton.draw();
		if(playbutton.detectClick(true)){
			pscreen=screen;
			screen = "GameSetup";
		}

		fill(220,220,255);
		instructionsbutton.draw();
		if(instructionsbutton.detectClick(true)){
			pscreen=screen;
			screen = "Instructions";
		}
	}else if(screen === "GameSetup"){
		background(50,255,50);
		if(true===true){
			pushMatrix();
			translate(offset[0], offset[1]);
			rectMode(CENTER);
			time+=0.01;
			if(round(time*100)/100 >= 24){
				time = 0;
			}
			if(round(time%1*100) >= 60){
				time = round(floor(time)+1);
			}
			
			if(timer%20 === 0){
				board[constrain(round(random(3,Size[0]-3)),3,Size[0]-3)][constrain(round(random(3,Size[1]-3)),3,Size[1]-3)].Spread();
			}

			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					board[x][y].Draw();
					board[x][y].IntTick();
				}
			}

			for(var i = 0; i < cars.length; i++){
				cars[i].FindSpeed();
			}

			noStroke();
			for(var i = 0; i < cars.length; i++){
				cars[i].Draw();
				cars[i].Drive();
			}

			popMatrix();

			rectMode(CENTER);
			fill(0, 0, 0, (cos(time/3.8)+1)*70);
			rect(width/2,height/2,width,height);

			textSize(20);
			fill(255,255,255);
			if(round(time%1*100) < 10){
				text(floor(time) + ":0" + round(time%1*100), 0, 20);
			}else{
				text(floor(time) + ":" + round(time%1*100), 0, 20);
			}
		} // draw background game

		rectMode(CENTER);
		fill(150, 150, 150, 150);
		rect(200, height/2, 400, height);

		fill(50,50,255);
		textSize(50);
		textMode(CENTER);
		text("Setup",110,60);

		fill(220,220,255);
		startbutton.draw();
		if(startbutton.detectClick(true)){
			pscreen=screen;
			screen = "MainGame";
		}

		mincitysizeslider.draw();
		if(mincitysizeslider.value > maxcitysizeslider.value){mincitysizeslider.value=maxcitysizeslider.value;}
		maxcitysizeslider.draw();
		if(maxcitysizeslider.value < mincitysizeslider.value){maxcitysizeslider.value=mincitysizeslider.value;}

		GridSpaceSlider.draw();

		var textAffix = ["","",""];

		//text to affix to min city slider
		if(mincitysizeslider.value === 0.1){textAffix[0]="Very Small";}
		if(mincitysizeslider.value === 0.2){textAffix[0]="Small";}
		if(mincitysizeslider.value === 0.3){textAffix[0]="Medium";}
		if(mincitysizeslider.value === 0.4){textAffix[0]="Large";}
		if(mincitysizeslider.value === 0.5){textAffix[0]="Very Large";}

		//text to affix to max city slider
		if(maxcitysizeslider.value === 0.1){textAffix[1]="Very Small";}
		if(maxcitysizeslider.value === 0.2){textAffix[1]="Small";}
		if(maxcitysizeslider.value === 0.3){textAffix[1]="Medium";}
		if(maxcitysizeslider.value === 0.4){textAffix[1]="Large";}
		if(maxcitysizeslider.value === 0.5){textAffix[1]="Very Large";}

		if(latched[0] !== mincitysizeslider.value && mincitysizeslider.clicked === false){
			latched[0] = mincitysizeslider.value;
			Size = [round(latched[2]*GridSpaceAspectRatio[0]), round(latched[2]*GridSpaceAspectRatio[1])];
			board_Scale = round(100/(Size[0])*2*1.65)/2;
			offset = [(board_Scale*50)/10,(board_Scale*50)/10];
			regenCity(Size, 400, 1000, mincitysizeslider.value*100+10, maxcitysizeslider.value*100+30);
		}
		if(latched[1] !== maxcitysizeslider.value && maxcitysizeslider.clicked === false){
			latched[1] = maxcitysizeslider.value;
			Size = [round(latched[2]*GridSpaceAspectRatio[0]), round(latched[2]*GridSpaceAspectRatio[1])];
			board_Scale = round(100/(Size[0])*2*1.65)/2;
			offset = [(board_Scale*50)/10,(board_Scale*50)/10];
			regenCity(Size, 400, 1000, mincitysizeslider.value*100+10, maxcitysizeslider.value*100+30);
		}
		if(latched[2] !== GridSpaceSlider.value && GridSpaceSlider.clicked === false){
			latched[2] = GridSpaceSlider.value;
			Size = [round(latched[2]*GridSpaceAspectRatio[0]), round(latched[2]*GridSpaceAspectRatio[1])];
			board_Scale = round(100/(Size[0])*2*1.65)/2;
			offset = [0,0];
			regenCity(Size, 400, 1000, mincitysizeslider.value*100+10, maxcitysizeslider.value*100+30);
		}

		fill(0);
		textSize(16);
		text("Minimum City Size: " + textAffix[0], 200, 130);
		text("Maximum City Size: " + textAffix[1], 200, 190);
		text("City Limmit Size: " + round(GridSpaceSlider.value*GridSpaceAspectRatio[0]) + " X " + round(GridSpaceSlider.value*GridSpaceAspectRatio[1]), 200, 250);
	}else if(screen === "Instructions"){
		background(50,255,50);
		if(true===true){
			pushMatrix();
			translate(offset[0], offset[1]);
			rectMode(CENTER);
			if(pscreen!=="pause"){time+=0.01;}
			if(round(time*100)/100 >= 24){
				time = 0;
			}
			if(round(time%1*100) >= 60){
				time = round(floor(time)+1);
			}
			
			if(timer%20 === 0){
				board[constrain(round(random(3,Size[0]-3)),3,Size[0]-3)][constrain(round(random(3,Size[1]-3)),3,Size[1]-3)].Spread();
			}

			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					board[x][y].Draw();
					if(pscreen!=="pause"){board[x][y].IntTick();}
				}
			}

			if(pscreen!=="pause"){
				for(var i = 0; i < cars.length; i++){
					cars[i].FindSpeed();
				}
			}

			noStroke();
			for(var i = 0; i < cars.length; i++){
				cars[i].Draw();
				if(pscreen!=="pause"){cars[i].Drive();}
			}

			popMatrix();

			rectMode(CENTER);
			fill(0, 0, 0, (cos(time/3.8)+1)*70);
			rect(width/2,height/2,width,height);

			textSize(20);
			fill(255,255,255);
			if(round(time%1*100) < 10){
				text(floor(time) + ":0" + round(time%1*100), 0, 20);
			}else{
				text(floor(time) + ":" + round(time%1*100), 0, 20);
			}

			if(pscreen === "pause"){
				text("Current Score " + round(averageSpeed*100), 0, 40); // Print Score
				text("Your Best is " + bestScore, 0, 60);
			}
		} // draw background game

		rectMode(CENTER);
		fill(150, 150, 150, 150);
		rect(width/2, height/2, 600, 800, 10);

		fill(75,75,255);
		textSize(100);
		text("Instructions", width/2-250, height/2-300);

		fill(0);
		textSize(30);
		text("The objective of the game is to maximize\nthe speed of traffic flowing through the\ncity. To do this, click on intersections and\ntoggle between having a stoplight and\nstopsign. From there you can modify the\nspecifics of the stop.\n\n\n\nUse your mouse to pan and '+' and '-' to\nzoom, 'c' to recenter your camera and\n'o' to toggle traffic density overlay.", width/2-270, height/2-250);
		
		fill(220,220,255);
		backbutton.pos = new PVector(675,750);
		backbutton.draw();
		if(backbutton.detectClick(true) === true){
			screen = pscreen;
		}
	}else if(screen === "pause"){
		background(50,255,50);
		if(true===true){
			pushMatrix();
			translate(offset[0], offset[1]);
			rectMode(CENTER);

			if(round(time*100)/100 >= 24){
				time = 0;
			}
			if(round(time%1*100) >= 60){
				time = round(floor(time)+1);
			}
			rectMode(CENTER);
			
			if(timer%20 === 0){
				board[constrain(round(random(3,Size[0]-3)),3,Size[0]-3)][constrain(round(random(3,Size[1]-3)),3,Size[1]-3)].Spread();
			}

			for(var x = 0; x < board.length; x++){
				for(var y = 0; y < board[x].length; y++){
					board[x][y].Draw();
				}
			}

			noStroke();
			for(var i = 0; i < cars.length; i++){
				cars[i].Draw();
			}

			popMatrix();

			rectMode(CENTER);
			fill(0, 0, 0, (cos(time/3.8)+1)*70);
			rect(width/2,height/2,width,height);

			fill(255,0,0);
			textSize(20);
			text(round(frameRate*100)/100, width-50, 20);

			fill(255,255,255);
			if(round(time%1*100) < 10){
				text(floor(time) + ":0" + round(time%1*100), 0, 20);
			}else{
				text(floor(time) + ":" + round(time%1*100), 0, 20);
			}
			text("Current Score " + round(averageSpeed*100), 0, 40); // Print Score
			text("Your Best is " + bestScore, 0, 60);
		} // draw background game

		rectMode(CENTER);
		fill(150, 150, 150, 200);
		rect(width/2, height/2, 600, 500, 10);

		fill(75,75,255);
		textSize(100);
		text("Paused", width/2-175, height/2-150);

		fill(175,175,200);
		backbutton.pos = new PVector(675, 600);
		backbutton.draw();
		if(backbutton.detectClick(true) === true){
			pscreen = screen;
			screen = "MainGame";
		}

		fill(175,175,200);
		instructionsbutton.pos = new PVector(675, 450);
		instructionsbutton.draw();
		if(instructionsbutton.detectClick(true) === true){
			pscreen = screen;
			screen = "Instructions";
		}
	}

	//println(screen);

	pmousePressed = mousePressed; // must be at the below all code using this varible, put at bottom of draw function if possible
	pkeyPressed = keyPressed;
	pkey = key;
	textAlign(CORNER,CORNER);
}