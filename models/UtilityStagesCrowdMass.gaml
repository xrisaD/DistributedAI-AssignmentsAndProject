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
		create Leader;
		
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
		live <- true;
		endTime <- time + 500;
	}
	
//	reflex test when: live {
//		write("Stage" + stageIndex + " is live.");
//	}
	
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
	point targetPoint <- nil;
	bool attending <- false;
	bool preferCrowd <- false;
	float crowdMass <- -1.5;
	// allow only two decisions
	int decision <- 0;
	
	init {
		loop i over: range(0, (length(attributesList)-1)) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		preferCrowd <- flip (0.5);
		if (preferCrowd) {
			crowdMass <- 1.5;
		}
		write "I prefer growd: " + preferCrowd + " and crowd mass: " + crowdMass;
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
		list<float> scores <- nil;
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
				decision <- 0;
			} else if (contents[0] = "crowd mass" and decision <= 0) {
				decision <- decision + 1;
				list<float> mass <- contents[1];
				write "MASS is: " + mass;
				loop j over: range(0, length(scorePerStage)-1) {
					float extra <- 0;
					int m <- mass[j];
					if (preferCrowd) {
						// social
						if (m < 0.2) {
							extra <- rnd(-1.0,-0.1);
						} else {
							extra <- rnd(1, 1.4);
						}
					} else {
						// anti-social
						if (m < 0.2) {
							extra <- rnd(1.2, 1.8);
						} else {
							extra <- rnd(-1.0,-0.1);
						}
					}
					add scorePerStage[j] + extra to: scores;
				}
			}
			
			if (contents[0] = "start" or contents[0] = "end") {
				scores <- scorePerStage;
			}
		}
		if !empty(scores) {
			do findMax (scores);
		}
		
	}
	
	action findMax (list<float> scores){
		float maxScore <- -100000.0;
		int maxIndex <- 0;
		loop i over: range(0, length(scores)-1) {
			if (scores[i] > maxScore) {
				maxScore <- scores[i];
				maxIndex <- i;
			}
		}
		targetPoint <- Stage[maxIndex].location + {rnd(-6,6), rnd(-6,6), 0};
		
		
		write("My scores are: " + scores);
		write("I am going to stage" + maxIndex + " with a score of " + maxScore + " and I prefer crowd " + preferCrowd + " with mass param: " +crowdMass);
		
		list<Leader> leader <- Leader;
		// inform leader
		do start_conversation (to :: leader, protocol :: 'fipa-request', performative :: 'inform', contents :: ["go", maxIndex]);
		
	}
	
	
	aspect aspect {
		if (preferCrowd) {
			draw sphere(1) color: #blue;
		} else {
			draw sphere(1) color: #pink;
		}
	}
}

species Leader skills: [fipa] {
	int counter <- 0;
	list<int> guestsPerStage <- nil;
	
	init {
		do initGuestsPerStage;	
	}
	
	action initGuestsPerStage {
		guestsPerStage <- nil;
		loop i over: range(0, numStages-1) {
			add 0.0 to: guestsPerStage; 	
		}
	}
	reflex getInform when: !empty(informs) and numGuests > counter {
		loop i over: informs {
			list contents <- i.contents;
			if (contents[0] = "go") {
				counter <- counter + 1;
				int stage <- contents[1] as int;
				guestsPerStage[stage] <- guestsPerStage[stage] + 1;
			}
		}
	}
	
	reflex forwardList when: numGuests = counter {
		// transform to percentage
		list<float> perc <- nil;
		loop i over: guestsPerStage{
			add (i/counter) to: perc;
		}
		write "Forward List with counters";
		list<Guest> guests <- Guest;
		write("MASS  :" +guestsPerStage +"after:"+perc);
		// send it to all guests
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["crowd mass", perc]);
		do initGuestsPerStage;
		counter <- 0;
		
	}
	
	aspect aspect {
		draw sphere(1) color: #red;
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
            species Leader aspect: aspect;
        }
    }
}