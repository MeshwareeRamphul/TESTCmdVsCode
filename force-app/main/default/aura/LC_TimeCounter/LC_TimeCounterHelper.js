/*({
    waitingTimeId: null,
	setStartTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",true);
        var currTime =component.get("v.ltngCurrTime");
        var ss = currTime.split(":");
        var dt = new Date();
        dt.setHours(ss[0]);
        dt.setMinutes(ss[1]);
        dt.setSeconds(ss[2]);
        
        var dt2 = new Date(dt.valueOf() + 1000);
        var temp = dt2.toTimeString().split(" ");
        var ts = temp[0].split(":");
        
        component.set("v.ltngCurrTime",ts[0] + ":" + ts[1] + ":" + ts[2]);
        this.waitingTimeId =setTimeout($A.getCallback(() => this.setStartTimeOnUI(component)), 1000);
    },
    setStopTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",false);
        window.clearTimeout(this.waitingTimeId);
    },
    setResetTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",false);
        component.set("v.ltngCurrTime","00:00:00");
        window.clearTimeout(this.waitingTimeId);
    }
})*/
({  
    
    waitingTimeId: null,
	setStartTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",true);
        this.waitingTimeId =setTimeout($A.getCallback(() => this.setStartTimeOnUI(component)), 1000);
    },
    
   
    countDownAction : function(component, event, helper,opptyCloseDate) {
        component.set("v.ltngIsDisplayed",true);
        var timeDiff; 
        var interval = window.setInterval(
            $A.getCallback(function() {
                //var opptyCloseDate = new Date( closeDate+" 00:00:00 ");
                var now_date = new Date();
                timeDiff= opptyCloseDate.getTime() - now_date.getTime(); // time difference between opportunity close date and todays date  
                console.log('timeDiff'+timeDiff);
                var days;
                var hours;
                var minutes;
                var seconds;
                
                if(timeDiff<=0){
                    days = 0;
                    hours = 0;
                    minutes = 0;
                    seconds = 0;
                    component.set("v.msg",'Bid Due Date has expired');
                    component.set("v.isValid",false);
                    window.clearInterval(interval);
                }else{
                    component.set("v.isValid",true);
                    seconds = Math.floor(timeDiff/1000); // seconds
                    minutes = Math.floor(seconds/60); //minute
                    hours = Math.floor(minutes/60); //hours
                    console.log('minutes',minutes);
                    console.log('hours',hours);
                    
                    days = Math.floor(hours/24); //days
                    hours %=24; 
                    minutes %=60;
                    seconds %=60;
                }
                component.set("v.day",days);
                component.set("v.hour",hours);
                component.set("v.minute",minutes);
                component.set("v.second",seconds);
            }), 1000);  
         
        
    },
    
    setStopTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",false);
        window.clearTimeout(this.interval);
    },
    setResetTimeOnUI : function(component) {
        component.set("v.ltngIsDisplayed",false);
        component.set("v.day","");
        component.set("v.hour","");
        component.set("v.minute","");
        component.set("v.second","");
        window.clearTimeout(this.interval);
    }
})