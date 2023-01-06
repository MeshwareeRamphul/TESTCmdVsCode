({
        updateSrcEvent : function(component, event, helper) {
           // component.set('v.showSpinner',true);
            var recordid = component.get("v.recordId");
            var action = component.get("c.updToPendingSelection");
            action.setParams({ "RoundId": recordid });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    //capture and display errors returned
                    if(result.error){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error",
                            "message": result.error,
                            "type" : "error",
                            "mode" : "sticky"
                        });
                        toastEvent.fire();                                             
                    }
                    //display success message
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": $A.get("$Label.c.LC02_successTitle"),
                            "message": $A.get("$Label.c.LC02_SuccessMsg"),
                            "type" : "success"
                        });
                        toastEvent.fire();  
                        
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": result.sourcingEventId,
                            "slideDevName": "related" 
                        });
                        
                        navEvt.fire();
                    }
                } 
                component.set('v.showSpinner',false);                           
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    })