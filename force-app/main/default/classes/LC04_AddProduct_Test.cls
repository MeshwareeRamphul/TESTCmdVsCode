@isTest
private class LC04_AddProduct_Test {
/*
----------------------------------------------------------------------
-- - Name          : LC04_AddProduct_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC04_AddProduct
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 02-MAY-2019   ZHE    1.0    Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
static User vUserPM;
	static Account acc;
	static Contact con;
	static List<Product__c> lstProds = new List<Product__c>();
	static Contract__c ctr; 
	static User vUserAdmin;

	static Opportunity opp;
	static Account entity;
	static Account LeEntity;

	static List<Id> lstOppProdId = new List<Id>();
	static List<Opp_ProductItem__c> lstOppProductItem;
	static List<String> lstResult1;



	static{
		
		vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' AND IsActive =  true LIMIT 1];
		System.runAs(vUserAdmin){

			acc          = AP05_TestDataFactory.createLegalEntityAccount(vUserAdmin);
			entity		 = AP05_TestDataFactory.createEntityAccount(vUserAdmin);
			LeEntity 	 = AP05_TestDataFactory.linkLEgalEntityToEntity(entity, acc);
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
									       Invoicing_Condition__c           = System.Label.InvoicingCondition_100BeginningOfService,
									       Global_Amount__c                 = 10000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(),
									       Signature_Type__c 				= 'Manual');
			insert ctr;

			opp 		= new Opportunity(	OwnerId                         = vUserAdmin.Id,
											Name 							= 'Test Opp',
											AccountId 						= entity.Id,
											StageName 						= AP_Constant.STAGE_LEADS_GATHERING,
											CloseDate						= System.Today().addMonths(-5),
											//Project_start_Date__c = System.Today().addMonths(-5),
											//Go_live_date__c = System.Today().addMonths(-1),
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
											RecordTYpeId                     = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
			);
			insert opp;

			
		}
	}
	@IsTest
    public static void testGetAllProducts(){
        System.runAs(vUserAdmin) {
            test.StartTest();
            	//method returns a list of Product which is related to the offer of the contract
	            List<Product__c> lstProd = LC04_AddProduct.getAllProducts(ctr.Id);
				System.debug('lstProd: ' + lstProd);

				// SGO - 2019/09/04 - get all opp prod 
	            List<Product__c> lstOppProd = LC04_AddProduct.getAllProducts(opp.Id);
				System.debug('lstOppProd: ' + lstOppProd);

            test.StopTest();

            /*System.assertEquals(5, lstProd.size());
            System.assertEquals(5, lstOppProd.size());*/

        }
    }
   	@IsTest
    public static void testSaveRecords(){
        System.runAs(vUserAdmin) {
            test.StartTest();
            	List<Id> lstProdId = new List<Id>();
            	lstProdId.add(lstProds[0].Id);
            	lstProdId.add(lstProds[2].Id);
            	lstProdId.add(lstProds[4].Id);
	            List<String> lstResult = LC04_AddProduct.saveRecords(lstProdId, ctr.Id);

				// SGO - 2019/09/04 - Opp prod
				lstOppProdId.add(lstProds[1].Id);
            	lstOppProdId.add(lstProds[3].Id);
            	lstResult1 = LC04_AddProduct.saveRecords(lstOppProdId, opp.Id);

            test.StopTest();
            
            List<ProductItem__c> lstProductItem = [select id, name, ProductDescription__c, Product__c from ProductItem__c where Contract__c = : ctr.Id];
            System.assertEquals(null, lstResult);
            System.assertEquals(3, lstProductItem.size());
            System.assertEquals(lstProds[0].Id, lstProductItem[0].Product__c);
            System.assertEquals(lstProds[2].Id, lstProductItem[1].Product__c);
            System.assertEquals(lstProds[4].Id, lstProductItem[2].Product__c);

			// SGO - 2019/09/04 - Opp prod
			lstOppProductItem = [select id, name, ProductDescription__c, Product__c from Opp_ProductItem__c where Opportunity__c = : opp.Id];
            System.assertEquals(null, lstResult1);
            System.assertEquals(2, lstOppProductItem.size());
            System.assertEquals(lstProds[1].Id, lstOppProductItem[0].Product__c);
            System.assertEquals(lstProds[3].Id, lstOppProductItem[1].Product__c);
            
        }
    }
}