model Project

global {
	
    int numPlaces <- 10; 
    int numGuests <- 20;
	list<string> placeTypes <- ["bar", "concert"];
	
	string place_at_location <- "place_at_location";
	
	predicate find_place <- new_predicate("find place");
	predicate place_location <- new_predicate("place_at_location");
	predicate have_fun <- new_predicate("have fun");
	predicate choose_place <- new_predicate("choose place");
    
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

species guest skills: [moving] control:simple_bdi {
	
	float viewDist <- 20.0;
	float viewDistPlace <- 1.0;
	string moodFor <- placeTypes[rnd(0, length(placeTypes)-1)];
	
	bool use_emotions_architecture <- true ;
    bool use_personality <- true;
    
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- rnd(0.0, 1.0);
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
	
	string guestType <- nil;
	
	
	
	point target;
	
	
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
	
	
	perceive target: guest in: viewDistPlace {
		
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
	
	
	reflex test {
		list<guest> likeable <- list<guest>((social_link_base where (each.liking > 0)) collect each.agent);
		write self.name + " " + likeable;
		write self.name + " social link base: " + social_link_base;
		
	}
	
	
	perceive target: place in: viewDist {
		focus id:place_at_location var:location;
		ask myself {
			// if the guest's mood for a place (bar, concert etc) is the same as the place type
			if(self.moodFor = myself.type) {
				//then a suitable place has been found
				do remove_intention(find_place, false);
			}
		}
	}
	
	rule belief: place_location new_desire: have_fun strength: 2.0;
	
	plan go_have_fun intention: have_fun {
		if(target = nil) {
			do add_subintention(get_current_intention(),choose_place, true);
            do current_intention_on_hold();
		}
		else {
			do goto target: target;
		}
	}
	
	plan choose_a_place intention:choose_place instantaneous: true {
        list<point> possible_places <- get_beliefs_with_name(place_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        list<point> suitable_places <- nil;
        loop coordinates over: possible_places {
        	place closestPlace <- agent_closest_to(coordinates) as place;
        	if(closestPlace != nil) {
        		if(closestPlace.type = self.moodFor) {
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
		
		if(guestType = "noisyPartyAnimal") {
			agentColour <- #orange;
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
		
		
		if(moodFor = "bar") {
			agentBorder <- #cyan;
		}
		else if (moodFor = "concert") {
			agentBorder <- #red;
		}
     	draw circle(1) color: agentColour border: agentBorder;
    }
	
}








experiment GoldBdi type: gui {
    output {
        display map type: opengl {
            species place;
            species guest;
        }


    }
}
