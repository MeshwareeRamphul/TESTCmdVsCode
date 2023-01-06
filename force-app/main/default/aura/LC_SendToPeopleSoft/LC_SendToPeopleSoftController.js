({

    closeQA : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    getValueFromLwc : function(component, event, helper) {
		component.set("v.showSpinner",event.getParam('showSpinner'));
	},
    
    refreshView: function(component, event) {
        // refresh the view
        $A.get('e.force:refreshView').fire();
    },

})