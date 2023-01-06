trigger OpportunityProductItemTrigger on Opp_ProductItem__c (after insert, after update, before insert, before update, before delete, after delete) {
  
    /*----------------------------------------------------------------------
-- - Name          : OpportunityProductItemTrigger
-- - Author        : Spoon
-- - Description   : trigger for Opp_ProductItem__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 					           1.0      Initial version 
-- 08-SEP-2021  ARA    1.1     SP-03707: Update Product selection module to allow multiple products from diff. Lvl3
-------------------------------------------------------------------------*/

  OppProductItemTriggerHandler handler = new OppProductItemTriggerHandler();
	List<Opp_ProductItem__c > lstPItems = new List<Opp_ProductItem__c >();
  
  if(Trigger.isAfter && Trigger.isInsert){
      handler.updateOppoProductLevel3(trigger.new);
  }
  
	if(Trigger.isAfter && Trigger.isUpdate) {
      for(Integer i=0; i<trigger.new.size();i++){
          if(trigger.new[i].Product__c != trigger.old[i].Product__c){
              lstPItems.add(trigger.new[i]);
          }
      }
      if(lstPItems.size() > 0){
          handler.updateOppoProductLevel3(trigger.new);
      }
	}
  
  if(Trigger.isBefore && Trigger.isDelete){
      handler.handleBeforeDelete(trigger.old);
  }
  
  if(Trigger.isAfter && Trigger.isDelete){
      handler.updateOppoProductLevel3(trigger.old);
  }
}