@isTest
private class AP12_PDFContractsAttached_Test {
    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static User adminUser;
    static Contract__c vContract;
    static PDFContractAttached__c pdfContractAttached;

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

        System.runAs(adminUser) {
            User vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPM = AP05_TestDataFactory.createPMUser(true);
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            AccountModification_Flag__c accModifFlag = new AccountModification_Flag__c(SetupOwnerId=vUserPM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
            insert accModifFlag;

            vUserPM1 = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];
            vProduct1 = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];

            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(vUserPM1, AP05_TestDataFactory.ACCOUNT_NAME);
            vEntity1 = AP05_TestDataFactory.createEntityAccount(vUserPM1, 'testEntity');
            vMEntity1 = AP05_TestDataFactory.createMasterEntityAccount(vUserPM1, 'Master Entity');
            vLegalEntity1 = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLegalEntity1);

            pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Not updated!';
            insert pdfContractAttached;

           	vContract = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM1, vEntityContact1, 'Draft', false);
            vContract.PDFContrAtt__c = pdfContractAttached.id;         
            insert vContract;

            Planned_Invoicing_Line__c pil =  AP05_TestDataFactory.createIL(vContract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id); 
            insert pil;
        }
    }
    @isTest
    static void testStatusNotChanged(){
        System.runAs(adminUser) {

            Test.startTest();
				vEntityContact1.LastName = 'LastNameContact Entity Changed';
				vEntityContact1.Title ='TitleContact EntityCHANGED';
				update vEntityContact1;
            Test.stopTest();


            PDFContractAttached__c pdfContractAttachedGOT = [SELECT Id, CurrentValue__c, LastPDFValue__c, PDFStatus__c 
															FROM PDFContractAttached__c WHERE ID = :pdfContractAttached.ID];

            System.assertNotEquals('Updated', pdfContractAttachedGOT.PDFStatus__c);
    	}
    }
}