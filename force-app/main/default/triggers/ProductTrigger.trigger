trigger ProductTrigger on Product__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        if (PAD.canTrigger('AP01')) {
            ProductTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap);
        }
    }
}