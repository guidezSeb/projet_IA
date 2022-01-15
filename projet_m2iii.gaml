
model HelloWorldBDI

global {
    int nb_tree <- 40; 
    int nb_deer <- 10;
    float step <- 10#mn;
    geometry shape <- square(20 #km);
    
    string tree_at_location <- "tree_at_location";
    string empty_tree_location <- "empty_tree_location";

    //predication
    predicate tree_location <- new_predicate(tree_at_location) ;
    predicate find_tree <- new_predicate("find tree") ;
    predicate has_branch <- new_predicate("extract branch");
    predicate eat_branch <- new_predicate("eat branch") ;
    predicate choose_tree <- new_predicate("choose a tree");
    predicate find_branch <- new_predicate("find branch");
    predicate share_information <- new_predicate("share information") ;

    init {
    create deer number: nb_deer;
    create tree number: nb_tree;
    }
    // END SIMULATION
    // reflex end_simulation when: sum(deer collect each.energy) = 0{
    //     do pause;
    //     ask deer {
    //     write deer + " : " +energy;
    // }
    // }
    	reflex display_social_links{
        loop tempDeer over: deer{
                loop tempDestination over: tempDeer.social_link_base{
                    if (tempDestination !=nil){
                        bool exists<-false;
                        loop tempLink over: socialLinkRepresentation{
                            if((tempLink.origin=tempDeer) and (tempLink.destination=tempDestination.agent)){
                                exists<-true;
                            }
                        }
                        if(not exists){
                            create socialLinkRepresentation number: 1{
                                origin <- tempDeer;
                                destination <- tempDestination.agent;
                                if(get_liking(tempDestination)>0){
                                    my_color <- #green;
                                } else {
                                    my_color <- #red;
                                }
                            }
                        }
                    }
                }
            }
    }
}


//add the simple_bdi architecture to the agents
species tree control: simple_bdi {
	
	int branch <- rnd(1,20);
    aspect default {
    draw triangle(200 + branch * 20) color: (branch > 0) ? #green : #gray border: #black;  
    }
    

}

species socialLinkRepresentation{
	    deer origin;
	    agent destination;
	    rgb my_color;
	    
	    aspect base{
	        draw line([origin,destination],50.0) color: my_color;
	    }
}

//add the simple_bdi architecture to the agents
species deer  skills: [moving] control:simple_bdi {
	float view_dist<-1000.0;
    float speed <- 2#km/#h;
   	int energy_consum <- 1;
    point target;
    int max_energy <- 100;
    int energy <- 100 update: energy - energy_consum max: max_energy;
    rgb my_color<-rnd_color(255);
    float proba_reproduce<- 0.01; //0.01 chance to reproduce
    int energy_reproduce<- 30;
    int nb_max_offsprings <- 1;
    
    
    aspect default {
        draw square(500) color: #black ;
    }
    
	//define a new predicate that will be used as a desire
	
	
	//at init, add the find_branch to the agent desire base
	init {
		do add_desire(find_tree);
	}
	
	reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) {
		
		create species(self) number: 1 {
			create deer number: 1;
			location <- myself.location;
			energy <- myself.energy - energy_reproduce;
		}

		
	}
	
	 perceive target: tree where (each.branch > 0) in: view_dist {
	    focus id:tree_at_location var:location;
	    ask myself {
	    	do add_desire(predicate:share_information, strength: 5.0);
	        do remove_intention(find_tree, false);
	    }
    }
    perceive target: deer in: view_dist {
    socialize liking: 1 -  point(my_color.red, my_color.green, my_color.blue) distance_to point(myself.my_color.red, myself.my_color.green, myself.my_color.blue) / 255;
    }
    
    reflex die when: energy <= 0 {
		do die;
	}
    
    rule belief: tree_location new_desire: has_branch strength: 2.0;
    rule belief: has_branch new_desire: eat_branch strength: 3.0;
    
	//definition of a plan that allow to fulfill the  find_branch intention
	 plan lets_wander intention: find_tree  {
	        do wander;
	 }
	 
 	plan get_branch intention:has_branch {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_tree, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target ;
	        if (target = location)  {
	        tree current_tree<- tree first_with (target = each.location);
	        //eat until they have almost their energy back
	        if current_tree.branch > 0 and energy < max_energy - 10{
	            do add_belief(has_branch);
	            ask current_tree {branch <- branch - 1;}   
                energy <- energy + 10;
	        } else {
	            do add_belief(new_predicate(empty_tree_location, ["location_value"::target]));
	        }
	        target <- nil;
	        }
	    }   
    }
    
    plan share_information_to_friends intention: share_information instantaneous: true{
    list<deer> my_friends <- list<deer>((social_link_base where (each.liking > 0)) collect each.agent);
    loop known_tree over: get_beliefs_with_name(tree_at_location) {
        ask my_friends {
          do add_belief(known_tree);
        }
    }
    loop known_empty_tree over: get_beliefs_with_name(empty_tree_location) {
        ask my_friends {
        do add_belief(known_empty_tree);
        }
    }
        
    do remove_intention(share_information, true); 
    }
    
    plan choose_closest_tree intention: choose_tree instantaneous: true {
        list<point> possible_trees <- get_beliefs_with_name(tree_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        list<point> empty_trees <- get_beliefs_with_name(empty_tree_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        possible_trees <- possible_trees - empty_trees;
        if (empty(possible_trees)) {
            do remove_intention(has_branch, true); 
        } else {
            target <- (possible_trees with_min_of (each distance_to self)).location;
        }
        do remove_intention(choose_tree, true); 
    }
    
}
	

experiment HelloWorldBDI type: gui {
    output {
        display map type: opengl {
        species deer ;
        species tree ;
    }
       display socialLinks type: opengl{
        species socialLinkRepresentation aspect: base;
    }
    }
}