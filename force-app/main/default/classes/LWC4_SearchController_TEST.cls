@isTest
public with sharing class LWC4_SearchController_TEST {
 /* --------------------------------------------------------------------------------------
    -- - Name          : LWC4_SearchController_TEST
    -- - Author        : Spoon
    -- - Description   : Test class for LWC4_SearchController
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 05-JAN-2022  MBE    1.0     Initial version 
    --------------------------------------------------------------------------------------*/
    static User testUser;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Negotiation_Round__c> lstRound;
    static List<Bidder__c> lstParticipant;
    static Map<String, RecordType> mapSE = new Map<String, RecordType>();
	static Map<String, RecordType> mapRT = new Map<String, RecordType>();
	static Map<String, RecordType> mapContactRT = new Map<String, RecordType>();
    static String strInternalRole = 'Internal';

    static{      
        List<UserRole> lstRole = [SELECT Id, Name FROM UserRole WHERE Name = : strInternalRole];

      	testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);

        if(lstRole.size() > 0){
            testUser.UserRoleId = lstRole[0].Id;
        }
        
      	insert testUser;

        List<Profile> lstProfiles = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];
        
      	system.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');
            // Account
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Active__c = true;
            con1.Email = 'test1@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Active__c = true;
            con2.Email = 'test2@gmail.com';

			Contact con3 = TestFactory.createContact(lstAccount[0],'Jim','Brick');
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con3.Active__c = true;
            con3.Email = 'test3@gmail.com';

			Contact con4 = TestFactory.createContact(lstAccount[1],'Ken','Jeh');
            con4.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con4.Active__c = true;
            con4.Email = 'test4@gmail.com';

			Contact con5 = TestFactory.createContact(lstAccount[1],'Ken2','Jeh');
            con5.recordTypeId = mapContactRT.get('Entity_contact').Id;
            con5.Active__c = true;
            con5.Email = 'test5@gmail.com';

			Contact con6 = TestFactory.createContact(lstAccount[1],'Ken3','Jeh');
            con6.recordTypeId = mapContactRT.get('Entity_contact').Id;
            con6.Active__c = true;
            con6.Email = 'test6@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
			lstContact.add(con3);
			lstContact.add(con4);
			lstContact.add(con5);
			lstContact.add(con6);
            insert lstContact;

			//Sourcing Event RFI
			lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                )
            };
            insert lstSourcingEvent;

            //Negotiation Round
			lstRound = new List<Negotiation_Round__c>{
				new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'Preparation'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                )
            };
            insert lstRound;

			//Bidders
			lstParticipant = new List<Bidder__c>{
				new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                ),
				new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[2].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_AWARDEE,
                    Negotiation_Round__c = lstRound[1].Id
                )
            };
            insert lstParticipant;
        }
    }

    @isTest
    static void search_test(){
        System.runAs(testUser){
            test.startTest();
                List<String> lstFields = new List<String>{'Name', 'Round_Status__c'};
                List<sObject> lstResult = LWC4_SearchController.search('Negotiation_Round__c', 'Sourcing_Event__c', lstSourcingEvent[0].Id, lstFields, 'Preparation');
            test.stopTest();
            // System.assertEquals(1, lstResult.size());
        }
    }

    @isTest
    static void searchCurrentRound_test(){
        System.runAs(testUser){
            test.startTest();
            LWC4_SearchController.WrapperParameters wp = new LWC4_SearchController.WrapperParameters();
            wp.objectName = 'Negotiation_Round__c';
            wp.currentObject = 'Sourcing_Event__c';
            wp.currentRecordId = lstSourcingEvent[0].Id;
            wp.fields = new List<String>();
            String param = Json.serialize(wp);
            List<sObject> lstResult = LWC4_SearchController.searchWithCondition(param);
            //List<sObject> lstResult = LWC4_SearchController.searchCurrentRound(lstSourcingEvent[0].Id);
            test.stopTest();
            // System.assertEquals(1, lstResult.size());
        }
    }

    @isTest
    static void searchWithConditionBidderStatus_test(){
        System.runAs(testUser){
            test.startTest();
                List<String> lstFields = new List<String>{'Name', 'Bidder_Status__c'};
                List<String> lstConditions = new List<String>{'Bidder_Status__c', 'Negotiation_Round__c'};
                LWC4_SearchController.WrapperParameters wp = new LWC4_SearchController.WrapperParameters();
                wp.objectName = 'Bidder__c';
                wp.currentObject = 'Sourcing_Event__c';
                wp.selectedRound = lstRound[1].Id;
                wp.currentRecordId = lstSourcingEvent[1].Id;
                wp.searchTerm = AP_Constant.PARTICIPANT_STATUS_AWARDEE;
                wp.fields = lstFields;
                wp.conditions = lstConditions;
                String param = Json.serialize(wp);
                List<sObject> lstResult = LWC4_SearchController.searchWithCondition(param);
                //List<sObject> lstResult = LWC4_SearchController.searchWithCondition('Bidder__c', 'Sourcing_Event__c', lstRound[1].Id, lstSourcingEvent[1].Id, lstFields, AP_Constant.PARTICIPANT_STATUS_AWARDEE, lstConditions, null);
            test.stopTest();
        
            System.assertEquals(2, lstResult.size());
        }
    }

    @isTest
    static void searchWithConditionOther_test(){
        System.runAs(testUser){
            test.startTest();
                List<String> lstFields = new List<String>{'Name', 'Round_Status__c'};
                List<String> lstConditions = new List<String>{'Round_Status__c'};
                LWC4_SearchController.WrapperParameters wp = new LWC4_SearchController.WrapperParameters();
                wp.objectName = 'Negotiation_Round__c';
                wp.currentObject = 'Sourcing_Event__c';
                wp.selectedRound = lstRound[1].Id;
                wp.currentRecordId = lstSourcingEvent[0].Id;
                wp.searchTerm = 'Preparation';
                wp.fields = lstFields;
                wp.conditions = lstConditions;
                String param = Json.serialize(wp);
                List<sObject> lstResult = LWC4_SearchController.searchWithCondition(param);
            test.stopTest();
        
            System.assertEquals(1, lstResult.size());
        }
    }
    

    @isTest
    static void searchWithConditionContact_test(){
        System.runAs(testUser){
            test.startTest();
                List<String> lstFields = new List<String>{'Name', 'Email', 'AccountId', 'EntityName__c'};
                List<String> lstConditions = new List<String>{'Name','Email','Active__c','RecordTypeId'};
                List<String> rejectedEmails = new List<String>{lstContact[5].Email};
                LWC4_SearchController.WrapperParameters wp = new LWC4_SearchController.WrapperParameters();
                wp.objectName = 'Contact';
                wp.searchTerm = 'Ken';
                wp.fields = lstFields;
                wp.conditions = lstConditions;
                wp.rejectedEmails = rejectedEmails;
                String param = Json.serialize(wp);
                List<sObject> lstResult = LWC4_SearchController.searchWithCondition(param);
            test.stopTest();
        
            System.assertEquals(1, lstResult.size());
        }
    }
    

    @isTest
    static void searchWithConditionActivityCode_test(){
        System.runAs(testUser){
            test.startTest();
                List<String> lstFields = new List<String>{'Name','GIE_GO_SAS__c','Activity_Level_1__c','Activity_Level_2__c','Cost_center_description__c','Active__c'};
                List<String> lstConditions = new List<String>{'Id','Name','GIE_GO_SAS__c','Activity_Level_1__c','Activity_Level_2__c','Cost_center_description__c','Active__c'};
                Master_WBS_Structure__c vMasterWBS_2 = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', System.Label.Ctr_AXA_LE_SAS, 'CSS', 'Digital', '2022', true);
                vMasterWBS_2.Name = 'L21FS_GC_000121';
                vMasterWBS_2.Active__c = true;
                update vMasterWBS_2;

                LWC4_SearchController.WrapperParameters wp = new LWC4_SearchController.WrapperParameters();
                wp.objectName = 'Master_WBS_Structure__c';
                wp.searchTerm = 'MOSS';
                wp.axaGoLegalEntity = System.Label.Ctr_AXA_LE_SAS;
                wp.serviceType = 'BAU';
                wp.fields = lstFields;
                wp.conditions = lstConditions;
                String param = Json.serialize(wp);
                List<sObject> lstResult = LWC4_SearchController.searchWithCondition(param);
            test.stopTest();
        
            System.assertEquals(1, lstResult.size());
        }
    }
}