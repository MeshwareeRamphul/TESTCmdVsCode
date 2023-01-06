@isTest
public without sharing class LC53_WithdrawParticipation_TEST {
/*----------------------------------------------------------------------
-- - Name          : LC53_WithdrawParticipation_TEST
-- - Author        : Spoon
-- - Description   : test class for LC53_WithdrawParticipation
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 10-JAN-2022  HSO  1.0      Initial version 
-------------------------------------------------------------------------*/
    static User userAdmin;
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
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name = 'AXA GO France'].Id;

        userAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        userAdmin.Bypass_FieldFilter__c = true;
        userAdmin.UserRoleId = userRoleId;
        insert userAdmin;

        System.runAs(userAdmin){
            //RecordType
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Account
            lstAccount = TestFactory.createAccount(5, mapRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con0 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con0.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con0.Email = 'test1jamesbrown@gmail.com';
            
            Contact con1 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test2kimjah@gmail.com';
            

            lstContact.add(con0);
            lstContact.add(con1);

            insert lstContact;

            //Profile
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];

            //User
            lstUser.add(TestFactory.createUser('userAdmin1', profile.Id, true));

            lstUser[0].ContactId = lstContact[0].Id;
            lstUser[0].IsActive = true;

            insert lstUser;

            //Sourcing Event
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
                    Legal_Entity__c = lstAccount2[1].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = false,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    SharingLogic__c = 'Restrict access to my sourcing team'
                )
            };

            insert lstSourcingEvent;

            //Participants
            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_LOST
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SELECTED
                )
            };
            insert lstParticipant;
        }
    }

    @isTest
    static void showWithdrawBtn_Hide_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                Map<String, Object> mapResult = LC53_WithdrawParticipation.showWithdrawBtn(lstParticipant[0].Id);
            Test.stopTest();

            System.assertEquals(true, mapResult.containsKey('hide'));
        }
    }

    @isTest
    static void showWithdrawBtn_Show_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                Map<String, Object> mapResult = LC53_WithdrawParticipation.showWithdrawBtn(lstParticipant[1].Id);
            Test.stopTest();

            System.assertEquals(true, mapResult.containsKey('show'));
        }
    }

    @isTest
    static void withdraw_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                Map<String, Object> mapResult = LC53_WithdrawParticipation.withdraw(lstParticipant[1].Id);
            Test.stopTest();
            
            List<Bidder__c> lstBidder = [SELECT Id, bidder_status__c FROM Bidder__c WHERE Id = :lstParticipant[1].Id];

            //System.assertEquals(true, mapResult.containsKey('success'));

            for(Bidder__c bidder : lstBidder){
                System.assertEquals('Declined', bidder.bidder_status__c);
            }
        }
    }

    @isTest
    static void withdraw_Test2(){
        System.runAs(lstUser[0]){
            Test.startTest();
                Map<String, Object> mapResult = LC53_WithdrawParticipation.withdraw(null);
            Test.stopTest();
    
            System.assertEquals(true, mapResult.containsKey('Error'));
        }
    }
}