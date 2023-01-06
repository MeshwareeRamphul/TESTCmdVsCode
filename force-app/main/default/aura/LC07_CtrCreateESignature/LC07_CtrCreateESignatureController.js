({
    doInit : function(component, event, helper) {
        helper.checkStatus(component, event);

    },    
    toCreateEsignJS : function(component, event, helper) {
        var recordid = component.get("v.recordId");
        // if (status == 'Not updated!'){
        //     alert('Please update the contract PDF before creating the signature');
        //     return false;
        // }
        // else{
            //window.top.location.href="/apex/VFP22_showSignatory?contractId={!"+ recordid + "}";
            console.log('recordid', recordid);
            var url = '/apex/VFP22_showSignatory?contractId=' + recordid;
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": url
            });
            urlEvent.fire();
       //}
    }
})