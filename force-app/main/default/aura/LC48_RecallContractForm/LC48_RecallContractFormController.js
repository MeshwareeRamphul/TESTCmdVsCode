({
  
    handleConfirmDialog : function(component, event, helper) {
        component.set('v.showConfirmDialog', true);
    }, 
    
    handleConfirmDialogYes : function(component, event, helper) {
        console.log('Yes');
        component.set('v.showConfirmDialog', false);
       // component.set('v.confirmation', true);
  
        var action = component.get("c.callVFCMethod");
        action.setParams({
            ctrId: component.get("v.recordId")
        });
         //if(confirmation == true){
            action.setCallback(this,function(a){
                var state = a.getState();    
//                console.log('state', state);
                if(state == "SUCCESS"){   
                    var message = a.getReturnValue(); 
//                    console.log('message', message);
                      $A.get("e.force:closeQuickAction").fire();
                    if (message.ok){
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Contract status has been updated to In Progress.",
                            "type" : "success"
                        });
                        toastEvent.fire();
                      
                       // $A.get('e.force:refreshView').fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error",
                            "message": message.err,
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
                
                $A.get('e.force:refreshView').fire();
                
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