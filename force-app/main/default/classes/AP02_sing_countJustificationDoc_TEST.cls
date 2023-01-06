@isTest
public class AP02_sing_countJustificationDoc_TEST {
/*----------------------------------------------------------------------
-- - Name          : AP02_sing_countJustificationDoc_TEST
-- - Author        : Spoon
-- - Description   : Test Class for AP02_sing_countJustificationDoc
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 23-DEC-2021  MBE  1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUser;
    static User testUserEsourcingVendor;
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static List<Sourcing_Event__c> lstSourcingEventRFI;
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
    static PermissionSet ps;

    static{     

        List<UserRole> lstRole = [SELECT Id, Name FROM UserRole WHERE Name = : strInternalRole];

        testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);

        if(lstRole.size() > 0){
            testUser.UserRoleId = lstRole[0].Id;
        }
        
        insert testUser;

        List<Profile> lstProfiles = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];
        
        ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_ByPassAP44'];
        
        system.runAs(testUser){
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Account
            lstAccount = TestFactory.createAccount(6, mapRT.get('cTin_Supplier').id);
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

            Contact con6 = TestFactory.createContact(lstAccount[5],'Tom','Haank');
            con6.Email = 'test6@gmail.com';
            con6.recordTypeId = mapContactRT.get('cTin_Supplier').Id;

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            lstContact.add(con4);
            lstContact.add(con5);
            lstContact.add(con6);
            insert lstContact;

            testUserEsourcingVendor = TestFactory.createUser('UsrAdmin', lstProfiles[0].Id, true);
            testUserEsourcingVendor.ContactId = lstContact[3].Id;
            insert testUserEsourcingVendor;

      //Sourcing Event RFI
      lstSourcingEventRFI = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event RFI 01',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[0].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Preferred_Time_Zone2__c = 'GMT+01 Europe/Madrid',
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
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Preferred_Time_Zone2__c = 'GMT+01 Europe/Madrid',
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
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = false,
                    Preferred_Time_Zone2__c = 'GMT+01 Europe/Madrid',
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    Sing_Requesting_Owner_Entity__c = '1000 - AXA Investment Managers',
                    RecordTypeId = mapSE.get('RFI').id
                )
            };
            insert lstSourcingEventRFI;

            List<Sourcing_Event__share> lstSEShare = new List<Sourcing_Event__share>();

            for(Sourcing_Event__c se : lstSourcingEventRFI){
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
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEventRFI[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'In Progress'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEventRFI[2].Id,
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
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                    Contact_Bidder__c = lstContact[0].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[1].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                    Contact_Bidder__c = lstContact[2].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[1].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[1].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[2].Id,
                    Contact_Bidder__c = lstContact[4].id,
                    Sing_Account__c = lstAccount[4].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
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
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[0].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[1].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[3].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[2].Id, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[4].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[2].Id, ShareType='I')
            };
            insert lstContentDocumentLink;
        }
    }

    @isTest
    static void updtCountJustification_Test(){
        system.runAs(testUser){
            test.startTest();
                for(ContentDocument cd : lstContentDocument){
                    cd.Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
                }

                update lstContentDocument;

                delete lstContentDocument;
            test.stopTest();

            /*for(ContentDocument cd : [SELECT Id, Description FROM ContentDocument WHERE Id IN :lstContentDocument]){
                //System.assertEquals(AP_Constant.DOCUMENT_TYPE_RFX_RESULTS, cd.Description);
            }*/
        }
    }

    @isTest
    static void blockDocumentDeletion_Test(){
        if(ps != null){
            insert new PermissionSetAssignment(AssigneeId = testUser.id, PermissionSetId = ps.Id);
        }
        system.runAs(testUser){
                
                    for(ContentDocument cd : lstContentDocument){
                        cd.Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
                    }

                    update lstContentDocument;

                    for(Sourcing_Event__c se : lstSourcingEventRFI){
                        se.Documents_Uploaded__c = 'Yes';
                    }

                    update lstSourcingEventRFI;
                    test.startTest();try{
                    delete lstContentDocument;
                }catch(Exception ex){
                   // System.assert(ex.getMessage().contains(System.Label.AP03_Sing_ErrorDocumentUploadedDeletion));                  
                }
                
            test.stopTest();
        
        }
    }

    @isTest
    static void blockUpdateCompletedRound_Test(){
        system.runAs(testUser){
            test.startTest();
                try{
                   
                    for(ContentDocument cd : lstContentDocument){
                        cd.Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
                    }

                    update lstContentDocument;

                    for(ContentDocument cd : [SELECT Id, Description FROM ContentDocument WHERE Id IN :lstContentDocument]){
                        //System.assertEquals(AP_Constant.DOCUMENT_TYPE_RFX_RESULTS, cd.Description);
                    }

                }catch(Exception ex){
                    //System.assertNotEquals(null, ex.getMessage());
                }
            test.stopTest();
        }
    }

    @isTest
    static void addToParticipantDocument_Test(){
        system.runAs(testUser){
            test.startTest();
                List<ContentVersion> lstNewContentVersion = new List<ContentVersion>{
                    new ContentVersion(Title='Doc4', PathOnClient='Doc4.jpg', VersionData=fileContentInBlob, IsMajorVersion=true),
                    new ContentVersion(Title='Doc5', PathOnClient='Doc5.jpg', VersionData=fileContentInBlob, IsMajorVersion=true),
                    new ContentVersion(Title='Doc6', PathOnClient='Doc6.jpg', VersionData=fileContentInBlob, IsMajorVersion=true),
                    new ContentVersion(Title='Doc7', PathOnClient='Doc7.jpg', VersionData=fileContentInBlob, IsMajorVersion=true)
                };
                insert lstNewContentVersion;


                lstNewContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :lstNewContentVersion];

                Set<Id> setContentDocId = new Set<Id>();

                for(ContentVersion cv : lstNewContentVersion){
                    setContentDocId.add(cv.ContentDocumentId);
                }
            
                List<ContentDocument> lstNewContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument WHERE Id IN :setContentDocId];

                List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>{
                    new contentDocumentLink(ContentDocumentId=lstNewContentDocument[0].Id, LinkedEntityId=lstParticipant[0].Id, ShareType='I'),
                    new contentDocumentLink(ContentDocumentId=lstNewContentDocument[1].Id, LinkedEntityId=lstParticipant[1].Id, ShareType='I'),
                    new contentDocumentLink(ContentDocumentId=lstNewContentDocument[2].Id, LinkedEntityId=lstSourcingEventRFI[0].Id, ShareType='I'),
                    new contentDocumentLink(ContentDocumentId=lstNewContentDocument[3].Id, LinkedEntityId=lstSourcingEventRFI[1].Id, ShareType='I')
                };
                insert lstContentDocumentLink;  
            test.stopTest();

            /*for(ContentVersion cv : [SELECT Id, Participant__c, Negotiation_Round__c, Sharing_Logic__c FROM ContentVersion WHERE Id IN :lstNewContentVersion]){
               // System.assertNotEquals('', cv.Participant__c);
               // System.assertNotEquals('', cv.Negotiation_Round__c);
            }*/
        }
    }

    @isTest
    static void updateParticipantStatus_Test(){
        system.runAs(testUser){
            test.startTest();

                for(ContentDocument cd : lstContentDocument){
                    cd.Description = 'NDA Signed';
                }

                update lstContentDocument;

                lstContentVersion[0].Participant__c = lstParticipant[0].Id;
                lstContentVersion[1].Participant__c = lstParticipant[1].Id;
                lstContentVersion[2].Participant__c = lstParticipant[2].Id;
                update lstContentVersion;
            test.stopTest();

            /*List<Id> lstBiddersId = new List<Id>{lstParticipant[0].Id, lstParticipant[1].Id, lstParticipant[2].Id};

            for(Bidder__c participant : [SELECT Id, Negotiation_Round__c, Bidder_Status__c FROM Bidder__c WHERE Id IN :lstBiddersId]){
               // System.assertEquals('NDA Signed', participant.Bidder_Status__c);
            }*/
        }
    }

    @isTest
    static void addParticipantToRound_Test(){
        system.runAs(testUser){
            test.startTest();
                
            
            lstSourcingEventRFI[2].Documents_Uploaded__c = 'Yes';
            lstSourcingEventRFI[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEventRFI[2].Publish_start_date_time__c = System.Today();
            lstSourcingEventRFI[2].Bid_Due_Date__c = System.Today().addMonths(1);
            update lstSourcingEventRFI;
            
            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEventRFI[2].Id,
                Contact_Bidder__c = lstContact[5].id,
                Sing_Account__c = lstAccount[5].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                NDA_Signed__c = true,
                Negotiation_Round__c = lstRound[2].Id
            );
            insert bid;
            test.stopTest();
        
        }
    }

    @isTest
    static void shareDocumentsWithParticipant_Test(){
        system.runAs(testUser){
            test.startTest();
            LWC2_DocumentToUpload_Sing.DocumentWrapper doc1 = new LWC2_DocumentToUpload_Sing.DocumentWrapper();
            doc1.documentId = lstContentDocument[3].Id;
            doc1.name = 'Test 3';
            doc1.fileName = 'Test 3';
            doc1.type = 'RFX Requirements';
            doc1.sharingLogic = 'All Vendors';
            doc1.participantId = lstParticipant[4].Id;
            doc1.inserted = true;
            doc1.required = true;

            List<LWC2_DocumentToUpload_Sing.DocumentWrapper> lstDocumentWrapper = new List<LWC2_DocumentToUpload_Sing.DocumentWrapper>{doc1};
            Map<String, Object> mapResult = LWC2_DocumentToUpload_Sing.addDocuments(lstDocumentWrapper, lstSourcingEventRFI[2].Id);    
            
            lstSourcingEventRFI[2].Documents_Uploaded__c = 'Yes';
            lstSourcingEventRFI[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEventRFI[2].Publish_start_date_time__c = System.Today();
            lstSourcingEventRFI[2].Bid_Due_Date__c = System.Today().addMonths(1);
            update lstSourcingEventRFI[2];

            Integer size1 = [SELECT count() FROM ContentDocumentLink WHERE ContentDocumentId = :lstContentDocument[3].Id];

            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEventRFI[2].Id,
                Contact_Bidder__c = lstContact[5].id,
                Sing_Account__c = lstAccount[5].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                Negotiation_Round__c = lstRound[2].Id
            );
            insert bid;

            Integer size2 = [SELECT count() FROM ContentDocumentLink WHERE ContentDocumentId = :lstContentDocument[3].Id];
           // System.assertEquals(size1 + 1, size2);
            //AP02_sing_countJustificationDoc.dummyTest();
            test.stopTest();
        }
    }

    /*@isTest
    static void blockInsertionEventCompleted_Test(){
        system.runAs(testUser){
            
            test.startTest();
            
            lstContentDocument[0].Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
            lstContentDocument[1].Description = AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS;
            lstContentDocument[3].Description = AP_Constant.DOCUMENT_TYPE_RFX_RESULTS;
            lstContentDocument[4].Description = AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS;
        
            update lstContentDocument;

            lstSourcingEventRFI[2].Documents_Uploaded__c = 'Yes';
            lstSourcingEventRFI[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEventRFI[2].Publish_start_date_time__c = System.Today();
            lstSourcingEventRFI[2].Bid_Due_Date__c = System.Today().addMonths(1);
            update lstSourcingEventRFI[2];

            lstSourcingEventRFI[2].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_COMPLETED;
            update lstSourcingEventRFI[2];
            test.stopTest();
        }// An awardee
    }*/
}