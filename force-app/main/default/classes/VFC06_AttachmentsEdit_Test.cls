@isTest
private class VFC06_AttachmentsEdit_Test {
    
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
            // Create AM user
            User vUserAM = AP05_TestDataFactory.createAMUser();

            // Create the account related to the offer
            Account vAccount = AP05_TestDataFactory.createEntityAccount(vUserAM);
            
            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            // Create the entity contact related to the account
            User vAXAGSUser = AP05_TestDataFactory.createAXAGSUser(vAccount);
            
            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            // Attachment 
            Product_Attachment__c vProductAttachment = AP05_TestDataFactory.createProductAttachment(vProduct);
        }
    }


    @isTest
    static void back_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product_Attachment__c vProductAttachment = [SELECT Id, Attachment_Id__c, Product__c FROM Product_Attachment__c WHERE Name = :AP05_TestDataFactory.ATTACHMENT_NAME LIMIT 1];

        System.runAs(vUserOO) {
            Test.startTest();           
            
            ApexPages.StandardController  vStd = new ApexPages.StandardController(vProductAttachment);
            VFC06_AttachmentsEdit vController = new VFC06_AttachmentsEdit(vStd);
            System.assert(vController.back() != null);

            Test.stopTest();
        }
    }
    


    @isTest
    static void processUpload_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product_Attachment__c vProductAttachment = [SELECT Id, Attachment_Id__c, Product__c  FROM Product_Attachment__c WHERE Name = :AP05_TestDataFactory.ATTACHMENT_NAME LIMIT 1];

        System.runAs(vUserOO) {
            Test.startTest();           
            
            ApexPages.StandardController  vStd = new ApexPages.StandardController(vProductAttachment);
            VFC06_AttachmentsEdit vController = new VFC06_AttachmentsEdit(vStd);
            Blob vFileContent = Blob.valueOf('Test blob');
            vController.fileBody = vFileContent;

            System.assert(vController.processUpload() != null);

            Test.stopTest();
        }
    }

}