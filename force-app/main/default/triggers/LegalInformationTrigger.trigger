trigger LegalInformationTrigger on Legal_Information__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    
    if(Trigger.isAfter && Trigger.isInsert){
        LegalInformationHandler.afterInsert(trigger.new);
    } 
    
    if(Trigger.isBefore && Trigger.isInsert){
        LegalInformationHandler.beforeInsert(trigger.new);
    }
}