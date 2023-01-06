({
	doInit: function(component, event, helper) {
        helper.getLink(component, event, helper);
	},
    
    goToPSDashboard: function(component, event, helper) {
        var urlToDashboard = component.get("v.dashboardLink");
        if(urlToDashboard != ""){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": urlToDashboard
            });
    
            urlEvent.fire();
        }
    },
})