/**
 * @description       : 
 * @author            : SCHSO
 * @group             : 
 * @last modified on  : 12-05-2021
 * @last modified by  : SCHSO
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   12-03-2021   SCHSO   Initial Version
 * 1.1   02-03-2022   ARA   SP-03491
**/
@isTest
public with sharing class VFC_ValidateParticipation_TEST {
    public VFC_ValidateParticipation_TEST() {}

    static User testUser;
    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<Bidder__c> lstParticipant;
    static List<Negotiation_Round__c> lstRound;
    static List<Account> lstAccount, lstAccount2;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static Account supplier1;
    static list<Contact> lstContact=new list<Contact>();
    
	static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        
        System.runAs(testUser){
            
            Map<String, RecordType> mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            Map<String, RecordType> mapContactRT = AP_Constant.getRecordTypes('Contact');
            Map<String, RecordType> mapAccountRT = AP_Constant.getRecordTypes('Account');
            
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
            con1.Email = 'hasitinaraholdina@gmail.com';

            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'hasitinaraholdina@gmail.com';

            lstContact.add(con1);
            lstContact.add(con2);
            insert lstContact;


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
                    Round_Status__c = 'Cancelled'
                )
            };

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
        }
    }

    @isTest
    static void acceptTest(){
        ApexPages.currentPage().getParameters().put('id', lstParticipant[0].Id);
        System.runAs(testUser){
            Test.startTest();
            VFC_ValidateParticipation vp = new VFC_ValidateParticipation(); 
            vp.accept();
            Test.stopTest();
        }
    }

    // 02-03-2022   ARA   SP-03491
    @isTest
    static void acceptWhenPublishedTest(){
        ApexPages.currentPage().getParameters().put('id', lstParticipant[0].Id);
        System.runAs(testUser){
            Test.startTest();
            lstSourcingEvent[0].Documents_Uploaded__c = 'Yes';
            lstSourcingEvent[0].Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED;
            update lstSourcingEvent;

            VFC_ValidateParticipation vp = new VFC_ValidateParticipation(); 
            vp.accept();
            Test.stopTest();
        }
    }

    @isTest
    static void declineTest(){
        ApexPages.currentPage().getParameters().put('id', lstParticipant[0].Id);
        System.runAs(testUser){
            Test.startTest();
            VFC_ValidateParticipation vp = new VFC_ValidateParticipation(); 
            vp.decline();
            Test.stopTest();
        }
    }
}