@isTest
public with sharing class AP31_ManageFiles_Test {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : AP31_ManageFiles
-- - Author        : Spoon Consulting 
-- - Description   : test class for controller AP31_ManageFiles
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 08-AUG-2019  USA    1.0      Initial version
-- 22-JAN-2020  SGO    1.1      cTin - Rework + Insert / Delete Content distribution when content document link is inserted / deleted
--------------------------------------------------------------------------------------*/

    static String versionData='version'; 
    static ContentWorkspace workspace;

    static User usrAdmin;
    static User testAdminAuth;
    static List<User> lstUsers = new List<User>();
    static List<Contract__c> lstCtrs;
    static List<ContentVersion> lstCVs = new List<ContentVersion>();
    static List<ContentDistribution> lstContentDist = new List<ContentDistribution>();
    static List<contentDocumentLink> lstCDLs = new List<contentDocumentLink>();
    static List<ContentDocument> lstDocuments = new List<ContentDocument>();
    static List<contentDistribution> lstRetCDs = new List<contentDistribution>();
    static List<contentDistribution> lstRetCDeSign = new List<contentDistribution>();
    static List<eSignature__c> lstESigns = new List<eSignature__c>();

    static{
        usrAdmin = TestFactory.createUser('usrAdmin', TestFactory.getProfileAdminId(), true);
        lstUsers.add(usrAdmin);
        testAdminAuth = TestFactory.createUser('testAdmin', TestFactory.getProfileAdminId(), true);
        testAdminAuth.cTin_EntityLocalCode__c = AP_Constant.entityLocalCodeCORE;
        testAdminAuth.cTin_Universign__c = true;
        // Allin
        testAdminAuth.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
        lstUsers.add(testAdminAuth);
        insert lstUsers;

        System.runAs(testAdminAuth){
            lstCtrs = new List<Contract__c>{
                // Allin
                new Contract__c(RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(), name='opCo_ctr'),
                // cTin
                new Contract__c(RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId(), name='cTin_ctr'),
                new Contract__c(RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId(), name='cTin_ctr2')
            };
            insert lstCtrs;

            for (Integer i=0;i<3;i++){
                lstESigns.add(new eSignature__c(RecordTypeId=Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId(), name='eSign', Contract__c=lstCtrs[i].Id));
            }
            insert lstESigns;

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  

            for (Integer i=0;i<6;i++){
                lstCVs.add(new ContentVersion(Description = 'Descrip'+i, title = 'title_SOW',PathOnClient='test'+i+'.pdf', versionData = Blob.valueOf(versionData),IsMajorVersion =true));
            }
            insert lstCVs;

            List<ContentDistribution> lstCD = new List<ContentDistribution>();
            integer i=0;
            String recordId = '';
            for(ContentVersion cv: lstCVs){
                if(i<3)
                recordId= lstCtrs[i].Id;
                else
                recordId = lstESigns[i-3].Id;

                lstCD.add(new ContentDistribution(
                    Name = cv.Title,
                    ContentVersionId = cv.Id,
                    RelatedRecordId= recordId,
                    PreferencesAllowViewInBrowser= true,
                    PreferencesLinkLatestVersion=true,
                    PreferencesNotifyOnVisit=false,
                    PreferencesPasswordRequired=false,
                    PreferencesAllowOriginalDownload= true
                ));
                i++;
            }
            insert lstCD;
           
            lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            system.debug('**********contDoc '+lstDocuments.size());
            
        }
    }

    @IsTest
    static void testGeneratePublicURL(){

        System.runAs(testAdminAuth){
            Test.startTest();

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>();
            Integer i=0;
            String entityId = '';
            for(ContentDocument cd: lstDocuments){
                if(i<3)
                entityId= lstCtrs[i].Id;
                else
                entityId = lstESigns[i-3].Id;
                lstCDL.add(new contentDocumentLink(LinkedEntityId=entityId, ContentDocumentId=cd.Id));
                i++;
            }
            insert lstCDL;
                // System.debug('@@ lstCDLs '+ lstCDLs.size() + ' : ' + lstCDLs);

            Test.stopTest();

            lstRetCDs = [SELECT Id, DistributionPublicUrl,RelatedRecordId, ContentVersionId FROM contentDistribution WHERE RelatedRecordId in :lstCtrs];
            lstRetCDeSign = [SELECT Id, DistributionPublicUrl,RelatedRecordId, ContentVersionId FROM contentDistribution WHERE RelatedRecordId in :lstESigns];

            // System.debug('@@ lstRetCDs '+ lstRetCDs.size() + ' : ' + lstRetCDs);
            // System.debug('@@ lstRetCDeSign '+ lstRetCDeSign.size() + ' : ' + lstRetCDeSign);

          //  System.assertEquals(3, lstRetCDs.size());
           // System.assertEquals(3, lstRetCDeSign.size());
        }
    }

       @IsTest
    static void testDeleteContentDist(){

        System.runAs(testAdminAuth){
            Test.startTest();
            
                for (Integer i=0;i<3;i++){
                    // ctr
                    lstCDLs.add(new contentDocumentLink(LinkedEntityId=lstCtrs[i].Id, ContentDocumentId=lstDocuments[i].Id,ShareType='I'));
                }
                // eSign
                lstCDLs.add(new contentDocumentLink(LinkedEntityId=lstESigns[0].Id, ContentDocumentId=lstDocuments[3].Id,ShareType='I'));
                lstCDLs.add(new contentDocumentLink(LinkedEntityId=lstESigns[1].Id, ContentDocumentId=lstDocuments[4].Id,ShareType='I'));
                lstCDLs.add(new contentDocumentLink(LinkedEntityId=lstESigns[2].Id, ContentDocumentId=lstDocuments[5].Id,ShareType='I'));
                insert lstCDLs;
                // System.debug('@@ lstCDLs '+ lstCDLs.size() + ' : ' + lstCDLs);

                delete lstCDLs;

            Test.stopTest();

            lstRetCDs = [SELECT Id, DistributionPublicUrl,RelatedRecordId, ContentVersionId FROM contentDistribution WHERE RelatedRecordId in :lstCtrs];
            lstRetCDeSign = [SELECT Id, DistributionPublicUrl,RelatedRecordId, ContentVersionId FROM contentDistribution WHERE RelatedRecordId in :lstESigns];

            // System.debug('@@ lstRetCDs '+ lstRetCDs.size() + ' : ' + lstRetCDs);
            // System.debug('@@ lstRetCDeSign '+ lstRetCDeSign.size() + ' : ' + lstRetCDeSign);

            // Delete cTin ctr only, Do not delete Allin ctr
           // System.assertEquals(1, lstRetCDs.size());
           // System.assertEquals(0, lstRetCDeSign.size());
            
            try{ContentdocumentTriggerHandler.handleBeforeDelete(lstDocuments);}
            catch(Exception e){}
        }
    }
}