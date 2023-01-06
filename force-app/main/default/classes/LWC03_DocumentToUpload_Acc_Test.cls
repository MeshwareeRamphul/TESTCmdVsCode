@isTest
public with sharing class LWC03_DocumentToUpload_Acc_Test {
        /* --------------------------------------------------------------------------------------
    -- - Name          : LWC03_DocumentToUpload_Acc_Test
    -- - Author        : AMA
    -- - Description   : test class for LWC03_DocumentToUpload_Acc
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 21-JUN-2022  AMA    1.0     Initial version
    --------------------------------------------------------------------------------------*/
    static account acc =  new account();
    static List<User> lstUser = new list<User>();
    static ContentVersion ConVer = new ContentVersion();
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static LWC03_DocumentToUpload_Acc.DocumentWrapper docwrap, docwrap1, docwrap2;
    static User testUser;

    static{      
        for(integer i=0;i<3;i++){
            lstUser.add(TestFactory.createUsercTin('Testuser'+ i , UserInfo.getProfileId(), true));          
        }
        insert lstUser;

        //lstUser[0].PAD_BypassTrigger__c = 'AP40;AP25';
        lstUser[0].PAD_BypassValidationRules__c =true;
        //lstUser[0].cTin_Universign__c = true;
        update lstUser;
        testUser = lstUser[0];


        System.runAs(testUser){
            // Create the customer (aka entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(lstUser[0]);
            // Create the entity account
            Account vEAccount = AP05_TestDataFactory.createEntityAccount(lstUser[0]);

            //create contract
            acc = vAccount;
            
            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc0', PathOnClient='Doc0.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, account__c=acc.Id),
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, account__c=acc.Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, account__c=acc.Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber, account__c FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstContentVersion[0].account__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstContentVersion[1].account__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstContentVersion[2].account__c, ShareType='I')
            };
            insert lstContentDocumentLink;

            docwrap = new LWC03_DocumentToUpload_Acc.DocumentWrapper();
            docwrap.documentId = lstContentDocument[0].Id;
            docwrap.fileName = 'Test 0';
            docwrap.type = 'Internal files';

            docwrap1 = new LWC03_DocumentToUpload_Acc.DocumentWrapper();
            docwrap1.documentId = lstContentDocument[1].Id;
            docwrap1.fileName = 'Test 1';
            docwrap1.type = 'External files';

            docwrap2 = new LWC03_DocumentToUpload_Acc.DocumentWrapper();
            docwrap2.documentId = lstContentDocument[2].Id;
            docwrap2.fileName = 'Test 2';
            docwrap2.type = 'Internal files';
        }
    }

    @isTest
    static void getDocumentType_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC03_DocumentToUpload_Acc.getDocumentType(acc.Id);
            test.stopTest();
        }
    }

    @isTest
    static void getAllDocuments_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC03_DocumentToUpload_Acc.getAllDocuments(acc.Id);
            test.stopTest();
        }
    }

    @isTest
    static void addDocument_test(){
        System.runAs(testUser){
            test.startTest();
                List<LWC03_DocumentToUpload_Acc.DocumentWrapper> lstDocumentWrapper = new List<LWC03_DocumentToUpload_Acc.DocumentWrapper>{docwrap};
                Map<String, Object> mapResult = LWC03_DocumentToUpload_Acc.addDocuments(lstDocumentWrapper, acc.Id);
            test.stopTest();
        }
    }

    @isTest
    static void replaceDocument_test(){
        System.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LWC03_DocumentToUpload_Acc.replaceDocument(docwrap2, lstContentDocument[1].Id, acc.Id);
            test.stopTest();
        }
    }

    @isTest
    static void deleteDocumentSuccess_test(){
        System.runAs(testUser){
            test.startTest();
                List<Id> lstContentDocumentId = new List<Id>{lstContentDocument[0].Id};
                String result = LWC03_DocumentToUpload_Acc.deleteDocument(lstContentDocumentId);
            test.stopTest();
        }
    }
}