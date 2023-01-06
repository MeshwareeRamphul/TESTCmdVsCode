({
    createEsign : function(component, event, helper) {
        var recordid = component.get("v.recordId");
        var action = component.get("c.validateCreateSign");
        action.setParams({ "contractId": recordid });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
                //capture nad display errors returned
                if(result.error){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error"
                    });
                    toastEvent.fire();                                             
                }
                //display success message
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": 'eSignature created successfully',
                        "type" : "success"
                    });
                    toastEvent.fire();  
                    
                     var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": result.esignId,
                        "slideDevName": "related" 
                    });
                    
                    navEvt.fire();
                }
            }                            
        });
        // Send action off to be executed
        $A.enqueueAction(action);
	}
})