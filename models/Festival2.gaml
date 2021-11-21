/**
* Name: Festival2
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* Tags: 
*/


model Festival2

global {
	list<string> items <- 		["painting", "book", "ticket", "cd"];
	list<bool> itemsSoldNow <-  [false, false, false, false];
	list<string> itemsColour <- ["lightblue", "lightgreen", "yellow", "red"];
	int numAuctioneers <- length(items);
	int numGuests <- 20;
	
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
	int maxPrice <- rnd(100, 90000);
	
	rgb agentColour <- itemsColour[idx];
	
	action setName(int num) {
		personName <- "Guest" + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		do wander;
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			write(personName + " received message (Inform): " + i.contents + " from " + i.sender);
		}
	}
	
	reflex getPrice when: !empty(cfps) {
		loop i over: cfps {
			write(personName + " received message (cfps): " + i.contents + " from " + i.sender);
			
			loop currentPrice over: i.contents {
				int diff <- (currentPrice as int) - maxPrice;
				write "Diff: " + diff;
				if (diff <= 0) {
					write "I bid";
					do propose with: (message: i, contents: ['i bid']);
				}
			}

		}
	}

	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint; 
	}
	
	aspect base {
		draw circle(1) color: agentColour;
	}
}


species Auctioneer skills: [fipa]{
		
	string personName <- "Undefined";
	bool isSelling <- false;
	string sellingItem <- nil;
	bool sentMsg <- false;
	list<Guest> guests <- nil;
	float timeSent <- 0.0;
	float sellingPrice <- 100000.0;
	
	int idx <- nil;
	
	action setName(int num) {
		personName <- "Auctioneer" + num;
	}

	reflex timePass when: !isSelling {
		isSelling <- flip(0.1);
	}
	
	
	reflex announcetAuction when: isSelling and !sentMsg{
		write "Start Auction";
		
		int c <- 0;
		list<int> availableItemsIdx <- nil;
		loop i over: itemsSoldNow {
			if (!i) {
				add c to: availableItemsIdx;
			}
			c <- c + 1;
		}
		
		idx <- availableItemsIdx[rnd(0, length(availableItemsIdx)-1)];
		itemsSoldNow[idx] <- true;
		
		sellingItem <- items[0];//items[idx];
		guests <- Guest where (each.desiredItem = sellingItem);
		
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['item for sale', sellingItem]);
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [sellingPrice]);
	
		sentMsg <- true;
		timeSent <- time;
	}
	
	reflex noBids when: sentMsg and time = timeSent+1 and empty(proposes) {
		write "No proposes";
		sellingPrice <- sellingPrice*90/100;
		write "new selling price :" + sellingPrice;
		timeSent <- time;
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [sellingPrice]);
	}
	
	reflex haveBids when: sentMsg and time = timeSent+1 and !empty(proposes) {
		message m  <- proposes at 0;
		write "Item sold from: "+ personName + " price: " + sellingPrice + " message:"+ m;
		write m;
		isSelling <- false;
		sentMsg <- false;
		sellingPrice <- 100000.0;
		itemsSoldNow[idx] <- false;
		write("itemsSoldNow : ", itemsSoldNow);
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

