({
    doInit: function(cmp, evt, helper) {
        cmp.set("v.showSpinner", true);
        var myPageRef = cmp.get("v.pageReference");
        var parameters = JSON.stringify(myPageRef.state.c__listOfContracts).replaceAll('"', '');
        var ctr = '';
        var retURL = '';
        if(parameters.includes(',')){
            ctr = parameters.substring(0,parameters.lastIndexOf(','));
            retURL = parameters.substring(parameters.lastIndexOf(',') + 1);
        }else{
            ctr = '';
            retURL = parameters;
        }
        cmp.set("v.listOfContracts",ctr);
        cmp.set("v.retURL",retURL);

        helper.checkStatus(cmp, evt);
    },

    reInit : function(cmp, evt, helper) {
        $A.get('e.force:refreshView').fire();
    },

    handleConfirmDialogNo: function(cmp, evt, helper) {
        cmp.set("v.listOfContracts",[]);
        cmp.set('v.showConfirmDialog', false);
        
        helper.goToListView(cmp, evt);
        //helper.closeConsoleTab(cmp, evt) ;
        //redirect to list view
        //helper.redirectToListView(cmp, evt); 
        /**var url = window.location.href; 
        var value = url.substr(0,url.lastIndexOf('/') + 1);
        window.history.back();
        return false;*/
    }, 

    handleConfirmDialogYes: function(cmp, evt, helper) {
        //cmp.set("v.showSpinner", true);
        helper.sendToPS(cmp, evt);
    }
})