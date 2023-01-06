@isTest
private class VFC08_OpportunityDeletion_Test {
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
	static void deleteOpty() {
		User vUserOO = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OO_USERNAME LIMIT 1];
		// Get the offer
		Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
		// Get the account
		Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];

		System.runAs(vUserOO) {
			Test.startTest();

			Opportunity vOpty = AP05_TestDataFactory.createOpportunityStageCollect(vAccount, vProduct);
			ApexPages.StandardController vStd = new ApexPages.StandardController(vOpty);
			VFC08_OpportunityDeletion vController = new VFC08_OpportunityDeletion(vStd);
			vController.deleteTheRecord();

			// Check the opportunity has not been deleted
			List<Opportunity> vOptyReloaded = [SELECT Id FROM Opportunity WHERE Id=:vOpty.Id];
			System.assert(vOptyReloaded != null, 'Opportunity shouldnt have been deleted');

			Opportunity vOpty2 = AP05_TestDataFactory.createOpportunityStageCollect(vAccount, vProduct, 'OptyTest2');
			ApexPages.StandardController vStd2 = new ApexPages.StandardController(vOpty2);
			VFC08_OpportunityDeletion vController2 = new VFC08_OpportunityDeletion(vStd2);
			vController2.deleteTheRecord();

			// Check the opportunity has been deleted
			List<Opportunity> vOptyReloaded2 = [SELECT Id FROM Opportunity WHERE Id=:vOpty2.Id];
			System.assert(vOptyReloaded2.size() == 0, 'Opportunity should have been deleted : ' + vOptyReloaded2);

			Test.stopTest();
		}
	}

	
}