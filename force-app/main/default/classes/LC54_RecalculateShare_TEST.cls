@isTest
public class LC54_RecalculateShare_TEST {

    /*----------------------------------------------------------------------
    -- - Name          : LC54_RecalculateShare_TEST
    -- - Author        : Spoon
    -- - Description   : class test for LC54_RecalculateShare
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 02-MAR-2022  ARA    1.0      Initial Version (SP-03490)
    -------------------------------------------------------------------------*/

    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Negotiation_Round__c> lstRound;
    static List<Account> lstAccount, lstAccount2;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static List<Sourcing_Event__share> lstShare;
    static List<User> lstUser;
    static Integer nbrSharing;
    static Profile vendorProfile;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static Account supplier1;
    static list<Contact> lstContact=new list<Contact>();
    
	static{
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.UserRoleId = portalRole.Id;
        insert testUser;
        
        System.runAs(testUser){
            
            Map<String, RecordType> mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            Map<String, RecordType> mapContactRT = AP_Constant.getRecordTypes('Contact');
            Map<String, RecordType> mapAccountRT = AP_Constant.getRecordTypes('Account');
            vendorProfile = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile limit 1];
            
            // Account
            lstAccount = TestFactory.createAccount(3, mapAccountRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapAccountRT.get('cTin_AXA').id);
            // Create the legal entity (aka billing entity) account
            supplier1 = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Contact
            // Contact con1 = TestFactory.createContact(supplier1,'James','Brown');
            // Contact con2 = TestFactory.createContact(supplier1,'Kim','Jah');
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test1@test.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'test2@test.com';

            lstContact.add(con1);
            lstContact.add(con2);
            insert lstContact;

            lstUser = new List<User>{
                new User(
                    Username = System.now().millisecond() + 'test1@test.com',
                    ContactId = lstContact[0].Id,
                    ProfileId = vendorProfile.Id,
                    Alias = 'test1',
                    Email = lstContact[0].Email,
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'McTest1',
                    CommunityNickname = 'test1',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US'
                ),
                new User(
                    Username = System.now().millisecond() + 'test2@test.com',
                    ContactId = lstContact[1].Id,
                    ProfileId = vendorProfile.Id,
                    Alias = 'test2',
                    Email = lstContact[1].Email,
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'McTest2',
                    CommunityNickname = 'test2',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US'
                )
            };
            insert lstUser;

            lstSourcingEvent = new List<Sourcing_Event__c>{new Sourcing_Event__c(
                    Description__c = 'test event 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = false,
                    NDA_Mandatory__c = false,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id
                )
            };
            insert lstSourcingEvent;

            lstRound = new List<Negotiation_Round__c>{
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addDays(10),
                    Round_Start_Date__c = System.Today().addMonths(2),
                    Round_Status__c = AP_Constant.ROUND_STATUS_IN_PROGRESS
                )
            };

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS
                )
            };
            insert lstParticipant;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();
            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];
            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I')
            };
            insert lstContentDocumentLink;

            for(ContentDocument cd : lstContentDocument){
                cd.Description = 'RFX Requirements';
            }
            update lstContentDocument;

            lstShare = [SELECT Id, Userorgroupid from Sourcing_event__share where Parentid = :lstSourcingEvent[0].Id];
            System.debug('***** lstShare0 '+lstShare);
            lstSourcingEvent[0].Documents_Uploaded__c = 'Yes';
            lstSourcingEvent[0].Publish_start_date_time__c = System.Today().addDays(4);
            lstSourcingEvent[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            update lstSourcingEvent;

            lstUser[0].AgreedToPolicy__c = true;
            lstUser[0].TermsOfService__c = true;
            lstUser[0].IsActive = true;
            lstUser[1].AgreedToPolicy__c = true;
            lstUser[1].TermsOfService__c = true;
            lstUser[1].IsActive = true;
            update lstUser;
            
            lstShare = [SELECT Id, Userorgroupid from Sourcing_event__share where Parentid = :lstSourcingEvent[0].Id];
            System.assertEquals(3, lstShare.size());
            
            List<Sourcing_Event__share> lstSharing = new List<Sourcing_Event__share>{lstShare[1], lstShare[2]};
            delete lstSharing;
        }
    }

    @isTest
    static void acceptWhenPublishedTest(){
        ApexPages.currentPage().getParameters().put('id', lstParticipant[0].Id);
        System.runAs(testUser){
            
            Test.startTest();

            Integer nbrSharing = [SELECT count() from Sourcing_event__share where Parentid = :lstSourcingEvent[0].Id];
            System.assertEquals(1, nbrSharing);
            
            LC54_RecalculateShare.recalculateSharing(lstSourcingEvent[0].Id);
            
            Test.stopTest();

            nbrSharing = [SELECT count() from Sourcing_event__share where Parentid = :lstSourcingEvent[0].Id];
            System.assertEquals(3, nbrSharing);
        }
    }
}