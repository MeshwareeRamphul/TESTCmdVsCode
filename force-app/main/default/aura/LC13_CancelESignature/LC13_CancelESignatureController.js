({
	 
    handleConfirmDialog : function(component, event, helper) {
        component.set('v.showConfirmDialog', true);
    }, 
    
    handleConfirmDialogYes : function(component, event, helper) {
        console.log('Yes');
        component.set('v.showConfirmDialog', false);
       // component.set('v.confirmation', true);
  
        var action = component.get("c.cancelESignature");
        action.setParams({
            ctrId: component.get("v.recordId")
        });
         //if(confirmation == true){
            action.setCallback(this,function(a){
                var state = a.getState();   
                var result = a.getReturnValue();    
                console.log('state', state);
                console.log('result', result);
                if(state == "SUCCESS"){                       
                    if (result.success){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Your eSignature has been cancelled.",
                            "type" : "success"
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error",
                            "message": result.error,
                            "type" : "error"
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire(); 
                    }
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
                    $A.get("e.force:closeQuickAction").fire();    
                }
            });
        //}
        $A.enqueueAction(action);
    
    },
    
	    
    handleConfirmDialogNo : function(component, event, helper) {
        console.log('No');
        component.set('v.showConfirmDialog', false);
        component.set('v.confirmation', false);
    },
})