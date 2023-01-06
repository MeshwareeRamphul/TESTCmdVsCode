@isTest
public with sharing class VFC02_IdCard_Test {
	static User adminUser;

    static {
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
			//Create data for the tests methods

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
	static void getMainProduct_Test() {
		User vUserOO = [SELECT Id FROM USER WHERE UserName = 'userOO@test.com' LIMIT 1];

		// Get the offer
		Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];
		// Get the account
		Account vAccount = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ENTITY_NAME];

		System.runAs(vUserOO) {
			Test.startTest();
			Opportunity vOpty = new Opportunity();			
			vOpty.AccountId = vAccount.Id;
			vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
			vOpty.closeDate = Datetime.now().date();
			vOpty.Name = 'OptyTestMoveAXAGS';
			vOpty.OwnerId = vAccount.OwnerId;
			insert vOpty;

			// Engagement committee
			vOpty.Engagement_Committee_Lookup__r = new EngagementCommittee__c();
			vOpty.Engagement_Committee_Lookup__r.Opportunity__c = vOpty.Id;
			vOpty.Engagement_Committee_Lookup__r.Risks_Low__c = 'Risk1\nRisk2';
			vOpty.Engagement_Committee_Lookup__r.Total_cost__c = 33222;
			vOpty.Engagement_Committee_Lookup__r.Total_Revenue__c = 33223;
			//insert vOpty.Engagement_Committee_Lookup__r;

			// Product association
			//OpportunityProduct__c vOptyProduct = AP05_TestDataFactory.createOpportunityProductLink(vOpty, vProduct);

			//Opportunity vOptyRetrieved = [SELECT Id, Product__c, Engagement_Committee_Lookup__r.Total_Revenue__c,
			//								 Engagement_Committee_Lookup__r.Total_cost__c, Engagement_Committee_Lookup__r.Risks_Low__c,
			//								 Engagement_Committee_Lookup__r.Risks_Medium__c,
			//								 Engagement_Committee_Lookup__r.Risks_High__c FROM Opportunity WHERE ID = :vOpty.ID];
	

			ApexPages.StandardController vSC = new ApexPages.StandardController(vOpty);
			VFC02_IdCard vController = new VFC02_IdCard(vSC);

			System.assert(vController.getTotalCost() != null);
			System.assert(vController.getTotalRevenue() != null);
			Test.stopTest();
		}
	}
}