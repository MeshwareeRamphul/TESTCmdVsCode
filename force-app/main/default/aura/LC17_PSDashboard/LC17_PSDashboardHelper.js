({
	getLink : function(component) {
        var action = component.get("c.getURL");
        //Setting the Callback
        action.setParams({
            objID: component.get("v.recordId")
        });
        action.setCallback(this,function(a){
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var result = a.getReturnValue();
                if(!$A.util.isEmpty(result) && !$A.util.isUndefined(result)){
                	component.set("v.dashboardLink",result);
                }
                else if($A.util.isEmpty(result)){
                	component.set("v.dashboardLink",result);
                	component.set("v.errorMsg",'No link available to view the dashboard.');
                	$A.get('e.force:refreshView').fire();
                }   
            }
            else if(state == "ERROR"){
                console.log('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
})