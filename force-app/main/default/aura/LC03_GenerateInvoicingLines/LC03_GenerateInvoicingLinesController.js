({
	doInit : function(component, event, helper) {
		component.set('v.showSpinner',true);
		var contractId = component.get('v.recordId');
		var action = component.get("c.GenerateAContractPInvoicingLine");
		
		action.setParams({"CtrId":contractId});
		action.setCallback(this, function(response){
			var state = response.getState();
            var toast = $A.get("e.force:showToast");
            //check if result is successfull
            if(state == "SUCCESS"){
                var result = response.getReturnValue();
                if($A.util.isEmpty(result)){
                    toast.setParams({
                        "title" : "Success",
                        "type" : "info",
                        "message" : "Invoicing lines generated with success",
                        "mode": "dismissable"
                    });
                    toast.fire();
                	$A.get("e.force:closeQuickAction").fire();
					component.set('v.showSpinner',false);
					$A.get('e.force:refreshView').fire();
                }
                else{
                    toast.setParams({
                        "title" : "Error",
                        "type" : "info",
                        "message" : result,
                        "mode": "sticky"
                    });
                    toast.fire();
                	$A.get("e.force:closeQuickAction").fire();
                }  

            }else if(state == "ERROR"){
                toast.setParams({
                    "title" : "",
                    "type" : "error",
                    "message" : state
                });
                toast.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
		});
		$A.enqueueAction(action);
	}
})