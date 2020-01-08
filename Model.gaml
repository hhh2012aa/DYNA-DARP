model model1

global {
    int nb_request <- 50;
    int nb_vehicle <- 40;
    float step <- 1 #sec;
    geometry shape <- square(20 #km);
    float mileage <- 0.0;
    int satisfied_req <- 0;
    int unsatisfied_req <- 0;
    float speed1 <- 6.9444; 
   
    reflex stop_simulation when: current_date - starting_date = 43200 {
    	do pause ;
    } 
    
    reflex dynamic_request when:  current_date - starting_date  <= 39180{
		if rnd (400) = 1
		{
			create dest number:1;
			create origin number:1;
		}
	}
    
    init{
	create dest number:nb_request;
    create origin number:nb_request;
    create vehicle number:nb_vehicle/2 {location <- {5000, 10000};}
    create vehicle number:nb_vehicle/2 {location <- {15000, 10000};}
    //create vehicle number:1 {location <- {5000, 10000};}
    //create vehicle number:1 {location <- {15000, 10000};}
    }
}



species dest {
	int area_d;
	bool paired <- false;
	bool already <- false;
	
		init{
		
			if location.x <= 10000
				{ area_d <- 1 ;}
			else
				{ area_d <- 2 ;}
		}
		
		
	    aspect circle {
        	draw circle(200)  color:already? #white : #blue;
    	}
}





species origin {
	
		int area_o;
	    int time_window <- rnd(43200 - int(current_date)) + int(current_date) ;
	    agent partner1;
	    bool satisfied <- false;

		init{
			
	 	partner1 <- one_of ((dest) where (each.paired = false));
	 		ask dest(partner1) {paired <- true;}
	 	
				if location.x <= 10000
					{ area_o <- 1;}
				else
					{area_o <- 2 ;}
			}	
		
	 
	    aspect circle {
        	draw circle(200) color: satisfied? #white : #red;
    	}
}


species vehicle skills:[moving]{
	float speed <- 20 #km/#h;
	point the_target <- nil ;
	agent agent_closet1;
	agent agent_closet1_dest;
	agent agent_closet2;
	agent agent_closet2_dest;
	agent VV <- self;
	int status;
	int area_v;
	int passenger <- 0;
	
	init {
		status <- 0;
			if location.x <= 10000
				{ area_v <- 1;}
			else
				{ area_v <- 2 ;}		
	}
	
	//list<agent> near_agents <- agents_at_distance (20#km) of_species origin;

    bool time_window_constraint (agent V1, agent O1) {
    
 	bool tw_bool;
 	int TW1 <- origin(O1).time_window;
 	
 	float Dis1 <- V1 distance_to O1; //加入GIS後要改
 	float tv_time1 <- Dis1 / speed1;
 	int date1 <- int(current_date);
 	if TW1 < date1 {return false;}
 	if TW1 < (date1 + tv_time1) and (date1 + tv_time1) < TW1 + 9000{
 		tw_bool <- true;
 		}
 	else{
 		tw_bool <- false;
 		}
 	return tw_bool;
 	} 
 
 
 	bool vehicle_sharing (agent origin1,agent new_origin) {
 		bool share <- false;
 		agent dest1 <- origin(origin1).partner1;
 		agent new_dest <-  origin(new_origin).partner1;
 		float Dis1 <- origin1 distance_to dest1;
 		float Dis2 <- new_origin distance_to new_origin;
 		float Extra_Dis <- (origin1  distance_to new_origin) + Dis2 + (new_dest distance_to dest1);
 		
 		if Extra_Dis < Dis1 / 2{
 			share <- true;
 		}
 		else {
 			share <- false;
 		}
		return share;
		write share;
		
 		}
 	
 	int now_area{
 		
 		if location.x <= 10000
				{ return  1;}
			else
				{ return 2 ;}
 		
 	}
 
 	
	
    aspect square {
        draw square(500) color: #green;
    }
    
     reflex time_to_go when: status = 0  {
        	
	 	if passenger = 0 {
	        	list<agent> agent_closet0 <- origin where ((each.satisfied = false) and (each.area_o = self.area_v)) at_distance 10 #km;
			
				if area_v != now_area  {
	        		
	 			 		list<agent> agent_closet0 <- agent_closet0 + origin where ((each.satisfied = false) and (each.area_o != self.area_v) and (each.area_o != dest(each.partner1).area_d)) at_distance 10 #km;
	 				
	 			}
	 		
	 			agent_closet1 <- agent_closet0 where(time_window_constraint(VV,each) = true) closest_to self;
	       		if agent_closet1 != nil or dead(agent_closet1) != true{
	         		status <- 1;
	         		
	         		agent_closet1_dest <- origin(agent_closet1).partner1;
	         		origin(agent_closet1).satisfied <- true;
	      		
	         		satisfied_req <- satisfied_req + 1;			
	         } 
	  		}
	  
 		else if passenger = 1 {
	        list<agent> agent_closet0 <- origin where ((each.satisfied = false) and (each.area_o = self.area_v)) at_distance 10 #km;
			
	 			
	 		
	 				agent_closet2 <- agent_closet0 where(time_window_constraint(VV,each) = true) closest_to self;

	       		if (agent_closet2 != nil) {
	         		if vehicle_sharing(agent_closet1 , agent_closet2){
	         			status <- 1;
	         			agent_closet2_dest <- origin(agent_closet2).partner1;
	         			write agent_closet2_dest;
	         			origin(agent_closet2).satisfied <- true;
	         			satisfied_req <- satisfied_req + 1;			
	         		}
	         		else {
	         			agent_closet2 <- nil;
	         			status <- 1;
	         		}
	         		}
	         }
	         	else
	         		{
	         			agent_closet2 <- nil;
	         			status <- 1;
	         		} 
	         
	         	
	         }
	         	
	  			
	  
  
 		 
  
  
	reflex move_O when: status = 1 {
		
		if passenger = 0 {
			do goto target: agent_closet1  ;
			mileage <- mileage + 6.9444 / 1000 ;
						
			if location = origin(agent_closet1).location {
				status <- 0; //??
				passenger <- passenger + 1;
				//agent_closet1 <- nil;

			}
		 }
		 else if passenger = 1 {
		 	
		 	if agent_closet2 != nil
		 	{
				do goto target: agent_closet2  ;
				mileage <- mileage + 6.9444 / 1000 ;
						
				if location = origin(agent_closet2).location {
					status <- 2;
					passenger <- passenger + 1;
					agent_closet2 <- nil;
					write "55564";
			}	
			}
			else
			{
				status <- 2;
			}
		 }
		 
	}
	
   	reflex move_D when: status = 2 {
		
		
		if passenger = 1{
			do goto target: agent_closet1_dest;
			mileage <- mileage + 6.9444 / 1000 ;
		
			if location = agent_closet1_dest.location {
				passenger <- passenger - 1;
				status <- 0;	
				dest(agent_closet1_dest).already <- true;
				agent_closet1_dest <- nil;	
		}		
	}
	
		else if passenger = 2{
			do goto target: agent_closet2_dest;
			mileage <- mileage + 6.9444 / 1000 ;
		
			if location = agent_closet2_dest.location {
				passenger <- passenger - 1;
				status <- 2;	
				dest(agent_closet2_dest).already <- true;
				agent_closet2_dest <- nil;	
		}		
	}
	
	
	
	
	}
	
 }

experiment main type: gui {

    output {
    display map {
        species vehicle aspect:square; 
        species origin aspect:circle;
        species dest aspect:circle;   
    }
    }
}
