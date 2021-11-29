/**
* Name: UtilityStages
* Based on the internal empty template. 
* Author: Ilias, Chrysa
* Tags: 
*/


model UtilityStagesCrowdMass

global {
	int numStages <- 4;
	int numGuests <- 20;
	list<string> attributesList <- ["lightshow", "speakers", "band", "decoration", "drinks", "food"];
	
	init {
		create Guest number:numGuests;
		create Stage number:numStages;
		
		loop counter from: 0 to: numStages - 1 {
        	Stage s <- Stage[counter];
        	s <- s.setIndex(counter);
        }
	}
	
}

species Stage skills: [fipa] {
	
	bool live <- false;
	float endTime <- 0.0;
	list<float> prefferences <- nil;
	list<Guest> guests <- nil;
	int stageIndex;
	bool informGuests <- false;
	
	init {
		do intializeAttributes;
	}
	
	action setIndex(int index) {
		stageIndex <- index;
	}
	
	reflex timePass when: !live {
		live <- flip(0.5);
		endTime <- time + 2000;
	}
	
	reflex test when: live {
		write("Stage" + stageIndex + " is live.");
	}
	
	reflex isLive when: live and !informGuests {
		informGuests <- true;
		write("Stage" + stageIndex + " is live.");
		guests <- Guest;
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["start", stageIndex, prefferences]);
	}
	
	reflex endConcert when: time > endTime {
		live <- false;
		informGuests <- false;
		do intializeAttributes;
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["end", stageIndex]);
		
	}
	
	action intializeAttributes {
		prefferences <- nil;
		loop i over: range(0, length(attributesList)-1) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		
		write("Stage" + stageIndex + " has attributes: " + prefferences);
	}
	
	aspect aspect {
		draw pyramid(5) color: #gray;
	}
	
}

species Guest skills: [fipa, moving] {
	
	list<float> prefferences <- nil;
	list<float> scorePerStage <- nil;
	float winningScore <- -1.0;
	point targetPoint <- nil;
	bool attending <- false;
	
	init {
		loop i over: range(0, length(attributesList)-1) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		
		loop i over: range(0, numStages-1) {
			add 0.0 to: scorePerStage;
		}
		
	}
	
	reflex goToPlace {
		do goto target:targetPoint; 
	}
	
	reflex party when: targetPoint != nil and location distance_to(targetPoint) < 10 {
		do wander;
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			list contents <- i.contents;
			if (contents[0] = "start") {
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
			
		}
		do findMax;
		
	}
	
	action findMax {
		float maxScore <- 0.0;
		int maxIndex <- 0;
		loop i over: range(0, length(scorePerStage)-1) {
			if (scorePerStage[i] > maxScore) {
				maxScore <- scorePerStage[i];
				maxIndex <- i;
			}
		}
		targetPoint <- Stage[maxIndex].location + {rnd(-6,6), rnd(-6,6), 0};
		
		write("My scores are: " + scorePerStage);
		write("I am going to stage" + maxIndex + " with a score of " + maxScore);
	}
	
	aspect aspect {
		draw sphere(1) color: #blue;
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