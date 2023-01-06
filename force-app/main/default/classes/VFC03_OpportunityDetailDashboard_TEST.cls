@isTest
private class VFC03_OpportunityDetailDashboard_TEST {
/*
----------------------------------------------------------------------
-- - Name          : VFC06_OpportunityDetailDashboard_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class of VFC06_OpportunityDetailDashboard
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 17-JUNE-2014   MRA    1.0    Intitial version
----------------------------------------------------------------------
**********************************************************************
*/	
	static User testUser;
    static Account vAccount;
	static list <Account> accountList;
	static list<Opportunity> lstOpps;
	
	static{
		//creating test user
		testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
		testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
		insert testUser;

		System.runAs(testUser){
			
			vAccount = AP05_TestDataFactory.createEntityAccount(testUser);
			
			Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ testUser);

			lstOpps = new List<Opportunity>{
				new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Ap_Constant.RT_OPP_LIGHTNING_FULL_LABEL).getRecordTypeId(),
				Name = 'opp1', Product__c = vProduct.Id, Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id, AccountId = vAccount.Id),
				new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Ap_Constant.RT_OPP_LIGHTNING_FULL_LABEL).getRecordTypeId(),
				Name = 'opp2', Product__c = vProduct.Id, Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id, AccountId = vAccount.Id),
				new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Ap_Constant.RT_OPP_LIGHTNING_FULL_LABEL).getRecordTypeId(),
				Name = 'opp3', Product__c = vProduct.Id, Category__c = Label.OptyCategory_Project, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id, AccountId = vAccount.Id)
			};   
			    	                                         
            insert lstOpps;      
		}
	}//end static
	
	static testMethod void test_OppDetailDashboard(){
		system.debug('## >>>Starting method test_OppDetailDashboard<<<< ');
		system.runAs(testUser){
			test.startTest();
				PageReference pageRef = Page.VFP03_OpportunityDetailDashboard;
				Test.setCurrentPage(pageRef);
			    ApexPages.StandardController sc1 = new ApexPages.StandardController(lstOpps[0]);		        
			    VFC03_OpportunityDetailDashboard controller = new VFC03_OpportunityDetailDashboard(sc1);	
			test.stopTest();	
			
			//assert 
			system.assertEquals(2, controller.clashOppList.size());		
		}	
		system.debug('## >>>Ending method test_OppDetailDashboard<<<< ');	
	}
}