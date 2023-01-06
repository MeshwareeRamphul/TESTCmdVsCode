/**
 * <b>Class VFC20_ContractDelete_Test </b>: unit test class for VFC20_ContractDelete/VFP20_ContractDelete
 * @author Eric Wartelle
 * @version 1.0
 */
@istest
private class VFC20_ContractDelete_Test {
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

            // Create the legal entity (aka billing entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(adminUser);

            // Create the entity account
            Account vEAccount = AP05_TestDataFactory.createEntityAccount(adminUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
			// Create PMO User
			User vUserPMO = AP05_TestDataFactory.createPMOUser();
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
			Contract__c vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);   
        }
    }

    /**
     * <b>Main test method</b>
     */
    @istest
	static void ContractDelete() {
		//Getting the corresponding element
		User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
		Contract__c vContract = [SELECT Id, Account__c FROM Contract__c LIMIT 1];

    	System.runAs(vUserPMO) {
			Test.startTest();
    		ApexPages.StandardController stdController = new ApexPages.StandardController(vContract);
    		VFC20_ContractDelete controller = new VFC20_ContractDelete(stdController);
   			PageReference result = controller.deleteContract();
			controller.FillCodeCoverage();

			//
			System.assertEquals(result, null, 'The delete action failed');
			Test.stopTest();
    	}
	}
}