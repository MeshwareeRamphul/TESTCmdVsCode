/**
 * @description       : 
 * @author            : SCHSO
 * @group             : 
 * @last modified on  : 12-22-2021
 * @last modified by  : SCHSO
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   12-22-2021   SCHSO   Initial Version
 * 1.1   01-04-2022   MBE     Rework
**/
@isTest
public class AP03_Sing_BlockEventCompletion_Test {
    Static User testUser;
    Static List<Sourcing_Event__c> lstSourcingEvent;
    Static List<Bidder__c> lstParticipant;
    Static List<Negotiation_Round__c> lstRound;
    Static List<Account> lstAccount, lstAccount2;
    Static Account supplier1;
    Static list<Contact> lstContact=new list<Contact>();
    Static List<ContentVersion> lstContentVersion;
    Static List<ContentDocument> lstContentDocument;
    Static List<ContentDocumentLink> lstContentDocumentLink;
    Static String fileContent = 'Test data';
    Static Blob fileContentInBlob = Blob.valueOf(fileContent);
    Static Map<String, RecordType> mapSE = new Map<String, RecordType>();
	Static Map<String, RecordType> mapRT = new Map<String, RecordType>();
    Static Map<String, RecordType> mapContactRT = new Map<String, RecordType>();

    static{ 
        testUser = TestFactory.createUser('UsrAdmin', TestFactory.getProfileAdminId(), true);
        insert testUser;

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

            //Sourcing Event RFI
            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event 01',
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
                    Description__c = 'test event 02',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    Legal_Entity__c = lstAccount2[1].Id,
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFI').id
                ),
                new Sourcing_Event__c(
                    Description__c = 'test event 03',
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
                    Round_Status__c = 'Cancelled'
                ),
                new Negotiation_Round__c(
                    Sourcing_Event__c = lstSourcingEvent[1].Id,
                    Sing_NotifyParticipants__c = true,
                    Sing_Round_Bid_Due_Date__c = System.Today().addMonths(2),
                    Round_Start_Date__c = System.Today().addDays(10),
                    Round_Status__c = 'Cancelled'
                ),
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
                    Round_Status__c = 'Cancelled'
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
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[2].Id
                ),
                new Bidder__c(
                    Sourcing_Event__c = lstSourcingEvent[0].Id,
                    Contact_Bidder__c = lstContact[3].id,
                    Sing_Account__c = lstAccount[1].id,
                    Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED,
                    Negotiation_Round__c = lstRound[2].Id
                )
            };
            insert lstParticipant;
            
            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Negotiation_Round__c=lstRound[0].Id),
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
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstSourcingEvent[1].Id, ShareType='I')
            };
            insert lstContentDocumentLink;
        }
    }  

    @isTest
    static void errorParticipantSignedNDA_Test(){
        System.runAs(testUser){
            Test.startTest();
                try{
                    for(Bidder__c participant : lstParticipant){
                        participant.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED;
                    }
                    update lstParticipant;

                    for(Sourcing_Event__c se : lstSourcingEvent){
                        se.Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
                    }

                    lstSourcingEvent[0].NDA_Mandatory__c = true;
                    update lstSourcingEvent;
                }catch(Exception ex){
                    System.assert(ex.getMessage().contains(System.Label.AP03_Sing_ErrorParticipantSignedNDA));                  
                }
            Test.stopTest();
        }
    }

    @isTest
    static void errorCheckDocumentBeforeComplete_Test(){
        System.runAs(testUser){
            Test.startTest();
                try{
                    for(Bidder__c participant : lstParticipant){
                        participant.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED;
                    }
                    update lstParticipant;

                    for(Sourcing_Event__c se : lstSourcingEvent){
                        se.Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_COMPLETED;
                    }

                    update lstSourcingEvent;
                }catch(Exception ex){
                    System.assert(ex.getMessage().contains(System.Label.AP03_Sing_ErrorRequiredDocOnComplete));                  
                }
            Test.stopTest();
        }
    }

    @isTest
    static void errorCheckUploadedDocument_Test(){
        System.runAs(testUser){
            Test.startTest();
                try{
                    for(Sourcing_Event__c se : lstSourcingEvent){
                        se.Documents_Uploaded__c = 'Yes';
                    }
                    update lstSourcingEvent;
                }catch(Exception ex){
                    System.assert(ex.getMessage().contains(System.Label.AP03_Sing_ErrorNoDocumentUploaded));                  
                }
            Test.stopTest();
        }
    }
}