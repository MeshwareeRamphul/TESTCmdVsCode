/**
 * <b>Class VFC24_ILCreditNote_Test </b>: unit class test for VFC24_ILCreditNote
 * @author Urvashi Sadasing
 * @version 1.0
 */
@isTest
private class VFC24_ILCreditNote_Test
{
	static User adminUser;
	static User vUserPMOADV;
	static User vUserPMO;

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
        adminUser.PAD_BypassTrigger__c = 'AP25a;AP25;AP112;';
        adminUser.PAD_BypassValidationRules__c = true;
        insert adminUser;

		System.runAs(adminUser) {

	    	//Create datas for the tests methods
	    	vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

			// Create OO user
			User vUserOO = AP05_TestDataFactory.createOOUser();
			
			// Create PMO User
			vUserPMO = AP05_TestDataFactory.createPMOUser();

			// Create PM user
			User vUserPM = AP05_TestDataFactory.createPMUser();

			// Create the customer (aka entity) account
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
			Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer, */vUserOO);

			Master_WBS_Structure__c vMasterWBS = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', 'AXA Group Operations SAS', 'CSS', 'Digital', '2016', true);
	    	
			//Contract
			Contract__c vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);   
			vContract.Status__c = 'Ready for Signature';
			vContract.Master_WBS_2__c = vMasterWBS.Id; //'a0K1p00000T9dWG';
			Update vContract;

			//Invoicing Line
			Planned_Invoicing_Line__c vInvoicingLine = AP05_TestDataFactory.createIL(vContract, 100,'Cred_Note_to_Create', '04', System.Today(), System.Today().addMonths(4), vEntityContact.Id);
			//Planned_Invoicing_Line__c vInvoicingLine = AP05_TestDataFactory.createIL(vContract, 'Cred_Note_to_Create', '04'); 	
			insert vInvoicingLine;
		}
    }	

	@isTest
	static void chkRightsTrue()
	{
		Planned_Invoicing_Line__c vInvoicingLine = [SELECT Id, recordtype.name, TECH_GIE_SAS__c, Contract2__c, type__c, Status__c, AmountIL__c FROM Planned_Invoicing_Line__c LIMIT 1];

		System.runAs(vUserPMOADV) {
    		ApexPages.StandardController stdController = new ApexPages.StandardController(vInvoicingLine);
    		VFC24_ILCreditNote controller = new VFC24_ILCreditNote(stdController);
    		controller.standardController = null;
    		try{
    			controller.checkRights();
    		} 
    		catch(Exception e){
    			System.debug('#test vfc24 Exception : ' + e.getMessage());
    		}
    	}
	}

@isTest
	static void chkRightsFalse()
	{
		Planned_Invoicing_Line__c vInvoicingLine = [SELECT Id, recordtype.name, TECH_GIE_SAS__c, Contract2__c, type__c, Status__c, AmountIL__c FROM Planned_Invoicing_Line__c LIMIT 1];

		System.runAs(vUserPMO) {
    		ApexPages.StandardController stdController = new ApexPages.StandardController(vInvoicingLine);
    		VFC24_ILCreditNote controller = new VFC24_ILCreditNote(stdController);
    		controller.standardController = null;
    		try{
    			controller.checkRights();
    		} 
    		catch(Exception e){
    			System.debug('#test vfc24 Exception : ' + e.getMessage());
    		}
    	}
	}
}