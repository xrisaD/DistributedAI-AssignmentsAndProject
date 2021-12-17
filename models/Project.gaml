/**
* Name: Project
* Based on the internal empty template. 
* Author: Chrysa
* Tags: 
*/


model Project

global {
	
    int nb_party_animals <- 10;
    int nb_chill_people <- 10;
    place bar;
    place concert;
    
    float step <- 10#mn;
    
   string place_at_location <- "place_at_location";
        
    predicate find_place <- new_predicate("find place") ;
    predicate place_location <- new_predicate(place_at_location) ;
    predicate have_fun <- new_predicate("have fun") ;
     
    emotion joy <- new_emotion("joy");
    
    init {
        create place {
        	bar <- self.setType("bar");
        }
        create place {
        	concert <- self.setType("concert");
        }
    	create party_animal number: nb_party_animals;
    	create chill_person number: nb_chill_people;
    }
    
}

species party_animal skills: [moving] control:simple_bdi {
	float view_dist<-0.0;
	
    bool use_emotions_architecture <- true ;
    bool use_personality <- true;
    
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- 1.0;
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
	
	init {
		do add_desire(find_place);
	}
	
	perceive target: place in: view_dist { 
       focus id: place_at_location var: location;
       ask myself {
            do remove_intention(find_place, false);
        }
    }
    
    rule belief: place_location new_desire: have_fun strength: 2.0;
    
     plan have_fun intention:have_fun  {
     	write "have_fun";
     }
	
	plan lets_wander intention:find_place {
        do wander;
    }
    
    aspect default { draw circle(1) color: #red; }
}

species chill_person skills: [moving] control:simple_bdi {
	bool use_emotions_architecture <- true ;
	bool use_personality <- true;
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- 0.0;
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
    int quantity <- rnd(1,20);
    
    init {
		do add_desire(find_place);
	}
    
    plan lets_wander intention:find_place {
		write "ok!";
        do wander;
    }
    
     aspect default { draw circle(1) color: #blue;}
}

species place {
	string type <- "";
	
	action setType (string curType) {
		type <- curType;
	}
	
    aspect default {
    	rgb placeColor <- rgb("black");
    	if (type = "concert") {
        	placeColor <- rgb("green");
        } 
        draw square(5) color: placeColor ;
    }
}


experiment GoldBdi type: gui {
    output {
        display map type: opengl {
        species place ;
        species party_animal ;
        species chill_person ;
    }
    }
}

