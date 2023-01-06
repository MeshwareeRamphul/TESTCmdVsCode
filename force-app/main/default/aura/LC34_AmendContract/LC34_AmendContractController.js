({

    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    //method display error message
	doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var contractId = component.get("v.recordId");       
		console.log("## record id :",contractId);      
		var action = component.get("c.validateAmend");
        action.setParams({ "contractId": contractId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
               
                //check if error
                if(result.error){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error"
                    });
                    toastEvent.fire(); 
                   // component.set("v.showSpinner", false);
                    $A.get("e.force:closeQuickAction").fire();                          
                }
                else{
                    //component.set("v.showSpinner", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message":$A.get("$Label.c.LC34_AmendSuccess"),
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
                //component.set("v.showSpinner", false);
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