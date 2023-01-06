@isTest
public with sharing class LWC03_DocumentToUpload_cTin_TEST {
    /* --------------------------------------------------------------------------------------
    -- - Name          : LWC03_DocumentToUpload_cTin_TEST
    -- - Author        : AMA
    -- - Description   : test class for LWC03_DocumentToUpload_cTin
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 12-MAY-2022  AMA    1.0     Initial version
    --------------------------------------------------------------------------------------*/
    static Contract__c ctr =  new Contract__c();
    static List<User> lstUser = new list<User>();
    static ContentVersion ConVer = new ContentVersion();
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static LWC03_DocumentToUpload_cTin.DocumentWrapper docwrap, docwrap1, docwrap2;
    static User testUser;

    static{      
        for(integer i=0;i<3;i++){
            lstUser.add(TestFactory.createUsercTin('Testuser'+ i , UserInfo.getProfileId(), true));          
        }
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40;AP33';
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
            ctr = TestFactory.createContract(vAccount.Id, 'TestContract', 'Draft');
            insert ctr;
    
            
            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc0', PathOnClient='Doc0.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Contract__c=ctr.Id),
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Contract__c=ctr.Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.pdf', VersionData=fileContentInBlob, IsMajorVersion=true, Contract__c=ctr.Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber, Contract__c FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstContentVersion[0].Contract__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstContentVersion[1].Contract__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstContentVersion[2].Contract__c, ShareType='I')
            };
            insert lstContentDocumentLink;

            docwrap = new LWC03_DocumentToUpload_cTin.DocumentWrapper();
            docwrap.documentId = lstContentDocument[0].Id;
            docwrap.fileName = 'Test 0';
            docwrap.type = 'Internal files';

            docwrap1 = new LWC03_DocumentToUpload_cTin.DocumentWrapper();
            docwrap1.documentId = lstContentDocument[1].Id;
            docwrap1.fileName = 'Test 1';
            docwrap1.type = 'External files';

            docwrap2 = new LWC03_DocumentToUpload_cTin.DocumentWrapper();
            docwrap2.documentId = lstContentDocument[2].Id;
            docwrap2.fileName = 'Test 2';
            docwrap2.type = 'Internal files';
        }
    }

    @isTest
    static void getDocumentType_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC03_DocumentToUpload_cTin.getDocumentType(ctr.Id);
            test.stopTest();
            
            String prefixId = ('' + ctr.Id).substring(0, 3);
            String currentObject = '';
            for(Schema.SObjectType objectInstance : Schema.getGlobalDescribe().values()){
                if(objectInstance.getDescribe().getKeyPrefix() == prefixId){
                    currentObject = objectInstance.getDescribe().getName();
                }
            }
            //System.assertEquals(mapOfResult.get('currentObject'), currentObject);
        }
    }

    @isTest
    static void getAllDocuments_test(){
        System.runAs(testUser){
            test.startTest();
                map<String,Object> mapOfResult = LWC03_DocumentToUpload_cTin.getAllDocuments(ctr.Id);
            test.stopTest();

            //system.assertEquals(null, mapOfResult.get('data'));
        }
    }

    @isTest
    static void addDocument_test(){
        System.runAs(testUser){
            test.startTest();
                List<LWC03_DocumentToUpload_cTin.DocumentWrapper> lstDocumentWrapper = new List<LWC03_DocumentToUpload_cTin.DocumentWrapper>{docwrap};
                Map<String, Object> mapResult = LWC03_DocumentToUpload_cTin.addDocuments(lstDocumentWrapper, ctr.Id);
            test.stopTest();

            List<ContentDocumentLink> lstAllContentDocumentLink = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :ctr.Id];
            //System.assertEquals(3, lstAllContentDocumentLink.size());
        }
    }

    @isTest
    static void replaceDocument_test(){
        System.runAs(testUser){
            test.startTest();
                Map<String, Object> mapResult = LWC03_DocumentToUpload_cTin.replaceDocument(docwrap2, lstContentDocument[1].Id, ctr.Id);
            test.stopTest();

            LWC03_DocumentToUpload_cTin.DocumentWrapper newDocResult = (LWC03_DocumentToUpload_cTin.DocumentWrapper)mapResult.get('data');
        }
    }

    @isTest
    static void deleteDocumentSuccess_test(){
        System.runAs(testUser){
            test.startTest();
                List<Id> lstContentDocumentId = new List<Id>{lstContentDocument[0].Id};
                String result = LWC03_DocumentToUpload_cTin.deleteDocument(lstContentDocumentId);
            test.stopTest();

            //System.assertEquals('success', result);
            
            List<ContentDocument> lstDeletedContentDocument = [SELECT Id FROM ContentDocument WHERE Id = :lstContentDocument[0].Id];
            //System.assertEquals(0, lstDeletedContentDocument.size());

            List<ContentDocument> lstAllContentDocument = [SELECT Id FROM ContentDocument];
            //System.assertEquals(2, lstAllContentDocument.size());
        }
    }

}