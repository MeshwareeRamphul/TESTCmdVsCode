({
	sendToPeopleSoft : function(component, event, helper) {
		component.set('v.showSpinner',true);
		//helper.showSpinner(component);
		var contractId = component.get('v.recordId');

		var action1 = component.get("c.setToSendingtoPS");
		action1.setParams({"curCtr":contractId});
		action1.setCallback(this, function(response){

			var state = response.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
            }else if(state == "ERROR"){
            }
		});
		$A.enqueueAction(action1);


		var action2 = component.get("c.sendCtrlightoPeopleSoft");
		action2.setParams({"curCtr":contractId});
		action2.setCallback(this, function(response){

			var state = response.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var result = response.getReturnValue();
                if($A.util.isEmpty(result)){
                    component.set('v.showSpinner',false);
					$A.get('e.force:refreshView').fire();
					//helper.hideSpinner(component);
                }
                else{
                	alert(result);
                	component.set('v.showSpinner',false);
					$A.get('e.force:refreshView').fire();
					//helper.hideSpinner(component);
                }

            }else if(state == "ERROR"){
            	alert(state);
                console.log('Error in calling server side action');
                component.set('v.showSpinner',false);
				$A.get('e.force:refreshView').fire();
				//helper.hideSpinner(component);
            }
		});
		$A.enqueueAction(action2);
	}
})