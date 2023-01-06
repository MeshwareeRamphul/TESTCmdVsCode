@isTest
public with sharing class AP11_OpportunityProduct_Test {

	
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
			
			//Product
			Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
		}
	}


	@isTest
	public static void addPOAsFollower_Test() {
		User vUserOptyOwner = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OPTYOWNER_USERNAME LIMIT 1];
		// Get the product
		Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
		// Get the account
		Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];

		System.runAs(vUserOptyOwner) {
			Test.startTest();
			new AP11_OpportunityProduct();
			/*// opty creation
			Opportunity vOpty = new Opportunity();
			vOpty.AccountId = vAccount.Id;
			vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
			vOpty.closeDate = Datetime.now().date();
			vOpty.Name = 'checkOnlyOneMainProduct';
			insert vOpty;

			String vException = null;

			// Product association
			OpportunityProduct__c vOptyProduct = AP05_TestDataFactory.createOpportunityProductLink(vOpty, vProduct);

			try {
				// 2nd main Product association
				OpportunityProduct__c vOptyProduct2 = AP05_TestDataFactory.createOpportunityProductLink(vOpty, vProduct);
			} catch (Exception e) {
				vException += e.getMessage();
			}

			List<EntitySubscription> vExistingSubscriptions = [SELECT ID, subscriberId, parentId FROM EntitySubscription WHERE parentID = :vOpty.Id LIMIT 20];
			System.assert(vExistingSubscriptions.size() == 3);*/
			Test.stopTest();
		}
	}

	 
}