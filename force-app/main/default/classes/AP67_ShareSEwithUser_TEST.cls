@isTest
public class AP67_ShareSEwithUser_TEST {
/*----------------------------------------------------------------------
-- - Name          : AP67_ShareSEwithUser_TEST
-- - Author        : Spoon
-- - Description   : test class for AP67_ShareSEwithUser
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 21-JAN-2022  ARA  1.0      Initial version 
-------------------------------------------------------------------------*/

    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<User> lstUser = new List<User>();
    static Map<String, RecordType> mapSE;
    static Map<String, RecordType> mapRT;
    static Map<String, RecordType> mapContactRT;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<Negotiation_Round__c> lstRound;
    static List<Sourcing_Event_Team__c> lstTeam;
    static Profile vendorProfile;
    static User userVendor;

    static{
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.UserRoleId = portalRole.Id;
        insert testUser;

        System.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');
            vendorProfile = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile limit 1];

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

            Contact con3 = TestFactory.createContact(lstAccount[2],'Kim','Jong');
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con3.Email = 'test3@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            insert lstContact;

            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    OwnerId = lstUser[3].Id,
                    Description__c = 'test event 777',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id,
                    BusinessOwner__c = lstUser[4].Id
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
                    BusinessOwner__c = lstUser[3].Id
                )
            };
            insert lstSourcingEvent;
            
            //Negotiation Round
			lstRound = new List<Negotiation_Round__c>{
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
                )
            };
            insert lstRound;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    NDA_Signed__c = true,
                    Negotiation_Round__c = lstRound[1].Id
                )
            };
            insert lstParticipant;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[1].Id),
                new ContentVersion(Title='Doc3', PathOnClient='Doc3.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[1].Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I')
            };
            insert lstContentDocumentLink;

            lstContentDocument[0].Description = AP_Constant.DOCUMENT_TYPE_NDA_SIGNED;
            lstContentDocument[1].Description = AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS;
            lstContentDocument[2].Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
            update lstContentDocument;

            /*lstTeam = new List<Sourcing_Event_Team__c>{
                new Sourcing_Event_Team__c(
                    Role__c = '001',
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Team_Member__c = testUser.Id
                ),
                new Sourcing_Event_Team__c(
                    Role__c = '002',
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Team_Member__c = lstUser[2].Id,
                    Event_Access_Level__c = 'Read'
                )
            };
            insert lstTeam;*/
        }
    }

    @isTest
    static void createSourcingEventShare_test(){
        System.runAs(testUser){
            
            Test.startTest();
            lstSourcingEvent[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEvent[0].Publish_start_date_time__c = System.Today();
            lstSourcingEvent[0].Documents_Uploaded__c = 'Yes';
            update lstSourcingEvent;

            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEvent[0].Id,
                Contact_Bidder__c = lstContact[2].id,
                Sing_Account__c = lstAccount[2].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                NDA_Signed__c = true,
                Negotiation_Round__c = lstRound[1].Id
            );
            insert bid;

            userVendor = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = lstContact[2].Id,
                ProfileId = vendorProfile.Id,
                Alias = 'test123',
                Email = lstContact[2].Email,
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert userVendor;
            
            userVendor.AgreedToPolicy__c = true;
            userVendor.TermsOfService__c = true;
            userVendor.IsActive = false;
            update userVendor;
            
            userVendor.IsActive = true;
            update userVendor;
            AP67_ShareSEwithUser.createSourcingEventShare(new List<User>{userVendor});
            Test.stopTest();
        }
    }
}