trigger InvoicingLineTrigger on Invoicing_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	//if (Trigger.isBefore) {
	//	if(Trigger.isUpdate) {
	//		if (PAD.canTrigger('AP512')) {
	//			AP12_InvoicingLines.updateStatus(Trigger.oldMap, Trigger.newMap);
	//		}
	//	}	

	//	if(Trigger.isInsert){
	//		if(PAD.canTrigger('AP512')){
	//			AP12_InvoicingLines.updateWBSInformations(Trigger.new);
	//		}
	//	}				
	//}
}