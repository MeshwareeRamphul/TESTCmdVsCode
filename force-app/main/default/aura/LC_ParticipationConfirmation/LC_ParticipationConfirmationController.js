({
    doInit: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        if(myPageRef != null){
            var recordId = myPageRef.state.c__recordId;
            cmp.set("v.recordId", recordId);
        }
    },

    closeQA : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})