({
    getDoc : function(component) {
        var action = component.get("c.loadData");
        //Setting the Callback
        action.setParams({
            oppId: component.get("v.recordId")
        });

        var defaultPicklist = component.get("v.defaultPicklist");

        action.setCallback(this,function(a){
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var result = a.getReturnValue();
                if(!$A.util.isEmpty(result) && !$A.util.isUndefined(result))
                    component.set("v.lstDocument",result);
                    if(result[0].hasOwnProperty('doc') && result[0].doc.hasOwnProperty('DeveloperName') && (defaultPicklist == '' || typeof defaultPicklist == 'undefined')){
                        component.set("v.defaultPicklist",result[0].doc.DeveloperName);
                    }
                    for(var i=0; i<result.length; i++){
                        var selected = false;
                        if(result[i].hasOwnProperty('doc') && result[i].doc.hasOwnProperty('DeveloperName') && result[i].doc.DeveloperName == defaultPicklist){
                            var selected = true;
                        }
                        result[i].selected = selected;
                    }

            }else if(state == "ERROR"){
                console.log('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
	},
    UpdateDocument : function(component,event,Id) {
        var action = component.get("c.UpdateFiles");  
        var fDesc = component.find("fileDescription").get("v.value");  
        action.setParams({"documentId":Id,
            "description": fDesc,  
            "oppId": component.get("v.recordId")  
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){
                var result = response.getReturnValue();   
                this.getDoc(component);
            }  
        });  
        $A.enqueueAction(action);  
   }  
})