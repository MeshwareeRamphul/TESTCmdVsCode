({
	checkStatus : function(cmp, evt) {
		var action = cmp.get("c.checkStatus");
        action.setParams({
            contractIds: cmp.get("v.listOfContracts")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
                
                cmp.set("v.showSpinner", false);
                if(result.error){
                    // show error message
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error",
                        "mode": "sticky"
                    });
                    toastEvent.fire();
                    //redirect to list view
                    this.goToListView(cmp, evt);
                    /*var url = window.location.href;
                    var value = url.substr(0,url.lastIndexOf('/') + 1);
                    window.history.back();
                    return false;*/
                }
                else{
                    // show confirmation dialog
                    cmp.set('v.showConfirmDialog', true);
                }
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'We encountered an unexpected error: Cannot send contract to PeopleSoft',
                    "type" : "error",
                    "mode": "sticky"
                });
                toastEvent.fire();
                cmp.set("v.showSpinner", false);
            }         
        });
        $A.enqueueAction(action);
        $A.get("e.force:closeQuickAction").fire();
    },


    sendToPS : function(cmp, evt) {
		var action = cmp.get("c.sendToPS");
        action.setParams({
            contractIds: cmp.get("v.listOfContracts")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
                
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result.error){
                    // show error message
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error",
                        "mode": "sticky"
                    });
                }else{
                    // inform the user that they will receive an email as soon as the process is complete 
                    toastEvent.setParams({
                        "title": "Success", 
                        "message": 'Your Contracts are being sent to People Soft, you will receive an email shortly with the results',
                        "type" : "success"
                    });
                }
            }
            else {
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'We encountered an unexpected error: Cannot send contracts to PeopleSoft',
                    "type" : "error",
                    "mode": "sticky"
                });
            }
            
            cmp.set("v.showSpinner", false);
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        });

        $A.enqueueAction(action);
        //redirect to list view
        this.goToListView(cmp, evt);
        /*var url = window.location.href;
        var value = url.substr(0,url.lastIndexOf('/') + 1);
        window.history.back();
        return false;*/
    },

    redirectToListView : function(cmp, evt) {
        var url = window.location.href; 
        var value = url.substr(0,url.lastIndexOf('/') + 1);
        window.history.back();
        return false;
    },

    goToListView : function(cmp, evt){
        var retURL = cmp.get("v.retURL");
        console.log('*****111', retURL);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": retURL
        });
        urlEvent.fire();
        $A.get("e.force:closeQuickAction").fire();

        //this.closeFocusedTab(cmp, evt);
    },

    closeFocusedTab : function(component, event) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                    return false;
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },
})