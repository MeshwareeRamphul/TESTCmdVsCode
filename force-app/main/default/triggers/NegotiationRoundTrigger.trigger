trigger NegotiationRoundTrigger on Negotiation_Round__c (before insert, after insert, before update, after update){
	if (Trigger.isBefore && Trigger.isInsert) {
        //NegotiationRoundTriggerhandler.BeforeInsertHandler(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        NegotiationRoundTriggerhandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        //NegotiationRoundTriggerhandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        NegotiationRoundTriggerhandler.afterUpdateHandler(Trigger.newmap, Trigger.oldMap);
    }
}