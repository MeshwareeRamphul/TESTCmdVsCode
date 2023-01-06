public without sharing class ProductItemTriggerHandler { 
	
    /*----------------------------------------------------------------------
-- - Name          : ProductItemTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for ProductItem__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 					   1.0      Initial version 
-- 08-JUL-2021  ARA    1.1      SP-01432: Block process when related contract is read only
-- 07-SEP-2022  ARA    1.2      SP-03707: Update Product selection module to allow multiple products from diff. Lvl3
-------------------------------------------------------------------------*/

	public ProductItemTriggerHandler(){}

	public void handleChanges(List<ProductItem__c> lstProdItemNew){
		system.debug('##AP51## Starting handlebeforeInsert: ' + lstProdItemNew );
		List<ProductItem__c> lstProdItemNewNotfromOpp = new List<ProductItem__c>();
		map<id,id> pItemIdContractIdMap=new map<id,id>();

		for(ProductItem__c pItem:lstProdItemNew){
			//check added to prevent update on contract when creating line from oppty
			if (pItem.Tech_OppItem__c == null){
				pItemIdContractIdMap.put(pItem.id,pItem.contract__c);
				lstProdItemNewNotfromOpp.add(pItem);
			}
		}

		if(PAD.canTrigger('AP51') && lstProdItemNewNotfromOpp.size() > 0)
			AP51_ManageProductonContract.blockProductItem(lstProdItemNewNotfromOpp,pItemIdContractIdMap);
	}
	
	public void handleBeforeDelete(List<ProductItem__c> lstProdItem){
		// 08-07-2021	SP-01432
		Set<Id> lstCtrId = new Set<Id>();
		List<Contract__c> lstContract = new List<Contract__c>();
		set<Id> setCtrRecTypesOpCoRO    = new set<Id>{ Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId(),  Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING_LABEL).getRecordTypeId()};

		for(ProductItem__c pItem:lstProdItem){
			lstCtrId.add(pItem.Contract__c);
		}
		lstContract = [SELECT Id FROM Contract__c WHERE Id IN :lstCtrId AND RecordTypeId IN :setCtrRecTypesOpCoRO];
		if(lstContract.size() > 0){
			lstProdItem[0].addError('Related product cannot be deleted at this contract status');
		}
	}

	// 07-SEP-2022  ARA     SP-03707
	public void updateContractProductLevel3(List<ProductItem__c> lstProdItem){
		Set<Id> setCtrId = new Set<Id>();
		for(ProductItem__c pItem: lstProdItem){
			setCtrId.add(pItem.Contract__c);
		}
		// 07-09-2022	SP-03707
		if(setCtrId.size() > 0){
			List<Contract__c> lstCtr = new List<Contract__c>();
			Map<Id, String> mapProductLevel3 = new Map<Id, String>();
			
			for(ProductItem__c pItem: [SELECT Id, Contract__c, Product_Level_3__c, Status__c FROM ProductItem__c WHERE Contract__c IN :setCtrId]){
				if(pItem.Status__c == Label.Product_status_live){
					if(!mapProductLevel3.containsKey(pItem.Contract__c)){
						mapProductLevel3.put(pItem.Contract__c, pItem.Product_Level_3__c);
					}else if(mapProductLevel3.get(pItem.Contract__c) != pItem.Product_Level_3__c){
						mapProductLevel3.put(pItem.Contract__c, Label.Contract_MultiProductLevel3);
					}
				}
			}
			
			for(Id ctrId: setCtrId){
				if(mapProductLevel3.containsKey(ctrId)){
					lstCtr.add(new Contract__c(Id = ctrId, Product_Level_3__c = mapProductLevel3.get(ctrId)));
				}else{
					lstCtr.add(new Contract__c(Id = ctrId, Product_Level_3__c = ''));
				}
			}
			//update lstCtr;
			Database.update(lstCtr,false);
		}
	}
}