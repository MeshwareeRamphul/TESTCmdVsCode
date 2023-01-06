({
	doInit : function(component, event, helper) {
		var action = component.get('c.recalculateSharing'); 
		var eventId = component.get('v.recordId');
        console.log('eventId ', eventId);
        action.setParams({
            "eventId" : eventId
        });
        action.setCallback(this, function(response){
            var state = response.getState(); // get the response state
            var result = response.getReturnValue();
            var toastEvent = $A.get("e.force:showToast");
            if(state == "SUCCESS") {
                toastEvent.setParams({
                    "title": "Success", 
                    "message":result.success,
                    "type" : "success"
                });
                toastEvent.fire();
            }
            else{
                toastEvent.setParams({
                    "title": "Error",
                    "message": result.error,
                    "type" : "error"
                });
                toastEvent.fire();
            }
                $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
	}
})