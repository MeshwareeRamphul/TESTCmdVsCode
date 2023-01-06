trigger AttachmentTrigger on Attachment (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	if (Trigger.isBefore && Trigger.isDelete) {
		if (PAD.canTrigger('AP13')) {
			AP13_Attachment.preventDeletion(Trigger.oldMap);
		}
	}
}