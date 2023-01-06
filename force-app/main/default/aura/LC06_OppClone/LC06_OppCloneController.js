({
	doInit : function(component, event, helper) {
		console.log('doInit');
        var action = component.get("c.cloneOpportunity");
        action.setParams({
            oppId: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                var returnMessage = a.getReturnValue();
                console.log('returnMessage', returnMessage);
                if(returnMessage.startsWith("006")){
                    var clonedOppId = returnMessage;

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Your opportunity has been cloned.",
                        "type" : "success"
                    });
                    toastEvent.fire();
    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": clonedOppId,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
                else{
                    console.log('Error');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": returnMessage,
                        "type" : "error"
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();                   
                }

            }
        });      
        $A.enqueueAction(action);
	}
})