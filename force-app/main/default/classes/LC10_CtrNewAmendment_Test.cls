@isTest
public with sharing class LC10_CtrNewAmendment_Test {
    static user testUser;
    static User vUserOO;
    static User vUserPMOADV;
    static User vUserPMO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;

    static Contract__c vContract;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static Contract__c vContract4;

    static ProductItem__c vCtrPItem;
    static ProductItem__c vCtrPItem2;


    static String result;
    static Opportunity vOpp= new Opportunity();

    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static List<Planned_Invoicing_Line__c> lstInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstUpdInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Contract__c> lstContracts = new List<Contract__c>();
    static List<ProductItem__c> lstCtrPItems = new List<ProductItem__c>();

    static{

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        system.runAs(testUser){
            AP_Constant.themeLightning = true;
            // Create user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();
            vUserPMO = AP05_TestDataFactory.createPMOUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = testUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            vProduct2 = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct3');


            //Create contracts
            vContract = AP05_TestDataFactory.createContract2(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract2 = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);

            vContract3 = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL, vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract4 = AP05_TestDataFactory.createContract2(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING_LABEL, vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);

            lstContracts.add(vContract);
            lstContracts.add(vContract2);
            lstContracts.add(vContract3);
            lstContracts.add(vContract4);

            insert lstContracts;
        }
    }
    
	// start test
    @isTest
    public static void  cloneAmendmentTest() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        System.runAs(testUser) {
            vContract.AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_NEWLEGAL_ENTITY;
            update(vContract);

            test.StartTest();
                String returnvalue = LC10_CtrNewAmendment.createAmendmentFromContract(vContract.Id);
                System.assert(returnvalue.startsWith('a0D'));
                Contract__c clonedAmend = [SELECT Id, recordtypeId FROM Contract__c WHERE id =:returnvalue LIMIT 1];
                System.assertEquals(clonedAmend.recordtypeId, vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id );
            test.StopTest();
        }
    }
    
    @isTest
    public static void  cloneAmendment_ProductItem_Test() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        System.runAs(testUser) {
            ProductItem__c pItem = AP05_TestDataFactory.createCtrProdItems(vContract, vProduct2, 'Product 2');
            insert pItem;
            vContract.AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_NEWLEGAL_ENTITY;
            vContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
            update(vContract);

            test.StartTest();
                String returnvalue = LC10_CtrNewAmendment.createAmendmentFromContract(vContract.Id);
                System.assert(returnvalue.startsWith('a0D'));
            test.StopTest();
        }
    }
    
    //-- 30/07/2020	ARA	SP-00378
    @isTest
    public static void  cloneAmendment_Cancelled_Test() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        System.runAs(testUser) {
            vContract.AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_NEWLEGAL_ENTITY;
            vContract.Decision_maker__c = 'Entity';
            vContract.Cancelled_reason__c = 'Price';
            vContract.Status__c = System.Label.ContractStatus_Cancelled;
            update(vContract);

            test.StartTest();
                String returnvalue = LC10_CtrNewAmendment.createAmendmentFromContract(vContract.Id);
                System.assertEquals(returnvalue, System.Label.NewAmendmentError);
            test.StopTest();
        }
    }
}