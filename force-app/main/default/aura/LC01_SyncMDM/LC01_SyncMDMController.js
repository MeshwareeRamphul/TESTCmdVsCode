({
	doInit : function(component, event, helper) {
		component.set('v.showSpinner',true);
		var accid = component.get('v.recordId');
		var accRecord = component.get("v.accRecord");
		if(typeof accRecord.MDMLegalEntityCode__c == "undefined" || accRecord.MDMLegalEntityCode__c == '' || accRecord.MDMLegalEntityCode__c == null){
			component.set('v.showSpinner',false);
			var resultToast = $A.get("e.force:showToast");
			resultToast.setParams({
				"title" : "Error!",
				"type" : "error",
				"message" : "To sync with MDM, the field MDM Legal Entity Code must be filled"
			});
			resultToast.fire();
			$A.get("e.force:closeQuickAction").fire();
		}
		else{
			component.set('v.showSpinner',true);
			var action = component.get("c.CallWebserviceLightning");
			action.setParams({"accId":accid});
			action.setCallback(this, function(response){
				var result = response.getState();
				$A.get("e.force:closeQuickAction").fire();
				$A.get('e.force:refreshView').fire();
				component.set('v.showSpinner',false);
			});
			$A.enqueueAction(action);
		};
	}
})