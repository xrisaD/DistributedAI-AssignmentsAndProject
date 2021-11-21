/**
* Name: Festival1
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* Tags: 
*/


model Festival1

global {
	int numGuests <- 10;
	int numAuctioneers <- 1;
	list<string> items <- ["painting", "book", "ticket", "cd"];
	list<string> itemsColour <- ["lightblue", "lightgreen", "yellow", "red"];
	
	init {
		create Guest number:numGuests;
		create Auctioneer number:numAuctioneers;

				
		loop counter from: 1 to: numGuests {
        	Guest myGuest <- Guest[counter - 1];
        	myGuest <- myGuest.setName(counter);
        }  
        
        loop counter from: 1 to: numAuctioneers {
        	Auctioneer myAuctioneer <- Auctioneer[counter - 1];
        	myAuctioneer <- myAuctioneer.setName(counter);
        }    
                 
	}
}



species Guest skills:[moving, fipa]{
		
	string personName <- "Undefined";
	point targetPoint <- nil;
	int idx <- rnd(0, length(items)-1);
	string desiredItem <- items[idx];
	int price <- rnd(100, 100000);
	
	action setName(int num) {
		personName <- "Guest" + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		do wander;
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			price <- rnd(100, 100000);
		}
	}
	
	reflex getPrice when: !empty(cfps) {
		loop i over: cfps {
			do propose with: (message: i, contents: [price]);
		}
	
	}
	aspect base {
		rgb agentColor <- rgb("lightgreen");
		draw circle(1) color: rgb(itemsColour[idx]);
	}
}


species Auctioneer skills: [fipa]{
		
	string personName <- "Undefined";
	bool isSelling <- false;
	string sellingItem <- nil;
	bool sentMsg <- false;
	bool someoneBid <- false;
	int currentNumOfGuests <- 0;
	
	action setName(int num) {
		personName <- "Auctioneer" + num;
	}

	reflex timePass when: !isSelling {
		isSelling <- flip(0.4);
	}
	
	
	reflex announcetAuction when: isSelling and !sentMsg{
		write "Start Auction";
		int idx <- rnd(0, length(items)-1);
		sellingItem <- items[idx];
		list<Guest> guests <- Guest where (each.desiredItem = sellingItem);
		currentNumOfGuests <- length(guests);
		
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['item for sale', sellingItem]);
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: ['Start bid']);
	
		sentMsg <- true;
	}
	
	reflex haveBids when: sentMsg and !empty(proposes) and (length(proposes) = currentNumOfGuests){
		int maxPrice <- 0;
		message maxPropose <- nil;
		
		loop propose over: proposes {
			loop price over: propose.contents {
				if (price as int) > maxPrice {
					maxPrice <- (price as int);
					maxPropose <- propose;
				}
			}
		}
		
		// sold at the max price
		loop propose over: proposes {
			loop price over: propose.contents {
				if (price as int) = maxPrice {
					do accept_proposal with: (message:: propose, contents:: []);
				} else {
					do reject_proposal with: (message:: propose, contents:: []);
				}
			}
		}
		write "SOLD to: " + maxPropose.sender +" Price: "+maxPrice;
		isSelling <- false;
		sentMsg <- false;
		
	}
	
	aspect base {
		rgb agentColor <- rgb("blue");
		draw circle(1) color: agentColor;
	}
}



experiment myExperiment type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Auctioneer aspect:base;
		}
	}
}

