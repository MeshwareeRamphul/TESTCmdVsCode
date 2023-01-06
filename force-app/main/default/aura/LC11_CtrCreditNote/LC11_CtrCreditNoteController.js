({
    doInit : function(component, event, helper) {
		component.set('v.showSpinner',true);
		var invLineId = component.get('v.recordId');
		var action = component.get("c.CreateNewCreditNote");
		
		action.setParams({"invLineId":invLineId});
		action.setCallback(this, function(response){
            var state = response.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var returnMessage = response.getReturnValue();
                //console.log('returnMessage', returnMessage);
                if(returnMessage.startsWith('a07')){
                    var creditNoteId = returnMessage;

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "A new credit note has been created.",
                        "type" : "success"
                    });
                    toastEvent.fire();
    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": creditNoteId,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
                else{
                    //console.log('Error');
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