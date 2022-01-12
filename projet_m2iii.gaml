/***
* Name: BDIdeer
***/

model BDItutorial3

global {
    //deer eat tree's branch
    int nb_trees <- 10;
    int nb_deers <-5; 
    tree the_tree;
    // geometry shape <- square(20 #km);
    float step <- 5#mn;
	
	string tree_at_location <- "tree_at_location";
	string empty_tree_location <- "empty_tree_location";	
	
	//possible predicates concerning trees
	predicate tree_location <- new_predicate(tree_at_location) ;
	predicate choose_tree <- new_predicate("choose a branch tree");
	predicate eat_branch <- new_predicate("eat branch");
	predicate find_branch <- new_predicate("find branch") ;
	predicate share_information <- new_predicate("share information") ;
	
	float inequality <- 0.0 update: standard_deviation(deers collect each.branch_eat);
	
	init {
		create tree {
			the_tree <- self;	
		}
		create deer number: nb_deers;
		create tree number: nb_trees;
		
		
	}


	// reflex display_social_links{
	// 	loop tempdeer over: deer{
	// 			loop tempDestination over: tempdeer.social_link_base{
	// 				if (tempDestination !=nil){
	// 					bool exists<-false;
	// 					loop tempLink over: socialLinkRepresentation{
	// 						if((tempLink.origin=tempdeer) and (tempLink.destination=tempDestination.agent)){
	// 							exists<-true;
	// 						}
	// 					}
	// 					if(not exists){
	// 						create socialLinkRepresentation number: 1{
	// 							origin <- tempdeer;
	// 							destination <- tempDestination.agent;
	// 							if(get_liking(tempDestination)>0){
	// 								my_color <- #green;
	// 							} else {
	// 								my_color <- #red;
	// 							}
	// 						}
	// 					}
	// 				}
	// 			}
	// 		}
	// }
	
	
}


species tree {
    int quantity <- rnd(1,10); //branch on tree
	int branchs;
    aspect default {
        draw triangle(1 + quantity * 1) color: (quantity > 0) ? #green : #brown;    
    }
}

species deer {
	aspect default {
	  draw square(1) color: #yellow ;
	}
}

species deers skills: [moving] control:simple_bdi {
	
	float view_dist<-1000.0;
	float speed <- 5#km/#h;
	rgb my_color<-rnd_color(255);
	point target;
	int branch_eat;

    bool use_social_architecture <- true;
	
	init {
		do add_desire(find_branch);
	}
	
	perceive target: tree in: view_dist {
		socialize liking: 1 -  point(myself.my_color.red, myself.my_color.green, myself.my_color.blue) distance_to point(myself.my_color.red, myself.my_color.green, myself.my_color.blue) / 255;
		//créer un lien social "physique" que l'on affiche avec en couleur, vert pour liking positif et rouge pour liking négatif
		//s'assurer qu'on a seulement 1 lien physique par lien social.
		//l'aspect sera une ligne droite avec chaque bout placé à la location de chaque agent à ses bouts
		//Faire cet affichage dans un réflexe global
	}
		
	perceive target: tree where (each.quantity > 0) in: view_dist {
		focus id: tree_at_location var:location;
		ask myself {
			do add_desire(predicate:share_information, strength: 5.0);
			do remove_intention(find_branch, false);
		}
	}
	
	rule belief: tree_location new_desire: eat_branch strength: 2.0;
	//rule belief: eat_branch new_desire: sell_branch strength: 3.0;
	
		
	plan lets_wander intention: find_branch finished_when: has_desire(eat_branch) {
		do wander;
	}
	
	plan get_branch intention:eat_branch 
	{
		if (target = nil) {
			do add_subintention(get_current_intention(),choose_tree, true);
			do current_intention_on_hold();
		} else {
			do goto target: target ;
			if (target = location)  {
				tree current_tree<- tree first_with (target = each.location);
				if current_tree.quantity > 0 {
				 	do add_belief(eat_branch);
					ask current_tree {quantity <- quantity - 1;}	
				} else {
					do add_belief(new_predicate(empty_tree_location, ["location_value"::target]));
				}
				target <- nil;
			}
		}	
	}
	
	 plan choose_closest_tree intention: choose_tree instantaneous: true {
		list<point> possible_tree <- get_beliefs_with_name(tree_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> empty_trees <- get_beliefs_with_name(empty_tree_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		possible_tree <- possible_tree - empty_trees;
		if (empty(possible_tree)) {
			do remove_intention(eat_branch, true); 
		} else {
			target <- (possible_tree with_min_of (each distance_to self)).location;
		}
		do remove_intention(choose_tree, true); 
	}
	
	// plan return_to_base intention: sell_branch {
		// do goto target: the_tree ;
		// if (the_tree.location = location)  {
		// 	do remove_belief(eat_branch);
		// 	// do remove_intention(sell_branch, true);
		// 	branch_eat <- branch_eat + 1;
		// }
	// }
	
	plan share_information_to_friends intention: share_information instantaneous: true {
		list<deers> my_friends <- list<deers>((social_link_base where (each.liking > 0)) collect each.agent);
		loop known_tree over: get_beliefs_with_name(tree_at_location) {
			ask my_friends {
				do add_directly_belief(known_tree);
			}
		}
		loop known_empty_tree over: get_beliefs_with_name(empty_tree_location) {
			ask my_friends {
				do add_directly_belief(known_empty_tree);
			}
		}
		
		do remove_intention(share_information, true); 
	}

	aspect default {
	  draw circle(5) color: my_color border: #black depth: branch_eat;
	  draw circle(view_dist) color: my_color border: #black depth: branch_eat empty: true;
	}
}

species socialLinkRepresentation{
	tree origin;
	agent destination;
	rgb my_color;
	
	aspect base{
		draw line([origin,destination],50.0) color: my_color;
	}
}


experiment branchBdi type: gui {
	output {
		display map type: opengl {
			species tree ;
			species deer ;
		}
		
		display socialLinks type: opengl{
			species socialLinkRepresentation aspect: base;
		}
		
		// display chart {
		// 	chart "Money" type: series {
		// 		datalist legend: tree accumulate each.name value: tree accumulate each.branch_eat color: tree accumulate each.my_color;
		// 	}
		// }
		
	}
}
