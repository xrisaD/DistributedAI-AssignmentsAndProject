/**
* Name: FestivalSpeakers
* Based on the internal empty template. 
* Author: Chrysa, Ilias
* Tags: 
*/


model FestivalSpeakers

global {
	int grid <- 4;
	int queens <- grid;
	float gridSize <- 100/grid;
	init {
	
	
	
		create Queen number:queens;
		loop counter from: 0 to: queens - 1 {
        	Queen q <- Queen[counter];
        	q <- q.setY(counter);
        	if (counter>0) {
        		q <- q.setPred(Queen[counter - 1]);
        	}
        }
        loop counter from: 0 to: queens-2 {
        	Queen q <- Queen[counter];
        	q <- q.setSucc(Queen[counter+1]);
        }
        Queen q <- Queen[0];
        q <- q.start();
	}
	
}

species Queen skills: [fipa] {
	Queen pred <- nil;
	Queen succ <- nil;
	int x <- -1;
	int y <- -1;
	bool systemStable <- false;
	list<int> availableX <- [];
	
	init {
		do initializeList;
	}
	
	action initializeList {
		loop i over: range(0, grid-1) {
			add i to: availableX;
		}
	}
	action setY (int pointY) {
		y <- pointY;
	}
	
	action setSucc (Queen succQueen) {
		succ <- succQueen;
	}
	
	action setPred (Queen predQueen) {
		pred <- predQueen;
	}
	
	action start {
		x <- rnd(0, grid-1);
		do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'inform', contents :: ["start"]);
			
	}

	
	reflex getInform when: !empty(informs) and !systemStable {
		loop i over: informs {
			loop content over: i.contents {
				if (content = "start") {
					do choocePointAndAsk;
				} else if (content = "systemStable") {
					systemStable <- true;
					if (pred != nil) {
						do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'inform', contents :: ["systemStable"]);
					}
				}
				
			}
		}
	}
	
	action choocePointAndAsk {
		// choose a point
		int index <- rnd(0, length(availableX)-1);
		x <- availableX[index];
		write "I am "+y+" and I choose "+x;
		if (pred != nil) {
			// ask your predecessor if this point is available
			do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["ask", x, y]);	
		} else {
			// we are the first one so we don't have to ask sb
			do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'inform', contents :: ["start"]);	
		}
	}
	
	
	reflex getCpf when: !empty(cfps) and !systemStable {
		loop i over: cfps {
			list con <- i.contents;
			if (con[0] = "ask") {
				write "I am "+y+" and I receive an [ASK] message from my succ";
				// check point
				int succX <- con[1];
				int succY <- con[2];
				bool isOk <- checkPoint(succX, succY);
				write "I am "+y+" and isOk value is: "+isOk;
				if (isOk and pred != nil) {
					// ask predecessor
					write "is Ok and not nill";
					do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["ask", succX, succY]);
				} else if (isOk and pred = nil) {
					write "is Ok and nill";
					do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["accept", succX, succY]);
				}else {
					write "not ok";
					do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["reject", succX, succY]);
				}
			} else if (con[0] = "reject"){
				int predX <- con[1];
				int predY <- con[2];
				
				if (predY != y) {
					do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["reject", predX, predY]);
				} else {
					// rejected point
					write "reject";
					// remove this point and choose a different point
					remove x from: availableX;
					if (length(availableX) > 0) {
						do choocePointAndAsk;
					} else {
						// init again the list
						do initializeList;
						// you need to reorder the predecessor
						if (pred != nil) {
							do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["reorder"]);	
						} else {
							do choocePointAndAsk;
						}
					}
					
				}
			} else if (con[0] = "accept") {
				
				if(succ = nil) {
					systemStable <- true;
					do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'inform', contents :: ["systemStable"]);
				}
				else {
					write "accept";
					int predX <- con[1];
					int predY <- con[2];
					
					if (predY != y) {
						// send accept to the successor 
						do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["accept", predX, predY]);
					} else {
						// start the next queen
						if (succ  != nil) {
							do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'inform', contents :: ["start"]);	
						}
					}
				}

			} else if (con[0] = "reorder") {
				write "reorder" + y;
				// delete the current point
				remove x from: availableX;
				if (length(availableX) > 0) {
					// choose another poijnt
					do choocePointAndAsk;
				} else {
					// init again the list
					do initializeList;
					// you need to reorder the predecessor
					if (pred != nil) {
						do start_conversation (to :: [pred], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["reorder"]);	
					} else {
						write "Problem";
						do choocePointAndAsk;
					}
				}
			}
		}
	}
	

	
	bool checkPoint(int succX, int succY) {
		if (succX = x) {
			return false;
		} else {
			int diff <- succY - y;
			if ((succX = x-diff) or (succX = x+diff)){
				return false;
			}
		}
		return true;
	}
	
	aspect aspect {
		if (x != -1 and y!= -1) {
			image_file  paobc <- image_file("https://upload.wikimedia.org/wikipedia/en/thumb/1/18/Panathinaikos_BC_logo.svg/1200px-Panathinaikos_BC_logo.svg.png");
			draw paobc size: (100/grid)*0.7 at: MyGrid[x, y];
			//image_file  paofc <- image_file("https://upload.wikimedia.org/wikipedia/en/thumb/8/84/Panathinaikos_F.C._logo.svg/1200px-Panathinaikos_F.C._logo.svg.png");
        	//draw paofc size: 15 at: MyGrid[x, y];
		}
	}
	
	
}

grid MyGrid width: grid height: grid {
    aspect aspect {
    	rgb agentColor <- nil;
    	if (grid_x mod 2 = 0) {
    		if (grid_y mod 2 = 0) {
    			agentColor <- rgb(0, 122, 61);
    		} else {
    			agentColor <- rgb("white");
    		}
    	} else {
    		if (grid_y mod 2 = 1) {
    			agentColor <- rgb(0, 122, 61);
    		} else {
    			agentColor <- rgb("white");
    		}
    	}
    	draw square(gridSize) color: agentColor;	
    }
}

experiment MyExperiment type: gui {
    output {
        display MyDisplay type: opengl {
            species MyGrid aspect: aspect;
            species Queen aspect: aspect;
        }
    }
}