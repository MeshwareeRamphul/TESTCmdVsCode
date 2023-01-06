@isTest
public without sharing class LC_Sing_MngPortalAccess_TEST {
/*----------------------------------------------------------------------
-- - Name          : LC_Sing_MngPortalAccess_TEST
-- - Author        : Spoon
-- - Description   : test class for LC_Sing_MngPortalAccess
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 04-JAN-2022  HSO  1.0      Initial version 
-------------------------------------------------------------------------*/

    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<User> lstUser = new List<User>();
    static List<Sourcing_Event_Team__c> lstTeam;
    static Map<String, RecordType> mapSE;
    static Map<String, RecordType> mapRT;

    static{
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name = 'AXA GO France'].Id;

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Bypass_FieldFilter__c = true;
        testUser.UserRoleId = userRoleId;
        insert testUser;

        System.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');

            // Account
            lstAccount = TestFactory.createAccount(5, mapRT.get('cTin_Parent_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.Email = 'test1jamesbrown@gmail.com';
            
            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.Email = 'test2kimjah@gmail.com';

            Contact con3 = TestFactory.createContact(lstAccount[2],'agrad','skaiz');
            con3.Email = 'test3agradskaiz@gmail.com';

            Contact con4 = TestFactory.createContact(lstAccount[3],'Jay','Jay');
            con4.Email = 'test4jayjay@gmail.com';

            Contact con5 = TestFactory.createContact(lstAccount[4],'John','cena');
            con5.Email = 'test5johncena@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            lstContact.add(con4);
            lstContact.add(con5);

            insert lstContact;

            //Profile
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];

            //Users
            lstUser.add(TestFactory.createUser('Testuser1', profile.Id, true));
            lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser3', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser4', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser5', profile.Id, true));
            
            lstUser[0].ContactId = lstContact[0].Id;
            lstUser[0].IsActive = true;

            lstUser[4].ContactId = lstContact[4].Id;
            lstUser[4].IsActive = true;

            insert lstUser;

            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
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
                    SharingLogic__c = 'Restrict access to my sourcing team',
                    ContractAlreadyGenerated__c = true

                ),
                new Sourcing_Event__c(
                    Description__c = 'test event 778',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = false,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    SharingLogic__c = 'Restrict access to my sourcing team'
                ),
                new Sourcing_Event__c(
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
                    SharingLogic__c = 'Restrict access to my entity'
                ),
                new Sourcing_Event__c(
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
                    SharingLogic__c = 'Restrict access to my entity'
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event 779',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = false,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    SharingLogic__c = 'Restrict access to my entity'
                )

            };

            insert lstSourcingEvent;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED
                ),
                //when bidder sourcin_event__r NDA_Mandatory__c is false
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Contact_Bidder__c = lstContact[2].id,
                    Sing_Account__c = lstAccount[2].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[3].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[3].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SELECTED
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[4].Id,
                    Contact_Bidder__c = lstContact[4].id,
                    Sing_Account__c = lstAccount[4].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SELECTED
                )
            };
            insert lstParticipant;
        }
    }

    @isTest
    static void openAccess_Test(){
        System.runAs(testUser){

            Test.startTest();
                Map <String, Object> mapResult = LC_Sing_ManagePortalAccess.openAccess(lstSourcingEvent[0].Id);
            Test.stopTest();

            List<User> lstUsr = [SELECT Id, ContactId, isActive FROM User WHERE ContactId = :lstContact[0].Id];

            System.assertEquals(true, lstUsr.size() > 0);
            System.assert(mapResult.keySet().contains('success'));

            for(User u : lstUsr){
                System.assertEquals(true, u.isActive);
            }
        }
    }

    // @isTest
    // static void openAccess_InactiveUser_Test(){
    //     // System.runAs(testUser){
    //     //     lstUser[1].isActive = false;
    //     //     update lstUser;
    //     //     User u = [SELECT Id, Name, isActive FROM USER WHERE Id = :lstUser[1].Id];
    //     //     System.debug('###User Active ' + u.isActive);
    //     //     Test.startTest();
    //     //         LC_Sing_ManagePortalAccess.openAccess(lstSourcingEvent[0].Id);
    //     //     Test.stopTest();
    //     // }
    //     System.runAs(testUser){
    //         lstUser[0].isActive = false;
    //         update lstUser;
            
    //         Test.startTest();
    //             Map <String, Object> mapResult = LC_Sing_ManagePortalAccess.openAccess(lstSourcingEvent[0].Id);
    //         Test.stopTest();

    //         System.assert(mapResult.keySet().contains('success'));
    //     }
    // }

    //if Bidder.sourcin_event__r.NDA_Mandatory__c = false
    @isTest
    static void openAccess_NoNdaMandatory_Test(){
        System.runAs(testUser){
            Test.startTest();
                Map <String, Object> mapResult = LC_Sing_ManagePortalAccess.openAccess(lstSourcingEvent[1].Id);
            Test.stopTest();

            System.assert(mapResult.keySet().contains('success'));
        }
    }

    @isTest
    static void closeAccess_Test(){
        System.runAs(testUser){
            Test.startTest();
                lstParticipant[3].Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_LOST;
                update lstParticipant;
            Test.stopTest();

            List<User> lstUsr = [SELECT Id, isActive, contactId FROM User WHERE contactId = :lstContact[3].Id ];

            System.assertEquals(true, lstUser.size() > 0);

            for(User u : lstUsr){
                System.assertEquals(false, u.isActive);
            }
        }
    }

        // @isTest
    // static void closeAccess_NoContactsWithNoUpdt_Test(){
    //     System.runAs(testUser){
    //         Test.startTest();
    //             lstParticipant[3].Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_LOST;
    //             update lstParticipant;
    //         Test.stopTest();
    //     }
    // }

    @isTest
    static void openAccessToBidder_Test(){
        System.runAs(testUser){
            Test.startTest();
            lstParticipant[4].Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED;
                update lstParticipant;
            Test.stopTest();
            
            List<User> lstUsr = [SELECT Id, ContactId, isActive FROM User WHERE ContactId = :lstContact[4].Id];

            System.assertEquals(true, lstUsr.size() > 0);

            for(User u : lstUsr){
                System.assertEquals(true, u.isActive);
            }
        }
    }

    @isTest
    static void openAccessToBidder_InactiveUser_Test(){
        System.runAs(testUser){
            lstUser[4].IsActive = false;
            update lstUser;

            Test.startTest();
                lstParticipant[4].Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED;
                update lstParticipant;
            Test.stopTest();
            List<User> lstUsr = [SELECT Id, ContactId, isActive FROM User WHERE ContactId = :lstContact[4].Id];

            System.assertEquals(true, lstUsr.size() > 0);

            for(User u : lstUsr){
                System.assertEquals(true, u.isActive);
            }
        }
    }
}