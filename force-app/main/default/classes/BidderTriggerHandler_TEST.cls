@isTest
public class BidderTriggerHandler_TEST {
    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Contact> lstContact = new list<Contact>();
    static List<Account> lstAccount, lstAccount2;
    static List<Negotiation_Round__c> lstRound;
    static List<Bidder__c> lstParticipant;

    static {
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

            lstContact.add(con1);
            insert lstContact;

            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    //Legal_Entity__c = lstAccount2[0].Id,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = 'Published',
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
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS,
                    Negotiation_Round__c = lstRound[0].Id
                )
            };
            insert lstParticipant;
        }
    }

    @isTest static void RunBidderTriggerHandler_TEST() {
       //System.runAs(){
            Test.startTest();
            BidderTriggerHandler.afterUpdateHandler( new Map<ID, Bidder__c>(lstParticipant), new Map<ID, Bidder__c>(lstParticipant));
            Test.stopTest();  
        //}
    }
}