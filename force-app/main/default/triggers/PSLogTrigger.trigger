trigger PSLogTrigger on Log__c (before insert, after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        PSLogTriggerHandler.afterInsertHandler(Trigger.new);
    }
}