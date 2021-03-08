float[][] points = {};
Text = document.getElementById("output-svg").value;

void setup(){
	size(800, 600);

}

void draw(){
	background(150);

	Text = document.getElementById("output-svg").value;
	name = "<%= name %>";

	//if(points.length == 0 && Text.length > 0){
	//println(document.getElementById("run-button").value);

	//if(keyPressed){
	//	println(document.getElementById("svg-render").innerHTML);
	//	loadImage(flatten(document.getElementById("svg-render").innerHTML), "svg");
		//image(I, 300, 300);
	//}


	//}
	//println(points.length);
	stroke(255,0,0);
	for(int i = 0; i < points.length; i++){
		//println(points[i][0]);
		line(points[i][0]+100, -points[i][1]+100, points[(i+1)%points.length][0]+100, -points[(i+1)%points.length][1]+100);
	}

	fill(0);
	text(Text, 100, 100);
	text(name, 100, 300);
}

document.getElementById("run-button").onclick = function() {
	float[][] r = {};
	points = r;
	int p = 0;
	String num = "";
	float[] t = new float[2];
	for(int s = 0; s < Text.length; s++){
		char ch = Text.charAt(s);
		if(ch == ","){
			if(p == 0){
				t[0] = float(num);
				p++;
			}else{
				t[1] = float(num);
				p = 0;
				points = (float[][])append(points, t);
				t = new float[2];
				//println(points.length + " " + points);
			}
		num = "";
		}else{
			num += ch;
		}
	}
};