@isTest
public with sharing class LC_TimeCounter_TEST {
/*----------------------------------------------------------------------
-- - Name          : LC_TimeCounter_TEST
-- - Author        : Spoon
-- - Description   : Test Class for LC_TimeCounter
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 24-DEC-2021  MBE   1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUser;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Negotiation_Round__c> lstRound;
    static List<Bidder__c> lstParticipant;
    static Map<String, RecordType> mapSE = new Map<String, RecordType>();
	static Map<String, RecordType> mapRT = new Map<String, RecordType>();
	static Map<String, RecordType> mapContactRT = new Map<String, RecordType>();

    static{ 
        testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);
        insert testUser;
        
        system.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Account
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Parent_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test1@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'test2@gmail.com';

            Contact con3 = TestFactory.createContact(lstAccount[0],'Jim','Brick');
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con3.Email = 'test3@gmail.com';

            Contact con4 = TestFactory.createContact(lstAccount[1],'Ken','Jeh');
            con4.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con4.Email = 'test4@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            lstContact.add(con4);
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
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
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
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[2].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[2].Id
                )
            };
            insert lstParticipant;
        }
    }  

    static testmethod void defaultRemainingTimeRound_Test(){
        system.runAs(testUser){
            test.startTest();
                DateTime dte = LC_TimeCounter.defaultRemainingTime(lstRound[0].Id);
            test.stopTest();

            System.assertEquals(System.Today().addMonths(2), dte);
        }
    }

    static testmethod void defaultRemainingTimeBidder_Test(){
        system.runAs(testUser){
            test.startTest();
                DateTime dte = LC_TimeCounter.defaultRemainingTime(lstParticipant[5].Id);
            test.stopTest();

            System.assertEquals(System.Today().addMonths(2), dte);
        }
    }

    static testmethod void defaultRemainingTimeSourcingEvent_Test(){
        system.runAs(testUser){
            test.startTest();
                DateTime dte = LC_TimeCounter.defaultRemainingTime(lstSourcingEvent[0].Id);
            test.stopTest();

            System.assertEquals(System.Today().addDays(5), dte);
        }
    }
}