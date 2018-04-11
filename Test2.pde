void setup() {
  size(1650, 950);
  background(50,255,50);
}

randomSeed(1);

var useImages = true;
var averageSpeed = 0;

var carImages = [loadImage("/Images/Car1.jpg"),loadImage("/Images/Car2.jpg"),loadImage("/Images/Car3.jpg"),loadImage("/Images/Car4.jpg")];

var time = 2;
var FR = 60;

var Size = [41,23];
var board_Scale = 4;
var board = [];
var board_Connections = [];
var offset = [0,0];
var trafficOverlay = false;
var edditing = null;

for(var x = 0; x < Size[0]; x++){
	board.push([]);
	for(var y = 0; y < Size[1]; y++){
		board[x].push([0,0,0,0]);
	}
}

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

var origin = [floor(Size[0]/2), floor(Size[1]/2)];

board[floor(Size[0]/2)][floor(Size[1]/2)] = [1,0,1,0];

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
	if(ArraysEqual(board[x][y], [0,0,0,0]) === false && depth < maxDepth){
		var probability = 1.2-(Dist(x,y,origin[0],origin[1])/50);
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

GenAdj(floor(Size[0]/2),floor(Size[1]/2),0,10);

function Connect(x,y){
	var adj = GetAdjConnections(x,y);
	for(var i = 0; i < adj.length; i++){
		if(adj[i] === 1){
			board[x][y][i] = 1;
		}
	}
}

for(var x = 0; x < board.length; x++){
	for(var y = 0; y < board[x].length; y++){
		if(round(random(0.2,1.5)) == 1){
			Connect(x, y);
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
	this.intTime = round(random(5,10)); // time(in seconds) between the changing of the stop light
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
	for(var i=0;i<FR*10;i++){this.trafficValueHistory.push(0);}
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
		if(this.timer >= round(this.intTime*FR)){
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

	/*this.trafficValueHistory.splice(0,1);
	var temp = 0;
	for(var i = 0; i < this.cars.length; i++){
		temp+=cars[i].speed;
	}
	this.trafficValueHistory.push((temp*this.cars.length)/(averageSpeed*cars.length));
	this.trafficValue=0;
	for(var i=0;i<this.trafficValueHistory.length;i++){this.trafficValue = (this.trafficValue*this.trafficValueHistory.length) + this.trafficValueHistory[i];}
	this.trafficValue = this.trafficValue/this.trafficValueHistory.length;*/

	//translate and scale properly. Can draw between (-50,-50) and (50,50)

	if(this.pos.x+offset[0] > -(50*(board_Scale/10)) && this.pos.x+offset[0] < width+(50*(board_Scale/10)) && this.pos.y+offset[1] > -(50*(board_Scale/10)) && this.pos.y+offset[1] < height+(50*(board_Scale/10))){
		var clickRad = 7;
		if(mousePressed && mouseX >= this.pos.x+offset[0]-clickRad*board_Scale/10 && mouseX <= this.pos.x+offset[0]+clickRad*board_Scale/10 && mouseY >= this.pos.y+offset[1]-clickRad*board_Scale/10 && mouseY <= this.pos.y+offset[1]+clickRad*board_Scale/10 && this.roadnum > 2){
			//if the center of the tile is clicked
			edditing = this.place
		}

		pushMatrix();
		translate(this.pos.x, this.pos.y);
		scale(board_Scale/10);

		noStroke();
		fill(50,255,50);
		rect(0, 0, 100, 100);
		if(this.roadnum <= 2){
			this.roadnum = 0;
		}
		for(var i = 0; i < this.connections.length; i++){
			if(this.connections[i] === 1){
				fill(150);
				rect(22,0,58,14);
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
		popMatrix();
		//fill(255,0,0);
		//rect(this.pos.x, this.pos.y, 14*board_Scale/10, 14*board_Scale/10);
	}
};

for(var x = 0; x < board.length; x++){
	for(var y = 0; y < board[x].length; y++){
		board[x][y] = new piece(x,y,board[x][y]);
	}
}

function FindCIF(that) { // CIF = Car in front
	var valid = board[that.tile.x][that.tile.y].cars;
	var nvalid = [];
	
	for(var i = 0; i < valid.length; i++){ // find all cars in the same tile that have the same rotation
		var a = cars[valid[i]];
		if(that.rotation === a.rotation && that.num !== cars[valid[i]].num){//(that.pos.x*cos(that.rotation) >= a.pos.x+abs(cos(a.rotation)+1)*4 && that.pos.x*cos(that.rotation) <= a.pos.x-abs(cos(a.rotation)+1)*4 && (that.rotation+180)%360 !== a.rotation) || (that.pos.y*sin(that.rotation) <= a.pos.y+abs(sin(a.rotation)+1)*4 && that.pos.y*sin(that.rotation) >= a.pos.y-abs(sin(a.rotation)+1)*4 && (that.rotation+180)%360 !== a.rotation) || 
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
	this.CIF = [0,0,0];
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
			//text("Information for car #" + this.num + "\npos: " + this.pos + "\nroad: " + this.road + ", " + this.newRoad + "\nspeed: " + this.speed + "\ntile: " + this.tile + "\nrotation: " + this.rotation + "\nnew Y: " + round((this.pos.y+sin(this.rotation/180*PI)*constrain(this.speed,0,this.maxSpeed)/10)*10)/10, 0, 0);
		//}

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
		this.CIF = FindCIF(this);
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
	}else if(this.pos.x > 50){
		this.pos.x = -50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.x += 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
	}

	if(this.pos.y < -50){
		this.pos.y = 50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.y -= 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
	}else if(this.pos.y > 50){
		this.pos.y = -50;
		board[this.tile.x][this.tile.y].cars = RemoveInstances(this.num, board[this.tile.x][this.tile.y].cars);
		this.tile.y += 1;
		board[this.tile.x][this.tile.y].cars.push(this.num);
		this.newRoad = PickDir(this.tile.x,this.tile.y,this.road);
		this.turned = false;
	}

	if(round(this.pos.x) === 0 && round(this.pos.y) === 0 && this.turned === false){
		//println(this.road + ", " + this.newRoad);r
		this.turned = true;
		this.road = this.newRoad;
		this.rotation = 90*this.road;
		this.pos.x = 0;
		this.pos.y = 0;
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
	this.CIF = FindCIF(this);//stores the value of the car ahead of the current car 

	if(this.CIF[0] === -1){
		this.speed = 10;
	}else if(this.rotation === cars[this.CIF[0]].rotation){
		this.CIFdist = this.CIF[1];
		//println(this.CIFdist);
		this.CIF = cars[this.CIF[0]];
		if(this.CIFdist < 13){
			this.speed = constrain(constrain(this.CIF.speed,0,this.CIF.maxSpeed)-1,0,10);
		}else if(this.CIFdist < 15){
			this.speed = constrain(this.CIF.speed,0,this.CIF.maxSpeed);
		}else if(this.CIFdist < 50){
			this.speed = constrain(constrain(this.CIF.speed,0,this.CIF.maxSpeed)+ceil(this.CIFdist/5)/2,0,10);
		}else{
			this.speed = constrain(this.speed+0.5,0,10);
		}
	}else{
		if(this.CIFdist < 5){
			this.speed = 0;
		}
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

	averageSpeed += constrain(this.speed,0,this.maxSpeed);
};

var cars = [];

var spots = [];

for(var x = 0; x < board.length; x++){
	for(var y = 0; y < board[x].length; y++){
		if(ArraysEqual(board[x][y].connections, [0,0,0,0]) === false){
			spots.push([x,y]);
		}
	}
}

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

for(var i = 0; i < 100; i++){
	CreateCar();
}

//cars.push(new Car(21,11,0));
//cars.push(new Car(22,11,0));

var timer = 1;
var dawn = true;

for(var x = 0; x < Size[0]; x++){
	for(var y = 0; y < Size[1]; y++){
		board[x][y].Connect();
	}
}

frameRate(FR);

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

	if(mousePressed && mouseX >= width-TabWidth+20 && mouseX <= width-TabWidth+100 && mouseY >= 30 && mouseY <= 60){stop.intersection = "LIGHT";}
	if(mousePressed && mouseX >= width-TabWidth+110 && mouseX <= width-TabWidth+190 && mouseY >= 30 && mouseY <= 60){stop.intersection = "STOP";}

	popMatrix();
}

void draw(){
	background(50,255,50);

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

	//(x-(100/board_Scale))/board_Scale/10 = tx, (y-(100/board_Scale))/board_Scale/10 = ty
	//var mouseTile = board[constrain(round(((mouseX-offset[0])-(100/board_Scale))/board_Scale/10),0,Size[0])][constrain(round(((mouseY-offset[1])-(100/board_Scale))/board_Scale/10),0,Size[1])];

	//println(round(mouseTile.intTime));

	//println(board[mouseTile[0]][mouseTile[1]].trafficValue);

	if(mousePressed){
		//frameRate(5);
		//println(mouseTile[0]+", "+mouseTile[1]);
		//board[mouseTile[0]][mouseTile[1]].Connect();

	}else{
		//frameRate(60);
	}

	if(mousePressed){
		offset[0] += mouseX-pmouseX;
		offset[1] += mouseY-pmouseY;
	}

	if(timer%5 === 0){
		board[round(random(3,Size[0]-3))][round(random(3,Size[1]-3))].Spread();
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

	if(timer%20 === 0 && round(random(0,1)) === 1 && cars.length < 300){
		//CreateCar();
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

	if(mousePressed && mouseX < width*7/8){
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
	text(frameRate, width-50, 20);
	fill(255,255,255);
	if(round(time%1*100) < 10){
		text(floor(time) + ":0" + round(time%1*100), 0, 20);
	}else{
		text(floor(time) + ":" + round(time%1*100), 0, 20);
	}
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

	if(keyPressed && key === 's'){
		frameRate(10);
	}else{
		frameRate(60);
	}

	if(keyPressed && key === 'c'){
		offset = [0,0];
		board_Scale = 4;
	}

	if(keyPressed && key === 'o'){
		trafficOverlay = !trafficOverlay;
	}

	if(keyPressed && key === '='){
		board_Scale += 0.5;
		offset[0] += -((width/2)*(0.25)/2);
		offset[1] += -((height/2)*(0.25)/2);
	}else if(keyPressed && key === '-' && board_Scale > 2){
		board_Scale -= 0.5;
		offset[0] += -((width/2)*(-0.25)/2);
		offset[1] += -((height/2)*(-0.25)/2);
	}
}