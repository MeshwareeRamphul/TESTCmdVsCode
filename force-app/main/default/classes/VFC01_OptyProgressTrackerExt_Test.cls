@isTest
private class VFC01_OptyProgressTrackerExt_Test {
    
    static User adminUser;

    static {
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
        insert adminUser;
        
        System.runAs(adminUser) {
            //Create data for the tests methods

            // Create AM user
            User vUserAM = AP05_TestDataFactory.createAMUser();

            // Create the account related to the offer
            Account vAccount = AP05_TestDataFactory.createEntityAccount(adminUser);
            Account vLegalEntity = AP05_TestDataFactory.createLegalEntityAccount(adminUser);
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
        System.runAs(adminUser) {
            Test.startTest();
            ApexPages.StandardController vSC = new ApexPages.StandardController(new Opportunity());
            VFC01_OptyProgressTrackerExt vController = new VFC01_OptyProgressTrackerExt(vSC);
            for (Integer i = 0; i < VFC01_OptyProgressTrackerExt.optyStaticStagesList.size(); i++) {
                String vStageName = VFC01_OptyProgressTrackerExt.optyStaticStagesList[i].MasterLabel;
                System.assert(vController.getStageNumberByName(vStageName) == VFC01_OptyProgressTrackerExt.optyStaticStagesList[i].SortOrder);
            }
            Test.stopTest();
        }
    }

    @isTest 
    static void getNumberOfOptyStages_Test() {
        System.runAs(adminUser) {
            Test.startTest();
            ApexPages.StandardController vSC = new ApexPages.StandardController(new Opportunity());
            VFC01_OptyProgressTrackerExt vController = new VFC01_OptyProgressTrackerExt(vSC);        
            List<OpportunityStage> vOptyStagesList = [Select Id FROM OpportunityStage WHERE IsActive=true ORDER BY SortOrder ASC];
            System.assert(vController.getNumberOfOptyStages() == vOptyStagesList.size());
            Test.stopTest();
        }
    }

    /**
    * Check the stages have been removed from the last open stage to the close one
    */
    @isTest 
    static void checkStageLastOpenStage_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        vUserOO.PAD_BypassTrigger__c = 'AP03';
        vUserOO.PAD_BypassValidationRules__c = true;
        vUserOO.PAD_BypassWorkflows__c = false;
        update vUserOO;

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

            // Move directly to answer in progress thanks to by pass trigger
            vOpty.StageName = AP_Constant.STAGE_CONTRACTING;
            vOpty.Last_Open_Stage__c = AP_Constant.STAGE_CONTRACTING;
            //update vOpty;
            vOpty.StageName = AP_Constant.STAGE_LOST;
            //update vOpty;
            // Reload opportunity
            //vOpty = [SELECT Id, OwnerID, Last_Open_Stage__c, StageName, IsClosed, IsWon, RecordTypeId FROM Opportunity WHERE ID = :vOpty.Id];
            /*vOpty = [SELECT Id, OwnerID, Last_Open_Stage__c, StageName, IsClosed, IsWon, RecordTypeId FROM Opportunity LIMIT 1];

            ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);*/

            Test.stopTest();
        }
    }

    /**
    * Check the stakeholders functions
    */
    @isTest 
    static void checkStakeholders_Test() {
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
            VFC01_OptyProgressTrackerExt vController = new VFC01_OptyProgressTrackerExt(vSC);
    
            // Stakeholders
            System.assert(vController.getIsProductFilledIn() == false);
            System.assert(vController.getIsPOExists() == false);
            System.assert(vController.getIsAMOExists() == false);
            
            Test.stopTest();
        }
    }
    

    /**
    * Check the stages functions
    */
    @isTest 
    static void getUIStages_Test() {
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
            VFC01_OptyProgressTrackerExt vController = new VFC01_OptyProgressTrackerExt(vSC);

            vController.getLostStageSortOrder();
            vController.getWonStageSortOrder();


            System.assert(vController.getIsWon() == false);
            System.assert(vController.getIsWonToLostOpty() == false);
            System.assert(vController.getIsLost() == false);
            System.assert(vController.getIsClosed() == false);
            System.assertEquals(vController.getTooltip(), VFC01_OptyProgressTrackerExt.stagesMessages.get(AP_Constant.STAGE_LEADS_GATHERING));
            System.assert(vController.getNumberOfStagesToDisplay() == 5, vController.getNumberOfStagesToDisplay());
            
            vOpty.Entity_contact__c = vContact.Id;
            vController.moveToNextStage();
            ApexPages.currentPage().getParameters().put('pStage', AP_Constant.STAGE_LEADS_GATHERING);
            vController.goBackToStage(); 
            
            Test.stopTest();
        }
    }    
}