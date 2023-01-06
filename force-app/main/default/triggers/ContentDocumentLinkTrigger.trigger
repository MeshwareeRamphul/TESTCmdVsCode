trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, after delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentLinkTriggerHandler.handleAfterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        ContentDocumentLinkTriggerHandler.handleAfterDelete(Trigger.old);
    }
}