@isTest

public without sharing class VFC07_ContractClone_Test {

    public  static Contract__c ATSContract,vContract;
    public static user adminUser,vUserPMO,vUserOO,vUserPM;
    public  static  Account vAccount,vEAccount; 
    public static Contact vEntityContact;
    public  static Product__c vProduct;
    public  static ProductItem__c pItem;

    static {
        //Create datas for the tests methods

        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName(); //'userAdmin@User.com';
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        adminUser.PAD_BypassValidationRules__c = true;
        insert adminUser;

        System.runAs(adminUser) {
            // Create PMO User
            vUserPMO = AP05_TestDataFactory.createPMOADVUser();

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            // Create PM user
            vUserPM = AP05_TestDataFactory.createPMUser();
            // Create the customer (aka entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            vAccount.signature_Type__c = 'Electronic';
            update vAccount;

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);
            
            ATSContract=new Contract__c(
                Name='ContractATS',
                AXA_GS_Signed_By__c             = vEntityContact.Id,
                CustomerSignedBy__c             = vEntityContact.Id,
                Customer_Operational_Contact__c = vEntityContact.Id,
                Account__c                      = vAccount.Id,/*Notify_Validation__c = vUserOO.Id, */
                Status__c                       = AP_Constant.CONTRACT_STATUS_DRAFT,
                StartDate__c                    = System.Today().addMonths(-5),
                EndDate__c                      = System.Today().addMonths(-1),
                AXA_GO_Legal_Entity__c          = 'AXA Group Operations SAS',
                ServiceType__c                  = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                InvoicingMethod__c              = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                Global_Amount__c                = 100,SOW_Operational__c = '123',
                Invoicing_Condition__c          = System.Label.InvoicingCondition_100BeginningOfService,
                recordtypeId                    = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId()
            );

            insert ATSContract;


            pItem=new  ProductItem__c (contract__c=ATSContract.Id,product__c=vProduct.id);
            insert pItem;

        }
    }

    // start test
    @isTest
    Public static void createAmendmentTest() {
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMOADV_USERNAME];    
        System.runAs(vUserPMO) {
            Test.startTest();

            Contract__c c = [SELECT Status__c, Id, Account_Manager__c, Account__c, C_Account__c, AXA_GO_Legal_Entity__c, AXA_GS_Signed_By__c,
                    Customer_Operational_Contact__c, CustomerSignedBy__c, EndDate__c, Global_Amount__c, Invoicing_Condition__c, Language__c,
                    OwnerId, RecordType.Name, Service_Started__c, ServiceType__c, InvoicingMethod__c, Amendment_to__c,
                    SOW_Operational__c, StartDate__c, CurrencyIsoCode, Name, Amendment_to__r.Name FROM Contract__c 
                    WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.ID][0];

            Test.setCurrentPageReference(Page.VFP07_ContractAmendment);
            VFC07_ContractAmendment controller = new VFC07_ContractAmendment(new ApexPages.StandardController(c));
            Contract__c amendment = controller.createAmendmentFromContract(c);
            System.assert(amendment != null);

            PageReference vPr = controller.createAmendment();
            System.assert(vPr != null);

            Test.stopTest();
        }
    }

    // start test
    @isTest
    Public static void createAmendmentTestContractEdit() {
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMOADV_USERNAME];
        System.runAs(vUserPMO) {
            Test.startTest();

            Contract__c c = [SELECT Status__c, Id, Account_Manager__c, Account__c, C_Account__c, AXA_GO_Legal_Entity__c, AXA_GS_Signed_By__c,
                    Customer_Operational_Contact__c, CustomerSignedBy__c, EndDate__c, Global_Amount__c, Invoicing_Condition__c, Language__c,
                    OwnerId, RecordType.Name, Service_Started__c, ServiceType__c, InvoicingMethod__c, Amendment_to__c,
                    SOW_Operational__c, StartDate__c, CurrencyIsoCode, Name, Amendment_to__r.Name FROM Contract__c 
                    WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/id=:vContract.Id][0];          

            Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');
            c.recordtypeId=vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
            update c;

            Test.setCurrentPageReference(Page.VFP07_ContractAmendment);
            VFC07_ContractAmendment controller = new VFC07_ContractAmendment(new ApexPages.StandardController(c));
            Contract__c amendment = controller.createAmendmentFromContract(c);
            System.assert(amendment != null);

            PageReference vPr = controller.createAmendment();
            System.assert(vPr != null);


            Test.stopTest();
        }
    }


    // start test
    @isTest
    Public static void  cloneContractTest() {
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMOADV_USERNAME];
        System.runAs(vUserPMO) {
            Test.startTest();

            Contract__c c = [SELECT Status__c,recordtypeId, Tech_RecordTypeName__c,Id, Account_Manager__c, Account__c, C_Account__c, AXA_GO_Legal_Entity__c, AXA_GS_Signed_By__c,
                    Customer_Operational_Contact__c, CustomerSignedBy__c, EndDate__c, Global_Amount__c, Invoicing_Condition__c, Language__c,
                    OwnerId, RecordType.Name, Service_Started__c, ServiceType__c, InvoicingMethod__c, Amendment_to__c,
                    SOW_Operational__c, StartDate__c, CurrencyIsoCode, Name, Amendment_to__r.Name 
                    FROM Contract__c 
                    WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];

            Test.setCurrentPageReference(Page.VFP07_ContractClone);

            VFC07_ContractClone controller = new VFC07_ContractClone(new ApexPages.StandardController(c));

            c.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            c.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            update(c);

            PageReference vClonedContract = controller.cloneContract();
            System.assert(vClonedContract == null);

            //Test : a contract can't be cloned if it's service type is Project
            c.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            c.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            update(c);

            vClonedContract = controller.cloneContract();
            //System.assert(vClonedContract != null);

            //Test : a contract can't be cloned if it's status is cancelled
            c.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            c.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            c.Decision_maker__c = 'Entity';
            c.Cancelled_reason__c = 'Product';
            update(c);
            c.Status__c = 'Cancelled';
            update(c);

            vClonedContract = controller.cloneContract();
            System.assert(vClonedContract == null);


            Test.stopTest();

            Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

            c.recordtypeId=vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
            update c;



            Test.setCurrentPageReference(Page.VFP07_ContractClone);

            VFC07_ContractClone controller_ATS = new VFC07_ContractClone(new ApexPages.StandardController(c));

            PageReference vClonedContract_ATS = controller_ATS.cloneContract();
            //vClonedContract_ATS = controller.cloneContract();

        }
    }

    @isTest
    Public static void  cloneATSContractTest() {
    User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMOADV_USERNAME];

    System.runAs(vUserPMO) {
        Test.startTest();

        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        Contract__c c = [SELECT recordtypeId,Tech_RecordTypeName__c,Status__c, Id, Account_Manager__c, Account__c, C_Account__c, AXA_GO_Legal_Entity__c, AXA_GS_Signed_By__c,
                Customer_Operational_Contact__c, CustomerSignedBy__c, EndDate__c, Global_Amount__c, Invoicing_Condition__c, Language__c,
                OwnerId, RecordType.Name, Service_Started__c, ServiceType__c, InvoicingMethod__c, Amendment_to__c,
                SOW_Operational__c, StartDate__c, CurrencyIsoCode, Name, Amendment_to__r.Name FROM Contract__c 
                where id=:ATSContract.Id
                /*WHERE Name =: 'ContractATS'*/][0];

        Product__c product = [select id from product__c where name=:'testProduct'][0];


        ProductItem__c pItem=new  ProductItem__c (contract__c=c.Id,product__c=product.id);
        insert pItem;


        Test.setCurrentPageReference(Page.VFP07_ContractClone);

        VFC07_ContractClone controller = new VFC07_ContractClone(new ApexPages.StandardController(c));

        PageReference vClonedContract = controller.cloneContract();
        //System.assert(vClonedContract == null);


        Test.stopTest();
        }
    }
}