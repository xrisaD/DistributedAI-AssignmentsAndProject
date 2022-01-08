/**
* Name: Festival
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* Tags: 
*/


model Festival

global {
	int numGuests <- 20;
	int numStores <- 5;
	int numInfoCentres <- 1;
	
	point infoCentreLoc <- {50,50};
	
	//thresholds for deciding store types 
	int thr1 <- 2; // 1, 2 = 2 cafes
	int thr2 <- 4; // 3, 4 = 2 restaurants and then 1 remaining kiosk
	int thrCount <- 1;
	
	init {
		create Guest number:numGuests;
		create Store number:numStores;
		create InfoCentre number:numInfoCentres;
				
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
	
	bool isHungry <- false;
	bool isThirsty <- false;
	bool targetCentre <- false;
	bool targetStore <- false;
	point targetPoint <- nil;
	bool discover <- nil;
	float distance <- 0.0;
	
	// memory
	list<point> restaurants;
	list<point> cafes;
	list<point> kiosks;
		
	string personName <- "Undefined";
	
	action setName(int num) {
		personName <- "Person " + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		isHungry <- flip(0.01);
		isThirsty <- flip(0.01);
		do wander;
	}
	
	reflex timePass when: (isHungry or isThirsty) and targetPoint = nil {
		
		if ((isHungry and isThirsty and length(kiosks) = 0) 
			or (isHungry and length(restaurants) = 0) 
			or (isThirsty and length(cafes) = 0)) {
				discover <- true;
		}
		else if ((isHungry and isThirsty and length(kiosks) = numStores-thr2) 
			or (isHungry and length(restaurants) = thr2-thr1) 
			or (isThirsty and length(cafes) = thr1)) {
			discover <- false;
		}
		else {
			discover <- flip(0.5);
		}
		
		// go to the infoCentre and ask for a new place
		if (discover) {
			targetPoint <- infoCentreLoc;
			targetCentre <- true;	
		} else {
			// go to a place you have visited before
			targetPoint <- findVisitedStore();
			targetStore <- true;
		}
		distance <- distance + (self.location distance_to targetPoint);
	}
	
	point findVisitedStore {
			if (isHungry and isThirsty) {
				// find the best kiosk
				return findTheBestPoint(kiosks);
			} else if (isHungry) {
				return findTheBestPoint(restaurants);
			} else if (isThirsty) {
				return findTheBestPoint(cafes); 
			}
	}	
		
	point findTheBestPoint(list<point> points) {
		point myLocation <- self.location;
		point theBestpoint <- points[0];
		float minDistance <- (points[0] distance_to myLocation);
		loop i over:points {
			float currentDistance <- i distance_to myLocation;
			if (currentDistance < minDistance) {
				minDistance <- currentDistance;
				theBestpoint <- i;
			}
		}
		return theBestpoint;
	}
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint; 
	}
	
	reflex enterInfoCentre when: targetCentre and location distance_to(targetPoint) < 2 {
		
		if (isHungry and isThirsty) {
			ask InfoCentre {
				myself.targetPoint <- self.getKiosk(myself.kiosks);
			}
			add targetPoint to: kiosks;
		}
		else if (isHungry) {
			ask InfoCentre {
				myself.targetPoint <- self.getRestaurant(myself.restaurants);
			}
			add targetPoint to: restaurants;
		}
		else {
			ask InfoCentre {
				myself.targetPoint <- self.getCafe(myself.cafes);
			}
			add targetPoint to: cafes;
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
		rgb agentColor <- rgb("green");
		
		if (isHungry and isThirsty) {
			agentColor <- rgb("red");
		} else if (isThirsty) {
			agentColor <- rgb("darkorange");
		} else if (isHungry) {
			agentColor <- rgb("yellow");
		}
		
		draw circle(1) color: agentColor;
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
	point getKiosk(list<point> seenKiosks) {
		list<point> notSeen;
		loop i over: kiosks {
			if !(seenKiosks contains i.location) {
				add i.location to: notSeen;
			}
		}
		int num <- length (notSeen);
		int index <- rnd(num-1);
		return notSeen at index;
		
	}
	
	// select and return a random cafe
	point getCafe(list<point> seenCafes) {
		list<point> notSeen;
		loop i over: cafes {
			if !(seenCafes contains i.location) {
				add i.location to: notSeen;
			}
		}
		int num <- length (notSeen);
		int index <- rnd(num-1);
		return notSeen at index;
	}
	
	// select and return a random restaurant
	point getRestaurant (list<point> seenRestaurants) {
		list<point> notSeen;
		loop i over: restaurants {
			if !(seenRestaurants contains i.location) {
				add i.location to: notSeen;
			}
		}
		int num <- length (notSeen);
		int index <- rnd(num-1);
		return notSeen at index;
	}
	aspect base {
		rgb agentColor <- rgb("blue");
		draw square(5) color: agentColor at: infoCentreLoc;
	}
	

}



experiment myExperiment type:gui {
	init {
		create simulation with:[seed::10];
	}
	output {
		display myDisplay {
			species Guest aspect:base;
			species Store aspect:base;
			species InfoCentre aspect:base;
		}
		display chartWithDistance {
			chart "sum distance" {
				data "sum distance with brain" value: Guest sum_of each.distance;
			}
		}
	}
}
