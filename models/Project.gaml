model Project

global {
	
    int numPlaces <- 10; 
    int numGuests <- 50;
	list<string> placeTypes <- ["bar", "concert"];
	
	string place_at_location <- "place_at_location";
	
	predicate find_place <- new_predicate("find place");
	predicate place_location <- new_predicate("place_at_location");
	predicate have_fun <- new_predicate("have fun");
	predicate choose_place <- new_predicate("choose place");
	predicate initiate_interaction <- new_predicate("initiate interaction");
	
	
	emotion joy <- new_emotion("joy");
	emotion sadness <- new_emotion("sadness");
    
    init {
        create place number:numPlaces;
        create guest number:numGuests;
    }

}


species place {
	
	string type <- placeTypes[rnd(0, length(placeTypes)-1)];
	
	
	aspect default {
		rgb agentColour <- #green;
		if(type = "bar") {
			agentColour <- #cyan;
		}
		else if (type = "concert") {
			agentColour <- #red;
		}
     	draw square(5) color: agentColour;
    }
	
}

species guest skills: [moving, fipa] control:simple_bdi {
	
	float viewDist <- 1.0;
	float viewDistPlace <- 50.0;
	string moodFor <- placeTypes[rnd(0, length(placeTypes)-1)];
	int timeDiff <- rnd(500,1000);
	float currTime <- time;
	
	list<string> guestsInteracted <- nil;
	list<guest> acceptedFrom <- nil;
	list<guest> rejectedFrom <- nil;
	list<point> placesVisited <- nil;
	bool isInteracting <- false;
	int happiness <- 0;
	
	bool use_emotions_architecture <- true ;
    bool use_personality <- true;
    
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- rnd(0.0, 1.0);
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
	
	string guestType <- nil;
	
	
	point target;
	
	
	//noisyPartyAnimal
	//quietPartyAnimal
	//deepTopicsChatter
	//boring
	//cringy
	
	init {
		if(extroversion > 0.5) {
			if(neurotism > 0.5) {
				guestType <- "noisyPartyAnimal";
			}
			else {
				guestType <- "quietPartyAnimal";
			}
		}
		else {
			if(openness > 0.5) {
				if(agreeableness > 0.5) {
					guestType <- "deepTopicsChatter";
				}
				else {
					guestType <- "boring";
				}
			}
			else {
				guestType <- "cringy";
			}
		}
		
		
		do add_desire(find_place);
	}
	
	
	plan lets_wander intention: find_place {
		do wander;
	}
	

	
	perceive target: guest in: viewDist {
		if (!dead(self)) {
			
			
			if(myself.guestType = "noisyPartyAnimal") {
			
			if(guestType = "noisyPartyAnimal") {
				socialize liking: 1;
			}
			else if(guestType = "quietPartyAnimal") {
				socialize liking: 0.8;
			}
			else if(guestType = "deepTopicsChatter") {
				socialize liking: -0.2;
			}
			else if(guestType = "boring") {
				socialize liking: -0.5;
			}
			else if(guestType = "cringy") {
				socialize liking: -1.0;
			}
			
		}
		
		
		else if(myself.guestType = "quietPartyAnimal") {
			
			if(guestType = "noisyPartyAnimal") {
				socialize liking: 0.7;
			}
			else if(guestType = "quietPartyAnimal") {
				socialize liking: 1.0;
			}
			else if(guestType = "deepTopicsChatter") {
				socialize liking: -0.1;
			}
			else if(guestType = "boring") {
				socialize liking: -0.5;
			}
			else if(guestType = "cringy") {
				socialize liking: -1.0;
			}
			
		}
		
		
		
		else if(myself.guestType = "deepTopicsChatter") {
			
			if(guestType = "noisyPartyAnimal") {
				socialize liking: -0.2;
			}
			else if(guestType = "quietPartyAnimal") {
				socialize liking: 0.0;
			}
			else if(guestType = "deepTopicsChatter") {
				socialize liking: 1.0;
			}
			else if(guestType = "boring") {
				socialize liking: 0.1;
			}
			else if(guestType = "cringy") {
				socialize liking: -1.0;
			}
			
		}
		
		
		
		else if(myself.guestType = "boring") {
			
			if(guestType = "noisyPartyAnimal") {
				socialize liking: 0.3;
			}
			else if(guestType = "quietPartyAnimal") {
				socialize liking: 0.5;
			}
			else if(guestType = "deepTopicsChatter") {
				socialize liking: 1.0;
			}
			else if(guestType = "boring") {
				socialize liking: 0.5;
			}
			else if(guestType = "cringy") {
				socialize liking: -1.0;
			}
			
		}
		
		
		
		
		else if(myself.guestType = "cringy") {
			
			if(guestType = "noisyPartyAnimal") {
				socialize liking: 0.5;
			}
			else if(guestType = "quietPartyAnimal") {
				socialize liking: 0.5;
			}
			else if(guestType = "deepTopicsChatter") {
				socialize liking: 0.7;
			}
			else if(guestType = "boring") {
				socialize liking: -0.5;
			}
			else if(guestType = "cringy") {
				socialize liking: 0.0;
			}
			
		}
			
			
		}
		
		
		
    }
    
    float getLiking (guest sender) {
    	loop relation over: social_link_base {
			if (relation.agent = sender) {
				return relation.liking;
			}
		}
    }
    
    reflex getAccepts when: !empty(accept_proposals) and !dead(self) {
    	loop p over: accept_proposals {
    		if(!(acceptedFrom contains p.sender) and !dead(p.sender as guest)) {
	    		add p.sender to: acceptedFrom;
	    		happiness <- happiness + 1;	
	    		write "ACCEPT " + self.name + " HAPPINESS " + happiness + " FROM " + p.sender;
    		}
    		
    	}
    }
    
    reflex getRejects when: !empty(reject_proposals) and !dead(self) {
    	loop p over: reject_proposals {
    		if(!(rejectedFrom contains p.sender) and !dead(p.sender as guest)) {
	    		add p.sender to: rejectedFrom;
	    		happiness <- happiness - 1;
    			write "REJECT " + self.name + " HAPPINESS " + happiness + " FROM " + p.sender;
    		}
    		
    	}
    }
    
    reflex getCfps when: !empty(cfps) and !dead(self) {
    	loop i over: cfps {
    		list content <- i.contents;
    		string msg <- content[0];
    		guest sender <- content[1];
    		float l <- getLiking(sender);
			
			
				
			if (msg = "dance") {
				if (self.guestType = "noisyPartyAnimal") {
					if (l >= 0) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					}
					else {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
				else {
					if ((l > 0.5) or (l >= 0 and moodFor = "concert")) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					} 
					else  {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
			} 
				
			else if (msg = "drink") {
				if (self.guestType = "noisyPartyAnimal" or self.guestType = "quietPartyAnimal") {
					if (l >= 0) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					}
					else {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
				else {
					if ((l > 0.5) or (l >= 0 and moodFor = "concert")) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					} 
					else  {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
			}
				
			else if (msg = "purpose of life") {
				if (self.guestType = "deepTopicsChatter" or self.guestType = "boring") {
					if (l >= 0) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					}
					else {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "monopoly") {
				if (self.guestType = "boring" or self.guestType = "cringy") {
					if (l >= 0.5) {
						write self.name + " will send ACCEPT to " + sender;		
						do accept_proposal with: (message:: i, contents:: []);
					}
					else if (l>=0 and moodFor = "bar"){
						write self.name + " will send ACCEPT to " + sender;	
						do accept_proposal with: (message:: i, contents:: []);
					}
					else {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "expired candy") {
				write self.name + " will send REJECT to " + sender;	
				do reject_proposal with: (message:: i, contents:: []);
			}
				
			else if (msg = "dance close by") {
				if (l >= 0) {
					write self.name + " will send ACCEPT to " + sender;	
					do accept_proposal with: (message:: i, contents:: []);
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "raised drink") {
				if (l >= 0) {
					write self.name + " will send ACCEPT to " + sender;	
					do accept_proposal with: (message:: i, contents:: []);
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "mini cv") {
				if(self.guestType != "deepTopicsChatter") {
					if (l >= 0.5) {
						if(self.guestType = "crazyPartyAnimal" and moodFor = "concert") {
							write self.name + " will send REJECT to " + sender;	
							do reject_proposal with: (message:: i, contents:: []);
						}
						else {
							write self.name + " will send ACCEPT to " + sender;	
							do accept_proposal with: (message:: i, contents:: []);
						}
					}
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "weather talk") {
				if(self.guestType = "boring" and l >= 0) {
					write self.name + " will send ACCEPT to " + sender;	
					do accept_proposal with: (message:: i, contents:: []);
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "drunk people comment") {
				if (l >= 0.5) {
					write self.name + " will send ACCEPT to " + sender;	
					do accept_proposal with: (message:: i, contents:: []);
				}
				else {
					write self.name + " will send REJECT to " + sender;	
					do reject_proposal with: (message:: i, contents:: []);
				}
			}
				
			else if (msg = "mood ruiner") {
				write self.name + " will send REJECT to " + sender;	
				do reject_proposal with: (message:: i, contents:: []);
			}
				
			else if (msg = "source of problems") {
				if(self.guestType = "boring" or self.guestType = "cringy" or self.guestType = "deepTopicsChatter") {
					if (l >= 0.5) {
						write self.name + " will send ACCEPT to " + sender;	
						do accept_proposal with: (message:: i, contents:: []);
					}
					else {
						write self.name + " will send REJECT to " + sender;	
						do reject_proposal with: (message:: i, contents:: []);
					}
				}
			}
				
			else if (msg = "ask to leave") {
				write self.name + " will send REJECT to " + sender;	
				do reject_proposal with: (message:: i, contents:: []);
			}
				
			else if (msg = "insulted") {
				write self.name + " will send REJECT to " + sender;	
				do reject_proposal with: (message:: i, contents:: []);
			}
				
				
			
		}
    }
    
    
    
    action refreshOptions {
    	if(length(placesVisited) >= numPlaces/3) {
    		placesVisited <- nil;
    	}
    	if(length(guestsInteracted) >= numGuests/5) {
    		guestsInteracted <- nil;
			acceptedFrom <- nil;
			rejectedFrom <- nil;
    	}
    }
    
	
    
    reflex bored when: time >= currTime + timeDiff and !dead(self) {
		currTime <- time;
		write self.name + " spent enough time here and will look at another place.";
		happiness <- happiness -1;
		do refreshOptions;
		do remove_intention(initiate_interaction, true); 
		//do add_desire(find_place);
		
	}
	
	reflex easyWayOut when: happiness <= -10 and !dead(self) {
		// commit suicide
		write "SUICIDE name: " + self.name + " happiness: " + happiness + " type: " + self.guestType;
		do die;
	}
	
	reflex changePlace when: happiness > -10 and happiness <= -5 and !dead(self) {
		write self.name + " is not enjoying this and will look for another place.";
		happiness <- -2;
		do refreshOptions;
		do remove_intention(initiate_interaction, true); 
		//do add_desire(find_place);
	}
	

	
	plan scopeFriends intention: initiate_interaction when: !dead(self){

		//write self.name + " has this social network: " + social_link_base;
		loop relation over: social_link_base {
				if(!(guestsInteracted contains (relation.agent as string)) and !dead(relation.agent as guest)) {
					//write self.name + " has this social contact: " + relation;
				
					if(relation.liking >= 0.7) {
						if (self.guestType = "noisyPartyAnimal") {
							write self.name + " offers to dance with " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["dance", self]);	
						}
						else if (self.guestType = "quietPartyAnimal") {
							write self.name + " offers a drink to " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["drink", self]);	
						}
						else if (self.guestType = "deepTopicsChatter") {
							write self.name + " asks " + relation.agent + " about the purpose of life";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["purpose of life", self]);	
						}
						else if (self.guestType = "boring") {
							write self.name + " offers to play monopoly with " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["monopoly", self]);	
						}
						else if (self.guestType = "cringy") {
							write self.name + " offers expired candy " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["expired candy", self]);	
						}
					}
					else if (relation.liking > 0) {
						if (self.guestType = "noisyPartyAnimal") {
							write self.name + " dances close to  " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["dance close by", self]);	
						}
						else if (self.guestType = "quietPartyAnimal") {
							write self.name + " raises his drink to " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["raised drink", self]);	
						}
						else if (self.guestType = "deepTopicsChatter") {
							write self.name + " wants to start learning about " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["mini cv", self]);	
						}
						else if (self.guestType = "boring") {
							write self.name + " starts talking about the weather with " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["weather talk", self]);	
						}
						else if (self.guestType = "cringy") {
							write self.name + " starts talking about drunk people to " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["drunk people comment", self]);	
						}
					}
					else if (relation.liking >= -0.5) {
						if (self.guestType = "noisyPartyAnimal") {
							write self.name + " ignores " + relation.agent + " and keeps partying";
						}
						else if (self.guestType = "quietPartyAnimal") {
							write self.name + " tells " + relation.agent + " that he ruining the mood";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["mood ruiner", self]);	
						}
						else if (self.guestType = "deepTopicsChatter") {
							write self.name + " asks " + relation.agent + " which past experience made him so annoying";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["source of problems", self]);	
						}
						else if (self.guestType = "boring") {
							write self.name + " ignores " + relation.agent;
						}
						else if (self.guestType = "cringy") {
							write self.name + " insults " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["insulted", self]);	
						}
					}
					else if(relation.liking < -0.5) {
						if (self.guestType = "noisyPartyAnimal") {
							write self.name + " insults " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["insulted", self]);	
						}
						else if (self.guestType = "quietPartyAnimal") {
							write self.name + " asks " + relation.agent + " to go away";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["ask to leave", self]);	
						}
						else if (self.guestType = "deepTopicsChatter") {
							write self.name + " asks " + relation.agent + " to go away";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["ask to leave", self]);	
						}
						else if (self.guestType = "boring") {
							write self.name + " asks " + relation.agent + " to go away";
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["ask to leave", self]);	
						}
						else if (self.guestType = "cringy") {
							write self.name + " insults " + relation.agent;
							do start_conversation (to :: [relation.agent], protocol :: 'fipa-request', performative :: 'cfp', contents :: ["insulted", self]);	
						}
					}
			}
			
			add relation.agent as string to: guestsInteracted;
			
			
	}
		
		

	}

	
	
	perceive target: place in: viewDistPlace {
		focus id:place_at_location var:location;
		ask myself {
			// if the guest's mood for a place (bar, concert etc) is the same as the place type
			if(self.moodFor = myself.type) {
				//then a suitable place has been found
				if(!(self.placesVisited contains myself.location)) {
					do remove_intention(find_place, false);
				}
				
			}
		}
	}
	
	rule belief: place_location new_desire: have_fun strength: 2.0;
	

	plan go_have_fun intention: have_fun {
		if(target = nil or (placesVisited contains target)) {
			do add_subintention(get_current_intention(),choose_place, true);
            do current_intention_on_hold();
		}
		else {
			do goto target: target;
			if (target distance_to self.location = 0) {
				add target to: placesVisited;
				write self.name + " has found a place!";
				do add_subintention(get_current_intention(), initiate_interaction, true);
				do current_intention_on_hold();
			}
			
		}
	}
	
	plan choose_a_place intention:choose_place instantaneous: true {
        list<point> possible_places <- get_beliefs_with_name(place_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        list<point> suitable_places <- nil;
        loop coordinates over: possible_places {
        	place closestPlace <- agent_closest_to(coordinates) as place;
        	if(closestPlace != nil) {
        		if(closestPlace.type = self.moodFor and !(placesVisited contains closestPlace)) {
        			add coordinates to: suitable_places;
        		}	
        	}

        }
        
        if (empty(suitable_places)) {
        	do remove_intention(have_fun, true); 
        } else {
            target <- (suitable_places with_min_of (each distance_to self)).location;
        }
        
        do remove_intention(choose_place, true); 
	}
	
	aspect default {
		rgb agentColour <- #green;
		rgb agentBorder <- #green;
		
		if(dead(self)) {
			agentColour <- #purple;
		}
		else {
			if(guestType = "noisyPartyAnimal") {
				agentColour <- #yellow;
			}
			else if (guestType = "quietPartyAnimal") {
				agentColour <- #blue;
			}
			else if (guestType = "deepTopicsChatter") {
				agentColour <- #green;
			}
			else if (guestType = "boring") {
				agentColour <- #gray;
			}
			else if (guestType = "cringy") {
				agentColour <- #black;
			}
		}
		
		
		
		
		if(moodFor = "bar") {
			agentBorder <- #cyan;
		}
		else if (moodFor = "concert") {
			agentBorder <- #red;
		}
		
		
		if(dead(self)) {
			draw cross(3) color: agentColour border: #black;
		}
		else {
			draw circle(1) color: agentColour border: agentBorder;
		}
     	
     	
    }
	
}








experiment goBDI type: gui {
    output {
        display map type: opengl {
            species place;
            species guest;
        }
		display happinessChart {
			chart "sum of happiness" {
				data "sum happiness of each guest" value: guest sum_of each.happiness;
			}
		}
		display populationChart {
			chart "number of guests" {
				data "number of guests that are alive" value: length(guest);
			}
		}
    }
}
