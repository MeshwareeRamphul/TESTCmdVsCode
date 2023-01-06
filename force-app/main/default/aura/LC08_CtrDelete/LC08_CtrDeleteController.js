({
    doInit : function(component, event, helper) {
        console.log('doInit');
        var action = component.get("c.deleteContract");
        action.setParams({
            ctrId: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            var state = a.getState();           
            if(state == "SUCCESS"){    
                console.log('SUCCESS');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Your contract has been deleted.",
                    "type" : "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();

                console.log('FIRE');
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/a0D/o"
                });
                urlEvent.fire();
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
        $A.enqueueAction(action);
    }
})