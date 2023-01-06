({
    doThisInit : function(component, event, helper) {
        console.log('doThisInit');
        var action = component.get("c.createAmendmentFromContract");
        action.setParams({
            ctrId: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                var returnMessage = a.getReturnValue();
                console.log('returnMessage', returnMessage);
                if(returnMessage.startsWith("a0D")){
                    var clonedCtrId = returnMessage;

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The new amendment has been created.",
                        "type" : "success"
                    });
                    toastEvent.fire();
    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": clonedCtrId,
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