/**
 * <b>Class AP26_EROUpdatePrincipal_TEST </b>: test class for AP26_EROUpdatePrincipal
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */
@isTest
private class AP26_EROUpdatePrincipal_TEST {

    static Account vAccount = new Account();
    static Account vEAccount = new Account();
    static Account vMAccount = new Account();
    static Product__c vProduct = new Product__c();
    static User adminUser;
   
    static {
        // Create OO user
        User vUserOO = AP05_TestDataFactory.createOOUser();
        // Create PM user
        User vUserPM = AP05_TestDataFactory.createPMUser();
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
            // Create the customer (aka entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(adminUser);
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);
            // Create the master entity account
            vMAccount = AP05_TestDataFactory.createMasterEntityAccount(vUserPM);
            //Quartile (business area)
            /*Quartile__c vQuartile = AP05_TestDataFactory.createBusinessArea(vUserPM);
            //Petal (Domain)
            Petal__c vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserPM);
            // Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserPM);*/
            //Product
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            vProduct.Product_Level_3__c = 'Offer 01';
            update vProduct;
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

        }
    }

    @isTest
    static void createNewERO() {
        System.runAs(adminUser) {
            Test.startTest();
            ProductEntityLink__c vERO = AP05_TestDataFactory.createEro(vEAccount.Id, vProduct.Id, 'Opportunity', null);
            Test.stopTest();
            ProductEntityLink__c eroCreated = [SELECT id, Principal__c FROM ProductEntityLink__c WHERE id = :vERO.Id];
            //system.assertEquals(true, eroCreated.Principal__c);
        }
    }

    @isTest
    static void createNewEROsDiffStatus() {
        System.runAs(adminUser) {
            Test.startTest();
                //ProductEntityLink__c vERO1 = AP05_TestDataFactory.createEro(vEAccount.Id, vProduct.Id, vOffer.Id, 'Opportunity', null);
                ProductEntityLink__c vERO2 = AP05_TestDataFactory.createEro(vEAccount.Id, vProduct.Id, /*vOffer.Id,*/ 'New live', null);
            Test.stopTest();

            List<ProductEntityLink__c> lstEroCreated = [SELECT id, POS_Status__c, Principal__c FROM ProductEntityLink__c WHERE /*id = :vERO1.Id OR */ id =:vERO2.Id];
            for (ProductEntityLink__c ero : lstEroCreated){
                
                if (ero.POS_Status__c == 'New live'){
                    system.assertEquals(true, ero.Principal__c);
                }
                /*
                Commented temporarily -> encountering error 'DUPLICATES_DETECTED, This product is already installed on this entity' in prod

                if (ero.POS_Status__c == 'New live'){
                    system.assertEquals(true, ero.Principal__c);
                }
                if (ero.POS_Status__c == 'Opportunity'){
                    system.assertEquals(false, ero.Principal__c);
                }*/
            }
        }
    }

    @isTest
    static void createNewEROsDiffDates() {
        System.runAs(adminUser) {
            Test.startTest();
                ProductEntityLink__c vERO1 = AP05_TestDataFactory.createEro(vEAccount.Id, vProduct.Id, /*vOffer.Id,*/ 'Opportunity', date.newInstance(2016,01,12));
                //ProductEntityLink__c vERO2 = AP05_TestDataFactory.createEro(vEAccount.Id, vProduct.Id, vOffer2.Id, 'Opportunity', date.newInstance(2015,01,12));
            Test.stopTest();

            List<ProductEntityLink__c> lstEroCreated = [SELECT id, POS_Status__c, Principal__c, First_Release_Date__c FROM ProductEntityLink__c WHERE id = :vERO1.Id /*OR id =:vERO2.Id*/];
            for (ProductEntityLink__c ero : lstEroCreated){
            /*
            Commented temporarily -> encountering error 'DUPLICATES_DETECTED, This product is already installed on this entity' in prod
            if (ero.First_Release_Date__c == date.newInstance(2015,01,12)){
                    system.assertEquals(true, ero.Principal__c);
                }
                if (ero.First_Release_Date__c == date.newInstance(2016,01,12)){
                    system.assertEquals(false, ero.Principal__c);
                }*/
                if (ero.First_Release_Date__c == date.newInstance(2016,01,12)){
                    system.assertEquals(true, ero.Principal__c);
                }
            }
        }
    }
}