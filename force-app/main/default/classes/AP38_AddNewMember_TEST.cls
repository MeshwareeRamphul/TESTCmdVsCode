@isTest
private class AP38_AddNewMember_TEST {
/* 
----------------------------------------------------------------------
-- - Name          : AP38_AddNewMember_TEST
-- - Author        : Spoon Consulting
-- - Description   : Test Class for AP38_AddNewMember
-- Maintenance History:
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  ---------------------------------------
-- 20-OCT-2017  HVA    1.0      Initial version  
-- 21-OCT-2017  MRA    1.1      Reworked and optimised to resolve issue 'Too many soql query'              
---------------------------------------------------------------------
**********************************************************************
*/
	
	static User user;
	static User relatedUser;
	static List<Account> lstAccts;
	static Map<string,Id> mapAcctRecordTypes;
	static Map<string,Id> mapContRecordTypes;
	static Contact axaRep;
	static Contract__c contract;
    static string rtConDraftId;

	static{

		rtConDraftId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId();								  

		mapAcctRecordTypes = TestFactory.MapRecordType('Account');

		mapContRecordTypes = TestFactory.MapRecordType('Contact');
	
		user = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert user;

		System.runAs(user){

			relatedUser = new User( Username = 'test1@test11.test1', 
									LastName = 'test', 
									Email ='test@test1.test', 
									Alias = 'test', 
									ProfileId = UserInfo.getProfileId(),
	                            	TimeZoneSidKey = 'Europe/London', 
	                            	LocaleSidKey = 'en_US', 
	                            	EmailEncodingKey = 'UTF-8', 
	                            	LanguageLocaleKey = 'en_US', 
	                            	cTin_EntityLocalCode__c='CORE', 
	                            	PAD_BypassValidationRules__c = true, 
	                            	isActive = true, 
	                            	cTin_LegalRepresentative__c = true );
			insert relatedUser;

			lstAccts = new List<Account>();

			lstAccts = new List<Account>{TestFactory.createSupplier('Test Supplier', 'Florange', 'France')};
			lstAccts.add(new Account(Name = 'Test Supplier AXA', 
									 BillingCity = 'Florange',
									 BillingCountry = 'France',
									 RecordTypeId = mapAcctRecordTypes.get('cTin_AXA')));
			insert lstAccts;

			axaRep = new Contact(FirstName ='Test', 
                                 LastName = 'TestCon', 
                                 AccountId = lstAccts[1].Id , 
                                 email = 'testKerensen@gmail.com', 
                                 Phone = '+212667849903',
                                 cTin_Active__c = true, 
                                 cTin_LegalRepresentative__c = true,
                                 cTin_RelatedUser__c = relatedUser.Id);
			insert axaRep;
			
		}
	}

    //test scenario : add axa representative as team member
	static TestMethod void addAxaRep_Test(){

		System.runAs(user){
			test.startTest();
				contract = TestFactory.createcTinContracts('Test Contract', lstAccts[0].Id, rtConDraftId);
				contract.cTin_AXASignatoryRepresentative__c = axaRep.Id;
				contract.cTin_SupplierAccount__c = null ; 
		        contract.cTin_CommittedSpentAmount__c = '2';
		        contract.cTin_PaymentTerms__c = '15 days';
				insert contract;
			test.stopTest();

			list<cTin_ContractTeam__c> cTeamLst=[select id from cTin_ContractTeam__c where cTin_Contract__c=:contract.id];
			system.assertNotEquals(0,cTeamLst.size());
		}

	}

   //test scenario : delete Axa rep from team member
   static TestMethod void deleteAxaRep_Test(){
		System.runAs(user){
			contract = TestFactory.createcTinContracts('Test Contract', lstAccts[0].Id, rtConDraftId);
			contract.cTin_AXASignatoryRepresentative__c = axaRep.Id;
			contract.cTin_SupplierAccount__c = null ; 
	        contract.cTin_CommittedSpentAmount__c = '2';
	        contract.cTin_PaymentTerms__c = '15 days';
			insert contract;

			list<cTin_ContractTeam__c> cTeamInitialLst=[select id 
			                                           from cTin_ContractTeam__c 
			                                           where cTin_Contract__c=:contract.id];

			//set axa rep to blank
			contract.cTin_AXASignatoryRepresentative__c = null;

			test.startTest();			
				update contract;
			test.stopTest();

			list<cTin_ContractTeam__c> cTeamFinalLst=[select id 
			                                         from cTin_ContractTeam__c 
			                                         where cTin_Contract__c=:contract.id];

			system.assertNotEquals(cTeamInitialLst.size(),cTeamFinalLst.size());
		}	

	}

}