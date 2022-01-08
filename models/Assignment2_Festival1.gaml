/**
* Name: Festival1
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* DUTCH AUCTION
*/


model Festival1

global {
	int numGuests <- 50;
	int numAuctioneers <- 1;
	list<string> items <- ["painting", "book", "ticket", "cd"];
	list<string> itemsColour <- ["lightblue", "lightgreen", "yellow", "red"];
	
	float totalAmountSold <- 0.0;
	
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
	
	action setName(int num) {
		personName <- "Guest" + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		do wander;
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			write(personName + " received message (Inform): " + i.contents + " from " + i.sender);
			maxPrice <- rnd(100, 90000);
		}
	}
	
	reflex getPrice when: !empty(cfps) {
		loop i over: cfps {
			
			loop currentPrice over: i.contents {
				int diff <- (currentPrice as int) - maxPrice;
				write(personName + " received message (cfps): " + i.contents + " from " + i.sender+diff);
			
				if (diff <= 0) {
					do propose with: (message: i, contents: [currentPrice]);
				} else {
					do propose with: (message: i, contents: [0]);
				}
			}

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
	list<Guest> guests <- nil;
	bool someoneBid <- false;
	float sellingPrice <- 100000.0;
	float minPrice <- 60000.0;
	
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
		guests <- Guest where (each.desiredItem = sellingItem);
		
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['item for sale', sellingItem]);
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [sellingPrice]);
	
		sentMsg <- true;
	}
	
	reflex haveBids when: sentMsg and !empty(proposes) {
		someoneBid <- false;
		loop propose over: proposes {
			loop price over: propose.contents {
				if (price as float) = sellingPrice {
					write "Item SOLD, price: " + price + " guest: " + propose.sender;
					totalAmountSold <- totalAmountSold + sellingPrice;
					do accept_proposal with: (message:: propose, contents:: []);
					isSelling <- false;
					sentMsg <- false;
					sellingPrice <- 100000.0;
					someoneBid <- true;
				} else {
					do reject_proposal with: (message:: propose, contents:: []);
				}
			}
		}
		
	}
	reflex startAgain when: isSelling and !someoneBid{
		sellingPrice <- sellingPrice*90/100;
		if (sellingPrice < minPrice ) {
			write "RESTART";
			do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['item for sale', sellingItem]);
			sellingPrice <- 100000.0;
		}
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [sellingPrice]);
	}
	
	
	aspect base {
		rgb agentColor <- rgb("blue");
		draw circle(1) color: agentColor;
	}
}



experiment myExperiment type:gui {
	init {
		create simulation with:[seed::10];
	}
	output {
		display myDisplay {
			species Guest aspect:base;
			species Auctioneer aspect:base;
		}
		display chartWithDistance {
			chart "sum of sales" {
				data "sum of sales of Dutch auction" value: totalAmountSold;
			}
		}
	}
}

