/**
 * Trigger for the Entity Rolled Out Object
 */
trigger ProductEntityLinkTrigger on ProductEntityLink__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    /// Before methods
    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
        //USA 20170808: testing start
        //if (PAD.canTrigger('AP09')) {
        //    //AP09_ProductEntityLinks.fillAntiDuplicateField(Trigger.New);
        //    AP09_ProductEntityLinks.checkOrderStatus(Trigger.OldMap, Trigger.NewMap);
        //}
        //USA 20170808: testing end

        //USA 20170712 : ALLINFIN- 486
        if (Trigger.isInsert){
            if (PAD.canTrigger('AP26')){
                ProductEntityLinkTriggerHandler.handleBeforeInsert(Trigger.New);
            }
        }
        else if (Trigger.isUpdate){
            if (PAD.canTrigger('AP26')){
                ProductEntityLinkTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
            }
        }
    }

    //USA 20170808: testing start
    if (Trigger.isBefore && Trigger.isInsert) {
        AP09_ProductEntityLinks.fillAntiDuplicateField(Trigger.New);
    }
    //USA 20170808: testing end

	//Added by Johan Hazebrouck
	//Trigger to manage the isPartial fonctionnality
	List<ProductEntityLink__c> pProductEntityLink = new List<ProductEntityLink__c>();
	if(Trigger.isAfter){
		if (PAD.canTrigger('AP21')) {
			if(Trigger.isInsert){
				for(ProductEntityLink__c pel : Trigger.new){
					pProductEntityLink.add(pel);
				}
			}
			if(Trigger.isUpdate){
				for(ProductEntityLink__c pel : Trigger.new){
					if(pel.POS_Status__c != null && pel.POS_Status__c != Trigger.oldMap.get(pel.Id).POS_Status__c){
						pProductEntityLink.add(pel);
					}
				}
			}
            AP09_ProductEntityLinks.checkIsPartial(pProductEntityLink);
		}
        //USA 20170712 :Commented and added to line 41, inside if statement canTrigger AP21
		//AP09_ProductEntityLinks.checkIsPartial(pProductEntityLink);

        //USA 20170714 : ALLINFIN-485
        if (PAD.canTrigger('AP27')) {
            if(Trigger.isInsert){
                ProductEntityLinkTriggerHandler.handleAfterInsert(Trigger.newMap);
            }
            if (Trigger.isUpdate){
                ProductEntityLinkTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        }
	}
}