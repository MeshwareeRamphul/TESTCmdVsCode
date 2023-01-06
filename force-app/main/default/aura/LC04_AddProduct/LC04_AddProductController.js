({
	doInit: function(component, event, helper) {
        helper.getProd(component, event, helper);
	},
    cancel: function(component, event, helper) {
    	component.set("v.ShowModule", false);
    },
    ShowModuleBox: function(component, event, helper) {
    	component.set("v.ShowModule", true);
    },
    saveSelectedProducts: function(component, event, helper) {
        var selectedProducts= [];
        var checkvalue = component.find("checkProduct");
         
        if(!Array.isArray(checkvalue)){
            if (checkvalue.get("v.value") == true) {
                selectedProducts.push(checkvalue.get("v.text"));
            }
        }
        else{
            for (var i = 0; i < checkvalue.length; i++) {
                if (checkvalue[i].get("v.value") == true){
                    selectedProducts.push(checkvalue[i].get("v.text"));
                }
            }
        }
        // call the helper function and pass all selected record id's.    
      	helper.saveSelectedProdHelper(component, event, selectedProducts);
    },
    // For count the selected checkboxes. 
 	checkboxSelect: function(component, event, helper) {
	  	// get the selected checkbox value  
	  	var selectedRec = event.getSource().get("v.value");
	  	// get the selectedCount attrbute
	  	var getSelectedNumber = component.get("v.selectedCount");
	  	// check, if selected checkbox value is true then increment getSelectedNumber with 1 
	  	// else Decrement the getSelectedNumber with 1     
	  	if (selectedRec == true) {
	   		getSelectedNumber++;
	  	} 
	  	else{
	   		getSelectedNumber--;
	  	}
	  	// set the actual value on selectedCount attribute to show on header part. 
	  	component.set("v.selectedCount", getSelectedNumber);
 	},
 	// For select all Checkboxes 
 	selectAll: function(component, event, helper) {
  		//get the header checkbox value  
  		var selectedHeaderCheck = event.getSource().get("v.value");
 		var getAllId = component.find("checkProduct"); 
     	if(! Array.isArray(getAllId)){
       		if(selectedHeaderCheck == true){ 
          		component.find("checkProduct").set("v.value", true);
          		component.set("v.selectedCount", 1);
       		}
       		else{
           		component.find("checkProduct").set("v.value", false);
           		component.set("v.selectedCount", 0);
       		}
     	}
     	else{
       		// check if select all (header checkbox) is true then true all checkboxes on table in a for loop  
       		// and set the all selected checkbox length in selectedCount attribute.
       		// if value is false then make all checkboxes false in else part with play for loop 
       		// and select count as 0 
        	if (selectedHeaderCheck == true) {
        		for (var i = 0; i < getAllId.length; i++) {
  		  			component.find("checkProduct")[i].set("v.value", true);
   		 			component.set("v.selectedCount", getAllId.length);
        		}		
        	} 
        	else{
          		for (var i = 0; i < getAllId.length; i++) {
    				component.find("checkProduct")[i].set("v.value", false);
   			 		component.set("v.selectedCount", 0);
  	    		}
       		} 
     	}  
 	},
})