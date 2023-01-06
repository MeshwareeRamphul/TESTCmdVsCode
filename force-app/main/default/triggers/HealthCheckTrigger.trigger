Trigger HealthCheckTrigger on Health_Check__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    
    if(Trigger.isAfter && Trigger.isInsert){
        HealthCheckHandler.afterInsert(trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
        HealthCheckHandler.beforeInsert(trigger.new);
    }
}