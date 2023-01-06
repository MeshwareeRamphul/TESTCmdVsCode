({
    doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var ctrFormId = component.get("v.recordId");   
		var action = component.get("c.remind");
        action.setParams({ 
            "contractFormId": ctrFormId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log('state : ', state);
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
                    $A.get("e.force:closeQuickAction").fire();                          
                }
                else{
                    component.set("v.showSpinner", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success", 
                        "message": $A.get("$Label.c.cTin_ReminderSent"),
                        "type" : "success"
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();  
                }
            } 
            else {
                console.log('Error' + response.getReturnValue());
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": response.getReturnValue(),
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