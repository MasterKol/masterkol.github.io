String[] wordList;
Board b;

void setup(){
	size(700, 700);
	
	wordList = loadStrings("word_list.txt");
	
	b = new Board();
}

int alphaWidth = 200;

void draw(){
	background(30);
	stroke(255);
	line(alphaWidth, 0, alphaWidth, height);
	
	b.drawBoard();
}

class Board {
	int[] letterStates;
	char[][] letters = {};
	int[][] states = {}; // 0 = default, 1 = wrong, 2 = right letter, 3 = right space
	int line = 0;
	int head = 0;
	
	char[] word;
	
	int gameState = 0; // playing = 0, won = 1, lost = 2

	int errorTimer = 0;
  String errorMessage = "";
	
	Board(){
		reset();
	}
	
	void reset(){
		gameState = 0;
		word = wordList[floor(random(0, wordList.length))].toCharArray();

		letterStates = new int[26];
		for(int i = 0; i < 26; i++){
			letterStates[i] = 0;
		}
		
		letters = new char[0][];
		states = new int[0][];
		line = 0;
		head = 0;
		
		addrow();
		//println(word);
	}
	
	void input(int code){
		if(gameState != 0){return;}
		if(code >= 65 && code <= 90 && head < 5){
			letters[line][head] = (char)code;
			head++;
		}
		if(head > 0 && (code == BACKSPACE || code == DELETE)){
			letters[line][head-1] = ' ';
			head--;
		}
		if(code == 10 || code == 13){
			if(head < 5){
        showError("Word must be 5 letters");
      }else{
        inputRow();
      }
		}
	}
	
	void inputRow(){
		// check if word is in word list, if not return
		if(!isWord(charArrToString(letters[line]))){
			showError("Word is not in word List");
			return;
		}
		
		boolean won = true;
		for(int i = 0; i < 5; i++){
			if(letters[line][i] == word[i]){
				states[line][i] = 3;
				continue;
			}
			won = false;
			boolean broken = false;
			for(int w = 0; w < 5; w++){
				if(letters[line][i] == word[w]){
					states[line][i] = 2;
					broken = true;
					break;
				}
			}
			if(broken){continue;}
			states[line][i] = 1;
		}
		
		int l;
		for(int i = 0; i < 5; i++){
			l = (int)letters[line][i] - 65;
			letterStates[l] = max(letterStates[l], states[line][i]);
		}
		
		if(won){
			gameState = 1;
			return;
		}
		
		if(line == 5){
			gameState = 2;
			return;
		}
		
		addrow();
		head = 0;
		line++;
	}
	
	void addrow(){
		char[] newRow = {' ', ' ', ' ', ' ', ' '};
		letters = (char[][])append(letters, newRow);
		
		int[] newStates = {0,0,0,0,0};
		states = (int[][])append(states, newStates);
	}
	
	void drawBoard(){
		pushMatrix();
		translate(alphaWidth, 0);

		// display error
	    if(errorTimer > 0){
	      textAlign(CENTER, CENTER);
	      fill(255, 0, 0, errorTimer * 255 / 50);
	      textSize(40);
	      text(errorMessage, (width - alphaWidth) / 2, height - 50);
	      errorTimer--;
	    }
		
		float size = 80;
		
		textAlign(CENTER, CENTER);
		textSize(size * 0.8);
		
		stroke(255);
		translate((width - alphaWidth - 5 * size) / 2, (height - 6 * size) / 2);
		for(int y = 0; y < 6; y++){
			for(int x = 0; x < 5; x++){
				if(y <= line){
					if(states[y][x] == 0){
						noFill();
					}else if(states[y][x] == 1){
						fill(100);
					}else if(states[y][x] == 2){
						fill(200, 200, 0);
					}else if(states[y][x] == 3){
						fill(0, 200, 0);
					}
					
					if(y == line){
						stroke(100);
						strokeWeight(1);
						rect(0.07 * size, 0.07 * size, size * 0.86, size * 0.86);
					}else{
						noStroke();
						rect(0.06 * size, 0.06 * size, size * 0.88, size * 0.88);
					}
					
					
					fill(255);
					text(String.fromCharCode(letters[y][x]), size * 0.5, size * 0.5);
				}else{
					noFill();
					stroke(100);
					strokeWeight(1);
					rect(0.07 * size, 0.07 * size, size * 0.86, size * 0.86);
				}
				
				translate(size, 0);
			}
			translate(-size * 5, size);
		}
		popMatrix();
		drawLetters();
		drawEndGame();
	}
	
	void drawLetters(){
		float size = min((float)height / 10, (float)alphaWidth / 3) * 0.9;
		pushMatrix();
		translate((alphaWidth - size * 3) / 2, (height - size * 10) / 2);
		textAlign(CENTER, CENTER);
		textSize(size * 0.8);
		for(int i = 0; i < 3; i++){
			for(int l = 10 * i; l < min(26, 10 * (1 + i)); l++){
				if(letterStates[l] == 0){
					noFill();
				}else if(letterStates[l] == 1){
					fill(100);
				}else if(letterStates[l] == 2){
					fill(200, 200, 0);
				}else if(letterStates[l] == 3){
					fill(0, 200, 0);
				}
				stroke(100);
				strokeWeight(1);
				rect(0.05 * size, 0.05 * size, size * 0.9, size * 0.9);
				
				fill(255);
				text(String.fromCharCode(l + 65), size * 0.5, size * 0.5);
				
				translate(0, size);
			}
			translate(size, -size * 10);
		}
		popMatrix();
	}
	
	void drawEndGame(){
		if(gameState == 0){return;}
		pushMatrix();
		
		translate(alphaWidth + 50, 250);
		
		fill(0, 0, 0, 200);
		rect(0, 0, width - alphaWidth - 100, height - 500, 10);
		
		if(gameState == 1){
			fill(255);
			textSize(50);
			text("You Won!", (width - alphaWidth - 100) / 2, 35);
			textSize(20);
			text("The word was " + word.join("") + ".\nIt took you " + (line+1) + " guess" + ((line == 0) ? "" : "es") + " to get the word", (width - alphaWidth - 100) / 2, 100);
		}else if(gameState == 2){
			fill(255);
			textSize(50);
			text("You Lost!", (width - alphaWidth - 100) / 2, 35);
			textSize(20);
			text("The word was " + word.join("") + ".", (width - alphaWidth - 100) / 2, 100);
		}
		
		noStroke();
		fill(100, 200, 100);
		rect((width - alphaWidth - 300) / 2, 150, 200, 40, 10);
		
		fill(255);
		textSize(35);
		textAlign(BASELINE);
		text("Reset", (width - alphaWidth - 200) / 2, 180);
		
		if(mousePressed && mouseX > screenX((width - alphaWidth - 300) / 2, 150) && mouseY > screenY((width - alphaWidth - 200) / 2 - 50, 150)
										&& mouseX < screenX((width - alphaWidth + 100) / 2, 190) && mouseY < screenY((width - alphaWidth + 100) / 2, 190)){
			reset();
		}
		
		popMatrix();
	}

	void showError(String message){
    errorMessage = message;
    errorTimer = 200;
  }
}

/*void keyPressed(){
	console.log(keyCode);
	b.input(keyCode);
}*/

document.getElementById("html").addEventListener('keydown', function(event){
	var key = event.keyCode;
	console.log(key);
	b.input(key);
});

String charArrToString(char[] input){
	String out = "";
	for(int i = 0; i < input.length; i++){
		out += String.fromCharCode(input[i]);
	}
	return out;
}

boolean isWord(String word){
	for(int i = 0; i < wordList.length; i++){
		//console.log(word, wordList[i], word.equals(wordList[i]));
		if(word.equals(wordList[i])){
			return true;
		}
	}

	return false;
}