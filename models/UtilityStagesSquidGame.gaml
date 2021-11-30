/**
* Name: UtilityStages
* Based on the internal empty template. 
* Author: Ilias, Chrysa
* Tags: 
*/


model UtilityStagesSquidGame

global {
	int numStages <- 4;
	int numGuests <- 50;
	list<string> attributesList <- ["lightshow", "speakers", "band", "decoration", "drinks", "food", "money"];
	
	init {
		create Guest number:numGuests;
		create Stage number:numStages;
		
		loop counter from: 0 to: numStages - 1 {
        	Stage s <- Stage[counter];
        	s <- s.setIndex(counter);
        }
        
        loop counter from: 0 to: numGuests - 1 {
        	Guest g <- Guest[counter];
        	g <- g.setIndex(counter);
        }
	}
	
}

species Stage skills: [fipa] {
	
	bool live <- false;
	float endTime <- 0.0;
	list<float> prefferences <- nil;
	list<Guest> guests <- nil;
	int stageIndex;
	list<int> arrivedIndexes <- 0;
	bool informGuests <- false;
	bool squidGameCompleted <- false;
	bool startGame <- false;
	int numOfPlayersTotal <- 0;
	int numOfPlayersArrived <- 0;
	
	action setIndex(int index) {
		stageIndex <- index;
		do intializeAttributes;
	}
	
	reflex timePass when: !live {
		live <- true;
		if (stageIndex > 0) {
			endTime <- time + 300;
		} else {
			endTime <- #infinity;
		}
	}
	
	reflex playerArrived when: stageIndex = 0 and !empty(inform){
		
		loop i over: informs {
			list contents <- i.contents;
			if (contents[0] = "arrive") {
				int index <- contents[1] as int;
				if !(arrivedIndexes contains index) {
					add index to: arrivedIndexes;
					numOfPlayersArrived <- numOfPlayersArrived + 1;
				}
			}
		}
	}
	
	reflex isLive when: live and !informGuests {
		informGuests <- true;
		write("Stage" + stageIndex + " is live.");
		guests <- Guest;
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["start", stageIndex, prefferences]);
	}
	
	reflex startPlaying when: stageIndex = 0 and live and informGuests and !startGame {
		list<Guest> players <- Guest where (each.squidGameOn);
		if (length(players) > 3) {
			startGame <- true;
			numOfPlayersTotal <- length(players)-1;
		}
	}
	
	// play squid game
	reflex playSquidGame when: startGame and numOfPlayersTotal <= numOfPlayersArrived and !squidGameCompleted{ 
		write "START GAME";
		list<Guest> players <- Guest where (each.squidGameOn  and !each.isDead);
		int playersAlive <- length(players);
		bool atLeastTwoPlayers <- playersAlive > 1;
		
		loop while: atLeastTwoPlayers {
			playersAlive <- playOneGame();
			atLeastTwoPlayers <- playersAlive > 1;
		}
		squidGameCompleted <- true;
	}
	
	int playOneGame {
		// get all squid game players
		list<Guest> players <- Guest where (each.squidGameOn and !each.isDead);
		int counter <- 0;
		loop i over: range(0, length(players)-1){
			if(flip(0.9)) {
				// kill player
				do start_conversation (to :: [players[i]], protocol :: 'fipa-request', performative :: 'inform', contents :: ["kill"]);
				counter <- counter + 1;
			}
		}
		return length(players) - counter;
	}
	
	// simple stage end
	reflex endConcert when: time > endTime {
		live <- false;
		informGuests <- false;
		do intializeAttributes;
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["end", stageIndex]);
		
	}
	
	reflex completedSquidGame when: squidGameCompleted {
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["end squid game"]);
	}

	action intializeAttributes {
		prefferences <- nil;
		loop i over: range(0, length(attributesList)-2) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		// money
		if (stageIndex = 0) {
			// squid game
			add 1.0 to: prefferences;
		} else {
			add 0.0 to: prefferences;
		}
		write("Stage" + stageIndex + " has attributes: " + prefferences);
	}
	
	aspect aspect {
		if (stageIndex = 0 ){
			if(squidGameCompleted) {
				draw pyramid(5) color: #black;
			} else {
				draw pyramid(5) color: #red;
			}
		} else {
			draw pyramid(5) color: #gray;
		}
	}
	
}

species Guest skills: [fipa, moving] {
	
	list<float> prefferences <- nil;
	list<float> scorePerStage <- nil;
	int guestIndex <- nil;
	float winningScore <- -1.0;
	point targetPoint <- nil;
	bool attending <- false;
	bool squidGameOn <- false;
	bool isDead <- false;
	Stage targetStage <- nil;
	bool arrived <- false;
	
	init {
		loop i over: range(0, length(attributesList)-1) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		
		loop i over: range(0, numStages-1) {
			add 0.0 to: scorePerStage;
		}
		
	}
	
	action setIndex(int i) {
		guestIndex <- i;
	}
	
	reflex goToPlace {
		do goto target:targetPoint; 
	}
	
	reflex party when: targetPoint != nil and location distance_to(targetPoint) < 10 and !isDead{
		do wander;
		do start_conversation (to :: [targetStage], protocol :: 'fipa-request', performative :: 'inform', contents :: ["arrive", guestIndex]);
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			list contents <- i.contents;
			if (contents[0] = "start" and  !squidGameOn) {
				//calculate prefferences' value
				int index <- contents[1] as int;
				list concertAttributes <- contents[2];
				float score <- 0.0;
				loop j over: range(0, length(concertAttributes)-1) {
					float thisVal <- concertAttributes[j] as float;
					score <- score + prefferences[j] * thisVal;
				}
				scorePerStage[index] <- score;
			} 
			else if (contents[0] = "end") {
				int index <- contents[1] as int;
				scorePerStage[index] <- 0.0;
			} 
			else if (contents[0] = "kill" and squidGameOn) {
				isDead <- true;
			}
			else if (contents[0] = "end squid game") {
				scorePerStage[0] <- -1000.0;
			}
		}
		if (!squidGameOn) {
			do findMax;
		}
		
	}
	
	action findMax {
		float maxScore <- -1.0;
		int maxIndex <- 0;
	
		loop i over: range(0, length(scorePerStage)-1) {
			if (scorePerStage[i] > maxScore) {
				maxScore <- scorePerStage[i];
				maxIndex <- i;
			}
		}
		
		if (maxIndex = 0) {
			squidGameOn <- true;
		}
		
		targetStage <- Stage[maxIndex];
		targetPoint <- targetStage.location + {rnd(-6,6), rnd(-6,6), 0};
		
		write("My scores are: " + scorePerStage);
		write("I am going to stage" + maxIndex + " with a score of " + maxScore);
	}
	
	aspect aspect {
		if (!isDead) {
			draw sphere(1) color: #blue;
		} else {
			draw sphere(1) color: #red;
		}
	}
}

grid MyGrid width: 100 height: 10 {
    aspect aspect {
    	draw square(11) color: rgb(0, 122, 61);	
    }
}


experiment MyExperiment type: gui {
    output {
        display MyDisplay type: opengl background: #cyan {
            species MyGrid aspect: aspect;
            species Stage aspect: aspect;
            species Guest aspect: aspect;
        }
    }
}