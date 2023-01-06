({
    //method display error message
	doInit : function(component, event, helper) {
        var contractId = component.get("v.recordId");
       // $A.get("e.force:closeQuickAction").fire(); 
		console.log("## record id :",contractId);      
		var action = component.get("c.validateClone");
        action.setParams({ "contractId": contractId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
               
                //check if error
                if(result.error){
                    console.log('1');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error"
                    });
                    toastEvent.fire(); 
                    $A.get("e.force:closeQuickAction").fire();                          
                }
                else{
                     console.log('2');
                    //$A.get("e.force:closeQuickAction").fire(); 
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": $A.get("$Label.c.LC32_DuplicateSuccess"),
                        "type" : "success"
                    });
                    toastEvent.fire();
                    //redirect to cloned contract
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": result.newcontact,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            } 
            else {
                console.log('Error');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": a.getReturnValue(),
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }         
        });
        // Send action off to be executed
        $A.enqueueAction(action);
	}
})