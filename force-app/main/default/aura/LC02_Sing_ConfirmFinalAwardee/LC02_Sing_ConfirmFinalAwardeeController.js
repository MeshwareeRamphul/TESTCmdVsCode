({
	init : function(component, event, helper) {
		var action = component.get('c.sourcingEventId'); 
      
        action.setParams({
            "eventId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var res=a.getReturnValue();
                console.log('## result ok',res.lst);
            	//component.set('v.disabled',res.disablebtn);
                component.set('v.participantsList', res.lst); 
                
                if(res.lst=='No participants availalble for selection')
                	component.set('v.displayPanel', false); 
                else
                    component.set('v.displayPanel', true);
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
        if(component.get('v.selectedCheckBoxes').length>0){
        //calling apex to determine if selection is valid
        var action = component.get('c.updteParticipantlst');
        action.setParams({"eventId": component.get('v.recordId'),
                          "participantList": component.get('v.selectedCheckBoxes'),
                          "updatedlist": component.get('v.participantsList')
                           });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
                console.log('## result from save',result.success);
                /*if(result.success!='' && result.success!== 'undefined'){*/
                if( result.proceeed=='true'){
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
                }
                else{
                     
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
                    "message": 'An unexpected error was ecountered',
                    "type" : "error"
                });
                toastEvent.fire();
               
                //$A.get("e.force:closeQuickAction").fire();
            }   
        });
        $A.enqueueAction(action); 
    	}
        else{
             var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'Please select a participant',
                    "type" : "error"
                });
                toastEvent.fire();
        }
     
    },
})