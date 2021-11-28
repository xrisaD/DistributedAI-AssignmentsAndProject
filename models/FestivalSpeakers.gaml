/**
* Name: FestivalSpeakers
* Based on the internal empty template. 
* Author: Chrysa, Ilias
* Tags: 
*/


model FestivalSpeakers

global {
	int grid <- 5;
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
	bool isSet <- false;
	list<int> availableX <- [];
	
	init {
		loop i over: range(0, grid-1) {
			availableX[i] <- i;
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
	
	action place {
//		if (succ!=nil) {
//			do start_conversation (to :: [succ], protocol :: 'fipa-request', performative :: 'inform', contents :: ["start"]);		
//		}
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			loop content over: i.contents {
				if (content = "start") {
					// choose a point
					
					// ask your predecessor if this point is available
					
				}
				
			}
		}
	}
	
	reflex getAnsweFromPred {
		// if the point is available then inform your succ to start
		
		// else
		   //if other available point exists then check the next point (next x)
		
			// else,
	}
	
	aspect aspect {
		if (x != -1 and y!= -1) {
			draw circle(2) at: MyGrid[x, y] color: #black;
		}
	}
	
	
}

grid MyGrid width: grid height: grid {
    aspect aspect {
    	rgb agentColor <- nil;
    	if (grid_x mod 2 = 0) {
    		if (grid_y mod 2 = 0) {
    			agentColor <- rgb("green");
    		} else {
    			agentColor <- rgb("white");
    		}
    	} else {
    		if (grid_y mod 2 = 1) {
    			agentColor <- rgb("green");
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
