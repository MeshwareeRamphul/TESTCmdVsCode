trigger ContractTrigger on Contract__c (after insert, after update, before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ContractTriggerHandler.BeforeInsertHandler(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        ContractTriggerHandler.BeforeUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        ContractTriggerHandler.afterInsertHandler(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        if(!ContractTriggerHandler.hasExecutedafterUpdateHandler){
            ContractTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.old, Trigger.newmap, Trigger.oldMap);
            system.debug('ContractTrigger1');
        }
        
        //MRA - to be added to contractTriggerHandler after mep
        if (PAD.canTrigger('AP40')) {
            system.debug('ContractTrigger2');
            //Map<Id, Contract__c> mapofUpdatedContracts = new Map<Id, Contract__c>();
            set<id> setCtrId = new set<id>();
            
            for(integer i=0; i<trigger.new.size();i++){
                if(trigger.new[i].TECH_IsContractIn__c && (trigger.old[i].OwnerId != trigger.new[i].OwnerId) ){
                    //mapofUpdatedContracts.put(trigger.new[i].id,trigger.new[i]);
                    setCtrId.add(trigger.new[i].id);
                }
            }

            if (/*mapofUpdatedContracts.size() > 0*/ setCtrId.size()>0){
                AP40_GenerateContractShare.generateContractShare(setCtrId/*mapofUpdatedContracts*/);
            }

        }
        
        if (PAD.canTrigger('AP47')) {
            system.debug('ContractTrigger3');
            set<id>ctrIdSetOpco = new set<id>();
            set<id>ctrIdSetCtin = new set<id>();
            for(integer i=0; i<trigger.new.size();i++){
                if(trigger.new[i].Tech_RecoverLinkToDocument__c != trigger.old[i].Tech_RecoverLinkToDocument__c/*&& trigger.new[i].Tech_RecoverLinkToDocument__c==true*/){
                    if(trigger.new[i].TECH_IsContractIn__c){
                        ctrIdSetCtin.add(trigger.new[i].id);
                    }else {
                        ctrIdSetOpco.add(trigger.new[i].id);
                    }
                }
            }

            if (ctrIdSetCtin.size() > 0){
                system.debug('## calling AP47_UpdateFinalDocUrl');
                AP47_UpdateFinalDocUrl.UpdateLinkToDocument(ctrIdSetCtin);
            }
            if (ctrIdSetOpco.size() > 0){
                system.debug('## calling AP47_UpdateFinalDocUrl');
                AP47_UpdateFinalDocUrl.UpdateLinkToDocumentOpCo(ctrIdSetOpco);
            }
        }
        
        //MRA 19/08/2021 - SP-02005
        if(PAD.canTrigger('AP62')){
            system.debug('ContractTrigger4');
          set<id> contractIdSet=new set<id>();
           for(integer i=0; i<trigger.new.size();i++){
                if(trigger.new[i].TECH_IsContractIn__c && (trigger.new[i].TECH_NotifyBOLegals__c!= trigger.old[i].TECH_NotifyBOLegals__c
                                                         && trigger.new[i].TECH_NotifyBOLegals__c==true) ){
                     system.debug('## calling AP62_SendReminderToBOLegals');                                   
                    contractIdSet.add(trigger.new[i].id);
                }
            }

            if (contractIdSet.size() > 0){              
                AP62_SendReminderToBOLegals.NotifyBOLegals(contractIdSet);
            }

          
        }
        
        if (PAD.canTrigger('AP63')) {
            system.debug('ContractTrigger5');
            set<id>ctrIdSet = new set<id>();
            for(integer i=0; i<trigger.new.size();i++){
                if(trigger.new[i].TECH_IsContractIn__c && (trigger.new[i].cTin_NumberSignablePDF__c!= trigger.old[i].cTin_NumberSignablePDF__c) || 
                (trigger.old[i].TECH_ForceTriggerExecution__c!=trigger.new[i].TECH_ForceTriggerExecution__c &&
                trigger.new[i].TECH_ForceTriggerExecution__c=='AP63') ){
                    ctrIdSet.add(trigger.new[i].id);
                }
            }

            if (ctrIdSet.size() > 0 && !AP63_UpdateCFSignableLinks.hasAlreadyFired){
                system.debug('## calling AP63_UpdateCFSignableLinks');
                AP63_UpdateCFSignableLinks.UpdateLinks(ctrIdSet);
            }

        }
    }
}