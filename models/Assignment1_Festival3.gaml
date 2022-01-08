/**
* Name: Festival
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* Tags: 
*/


model Festival

global {
	int numGuests <- 50;
	int numStores <- 5;
	
	//thresholds for deciding store types 
	int thr1 <- 2; // 1, 2 = 2 cafes
	int thr2 <- 4; // 3, 4 = 2 restaurants and then 1 remaining kiosk
	int thrCount <- 1;
	
	init {
		create Store number:numStores;
		create InfoCentre;
		create Guest number:numGuests;
		create Security;
				
		loop counter from: 1 to: numGuests {
        	Guest myGuest <- Guest[counter - 1];
        	myGuest <- myGuest.setName(counter);
        }
		
		loop counter from: 1 to: numStores {
        	Store myStore <- Store[counter - 1];
        	myStore <- myStore.setName(counter);
        }
        
        
	}
}


species Guest skills:[moving]{
	
	bool isEvil <- flip(0.2);
	bool isHungry <- false;
	bool isThirsty <- false;
	bool targetCentre <- false;
	bool targetStore <- false;
	point targetPoint <- nil;
	point infoCentreLoc <- nil;
	float distance <- 0.0;
	
	string personName <- "Undefined";
	
	init {
        infoCentreLoc <-InfoCentre[0].location;
	}
	
	action setName(int num) {
		personName <- "Person " + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		isHungry <- flip(0.01);
		isThirsty <- flip(0.01);
		do wander;
	}
	
	reflex timePass when: (isHungry or isThirsty) and targetPoint = nil {
		targetPoint <- infoCentreLoc;
		targetCentre <- true;
		distance <- distance + (self.location distance_to targetPoint);
	}
	
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint; 
	}
	
	reflex enterInfoCentre when: targetCentre and location distance_to(targetPoint) < 2 {
		
		if (isHungry and isThirsty) {
			ask InfoCentre {
				myself.targetPoint <- self.getKiosk();
			}
		}
		else if (isHungry) {
			ask InfoCentre {
				myself.targetPoint <- self.getRestaurant();
			}
		}
		else if (isThirsty){
			ask InfoCentre {
				myself.targetPoint <- self.getCafe();
			}
		}

		targetCentre <- false;
		targetStore <- true;
		distance <- distance + (self.location distance_to targetPoint);
		
		
	}
	
	
	reflex enterStore when: targetStore and location distance_to(targetPoint) < 2 {
		isHungry <- false;
		isThirsty <- false;
		targetPoint <- nil;
		targetStore <- false;
	}
	
	aspect base {
		rgb agentColor <- rgb("lightgreen");
		
		if (isHungry and isThirsty) {
			agentColor <- rgb("red");
		} else if (isThirsty) {
			agentColor <- rgb("darkorange");
		} else if (isHungry) {
			agentColor <- rgb("yellow");
		}
		
		rgb borderColor <- nil;
		if (isEvil) {
			borderColor <- rgb("black");
		}
		
		draw circle(1) color: agentColor border: borderColor;
	}
}


species Store {
	string storeName <- "Undefined";
	string storeType <- "Undefined";
	rgb agentColor <- rgb("lightgray");
	
	init {
		if (thrCount <= thr1) { // Cafe
			agentColor <- rgb("darkorange");
			storeType <- "Cafe";
		} 
		else if (thrCount <= thr2) { // Restaurant
			agentColor <- rgb("yellow");
			storeType <- "Restaurant";	
		}
		else { // Kiosk
			agentColor <- rgb("red");
			storeType <- "Kiosk";
		}	
		
		thrCount <- thrCount + 1;
	}
	
	action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect base {
		draw triangle(5) color: agentColor;
	}
}

species InfoCentre {
	
	string centreName <- "Information Centre";
	
	list<Store> kiosks;
	list<Store> restaurants;
	list<Store> cafes;
	
	list<Guest> foundEvils;
	
	init {
		loop i over: Store {
			if (i.storeType = "Kiosk") {
				add i to:kiosks;
			} else if (i.storeType = "Restaurant") {
				add i to:restaurants;
			} else if (i.storeType = "Cafe"){
				add i to:cafes;
			}
		}
	}
	
	// select and return a random kiosk
	point getKiosk {
		int num <- length (kiosks);
		int index <- rnd(num-1);
		return (kiosks at index).location;
	}
	
	// select and return a random cafe
	point getCafe {
		int num <- length (cafes);
		int index <- rnd(num-1);
		return (cafes at index).location;
	}
	
	// select and return a random restaurant
	point getRestaurant {
		int num <- length (restaurants);
		int index <- rnd(num-1);
		return (restaurants at index).location;
	}

	
	// location distance_to(targetPoint) < 2
	reflex findEvils when: !empty(Guest at_distance 2) {
		list<Guest> possibleEvils <- Guest at_distance 5;
		loop g over: possibleEvils {
			if g.isEvil and !(foundEvils contains g){
				do callSecurity(g);
				add g to: foundEvils;
			}
		}
	}
	
	action callSecurity(Guest guest) {
		ask Security {
			add guest to: self.evils; 
		}
	}
	
	aspect base {
		rgb agentColor <- rgb("blue");
		draw square(5) color: agentColor;
	}
	

}

species Security skills:[moving]{
	
	list<Guest> evils;
	
	reflex patrol when: length(evils) <= 0{
		do wander;
	}
	
	reflex followEvil when: length(evils) > 0 {
		Guest evil <- evils[0];
		do goto target:evil.location speed: 2.0;
	}
	
	reflex killEvil when: !empty(evils) and location distance_to(evils[0])<2{
		Guest e <- evils[0];
		remove from: evils index:0;
		ask e {
			do die;
		}
	}
	
	aspect base {
		rgb agentColor <- rgb("blue");
		draw circle(1) color: agentColor;
	}
}



experiment myExperiment type:gui {
	output {
		display myDisplay {
			species Security aspect:base;
			species Guest aspect:base;
			species Store aspect:base;
			species InfoCentre aspect:base;
		}
		display chartWithEvils {
			chart "evils" {
				data "total evils" value: Guest count each.isEvil;
			}
		}
	}
}
