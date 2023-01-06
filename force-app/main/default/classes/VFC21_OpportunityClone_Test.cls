@isTest
private class VFC21_OpportunityClone_Test {

	static Opportunity vOpportunity;
	static User        adminUser;

	static{
		/*adminUser = new User();
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
		adminUser.PAD_BypassValidationRules__c = true;*/
		adminUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true,AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert adminUser; 

        System.runAs(adminUser){
	    	//Create datas for the tests methods
			// Create OO user
			User vUserOO = AP05_TestDataFactory.createOOUser();
			
			// Create PMO User
			User vUserPMO = AP05_TestDataFactory.createPMOUser();

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
	    	
			//Opportunity
			vOpportunity = AP05_TestDataFactory.createOpportunityStageCollect(vEAccount,vProduct);
			vOpportunity.AXA_GO_Entity__c = 'AXA Group Operations France';
			vOpportunity.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Full Opportunity Contract Process - Read-Only').getRecordTypeId();			
			update vOpportunity;
		}
	}

	@isTest
    static void testCloneAction() {

    	System.runAs(adminUser) {
	        Test.startTest();      
	        
	        //Getting back the opportunity 
	        Opportunity o = [SELECT AccountId,Amount,Answer_cinematic__c,Answer_due_date__c,Answer_sent_date__c,Assigned_to_Email__c,
	        				Assigned_to_Name__c,Assigned_to__c,AXA_GS_alignment_date__c,AXA_GS_alignment__c,AXA_GO_Entity__c,Budget_asked__c,
	        				Budget_value__c,Business_Value__c,CampaignId,Category__c,Cinematic_format__c,CloseDate,Closed_lost_reason__c,
	        				Close_decision_maker__c,CreatedById,CreatedDate,CurrencyIsoCode,DB_Competitor__c,Description,End_users_type__c,
	        				Engagement_committee_agreement__c,Engagement_Committee_Lookup__c,Entity_alignment_date__c,Entity_alignment__c,
	        				Entity_AMO_Email__c,Entity_AMO__c,Entity_contact__c,Entity_sponsor__c,ExpectedRevenue,Fiscal,FiscalQuarter,
	        				FiscalYear,ForecastCategory,ForecastCategoryName,Funding__c,Go_live_date__c,HasOpenActivity,HasOpportunityLineItem,
	        				HasOverdueTask,Id,Impacted_Business_Area__c,IsClosed,IsDeleted,IsWon,LastActivityDate,LastModifiedById,LastModifiedDate,
	        				LastReferencedDate,LastViewedDate,Last_Open_Stage__c,LeadSource,Lost_comment__c,Lost_in_Stage__c,Name,NextStep,
	        				Opportunity_Context__c,Opportunity_Introducer__c,OwnerId,PM_answer_assignment_date__c,PM_works_on_the_answer__c,
	        				Pre_Sales_Effort_M_d__c,Pricebook2Id,Probability,Product_Owner_Email__c,Product_Owner__c,Product__c,Project_budget__c,
	        				Project_name__c,Project_start_Date__c,ProposalAmount__c,RecordTypeId,Scope__c,StageName,SyncedQuoteId,SystemModstamp,
	        				Type,User_To_Notify_Email__c
	        				FROM Opportunity
	        				WHERE Id = :vOpportunity.Id 
	        				//LIMIT 1
	        				];
	        
	        //Testing the controller        
	        Test.setCurrentPageReference(Page.VFP21_OpportunityClone); 
	        VFC21_OpportunityClone controller = new VFC21_OpportunityClone(new ApexPages.StandardController(o));
            PageReference result = controller.CloneAction();

            //Testing the result
            System.assertNotEquals(result, null, 'The action have failed.');

	        Test.stopTest();        
    	}
    }
}