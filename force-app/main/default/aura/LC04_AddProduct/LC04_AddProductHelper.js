({
	getProd : function(component) {
        var action = component.get("c.getAllProducts");
        //Setting the Callback
        action.setParams({
            objID: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var result = a.getReturnValue();
                if(!$A.util.isEmpty(result) && !$A.util.isUndefined(result)){
                	component.set("v.lstProduct",result);
                }
                else if($A.util.isEmpty(result)){
                	component.set("v.lstProduct",result);
                	component.set("v.errorMsg",'All products have already been added or there are no products related to this offer.');
                	$A.get('e.force:refreshView').fire();
                }   
            }
            else if(state == "ERROR"){
                console.log('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    saveSelectedProdHelper: function(component, event, selectedProducts) {
	  	//call apex class method
	  	var action = component.get('c.saveRecords');
	  	// pass the all selected record's Id's to apex method 
	  	action.setParams({
	   		"lstProdId": selectedProducts,
	   		"objID": component.get("v.recordId") 
	  	});
	  	action.setCallback(this, function(response) {
	   		//store state of response
	   		var state = response.getState();
	   		if (state === "SUCCESS"){
	   			var result = response.getReturnValue();
	             if($A.util.isEmpty(result)){
	             	component.set("v.ShowModule", false);
					this.getProd(component);
	            }
	            else{
	            	alert(result);
	            	$A.get('e.force:refreshView').fire();
	            }
	        }
	        else if(state == "ERROR"){
	        	alert(state);
	            console.log('Error in calling server side action');
	            $A.get('e.force:refreshView').fire();
	        }
	        $A.get('e.force:refreshView').fire();
	        this.getProd(component);
	    });
	    $A.enqueueAction(action);
	},
})