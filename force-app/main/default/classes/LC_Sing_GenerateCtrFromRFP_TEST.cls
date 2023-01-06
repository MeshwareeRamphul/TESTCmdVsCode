@isTest
public without sharing class LC_Sing_GenerateCtrFromRFP_TEST {
/*----------------------------------------------------------------------
-- - Name          : LC_Sing_GenerateCtrFromRFP_TEST
-- - Author        : Spoon
-- - Description   : test class for LC_Sing_GenerateCtrFromRFP
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 24-DEC-2021  HSO  1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUser, testUser2;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<User> lstUser = new List<User>();
    static List<Sourcing_Event_Team__c> lstTeam;
    static Map<String, RecordType> mapSE;
    static Map<String, RecordType> mapRT;
	static Map<String, RecordType> mapContactRT;

    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Bypass_FieldFilter__c = true;
        insert testUser;

        testUser2 = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser2;

        System.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            //User
            lstUser.add(TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser3', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser4', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser5', UserInfo.getProfileId(), true));

            insert lstUser;
            for(User user : lstUser){
                user.cTin_Universign__c = true;
            }
            update lstUser;
            
            // Account
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Parent_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            //con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test1@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            //con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'test2@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            insert lstContact;

            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    OwnerId = testUser.Id,
                    Description__c = 'test event 777',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    BusinessOwner__c = lstUser[4].Id,
                    SharingLogic__c = 'Restrict access to my sourcing team',
                    APC_Level_0__c = '2-IT',
                   // APC_Level_1__c = '28 - Premises',
                    //APC_Level_2__c = '000-Core Migration Process',
                    //APC_Level_3__c = '010101 - Network & Telecom Incl. Telephony Software',
                    ContractAlreadyGenerated__c = true,
                    Sing_Beneficiary_entities__c = '1610 - AXA UK'

                ),
                new Sourcing_Event__c(
                    OwnerId = lstUser[2].Id,
                    Description__c = 'test event 778',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    BusinessOwner__c = lstUser[3].Id,
                    SharingLogic__c = 'Restrict access to my sourcing team'
                ),
                new Sourcing_Event__c(
                    OwnerId = lstUser[2].Id,
                    Description__c = 'test event 779',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    BusinessOwner__c = lstUser[3].Id,
                    SharingLogic__c = 'Restrict access to my entity'
                )

            };

            insert lstSourcingEvent;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_AWARDEE
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS
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
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Team_Member__c = lstUser[2].Id,
                    Event_Access_Level__c = 'Read'
                )
                
            };

            insert lstTeam;

        }
    }

    @isTest
    static void validateDisplay_AdminUser_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map<String, Object> mapResult = LC_Sing_GenerateCtrFromRFP.validateDisplay(lstSourcingEvent[0].Id);
            Test.stopTest();

            System.assert(mapResult.keySet().contains('show'));
        }
    }

    @isTest
    static void validateDisplay_SimpleUser_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map<String, Object> mapResult = LC_Sing_GenerateCtrFromRFP.validateDisplay(lstSourcingEvent[1].Id);
            Test.stopTest();

            System.assert(mapResult.keySet().contains('hide'));
        }
    }

    @isTest
    static void generateCtr_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map<String, Object> mapResult = LC_Sing_GenerateCtrFromRFP.generateCtr(lstSourcingEvent[0].Id);
            Test.stopTest();

            System.assert(mapResult.keySet().contains('success'));
        }
    }

    @isTest
    static void generateCtr_NoBidderAwardee_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map<String, Object> mapResult = LC_Sing_GenerateCtrFromRFP.generateCtr(lstSourcingEvent[1].Id);
            Test.stopTest();

            System.assert(mapResult.keySet().contains('error'));
        }
    }

    @isTest
    static void generateCtr_Catch_Test(){
        System.runAs(testUser2){
            Test.startTest();
                Map<String, Object> mapResult = LC_Sing_GenerateCtrFromRFP.generateCtr(lstSourcingEvent[0].Id);
            Test.stopTest();
            
            System.assert(mapResult.keySet().contains('error'));
        }
    }



}