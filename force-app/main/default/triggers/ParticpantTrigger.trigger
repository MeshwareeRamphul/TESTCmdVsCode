trigger ParticpantTrigger on Bidder__c (before insert, after insert, before update, after update, before delete) {
  if (Trigger.isBefore && Trigger.isInsert) {
        ParticpantTriggerHandler.BeforeInsertHandler(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        ParticpantTriggerHandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        //ParticpantTriggerHandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        ParticpantTriggerHandler.afterUpdateHandler(Trigger.newMap, Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isdelete) {
        ParticpantTriggerHandler.BeforeDeleteHandler(Trigger.oldMap);
    }
}