model HelloWorldBDI

global {
    int nb_tree <- 0; 
    int nb_deer <- 20;
    int nb_wolf <- 20;
    float step <- 10#mn;
    geometry shape <- square(20 #km);
    
    string tree_at_location <- "tree_at_location";
    string empty_tree_location <- "empty_tree_location";
    
    string deer_at_location <- "deer_at_location";
    string empty_deer_location <- "empty_deer_location";

    //predication
    predicate tree_location <- new_predicate(tree_at_location) ;
    predicate find_tree <- new_predicate("find tree") ;
    predicate has_branch <- new_predicate("extract branch");
    predicate eat_branch <- new_predicate("eat branch") ;
    predicate choose_tree <- new_predicate("choose a tree");
    predicate find_branch <- new_predicate("find branch");
    predicate share_information <- new_predicate("share information") ;
    
	predicate deer_location <- new_predicate(deer_at_location) ;
    predicate has_energy <- new_predicate("extract energy");
    predicate eat_energy <- new_predicate("eat energy") ;
    predicate choose_deer <- new_predicate("choose a deer");
    predicate find_energy <- new_predicate("find energy");
    predicate share_information_w <- new_predicate("share information wolf") ;
 	
 	//stat variable
 	int stat_nb_deer -> {length(deer)};
	int stat_nb_tree -> {length(tree)};
	int stat_nb_wolf -> {length(wolf)};
    
    init {
    create deer number: nb_deer;
    create tree number: nb_tree;
    create wolf number: nb_wolf;
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
             loop tempWolf over: wolf{
                loop tempDestination over: tempWolf.social_link_base{
                    if (tempDestination !=nil){
                        bool exists<-false;
                        loop tempLink_w over: socialLinkRepresentation{
                            if((tempLink_w.origin_w=tempWolf) and (tempLink_w.destination_w=tempDestination.agent)){
                                exists<-true;
                            }
                        }
                        if(not exists){
                            create socialLinkRepresentation number: 2{
                                origin_w <- tempWolf;
                                destination <- tempDestination.agent;
                                if(get_liking(tempDestination)>0){
                                    my_color <- #blue;
                                } else {
                                    my_color <- #yellow;
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
	
	//int branch <- rnd(1,20);
    float max_branch <- 20.0 ;
    float branch_prod <- rnd(5.0) ;
    float branch <- rnd(20.0) max: max_branch update: branch + branch_prod ;
    
    // coloration des cellules de la grid en fonction de leur niveau de nourriture disponible
    rgb color <- rgb(int(255 * (1 - branch)), 255, int(255 * (1 - branch))) 
         update: rgb(int(255 * (1 - branch)), 255, int(255 * (1 - branch))) ;
    
    // ajout d'une varibale neighbor2 qui contient la liste des cellules voisines à une distance de 2
   
 aspect default {
    draw triangle(600 + branch * 20) color: (branch > 0) ? color : color border: #black;  
    }
    

}

species socialLinkRepresentation{
	    deer origin;
		wolf origin_w;
	    agent destination;
	    agent destination_w;
	    rgb my_color;
	    
	    aspect base{
	        draw line([origin,destination],50.0) color: my_color;
	        draw line([origin_w,destination_w],50.0) color: my_color;
	    }
}

//add the simple_bdi architecture to the agents
species deer  skills: [moving] control:simple_bdi {
//    START DEER
	float view_dist<-1000.0;
    float speed <- 2#km/#h;
   	int energy_consum <- 5;
    point target;
    int max_energy <- 100;
    int energy <- 100 update: energy - energy_consum max: max_energy;
    rgb my_color<-rnd_color(255);
    float proba_reproduce<- 0.01; //0.01 chance to reproduce
    int energy_reproduce<- 30;
    int nb_max_offsprings <- 1;
    
    
    aspect default {
        draw square(300) color: #black ;
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
//        write "possible tree= " + possible_trees;
        if (empty(possible_trees)) {
            do remove_intention(has_branch, true); 
        } else {
            target <- (possible_trees with_min_of (each distance_to self)).location;
        }
        do remove_intention(choose_tree, true); 
    }
//    END DEER
}
	
	//    START WOLF
species wolf  skills: [moving] control:simple_bdi {
//VARIABLE
	float view_dist<-1000.0;
    float speed <- 2#km/#h;
   	int energy_w_consum <- 5;
    point target_w;
    int max_energy_w <- 100;
    int energy_w <- 100 update: energy_w - energy_w_consum max: max_energy_w;
    rgb my_color<-rnd_color(255);
    float proba_reproduce_w<- 0.01; //0.01 chance to reproduce
    int energy_w_reproduce<- 30;
    int nb_max_offsprings_w <- 1;
    deer agent_perceived <- nil;
   
    
    aspect default {
        draw square(300) color: #red ;
    }
    
	//define a new predicate that will be used as a desire
    predicate find_deer <- new_predicate("find deer") ;
	
	//at init, add the find_energy to the agent desire base
	init {
		do add_desire(find_deer);
	}
	
//	reflex reproduce when: (energy_w >= energy_w_reproduce) and (flip(proba_reproduce_w)) {
//		
//		create species(self) number: 1 {
//			create wolf number: 1;
//			location <- myself.location;
//			energy_w <- myself.energy_w - energy_w_reproduce;
//		}
//
//		
//	}
	
	 perceive target: deer where (each.energy > 0) in: view_dist {
	    focus id:deer_at_location var:location;
	    myself.agent_perceived <-self;
	    ask myself {
	    	do add_desire(predicate:share_information, strength: 5.0);
	        do remove_intention(find_deer, false);
	    }
    }
    perceive target: wolf in: view_dist {
    socialize liking: 1 -  point(my_color.red, my_color.green, my_color.blue) distance_to point(myself.my_color.red, myself.my_color.green, myself.my_color.blue) / 255;
    }
    
    reflex die when: energy_w <= 0 {
		do die;
	}
    
    rule belief: deer_location new_desire: has_energy strength: 2.0;
    rule belief: has_energy new_desire: eat_energy strength: 3.0;
    
	//definition of a plan that allow to fulfill the  find_energy intention
	 plan lets_wander_wolf intention: find_deer  {
	        do wander;
	 }
	 
 	plan get_energy intention:has_energy {
// 		write "actual target_w" + target_w;
	    if (target_w = nil) {
	        do add_subintention(get_current_intention(),choose_deer, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: agent_perceived.location ;
	        if (target_w = location)  {
	        
			//write dead(agent_perceived);
	        //eat until they have almost their energy_w back
	        //if deer alive
	        if (dead(agent_perceived) = false ) {
	        	//if deer has energy and wolf not have max energy
	        if (agent_perceived.energy > 0 and energy_w < max_energy_w){
	           energy_w <- energy_w + agent_perceived.energy;
	            do add_belief(has_energy);
	            ask agent_perceived {do die;}
	        } else {
	            do remove_belief(new_predicate(deer_at_location, ["location_value"::target_w]));
	            do add_belief(new_predicate(empty_deer_location, ["location_value"::target_w]));
	            
	            
	        }
	        target_w <- nil;
	        }
	        
	        }
	    }   
    }
    
    plan share_information_to_friends intention: share_information_w instantaneous: true{
    list<wolf> my_friends_wolf <- list<wolf>((social_link_base where (each.liking > 0)) collect each.agent);
    loop known_deer over: get_beliefs_with_name(deer_at_location) {
        ask my_friends_wolf {
          do add_belief(known_deer);
        }
    }
    loop known_empty_deer over: get_beliefs_with_name(empty_deer_location) {
        ask my_friends_wolf {
        do add_belief(known_empty_deer);
        }
    }
        
    do remove_intention(share_information, true); 
    }
    
    plan choose_closest_deer intention: choose_deer instantaneous: true {
        list<point> possible_deers <- get_beliefs_with_name(deer_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        list<point> empty_deers <- get_beliefs_with_name(empty_deer_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        possible_deers <- possible_deers - empty_deers;
        write "possible deer= " + possible_deers;
        if (empty(possible_deers)) {
            do remove_intention(has_energy, true); 
//            write "not having energy anymore";
        } else {
            target_w <- (possible_deers with_min_of (each distance_to self)).location;
            write "new target wolf= "+ target_w;
        }
        do remove_intention(choose_deer, true); 
    }
//    END wolf
}

experiment HelloWorldBDI type: gui {
    output {
        display map type: opengl {
        species deer ;
        species tree ;
        species wolf ;
    }
       display socialLinks type: opengl{
        species socialLinkRepresentation aspect: base;
      
    }
      	monitor "Number of deer" value: stat_nb_deer;
		monitor "Number of tree" value: stat_nb_tree;
		monitor "Number of wolf" value: stat_nb_wolf;
    }
}