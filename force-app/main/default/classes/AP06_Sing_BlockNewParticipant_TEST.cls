@isTest
public class AP06_Sing_BlockNewParticipant_TEST {
/*----------------------------------------------------------------------
-- - Name          : AP06_Sing_BlockNewParticipant_TEST
-- - Author        : Spoon
-- - Description   : Test Class for AP06_Sing_BlockNewParticipant
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 14-MAR-2022  ARA  1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUser;
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
    
    static{     
        testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);

        
        insert testUser;
        
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

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            lstContact.add(con4);
            insert lstContact;

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
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    Sing_Requesting_Owner_Entity__c = '1000 - AXA Investment Managers',
                    RecordTypeId = mapSE.get('RFI').id
                )
            };
            insert lstSourcingEventRFI;            

            //Negotiation Round
            lstRound = new List<Negotiation_Round__c>{
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
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
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                    Contact_Bidder__c = lstContact[1].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    Negotiation_Round__c = lstRound[0].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                    Contact_Bidder__c = lstContact[2].id,
                    Sing_Account__c = lstAccount[0].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED,
                    Negotiation_Round__c = lstRound[0].Id
                )
            };
            insert lstParticipant;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id)
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
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEventRFI[0].Id, ShareType='I')
            };
            insert lstContentDocumentLink;
        }
        }


    @isTest
    static void addParticipantToRound_Test(){
        system.runAs(testUser){
            test.startTest();
                
            
            lstSourcingEventRFI[0].Documents_Uploaded__c = 'Yes';
            lstSourcingEventRFI[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            lstSourcingEventRFI[0].Publish_start_date_time__c = System.Today();
            lstSourcingEventRFI[0].Bid_Due_Date__c = System.Today().addMonths(1);
            update lstSourcingEventRFI;
            
            Bidder__c bid = new Bidder__c(
                Sourcing_Event__c = lstSourcingEventRFI[0].Id,
                Contact_Bidder__c = lstContact[2].id,
                Sing_Account__c = lstAccount[0].id,
                Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED,
                NDA_Signed__c = true,
                Negotiation_Round__c = lstRound[0].Id
            );
            try{
                insert bid;
            }
            catch(Exception e){
                system.assert(e.getMessage().contains(System.Label.AP06_Sing_DuplicateVendor));
            }
            test.stopTest();
        
        }
    }

    @isTest
    static void eliminateParticipants_Test(){
        system.runAs(testUser){
            test.startTest();
            lstSourcingEventRFI[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_CANCELLED;
            update lstSourcingEventRFI;
            test.stopTest();
        }
    }
}