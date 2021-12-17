/**
* Name: Project
* Based on the internal empty template. 
* Author: Chrysa
* Tags: 
*/


model Project

global {
    int nb_bars <- 10;
    int nb_party_animals <- 10;
    int nb_chill_people <- 10;
    
    float step <- 10#mn;
    geometry shape <- square(20 #km);
    
    
    emotion joy <- new_emotion("joy");
    
    init {
        create bar number: nb_bars;
    	create party_animal number: nb_party_animals;
    	create chill_person number: nb_chill_people;
    }
    
}

species party_animal {
    int quantity <- rnd(1,20);
    
    bool use_personality <- true;
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- 1.0;
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
	
	
    aspect default {
    draw triangle(200 + quantity * 50) color: (quantity > 0) ? #yellow : #gray border: #black;  
    }
}

species chill_person {
	
	bool use_personality <- true;
	float openness <- rnd(0.0, 1.0);
	float conscientiousness <- rnd(0.0, 1.0);
	float extroversion <- 0.0;
	float agreeableness <- rnd(0.0, 1.0);
	float neurotism <- rnd(0.0, 1.0);
    int quantity <- rnd(1,20);
    
    aspect default {
    draw triangle(200 + quantity * 50) color: (quantity > 0) ? #yellow : #gray border: #black;  
    }
}

species bar {
    aspect default {
        draw square(1000) color: #black ;
    }
}

species park {
    aspect default {
        draw square(1000) color: #green ;
    }
}

experiment GoldBdi type: gui {
    output {
        display map type: opengl {
        species bar ;
        species party_animal ;
        species chill_person ;
    }
    }
}

