/*({
    doInit : function(component, event, helper) {
        handleStartClick
		console.log("diinit get called!!");
	},
    
    
    handleStartClick : function(component, event, helper) {
		console.log("start button clicked!!");
        var action = component.get('c.defaultRemainingTime'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "esourcingId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var res=a.getReturnValue();
                console.log('ltngCurrTime',res)
            	component.set('v.ltngCurrTime',res);      
            }
        });
        $A.enqueueAction(action);
        
        helper.setStartTimeOnUI(component);
	},
    handleStopClick : function(component, event, helper) {
		console.log("stop button clicked!!");
        helper.setStopTimeOnUI(component);
	},
    handleResetClick : function(component, event, helper) {
		console.log("Reset button clicked!!");
        helper.setResetTimeOnUI(component);
	}   
})*/
({
    doInit : function(component, event, helper) {
        let action = component.get("c.defaultRemainingTime");
        
        action.setParams({
            "recId" : component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            let state = response.getState();
            if(state == 'SUCCESS'){
                var result = response.getReturnValue();
                var oppCloseDt = new Date(result);
                var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
				var monthName = months[oppCloseDt.getMonth()];
                var dateNumber = oppCloseDt.getDate();
                var yearNumber =  oppCloseDt.getFullYear();
                var minute = oppCloseDt.getMinutes();
                var hour = oppCloseDt.getHours();
                console.log('Month Name: ' +monthName+' Date: '+dateNumber+' Year: '+yearNumber);
                var closeDateVar = monthName+' '+dateNumber+' '+yearNumber;
                var opptyCloseDate = new Date( closeDateVar+' '+hour+':'+minute+':00');
                var now_date = new Date();
                console.log('Todays date: ' +now_date);
                var timeDiff = opptyCloseDate.getTime() - now_date.getTime(); 
                          
                if(timeDiff <= 0){
                    component.set("v.isValid",false);
                }else{
                    helper.countDownAction(component, event, helper, opptyCloseDate);
                }
            }
        });
        $A.enqueueAction(action);
        
        helper.setStartTimeOnUI(component);
        
    },
    handleStopClick : function(component, event, helper) {
		console.log("stop button clicked!!");
        helper.setStopTimeOnUI(component);
	},
    handleResetClick : function(component, event, helper) {
		console.log("Reset button clicked!!");
        helper.setResetTimeOnUI(component);
	}   
})