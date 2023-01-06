@isTest
public with sharing class LC02_Sing_ConfirmFinalAwardee_TEST {
/*----------------------------------------------------------------------
-- - Name          : LC02_Sing_ConfirmFinalAwardee_TEST
-- - Author        : Spoon
-- - Description   : Test Class for LC02_Sing_ConfirmFinalAwardee
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
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Supplier').id);
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
                    Description__c = 'test event 01',
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
                    Description__c = 'test event 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event 03',
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
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_AWARDEE,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_AWARDEE,
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

    static testmethod void retrieveLastRound_Test(){
        system.runAs(testUser){
            test.startTest();
                List<Negotiation_Round__c> lstRound = LC02_Sing_ConfirmFinalAwardee.retrieveLastRound(lstSourcingEvent[0].Id);
            test.stopTest();

            //System.assertEquals(1, lstRound.size());
        }
    }

    static testmethod void sourcingEventIdParticipant_Test(){
        system.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LC02_Sing_ConfirmFinalAwardee.sourcingEventId(lstSourcingEvent[0].Id);
            test.stopTest();

            List<Bidder__c> lstParticipant = (List<Bidder__c>) mapResult.get('lst');
            //System.assertEquals(2, lstParticipant.size());
        }
    }

    static testmethod void sourcingEventIdNoParticipant_Test(){
        system.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LC02_Sing_ConfirmFinalAwardee.sourcingEventId(lstSourcingEvent[1].Id);
            test.stopTest();

            //String result = (String)mapResult.get('lst');
            //System.assertEquals('No participants availalble for selection', result);
        }
    }

    static testmethod void sourcingEventIdNoRound_Test(){
        system.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LC02_Sing_ConfirmFinalAwardee.sourcingEventId(lstSourcingEvent[2].Id);
            test.stopTest();

            String result = (String)mapResult.get('lst');
            //System.assertEquals('No active rounds available', result);
        }
    }

    static testmethod void updteParticipantlst_Test(){
        system.runAs(testUser){
            test.startTest();
                List<Id> lstParticipantId = new List<Id>{lstParticipant[0].Id, lstParticipant[2].Id, lstParticipant[5].Id};
                List<Bidder__c> lstParticipant = new List<Bidder__c>{lstParticipant[0], lstParticipant[2], lstParticipant[5]};

                Map<String, Object> mapResult = LC02_Sing_ConfirmFinalAwardee.updteParticipantlst(lstSourcingEvent[0].Id, lstParticipantId, lstParticipant);
            test.stopTest();
                
               
            //for(Bidder__c bidder : [SELECT Id, Bidder_Status__c FROM Bidder__c WHERE Id = :lstParticipant[2].Id]){
                //System.assertEquals(AP_Constant.PARTICIPANT_STATUS_AWARDEE, bidder.Bidder_Status__c);
            //}

            String proceedResult = (String)mapResult.get('proceeed');
            //System.assertEquals('true', proceedResult);

            String successResult = (String)mapResult.get('success');
            //System.assertEquals('Your changes have been saved', successResult);
        }
        }
        
        static testmethod void testFeedItemTrigger(){
             system.runAs(testUser){
             test.startTest();
                 Sourcing_Event__c src=new Sourcing_Event__c(
                    Description__c = 'test event 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id);
                 insert src;
                   
                 Bidder__c bidder=new Bidder__c(
                            Sourcing_Event__c = src.Id,
                            Contact_Bidder__c = lstContact[3].id,
                            Sing_Account__c = lstAccount[1].id,
                            Bidder_Status__c = 'Participation in Progress');
     
                insert bidder;
                
                FeedItem f = new FeedItem();
                f.Body = 'legal test';
                f.parentID = src.Id;
                insert f;
            test.stopTest();
            }
        }
    
}