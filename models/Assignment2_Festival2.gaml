/**
* Name: Festival1
* Based on the internal empty template. 
* Author: Ilias Merentitis, Chrysoula Dikonimaki
* ENGLISH AUCTION
*/


model Festival2

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
	int maxPrice <- rnd(50000, 100000);
	float  lastBid <- 0.0;
	
	
	action setName(int num) {
		personName <- "Guest" + num;
	}
	
	reflex moveAround when: targetPoint = nil {
		do wander;
	}
	
	reflex getInform when: !empty(informs) {
		loop i over: informs {
			write(personName + " received message (Inform): " + i.contents + " from " + i.sender);
			maxPrice <- rnd(50000, 100000);
		}
	}
	
	reflex getPrice when: !empty(cfps) {
		loop i over: cfps {
			
			loop currentPrice over: i.contents {
				
				//HERE I WIN THE AUCTION
				if (currentPrice as float) = lastBid {
					do propose with: (message: i, contents: [currentPrice]);
				} 
				
				else {
					
					
					if ((currentPrice as float) <= maxPrice) {
						//HERE I DECIDE HOW MUCH I RAISE
						
						float raise <- (currentPrice as float)* rnd(101.0,110.99999999)/100;
						if (raise > maxPrice) {
							raise <- maxPrice * 1.0;
						}  
						do propose with: (message: i, contents: [raise]);
						write(personName + " received message (cfps): " + i.contents + " from " + i.sender + ", raise to: " + raise);
						lastBid <- raise;
					}
					else {
						do propose with: (message: i, contents: [0.0]);
						write(personName + " is out.");
					}
					
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
	float minPrice <- rnd(5000.0, 6000.0);
	
	action setName(int num) {
		personName <- "Auctioneer" + num;
	}

	reflex timePass when: !isSelling {
		isSelling <- flip(0.4);
	}
	
	
	reflex announcetAuction when: isSelling and !sentMsg{
		int idx <- rnd(0, length(items)-1);
		sellingItem <- items[idx];
		
		write "Start Auction. Item: " + sellingItem + ", Price: " + minPrice + ", Seller: " + personName;
		guests <- Guest where (each.desiredItem = sellingItem);
		
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['item for sale', sellingItem]);
		do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [minPrice]);
	
		sentMsg <- true;
	}
	
	reflex haveBids when: sentMsg and !empty(proposes) {
		someoneBid <- false;
		float maxProposedPrice <- -1.0;
		message maxPropose <- nil;
		int withdrawn <- 0;
		loop propose over: proposes {
			loop price over: propose.contents {
				if((price as float) > maxProposedPrice) {
					maxProposedPrice <- price as float;
				}
				if((price as float) = 0.0) {
					withdrawn <- withdrawn + 1;
				}
			}
		}
		
		if (withdrawn = length(guests) - 1) {
			write personName + " SOLD an item, price: " + maxProposedPrice;
			totalAmountSold <- totalAmountSold + maxProposedPrice;
			write(proposes);
			isSelling <- false;
			sentMsg <- false;
			someoneBid <- true;
		} else {
			do start_conversation (to :: guests, protocol :: 'fipa-request', performative :: 'cfp', contents :: [maxProposedPrice]);
		}
		
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
				data "sum of sales of English auction" value: totalAmountSold;
			}
		}
	}
}

