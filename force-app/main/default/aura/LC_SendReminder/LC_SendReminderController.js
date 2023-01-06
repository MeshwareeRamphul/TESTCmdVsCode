({
    doInit: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        if(myPageRef != null){
            var recordId = myPageRef.state.c__recordId;
            var contractId = myPageRef.state.c__contractId;
            cmp.set("v.recordId", recordId);
            cmp.set("v.contractId", contractId);
        }
    },

    closeQA : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    getValueFromLwc : function(component, event, helper) {
		var contractId = event.getParam('contractId');
        if((typeof contractId) === 'string'){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(response) {
                if(response){
                    workspaceAPI.getFocusedTabInfo().then(function(resp) { 
                        // navigate to contract tab
                        workspaceAPI.getEnclosingTabId().then(function(tabId) {
                            workspaceAPI.openSubtab({
                                parentTabId: tabId,                
                                recordId : contractId,
                                focus: true
                            }).then(function(){
                                // close opened blank tab
                                workspaceAPI.closeTab({tabId: resp.tabId});
                            })
                        }).catch(function(error) {
                            console.log(error);
                        });
                    });
                }
            }).catch(function(error) {
                console.log(error);
            });  
        }
	} 
})