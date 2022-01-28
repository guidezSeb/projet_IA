model HelloWorldBDI

global {
    int nb_tree <- 40; 
    int nb_deer <- 20;
    int nb_wolf <- 20;
    float step <- 10#mn;
    geometry shape <- square(20 #km);
    float size_shape <- 20 #km;
    
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
    
    
	//define a new predicate that will be used as a desire
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
                loop tempDestination_w over: tempWolf.social_link_base{
                    if (tempDestination_w !=nil){
                        bool exists<-false;
                        loop tempLink_w over: socialLinkRepresentation{
                            if((tempLink_w.origin_w=tempWolf) and (tempLink_w.destination_w=tempDestination_w.agent)){
                                exists<-true;
                            }
                        }
                        if(not exists){
                            create socialLinkRepresentation number: 1{
                                origin_w <- tempWolf;
                                destination_w <- tempDestination_w.agent;
                                if(get_liking(tempDestination_w)>0){
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

//social link graph representation
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
species tree control: simple_bdi {
	
	//int branch <- rnd(1,20);
    float max_branch <- 20.0 ;
    float branch_prod <- rnd(growing_tree * 5) ; //2 branch per growing height
    float branch <- rnd(20.0) max: max_branch update: branch + branch_prod ;
    float surface_spread_x <- rnd(-1.5 #km, 1.5 #km); //seed will spread into 1.5km radius
    float surface_spread_y <- rnd(-1.5 #km, 1.5 #km);
    bool spread_tree <- true;
    float proba_spreading <- 0.01;
    float max_height <-  20.0 #m;
    float growing_tree<- rnd(0.4#cm, 0.6#cm);
    float size <- rnd(0.2 #m, 0.8 #m) max: max_height update: size + growing_tree;
    
    // change color depending to branch number
    rgb color <- rgb(int(255 * (1 - branch)), 255, int(255 * (1 - branch))) 
         update: rgb(int(255 * (1 - branch)), 255, int(255 * (1 - branch))) ;
    
   
	 aspect default {
	    draw triangle(600 + size * 20) color: (branch > 0) ? color : color border: #black;  
   	 }
   
    //new tree will spread near the parent tree to create a forest
     reflex spread when: (size <= max_height) and (flip(proba_spreading)) and (spread_tree = true) {
//     	 each tree have one seed
        create species(self) number: 1 {
            point child_pos <- myself.location + {surface_spread_x, surface_spread_y};
            float child_pos_x <- child_pos.x;
            float child_pos_y <- child_pos.y;
              //check pos_x into surface map
            if  (child_pos_x < 0.0) {
            	child_pos_x <-(child_pos_x + size_shape);
            } 
            else  if  (child_pos_x > size_shape) {
            	child_pos_x <-(child_pos_x - size_shape);
            } 
             else{ 
             	child_pos_x <- child_pos_x;
             }
            //check pos_y into surface map
            if  (child_pos_y < 0.0) {
            	child_pos_y <-(child_pos_y + size_shape);
            } 
            else  if  (child_pos_y > size_shape) {
            	child_pos_y <-(child_pos_y - size_shape);
            } 
             else{ 
             	child_pos_y <- child_pos_y;
             }
            
            child_pos <- {child_pos_x, child_pos_y};
            location <- child_pos;
            myself.spread_tree <- false;
        }
    }

}



//add the simple_bdi architecture to the agents
species deer  skills: [moving] control:simple_bdi {
//  START DEER
	float view_dist<-1000.0;
    float speed <- 45#km/#h;
   	int energy_consum <- 2;
    point target;
    int max_energy <- 100;
    int energy <- 100 update: energy - energy_consum max: max_energy;
    rgb my_color<-rnd_color(255);
    float proba_reproduce<- 0.01; //0.01 chance to reproduce
    int energy_reproduce<- 30;
    int nb_max_offsprings <- 1;
	image_file deer_image <- image_file("../includes/deer.png");
    
    aspect icon {
        //generate image
        draw deer_image size:1000;
		
    }
    
	
	//at init, add the find_branch to the agent desire base
	init {
		do add_desire(find_tree);
	}
	
	//deer only have one child 
	reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) {
		create species(self) number: 1 {
			create deer number: 1;
			location <- myself.location;
			energy <- myself.energy - energy_reproduce;
		}
	}
	//deer perceive tree with branch 
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
    
	//definition of a plan that allow to fulfill the  find_tree intention
	 plan lets_wander intention: find_tree  {
	        do wander;
	 }
	 
	 
 	plan get_branch intention:has_branch {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_tree, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target ;
	        //if deer came into his target point
	        if (target = location)  {
	        //define current tree	
	        tree current_tree<- tree first_with (target = each.location);
	        if (!dead(current_tree)) {
	        //eat until they have almost their energy back and tree has branch and tree has height under 2.5m
	        if (current_tree.branch > 0 and energy < max_energy - 10 and current_tree.size <= 2.5 #m ){
	            do add_belief(has_branch);
	            //this tree lose branch quantity
	            ask current_tree {branch <- branch - 1;}   
                energy <- energy + 10;
	        } else {
	            do add_belief(new_predicate(empty_tree_location, ["location_value"::target]));
	        }
	        //deer doesn't have a target anymore
	        target <- nil;
	        }
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
        //choose tree and define the current wolf target point
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
//    END DEER
}
	
	//    START WOLF
species wolf  skills: [moving] control:simple_bdi {
	//VARIABLE
	float view_dist<-1000.0;
    float speed <- 55#km/#h;
   	int energy_w_consum <- 2;
    point target_w;
    int max_energy_w <- 100;
    int energy_w <- 100 update: energy_w - energy_w_consum max: max_energy_w;
    rgb my_color<-rnd_color(255);
    float proba_reproduce_w<- 0.01; //0.01 chance to reproduce
    int energy_w_reproduce<- 30;
    int nb_max_offsprings_w <- 1;
    deer agent_perceived <- nil;
  	image_file wolf_image <- image_file("../includes/wolf.png");
    
    aspect icon {
        //generate image
        draw wolf_image size:1000;
    }
    
	//define a new predicate that will be used as a desire
    predicate find_deer <- new_predicate("find deer") ;
	
	//at init, add the find_energy to the agent desire base
	init {
		do add_desire(find_deer);
	}
	
	//wolf only have one child
	reflex reproduce when: (energy_w >= energy_w_reproduce) and (flip(proba_reproduce_w)) {
		create species(self) number: 1 {
			create wolf number: 1;
			location <- myself.location;
			energy_w <- myself.energy_w - energy_w_reproduce;
		}
	}
	
	 perceive target: deer where (each.energy > 0) in: view_dist {
	    focus id:deer_at_location var:location;
	    //define perceived deer has a variable usable in wolf
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
	    if (target_w = nil) {
	        do add_subintention(get_current_intention(),choose_deer, true);
	        do current_intention_on_hold();
	    } else {
	    	//if deer alive
	    	if (!dead(agent_perceived)) {
		        do goto target: agent_perceived.location ;
	        	//if wolf came into his target point
		        if ( target_w = agent_perceived.location)  {
		        	//if deer has energy and wolf not have max energy (if he has, he doesn't need to eat)
		        if (agent_perceived.energy > 0 and energy_w < max_energy_w){
		             do add_belief(has_energy);
		        } else {
		            do remove_belief(new_predicate(deer_at_location, ["location_value"::agent_perceived.location]));
		            do add_belief(new_predicate(empty_deer_location, ["location_value"::agent_perceived.location]));
		        }
		    
		        }
		          //deer doesn't have a target anymore
		            target_w <- nil;
	        
	        }
	    }   
    }
    //when has energy wolf get deer's energy and the deer dies
    	plan transfer_energy intention: eat_energy when: has_belief(has_energy){
			do remove_belief(has_energy);
			do remove_intention(eat_energy, true);
			if (!dead(agent_perceived)) {
			 	energy_w <- energy_w + agent_perceived.energy;
			 }
			 else{
			 	//not gain energy
			 	energy_w <- energy_w;
			 }
			 do add_intention(find_deer);
			//kill deer after drain
			 ask agent_perceived {do die;}

	
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
    //choose deer and define the current wolf target point
    plan choose_closest_deer intention: choose_deer instantaneous: true {
        list<point> possible_deers <- get_beliefs_with_name(deer_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        list<point> empty_deers <- get_beliefs_with_name(empty_deer_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
        possible_deers <- possible_deers - empty_deers;
        if (empty(possible_deers)) {
            do remove_intention(has_energy, true); 
        } else {
            target_w <- (possible_deers with_min_of (each distance_to self)).location;
        }
        do remove_intention(choose_deer, true); 
    }
//    END wolf
}

experiment HelloWorldBDI type: gui {
    output {
        display map type: opengl {
        species deer aspect: icon;
        species tree ;
        species wolf  aspect: icon;
    }
       display socialLinks type: opengl{
        species socialLinkRepresentation aspect: base;
      
    }
      	monitor "Number of deer" value: stat_nb_deer;
		monitor "Number of tree" value: stat_nb_tree;
		monitor "Number of wolf" value: stat_nb_wolf;
    }
}