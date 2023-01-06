@IsTest
public class AP61_Product_Test {
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
	static List<Product__c> lstProds = new List<Product__c>();
	static Contract__c ctr; 
	static Opportunity opp;
	static List<Id> lstOppProdId = new List<Id>();
	static List<Opp_ProductItem__c> lstOppProductItem;
    
    static user testUser, vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct1;
    static Product__c vProduct2;
    static Product__c vProduct3;
	static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
		System.runAs(testUser){
            
            vUserOO = AP05_TestDataFactory.createOOUser();
			// Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct1 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct1');
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct3');
            
     		ctr =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
			insert ctr;

			opp 		= new Opportunity(	OwnerId		= testUser.Id,
											Name 		= 'Test Opp',
											AccountId 	= vEAccount.Id,
											StageName 	= AP_Constant.STAGE_LEADS_GATHERING,
											CloseDate	= System.Today().addMonths(-5),
											//Project_start_Date__c = System.Today().addMonths(-5),
											//Go_live_date__c = System.Today().addMonths(-1),
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
											RecordTYpeId  = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
			);
			insert opp;
		}
	}
	
   	@IsTest
    public static void testChangeProductStatus(){
        System.runAs(testUser) {
			List<Id> lstProdId = new List<Id>();
			lstProdId.add(vProduct1.Id);
			lstProdId.add(vProduct2.Id);
			lstProdId.add(vProduct3.Id);
			LC16_AddProduct.saveRecords(ctr.Id, lstProdId);
			LC16_AddProduct.saveRecords(opp.Id, lstProdId);
            test.StartTest();
			vProduct1.Status__c = 'Retired';
			vProduct1.Product_Level_3__c = 'Test';
			update vProduct1;
            test.StopTest();
        }
    }
}