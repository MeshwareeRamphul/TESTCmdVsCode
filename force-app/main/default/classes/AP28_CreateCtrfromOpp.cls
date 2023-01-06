public with sharing class AP28_CreateCtrfromOpp {
	/*----------------------------------------------------------------------
    -- - Name          : AP28_CreateCtrfromOpp
    -- - Author        : Spoon Consulting 
    -- - Description   : Class for generating contract from opportunity
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 29-MAY-2019  USA    1.0      Initial version
	-- 11-FEB-2020  USA    1.1      Update for referentiel produit (SP-154)
    -- 08-SEP-2020  ARA    1.2      Optimization code (SP-321)
-------------------------------------------------------------------------*/

	public static void createCtrfromOpp (map<Id, Opportunity> mapOpp){
		//System.debug('##AP28## mapOpp: ' + mapOpp);
		List<Contract__c> lstCtrToInsert = new List<Contract__c>();
		List<ProductItem__c> lstCtrItemToInsert = new List<ProductItem__c>();
		mapOpp = new Map<Id, Opportunity>([SELECT Id, OwnerId,(SELECT Id, Product__r.Id, Opportunity__c, Product__c, ProductDescription__c, Status__c
												  FROM Opportunity_Product_Items__r), 
												 CurrencyIsoCode, AXA_GO_Entity__c, 
	                        					 (SELECT Id FROM Contracts1__r), Project_start_Date__c, AccountId, Name, StageName, Amount, PM_works_on_the_answer__c, Product__c, RecordTypeId, Go_live_date__c, Category__c
                							 FROM Opportunity 
                							 WHERE ID in :mapOpp.KeySet()]);
        for (Opportunity opp : mapOpp.values()){
        	//check if contract already exists
        	if (opp.Contracts1__r.size() <= 0){
	        	Contract__c vContract = new Contract__c();   

				vContract.Global_Amount__c 		   = opp.Amount != null? opp.Amount : 0;
		        vContract.OwnerId                  = opp.PM_works_on_the_answer__c != null ? opp.PM_works_on_the_answer__c : opp.OwnerId;
		        vContract.Opportunity__c           = opp.Id;
		        vContract.Name                     = opp.Name;
		        vContract.Status__c                = AP_Constant.CONTRACT_STATUS_DRAFT;
		        vContract.C_Account__c             = opp.AccountId;
		        vContract.CurrencyIsoCode          = opp.CurrencyIsoCode;
		        vContract.RecordTypeId             = AP_Constant.getRecordTypes('Contract__c').get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
		        vContract.StartDate__c             = opp.Project_start_Date__c;
		        vContract.EndDate__c               = opp.Go_live_date__c;
		        // vContract.TECH_Apex_Context__c     = true;
				vContract.TECH_Apex_Context__c     = false;
				vContract.AXA_GO_Legal_Entity__c   = opp.AXA_GO_Entity__c != AP_Constant.GS_ENTITY_AXA_GR_OP_FR ? opp.AXA_GO_Entity__c : null;
		        vContract.Service_Type_Picklist__c = convertFromCategoryToServiceTypePicklist(opp.Category__c);
		        
				lstCtrToInsert.add(vContract);
			}
		}

		if (lstCtrToInsert.size() > 0){
			try{
				insert lstCtrToInsert;
				for (Contract__c ctrInserted : lstCtrToInsert){
					for (Opp_ProductItem__c oppItem : mapOpp.get(ctrInserted.Opportunity__c).Opportunity_Product_Items__r){
						ProductItem__c ctrItem         = new ProductItem__c();
						ctrItem.Tech_OppItem__c        = oppItem.Id;
						ctrItem.Product__c             = oppItem.Product__c;
						ctrItem.ProductDescription__c  = oppItem.ProductDescription__c;
						ctrItem.Status__c              = oppItem.Status__c;
						ctrItem.Contract__c            = ctrInserted.Id;

						lstCtrItemToInsert.add(ctrItem);
					}
				}
				if (lstCtrItemToInsert.size() > 0){
					try{
						insert lstCtrItemToInsert;
					}
					catch(exception e) {
						system.debug('##AP28## error insert ctr items: ' + e.getMessage());
						mapOpp.get(lstCtrToInsert[0].Opportunity__c).addError('##AP28## error insert ctr items: ' + e.getMessage());
					}
				}
			}
			catch(exception e){
				system.debug('##AP28## error insert ctr: ' + e.getMessage());
				mapOpp.get(lstCtrToInsert[0].Opportunity__c).addError('##AP28## error insert ctr: ' + e.getMessage());			
			}
		}
	}

	/**
     * Methode convertFromCategoryToServiceTypePicklist : will convert a category into
     * a service type picklist
     * @param category String : the category from oppty
     * @return String : the service typ picklist value for the contract
     */
    private static String convertFromCategoryToServiceTypePicklist(String category){
        //variables declaration
        String serviceTypePicklist = '';

        if(category == System.Label.OptyCategory_Project){
            serviceTypePicklist = System.Label.Contract_ServiceTypePicklist_Project;
        }
        else{
            serviceTypePicklist = System.Label.Contract_ServiceTypePicklist_BAU;
        }
        //Returning the corresponding serviceTypePicklist
        return serviceTypePicklist;
    }
}