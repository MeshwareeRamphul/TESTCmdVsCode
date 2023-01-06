@isTest
private class VFC11_OpportunityButtons_Test {
    Static User testUser;
    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;

        System.runAs(testUser){
            //Create data for the tests methods

            // Create AM user
            User vUserAM = AP05_TestDataFactory.createAMUser();

            // Create the account related to the offer
            Account vAccount = AP05_TestDataFactory.createEntityAccount(vUserAM);
            Account vLegalEntity = AP05_TestDataFactory.createLegalEntityAccount(vUserAM);
            vLegalEntity = AP05_TestDataFactory.linkLEgalEntityToEntity(vAccount, vLegalEntity);

            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            // Create the entity contact related to the account
            User vAXAGSUser = AP05_TestDataFactory.createAXAGSUser(vAccount);

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
        }
    }

    @isTest 
    static void getStageNumberByName_Test() {
        ApexPages.StandardController vSC = new ApexPages.StandardController(new Opportunity());
        VFC01_OptyProgressTrackerExt vController = new VFC01_OptyProgressTrackerExt(vSC);
        for (Integer i = 0; i < VFC01_OptyProgressTrackerExt.optyStaticStagesList.size(); i++) {
            String vStageName = VFC01_OptyProgressTrackerExt.optyStaticStagesList[i].MasterLabel;
            System.assert(vController.getStageNumberByName(vStageName) == VFC01_OptyProgressTrackerExt.optyStaticStagesList[i].SortOrder);
        }
    }
    
    //Contract genereation
    @isTest 
    static void generateContracts_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        vUserOO.PAD_BypassTrigger__c = 'AP03;AP02;AP12';
        vUserOO.PAD_BypassValidationRules__c = true;
        vUserOO.PAD_BypassWorkflows__c = false;
        update vUserOO;


        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
        // Get the account
        Account vAccount = [SELECT Id, OwnerID, GIE_AXA_GS_Member__c FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];
        // Get the Billing Entity
        Account vLegalEntity = [SELECT Id, ParentId, OwnerID, GIE_AXA_GS_Member__c FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];
        // Get the contact
        //Contact vContact = [SELECT Id, OwnerID FROM Contact WHERE LastName = :AP05_TestDataFactory.CONTACT_ENTITY_LAST_NAME];
        Contact vContact = [SELECT Id, OwnerID FROM Contact LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Opportunity vOpty = new Opportunity();      
            vOpty.Product__c = vProduct.Id; 
            vOpty.AccountId = vAccount.Id;
            vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpty.closeDate = Datetime.now().date();
            vOpty.Name = 'OptyTestMoveAXAGS';
            vOpty.OwnerId = vAccount.OwnerId;
            insert vOpty;

            // Reload opportunity
            //vOpty = [SELECT Id, Account.Name, OwnerID, Last_Open_Stage__c, StageName, IsClosed, IsWon, AccountId, Account.AGS_Contract_Region__c, CurrencyIsoCode FROM Opportunity LIMIT 1];

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);
            VFC11_OpportunityButtons vController = new VFC11_OpportunityButtons(vSC);
            vController.winOpty(); // MOVE TO WIN
 
            vLegalEntity = AP05_TestDataFactory.linkLEgalEntityToEntity(vAccount, vLegalEntity);
            
            String vResult = VFC11_OpportunityButtons.createContracts(vOpty.Id, null);
            //String vResult = null;

            List<Contract__c> vGeneratedContracts = [SELECT Id FROM Contract__c WHERE Opportunity__c = :vOpty.Id];
            System.assert(vGeneratedContracts != null && vResult == null);

            Test.stopTest();
        }
    }
    
    // Check the stages functions
    @isTest 
    static void checkcontracts() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];

        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
        // Get the account
        Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];
        // Get the contact
        Contact vContact = [SELECT Id, OwnerID FROM Contact WHERE LastName = :AP05_TestDataFactory.CONTACT_ENTITY_LAST_NAME];

        System.runAs(vUserOO) {
            Test.startTest();
            Opportunity vOpty = new Opportunity();          
            vOpty.AccountId = vAccount.Id;
            vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpty.closeDate = Datetime.now().date();
            vOpty.Name = 'OptyTestMoveAXAGS';
            vOpty.OwnerId = vAccount.OwnerId;
            insert vOpty;

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty); 

            Boolean vIsThereContract = VFC11_OpportunityButtons.checkThereIsAContract(vOpty.Id);
            //Boolean vIsThereContract = false;
            System.assert(vIsThereContract == false);

            Test.stopTest();
        }
    }
    
    // Check the stages functions
    @isTest 
    static void getUIStagesLost_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];

        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
        // Get the account
        Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];
        // Get the contact
        Contact vContact = [SELECT Id, OwnerID FROM Contact WHERE LastName = :AP05_TestDataFactory.CONTACT_ENTITY_LAST_NAME];

        System.runAs(vUserOO) {
            Test.startTest();
            Opportunity vOpty = new Opportunity();          
            vOpty.AccountId = vAccount.Id;
            vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpty.closeDate = Datetime.now().date();
            vOpty.Name = 'OptyTestMoveAXAGS';
            vOpty.OwnerId = vAccount.OwnerId;
            vOpty.Amount = 2342;
            insert vOpty;

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);
            VFC11_OpportunityButtons vController = new VFC11_OpportunityButtons(vSC);

            System.assert(vController.getIsWon() == false);
            System.assert(vController.getIsClosed() == false); 
            System.assert(vController.getIsOpenAndAfterAlign() == false); //A revérifier
            
            vOpty.Entity_contact__c = vContact.Id; 
            
           // System.assert(vOpty.StageName == AP_Constant.STAGE_LEADS_GATHERING, vOpty.StageName);
            
            vOpty.Close_decision_maker__c = 'Entity';
            vOpty.Closed_lost_reason__c = 'Price';
            vController.closeOpty();
           // System.assert(vOpty.StageName == AP_Constant.STAGE_LOST, vOpty.StageName);

            Test.stopTest();
        }
    }

    @isTest 
    static void getUIStagesQualifyAlignContracting_BAU_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];

        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
        // Get the account
        Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];
        // Get the contact
        Contact vContact = [SELECT Id, OwnerID FROM Contact WHERE LastName = :AP05_TestDataFactory.CONTACT_ENTITY_LAST_NAME];

        System.runAs(vUserOO) {
            Test.startTest();
            Opportunity vOpty = new Opportunity();          
            vOpty.AccountId = vAccount.Id;
            vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpty.closeDate = Datetime.now().date();
            vOpty.Name = 'OptyTestMoveAXAGS';
            vOpty.OwnerId = vAccount.OwnerId;
            vOpty.Amount = 2342;
            insert vOpty;

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);
            VFC11_OpportunityButtons vController = new VFC11_OpportunityButtons(vSC);

            vOpty.Entity_contact__c = vContact.Id; 
            
            System.assert(vOpty.StageName == AP_Constant.STAGE_LEADS_GATHERING, vOpty.StageName);

            vOpty.Category__c = 'BAU';
            vOpty.Answer_due_date__c = System.today();
            vOpty.Product__c = vProduct.Id;
            
            vController.qualifyAlignOpty(); 
            
            vOpty.Answer_sent_date__c = System.today();
            vOpty.Answer_cinematic__c = 'SOW';
            vOpty.Project_start_Date__c = System.today();
            vOpty.Go_live_date__c = System.today();

            vController.contractingOpty(); 
            
            Test.stopTest();
        }
    }

    @isTest 
    static void cancelOpty_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];

        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
        // Get the account
        Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];
        // Get the contact
        Contact vContact = [SELECT Id, OwnerID FROM Contact WHERE LastName = :AP05_TestDataFactory.CONTACT_ENTITY_LAST_NAME];

        System.runAs(vUserOO) {
            Test.startTest();
            Opportunity vOpty = new Opportunity();          
            vOpty.AccountId = vAccount.Id;
            vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpty.closeDate = Datetime.now().date();
            vOpty.Name = 'OptyTestMoveAXAGS';
            vOpty.OwnerId = vAccount.OwnerId;
            vOpty.Amount = 2342;
            vOpty.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppContract).getRecordTypeId();
            insert vOpty;

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);
            VFC11_OpportunityButtons vController = new VFC11_OpportunityButtons(vSC);

            System.assert(vController.getIsWon() == false);
            System.assert(vController.getIsClosed() == false); 
            System.assert(vController.getIsOpenAndAfterAlign() == false);
 
            vOpty.Entity_contact__c = vContact.Id; 
            
            vOpty.Close_decision_maker__c = 'Entity';
            vOpty.Closed_lost_reason__c = 'Price';

            vController.cancelOpty();

            Test.stopTest();
        }
    }

}