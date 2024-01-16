var loadProgramButton = document.getElementById("LoadProgramButton");
var tapeInputArea = document.getElementById("TapeInputArea");
var resetButton = document.getElementById("ResetButton");
var tapeButton = document.getElementById("TapeButton");
var canvas = document.getElementById("cnvs");
var pageBody = document.getElementById("body");
var pausedInputs = document.getElementById("PausedInputs");
var playingInputs = document.getElementById("PlayingInputs");

Machine m;

color backgroundColor = color(50);
color outlineColor = color(205);
color textColor = color(205);
int outlineWidth = 1;

int speedScale = 2;

int sqSize = 50;

void setup(){
	size(screen.width, 100);
	frameRate(30);

	m = new Machine();
	updateCanvasSize();
}

void draw(){
	if(!(m.paused || m.halted)){
		redraw();
	}
}

void redraw(){
	background(backgroundColor);
	
	if(m != null){
		m.Update();
		m.Draw();
	}
}

void keyPressed(){
	if(key >= '0' && key <= '9'){
		m.speed = ((int)key - 48) * 10;
	}
	
	if(key == ' '){
		m.speed = 0;
		m.transitionTimer = 0;
		for(int i = 0; i < 50; i++){
			m.Step();
		}
	}
	
	if(key == 'j' && m.transitionTimer <= 10){
		m.transitionTimer = 0;
		m.speed = 3;
		for(int i = 0; i < 500 && !m.current.name.equals("MoveDirSkip"); i++){
			m.Step();
		}
	}
}

void keyReleased(){
	m.speed = 1;
}

class Machine {
	boolean isMeta = false;
	Map CharMap; // values represent ascii chars, num -> char
	Map CharMapRev; // values represent ascii chars, char -> num
	int tapeNum;
	int[] position;
	int[] dir;
	State[] states;
	State current;
	State starting;
	
	int[][] tapes;
	int transitionTimer = 0;
	int waitTime = 50;
	int speed = 1;
	
	boolean halted = false;
	boolean paused = false;
	
	Machine(){
		CharMap = new Map(); // setup basic machine that just halts immediately
		CharMap.set(0, " ");
		CharMapRev = new Map();
		CharMap.set(" ", 0);
		tapeNum = 1;
		InitializeTape();
		current = new State("HALT");
	  }
	
	Machine(String programName) {
		loadProgram(this, programName);
		//InitializeTape();
	}
	
	void InitializeTape(){
		tapes = new int[tapeNum][100];
		dir = new int[tapeNum];
		position = new int[tapeNum];
		for(int i = 0; i < position.length; i++){
			position[i] = tapes[0].length / 2;
		}
	}
	
	int borderSize = 10;
	int lengthToAdd = 50;
	void updateTapes(){
		for(int i = 0; i < tapes.length; i++){
			if(position[i] <= borderSize){
				position[i] += lengthToAdd;
				int[] t = new int[tapes[i].length + lengthToAdd];
				arrayCopy(tapes[i], 0, t, 50, tapes[i].length);
				tapes[i] = t;
			}
			if(tapes[i].length - position[i] <= borderSize){
				int[] t = new int[tapes[i].length + lengthToAdd];
				arrayCopy(tapes[i], 0, t, 0, tapes[i].length);
				tapes[i] = t;
			}
		}
	}
	
	void drawTape(int num){
		stroke(outlineColor);
		strokeWeight(outlineWidth);
		textSize(sqSize * 1.1);
		textAlign(CENTER, CENTER);
		
		int squares_on_screen = ceil(width / (float)sqSize); // number of squares on screen
		float offset = dir[num] * constrain((float)transitionTimer / (100 - waitTime) - 0.5, 0, 1) * sqSize; // offset in animation
		pushMatrix();
		
		translate(width/2 - sqSize / 2 + offset, 0);

		int tapeOffset = floor(squares_on_screen / 2) + 1;
		float p = -sqSize * tapeOffset; // center of current square
		int b = position[num] - tapeOffset; // index in tape to display as text
		while(p <= width/2 + sqSize){
			noFill();
			rect(p, 0, sqSize, sqSize);
			
			if(0 < b && b < tapes[num].length){
				fill(textColor);
				text(CharMap.get(tapes[num][b]), p + 0.5 * sqSize, sqSize * 0.5);
			}
			b++;
			p += sqSize;
		}
		
		translate(-offset, 0);
		
		// draw selected square highlight
		stroke(219, 172, 31);
		strokeWeight(3);
		noFill();
		rect(0, 0, sqSize, sqSize);
		popMatrix();
	}
	
	void Draw(){
		//float sqSize = (float)width / squares_on_screen + outlineWidth - 1;
		
		translate(0, 20);
		for(int i = 0; i < tapeNum; i++){
			drawTape(i);
			translate(0, sqSize * 1.1);
		}
		resetMatrix();

		textAlign(CENTER, CENTER);
		textSize(30);
		text(current.name, width / 2, height - 20);

		if(halted){ fill(255, 0, 0);	}else
		if(paused){ fill(255, 255, 0);	}
		else{ fill(0, 255, 0);			}
		
		noStroke();
		rect(0, height - 20, 20, 20);
		
		/*fill(0);
		textSize(20);
		text(current.name, 100, 500);*/
	}
	
	void Update(){
		if(halted || paused){return;}
		if(transitionTimer <= 0){
			transitionTimer += 100;
			Step();
		}else{
			transitionTimer -= speed * speedScale;
		}
	}
	
	void Step(){
		if(halted || paused){return;}

		Trans selected = null;
		int[] read = new int[tapeNum];

		for(int i = 0; i < tapeNum; i++){
			read[i] = tapes[i][position[i]];
		}

		for(Trans T : current.transitions){
			if(T.isMatch(read)){
				selected = T;
				break;
			}
		}

		if(selected == null){
			HaltMachine();
			return;
		}

		dir = selected.dir;
		for(int i = 0; i < tapeNum; i++){
			if(selected.write[i] != -1){
				tapes[i][position[i]] = selected.write[i];
			}
			position[i] += selected.dir[i];
		}
		current = selected.dest;
		
		updateTapes();

		if(current.name.equals("HALT")){
			HaltMachine();
			return;
		}
	}

	void HaltMachine(){
		PauseGUI();
		halted = true;
		transitionTimer = 0;
	}
	
	void LoadNumber(int number, int tapeNum, int zerochar, int onechar){
		int log2 = floor(log(max(1, number)) / log(2) + 1);
		for(int i = 0; i < log2; i++){
			tapes[tapeNum][position[tapeNum] + i] = ((number >> (log2 - i - 1)) % 2 == 0) ? zerochar : onechar;
		}
	}
	
	void LoadString(String str, int tapeNum){
		if(str.length() > tapes[tapeNum].length - position[tapeNum] - 1){
			tapes[tapeNum] = new int[tapes[tapeNum].length - position[tapeNum] + str.length() + 10];
		}
		
		for(int i = 0; i < str.length(); i++){
			// console.log(str.charAt(i));
			if(!CharMapRev.has(str.charAt(i))){
				console.log("\"" + str.charAt(i) + "\" at position " + i + " in the string is not a valid character");
				throw(new Error("\"" + str.charAt(i) + "\" at position " + i + " in the string is not a valid character"));
			}
			tapes[tapeNum][position[tapeNum] + i] = CharMapRev.get(str.charAt(i));
		}
	}
}

boolean verbose = true;
void loadProgramStrings(Machine m, String[] contents) throws SyntaxError {
	Line[] lines = preProcess(contents);
	
	if(lines.length < 0){
		throw(new SyntaxError("No content in file"));
	}
	
	try {
		m.tapeNum = parseInt(lines[0].str.trim());
	}catch(NumberFormatException e){
		throw(new SyntaxError("Invalid number", lines[0].lineNum));
	}
	
	if(m.tapeNum <= 0){
		throw(new SyntaxError("Tape num must be positive and nonzero", lines[0].lineNum));
	}
	
	if(lines.length <= 1){
		throw(new SyntaxError("No starting state specified"));
	}
	
	String startingState = lines[1].str.trim();
	
	if(lines.length <= 2){
		throw(new SyntaxError("Machine chars not specified"));
	}
	
	m.CharMap = new Map();
	String[] Chrs = lines[2].str.split(",");
	for(int i = 0; i < Chrs.length; i++){
		String trimmed = Chrs[i].trim();
		if(trimmed.length() == 0){
			throw(new SyntaxError("No char between commas", lines[2].lineNum));
		}
		if(trimmed.length() > 1){
			throw(new SyntaxError("Chars must be comma seperated", lines[2].lineNum));
		}
		char Char = trimmed.charAt(0);
		if(Char == "*" || Char == "[" || Char == "]"){
			throw(new Error(Char + " is a reserved character"));
		}
		m.CharMap.set(Chrs[i].trim().charAt(0), i);
	}
	if(verbose){console.log(m.CharMap);}
	
	// first pass to create all states
	Map stateMap = new Map();
	
	for(int i = 3; i < lines.length; i++){
		if((char)lines[i].str.charAt(0) == "["){continue;}
		String name = lines[i].str.trim();
		stateMap.set(name, new State(name, lines[i].lineNum));
	}
	
	if(verbose){console.log(stateMap.keys());}
	m.states = new State[stateMap.size];
	int stateInd = 0;
	stateMap.forEach(function(v, k){
		m.states[stateInd++] = v;
	});
	
	// set current state from list of states
	if(!stateMap.has(startingState)){
		throw(new SyntaxError("Starting state does not exist", lines[1].lineNum));
	}
	m.starting = stateMap.get(startingState);
	m.current = m.starting;
	
	// second pass to create transitions between states
	State currentProcessing = null;
	for(int i = 3; i < lines.length; i++){
		if(lines[i].str.charAt(0) != "["){
			currentProcessing = stateMap.get(lines[i].str);
			continue;
		}else if(currentProcessing == null){
			throw(new SyntaxError("transition was not preceeded by a state", lines[i].lineNum));
		}
		
		String[] regions = lines[i].str.split("]");
		
		if(regions.length != 4){
			throw(new SyntaxError("Invalid transition, should be of the form [read, chars] [write, chars] [directions] nextState"));
		}
		
		for(int j = 0; j < regions.length; j++){regions[j] = regions[j].trim();}
		
		String stateName = regions[3];
		
		if(!stateMap.has(stateName)){
			throw(new SyntaxError("Invalid state: \"" + stateName + "\"", lines[i].lineNum));
		}
		
		/*String[] startStrs = regions[0].substring(1, regions[0].length()).split(",");
		if(startStrs.length != m.tapeNum){throw(new SyntaxError(String.format("Not enough chars in read, expected %d got %d", m.tapeNum, startStrs.length), lines[i].lineNum));}
		int[] startChars = new int[m.tapeNum];
		
		String[] writeStrs = regions[1].substring(1, regions[1].length()).split(",");
		if(writeStrs.length != m.tapeNum){throw(new SyntaxError(String.format("Not enough chars in write, expected %d got %d", m.tapeNum, writeStrs.length), lines[i].lineNum));}
		int[] writeChars = new int[m.tapeNum];
		
		String[] dirStrs = regions[2].substring(1, regions[2].length()).split(",");
		if(dirStrs.length != m.tapeNum){throw(new SyntaxError(String.format("Not enough chars in direction, expected %d got %d", m.tapeNum, dirStrs.length), lines[i].lineNum));}
		int[] dirChars = new int[m.tapeNum];
		
		for(int j = 0; j < m.tapeNum; j++){
			String st = startStrs[j].trim();
			char startChar = intFromString(startStrs[j], lines[i].lineNum, m.CharMap, "read");
			char writeChar = intFromString(writeStrs[j], lines[i].lineNum, m.CharMap, "write");
			char dirChar = intFromString(dirStrs[j], lines[i].lineNum, null, "dir");
			
			if(dirChar != "L" && dirChar != "R" && dirChar != "N"){
				throw(new SyntaxError("'" + dirChar + "' is not a valid direction, use only L, R, or N", lines[i].lineNum));
			}
			
			startChars[j] = (startChar == "*") ? (-1) : m.CharMap.get(startChar);
			writeChars[j] = (writeChar == "*") ? (-1) : m.CharMap.get(writeChar);
			dirChars[j] = (dirChar == "L") ? -1 : ((dirChar == "R") ? 1 : 0);
		}
		
		currentProcessing.transitions.add(new Trans(startChars, writeChars, dirChars, stateMap.get(stateName), lines[i].lineNum));*/
		int[] startChars = processReadWriteString(regions[0], lines[i].lineNum, m, "read");
		int[] writeChars = processReadWriteString(regions[1], lines[i].lineNum, m, "write");
		
		String[] dirStrs = regions[2].substring(1, regions[2].length()).split(",");
		if(dirStrs.length > m.tapeNum){
			throw(new SyntaxError(String.format("Too many chars in direction, expected %d got %d", m.tapeNum, dirStrs.length), lines[i].lineNum));
		}
		int[] dirChars = new int[m.tapeNum];
		
		for(int j = 0; j < dirStrs.length; j++){
			dirChars[j] = intFromString(dirStrs[j], lines[i].lineNum, null, "dir");

			if(dirChars[j] != "L" && dirChars[j] != "R" && dirChars[j] != "N"){
				throw(new SyntaxError("'" + (char)dirChars[j] + "' is not a valid direction, use only L, R, or N", lines[i].lineNum));
			}

			dirChars[j] = (dirChars[j] == "L") ? -1 : ((dirChars[j] == "R") ? 1 : 0);
		}
		
		currentProcessing.transitions.add(new Trans(startChars, writeChars, dirChars, stateMap.get(stateName), lines[i].lineNum));
	}
	
	// reverse char map
	m.CharMapRev = m.CharMap;
	Map temp = new Map();
	m.CharMap.forEach(function(v, k){
		temp.set(v, k);
	});
	m.CharMap = temp;
	m.CharMapRev.delete(m.CharMap.get(0));
	m.CharMapRev.set(" ", 0);
	m.CharMap.set(0, " ");

	m.InitializeTape();
}

int[] processReadWriteString(String s, int lineNum, Machine m, String region){
	String[] parts = s.substring(1, s.length()).split(",");
	if(parts.length > m.tapeNum){
		throw(new SyntaxError(String.format("Too many chars in " + region + ", expected %d got %d", m.tapeNum, parts.length), lineNum));
	}
	int[] out = new int[m.tapeNum];
	for(int i = 0; i < m.tapeNum; i++){out[i] = -1;}

	for(int j = 0; j < parts.length; j++){
		String st = parts[j].trim();
		out[j] = intFromString(parts[j], lineNum, m.CharMap, "read");

		out[j] = (out[j] == "*") ? (-1) : m.CharMap.get(out[j]);
	}

	return out;
}

char intFromString(String str, int lineNum, Map charMap, String section) throws SyntaxError {
	String trimmed = str.trim();
	if(trimmed.length() != 1){
		throw(new SyntaxError("Values in " + section + " must be comma seperated", lineNum));
	}
	char out = trimmed.charAt(0);
	if(charMap != null && out != "*" && !charMap.has(out)){
		throw(new SyntaxError("Char '" + out + "' is not a valid character", lineNum));
	}
	return out;
}

Line[] preProcess(String[] rawLines) throws SyntaxError {
	ArrayList<Line> procLines = new ArrayList<Line>();
	
	// pre processing to remove comments and empty lines
	boolean inBlockComment = false;
	int blockCommentStartRow = -1;
	int blockCommentStartCol = -1;
	for(int i = 0; i < rawLines.length; i++){
		// end block comments
		String line = rawLines[i] + " "; // append a space so that .split always works in the expected way
		
		// process line comments
		if(line.contains("//")){
			line = line.split("//", 2)[0];
		}
		
		// remove block comments
		int startLength = line.length();
		boolean hasEnd = line.contains("*/");
		if(inBlockComment && !hasEnd){ // in a block comment and there is no comment end token on this line, continue to next
			continue;
		}
		if(inBlockComment && hasEnd){ // line starts in a block comment, cancel it with the first end comment token
			inBlockComment = false;
			line = line.split("\\*/", 2)[1];
		}
		
		while(line.contains("*/")){ // remove all block comments that are only on this line
			int startPos = line.indexOf("/*");
			int endPos = line.indexOf("*/");
			
			if(startPos == -1 || startPos > endPos){ // no start or end is before start, either way this is an error
				int truePos = endPos + startLength - line.length();
				throw(new SyntaxError("Unexpected end of block comment", i, truePos, 2));
			}
			String[] startSplit = line.split("/\\*", 2);
			String endOfLine = startSplit[1].split("\\*/", 2)[1];
			
			line = startSplit[0] + endOfLine;
		}
		
		if(line.contains("/*")){ // start new block comment that continues off the end of this line
			inBlockComment = true;
			blockCommentStartRow = i;
			blockCommentStartCol = line.indexOf("/*") + startLength - line.length();
			line = line.split("/\\*", 2)[0];
		}
		
		line = line.trim();
		if(line.length() == 0){
			continue;
		}
		procLines.add(new Line(rawLines[i], line, i));
	}
	
	if(inBlockComment){
		throw new SyntaxError("Block comment has no end", blockCommentStartRow, blockCommentStartCol, 2);
	}
	
	return procLines.toArray(new Line[0]);
}

class Line {
	String raw, str;
	int lineNum;
	Line(String raw, String str, int lineNum){
		this.raw = raw;
		this.str = str;
		this.lineNum = lineNum;
	}
}

class SyntaxError extends Error {
	int lineNum = -1;
	int start = 0;
	int len = -1;
	String message;
	SyntaxError(String message){
		this.message = message;
	}
	
	SyntaxError(String message, int lineNum){
		this.message = message;
		this.lineNum = lineNum;
	}
	
	SyntaxError(String message, int lineNum, int start, int len){
		this.message = message;
		this.lineNum = lineNum;
		this.start = start;
		this.len = len;
	}
	
	String getMessage(){
		String out = message;
		if(lineNum != -1){
			out += "\nLine: " + lineNum;
		}
		if(start != -1){
			out += " ; Column: " + start;
		}
		return out;
	}

	void DisplayError(){
		// move cursor to line
		editor.gotoLine(lineNum + 1, start, true);
		
		// put error in gutter
		editor.getSession().setAnnotations([{
		  row: lineNum,
		  column: start,
		  text: message,
		  type: "error"
		}]);

		// highlight line
		var Range = ace.require('ace/range').Range;

		if(len > 0){
			editor.session.addMarker(new Range(lineNum, start, lineNum, start + len), "myMarker", "text");
		}else{
			editor.session.addMarker(new Range(lineNum, start, lineNum, start + len), "myMarker", "fullLine");
		}
	}
}

class State{
	String name;
	ArrayList<Trans> transitions = new ArrayList<Trans>();
	int lineNum = -1;
	
	State(String name){
		this.name = name;
	}
	
	State(String name, int lineNum){
		this.name = name;
		this.lineNum = lineNum;
	}
}

class Trans {
	int[] sym;
	int[] dir;
	int[] write;
	int lineNum;
	
	State dest;
	Trans(int[] sym, int[] write, int[] dir, State dest){
		this.sym = sym;
		this.write = write;
		this.dir = dir;
		this.dest = dest;
	}
	
	Trans(int[] sym, int[] write, int[] dir, State dest, int lineNum){
		this.sym = sym;
		this.write = write;
		this.dir = dir;
		this.dest = dest;
		this.lineNum = lineNum;
	}
	
	boolean isMatch(int[] intp){
		for(int i = 0; i < intp.length; i++){
			if(sym[i] == -1){continue;} // matching any
			if(intp[i] != sym[i]){
				return false;
			}
		}
		return true;
	}
}

void setGlobalMachine(Machine nm){
	if(m == null || nm.tapeNum != m.tapeNum){
		tapeInputArea.rows = nm.tapeNum;
		tapeInputArea.value = "\n".repeat(nm.tapeNum-1);
	}

	m = nm;
	updateCanvasSize();
}

void updateCanvasSize(){
	canvas.width = pageBody.offsetWidth;
	width = canvas.width;
	// console.log(window.innerWidth);
	// console.log(width);
	if(m == null){
		canvas.height = 65 + sqSize;
	}else{
		canvas.height = 65 + sqSize * (1.1 * (m.tapeNum - 1) + 1);
	}
	height = canvas.height;
	redraw();
}

String[] getEditorContent(){
	return editor.getValue().split("\n");
}

function loadProgramButtonFunction(){
	Machine nm = new Machine();
	try{
		loadProgramStrings(nm, getEditorContent());
		nm.paused = true;
		setGlobalMachine(nm);
	} catch(SyntaxError e){
		console.log(e);
		e.DisplayError();
	}
}

void throwError(SyntaxError error){ // errorLine, message
	
}

function playPauseFunction(){
	if(m == null || m.halted){
		PauseGUI();
		return;
	}

	m.paused = !m.paused;
	if(m.paused){
		PauseGUI();
	}else{
		PlayGUI();
	}
}

void PlayGUI(){
	console.log("played");
	pausedInputs.style.display = "none";
	playingInputs.style.display = "flex";
}

void PauseGUI(){
	console.log("paused");
	pausedInputs.style.display = "flex";
	playingInputs.style.display = "none";
}

function resetMachineFunction(){

}

function setTapeFunction(){
	if(m == null){return;}
	// console.log(tapeInputArea.value);
	try{
		String[] parts = tapeInputArea.value.split("\n");

		for(int i = 0; i < min(m.tapeNum, parts.length); i++){
			m.LoadString(parts[i], i);			
		}

		// m.LoadString(tapeInputArea.value, 0);
		redraw();
	}catch(Error e){
		console.log(e);
	}
}

String tapeInputValue = "";
function tapeInputChange(){
	String newValue = tapeInputArea.value;
	int newNumLines = newValue.split("\n").length;
	int oldNumLines = tapeInputValue.split("\n").length;
	// console.log(newNumLines, oldNumLines);

	if(newNumLines <= m.tapeNum || oldNumLines > m.tapeNum){ // (new is valid) or (old is already broken, just set old to new and move on)
		tapeInputValue = newValue;
		return;
	}

	// new is invalid, old is valid
	if(newValue.length() - tapeInputValue.length() == 1){ // only one character was added that made this line invalid, force back to old
		tapeInputArea.value = tapeInputValue;
		return;
	}

	// new is invalid but multiple chars were added, just allow input
	tapeInputValue = newValue;
}

addEventListener("resize", (event) => {
	updateCanvasSize()
});

/*var loadProgramButton = document.getElementById("LoadProgramButton");
var playPauseButton = document.getElementById("PlayPauseButton");
var tapeInputArea = document.getElementById("TapeInputArea");
var tapeButton = document.getElementById("TapeButton");*/

// set button callbacks

tapeInputArea.oninput = tapeInputChange;
loadProgramButton.onclick = loadProgramButtonFunction;
document.getElementById("PlayButton").onclick = playPauseFunction;
document.getElementById("PauseButton").onclick = playPauseFunction;
tapeButton.onclick = setTapeFunction;
// resetButton.onclick = resetMachineFunction;