public with sharing class AP02_Opportunities {
	/*----------------------------------------------------------------------
    -- - Name          : AP02_Opportunities
    -- - Author        : Spoon
	-- - Description   : Class for checking stage, setting the user assinged to, 
						and Prefill Opp AXA GO Entity field with user connected company
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 					   1.0      Initial version
	-- 09-SEP-2020	ARA	   1.1		Optimization (SP-00321)
    -------------------------------------------------------------------------*/

	/**
    * Before insert method : Change the owner if not the oo
    */
	public static void handleBeforeInsert(List<Opportunity> lstOpportunity) {
		User currUser = [SELECT Name, Company__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		Set<String> setOppPickListValues = AP_Constant.getPickListValuesIntoListOpp();

		for (Opportunity opp : lstOpportunity){
			// Verify the stage
			if (!AP_Constant.STAGE_LEADS_GATHERING.equals(opp.StageName)) {
				opp.StageName.addError(System.Label.Opty_Err_Status_Creation);
			}

			// Add the user assinged to
			opp.Assigned_to__c = opp.OwnerId;

			//SRA 22082019 Prefill Opp AXA GO Entity field with user connected company
            if (OpportunityHandler.setOppRecTypesOpCo.contains(opp.recordtypeId)){
				if(currUser.Company__c != null && setOppPickListValues.contains(currUser.Company__c) && (opp.AXA_GO_Entity__c == null)) {
					opp.AXA_GO_Entity__c = currUser.Company__c;
				}
				else if (opp.AXA_GO_Entity__c == null) {
					opp.addError('Cannot find picklist value');
				}
			}
		}
	}
}