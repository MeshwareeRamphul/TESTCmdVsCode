trigger SourcingEventTeamTrigger on Sourcing_Event_Team__c (before insert, after insert, before update, after update,after delete) {
	if (Trigger.isBefore && Trigger.isInsert) {
        //SrcTeamTriggerHandler.BeforeInsertHandler(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        SrcTeamTriggerHandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
       // SrcTeamTriggerHandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {  
        SrcTeamTriggerHandler.afterUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    
    if (Trigger.isafter && Trigger.isDelete) {
        SrcTeamTriggerHandler.afterDeleteHandler(Trigger.oldMap);
    }
}