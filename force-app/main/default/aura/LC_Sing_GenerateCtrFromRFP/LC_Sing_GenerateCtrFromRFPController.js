({
    checkDisplay:function(component, event, helper) {
        var srceventId =  component.get("v.recordId");   
        var action = component.get("c.validateDisplay");
        action.setParams({ 
            "eventId": srceventId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log('state : ', state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("## result :", result);
               
                //check if error
                if(result.hide){
                    component.set("v.showConfirmation", false);
                    component.set("v.showNotAllowedMsg", true);
                                     
                }
                else{
                    component.set("v.showConfirmation", true);
                    component.set("v.showNotAllowedMsg", false);
                }
            } 
           /* else{
                console.log('Error' + response.getReturnValue());
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": response.getReturnValue(),
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }  */       
        });
        // Send action off to be executed
        $A.enqueueAction(action);

    },
    
	doInit : function(component, event, helper) {

        component.set("v.showSpinner", true);
        var srceventId =  component.get("v.recordId");   
        var action = component.get("c.generateCtr");
        action.setParams({ 
            "eventId": srceventId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log('state : ', state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("## result :", result);
               
                //check if error
                if(result.success){
                    $A.get('e.force:refreshView').fire();                        

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": result.success,
                        "type" : "success"
                    });
                    toastEvent.fire(); 
                    $A.get("e.force:closeQuickAction").fire(); 
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error", 
                        "message": result.Error,
                        "type" : "error"
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();  
                }
            } 
            else{
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

    },

    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})