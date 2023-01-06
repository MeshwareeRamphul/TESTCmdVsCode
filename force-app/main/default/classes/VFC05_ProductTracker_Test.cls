@isTest
private class VFC05_ProductTracker_Test {
	
	
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
		}
	}

	@isTest 
	static void initProductStages_Test() {
		User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];

		System.runAs(vUserOO) {
			Test.startTest();

			//Product
			Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
			
			ApexPages.StandardController vSC = new ApexPages.StandardController(vProduct);
			VFC05_ProductTracker vController = new VFC05_ProductTracker(vSC);

			System.assert(vController.getNumberOfStatus() != 0);

			//System.assert(vController.currentStageNumber == 1);

			Test.stopTest();
		}
	}

	@isTest 
	static void reorderProductStages_Test() {
		User vUserOO = [SELECT Id FROM USER WHERE UserName = 'userOO@test.com' LIMIT 1];

		System.runAs(vUserOO) {
			Test.startTest();

			//Product
			Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
			vProduct.Status__c = AP_Constant.PRODUCT_STATUS_STOPPED;
			
			ApexPages.StandardController vSC = new ApexPages.StandardController(vProduct);
			VFC05_ProductTracker vController = new VFC05_ProductTracker(vSC);

			System.assert(vController.getNumberOfStatus() != 0);

			//System.assertEquals(vController.currentStageNumber, vController.getNumberOfStatus());
			//System.assert(vController.getNumberOfStagesToDisplay() == vController.getNumberOfStatus());

			Test.stopTest();
		}
	}

	
}