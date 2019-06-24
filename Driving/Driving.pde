void setup(){ // Uses NEAT
	size(800, 600);
	randomSeed(5);
	frameRate(100);
}

int innovation_numberC = 0;
int innovation_numberN = 0;

float[][] existingNodes = {};
float[][] existingConnections = {};

int TN = 3;
Track t = new Track(TN);
Car c = new Car(t, new PVector(100,520), PI);
int Slen = 0;

float[] rotations = {/*-2*PI/3,-PI/2,*/-PI/4/*, 0*/, PI/4/*, PI/2, 2*PI/3*/};

/*
float[][] Nt = {{0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,1},{7,1}};
float[][] Ct = {{5,6,-10000,1,0}};

Net n = new Net(Nt, Ct);*/

Population pop = new Population(200, rotations.length+0+Slen, 2+Slen); // one in node for each rotation and 3 for velocity, rotation and bias
boolean s = true;
int LastNet = 0;
Net Best = pop.Nets[0];

boolean pKeyPressed = false;
int r = 0;
int rMax = 2000;

double frictionVal = -5;

void draw() {
	background(255);
	//println(mouseX + ", " + mouseY);
	
	if(keyPressed/* && !pKeyPressed*/ && key == 'f'){
		// run instantly
		while(r < rMax){
			boolean AllDead = true;
			r++;
			for(int i = 0; i < pop.Nets.length; i++){
				pop.Nets[i].SimulateStep(s, false);
				if(pop.Nets[i].alive){AllDead = false;}
			}
			if(AllDead){break;}
			s = false;
		}
		pop.RunGen();
		s=true;
		r=0;
	}else{
		// run and visualize
		boolean AllDead = true;
		r++;
		for(int i = 0; i < pop.Nets.length; i++){
			pop.Nets[i].SimulateStep(s, true);
			if(pop.Nets[i].alive){AllDead = false;}
		}
		s = false;
		if(AllDead || r > rMax){pop.RunGen();s=true;r=0;}
	}
	
	if(keyPressed && !pKeyPressed && key == 'p'){
		print("Nodes: ");
		for(int i = 0; i < Best.Nodes.length; i++){
			print(Best.Nodes[i][0] + ", ");
		}
		println();
		
		print("Connections: ");
		for(int i = 0; i < Best.connections.length; i++){
			float[] x = Best.connections[i];
			if((int)x[3] == 1){
				print("(" + x[0] + ", " + x[1] + ", " + x[2] + "), ");
			}
		}
		println();
	}
	
	
	//background(255);
	/*if(n.fitness == 0){
		println(millis());
		n.SimulateInst();
		println(millis());
	}
	println(n.fitness);
	
	if(c.touchingTrack()){
		background(255,0,0);
	}*/
	/*
	float a = 0;
	float b = 0;
	if(keyPressed && keyCode == UP){
		a += 0.5;
	}else if(keyPressed && keyCode == DOWN){
		a -= 0.5;
	}else if(keyPressed && keyCode == LEFT){
		b -= 0.05;
	}else if(keyPressed && keyCode == RIGHT){
		b += 0.05;
	}
	
	c.Drive(a,b);
	c.Draw(true);
	c.Step();
	
	if(c.touchingTrack()){
		background(255,0,0);
	}
	*/
	t.Draw();
	pKeyPressed = keyPressed;
}

// Helper Code

float Dot(PVector a, PVector b){
	return a.x*b.x + a.y*b.y;
}

float Cross(PVector a, PVector b){
	return a.x*b.y - a.y*b.x;
}

float[][] insert(float[][] array, float[] x, int place){
	float[][] out = {};
	for(int i = 0; i < place-1; i++){
		out = (float[][])append(out, array[i]);
	}
	out = (float[][])append(out, x);
	for(int i = place-1; i < array.length; i++){
		out = (float[][])append(out, array[i]);
	}
	return out;
}

Net[] insert(Net[] array, Net x, int place){
	Net[] out = {};
	if(place > 0){
		for(int i = 0; i < place-1; i++){
			out = (Net[])append(out, array[i]);
		}
	}
	out = (Net[])append(out, x);
	for(int i = max(place-1,0); i < array.length; i++){
		out = (Net[])append(out, array[i]);
	}
	return out;
}

float sigmoid(float x){
	return 1/(1 + exp(-x));
}

float[][] Remove(float[][] list, int[] to_Remove){
	float[][] out = {};
	
	for(int i = 0; i < list.length; i++){
		boolean c = false;
		for(int a = 0; a < to_Remove.length; a++){
			if(i == to_Remove[a]){
				c = true;
				break;
			}
		}
		if(c){continue;}
		out = (float[][])append(out, list[i]);
	}
	return out;
}

float[][] getDisjoint(Net A, Net B){
	float[][] out = {};
	float[][] c1 = new float[A.connections.length][];
	arrayCopy(A.connections, c1);
	float[][] c2 = new float[B.connections.length][];
	arrayCopy(B.connections, c2);
		
	for(int a = 0; a < c1.length; a++){
		boolean f = false;
		for(int b = 0; b < c2.length; b++){
			if(c1[a][4] == c2[b][4]){
				f = true;
				break;
			}
		}
		if(!f){
			for(int i = 0; i < A.Start_Nodes.length; i++){
				if(c1[a][0] == A.Start_Nodes[i]){
					out = (float[][])append(out, c1[a]);
				}
			}
		}
	}
	
	for(int a = 0; a < c2.length; a++){
		boolean f = false;
		for(int b = 0; b < c1.length; b++){
			if(c2[a][4] == c1[b][4]){
				f = true;
				break;
			}
		}
		if(!f){
			for(int i = 0; i < A.Start_Nodes.length; i++){
				if(c2[a][0] == A.Start_Nodes[i]){
					out = (float[][])append(out, c2[a]);
				}
			}
		}
	}
	return out;
}
float[][] getExcess(Net A, Net B){
	float[][] out = {};
	float[][] c1 = new float[A.connections.length][];
	arrayCopy(A.connections, c1);
	float[][] c2 = new float[B.connections.length][];
	arrayCopy(B.connections, c2);
		
	for(int a = 0; a < c1.length; a++){
		boolean f = false;
		for(int b = 0; b < c2.length; b++){
			if(c1[a][4] == c2[b][4]){
				f = true;
				break;
			}
		}
		if(!f){
			f = false;
			for(int i = 0; i < A.Start_Nodes.length; i++){
				if(c1[a][0] == A.Start_Nodes[i]){
					f = true;
				}
			}
			if(!f){out = (float[][])append(out, c1[a]);}
		}
	}
	
	for(int a = 0; a < c2.length; a++){
		boolean f = false;
		for(int b = 0; b < c1.length; b++){
			if(c2[a][4] == c1[b][4]){
				f = true;
				break;
			}
		}
		if(!f){
			f = false;
			for(int i = 0; i < A.Start_Nodes.length; i++){
				if(c2[a][0] == A.Start_Nodes[i]){
					f = true;
				}
			}
			if(!f){out = (float[][])append(out, c2[a]);}
		}
	}
	return out;
}

float GDist(Net A, Net B, float c1, float c2, float c3){
	float out = c1*getExcess(A,B).length/max(A.connections.length, B.connections.length) + c2*getDisjoint(A,B).length/max(A.connections.length, B.connections.length);
	
	float w = 0;
	for(int a = 0; a < A.connections.length; a++){
		for(int b = 0; b < B.connections.length; b++){
			if(A.connections[a][4] == B.connections[b][4]){
				w += abs(A.connections[a][2] - B.connections[b][2]);
			}
		}
	}
	out += c3*w/max(A.connections.length,B.connections.length);
	return out;
}

boolean TFProb(float prob){ // prob between 0 and 100
	if(random(0,100) <= prob){
		return true;
	}
	return false;
}

Net Breed(Net A, Net B){
	float[][] AConList = {};
	float[][] BConList = {};
	
	int a = 0;
	int b = 0;
	
	for(int i = 0; i < max(A.connections[A.connections.length-1][4], B.connections[B.connections.length-1][4]); i++){
		if(A.connections[a][4] != i && B.connections[b][4] != i){
			if(A.connections[a][4] == i){
				float[] t = new float[A.connections[a].length];
				arrayCopy(A.connections[a], t);
				AConList = (float[][])append(AConList, t);
				a++;
			}else{
				AConList = (float[][])append(AConList, null);
			}
			
			if(B.connections[b][4] == i){
				float[] t = new float[A.connections[a].length];
				arrayCopy(B.connections[b], t);
				BConList = (float[][])append(BConList, t);
				b++;
			}else{
				BConList = (float[][])append(BConList, null);
			}
		}
	}
	
	Net out;
	if(A.fitness > B.fitness){
		out = A.Copy();
		int ac = 0;
		for(int i = 0; i < AConList.length; i++){
			if(AConList[i] != null && BConList[i] != null){
				if(TFProb(50)){
					arrayCopy(BConList[i], out.connections[ac]);
				}
				
				if((AConList[i][3] == 0 || BConList[i][3] == 0) && TFProb(75)){
					out.connections[ac][3] = 0;
				}/*else{
					out.connections[ac][3] = 1;
				}*/
			}
			if(AConList[i] != null){ac++;}
		}
	}else{
		out = B.Copy();
		int bc = 0;
		for(int i = 0; i < BConList.length; i++){
			if(AConList[i] != null && BConList[i] != null && TFProb(50)){
				out.connections[bc] = AConList[i];
			}
			if(BConList[i] != null){bc++;}
		}
	}
	
	return out;
}

int[] getRange(int min, int max){
	int[] out = {};
	for(int i = min; i < max; i++){
		out = append(out, i);
	}
	return out;
}

// Track class

class Track {
	PVector[][] gaits = {}; //= {{new PVector(116.0, 129.0), new PVector(117.0, 180.0)}, {new PVector(127.0, 180.0), new PVector(127.0, 126.0)}, {new PVector(134.0, 126.0), new PVector(134.0, 182.0)}, {new PVector(150.0, 184.0), new PVector(150.0, 103.0)}, {new PVector(170.0, 111.0), new PVector(168.0, 179.0)}, {new PVector(185.0, 180.0), new PVector(187.0, 120.0)}, {new PVector(189.0, 188.0), new PVector(281.0, 188.0)}, {new PVector(116.0, 186.0), new PVector(33.0, 187.0)}, {new PVector(135.0, 277.0), new PVector(20.0, 274.0)}, {new PVector(130.0, 378.0), new PVector(20.0, 390.0)}, {new PVector(48.0, 526.0), new PVector(129.0, 460.0)}, {new PVector(267.0, 480.0), new PVector(266.0, 566.0)}, {new PVector(447.0, 566.0), new PVector(448.0, 471.0)}, {new PVector(531.0, 473.0), new PVector(529.0, 570.0)}, {new PVector(693.0, 547.0), new PVector(625.0, 456.0)}, {new PVector(666.0, 411.0), new PVector(773.0, 403.0)}, {new PVector(777.0, 324.0), new PVector(657.0, 325.0)}, {new PVector(667.0, 231.0), new PVector(780.0, 214.0)}, {new PVector(778.0, 91.0), new PVector(681.0, 102.0)}, {new PVector(570.0, 125.0), new PVector(570.0, 18.0)}, {new PVector(447.0, 2.0), new PVector(443.0, 93.0)}, {new PVector(391.0, 110.0), new PVector(283.0, 107.0)}, {new PVector(299.0, 264.0), new PVector(391.0, 172.0)}, {new PVector(358.0, 311.0), new PVector(493.0, 313.0)}, {new PVector(464.0, 439.0), new PVector(352.0, 363.0)}, {new PVector(310.0, 345.0), new PVector(203.0, 432.0)}, {new PVector(180.0, 273.0), new PVector(285.0, 292.0)}};
	PVector[][] track = {}; //= {{new PVector(659.0, 556.0), new PVector(106.0, 556.0)}, {new PVector(106.0, 556.0), new PVector(36.0, 499.0)}, {new PVector(36.0, 499.0), new PVector(32.0, 37.0)}, {new PVector(32.0, 37.0), new PVector(64.0, 7.0)}, {new PVector(64.0, 7.0), new PVector(248.0, 7.0)}, {new PVector(248.0, 7.0), new PVector(278.0, 39.0)}, {new PVector(278.0, 39.0), new PVector(277.0, 350.0)}, {new PVector(277.0, 350.0), new PVector(321.0, 391.0)}, {new PVector(321.0, 391.0), new PVector(356.0, 391.0)}, {new PVector(356.0, 391.0), new PVector(399.0, 353.0)}, {new PVector(399.0, 353.0), new PVector(399.0, 300.0)}, {new PVector(399.0, 300.0), new PVector(365.0, 269.0)}, {new PVector(365.0, 269.0), new PVector(321.0, 269.0)}, {new PVector(321.0, 269.0), new PVector(288.0, 241.0)}, {new PVector(288.0, 241.0), new PVector(287.0, 37.0)}, {new PVector(287.0, 37.0), new PVector(313.0, 11.0)}, {new PVector(313.0, 11.0), new PVector(494.0, 11.0)}, {new PVector(494.0, 11.0), new PVector(534.0, 48.0)}, {new PVector(534.0, 48.0), new PVector(588.0, 48.0)}, {new PVector(588.0, 48.0), new PVector(628.0, 15.0)}, {new PVector(628.0, 15.0), new PVector(723.0, 16.0)}, {new PVector(723.0, 16.0), new PVector(770.0, 53.0)}, {new PVector(770.0, 53.0), new PVector(762.0, 469.0)}, {new PVector(658.0, 556.0), new PVector(762.0, 470.0)}, {new PVector(157.0, 483.0), new PVector(116.0, 452.0)}, {new PVector(116.0, 452.0), new PVector(111.0, 173.0)}, {new PVector(111.0, 173.0), new PVector(195.0, 173.0)}, {new PVector(195.0, 173.0), new PVector(195.0, 397.0)}, {new PVector(195.0, 397.0), new PVector(272.0, 460.0)}, {new PVector(272.0, 460.0), new PVector(386.0, 459.0)}, {new PVector(386.0, 459.0), new PVector(475.0, 378.0)}, {new PVector(475.0, 378.0), new PVector(475.0, 274.0)}, {new PVector(475.0, 274.0), new PVector(398.0, 203.0)}, {new PVector(398.0, 203.0), new PVector(383.0, 202.0)}, {new PVector(383.0, 202.0), new PVector(358.0, 181.0)}, {new PVector(358.0, 181.0), new PVector(356.0, 91.0)}, {new PVector(356.0, 91.0), new PVector(369.0, 74.0)}, {new PVector(369.0, 74.0), new PVector(455.0, 72.0)}, {new PVector(455.0, 72.0), new PVector(502.0, 111.0)}, {new PVector(502.0, 111.0), new PVector(598.0, 108.0)}, {new PVector(598.0, 108.0), new PVector(653.0, 66.0)}, {new PVector(653.0, 66.0), new PVector(697.0, 66.0)}, {new PVector(697.0, 66.0), new PVector(694.0, 427.0)}, {new PVector(694.0, 427.0), new PVector(641.0, 483.0)}, {new PVector(641.0, 483.0), new PVector(158.0, 484.0)}, {new PVector(112.0, 135.0), new PVector(193.0, 135.0)}, {new PVector(193.0, 135.0), new PVector(193.0, 81.0)}, {new PVector(193.0, 81.0), new PVector(177.0, 54.0)}, {new PVector(177.0, 54.0), new PVector(131.0, 53.0)}, {new PVector(131.0, 53.0), new PVector(111.0, 75.0)}, {new PVector(111.0, 75.0), new PVector(112.0, 136.0)}, {new PVector(130.0, 136.0), new PVector(130.0, 146.0)}, {new PVector(174.0, 173.0), new PVector(173.0, 163.0)}};
	
	Track(){
		for(int i = 0; i < track.length; i++){
			if(track[i][0].x == track[i][1].x){
				track[i][1].x += 0.05;
			}
		}
	}
	
	Track(int TrackNum){
		for(int i = 0; i < track.length; i++){
			if(track[i][0].x == track[i][1].x){
				track[i][1].x += 0.1;
			}
		}
		
		if(TrackNum == 0){
			PVector[][] a = {{new PVector(160.0, 131.0), new PVector(236.0, 185.0)}, {new PVector(313.0, 165.0), new PVector(304.0, 70.0)}, {new PVector(412.0, 162.0), new PVector(465.0, 80.0)}, {new PVector(399.0, 215.0), new PVector(563.0, 185.0)}, {new PVector(536.0, 289.0), new PVector(626.0, 217.0)}, {new PVector(556.0, 357.0), new PVector(668.0, 389.0)}, {new PVector(519.0, 349.0), new PVector(475.0, 424.0)}, {new PVector(417.0, 375.0), new PVector(415.0, 289.0)}, {new PVector(349.0, 390.0), new PVector(290.0, 329.0)}, {new PVector(266.0, 365.0), new PVector(206.0, 441.0)}, {new PVector(173.0, 315.0), new PVector(249.0, 274.0)}};
			PVector[][] b = {{new PVector(224.0, 445.0), new PVector(141.0, 174.0)}, {new PVector(141.0, 174.0), new PVector(207.0, 99.0)}, {new PVector(207.0, 99.0), new PVector(379.0, 82.0)}, {new PVector(379.0, 82.0), new PVector(585.0, 128.0)}, {new PVector(585.0, 128.0), new PVector(488.0, 198.0)}, {new PVector(488.0, 198.0), new PVector(628.0, 251.0)}, {new PVector(628.0, 251.0), new PVector(647.0, 434.0)}, {new PVector(647.0, 434.0), new PVector(501.0, 434.0)}, {new PVector(501.0, 434.0), new PVector(445.0, 360.0)}, {new PVector(445.0, 360.0), new PVector(340.0, 360.0)}, {new PVector(340.0, 360.0), new PVector(318.0, 443.0)}, {new PVector(318.0, 443.0), new PVector(224.0, 445.0)}, {new PVector(264.0, 381.0), new PVector(207.0, 196.0)}, {new PVector(207.0, 196.0), new PVector(246.0, 145.0)}, {new PVector(246.0, 145.0), new PVector(374.0, 135.0)}, {new PVector(374.0, 135.0), new PVector(447.0, 151.0)}, {new PVector(447.0, 151.0), new PVector(412.0, 213.0)}, {new PVector(412.0, 213.0), new PVector(560.0, 276.0)}, {new PVector(560.0, 276.0), new PVector(584.0, 369.0)}, {new PVector(584.0, 369.0), new PVector(527.0, 371.0)}, {new PVector(527.0, 371.0), new PVector(477.0, 306.0)}, {new PVector(477.0, 306.0), new PVector(319.0, 304.0)}, {new PVector(319.0, 304.0), new PVector(288.0, 350.0)}, {new PVector(288.0, 350.0), new PVector(281.0, 381.0)}, {new PVector(281.0, 381.0), new PVector(264.0, 381.0)}};
			gaits = a;
			track = b;
		}else if(TrackNum == 1){
			PVector[][] a = {{new PVector(244.0, 468.0), new PVector(243.0, 550.0)}, {new PVector(193.0, 438.0), new PVector(132.0, 533.0)}, {new PVector(145.0, 386.0), new PVector(33.0, 430.0)}, {new PVector(142.0, 309.0), new PVector(15.0, 309.0)}, {new PVector(133.0, 215.0), new PVector(17.0, 213.0)}, {new PVector(149.0, 153.0), new PVector(52.0, 63.0)}, {new PVector(177.0, 145.0), new PVector(263.0, 36.0)}, {new PVector(178.0, 191.0), new PVector(284.0, 189.0)}, {new PVector(180.0, 272.0), new PVector(283.0, 272.0)}, {new PVector(289.0, 344.0), new PVector(182.0, 392.0)}, {new PVector(242.0, 466.0), new PVector(324.0, 399.0)}, {new PVector(371.0, 417.0), new PVector(375.0, 475.0)}, {new PVector(424.0, 394.0), new PVector(514.0, 438.0)}, {new PVector(430.0, 347.0), new PVector(533.0, 292.0)}, {new PVector(327.0, 290.0), new PVector(393.0, 235.0)}, {new PVector(381.0, 168.0), new PVector(302.0, 169.0)}, {new PVector(388.0, 109.0), new PVector(338.0, 47.0)}, {new PVector(445.0, 102.0), new PVector(444.0, 34.0)}, {new PVector(548.0, 103.0), new PVector(546.0, 36.0)}, {new PVector(642.0, 104.0), new PVector(641.0, 34.0)}, {new PVector(685.0, 140.0), new PVector(760.0, 127.0)}, {new PVector(764.0, 238.0), new PVector(683.0, 240.0)}, {new PVector(680.0, 296.0), new PVector(757.0, 296.0)}, {new PVector(765.0, 397.0), new PVector(683.0, 385.0)}, {new PVector(682.0, 503.0), new PVector(632.0, 435.0)}, {new PVector(549.0, 546.0), new PVector(546.0, 464.0)}, {new PVector(437.0, 478.0), new PVector(438.0, 544.0)}, {new PVector(350.0, 544.0), new PVector(351.0, 478.0)}};
			PVector[][] b = {{new PVector(607.0, 539.0), new PVector(173.0, 540.0)}, {new PVector(173.0, 540.0), new PVector(63.0, 475.0)}, {new PVector(63.0, 475.0), new PVector(36.0, 361.0)}, {new PVector(36.0, 361.0), new PVector(37.0, 103.0)}, {new PVector(37.0, 103.0), new PVector(100.0, 36.0)}, {new PVector(100.0, 36.0), new PVector(223.0, 31.0)}, {new PVector(223.0, 31.0), new PVector(274.0, 65.0)}, {new PVector(274.0, 65.0), new PVector(277.0, 350.0)}, {new PVector(277.0, 350.0), new PVector(326.0, 422.0)}, {new PVector(326.0, 422.0), new PVector(420.0, 423.0)}, {new PVector(420.0, 423.0), new PVector(463.0, 362.0)}, {new PVector(463.0, 362.0), new PVector(426.0, 303.0)}, {new PVector(426.0, 303.0), new PVector(360.0, 302.0)}, {new PVector(360.0, 302.0), new PVector(311.0, 262.0)}, {new PVector(311.0, 262.0), new PVector(309.0, 77.0)}, {new PVector(309.0, 77.0), new PVector(359.0, 40.0)}, {new PVector(359.0, 40.0), new PVector(684.0, 39.0)}, {new PVector(684.0, 39.0), new PVector(757.0, 90.0)}, {new PVector(757.0, 90.0), new PVector(756.0, 452.0)}, {new PVector(756.0, 452.0), new PVector(607.0, 539.0)}, {new PVector(181.0, 448.0), new PVector(119.0, 399.0)}, {new PVector(119.0, 399.0), new PVector(123.0, 137.0)}, {new PVector(123.0, 137.0), new PVector(188.0, 135.0)}, {new PVector(188.0, 135.0), new PVector(191.0, 389.0)}, {new PVector(191.0, 389.0), new PVector(255.0, 476.0)}, {new PVector(255.0, 476.0), new PVector(473.0, 476.0)}, {new PVector(473.0, 476.0), new PVector(565.0, 356.0)}, {new PVector(565.0, 356.0), new PVector(492.0, 251.0)}, {new PVector(492.0, 251.0), new PVector(396.0, 248.0)}, {new PVector(396.0, 248.0), new PVector(373.0, 229.0)}, {new PVector(373.0, 229.0), new PVector(370.0, 119.0)}, {new PVector(370.0, 119.0), new PVector(392.0, 97.0)}, {new PVector(392.0, 97.0), new PVector(646.0, 98.0)}, {new PVector(646.0, 98.0), new PVector(687.0, 129.0)}, {new PVector(687.0, 400.0), new PVector(687.1, 129.0)}, {new PVector(687.0, 400.0), new PVector(604.0, 463.0)}, {new PVector(604.0, 463.0), new PVector(473.0, 476.0)}, {new PVector(182.0, 449.0), new PVector(254.0, 477.0)}};
			gaits = a;
			track = b;
		}else if(TrackNum == 2){
			PVector[][] a = {{new PVector(116.0, 129.0), new PVector(117.0, 180.0)}, {new PVector(127.0, 180.0), new PVector(127.0, 126.0)}, {new PVector(134.0, 126.0), new PVector(134.0, 182.0)}, {new PVector(150.0, 184.0), new PVector(150.0, 103.0)}, {new PVector(170.0, 111.0), new PVector(168.0, 179.0)}, {new PVector(185.0, 180.0), new PVector(187.0, 120.0)}, {new PVector(189.0, 188.0), new PVector(281.0, 188.0)}, {new PVector(116.0, 186.0), new PVector(33.0, 187.0)}, {new PVector(135.0, 277.0), new PVector(20.0, 274.0)}, {new PVector(130.0, 378.0), new PVector(20.0, 390.0)}, {new PVector(48.0, 526.0), new PVector(129.0, 460.0)}, {new PVector(267.0, 480.0), new PVector(266.0, 566.0)}, {new PVector(447.0, 566.0), new PVector(448.0, 471.0)}, {new PVector(531.0, 473.0), new PVector(529.0, 570.0)}, {new PVector(693.0, 547.0), new PVector(625.0, 456.0)}, {new PVector(666.0, 411.0), new PVector(773.0, 403.0)}, {new PVector(777.0, 324.0), new PVector(657.0, 325.0)}, {new PVector(667.0, 231.0), new PVector(780.0, 214.0)}, {new PVector(778.0, 91.0), new PVector(681.0, 102.0)}, {new PVector(570.0, 125.0), new PVector(570.0, 18.0)}, {new PVector(447.0, 2.0), new PVector(443.0, 93.0)}, {new PVector(391.0, 110.0), new PVector(283.0, 107.0)}, {new PVector(299.0, 264.0), new PVector(391.0, 172.0)}, {new PVector(358.0, 311.0), new PVector(493.0, 313.0)}, {new PVector(464.0, 439.0), new PVector(352.0, 363.0)}, {new PVector(310.0, 345.0), new PVector(203.0, 432.0)}, {new PVector(180.0, 273.0), new PVector(285.0, 292.0)}};
			PVector[][] b = {{new PVector(659.0, 556.0), new PVector(106.0, 556.0)}, {new PVector(106.0, 556.0), new PVector(36.0, 499.0)}, {new PVector(36.0, 499.0), new PVector(32.0, 37.0)}, {new PVector(32.0, 37.0), new PVector(64.0, 7.0)}, {new PVector(64.0, 7.0), new PVector(248.0, 7.0)}, {new PVector(248.0, 7.0), new PVector(278.0, 39.0)}, {new PVector(278.0, 39.0), new PVector(277.0, 350.0)}, {new PVector(277.0, 350.0), new PVector(321.0, 391.0)}, {new PVector(321.0, 391.0), new PVector(356.0, 391.0)}, {new PVector(356.0, 391.0), new PVector(399.0, 353.0)}, {new PVector(399.0, 353.0), new PVector(399.0, 300.0)}, {new PVector(399.0, 300.0), new PVector(365.0, 269.0)}, {new PVector(365.0, 269.0), new PVector(321.0, 269.0)}, {new PVector(321.0, 269.0), new PVector(288.0, 241.0)}, {new PVector(288.0, 241.0), new PVector(287.0, 37.0)}, {new PVector(287.0, 37.0), new PVector(313.0, 11.0)}, {new PVector(313.0, 11.0), new PVector(494.0, 11.0)}, {new PVector(494.0, 11.0), new PVector(534.0, 48.0)}, {new PVector(534.0, 48.0), new PVector(588.0, 48.0)}, {new PVector(588.0, 48.0), new PVector(628.0, 15.0)}, {new PVector(628.0, 15.0), new PVector(723.0, 16.0)}, {new PVector(723.0, 16.0), new PVector(770.0, 53.0)}, {new PVector(770.0, 53.0), new PVector(762.0, 469.0)}, {new PVector(658.0, 556.0), new PVector(762.0, 470.0)}, {new PVector(157.0, 483.0), new PVector(116.0, 452.0)}, {new PVector(116.0, 452.0), new PVector(111.0, 173.0)}, {new PVector(111.0, 173.0), new PVector(195.0, 173.0)}, {new PVector(195.0, 173.0), new PVector(195.0, 397.0)}, {new PVector(195.0, 397.0), new PVector(272.0, 460.0)}, {new PVector(272.0, 460.0), new PVector(386.0, 459.0)}, {new PVector(386.0, 459.0), new PVector(475.0, 378.0)}, {new PVector(475.0, 378.0), new PVector(475.0, 274.0)}, {new PVector(475.0, 274.0), new PVector(398.0, 203.0)}, {new PVector(398.0, 203.0), new PVector(383.0, 202.0)}, {new PVector(383.0, 202.0), new PVector(358.0, 181.0)}, {new PVector(358.0, 181.0), new PVector(356.0, 91.0)}, {new PVector(356.0, 91.0), new PVector(369.0, 74.0)}, {new PVector(369.0, 74.0), new PVector(455.0, 72.0)}, {new PVector(455.0, 72.0), new PVector(502.0, 111.0)}, {new PVector(502.0, 111.0), new PVector(598.0, 108.0)}, {new PVector(598.0, 108.0), new PVector(653.0, 66.0)}, {new PVector(653.0, 66.0), new PVector(697.0, 66.0)}, {new PVector(697.0, 66.0), new PVector(694.0, 427.0)}, {new PVector(694.0, 427.0), new PVector(641.0, 483.0)}, {new PVector(641.0, 483.0), new PVector(158.0, 484.0)}, {new PVector(112.0, 135.0), new PVector(193.0, 135.0)}, {new PVector(193.0, 135.0), new PVector(193.0, 81.0)}, {new PVector(193.0, 81.0), new PVector(177.0, 54.0)}, {new PVector(177.0, 54.0), new PVector(131.0, 53.0)}, {new PVector(131.0, 53.0), new PVector(111.0, 75.0)}, {new PVector(111.0, 75.0), new PVector(112.0, 136.0)}, {new PVector(130.0, 136.0), new PVector(130.0, 146.0)}, {new PVector(174.0, 173.0), new PVector(173.0, 163.0)}};
			gaits = a;
			track = b;
		}else if(TrackNum == 3){
	      PVector[][] a = {{new PVector(244.0, 468.0), new PVector(243.0, 550.0)}, {new PVector(193.0, 438.0), new PVector(132.0, 533.0)}, {new PVector(145.0, 386.0), new PVector(33.0, 430.0)}, {new PVector(142.0, 309.0), new PVector(15.0, 309.0)}, {new PVector(133.0, 215.0), new PVector(17.0, 213.0)}, {new PVector(149.0, 153.0), new PVector(52.0, 63.0)}, {new PVector(177.0, 145.0), new PVector(263.0, 36.0)}, {new PVector(178.0, 191.0), new PVector(284.0, 189.0)}, {new PVector(180.0, 272.0), new PVector(283.0, 272.0)}, {new PVector(289.0, 344.0), new PVector(182.0, 392.0)}, {new PVector(242.0, 466.0), new PVector(324.0, 399.0)}, {new PVector(371.0, 417.0), new PVector(375.0, 475.0)}, {new PVector(424.0, 394.0), new PVector(514.0, 438.0)}, {new PVector(430.0, 347.0), new PVector(533.0, 292.0)}, {new PVector(327.0, 290.0), new PVector(393.0, 235.0)}, {new PVector(381.0, 168.0), new PVector(302.0, 169.0)}, {new PVector(388.0, 109.0), new PVector(338.0, 47.0)}, {new PVector(445.0, 102.0), new PVector(444.0, 34.0)}, {new PVector(548.0, 103.0), new PVector(546.0, 36.0)}, {new PVector(642.0, 104.0), new PVector(641.0, 34.0)}, {new PVector(685.0, 140.0), new PVector(760.0, 127.0)}, {new PVector(764.0, 238.0), new PVector(683.0, 240.0)}, {new PVector(680.0, 296.0), new PVector(757.0, 296.0)}, {new PVector(765.0, 397.0), new PVector(683.0, 385.0)}, {new PVector(682.0, 503.0), new PVector(632.0, 435.0)}, {new PVector(549.0, 546.0), new PVector(546.0, 464.0)}, {new PVector(437.0, 478.0), new PVector(438.0, 544.0)}, {new PVector(350.0, 544.0), new PVector(351.0, 478.0)}};
	      PVector[][] b = {{new PVector(607.0, 539.0), new PVector(173.0, 540.0)}, {new PVector(173.0, 540.0), new PVector(63.0, 475.0)}, {new PVector(63.0, 475.0), new PVector(36.0, 361.0)}, {new PVector(36.0, 361.0), new PVector(37.0, 103.0)}, {new PVector(37.0, 103.0), new PVector(100.0, 36.0)}, {new PVector(100.0, 36.0), new PVector(223.0, 31.0)}, {new PVector(223.0, 31.0), new PVector(274.0, 65.0)}, {new PVector(274.0, 65.0), new PVector(277.0, 350.0)}, {new PVector(277.0, 350.0), new PVector(326.0, 422.0)}, {new PVector(326.0, 422.0), new PVector(420.0, 423.0)}, {new PVector(420.0, 423.0), new PVector(463.0, 362.0)}, {new PVector(463.0, 362.0), new PVector(426.0, 303.0)}, {new PVector(426.0, 303.0), new PVector(360.0, 302.0)}, {new PVector(360.0, 302.0), new PVector(311.0, 262.0)}, {new PVector(311.0, 262.0), new PVector(309.0, 77.0)}, {new PVector(309.0, 77.0), new PVector(359.0, 40.0)}, {new PVector(359.0, 40.0), new PVector(684.0, 39.0)}, {new PVector(684.0, 39.0), new PVector(757.0, 90.0)}, {new PVector(757.0, 90.0), new PVector(756.0, 452.0)}, {new PVector(756.0, 452.0), new PVector(607.0, 539.0)}, {new PVector(181.0, 448.0), new PVector(119.0, 399.0)}, {new PVector(119.0, 399.0), new PVector(123.0, 137.0)}, {new PVector(123.0, 137.0), new PVector(188.0, 135.0)}, {new PVector(188.0, 135.0), new PVector(191.0, 389.0)}, {new PVector(191.0, 389.0), new PVector(255.0, 476.0)}, {new PVector(255.0, 476.0), new PVector(473.0, 476.0)}, {new PVector(473.0, 476.0), new PVector(565.0, 356.0)}, {new PVector(565.0, 356.0), new PVector(492.0, 251.0)}, {new PVector(492.0, 251.0), new PVector(396.0, 248.0)}, {new PVector(396.0, 248.0), new PVector(373.0, 229.0)}, {new PVector(373.0, 229.0), new PVector(370.0, 119.0)}, {new PVector(370.0, 119.0), new PVector(392.0, 97.0)}, {new PVector(392.0, 97.0), new PVector(646.0, 98.0)}, {new PVector(646.0, 98.0), new PVector(687.0, 129.0)}, {new PVector(687.0, 400.0), new PVector(687.1, 129.0)}, {new PVector(687.0, 400.0), new PVector(604.0, 463.0)}, {new PVector(604.0, 463.0), new PVector(473.0, 476.0)}, {new PVector(182.0, 449.0), new PVector(254.0, 477.0)}, {new PVector(68.0, 453.0), new PVector(76.0, 474.0)}, {new PVector(76.0, 474.0), new PVector(93.0, 461.0)}, {new PVector(93.0, 461.0), new PVector(83.0, 441.0)}, {new PVector(83.0, 441.0), new PVector(68.0, 453.0)}, {new PVector(57.0, 95.0), new PVector(47.0, 125.0)}, {new PVector(47.0, 125.0), new PVector(67.0, 124.0)}, {new PVector(67.0, 124.0), new PVector(81.0, 95.0)}, {new PVector(81.0, 95.0), new PVector(57.0, 95.0)}, {new PVector(235.0, 75.0), new PVector(232.0, 100.0)}, {new PVector(232.0, 100.0), new PVector(263.0, 96.0)}, {new PVector(263.0, 96.0), new PVector(266.0, 67.0)}, {new PVector(266.0, 67.0), new PVector(235.0, 75.0)}, {new PVector(246.0, 440.0), new PVector(248.0, 454.0)}, {new PVector(248.0, 454.0), new PVector(266.0, 457.0)}, {new PVector(266.0, 457.0), new PVector(272.0, 431.0)}, {new PVector(272.0, 431.0), new PVector(247.0, 418.0)}, {new PVector(247.0, 418.0), new PVector(246.0, 440.0)}, {new PVector(465.0, 342.0), new PVector(468.0, 370.0)}, {new PVector(468.0, 370.0), new PVector(501.0, 359.0)}, {new PVector(501.0, 359.0), new PVector(489.0, 332.0)}, {new PVector(489.0, 332.0), new PVector(465.0, 342.0)}, {new PVector(377.0, 57.0), new PVector(361.0, 92.0)}, {new PVector(361.0, 92.0), new PVector(337.0, 65.0)}, {new PVector(337.0, 65.0), new PVector(377.0, 57.0)}, {new PVector(720.0, 78.0), new PVector(718.0, 97.0)}, {new PVector(718.0, 97.0), new PVector(742.0, 100.0)}, {new PVector(742.0, 100.0), new PVector(720.0, 78.0)}, {new PVector(597.0, 510.0), new PVector(582.0, 532.0)}, {new PVector(582.0, 532.0), new PVector(625.0, 519.0)}, {new PVector(625.0, 519.0), new PVector(636.0, 497.0)}, {new PVector(636.0, 497.0), new PVector(597.0, 510.0)}, {new PVector(682.0, 416.0), new PVector(679.0, 448.0)}, {new PVector(679.0, 448.0), new PVector(702.0, 437.0)}, {new PVector(702.0, 437.0), new PVector(712.0, 400.0)}, {new PVector(712.0, 400.0), new PVector(682.0, 416.0)}, {new PVector(88.0, 324.0), new PVector(93.0, 362.0)}, {new PVector(93.0, 362.0), new PVector(116.0, 355.0)}, {new PVector(116.0, 355.0), new PVector(116.0, 295.0)}, {new PVector(116.0, 295.0), new PVector(99.0, 300.0)}, {new PVector(99.0, 300.0), new PVector(88.0, 324.0)}, {new PVector(202.0, 465.0), new PVector(180.0, 468.0)}, {new PVector(180.0, 468.0), new PVector(188.0, 483.0)}, {new PVector(188.0, 483.0), new PVector(202.0, 488.0)}, {new PVector(202.0, 488.0), new PVector(221.0, 469.0)}, {new PVector(221.0, 469.0), new PVector(202.0, 465.0)}};
	      gaits = a;
	      track = b;
	    }
	}
	
	boolean IntersectingTrack(PVector[] w) {
		PVector[] l1 = new PVector[w.length];
		arrayCopy(w, l1);
		
		if(l1[0].x == l1[1].x){
			l1[1].x += 0.1;
		}
		if(l1[0].y == l1[1].y){
			l1[1].y += 0.1;
		}
				
		for(int i = 0; i < track.length; i++){
			PVector[] l2 = track[i];
			if(l2[0].x == l2[1].x){
				l2[1].x += 0.1;
			}
			
			if(l2[0].y == l2[1].y){
				l2[1].y += 0.1;
			}
						
			if(max(l1[0].x,l1[1].x) < min(l2[0].x,l2[1].x)){
				continue;
			}
			
			float A1 = (l1[0].y-l1[1].y)/(l1[0].x-l1[1].x);
			float A2 = (l2[0].y-l2[1].y)/(l2[0].x-l2[1].x);
			float b1 = l1[0].y-A1*l1[0].x;
			float b2 = l2[0].y-A2*l2[0].x;
			
			if(A1 == A2 && b1 == b2){
				//println("x1: " + l2[0].x + ", y1: " + l2[0].y + ", x2: " + l2[1].x + ", y2: " + l2[1].y);
				//return true;
			}else if(A1 == A2){
				continue;
			}
			
			float Xa = (b2 - b1) / (A1 - A2);

			if((Xa < max( min(l1[0].x,l1[1].x), min(l2[0].x,l2[1].x) )) || (Xa > min( max(l1[0].x,l1[1].x), max(l2[0].x,l2[1].x) )) ){
				continue;
			}else{
				//println("x1: " + l2[0].x + ", y1: " + l2[0].y + ", x2: " + l2[1].x + ", y2: " + l2[1].y);
				return true;
			}
		}
		
		return false;
	}
	
	int IntersectingGait(PVector[] l1) {
		for(int i = 0; i < gaits.length; i++){
			PVector[] l2 = gaits[i];
			
			if(max(l1[0].x,l1[1].x) < min(l2[0].x,l2[1].x)){
				continue;
			}
			
			float A1 = (l1[0].y-l1[1].y)/(l1[0].x-l1[1].x);
			float A2 = (l2[0].y-l2[1].y)/(l2[0].x-l2[1].x);
			float b1 = l1[0].y-A1*l1[0].x;
			float b2 = l2[0].y-A2*l2[0].x;
			
			if(A1 == A2 && b1 == b2){
				return i;
			}else if(A1 == A2){
				continue;
			}
			
			float Xa = (b2 - b1) / (A1 - A2);
			
			if((Xa < max( min(l1[0].x,l1[1].x), min(l2[0].x,l2[1].x) )) || (Xa > min( max(l1[0].x,l1[1].x), max(l2[0].x,l2[1].x) )) ){
				continue;
			}else{
				return i;
			}
		}
		
		return -1;
	}
	
	PVector intPoint(PVector[] w){
		PVector out = null;
		PVector[] l1 = new PVector[w.length];
		arrayCopy(w, l1);
		if(l1[0].x == l1[1].x){l1[1].x += 0.01;}
		if(l1[0].y == l1[1].y){l1[1].y += 0.01;}
		for(int i = 0; i < track.length; i++){
			PVector[] l2 = track[i];
			if(l2[0].x == l2[1].x){l2[1].x+=0.1;}
			if(l2[0].y == l2[1].y){l2[1].y+=0.1;}
			if(max(l1[0].x,l1[1].x) < min(l2[0].x,l2[1].x)){
				continue;
			}
			
			float A1 = (l1[0].y-l1[1].y)/(l1[0].x-l1[1].x);
			float A2 = (l2[0].y-l2[1].y)/(l2[0].x-l2[1].x);
			float b1 = l1[0].y-A1*l1[0].x;
			float b2 = l2[0].y-A2*l2[0].x;
			
			if(A1 == A2){
				continue;
			}
			//println(A2);
			float Xa = (b2 - b1) / (A1 - A2);
			
			if((Xa < max( min(l1[0].x,l1[1].x), min(l2[0].x,l2[1].x) )) || (Xa > min( max(l1[0].x,l1[1].x), max(l2[0].x,l2[1].x) )) ){
				continue;
			}
			
			PVector P = new PVector(Xa, A1*Xa + b1);
			
			if(out == null || sq(out.x - l1[0].x) + sq(out.y - l1[0].y) > sq(P.x - l1[0].x) + sq(P.y - l1[0].y)){
				out = P;
			}
		}
		
		return out;
	}
	
	void Draw(){
		stroke(0,255,0);
		for(int i = 0; i < gaits.length; i++){
			line(gaits[i][0].x, gaits[i][0].y, gaits[i][1].x, gaits[i][1].y);
		}
		
		stroke(0);
		for(int i = 0; i < track.length; i++){
			line(track[i][0].x, track[i][0].y, track[i][1].x, track[i][1].y);
		}
	}
}

//Population Class

class Population{
	Net[] Nets = {};
	Net[][] Species = {};
	int NominalNets;
	float minDist = 3;
	float c1 = 2;
	float c2 = 2;
	float c3 = 0.4;
	int gen = 1;
	
	Population(int netNum, int Input_Nodes, int Output_Nodes){
		NominalNets = netNum;
		float[][] TempNodes = {};
		
		for(int a = 0; a < Input_Nodes; a++){
			float[] t = {a, 0, -1};
			TempNodes = (float[][])append(TempNodes, t);
		}
		
		for(int a = 0; a < Output_Nodes; a++){
			float[] t = {a+Input_Nodes, 2, -1};
			TempNodes = (float[][])append(TempNodes, t);
		}
		
		innovation_numberN = Input_Nodes + Output_Nodes;
		
		for(int i = 0; i < netNum; i++){
			float[][] TempConnections = {};
			for(int a = 0; a < Input_Nodes; a++){
				for(int b = 0; b < Output_Nodes; b++){
					float[] t = {a, Input_Nodes+b, 0, 1, a*Output_Nodes+b};
					TempConnections = (float[][])append(TempConnections, t);
				}
			}
			Nets = (Net[])append(Nets, new Net(TempNodes, TempConnections));
			Nets[Nets.length-1].Mutate();
		}
		
		innovation_numberC = 1;//Output_Nodes*Input_Nodes
		
		existingConnections = new float[Nets[0].connections.length][5];
		for(int i = 0; i < existingConnections.length; i++){
			arrayCopy(Nets[0].connections[i], existingConnections[i]);
		}
		
		existingNodes = new float[Nets[0].Nodes.length][3];
		for(int i = 0; i < existingNodes.length; i++){
			arrayCopy(Nets[0].Nodes[i], existingNodes[i]);
		}
	}
	
	void Speciate(){
		Net[][] t = {};
		Species = t;
		for(int i = 0; i < Nets.length; i++){
			boolean P = false;
			for(int s = 0; s < Species.length; s++){
				if(GDist(Species[s][0], Nets[i], c1, c2, c3) < minDist){
					Species[s] = (Net[])append(Species[s], Nets[i]);
					P = true;
				}
			}
			if(!P){
				Net[] x = {Nets[i]};
				Species = (Net[][])append(Species, x);
			}
		}
	}
	
	void DistributeFitness(){
		for(int s = 0; s < Species.length; s++){
			float TotalF = 0;
			for(int i = 0; i < Species[s].length; i++){
				TotalF += Species[s][i].fitness;
			}
			
			for(int i = 0; i < Species[s].length; i++){
				Species[s][i].fitness = Species[s][i].fitness/TotalF;
			}
		}
	}
	
	void SortNets(){
		Net[] newNets = {};
		for(int a = 0; a < Nets.length; a++){
			boolean placed = false;
			for(int b = 0; b < newNets.length; b++){
				if(Nets[a].fitness < newNets[b].fitness){
					newNets = insert(newNets, Nets[a], b+1);
					placed = true;
					break;
				}
			}
			if(!placed){newNets = (Net[])append(newNets, Nets[a]);}
		}
		Nets = newNets;
	}
	
	void RunGen(){
		/*for(int i = 0; i < Nets.length; i++){
			if(Nets[i].fitness == 0){
				Nets[i].SimulateInst(); // find fitness of all Networks that dont already have a fitness value
			}
		}*/
		
		double best = -100;
		
		for(int i = 0; i < Nets.length; i++){
			if(best < Nets[i].fitness){best = Nets[i].fitness;Best = Nets[i];}
		}
		println(best);
		
		Speciate(); // seperate Nets into species
		DistributeFitness(); // distribute fitness over all nets in a particular species
		// all networks now have their fitness finalized
		
		SortNets();
		
		Net[] toSave = {};
		println("---Gen #" + gen + "---");
		float[] range = {};
		int Number_To_Save = 20;
		for(int i = Nets.length-1; i >= Nets.length-Number_To_Save; i--){
			//println("Net " + i + ": " + Nets[i].fitness);
			toSave = (Net[])append(toSave, Nets[i]);
			if(range.length > 0){
				range = (float[])append(range, (float)(range[range.length-1]+Nets[i].fitness));
			}else{
				range = (float[])append(range, (float)Nets[i].fitness);
			}
		}


		Net[] NewNets = toSave;
		
		while(NewNets.length < NominalNets){
			//println('x');

			if(TFProb(20)){
				Net x = toSave[0]; // set up if next selection method fails
				float r = random(0, range[range.length-1]);
				for(int i = 0; i < range.length; i++){
					if(r <= range[i]){
						 x = toSave[i];
						 break;
					}
				}
				
				Net n = x.Copy();
				n.Mutate();
				
				NewNets = (Net[])append(NewNets, n);
			}else{
				Net NetA = toSave[0]; // set up if next selection method fails
				float ar = random(0, range[range.length-1]);
				for(int i = 0; i < range.length; i++){
					if(ar <= range[i]){
						 NetA = toSave[i];
						 break;
					}
				}
				Net NetB = toSave[0];
				
				if(TFProb(100)){
					float br = random(0, range[range.length-1]);
					for(int i = 0; i < range.length; i++){
						if(br <= range[i]){
							 NetB = toSave[i];
							 break;
						}
					}
				}/*else{
					int Spec = -1;
					for(int i = 0; i < Species.length; i++){
						for(int a = 0; a < Species[i].length; a++){
							if(NetA.NetNum == Species[i][a].NetNum){Spec = i;break;}
						}
						if(Spec != -1){break;}
					}

					double R = 0;
					double br = random(0,1);
					for(int i = 0; i < Species[Spec].length; i++){
						R+=Species[Spec][i].fitness;
						if(br < R){
							NetB = Species[Spec][i];
						}
					}
				}*/
				
				Net n = Breed(NetA, NetB);
				n.Mutate();
				
				NewNets = (Net[])append(NewNets, n);
			}
		}
		Nets = NewNets;
		
		//TN = round(random(0,1));
		//t = new Track(TN);
		frictionVal+=0.5;
		gen++;
	}
}

// Car Class

class Car{
	Track T;
	PVector pos;
	PVector vel = new PVector(0,0);
	float rotation;
	float Ray_Length = 300;
	float W = 10;
	float H = 5;
	boolean[] hitGates = {};
	
	Car(Track Tt, PVector Start, float rot){
		T = Tt;
		
		for(int i = 0; i < T.gaits.length; i++){
			hitGates = (boolean[])append(hitGates, false);
		}
		
		pos = Start;
		rotation = rot;
	}
	
	void Step(){
		pos.x = pos.x + vel.x;
		pos.y = pos.y + vel.y;
		
		/*float velDir = rotation;
		if(pos.x != 0 && pos.y != 0){
			velDir = atan2(vel.y, vel.x);
		}
		float velMag = sqrt(sq(vel.x) + sq(vel.y)) * 0.97 * min(max(abs(cos(rotation - velDir)),0.3),1);
		vel.x = velMag*cos(velDir);
		vel.y = velMag*sin(velDir);*/
		
		float velMag = min(sqrt(sq(vel.x) + sq(vel.y)), 7);
		vel.x = velMag*cos(rotation);
		vel.y = velMag*sin(rotation);
	}
	
	void Drive(float Acc, float rAcc){
		vel.x += Acc*cos(rotation);
		vel.y += Acc*sin(rotation);
		rotation += rAcc;
	}
	
	void Draw(boolean lines){
		if(lines){
			for(int i = 0; i < rotations.length; i++){
				stroke(0);
				strokeWeight(1);
				
				PVector[] lne = {new PVector(pos.x, pos.y), new PVector(pos.x + Ray_Length*cos(rotation + rotations[i]), pos.y + Ray_Length*sin(rotation + rotations[i]))};
				line(lne[0].x, lne[0].y, lne[1].x, lne[1].y);
				
				strokeWeight(5);
				PVector temp = T.intPoint(lne);
				if(temp != null){
					point(temp.x, temp.y);
				}
			}
			strokeWeight(1);
		}
		
		fill(255,0,0);
		noStroke();
		translate(pos.x, pos.y);
		rotate(rotation);
		rectMode(CENTER);
		rect(0,0,W,H);
		resetMatrix();
	}
	
	float[] Get_Inputs(){
		float[] out = {};
		for(int i = 0; i < rotations.length; i++){
			PVector[] lne = {new PVector(pos.x, pos.y), new PVector(pos.x + Ray_Length*cos(rotation + rotations[i]), pos.y + Ray_Length*sin(rotation + rotations[i]))};
			
			PVector temp = T.intPoint(lne);
			if(temp == null){
				out = append(out, 1);
			}else{
				out = append(out,sqrt(sq(temp.x - pos.x) + sq(temp.y - pos.y))/Ray_Length);
			}
		}
		
		//out = append(out, vel.x);
		//out = append(out, vel.y);
		//out = append(out, pos.x);
		//out = append(out, pos.y);
		
		//out = append(out, sqrt(sq(vel.x) + sq(vel.y)));
		//out = append(out, rotation);
		//out = append(out, 1);

		return out;
	}
	
	boolean touchingTrack(){
		//front right, front left, bottom left, bottom right
		PVector[] Corners = {new PVector(pos.x+W/2*cos(rotation)-H/2*sin(rotation), pos.y+W/2*sin(rotation)+H/2*cos(rotation)), new PVector(pos.x-W/2*cos(rotation)-H/2*sin(rotation), pos.y-W/2*sin(rotation)+H/2*cos(rotation)), new PVector(pos.x-W/2*cos(rotation)+H/2*sin(rotation), pos.y-W/2*sin(rotation)-H/2*cos(rotation)), new PVector(pos.x+W/2*cos(rotation)+H/2*sin(rotation), pos.y+W/2*sin(rotation)-H/2*cos(rotation))};
		//println(pos.x);
		for(int i = 0; i < 4; i++){
			PVector[] l = {Corners[i],Corners[(i+1)%4]};
			if(T.IntersectingTrack(l)){
				return true;
			}
		}
		return false;
	}
	
	boolean hitGate(){
		//front right, front left, bottom left, bottom right
		PVector[] Corners = {new PVector(pos.x+W/2*cos(rotation)-H/2*sin(rotation), pos.y+W/2*sin(rotation)+H/2*cos(rotation)), new PVector(pos.x+W/2*cos(rotation)+H/2*sin(rotation), pos.y+W/2*sin(rotation)-H/2*cos(rotation)), new PVector(pos.x-W/2*cos(rotation)+H/2*sin(rotation), pos.y-W/2*sin(rotation)-H/2*cos(rotation)), new PVector(pos.x-W/2*cos(rotation)-H/2*sin(rotation), pos.y-W/2*sin(rotation)+H/2*cos(rotation))};
		
		boolean t = true;
		for(int i = 0; i < hitGates.length; i++){
			if(!hitGates[i]){
				t = false;
				break;
			}
		}
		if(t){
			for(int i = 0; i < hitGates.length; i++){
				hitGates[i] = false;
			}
		}
		
		for(int i = 0; i < 3; i++){
			PVector[] l = {Corners[i],Corners[(i+1)%3]};
			int g = T.IntersectingGait(l);
			if(g != -1){
				if(!hitGates[g]){
					hitGates[g] = true;
					return true;
				}
			}
		}
		return false;
	}
}

// Net Class

class Net{
	float[][] Nodes; // Node # / Innovation #, Node layer(0 is input, 1 is hidden, 2 is output), divided connection
	float[][] connections; // start, end, weight, enabled(1 or 0), innovation #
	double fitness;
	int[] Start_Nodes;
	int[] lowest = {-1,-1}; // the lowest node # from the inputs, outputs
	int[] ioNum = {0,0};
	PVector[] LastPoints = new PVector[75];
	float[] storage = new float[Slen];
	//Track t = new Track(TN);
	Car c = new Car(t, new PVector(420,520), PI);
	boolean alive;
	int NetNum;
	
	Net(float[][] N, float[][] C){
		NetNum = LastNet+0;
		LastNet++;
		/*for(int i = 0; i < C.length; i++){
			println(C[i]);
		}*/
		Nodes = N;
		Sort_Nodes();
		
		int ll = (int)Nodes[Nodes.length-1][1];
		for(int i = 0 ; i < Nodes.length; i++){
			if(Nodes[i][1] == 0 && (Nodes[i][0] < lowest[1] || lowest[1] == -1)){
				lowest[0] = (int)Nodes[i][0];
			}
			
			if(Nodes[i][1] == ll && (Nodes[i][0] < lowest[1] || lowest[1] == -1)){
				lowest[1] = (int)Nodes[i][0];
			}
		}
		
		int[] x = {};
		for(int i = 0; i < Nodes.length; i++){
			if(Nodes[i][1] == 0){
				x = (int[])append(x, (int)Nodes[i][0]);
			}else{
				break;
			}
		}
		Start_Nodes = x;
		
		for(int i = 0; i < Nodes.length; i++){
			if(Nodes[i][1] == 0){ioNum[0]++;}
			if(Nodes[i][1] == 2){ioNum[1]++;}
		}
		
		connections = C;
	}
	
	void Sort_Nodes(){ // Sort nodes based on layer num
		float[][] Sorted_Nodes = {};
		for(int a = 0; a < Nodes.length; a++){
			boolean placed = false;
			for(int b = 0; b < Sorted_Nodes.length; b++){
				if(Nodes[a][1] < Sorted_Nodes[b][1] || (Nodes[a][1] == Sorted_Nodes[b][1] && Nodes[a][0] < Sorted_Nodes[b][0])){ // reverse sign to reverse order < is l to g and > is g to l
					Sorted_Nodes = insert(Sorted_Nodes, Nodes[a], b+1);
					placed = true;
					break;
				}
			}
			
			if(!placed){
				Sorted_Nodes = (float[][])append(Sorted_Nodes, Nodes[a]);
			}
		}
		Nodes = Sorted_Nodes;
	}
	
	void SortConnections(){
		float[][] out = {};
		for(int a = 0; a < connections.length; a++){
			boolean placed = false;
			for(int b = 0; b < out.length; b++){
				if(connections[a][4] < out[b][4]){ // reverse sign to reverse order < is l to g and > is g to l
					out = insert(out, connections[a], b+1);
					placed = true;
					break;
				}
			}
			
			if(!placed){
				out = (float[][])append(out, connections[a]);
			}
		}
		connections = out;
	}
	
	int getNode(int Node){
		for(int i = 0; i < Nodes.length; i++){
			if(Nodes[i][0] == Node){
				return i;
			}
		}
		return -1;
	}
	
	float[] Evaluate(float[] input){
		Sort_Nodes();
		int[][] NodeConnections = new int[Nodes.length][];
		
		for(int n = 0; n < Nodes.length; n++){
			int[] x = {}; NodeConnections[n] = x;
			for(int c = 0; c < connections.length; c++){ 
				if(connections[c][1] == Nodes[n][0]){
					NodeConnections[n] = append(NodeConnections[n], c);
				}
			}
		}
		
		float[] TempNodeValues = new float[Nodes.length];
		float[] FinalNodeValues = new float[Nodes.length];
		
		for(int i = 0; i < FinalNodeValues.length; i++){
			if(Nodes[i][1] == 0){
				FinalNodeValues[i] = input[i];
			}else{
				FinalNodeValues[i] = 0;
			}
		}
		
		int MaxRuns = 10;
		double maxDiff = 0.01;
		float[] lastOuts = new float[ioNum[1]];
		
		for(int i = 0; i < MaxRuns; i++){
			for(int n = 0; n < Nodes.length; n++){
				if(Nodes[n][1] == 0){TempNodeValues[n] = input[n];continue;}
				TempNodeValues[n] = 0;
				for(int c = 0; c < NodeConnections[n].length; c++){
					float[] con = connections[NodeConnections[n][c]];
					
					if(getNode((int)con[0]) == -1){
						println("error occured");
						println(n);
						println(NetNum);
						println(con[0]);
						for(int p = 0; p < Nodes.length; p++){
							print(Nodes[p][0] + ", ");
						}
						println();
					}else{
						TempNodeValues[n] += FinalNodeValues[getNode((int)con[0])]*con[2]*con[3];
					}
					//println(i + ": " + FinalNodeValues[(int)con[0]] + ", " + con[2] + ", " + con[3]);
				}
				TempNodeValues[n] = sigmoid(TempNodeValues[n]);
			}
			
			arrayCopy(TempNodeValues, FinalNodeValues);
			
			float[] out = new float[ioNum[1]];
			for(int n = Nodes.length-ioNum[1]; n < Nodes.length; n++){
				out[Nodes.length-n-1] = FinalNodeValues[n];
			}
			
			if(i != 0){
				boolean b = true;
				for(int o = 0; o < lastOuts.length; o++){
					if(out[o]-lastOuts[o] > maxDiff){
						b = false;
					}
				}
				if(b){
					arrayCopy(out, lastOuts);
					break;
				}
			}
			arrayCopy(out, lastOuts);
		}
		
		//int[] x = null;
		//x = concat(x,x);
		
		return lastOuts;
	}
	
	/*void SimulateInst(){
		t = new Track(TN);
		//c = new Car(t, new PVector(240,400), -PI/2 - 0.33);
		c = new Car(t, new PVector(420,520), PI);
		fitness = 0;
		alive = true;
		
		int r = 0;
		while(alive && r <= rMax){
			r++;
			float[] out = Evaluate(c.Get_Inputs());
			//println(out);
			c.Drive((out[0]-0.5)*2, (out[1]-0.5)/2);
			c.Step();
			if(c.touchingTrack()){
				alive = false;
			}
									
			if(c.hitGate()){
				fitness += 10;
			}
			//fitness -= 0.02;
			PVector avg = new PVector(0,0);
			boolean filled = true;
			for(int i = 1; i < LastPoints.length; i++){
				if(LastPoints[i] != null){
					avg.x += LastPoints[i].x - c.pos.x;
					avg.y += LastPoints[i].y - c.pos.y;
					LastPoints[i-1] = new PVector(LastPoints[i].x, LastPoints[i].y);
				}else{
					filled = false;
				}
			}
			LastPoints[LastPoints.length-1] = new PVector(c.pos.x, c.pos.y);
			if(filled && sq(avg.x/LastPoints.length) + sq(avg.y/LastPoints.length) < sq(15)){
				alive = false;
				break;
			}
			
			if(fitness < -2){
				alive = false;
				break;
			}
			
			//c.Draw(false);
		}
	}*/
	
	void SimulateStep(boolean start, boolean Draw){
		if(start){
			t = new Track(TN);
			if(TN == 0){
				c = new Car(t, new PVector(240,400), -PI/2 - 0.33);
			}else if(TN == 1 || TN == 3){
				c = new Car(t, new PVector(420,520), PI);
			}else if(TN == 2){
				c = new Car(t, new PVector(350,520), PI);
			}
			
			fitness = 0;
			alive = true;
			for(int i = 0; i < storage.length; i++){
				storage[i] = 0;
			}
		}
		
		if(alive){
			float[] out = Evaluate(concat(c.Get_Inputs(), storage));
			for(int i = 2; i < out.length; i++){
				storage[i-2] = out[i];
			}
			//println(NetNum);
			//println(out[0] + ", " + out[1]);
			//println(out);
			c.Drive((out[0]-0.5)*2, (out[1]-0.5)*4);
			c.Step();
			if(c.touchingTrack()){
				alive = false;
			}
									
			if(c.hitGate()){
				fitness += 10;
			}
			//fitness -= 0.02;
			PVector avg = new PVector(0,0);
			boolean filled = true;
			for(int i = 1; i < LastPoints.length; i++){
				if(LastPoints[i] != null){
					avg.x += LastPoints[i].x - c.pos.x;
					avg.y += LastPoints[i].y - c.pos.y;
					LastPoints[i-1] = new PVector(LastPoints[i].x, LastPoints[i].y);
				}else{
					filled = false;
				}
			}
			LastPoints[LastPoints.length-1] = new PVector(c.pos.x, c.pos.y);
			if(filled && sq(avg.x/LastPoints.length) + sq(avg.y/LastPoints.length) < sq(5)){
				alive = false;
			}
			
			if(fitness < -2){
				alive = false;
			}
			
			if(Draw){
				c.Draw(false);
			}
		}
	}
	
	void Mutate(){
		// Mutate connection
		for(int i = 0; i < connections.length; i++){
			if(TFProb(80)){
				if(TFProb(90)){
					connections[i][2] += random(-0.1,0.1);
				}else{
					connections[i][2] = random(-5,5);
				}
			}
			if(TFProb(1)){
				if(connections[i][3] == 0){connections[i][3] = 1;}else{connections[i][3] = 0;}
			}
		}
		
		//Generate New connection
		if(TFProb(20)){
			boolean fail = false;
			int InNode = (int)Nodes[round(random(-0.499, Nodes.length-0.501))][1];
			
			int OutNode = (int)Nodes[round(random(-0.499, Nodes.length-0.501))][1];
			while(OutNode != 0){
				OutNode = (int)Nodes[round(random(-0.499, Nodes.length-0.501))][1];
			}
			
			int InnNum = -1;
			for(int i = 0; i < existingConnections.length; i++){
				if(existingConnections[i][0] == InNode && existingConnections[i][1] == OutNode){
					InnNum = (int)existingConnections[i][4];
					break;
				}
			}
			
			for(int i = 0; i < connections.length; i++){
				if(InnNum == connections[i][4]){
					fail = true;
					break;
				}
			}
			
			if(!fail){
				if(InnNum == -1){
					InnNum = innovation_numberC;
					float[] x = {InNode, OutNode, random(-5,5), 1, InnNum};
					existingConnections = (float[][])append(existingConnections, x);
					innovation_numberC++;
				}
				
				float[] C = {InNode, OutNode, random(-5,5), 1, InnNum};
				connections = (float[][])append(connections, C);
			}
		}
		
		//Generate New Node
		if(TFProb(10) && connections.length > 0){
			int ToSplit = round(random(-0.499, connections.length-0.501));
			while(connections[ToSplit][3] == 0){
				ToSplit = round(random(-0.499, connections.length-0.501));
			}
			int innNum = -1;
			
			for(int i = 0; i < existingNodes.length; i++){
				if(connections[ToSplit][4] == existingNodes[i][2]){
					innNum = (int)existingNodes[i][0];
					break;
				}
			}
			
			if(innNum == -1){
				innNum = innovation_numberN;
				float[] x = {innNum, 1, connections[ToSplit][0]};
				existingNodes = (float[][])append(existingNodes, x);
				innovation_numberN++;
			}
			
			float[] n = {innNum, 1, connections[ToSplit][0]};
			Nodes = (float[][])append(Nodes, n);
			
			connections[ToSplit][3] = 0;
			float[][] Cs = {{connections[ToSplit][0]+0, innNum, 1, 1, -1},{innNum, connections[ToSplit][1]+0, connections[ToSplit][2]+0, 1, -1}};
			
			for(int i = 0; i < existingConnections.length; i++){
				if(existingConnections[i][0] == Cs[0][0] && existingConnections[i][1] == Cs[0][1]){ // test incoming connection
					Cs[0][4] = (int)existingConnections[i][4];
				}
				
				if(existingConnections[i][0] == Cs[1][0] && existingConnections[i][1] == Cs[1][1]){ // test outgoing connection
					Cs[1][4] = (int)existingConnections[i][4];
				}
			}
			
			if(Cs[0][4] == -1){
				Cs[0][4] = innovation_numberC;
				existingConnections = (float[][])append(existingConnections, Cs[0]);
				innovation_numberC++;
			}
			
			if(Cs[1][4] == -1){
				Cs[1][4] = innovation_numberC;
				existingConnections = (float[][])append(existingConnections, Cs[1]);
				innovation_numberC++;
			}
			
			connections = (float[][])append(connections, Cs[0]);
			connections = (float[][])append(connections, Cs[1]);
		}
	}
	
	Net Copy(){
		float[][] N = new float[Nodes.length][Nodes[0].length];
		float[][] C;
		if(connections.length == 0){
			C = new float[connections.length][];
		}else{
			C = new float[connections.length][connections[0].length];
		}
		
		for(int i = 0; i < Nodes.length; i++){
			arrayCopy(Nodes[i], N[i]);
		}
		
		for(int i = 0; i < connections.length; i++){
			arrayCopy(connections[i], C[i]);
		}
		
		return new Net(N, C);
	}
}
