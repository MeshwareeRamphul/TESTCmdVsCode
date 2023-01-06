({
	init : function(component, event, helper) {
        component.set('v.displayPanel', true);
		var action = component.get('c.buildParticipantlst');
        action.setParams({
            "roundId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var res=a.getReturnValue();
                console.log('## result ok',res.lst);
            	//component.set('v.disabled',res.disablebtn);
                
                if(res.lst=='No participants found')
                	component.set('v.displayPanel', false); 
                else
                    component.set('v.participantsList', res.lst); 
                //component.set('v.disableSign',res.disableSignbtn);
            }
            else{
                console.log('## result ko',res.lst);
            }
        });
        $A.enqueueAction(action);
	},
    
    selectedparticipants : function(component, event, helper) {
        var capturedCheckboxName = event.getSource().get("v.value");
        var selectedCheckBoxes =  component.get("v.selectedCheckBoxes");
        var len=selectedCheckBoxes.length;
        var addval=0;
        for(var i=0;i<len;i++){
            if(selectedCheckBoxes[i]==capturedCheckboxName){
                selectedCheckBoxes.splice(selectedCheckBoxes.indexOf(i), 1);
                addval++;
            }
        }
        if(addval==0){
            selectedCheckBoxes.push(capturedCheckboxName);
        }
        console.log('##selectedCheckBoxes',selectedCheckBoxes.length);
    },

    saveSelection: function(component, event, helper) {
        // component.set('v.showEditPanel', false);
        //calling apex to determine if selection is valid
        component.set('v.likedisable',true);
        var action = component.get('c.updteParticipantlst');
        action.setParams({"roundId": component.get('v.recordId'),
                          "selectedParticipant": component.get('v.selectedCheckBoxes'),
                          "lstParticipant": component.get('v.participantsList')
                           });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result.success);
                console.log('## result from save',result.success);
                if(result.success!=''){
                    //component.set('v.eSignatoryList', result.success);
                    
                     //component.set("v.showSpinner", true);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success", 
                            "message":"Your changes have been saved",
                            "type" : "success"
                        });
                        toastEvent.fire();
                        //redirect to cloned contract
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": component.get("v.recordId"),
                            "slideDevName": "related"
                        });
                        navEvt.fire();
                        $A.get('e.force:refreshView').fire();
                }
                else{
                     
                    component.set('v.likedisable',flse);
                    //component.set('v.disabled',true);
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "title": "Error",
                    "message": result.error,
                    "type" : "error"
                	});
                	toastEvent.fire();
                }
               
            } 
            else { 
               
                console.log('error from saveSignatories');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": result.error,
                    "type" : "error"
                });
                toastEvent.fire();
               
                //$A.get("e.force:closeQuickAction").fire();
            }   
        });
        $A.enqueueAction(action); 
     
    },
    
    closeAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})