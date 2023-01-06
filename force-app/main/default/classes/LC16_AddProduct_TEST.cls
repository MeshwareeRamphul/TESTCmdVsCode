@isTest
public class LC16_AddProduct_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC16_AddProduct_TEST
-- - Author        : ARA
-- - Description   : Test for class LC16_AddProduct
--                  
--
-- Maintenance History:
--
-- Date          Name      Version   Remarks
-- -----------   ----     -------   ---------------------------------------
-- 26-may-2020   ARA        1.0      Initial version (SP-00219)
--------------------------------------------------------------------------- */    
	static Account acc;
	static Contact con;
	static List<Product__c> lstProds = new List<Product__c>();
	static Contract__c ctr; 
	static List<Opportunity> lstOpps;
	static User testUser;
    static{
		
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
		System.runAs(testUser){

			acc          = AP05_TestDataFactory.createLegalEntityAccount(testUser);
			con          = AP05_TestDataFactory.createEntityContact(acc);
			lstProds     = new List<Product__c>{AP05_TestDataFactory.createProduct(testUser, 'Live !abcdefghijklmnnopqrstuvwxyz + de 25', 'test prod 1'),
												AP05_TestDataFactory.createProduct(testUser, 'Live !', 'test prod 2'),
												AP05_TestDataFactory.createProduct(testUser, 'Live !', 'test prod 3'),
												AP05_TestDataFactory.createProduct(testUser, 'Live !', 'test prod 4'),
												AP05_TestDataFactory.createProduct(testUser, 'Live !', 'test prod 5')};
			ctr          = new Contract__c(OwnerId                          = testUser.Id,
									       Name                             = 'ATS Test COntract',
									       AXA_GS_Signed_By__c              = con.Id,
									       CustomerSignedBy__c              = con.Id,
									       Customer_Operational_Contact__c  = con.Id,
									       Account__c                       = acc.Id,
									       ATS_Notify_Validation__c         = testUser.Id,
									       Status__c                        = AP_Constant.CONTRACT_STATUS_DRAFT,
									       StartDate__c                     = System.Today().addMonths(-5),
									       EndDate__c                       = System.Today().addMonths(-1),
									       AXA_GO_Legal_Entity__c           = 'AXA Group Operations SAS',
                                           ServiceType__c                   = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                                           InvoicingMethod__c               = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
									       Invoicing_Condition__c           = System.Label.InvoicingCondition_100BeginningOfService,
									       Global_Amount__c                 = 12000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(),
									       Signature_Type__c 				= 'Manual');
			insert ctr;
			lstOpps = new List<Opportunity>{
                new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId(),
                Name = 'opp1', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id),
                new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId(),
                Name = 'opp2', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id)
            };
			insert lstOpps;
		}
	}
    
	@isTest
    public static void getProductCatalogTest(){
        System.runAs(testUser) {
            test.StartTest();
	            LC16_AddProduct.getProductCatalog();
            test.StopTest();
        }
    }
    
	@isTest
    public static void getRecordTest(){
        System.runAs(testUser) {
            test.StartTest();
            	//method returns a list of Product which is not related the contract
	            sObject ctr = LC16_AddProduct.getRecord(ctr.Id);
            test.StopTest();
        }
    }
    
	@isTest
    public static void getProductsTest(){
        System.runAs(testUser) {
            String textSearch = 'test pr';
            test.StartTest();
            	//method returns a list of Product which is not related the contract
	            List<Product__c> lstProd = LC16_AddProduct.getProducts(textSearch, ctr.Id, 'product level 3', new List<Product__c>());
            test.StopTest();
            System.assertEquals(5, lstProd.size());
        }
    }
    
    @isTest
    public static void saveContractPIRecordsTest(){
        System.runAs(testUser) {
            List<Id> lstIdProd = new List<Id>();
            List<Product__c> lstProd = LC16_AddProduct.getProducts('test prod', ctr.Id, 'product level 3', new List<Product__c>());
            for(Integer i=0; i<3; i++){
                lstIdProd.add(lstProd[i].Id);
            }
            
            test.StartTest();
            	//method returns a list of Product which is not related the contract
	            List<String> results = LC16_AddProduct.saveRecords(ctr.Id, lstIdProd);
            test.StopTest();
            System.assertEquals(null, results);
        }
    }
    
    @isTest
    public static void saveOpportunityPIRecordsTest(){
        System.runAs(testUser) {
            List<Id> lstIdProd = new List<Id>();
            List<Product__c> lstProd = LC16_AddProduct.getProducts('test prod', lstOpps[0].Id, 'product level 3', new List<Product__c>());
            for(Integer i=0; i<3; i++){
                lstIdProd.add(lstProd[i].Id);
            }
            
            test.StartTest();
            	//method returns a list of Product which is not related the contract
	            List<String> results = LC16_AddProduct.saveRecords(lstOpps[0].Id, lstIdProd);
            test.StopTest();
            System.assertEquals(null, results);
        }
    }
}