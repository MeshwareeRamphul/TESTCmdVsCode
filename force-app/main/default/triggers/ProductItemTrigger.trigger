trigger ProductItemTrigger on ProductItem__c (after insert, after update, before insert, before update, before delete, after delete) {
	
	
    /*----------------------------------------------------------------------
-- - Name          : ProductItemTrigger
-- - Author        : Spoon
-- - Description   : trigger for ProductItem__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 					   1.0     Initial version 
-- 08-SEP-2021  ARA    1.1     SP-03707: Update Product selection module to allow multiple products from diff. Lvl3
-------------------------------------------------------------------------*/
	system.debug('### Starting ProductItemTrigger');

	ProductItemTriggerHandler handler = new ProductItemTriggerHandler();
	list<ProductItem__c > lstPItems = new list<ProductItem__c >();


	if (Trigger.isBefore && Trigger.isInsert) {	
		handler.handleChanges(trigger.new);
	}
	else if (Trigger.isAfter && Trigger.isInsert) {	
		handler.updateContractProductLevel3(trigger.new);
	}
	else if (Trigger.isBefore && Trigger.isUpdate) {	
		handler.handleChanges(trigger.new);
	}
	else if (Trigger.isAfter && Trigger.isUpdate) {
		for(Integer i=0; i<trigger.new.size();i++){
            if(trigger.new[i].Product__c != trigger.old[i].Product__c || trigger.new[i].Status__c != trigger.old[i].Status__c){
                lstPItems.add(trigger.new[i]);
            }
		}
		if(lstPItems.size() > 0){
			handler.updateContractProductLevel3(trigger.new);
		}
	}
	else if(Trigger.isBefore && Trigger.isDelete){
		handler.handleChanges(trigger.old);
		handler.handleBeforeDelete(trigger.old);
	}
	else if(Trigger.isAfter && Trigger.isDelete){
		handler.updateContractProductLevel3(trigger.old);
	}
}