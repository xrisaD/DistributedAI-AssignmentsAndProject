/**
* Name: UtilityStages
* Based on the internal empty template. 
* Author: Ilias, Chrysa
* Tags: 
*/


model UtilityStagesCrowdMass

global {
	int numStages <- 10;
	int numGuests <- 200;
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
		endTime <- time + 150;
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
	point targetPoint <- nil;
	bool attending <- false;
	bool preferCrowd <- false;
	// allow only two decisions
	int decision <- 0;
	int maxIndex <- 0;
	
	init {
		loop i over: range(0, (length(attributesList)-1)) {
			float randVal <- rnd(0.0, 1.0);
			add randVal to: prefferences;
		}
		preferCrowd <- flip (0.5);
		
		write "[ANTISOCIAL?]I prefer growd: " + preferCrowd;
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
	
	int LiveNow <- 0;
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
				LiveNow <- LiveNow + 1;
			} 
			else if (contents[0] = "end") {
				int index <- contents[1] as int;
				scorePerStage[index] <- 0.0;
				decision <- 0;
				LiveNow <- LiveNow - 1;
			} else if (contents[0] = "crowd mass" and decision<=0) {
				decision <- decision + 1;
				list<float> mass <- contents[1];
				list<float> antiSocialMass <- contents[2];
				write "MASS is: " + mass;
				write "maxIndex is:  "+maxIndex;
				loop j over: range(0, length(scorePerStage)-1) {
					if (j = maxIndex) {
						if (preferCrowd) {
							// social
							if ((mass[j] - antiSocialMass[j]) > antiSocialMass[j]) or mass[j] > 0.4 {
								// we have a decent amount of non antisocial people who will go there 
								// so we like this place, we will go there
								add scorePerStage[j] + 5 to: scores;
							} else {
								// enough antisocial people will go so they may change their mind
								// we wil help them and we will leave reduce the score for  this place with a high probability
								bool leave <- flip(0.8);
								if (leave) {
									add scorePerStage[j] - rnd(2, 3) to: scores;
								} else {
									add scorePerStage[j] to: scores;
								}
							}
							
						} else {
							// anti social
							
							// if social more than the antisocial
							if ((mass[j] - antiSocialMass[j]) > antiSocialMass[j]) or (mass[j]- antiSocialMass[j]) > 0.3 {
								// the majority will be social people, so I won't go
								add 0 to: scores;
							} else {
								// the majority of them are antisocial
								// what me as an antisocial will do?
								// change my mind and reduce the score by a percentage
								// or just go there and hope that the others will leave
								bool leave <- flip(0.3);
								if (leave) {
									add 0 to: scores;
								} else {
									add scorePerStage[j] to: scores;
								}
							}
						}
					} else {
						// not the one that I have selected
						
						if (preferCrowd) {
							// social
							// don't do anything
							add scorePerStage[j] to: scores;
						} else {
							// antisocial
							if (mass[j] < 0.2) {
								add scorePerStage[j]+rnd(2,3) to: scores;
							}else {
								add scorePerStage[j]-1 to: scores;
							}
						}
						
					}
					
				}
			}
			
			if (contents[0] = "start" or contents[0] = "end") {
				scores <- scorePerStage;
			}
		}
		if !empty(scores) and LiveNow > 0 {
			do findMax (scores);
		}
		
	}
	
	action findMax (list<float> scores){
		float maxScore <- -100000.0;
		maxIndex <- 0;
		loop i over: range(0, length(scores)-1) {
			if (scores[i] > maxScore) {
				maxScore <- scores[i];
				maxIndex <- i;
			}
		}
		targetPoint <- Stage[maxIndex].location + {rnd(-6,6), rnd(-6,6), 0};
		
		
		write("My scores are: " + scores);
		write("I am going to stage" + maxIndex + " with a score of " + maxScore + " and I prefer crowd " + preferCrowd);
		
		list<Leader> leader <- Leader;
		// inform leader
		do start_conversation (to :: leader, protocol :: 'fipa-request', performative :: 'inform', contents :: ["go", maxIndex, preferCrowd]);
		
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
	list<int> antisocialGuestsPerStage <- nil;
	
	init {
		do initGuestsPerStage;	
	}
	
	action initGuestsPerStage {
		guestsPerStage <- nil;
		loop i over: range(0, numStages-1) {
			add 0.0 to: guestsPerStage; 	
		}
		
		antisocialGuestsPerStage <- nil;
		loop i over: range(0, numStages-1) {
			add 0.0 to: antisocialGuestsPerStage; 	
		}
	}
	
	reflex getInform when: !empty(informs) and numGuests > counter {
		loop i over: informs {
			list contents <- i.contents;
			if (contents[0] = "go") {
				counter <- counter + 1;
				int stage <- contents[1] as int;
				guestsPerStage[stage] <- guestsPerStage[stage] + 1;
				bool preferCrowd <- contents[2];
				if (!preferCrowd) {
					antisocialGuestsPerStage[stage] <- antisocialGuestsPerStage[stage] + 1;
				}
				
			}
		}
	}
	
	reflex forwardList when: numGuests = counter {
		// transform to percentage
		list<float> perc <- nil;
		loop i over: guestsPerStage{
			add (i/counter) to: perc;
		}
		
		list<float> percAntis <- nil;
		loop i over: antisocialGuestsPerStage{
			add (i/counter) to: percAntis;
		}
		list<Guest> guests <- Guest;
		write("MASS  :" +guestsPerStage +"after:"+perc);
		// send it to all guests
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ["crowd mass", perc, percAntis]);
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