@isTest
private class VFC04_DistributorHome_TEST {
/*
----------------------------------------------------------------------
-- - Name          : VFC04_DistributorHome_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class of VFC04_DistributorHome
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 07-JULY-2014   MRA    1.0    Intitial version
-- 25-NOV-2014    YRA    1.1    Updated version
----------------------------------------------------------------------
**********************************************************************
*/

	static User testUserAdmin;
	static list <Account> accountList;
    static list<Opportunity> opportunityList;
	static DateTime StartTime,EndTime;
	static Account vAccount;
	
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
			vAccount = AP05_TestDataFactory.createEntityAccount(adminUser);

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
			
			//Produc
			Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
		}
	}

	
	static testMethod void test_DistributorHomeAdmin(){
		system.debug('## >>>Starting method test_DistributorHomeAdmin<<<< ');
		
		User vUserOptyOwner = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_OPTYOWNER_USERNAME LIMIT 1];
			system.runAs(vUserOptyOwner){
				
				Opportunity vOpty = new Opportunity();
				vOpty.AccountId = vAccount.Id;
				vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
				vOpty.closeDate = Datetime.now().date();
				vOpty.Name = 'OptyTestCheckFollowers';
				insert vOpty;
		
				// Custom setting data visibility
				Distributor_Home_Icons_Visibility__c vHomeIconsVis = new Distributor_Home_Icons_Visibility__c();
				vHomeIconsVis.Meetings_For_Today__c = true;
				vHomeIconsVis.NB_Opportunities__c = true;
				vHomeIconsVis.NB_OpportunitiesToApprove__c = true;
				insert vHomeIconsVis;

				test.startTest();
		 			System.debug('############# set VFP04 pageRef');
		 			PageReference pageRef = Page.VFP04_DistributorHome;
		 			Test.setCurrentPage(pageRef);
		 			System.debug('############# create VFP04 controller');
		 			
		 			VFC04_DistributorHome controller = new VFC04_DistributorHome();
		 			System.debug('############# before checkIcons visibility');
		 			//controller.checkIconsVisisbility();
		 			System.debug('############# before activate link');		 			
		 			//controller.activateLink();
		 		test.stopTest();		 		
			}
		system.debug('## >>>Ending method test_DistributorHomeAdmin<<<< ');
	}
}