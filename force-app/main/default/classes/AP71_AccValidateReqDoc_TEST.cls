@isTest
public with sharing class AP71_AccValidateReqDoc_TEST {
    /* --------------------------------------------------------------------------------------
    -- - Name          : AP71_AccValidateReqDoc_TEST
    -- - Author        : AMA
    -- - Description   : test class for AP71_AccValidateReqDoc
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 27-MAY-2022  AMA    1.0     Initial version
    --------------------------------------------------------------------------------------*/
    static List<User> lstUser = new list<User>();
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static User testUser;
    static Set<ID> setAccId;
    static Set<ID> contentDocSet;
    
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
            
            Account vAccount = new Account();
            vAccount.Name = 'test acc';
            vAccount.OwnerId = lstUser[0].Id;
            vAccount.Account_Manager__c = lstUser[0].Id;
            vAccount.GIE_AXA_GS_Member__c = 'No';
            vAccount.Active__c = true;
            vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_MASTER_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
            vAccount.Delegation__c = 'No';
            vAccount.cTin_TOBA_needed__c = 'No';
            insert vAccount;

            setAccId = new Set<ID>{vAccount.id};
    
            
            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc0', PathOnClient='Doc0.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Account__c=vAccount.Id),
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Account__c=vAccount.Id),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=fileContentInBlob, IsMajorVersion=true, Account__c=vAccount.Id)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber, Account__c FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=lstContentVersion[0].Account__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstContentVersion[1].Account__c, ShareType='I'),
                new contentDocumentLink(ContentDocumentId=lstContentVersion[2].ContentDocumentId, LinkedEntityId=lstContentVersion[2].Account__c, ShareType='I')
            };
            insert lstContentDocumentLink;

            contentDocSet =new Set<ID>{
                lstContentDocumentLink[0].id,
                lstContentDocumentLink[1].id,
                lstContentDocumentLink[2].id
            };

        }
    }
    
    @isTest
    static void AccValidateReqDoc_test(){
        System.runAs(testUser){
            test.startTest();
                AP71_AccValidateReqDoc.checkTOBAUploaded(setAccId,contentDocSet,'insert');
            test.stopTest();
        }
    }
}