trigger ContactTrigger on Contact (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
        /// After methods
    if (Trigger.isAfter && Trigger.isUpdate) {
        if (PAD.canTrigger('AP312')) {
            AP12_Contacts.updateContactCurrentValuePDF(Trigger.oldMap, Trigger.newMap);
        }
    }
}