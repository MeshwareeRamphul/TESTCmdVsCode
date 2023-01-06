@isTest
public with sharing class ParticipantTriggerHandler_TEST {
/*----------------------------------------------------------------------
-- - Name          : ParticipantTriggerHandler_TEST
-- - Author        : Spoon
-- - Description   : Test Class for ParticpantTriggerHandler
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 07-JAN-2022  MBE   1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUserAdmin;
    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Account> lstAccount, lstAccount2;
    static Account supplier1;
    static List<Contact> lstContact = new list<Contact>();
    
	static{
        testUserAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUserAdmin;

        Id buyerProfileId = [SELECT Id From Profile WHERE Name = 'cTin - Contract Buyer'].Id;
        testUser = TestFactory.createUser('UsrAdmin', buyerProfileId, true);
        insert testUser;
        
        System.runAs(testUser){
            
            Map<String, RecordType> mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            
            // Account
            lstAccount = TestFactory.createAccount(3, mapRT.get('cTin_Parent_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);
            // Create the legal entity (aka billing entity) account
            supplier1 = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Contact
            // Contact con1 = TestFactory.createContact(supplier1,'James','Brown');
            // Contact con2 = TestFactory.createContact(supplier1,'Kim','Jah');
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.Email = 'has@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.Email = 'hasi0a@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            insert lstContact;

            lstSourcingEvent = new List<Sourcing_Event__c>{new Sourcing_Event__c(
                    Description__c = 'test event 01',
                    Documents_Uploaded__c = 'No',
                    // Event_start_date__c = System.Today(),
                    // Event_End_date__c = System.Today().addDays(5),
                    // Bid_Due_Date__c = System.Today().addMonths(1),
                    Publish_start_date_time__c = System.Today(),
                    Bid_Due_Date__c = System.Today().addMonths(1),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id
                )
            };
            insert lstSourcingEvent;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = 'Selected'

                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = 'Selected'

                )
            };
            insert lstParticipant;
        }
    }

    @isTest
    static void deleteParticipant(){
        System.runAs(testUser){
            Test.startTest();
                delete lstParticipant[1];
            Test.stopTest();
        }
    }
}