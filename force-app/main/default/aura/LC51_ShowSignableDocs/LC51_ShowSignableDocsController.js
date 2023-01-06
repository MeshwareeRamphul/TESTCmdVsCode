({
    populateAttributes: function(cmp) {
        // Set the attribute value. 
        // You could also fire an event here instead.
        cmp.set("v.showNoDocAvailable", false);
        cmp.set('v.showConfidential', false);
        cmp.set('v.showDocUrl', false);
        
        var action = cmp.get("c.getAttributes");
         action.setParams({
                cfId : cmp.get("v.recordId")             
         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            console.log('##result'+result);
            if (state === "SUCCESS") {
                if(result.success!=''){
                    if(result.donotdisplay=='true'){
                         cmp.set('v.showNoDocAvailable', false);
                         cmp.set('v.showConfidential', true);
                         cmp.set('v.showDocUrl', false);
                    }
                    
                    if(result.displaydoc=='true'){
                         cmp.set('v.showNoDocAvailable', false);
                         cmp.set('v.showConfidential', false);
                         cmp.set('v.showDocUrl', true);
                       
                    }
                    
                    if(result.Nodocument=='true'){
                         cmp.set('v.showNoDocAvailable', true);
                         cmp.set('v.showConfidential', false);
                         cmp.set('v.showDocUrl', false);
                    }
                   
                   
                }
                else{
                    //cmp.set("v.showNoDocAvailable", true);
                   
                }
            } 
            else { 
                //cmp.set('v.showNoDocAvailable', true);
               
            }
            
        });
        $A.enqueueAction(action);
        
    }
})