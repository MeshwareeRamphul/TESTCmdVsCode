@isTest
private class VFC13_SOWEditor_Test {
    static User vUserOO,vUserPMO,vUserPM,adminUser;
    static Account vAccount,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;

     
    static{
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
        
        system.runas(adminUser){
        // Create OO user
        vUserOO = AP05_TestDataFactory.createOOUser();

        // Create PMO User
        vUserPMO = AP05_TestDataFactory.createPMOUser();

        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser();

        // Create the customer (aka entity) account
        vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

        // Create the entity account
        vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

        // Create the couple Entity - Billing Entity on Parent Entity
        vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

        // Create the entity contact related to the account
        vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
        
        //Product
        vProduct = AP05_TestDataFactory.createProduct(vUserOO);
        
        //Contract
        vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);   
     }
    }
    
    
    static testMethod void saveSOWTest() {
        Contract__c vContract = [SELECT Id FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.id][0];
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
        System.runAs(vUserPMO) {
            
            Test.startTest();
            ApexPages.StandardController vStdController = new ApexPages.StandardController(vContract);
            
            VFC13_SOWEditor vController = new VFC13_SOWEditor(vStdController);
            vContract.SOW_Operational__c = 'test';
            vController.saveSow();
            
            Contract__c vContractRetrieved = [SELECT Id, SOW_Operational__c FROM Contract__c WHERE Id = :vContract.Id];
            System.assert(vContractRetrieved.SOW_Operational__c == 'test');
            
            
            Test.stopTest();
        
        }
    }
    
    /*static testMethod void saveSLATest() {
        Contract__c vContract = [SELECT Id FROM Contract__c WHERE id=:vContract.id][0];
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
        System.runAs(vUserPMO) {
            
            Test.startTest();
            ApexPages.StandardController vStdController = new ApexPages.StandardController(vContract);
            
            VFC13_SOWEditor vController = new VFC13_SOWEditor(vStdController);
            vContract.SLA__c = 'test';
            vController.saveSow();
            
            Contract__c vContractRetrieved = [SELECT Id, SLA__c FROM Contract__c WHERE Id = :vContract.Id];
            System.assert(vContractRetrieved.SLA__c == 'test');
            
            vController.saveSLA();
            Test.stopTest();
        
        }
    }*/
}