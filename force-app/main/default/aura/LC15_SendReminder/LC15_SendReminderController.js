({
    doInit : function(component, event, helper) {
        component.set('v.showSpinner',true);
        var eSignatoryId = component.get("v.recordId");
        var action = component.get("c.sendReminder");
        action.setParams({"eSignatoryId": eSignatoryId});
       
//        var confirmation = confirm('Do you want to send reminder email to the signatory?');
//        if(confirmation == true){
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                var result = a.getReturnValue();
                component.set('v.showSpinner',false);
                if(result.contractType == 'ContractIn'){
                    var toastEvent = $A.get("e.force:showToast");
                    if(result.error){      
                        toastEvent.setParams({
                            "type" : "error",
                            "title": "Error",
                            "message": result.error,
                            "mode": "sticky"
                        });
                        //toastEvent.fire();
                    }/*else if(result.eSignatureId){
                        var url = '/apex/VFP22_RelaunchSignature?id='+result.eSignatureId+'&signatoryId='+ eSignatoryId;
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": url
                        });
                        urlEvent.fire();
                    }*/
                    else if(result.success){
                        toastEvent.setParams({
                            "type" : "success",
                            "title": "Success",
                            "message": result.success,
                            "mode": "dismissible"
                        });
                    }
                     toastEvent.fire();
                    
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    if(result.error){
                        toastEvent.setParams({
                            "type" : "error",
                            "title": "Error",
                            "message": result.error,
                            "mode": "sticky"
                        });
                    }else if(result.success){
                        toastEvent.setParams({
                            "type" : "success",
                            "title": "Success",
                            "message": result.success,
                            "mode": "dismissible"
                        });
                    }
                    toastEvent.fire();
                }
            }
            else{
                var errorMsg = a.getError()[0].message;
                var toastEvent = $A.get("e.force:showToast");
                component.set('v.showSpinner',false);
                toastEvent.setParams({
                    "title": "Error",
                    "message": errorMsg,
                    "type" : "error"
                });
                toastEvent.fire();
            }
            //$A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
        });
//        }
        $A.enqueueAction(action);
    }
})