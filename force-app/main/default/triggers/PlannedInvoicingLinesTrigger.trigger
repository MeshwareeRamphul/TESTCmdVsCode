/**
 * <b>Trigger PlannedInvoicingLinesTrigger</b>: Trigger for Planned Invoicing Line
 * @author : Eric Wartelle, Urvashi Sadasing
 * @version : 0.1, 0.2, 0.3 (rework)
 */
trigger PlannedInvoicingLinesTrigger on Planned_Invoicing_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	// After methods
	if (Trigger.isAfter && Trigger.isUpdate) {
		PlannedInvoicingLinesHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
	}

	// Before methods
	if(Trigger.isBefore){
		if(Trigger.isInsert){
			PlannedInvoicingLinesHandler.handleBeforeInsert(Trigger.new);
		}
		if(Trigger.isUpdate){			
			PlannedInvoicingLinesHandler.handleBeforeUpdate(Trigger.oldMap,Trigger.newMap);			
			//InvoiceLineTriggerHandler.checkRights(Trigger.new);
		}
	}

	if(Trigger.isBefore && Trigger.isDelete){
		PlannedInvoicingLinesHandler.handleBeforeDelete(Trigger.oldMap);	
	}
}