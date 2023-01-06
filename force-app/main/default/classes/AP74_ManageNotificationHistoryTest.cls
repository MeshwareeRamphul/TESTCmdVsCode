@isTest
public with sharing class AP74_ManageNotificationHistoryTest {

    static List<User> lstUser = new list<User>();
    static List<Sourcing_Event__c> lstSourcingEvent = new List<Sourcing_Event__c>();
    static List<Bidder__c> lstParticipant = new List<Bidder__c>();
    
    static{
        lstUser.add(TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true));
        insert lstUser;

        //lstUser[0].Bypass_FieldFilter__c=true;
        //lstUser[0].cTin_Universign__c = true;
        //lstUser[0].PAD_BypassValidationRules__c = true;
        //lstUser[0].PAD_BypassTrigger__c = 'AP40;AP39';
        //update lstUser;

        lstSourcingEvent.add(new Sourcing_Event__c(
            Description__c = 'test event 01',
            Documents_Uploaded__c = 'No',
            Event_start_date__c = System.Today(),
            Event_End_date__c = System.Today().addMonths(1),
            Bid_Due_Date__c = System.Today().addDays(5),
            NDA_Sent__c = true,
            NDA_Mandatory__c = true,
            Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS
        ));

        System.runAs(lstUser[0]){
            insert lstSourcingEvent;

            
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');

            lstParticipant.add(new Bidder__c(
                Sourcing_Event__c = lstSourcingEvent[0].Id,
                Sing_Account__c = TestFactory.createAccount(3, mapRT.get('cTin_Supplier').id)[0].id
            ));
            insert lstParticipant;
        }
    }

    @IsTest
    static void createNotificationHistory(){
        Messaging.SendEmailResult[] results;

        System.runAs(lstUser[0]){
            AP74_ManageNotificationHistory.CreateNotificationHistory(lstParticipant, results,'test notif');
        }
    }
}