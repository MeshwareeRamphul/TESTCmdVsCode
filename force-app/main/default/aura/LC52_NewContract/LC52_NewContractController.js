({
	doInit : function(component, event, helper) {
		var recordTypeId = component.get("v.pageReference").state.recordTypeId;
		var action = component.get("c.getRecordType");
		action.setParams({
            "recordTypeId": recordTypeId
        });
        action.setCallback(this, function(response){
            if(response.getState()==='SUCCESS'){
                var result = response.getReturnValue();
				if(result){
					if(result.recordType){
						var createRecordEvent = $A.get("e.force:createRecord");
						createRecordEvent.setParams({
							"entityApiName": "Contract__c",
							"recordTypeId": result.recordType
						});
						createRecordEvent.fire();
					}else if(result.error){
						var toastEvent = $A.get("e.force:showToast");
							toastEvent.setParams({
								"title": "Error",
								"message": result.error,
								"type" : "error"
							});
						toastEvent.fire();   
					}
				}
            }
        });
        $A.enqueueAction(action);
	}
})