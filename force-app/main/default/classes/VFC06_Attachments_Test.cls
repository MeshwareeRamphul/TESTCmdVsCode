/***
* Test class for VFC06_* classes
*/
@isTest
private class VFC06_Attachments_Test {

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
        }
    }

    @isTest
    static void saveCustomAttachment_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
        System.runAs(vUserOO) {
            Test.startTest();           

            ApexPages.StandardController vStd = new ApexPages.StandardController(vProduct);
            VFC06_Attachments vController = new VFC06_Attachments(vStd);
            vController.attachmentName = 'test';
            vController.deliverable = '';
            Database.SaveResult vAttachmentResult = vController.saveCustomAttachment();

            System.assert(vAttachmentResult != null && vAttachmentResult.isSuccess());

            Test.stopTest();
        }
    }

    @isTest
    static void saveStandardAttachment_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
        System.runAs(vUserOO) {
            Test.startTest();       

            ApexPages.StandardController vStd = new ApexPages.StandardController(vProduct);
            VFC06_Attachments vController = new VFC06_Attachments(vStd);
            Blob vFileContent = Blob.valueOf('Test in progress');
            vController.fileBody = vFileContent;
            vController.fileName = 'Test in progress attachmentName';

            Database.SaveResult vAttachmentResult = vController.saveStandardAttachment(vProduct.Id);
            System.assert(vAttachmentResult != null && vAttachmentResult.isSuccess());

            Test.stopTest();
        }   
    }


    @isTest
    static void getDeliverables_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
        System.runAs(vUserOO) {
            Test.startTest();           
            
            ApexPages.StandardController vStd = new ApexPages.StandardController(vProduct);
            VFC06_Attachments vController = new VFC06_Attachments(vStd);
            System.assert(vController.getDeliverables() != null);

            Test.stopTest();
        }
    }

    @isTest
    static void back_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
        System.runAs(vUserOO) {
            Test.startTest();           
            
            ApexPages.StandardController vStd = new ApexPages.StandardController(vProduct);
            VFC06_Attachments vController = new VFC06_Attachments(vStd);
            System.assert(vController.back() != null);

            Test.stopTest();
        }
    }

    @isTest
    static void processUpload_test() {
        User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
        Product__c vProduct = [SELECT Id FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME LIMIT 1];
        System.runAs(vUserOO) {
            Test.startTest();           
            
            ApexPages.StandardController vStd = new ApexPages.StandardController(vProduct);
            VFC06_Attachments vController = new VFC06_Attachments(vStd);
            vController.deliverable = 'Test';
            Blob vFileContent = Blob.valueOf('Test in progress');
            vController.fileBody = vFileContent;
            vController.fileName = 'Test in progress attachmentName';

            System.assert(vController.processUpload() != null);

            // Errors
            vController.deliverable = System.Label.ProductAttach_Other;
            vController.attachmentName = null;
            System.Assert(vController.processUpload() == null);
            vController.deliverable = 'Test';

            vController.deliverable = null; 
            System.assert(vController.processUpload() == null);
            vController.deliverable = 'Test';

            // test error on save standard attachment
            vController.fileBody = null;
            vController.fileName = null;
            System.Assert(vController.processUpload() == null);

            Test.stopTest();
        }
    }
}