model Example

global {
    int nb_mines <- 10; 
    int nb_miners <-5;
    market the_market;
    geometry shape <- square(20 #km);
    float step <- 10#mn;
    
    string mine_at_location <- "mine_at_location";
    string empty_mine_location <- "empty_mine_location";
        
    //possible predicates concerning miners
    predicate mine_location <- new_predicate(mine_at_location) ;
    predicate choose_gold_mine <- new_predicate("choose a gold mine");
    predicate has_gold <- new_predicate("extract gold");
    predicate find_gold <- new_predicate("find gold") ;
    predicate sell_gold <- new_predicate("sell gold") ;
    
    float inequality <- 0.0 update:standard_deviation(miner collect each.gold_sold);
    
    init {
        create market {
            the_market <- self;    
        }
        create gold_mine number:nb_mines;
        create miner number:nb_miners;
    }
    
    reflex end_simulation when: sum(gold_mine collect each.quantity) = 0 and empty(miner where each.has_belief(has_gold)){
        do pause;
        ask miner {
        write name + " : " +gold_sold;
    }
    }
}

species gold_mine {
    int quantity <- rnd(1,20);
    aspect default {
        draw triangle(200 + quantity * 50) color: (quantity > 0) ? #yellow : #gray border: #black;    
    }
}

species market {
    int golds;
    aspect default {
      draw square(1000) color: #black ;
    }
}

species miner skills: [moving] control:simple_bdi {
    
    float view_dist<-1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
    int gold_sold;
    
    init {
        do add_desire(find_gold);
    }
        
    
    rule belief: mine_location new_desire: has_gold strength: 2.0;
  
    plan lets_wander intention: find_gold  {
    	write "hey";
        do wander;
    }
    
   

    aspect default {
      draw circle(200) color: my_color border: #black depth: gold_sold;
    }
}

experiment GoldBdi type: gui {
    output {
        display map type: opengl {
            species market ;
            species gold_mine ;
            species miner;
        }
        display chart {
        chart "Money" type: series {
        datalist legend: miner accumulate each.name value: miner accumulate each.gold_sold color: miner accumulate each.my_color;
        }
    }

    }
}