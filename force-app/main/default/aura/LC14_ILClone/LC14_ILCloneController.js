({doInit : function(component, event, helper) {
    console.log('doInit');
    var action = component.get("c.cloneInvoicingLine");
    action.setParams({
        iLId: component.get("v.recordId")
    });
    action.setCallback(this,function(a){
        var state = a.getState();
        if(state == "SUCCESS"){
            
            var returnMessage = a.getReturnValue();
            console.log('returnMessage', returnMessage);
            if(returnMessage.startsWith("a07")){
                var clonedILId = returnMessage;

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Your invoicing line has been cloned.",
                    "type" : "success"
                });
                toastEvent.fire();

                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": clonedILId,
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