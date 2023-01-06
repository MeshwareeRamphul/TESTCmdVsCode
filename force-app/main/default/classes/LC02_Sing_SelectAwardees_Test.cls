@isTest
public class LC02_Sing_SelectAwardees_Test {

    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : LC02_Sing_SelectAwardees_Test
    -- - Author        : ARA
    -- - Description   : test class for LC02_Sing_SelectAwardees
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 04-JAN-2022  ARA    1.0     Initial version
    --------------------------------------------------------------------------------------*/
    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Sourcing_Event_Team__c> lstTeam;
    static List<Account> lstAccount, lstAccount2;
    static List<User> lstUser = new List<User>();
    static List<Contact> lstContact = new list<Contact>();
    static List<Negotiation_Round__c> lstRound;
    static Blob beforeblob;

    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        
        System.runAs(testUser){
            Map<String, RecordType> mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            Map<String, RecordType> mapContactRT = AP_Constant.getRecordTypes('Contact');

            //User
            lstUser.add(TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser3', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser4', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser5', UserInfo.getProfileId(), true));

            insert lstUser;

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
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id
                )
            };
            insert lstSourcingEvent;

            beforeblob = Blob.valueOf('Unit Test Attachment Body');
            ContentVersion cv = new ContentVersion();
            cv.title = 'test title trigger';      
            cv.PathOnClient = 'test';           
            cv.VersionData = beforeblob;
            cv.Sourcing_Event__c = lstSourcingEvent[0].id;
            insert cv;

            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = lstSourcingEvent[0].id;
            contentlink.ShareType = 'I';
            contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            contentlink.Visibility = 'AllUsers'; 
            insert contentlink;

            lstSourcingEvent[0].Documents_Uploaded__c  = 'Yes';
            update lstSourcingEvent;

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
                )
            };
            insert lstParticipant;

            lstTeam = new List<Sourcing_Event_Team__c>{
                new Sourcing_Event_Team__c(
                    Role__c = '001',
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Team_Member__c = testUser.Id
                    // Member_Group__c = 'AXA Partners Procurement',
                ),
                new Sourcing_Event_Team__c(
                    Role__c = '002',
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Team_Member__c = lstUser[2].Id,
                    Event_Access_Level__c = 'Read'
                ),
                new Sourcing_Event_Team__c(
                    Role__c = '002',
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Team_Member__c = lstUser[3].Id,
                    Event_Access_Level__c = 'Read'
                )
            };

            insert lstTeam;
        }
    }

    @isTest
    public static void testUpdToPendingSelection(){
        System.runAs(testUser){
            test.startTest();
            map<String,Object> mapOfResult = LC02_Sing_SelectAwardees.updToPendingSelection(lstRound[0].Id);
            test.stopTest();
            
            System.assertEquals(mapOfResult.get('sourcingEventId'), lstSourcingEvent[0].Id);
        }
    }
}