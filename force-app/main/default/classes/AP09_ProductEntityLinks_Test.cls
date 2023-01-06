@isTest
private class AP09_ProductEntityLinks_Test {
    
    static User adminUser;

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
        insert adminUser;

		System.runAs(adminUser) {
            // Create the account related to the offer
            Account vAccount = AP05_TestDataFactory.createEntityAccount(adminUser);

            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            // Create the entity contact related to the account
            User vAXAGSUser = AP05_TestDataFactory.createAXAGSUser(vAccount);

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();

            // Create MO user
            User vUserMO = AP05_TestDataFactory.createMOUser();

            // Create Opty owner user
            User vUserOptyUser = AP05_TestDataFactory.createOptyOwnerUser();
            
            //Produc
            Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
        }
    }


    @isTest
    static void fillAntiDuplicateField_Test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Account vAccount = [SELECT Id FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
       
        System.runAs(adminUser) {
            Test.startTest();

            ProductEntityLink__c vLink = new ProductEntityLink__c();
            vLink.Entity__c = vAccount.Id;
            vLink.Product__c = vProduct.Id;
            vLink.First_Release_Date__c = Date.today();
            vLink.Last_Release_Date__c = Date.today();
            vLink.Percent_Deployed__c = 0.5;
            vLink.POS_Status__c = 'Planned';
            insert vLink;

            //ProductEntityLink__c vLinkRetrieved = [SELECT Id,TECH_Anti_Duplicate_Value__c,Product__c, Entity__c FROM ProductEntityLink__c WHERE ID  = :vLink.Id LIMIT 1];
            ProductEntityLink__c vLinkRetrieved = [SELECT Id,TECH_Anti_Duplicate_Value__c, Product__c , Entity__c FROM ProductEntityLink__c WHERE ID  = :vLink.Id LIMIT 1];

            //System.assert(vLinkRetrieved.TECH_Anti_Duplicate_Value__c == (vLinkRetrieved.Product__c + '_' + vLinkRetrieved.Offer__c + '_' + vLinkRetrieved.Entity__c), ' Value of field : ' + vLinkRetrieved.TECH_Anti_Duplicate_Value__c);
			
			ProductEntityLink__c vLink2 = new ProductEntityLink__c();
            vLink2.Entity__c = vAccount.Id;
            vLink2.Product__c = null;
            vLink2.First_Release_Date__c = Date.today().addDays(-5);
            vLink2.Last_Release_Date__c = Date.today();
            vLink2.Percent_Deployed__c = 0.5;
            //vLink2.POS_Status__c = 'Opportunity';
            vLink.Is_Partial__c = false;
            insert vLink2;
			
			/*vLink2.POS_Status__c = 'Planned';
			update vLink2;
			
			vLink2.POS_Status__c = 'Live';
			update vLink2;*/
			
            Test.stopTest();
        }
    }

}