trigger BidderTrigger on Bidder__c (before insert, after insert, before update, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        //BidderTriggerHandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
       // BidderTriggerHandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        system.debug('***trigger afterUpdateHandler');
        BidderTriggerHandler.afterUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }

}