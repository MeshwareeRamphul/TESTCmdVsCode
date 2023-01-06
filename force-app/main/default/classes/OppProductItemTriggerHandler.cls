public class OppProductItemTriggerHandler {
    /*----------------------------------------------------------------------
-- - Name          : OppProductItemTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Opp_ProductItem__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 08-JUL-2021  ARA    1.0      SP-01432: Initial version 
-- 07-SEP-2022  ARA    1.2     SP-03707: Update Product selection module to allow multiple products from diff. Lvl3
-------------------------------------------------------------------------*/
    
	public void handleBeforeDelete(List<Opp_ProductItem__c> lstProdItem){
		Set<Id> lstOppId = new Set<Id>();
		List<Opportunity> lstOpp = new List<Opportunity>();
		set<Id> setOppRecTypesOpCoRO    = new set<Id>{ Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.RT_SingleOppReadOnly).getRecordTypeId(),  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.RT_FullOppReadOnly).getRecordTypeId()};

		for(Opp_ProductItem__c pItem:lstProdItem){
			lstOppId.add(pItem.Opportunity__c);
		}
		lstOpp = [SELECT Id FROM Opportunity WHERE Id IN :lstOppId AND RecordTypeId IN :setOppRecTypesOpCoRO];
		if(lstOpp.size() > 0){
			lstProdItem[0].addError('Related product cannot be deleted at this opportunity stage');
		}
	}
    
	// 07-SEP-20212  ARA    SP-03707
	public void updateOppoProductLevel3(List<Opp_ProductItem__c> lstProdItem){
		Set<Id> setOpp = new Set<Id>();
		for(Opp_ProductItem__c pItem: lstProdItem){
			setOpp.add(pItem.Opportunity__c);
		}
		// 07-09-2022	SP-03707
		if(setOpp.size() > 0){
			List<Opportunity> lstOpp = new List<Opportunity>();
			Map<Id, String> mapProductLevel3 = new Map<Id, String>();

			for(Opp_ProductItem__c pItem: [SELECT Id, Opportunity__c, Product_Level_3__c, Status__c FROM Opp_ProductItem__c WHERE Opportunity__c IN :setOpp]){
				if(pItem.Status__c == Label.Product_status_live){
					if(!mapProductLevel3.containsKey(pItem.Opportunity__c)){
						mapProductLevel3.put(pItem.Opportunity__c, pItem.Product_Level_3__c);
					}else if(mapProductLevel3.get(pItem.Opportunity__c) != pItem.Product_Level_3__c){
						mapProductLevel3.put(pItem.Opportunity__c, Label.Contract_MultiProductLevel3);
					}
				}
			}
			
			for(Id oppId: setOpp){
				if(mapProductLevel3.containsKey(oppId)){
					lstOpp.add(new Opportunity(Id = oppId, Product_Level_3__c = mapProductLevel3.get(oppId)));
				}else{
					lstOpp.add(new Opportunity(Id = oppId, Product_Level_3__c = ''));
				}
			}
			//update lstOpp;
			Database.update(lstOpp,false);
		}
	}
}