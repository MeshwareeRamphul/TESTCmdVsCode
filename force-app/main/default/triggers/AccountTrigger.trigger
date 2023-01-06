trigger AccountTrigger on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    system.debug('##USA## account trigger');
		/// After methods
	if (Trigger.isAfter && Trigger.isUpdate) {
		if (PAD.canTrigger('AP212')) {
			AP12_Accounts.updateAccountCurrentValuePDF(Trigger.oldMap, Trigger.newMap);
		}

        if (PAD.canTrigger('AP25')|| PAD.canTrigger('AP30') ) {
            system.debug('##USA## handle after update');
            AccountTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap);
        }

        if (PAD.canTrigger('AP25')) {
        	
        }


	}

	if (Trigger.isAfter && Trigger.isInsert) {

		if (PAD.canTrigger('AP25')) {
        	AccountTriggerHandler.handleAfterInsert(trigger.oldMap, trigger.newMap);
        }
	}
	
	if (Trigger.isBefore && Trigger.isInsert) {

		if (PAD.canTrigger('AP25')) {
        	AccountTriggerHandler.handleBeforeInsert(trigger.new);
        }
	}

}