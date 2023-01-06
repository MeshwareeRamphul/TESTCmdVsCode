({
    doInit : function(component, event, helper) {
        var action = component.get("c.cloneAnySobjet");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": 'A new round has been created successfully',
                        "type" : "success"
                    });
               toastEvent.fire();
                console.log('## response.getReturnValue()' , response.getReturnValue());
                var sObjectEvent = $A.get("e.force:navigateToSObject");
                sObjectEvent.setParams({
                    "recordId": response.getReturnValue(),
                    "slideDevName": "detail"
                });
                sObjectEvent.fire(); 
                
            }else if (state === "ERROR"){
                var errors = response.getError();
                if(errors) {
                    component.set("v.errorMsg", errors[0].message);
                    var errorMsg = component.find('errorMsg');
                    $A.util.removeClass(errorMsg, 'slds-hide');
                    var field = component.find('field');
                    $A.util.addClass(field, 'slds-hide');
                }
            }
        });
        $A.enqueueAction(action);
    },
})