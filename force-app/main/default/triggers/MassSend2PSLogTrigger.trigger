trigger MassSend2PSLogTrigger on MassSend2PSLog__c (before insert, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        MassSend2PSLogTriggerHandler.AfterUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
}