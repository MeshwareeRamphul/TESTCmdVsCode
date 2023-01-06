@isTest
public with sharing class LWC2_DocumentToUpload_Sing_TEST {
    /* --------------------------------------------------------------------------------------
    -- - Name          : LC02_Sing_SelectAwardees_Test
    -- - Author        : ARA
    -- - Description   : test class for LC02_Sing_SelectAwardees
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 04-JAN-2022  ARA    1.0     Initial version
    -- 05-JAN-2022  MBE    1.1     Rework
    --------------------------------------------------------------------------------------*/
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
    static LWC2_DocumentToUpload_Sing.DocumentWrapper docportal, docSpecificVendor, docAllVendors;

    static{      
        List<UserRole> lstRole = [SELECT Id, Name FROM UserRole WHERE Name = : strInternalRole];

      	testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);

        if(lstRole.size() > 0){
            testUser.UserRoleId = lstRole[0].Id;
        }
        
      	insert testUser;

        testUser.PAD_BypassTrigger__c = 'AP02;AP31';
        testUser.PAD_BypassWorkflows__c =true;
        testUser.Bypass_FieldFilter__c =true;
        testUser.PAD_Bypass_ReadOnly_HC__c=true;
        testUser.PAD_BypassValidationRules__c =true;
        update testUser;


        List<Profile> lstProfiles = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];
        
      	system.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

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

			Contact con3 = TestFactory.createContact(lstAccount[0],'Jim','Brick');
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con3.Email = 'test3@gmail.com';

			Contact con4 = TestFactory.createContact(lstAccount[1],'Ken','Jeh');
            con4.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con4.Email = 'test4@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
			lstContact.add(con3);
			lstContact.add(con4);
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
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                )
            };
            insert lstSourcingEvent;

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
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                )
            };
            insert lstParticipant;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc3', PathOnClient='Doc3.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id, Participant__c = lstParticipant[0].Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber, Participant__c FROM ContentVersion WHERE Id IN :setContentVersionId order by Title ASC];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstParticipant[0].Id, ShareType='I')
            };
            insert lstContentDocumentLink;

            docSpecificVendor = new LWC2_DocumentToUpload_Sing.DocumentWrapper();
            docSpecificVendor.documentId = lstContentDocument[0].Id;
            docSpecificVendor.name = 'Test 1';
            docSpecificVendor.fileName = 'Test 1';
            docSpecificVendor.type = 'NDA Signed';
            docSpecificVendor.sharingLogic = 'Specific Vendor';
            docSpecificVendor.roundId = lstRound[1].Id;
            docSpecificVendor.participantId = lstParticipant[0].Id;
            docSpecificVendor.inserted = true;
            docSpecificVendor.required = true;

            docAllVendors = new LWC2_DocumentToUpload_Sing.DocumentWrapper();
            docAllVendors.documentId = lstContentDocument[1].Id;
            docAllVendors.name = 'Test 2';
            docAllVendors.fileName = 'Test 2';
            docAllVendors.type = 'NDA Signed';
            docAllVendors.sharingLogic = 'All Vendors';
            docAllVendors.roundId = lstRound[1].Id;
            docAllVendors.participantId = lstParticipant[0].Id;
            docAllVendors.inserted = true;
            docAllVendors.required = true;

            docportal = new LWC2_DocumentToUpload_Sing.DocumentWrapper();
            docportal.documentId = lstContentDocument[2].Id;
            docportal.name = 'Test 1';
            docportal.fileName = 'Test 1';
            docportal.type = 'Participant Document';
            docportal.sharingLogic = 'Specific Vendor';
            docportal.roundId = lstRound[1].Id;
            docportal.participantId = lstParticipant[0].Id;
            docportal.inserted = true;
            docportal.required = true;
        }
    }

    @isTest
    static void getDocumentType_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC2_DocumentToUpload_Sing.getDocumentType(lstSourcingEvent[0].Id);
            test.stopTest();
            
            String prefixId = ('' + lstSourcingEvent[0].Id).substring(0, 3);
            String currentObject = '';
            for(Schema.SObjectType objectInstance : Schema.getGlobalDescribe().values()){
                if(objectInstance.getDescribe().getKeyPrefix() == prefixId){
                    currentObject = objectInstance.getDescribe().getName();
                }
            }
            /*User user = [SELECT Id, name FROM User WHERE Id = :testUser.Id];
            System.assertEquals(mapOfResult.get('currentObject'), currentObject);
            System.assertEquals(mapOfResult.get('user'), user);*/
        }
    }

    @isTest
    static void getAllDocuments_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC2_DocumentToUpload_Sing.getAllDocuments(lstSourcingEvent[0].Id);
            test.stopTest();

            System.assertNotEquals(null, mapOfResult.get('data'));
        }
    }

    @isTest
    static void getParticipantDocuments_test(){
        System.runAs(testUser){
            test.startTest();
                List<LWC2_DocumentToUpload_Sing.DocumentWrapper> lstDocumentWrapper = new List<LWC2_DocumentToUpload_Sing.DocumentWrapper>{docportal};
                Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.addParticipantDocuments(lstDocumentWrapper, lstParticipant[0].Id);

                map<String,Object> mapOfResult = LWC2_DocumentToUpload_Sing.getParticipantDocuments(lstParticipant[0].Id);
            test.stopTest();

            System.assertNotEquals(null, mapOfResult.get('data'));
        }
    }

    @isTest
    static void addDocument_test(){
        System.runAs(testUser){
            test.startTest();
                List<LWC2_DocumentToUpload_Sing.DocumentWrapper> lstDocumentWrapper = new List<LWC2_DocumentToUpload_Sing.DocumentWrapper>{docSpecificVendor, docAllVendors};
                Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.addDocuments(lstDocumentWrapper, lstSourcingEvent[0].Id);
            test.stopTest();

            /*List<ContentDocumentLink> lstAllContentDocumentLink = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :lstSourcingEvent[0].Id];
            System.assertEquals(2, lstAllContentDocumentLink.size());*/
        }
    }

    @isTest
    static void replaceDocumentSpecificVendor_test(){
        System.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.replaceDocument(docSpecificVendor, lstContentDocument[1].Id, lstSourcingEvent[0].Id);
            test.stopTest();

            LWC2_DocumentToUpload_Sing.DocumentWrapper newDocResult = (LWC2_DocumentToUpload_Sing.DocumentWrapper)mapResult.get('data');
            System.assertEquals(docSpecificVendor.roundId, newDocResult.roundId);
            System.assertEquals(docSpecificVendor.participantId, newDocResult.participantId);
        }
    }

    @isTest
    static void replaceDocumentAllVendor_test(){
        System.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.replaceDocument(docAllVendors, lstContentDocument[1].Id, lstSourcingEvent[0].Id);
            test.stopTest();

            LWC2_DocumentToUpload_Sing.DocumentWrapper newDocResult = (LWC2_DocumentToUpload_Sing.DocumentWrapper)mapResult.get('data');
            System.assertEquals(docAllVendors.roundId, newDocResult.roundId);
            System.assertEquals(docAllVendors.participantId, newDocResult.participantId);
        }
    }

    @isTest
    static void deleteDocumentSuccess_test(){
        System.runAs(testUser){
            test.startTest();
                List<Id> lstContentDocumentId = new List<Id>{lstContentDocument[0].Id};
                Map<String,String> result = LWC2_DocumentToUpload_Sing.deleteDocument(lstContentDocumentId);
            test.stopTest();

            System.assertEquals(result.containsKey('success'), true);

            /*List<ContentDocument> lstAllContentDocument = [SELECT Id FROM ContentDocument];
            System.assertEquals(1, lstAllContentDocument.size());
            
            List<ContentDocument> lstDeletedContentDocument = [SELECT Id FROM ContentDocument WHERE Id = :lstContentDocument[0].Id];
            System.assertEquals(0, lstDeletedContentDocument.size());*/
        }
    }

    @isTest
    static void updateDocument_test(){
        System.runAs(testUser){
            test.startTest();
                docSpecificVendor.name = 'Test 1 Updated';
                docAllVendors.name = 'Test 2 Updated';
                List<LWC2_DocumentToUpload_Sing.DocumentWrapper> lstDocumentWrapper = new List<LWC2_DocumentToUpload_Sing.DocumentWrapper>{docSpecificVendor, docAllVendors};
                Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.updateDocument(lstDocumentWrapper, lstSourcingEvent[0].Id);
            test.stopTest();

            /*for(ContentVersion cv1 : [SELECT Id, Sing_DocumentName__c FROM ContentVersion WHERE ContentDocumentId = :docSpecificVendor.documentId]){
                System.assertEquals('Test 1 Updated', cv1.Sing_DocumentName__c);
            }

            for(ContentVersion cv2 : [SELECT Id, Sing_DocumentName__c FROM ContentVersion WHERE ContentDocumentId = :docAllVendors.documentId]){
                System.assertEquals('Test 2 Updated', cv2.Sing_DocumentName__c);
            }*/
        }
    }
}