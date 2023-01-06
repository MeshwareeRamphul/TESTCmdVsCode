/**
 * <b>Class VFC19_ILClone_Test </b>: unit class test for VFC19_ILClone / VFP19_ILClone
 * @author Eric Wartelle
 * @version 1.0
 */
@isTest
private class VFC19_ILClone_Test{

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
			// Create OO user
			User vUserOO = AP05_TestDataFactory.createOOUser();
			
			// Create PMO User
			User vUserPMO = AP05_TestDataFactory.createPMOUser();

			// Create PM user
			User vUserPM = AP05_TestDataFactory.createPMUser();

			// Create the customer (aka entity) account
			/*Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(adminUser);

			// Create the entity account
			Account vEAccount = AP05_TestDataFactory.createEntityAccount(adminUser);

			// Create the couple Entity - Billing Entity on Parent Entity
			vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

			// Create the entity contact related to the account
			Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);*/

			
			
			// Create the legal entity (aka billing entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

            // Create the entity account
            Account vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
			//Quartile (business area)
			/*Quartile__c vQuartile = AP05_TestDataFactory.createBusinessArea(vUserPM);

			//Petal (Domain)
			Petal__c vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserPM);

			// Offer
			Offer__c vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserPM);*/
			
			//Product
			Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
			
			//Contract
			Contract__c vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);   

			//Invoicing Line
			Invoicing_Line__c vInvoicingLine = AP05_TestDataFactory.createInvoicingLine(vContract, 'Invoicing_Line_To_Be_Cloned'); 	
		}	
	}

    /**
     * <b>Method mainTest </b>: main unit test 
     */
	@isTest
	static void mainTest()
	{
		//Getting the corresponding element
		User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
		Invoicing_Line__c vInvoicingLine = [SELECT Id FROM Invoicing_Line__c LIMIT 1];

		System.runAs(adminUser) {
            Test.startTest();  
    		ApexPages.StandardController stdController = new ApexPages.StandardController(vInvoicingLine);
    		VFC19_ILClone controller = new VFC19_ILClone(stdController);
    		try{
    			controller.cloneInvoicingLine();
    		} 
    		catch(Exception e){
    			
    		}
            Test.stopTest();
    	}
	}
}