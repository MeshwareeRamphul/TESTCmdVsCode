@isTest
public without sharing class AP01_Sing_UptBidDueDtOnSourcing_TEST {
/*----------------------------------------------------------------------
-- - Name          : AP01_Sing_UptBidDueDtOnSourcing_TEST
-- - Author        : Spoon
-- - Description   : test class for AP01_Sing_UpdateBidDueDateOnSourcing
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 22-DEC-2021  HSO  1.0      Initial version 
-- 04-JAN-2022  MBE  1.1      Increse Coverage - launchParticipation_Test  
-------------------------------------------------------------------------*/
    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<Negotiation_Round__c> lstRound;

    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        
        System.runAs(testUser){
            Map<String, RecordType> mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            Map<String, RecordType> mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Account
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test1@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'test2@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            insert lstContact;


            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id
                )
            };
            insert lstSourcingEvent;

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
                    Round_Status__c = 'Preparation'
                )
            };

            insert lstRound;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS,
                    Negotiation_Round__c = lstRound[1].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SELECTED,
                    Negotiation_Round__c = lstRound[0].Id
                )
            };
            insert lstParticipant;

        }
    }

    @isTest
    static void updateBidDueDate_Test(){
        System.runAs(testUser){
            lstRound[0].Sing_Round_Bid_Due_Date__c = System.Today().addDays(20);
            lstRound[0].Round_Status__c = 'In Progress';
            
            Test.startTest();
                update lstRound[0];
            Test.stopTest();

            Sourcing_Event__c event = [SELECT Id, Bid_Due_Date__c FROM Sourcing_Event__c WHERE Id = :lstRound[0].Sourcing_Event__c];

            System.assertEquals( true, event != null);
            System.assertEquals( lstRound[0].Sing_Round_Bid_Due_Date__c, event.Bid_Due_Date__c);
        }
    }
    
    @isTest
    static void launchParticipation_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map<String, Object> mapResult = AP01_Sing_UpdateBidDueDateOnSourcing.launchParticipation(lstSourcingEvent[0].Id);
            Test.stopTest();

            String successResult = (String)mapResult.get('success');

            System.assertEquals(System.Label.AP01_ConfirmationEmailSent, successResult);
        }
    }

}