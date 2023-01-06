({
    handleConfirmDialogYes : function(component, event, helper) {
        let button = event.getSource();
        button.set('v.disabled',true);
        component.set('v.showSpinner', true);
        var action = component.get("c.cancelIL");
        action.setParams({
            ilId: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            var state = a.getState();    

            if(state == "SUCCESS"){   
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Your invoicing line has been canceled.",
                    "type" : "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                component.set('v.showSpinner', false);
                window.location.reload()
            }
            else{
                var errorMsg = a.getError()[0].message; 
                console.log('errorMsg', errorMsg);               
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": errorMsg,
                    "type" : "error"
                });
                toastEvent.fire();
                component.set('v.showSpinner', false);
                $A.get("e.force:closeQuickAction").fire();
            }
        });      
        $A.enqueueAction(action);
    },

    
    handleConfirmDialogNo : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();  
    },
})