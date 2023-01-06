@isTest
private class VFC09_OpportunityPrePopulate_Test {
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
	static void redirectToOptyPopulated_Test() {
		User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
		// Get the offer
		Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
		// Get the account
		Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];

		System.runAs(vUserOO) {
			Test.startTest();

			ApexPages.StandardController vSC = new ApexPages.StandardController(new Opportunity());
			VFC09_OpportunityPrePopulate vController = new VFC09_OpportunityPrePopulate(vSC);

			PageReference vPr = vController.redirectToOptyPopulated();
			System.assert(vPr != null);

			Test.stopTest();
		}
	}

}