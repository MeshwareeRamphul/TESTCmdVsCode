@isTest
public with sharing class AP61_SendEmail_Round_TEST {
    static User testUser;
    static User testUserEsourcingVendor;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Negotiation_Round__c> lstRound;
    static List<Bidder__c> lstParticipant;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static Map<String, RecordType> mapSE = new Map<String, RecordType>();
	static Map<String, RecordType> mapRT = new Map<String, RecordType>();
    static Map<String, RecordType> mapContactRT = new Map<String, RecordType>();
    static String strInternalRole = 'Internal';

    static{      

        List<UserRole> lstRole = [SELECT Id, Name FROM UserRole WHERE Name = : strInternalRole];

      	testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);

        if(lstRole.size() > 0){
            testUser.UserRoleId = lstRole[0].Id;
        }
        
      	insert testUser;

        List<Profile> lstProfiles = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];
        
      	system.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Account
            lstAccount = TestFactory.createAccount(5, mapRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.Email = 'test1@gmail.com';
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.Email = 'test2@gmail.com';
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

			Contact con3 = TestFactory.createContact(lstAccount[0],'Jim','Brick');
            con3.Email = 'test3@gmail.com';
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

			Contact con4 = TestFactory.createContact(lstAccount[1],'Ken','Jeh');
            con4.Email = 'test4@gmail.com';
            con4.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

			Contact con5 = TestFactory.createContact(lstAccount[4],'Ken','Wood');
            con5.Email = 'test5@gmail.com';
            con5.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

            lstContact.add(con1);
            lstContact.add(con2);
			lstContact.add(con3);
			lstContact.add(con4);
			lstContact.add(con5);
            insert lstContact;

            testUserEsourcingVendor = TestFactory.createUser('UsrAdmin', lstProfiles[0].Id, true);
            testUserEsourcingVendor.ContactId = lstContact[3].Id;
            insert testUserEsourcingVendor;

			//Sourcing Event RFI
			lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    Sing_Requesting_Owner_Entity__c = '1000 - AXA Investment Managers',
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    Sing_Requesting_Owner_Entity__c = '1000 - AXA Investment Managers',
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 03',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    Preferred_Time_Zone2__c= 'GMT+01 Europe/Paris',
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = false,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    Sing_Requesting_Owner_Entity__c = '1000 - AXA Investment Managers',
                    RecordTypeId = mapSE.get('RFI').id
                )
            };
            insert lstSourcingEvent;

            List<Sourcing_Event__share> lstSEShare = new List<Sourcing_Event__share>();

            for(Sourcing_Event__c se : lstSourcingEvent){
                Sourcing_Event__share newSharing = new Sourcing_Event__share ();
                newSharing.accesslevel = 'Read';
                newSharing.UserOrGroupId = testUserEsourcingVendor.Id; 
                newSharing.parentId = se.Id;
                lstSEShare.add(newSharing);
            }

            insert lstSEShare;

            

            //Negotiation Round
			lstRound = new List<Negotiation_Round__c>{
				new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                )
            };
            insert lstRound;

			//Bidders
			lstParticipant = new List<Bidder__c>{
				new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                ),
				new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[2].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[2].Id,
                    Contact_Bidder__c = lstContact[4].id,
                    Sing_Account__c = lstAccount[4].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                    Negotiation_Round__c = lstRound[2].Id
                )
            };
            insert lstParticipant;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc3', PathOnClient='Doc3.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[1].Id),
                new ContentVersion(Title='Doc4', PathOnClient='Doc4.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[2].Id, Sharing_Logic__c = 'All Vendors'),
                new ContentVersion(Title='Doc5', PathOnClient='Doc5.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[2].Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument ORDER BY LatestPublishedVersionId DESC];

            for(ContentDocument cd : lstContentDocument){
                cd.Description = AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS;
            }
            update lstContentDocument;

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstSourcingEvent[1].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[3].ContentDocumentId, LinkedEntityId=lstSourcingEvent[2].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[4].ContentDocumentId, LinkedEntityId=lstSourcingEvent[2].Id, ShareType='I')
            };
            insert lstContentDocumentLink;
        }
    }

    @isTest
    static void sendMailTest(){
      
        System.runAs(testUser){
            Test.startTest();
            lstContentDocument[lstContentDocument.size()-1].Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
            update lstContentDocument;
            
            lstSourcingEvent[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEvent[2].Documents_Uploaded__c = 'Yes';
            lstSourcingEvent[2].Publish_start_date_time__c = System.Today().addDays(4);
            update lstSourcingEvent;
            AP61_SendEmail_Round.sendTo_ShortlistedOrInProgress_Participant(lstRound);
            Test.stopTest();
        }
    }


}