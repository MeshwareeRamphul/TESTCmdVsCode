@isTest
public without sharing class AP05_Sing_mangageEventTeam_TEST {
/*----------------------------------------------------------------------
-- - Name          : AP05_Sing_mangageEventTeam_TEST
-- - Author        : Spoon
-- - Description   : test class for AP05_Sing_mangageEventTeam
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 23-DEC-2021  HSO  1.0      Initial version 
-- 06-JAN-2022  MBE  1.1      Add test method updateSourcingTeam
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
                    BusinessOwner__c = lstUser[4].Id,
                    SharingLogic__c = 'Restrict access to my sourcing team'
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
                    RecordTypeId = mapSE.get('RFI').id,
                    BusinessOwner__c = lstUser[3].Id,
                    SharingLogic__c = 'Restrict access to my entity'
                )
            };
            insert lstSourcingEvent;
            
            //Negotiation Round
            lstRound = new List<Negotiation_Round__c>{
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addDays(10),
                    Round_Start_Date__c = System.Today().addDays(2),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addDays(10),
                    Round_Start_Date__c = System.Today().addDays(2),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addDays(10),
                    Round_Start_Date__c = System.Today().addDays(2),
                    Round_Status__c = 'In Progress'
                )
            };
            insert lstRound;

            lstParticipant = new List<Bidder__c>{
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    NDA_Signed__c = true,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS,
                    NDA_Signed__c = true,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    NDA_Signed__c = true,
                    Negotiation_Round__c = lstRound[2].Id
                )
            };
            insert lstParticipant;
/*
            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc3', PathOnClient='Doc3.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[1].Id),
                new ContentVersion(Title='Doc4', PathOnClient='Doc4.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[1].Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            Boolean isNDA = true;
            for(ContentDocument cd : lstContentDocument){
                cd.Description = isNDA ? AP_Constant.DOCUMENT_TYPE_NDA_SIGNED : AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS;
                isNDA = false;
            }

            //update lstContentDocument;

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstSourcingEvent[2].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[3].ContentDocumentId, LinkedEntityId=lstSourcingEvent[2].Id, ShareType='I')
            };
            //insert lstContentDocumentLink;
            //*/
        }
    }
    
    @isTest
    static void addBoToTeam_Test(){
        System.runAs(testUser){
            List<Sourcing_Event__c> lstEvent = new List<Sourcing_Event__c>{
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
                    RecordTypeId = mapSE.get('RFP').id,
                    BusinessOwner__c = lstUser[4].Id,
                    SharingLogic__c = 'Restrict access to my sourcing team'
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
                

            Test.startTest();
                insert lstEvent;

                lstEvent[0].BusinessOwner__c = lstUser[0].Id;
                lstEvent[0].OwnerId = lstUser[0].Id;
                lstEvent[0].SharingLogic__c = 'Restrict access to my entity';

                lstEvent[1].BusinessOwner__c = lstUser[1].Id;
                lstEvent[1].OwnerId = lstUser[1].Id;
                lstEvent[1].SharingLogic__c = '';

                lstEvent[2].SharingLogic__c = 'Restrict access to my sourcing team';

                update lstEvent;
            Test.stopTest();
        }
    }

   /* @isTest
    static void shareWithPortalUsers_Test(){
        System.runAs(testUser){
            Test.startTest();
            lstContentDocument[lstContentDocument.size()-1].Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
            update lstContentDocument;
            
            lstSourcingEvent[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEvent[2].Documents_Uploaded__c = 'Yes';
            lstSourcingEvent[2].Publish_start_date_time__c = System.Today().addDays(4);
            update lstSourcingEvent;
            Test.stopTest();

            for(Sourcing_Event__c event : [SELECT Id, Name,  Documents_Uploaded__c, Sourcing_Status__c FROM Sourcing_Event__c WHERE Id = :lstSourcingEvent[2].Id]){
                System.assertEquals('Yes', event.Documents_Uploaded__c);
                System.assertEquals(AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED, event.Sourcing_Status__c);
            }
        }
    }
   */
    @isTest
    static void shareWithPortalNewActivatedUsers_Test(){
        System.runAs(testUser){

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
            
            Test.startTest();
            lstSourcingEvent[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEvent[0].Documents_Uploaded__c = 'Yes';
            lstSourcingEvent[0].Publish_start_date_time__c = System.Today().addDays(2);
            //update lstSourcingEvent;

            Integer count = [SELECT count() FROM Sourcing_Event__share WHERE parentId = :lstSourcingEvent[0].Id];
            //System.assertEquals(1, count);

            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEvent[0].Id,
                Contact_Bidder__c = lstContact[2].id,
                Sing_Account__c = lstAccount[2].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                NDA_Signed__c = true,
                Negotiation_Round__c = lstRound[2].Id
            );
            insert bid;

            userVendor.AgreedToPolicy__c = true;
            userVendor.TermsOfService__c = true;
            userVendor.IsActive = true;
            update userVendor;
            List<Sourcing_Event__share> lstEventShare = [SELECT Id, parentId, UserOrGroupId FROM Sourcing_Event__share WHERE parentId = :lstSourcingEvent[0].Id];
            //System.assertEquals(count+1, lstEventShare.size());
            //System.assertEquals(userVendor.Id, lstEventShare[lstEventShare.size()-1].UserOrGroupId);
            Test.stopTest();

        }
    }

    @isTest
    static void deleteSharingEvent_Test(){
        System.runAs(testUser){
            List<User> lstVendor = new List<User>();
            User userVendor1 = new User(
                Username = System.now().millisecond() + 'test1@test.com',
                ContactId = lstContact[1].Id,
                ProfileId = vendorProfile.Id,
                Alias = 'test1',
                Email = lstContact[1].Email,
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test1',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            lstVendor.add(userVendor1);
            
            User userVendor2 = new User(
                Username = System.now().millisecond() + 'test2@test.com',
                ContactId = lstContact[2].Id,
                ProfileId = vendorProfile.Id,
                Alias = 'test2',
                Email = lstContact[2].Email,
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test2',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            lstVendor.add(userVendor2);
            insert lstVendor;

            Test.startTest();
            lstSourcingEvent[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
           // lstSourcingEvent[0].Documents_Uploaded__c = 'Yes';
           // lstSourcingEvent[0].Publish_start_date_time__c = System.Today().addDays(2);
           // update lstSourcingEvent;
            
            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEvent[0].Id,
                Contact_Bidder__c = lstContact[2].id,
                Sing_Account__c = lstAccount[2].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                NDA_Signed__c = true,
                Negotiation_Round__c = lstRound[2].Id
            );
            insert bid;

            lstVendor[0].AgreedToPolicy__c = true;
            lstVendor[0].TermsOfService__c = true;
            lstVendor[0].IsActive = true;
            lstVendor[1].AgreedToPolicy__c = true;
            lstVendor[1].TermsOfService__c = true;
            lstVendor[1].IsActive = true;
            update lstVendor;

            Integer shareSize1 = [SELECT count() FROM Sourcing_Event__share WHERE parentId = :lstSourcingEvent[0].Id];
            List<Bidder__c> lstBid = [SELECT Id FROM Bidder__c WHERE Sourcing_Event__c = :lstSourcingEvent[0].Id];
            if(lstBid.size() > 0){
                for(Bidder__c bidder : lstBid){
                    bidder.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_LOST;
                }
                update lstBid;
            }
            Integer shareSize2 = [SELECT count() FROM Sourcing_Event__share WHERE parentId = :lstSourcingEvent[0].Id];
            //System.assertEquals(shareSize1 - lstBid.size(), shareSize2);
            Test.stopTest();

        }
    }

    @isTest
    static void updateSourcingTeam(){
        System.runAs(testUser){

            Test.startTest();
            lstTeam = new List<Sourcing_Event_Team__c>{
                new Sourcing_Event_Team__c(
                    Role__c = '001',
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Team_Member__c = testUser.Id
                    //Member_Group__c = 'AXA Partners Procurement'
                ),
                new Sourcing_Event_Team__c(
                    Role__c = '002',
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Team_Member__c = lstUser[2].Id,
                    Event_Access_Level__c = 'Read'
                    //Member_Group__c = 'AXA Partners Procurement'
                )
            };
            insert lstTeam;
                lstTeam[0].Team_Member__c = lstUser[2].Id;
                update lstTeam;
            Test.stopTest();

            for(Sourcing_Event_Team__c team : [SELECT Id, Name,  Team_Member__c FROM Sourcing_Event_Team__c WHERE Id = :lstTeam[0].Id]){
                //System.assertEquals(lstUser[2].Id, team.Team_Member__c);
            }
        }
    }
    
   
    
}