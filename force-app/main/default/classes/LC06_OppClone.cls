public with sharing class LC06_OppClone {
	/*
----------------------------------------------------------------------
-- - Name          : LC06_OppClone
-- - Author        : SPOON
-- - Description   : Controller for opportunity clone
--                  
--
-- Maintenance History:
--
-- Date          Name      Version   Remarks
-- -----------   ----     -------   ---------------------------------------
-- -----------------        1.0      Initial version (SP-00219)
-- 30-JUN-2021   ARA        1.1      SP-01432: Do not clone product items
--------------------------------------------------------------------------- */
    
	static Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Opportunity');

	static Set<String> setAXAGsEntity = AP_Constant.getPickListValuesIntoListOpp();

	private static boolean canBeCloned(Opportunity currentOpp){

		System.debug('## LC06_OppClone.canBeCloned start.');

		Set<Id> setAppRecTypesId = new Set<Id>();
		for (RecordType recType: [SELECT Id, Name FROM RecordType WHERE SObjectType ='Opportunity'
		AND (DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL OR
		DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL_RO OR
		DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE OR
		DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO)
		]){
			setAppRecTypesId.add(recType.Id);
		}
		System.debug('##lc06 setAppRecTypesId ' + setAppRecTypesId);

		if (setAppRecTypesId.contains(currentOpp.RecordTypeId) ){
			return true;
		}
		else{
			return false;
		}
	}

	@AuraEnabled
	public static String cloneOpportunity(String oppId){
		System.debug('## LC06_OppClone.cloneOpportunity start.');

		List<Opportunity> currentOpp = [SELECT AccountId, AXA_GO_Entity__c, Name, Amount, Probability, StageName, Assigned_to__c, CloseDate, OwnerId, CurrencyIsoCode, Opportunity_Context__c,
				Business_Value__c, Category__c, Answer_due_date__c, Funding__c, Entity_contact__c, Answer_sent_date__c, Entity_sponsor__c,Answer_cinematic__c,
				PM_works_on_the_answer__c, Project_start_Date__c, End_users_type__c, Go_live_date__c, Pre_Sales_Effort_M_d__c, Close_decision_maker__c, Lost_comment__c,
				Closed_lost_reason__c, Lost_in_Stage__c,RecordTypeId,TECH_HaveContract__c,TECH_Assignment_done__c,TECH_ContractStatus__c
		FROM Opportunity WHERE Id =:oppId
		LIMIT 1];

		System.debug('## LC06_OppClone.currentOpp : ' + currentOpp);

		if ( currentOpp.size() == 0 ){
			return 'The opportunity has not been found to be cloned';
		}

		if (canBeCloned(currentOpp[0])){
			System.debug('## LC06_OppClone.cloneOpportunity continue.');

			Opportunity clonedOpp = currentOpp[0].clone(false, true, false, false); //Deep clone

			//Full
			if (currentOpp[0].RecordTypeId == vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_FULL).Id ||
					currentOpp[0].RecordTypeId == vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_FULL_RO).Id) {
				clonedOpp.RecordTypeId = vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_FULL).Id;
			}
			//Single
			if (currentOpp[0].RecordTypeId == vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).Id ||
					currentOpp[0].RecordTypeId == vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO).Id) {
				clonedOpp.RecordTypeId = vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).Id;
			}

			if (setAXAGsEntity.contains(currentOpp[0].AXA_GO_Entity__c)){

				if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS France' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services France' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations France';
				}
				else if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS Asia' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services Asia' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited';
				}
				else if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS UK' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services UK' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations UK';
				}
				else if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS Spain' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services Spain' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations Spain';
				}
				else if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS Portugal' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services Portugal' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations Portugal';
				}
				else if (currentOpp[0].AXA_GO_Entity__c == 'AXA GS Switzerland' || currentOpp[0].AXA_GO_Entity__c == 'AXA Services Switzerland' ){
					clonedOpp.AXA_GO_Entity__c = 'AXA Group Operations Switzerland';
				}
				else{
					System.debug('##lc06 currentOpp[0].AXA_GO_Entity__c: ' + currentOpp[0].AXA_GO_Entity__c);
					clonedOpp.AXA_GO_Entity__c = currentOpp[0].AXA_GO_Entity__c;
				}
			}
			else{
				System.debug('##lc06 currentOpp[0].AXA_GO_Entity__c: ' + currentOpp[0].AXA_GO_Entity__c + ' does not exist.');
				currentOpp[0].AXA_GO_Entity__c = null;
			}

			clonedOpp.stageName = AP_Constant.STAGE_LEADS_GATHERING;
			clonedOpp.Name = 'NEW_OPPORTUNITY';
			clonedOpp.TECH_HaveContract__c = false;
			clonedOpp.TECH_Assignment_done__c = false;
			clonedOpp.TECH_ContractStatus__c = '';
			clonedOpp.Probability = 25.0;
			clonedOpp.OwnerId = UserInfo.getUserId();

			System.debug('## LC06_OppClone.cloneOpportunity - Before inserting the cloned opp into database');
			try {
				insert clonedOpp;
			}
			catch (Exception e) {
				System.debug('Technical error occured : ' + e.getMessage());
				return 'Technical error occured : ' + e.getMessage();
			}
			System.debug('## LC06_OppClone.cloneOpportunity ends');
			return clonedOpp.Id;
		}
		else{
			return 'You cannot clone the following opportunity : ' + currentOpp[0].Name ;
		}
	}
}