@isTest
private class LC08_CtrDelete_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC08_CtrDelete_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC08_CtrDelete
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 22-AUG-2019   KZE    1.0    Intitial version
-- 20-SEP-2019	 SGO 	1.1	   handleExceptions()
-- 23-SEP-2019	 SGO	1.2	   allowDelete() modified
----------------------------------------------------------------------
**********************************************************************
*/
	static User vUserPM;
	static User vUserPMO;
	static Account acc;
	static Contact con;
	static List<Product__c> lstProds = new List<Product__c>();
	static List<Contract__c> lstContrs = new List<Contract__c>();
	static Contract__c ctr; 
	static Contract__c ctr2; 
	static User vUserAdmin;
	static User testUserAdmin;

	static List<User> lstUsers = new List<User>();

	static{

		vUserAdmin   = TestFactory.createUser('UsrAdmin',TestFactory.getProfileIdByName('System Administrator'),true);
		
        testUserAdmin = TestFactory.createUser('UsrAdmin1',TestFactory.getProfileAdminId(),true);
		testUserAdmin.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;

		lstUsers.add(vUserAdmin);
		lstUsers.add(testUserAdmin);

		insert lstUsers;
		
		User vUserAdmin = [Select Id from User Where Id = :vUserAdmin.Id ];
        
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
    public static void allowDelete(){
		User vUserAdmin = [Select Id from User Where Id = :vUserAdmin.Id ];
        System.runAs(vUserAdmin) {


            test.StartTest();

				DeletionPermissionFlag__c contractDeletionFlag= new DeletionPermissionFlag__c(SetupOwnerId=vUserAdmin.Id, ContractDelete__c=true);
				insert contractDeletionFlag;

				Boolean contractDeletionFlag1 = DeletionPermissionFlag__c.getInstance(UserInfo.getUserId()).ContractDelete__c;
				System.debug('## lc08 contractDeletionFlag1 ' + contractDeletionFlag1);

                LC08_CtrDelete.deleteContract(ctr.Id); 
				    
            test.StopTest();

			List<Contract__c> lstRetContrs = [select Id, name from Contract__c Where Id in :lstContrs];

            System.assertEquals(1, lstRetContrs.size());
        }
    }

	@IsTest
    public static void dontAllowDelete(){
        System.runAs(testUserAdmin) {
            test.StartTest();
                try{
                    LC08_CtrDelete.deleteContract(ctr.Id);
                    System.assert(false);
                }
				catch(AuraHandledException e) {
                    System.assert(true);
                    System.debug('## error msg in catch ' + e);

                    System.debug('## error msg in catch ' + e.getMessage());
                    System.assertEquals('Script-thrown exception',e.getMessage());
                }  	            
            test.StopTest();

            System.assertEquals(2, lstContrs.size());
        }
    }

	@IsTest
    public static void handleException(){
        System.runAs(testUserAdmin) {
            test.StartTest();
                try{

					delete ctr;

                    LC08_CtrDelete.deleteContract(ctr.Id);
                    System.assert(false);
                }
				catch(AuraHandledException e) {
                    System.assert(true);
                    System.debug('## error msg in catch ' + e);

                    System.debug('## error msg in catch ' + e.getMessage());
                    //System.assertEquals('Script-thrown exception',e.getMessage());
                }  	            
            test.StopTest();

        }
    }


}