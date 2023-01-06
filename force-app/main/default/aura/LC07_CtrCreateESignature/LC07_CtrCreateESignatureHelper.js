({
    checkStatus : function(component)  {
        console.log('helper.checkStatus');
        // var action = component.get("c.getStatut");
        // //Setting the Callback
        // action.setParams({
        //     cID: component.get("v.recordId")
        // });
        // action.setCallback(this,function(a){
        //     var state = a.getState();
        //     console.log('state', state);
        //     if(state == "SUCCESS"){
        //         var cont = a.getReturnValue();
        //         console.log('cont', cont);
        //         if( cont.Status__c=='Ready for Signature' && cont.Signature_Type__c=='Electronic'){
        //             console.log('READY');
        //         }
        //         else{
        //             console.log('NOT READY');
        //             $A.util.addClass(component.find("CreateSigButton"), 'slds-hide');
        //         }
        //     }
        // });
        // //adds the server-side action to the queue        
        // $A.enqueueAction(action);
    }
})