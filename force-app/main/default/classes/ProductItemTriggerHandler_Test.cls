@isTest
public class ProductItemTriggerHandler_Test {
/*
----------------------------------------------------------------------
-- - Name          : ProductItemTriggerHandler_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of ProductItemTriggerHandler
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
	static Contract__c ctr;
    static user testUser, vUserOO;
    static Account vAccount,vAccount1;
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
            //vAccount1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            system.debug('****vAccount '+vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct1 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct1');
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct3');
            
     		ctr =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
			insert ctr;
		}
	}
	
   	@IsTest
    public static void testChangeProductStatus(){
        System.runAs(testUser) {
			
			List<Id> lstProdId = new List<Id>();
			lstProdId.add(vProduct1.Id);
			lstProdId.add(vProduct2.Id);
			LC16_AddProduct.saveRecords(ctr.Id, lstProdId);
            
            ctr.Contract_Signed_Date__c = System.Today();
            ctr.Status__c = System.Label.ContractStatus_Signed;
            ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Single_Contract_process_Read_Only_OpCo360').getRecordTypeId();
            ctr.PDFStatus_lgt__c ='Updated';
            update ctr;
            
            test.StartTest();
                List<ProductItem__c> lstProductItem = [select id, name, ProductDescription__c, Product__c from ProductItem__c where Contract__c = : ctr.Id];
                try{
                    delete lstProductItem[0];   
                }catch(DMLException e){
                    System.assert(e.getMessage().contains('Related product cannot be deleted at this contract status'));
                }
                lstProductItem[1].Product__c = vProduct3.Id;
                update lstProductItem[1];
            test.StopTest();
        }
    }
}