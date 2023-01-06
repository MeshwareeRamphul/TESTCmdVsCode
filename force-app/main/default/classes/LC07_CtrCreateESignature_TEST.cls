@isTest
private class LC07_CtrCreateESignature_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC07_CtrCreateESignature_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC07_CtrCreateESignature
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 27-AUG-2019   KZE    1.0    Intitial version
-- 11-SEP-2019	 SGO 	1.2	   Method testHandleException added (100%)
----------------------------------------------------------------------
**********************************************************************
*/
    static User vUserPM;
	static Account acc;
	static Contact con;
	static List<Product__c> lstProds = new List<Product__c>();
	static List<Contract__c> lstContrs = new List<Contract__c>();
	static Contract__c ctr; 
	static Contract__c ctr2; 
	static User vUserAdmin;
	static User testUserAdmin;

	static{

        testUserAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUserAdmin;
		
		vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' AND IsActive =  true LIMIT 1];
        
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

		System.runAs(vUserAdmin){

			acc          = AP05_TestDataFactory.createLegalEntityAccount(vUserAdmin);
			con          = AP05_TestDataFactory.createEntityContact(acc);
			lstProds     = new List<Product__c>{AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 1'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 2'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 3'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 4'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 5')};
			ctr          = new Contract__c(OwnerId                          = vUserAdmin.Id,
									       Name                             = 'ATS Test COntract',
									       AXA_GS_Signed_By__c              = con.Id,
									       CustomerSignedBy__c              = con.Id,
									       Customer_Operational_Contact__c  = con.Id,
									       Account__c                       = acc.Id,
									       ATS_Notify_Validation__c         = vUserAdmin.Id,
									       Status__c                        = AP_Constant.CONTRACT_STATUS_DRAFT,
									       StartDate__c                     = System.Today().addMonths(-5),
									       EndDate__c                       = System.Today().addMonths(-1),
									       AXA_GO_Legal_Entity__c           = 'AXA Group Operations SAS',
										   ServiceType__c 					= AP05_TestDataFactory.CONTRACT_STYPE_BAU,
										   InvoicingMethod__c 				= AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
									       Invoicing_Condition__c           = '100% End of service',
									       Global_Amount__c                 = 10000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id,
									       Signature_Type__c 				= 'Manual');

			ctr2          = new Contract__c(OwnerId                          = vUserAdmin.Id,
									       Name                             = 'ATS Test COntract2',
									       AXA_GS_Signed_By__c              = con.Id,
									       CustomerSignedBy__c              = con.Id,
									       Customer_Operational_Contact__c  = con.Id,
									       Account__c                       = acc.Id,
									       ATS_Notify_Validation__c         = vUserAdmin.Id,
									       Status__c                        = AP_Constant.CONTRACT_STATUS_DRAFT,
									       StartDate__c                     = System.Today().addMonths(-5),
									       EndDate__c                       = System.Today().addMonths(-1),
									       AXA_GO_Legal_Entity__c           = 'AXA Group Operations SAS',
										   ServiceType__c 					= AP05_TestDataFactory.CONTRACT_STYPE_BAU,
										   InvoicingMethod__c 				= AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
									       Invoicing_Condition__c           = '100% End of service',
									       Global_Amount__c                 = 10000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id,
									       Signature_Type__c 				= 'Manual');
            lstContrs.add(ctr);
            lstContrs.add(ctr2);
			insert lstContrs;
		}
	}
	@IsTest
    public static void testgetStatut(){
        System.runAs(vUserAdmin) {
            test.StartTest();
                Object  c = LC07_CtrCreateESignature.getStatut(ctr.Id);
                System.assertNotEquals(c, null);  	            
            test.StopTest();
        }
    }

	@isTest
	public static void testHandleException(){
		System.runAs(vUserAdmin){
			test.StartTest();
			
				try{
					delete ctr;
					Object  c = LC07_CtrCreateESignature.getStatut(ctr.Id);
				}
				catch(Exception ex){
					//System.debug('##SGO##' +ex);
					System.assertEquals('Script-thrown exception', ex.getMessage());
					
				}

			test.StopTest();
		}
	}
}