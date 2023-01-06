trigger LocalInformationTrigger on Local_information__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	if (Trigger.isAfter && Trigger.isUpdate) {
		if (PAD.canTrigger('AP30')) {
			system.debug('##KZE handle after update');
            LocalInformationTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap);
		}
	}    
}