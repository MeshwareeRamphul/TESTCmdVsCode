@isTest
public with sharing class AP03_Opportunities_Test {
    
    Static User testUser;
    Static List<Opportunity> lstOpps;
    Static List<Opportunity> lstUpdOpps = new List<Opportunity>();
    static Opportunity opp1;
    static Opportunity opp2;
    static Opportunity opp3;
    static List<RequiredDocuments__mdt> lstDocsReq;
    
    static Blob beforeblob;
    static ContentWorkspace workspace;
    
    static ContentDocumentLink contentlink ;
    static ContentDocumentLink cdl ;
    static ContentDocumentLink cdl2 ;
    static ContentDocumentLink cdl3 ;
    
    static List<ContentDocument> documents;
    static ContentDocument cd;
    static ContentDocument cd1;
    static ContentDocument cd2;
    static ContentDocument cd3;
    static List<contentDocumentLink> lstCDLs  = new List<contentDocumentLink>();
    
    static Attachment att;
    static Attachment att1;
    static Attachment att2;
    static Attachment att3;
    static List<Attachment> lstAtts = new  List<Attachment>();
    static List<ContentDocument> lstCDs;
    
    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
        
        System.runAs(testUser){
            
            lstOpps = new List<Opportunity>{
                opp1 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                       Name = 'opp1', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today()),
                    opp2 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                           Name = 'opp2', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today()),
                    opp3 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                           Name = 'opp3', Category__c = Label.OptyCategory_Project, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today())
                    };
                        insert lstOpps;
            
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  
            
            beforeblob = Blob.valueOf('Unit Test Attachment Body');
        }
    }
    
    
    @isTest
    static void handleBeforeUpdateTest(){
        System.runAs(testUser){
            Test.startTest();
            
            ContentVersion contentVersion = new ContentVersion(
                Title = 'PAS',
                PathOnClient = 'Doc2.jpg',
                VersionData = Blob.valueOf('PAS'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            ContentVersion contentVersion1 = new ContentVersion(
                Title = 'CSH',
                PathOnClient = 'Doc3.jpg',
                VersionData = Blob.valueOf('CSH'),
                IsMajorVersion = true
            );
            insert contentVersion1;    
            ContentVersion contentVersion2 = new ContentVersion(
                Title = 'CVA',
                PathOnClient = 'Doc4.jpg',
                VersionData = Blob.valueOf('CVA'),
                IsMajorVersion = true
            );
            insert contentVersion2;    
            ContentVersion contentVersion3 = new ContentVersion(
                Title = 'ECA',
                PathOnClient = 'Doc1.jpg',
                VersionData = Blob.valueOf('ECA'),
                IsMajorVersion = true
            );
            insert contentVersion3; 
            
            
            /*system.debug('@@@1 contentVersion1.ContentDocumentId : ' + contentVersion1.ContentDocumentId);
            lstCDs = new List<ContentDocument>{
            cd = new ContentDocument(Id=contentVersion1.ContentDocumentId),
            cd1 = new ContentDocument(Id=contentVersion2.ContentDocumentId),
            cd2 = new ContentDocument(Id=contentVersion3.ContentDocumentId),
            cd3 = new ContentDocument(Id=contentVersion.ContentDocumentId)
            };*/
            
            documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            System.debug('@@@1 documents' + documents);
            System.debug('SELECT cdl doc 1: '+[SELECT ContentDocumentId, LinkedEntityId, Id FROM ContentDocumentLink WHERE ContentDocumentId = :documents[0].Id ]);
            
            lstCDLs = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[3].Id,ShareType='I'),
                    
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[3].Id,ShareType='I'),
                    
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[3].Id,ShareType='I')
                    };
                        insert lstCDLs;
            
            lstOpps = [SELECT Id, Name from Opportunity where Id = :opp1.Id OR Id = :opp2.Id OR Id = :opp3.Id];
            
            Map<Id,Id> mapDocEntity = new Map<Id,Id>();
            for (ContentDocumentLink cdl :lstCDLs){
                if (String.valueOf(cdl.LinkedEntityId).startsWith('006')){
                    mapDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
            System.debug('@@@ mapDocEntity ' + mapDocEntity);
            
            List<ContentDistribution> lstContentDistribution = new List<ContentDistribution>();
            for (ContentVersion cv: [SELECT Id, Title,ContentDocument.title,contentDocumentId from ContentVersion Where Id = :contentVersion.Id OR Id = :contentVersion1.Id OR Id = :contentVersion2.Id OR Id = :contentVersion3.Id ] ){
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.contentDocument.title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowViewInBrowser= true;
                cd.PreferencesLinkLatestVersion=true;
                cd.PreferencesNotifyOnVisit=false;
                cd.PreferencesPasswordRequired=false;
                cd.PreferencesAllowOriginalDownload= true;
                cd.RelatedRecordId = mapDocEntity.get(cv.contentDocumentId);
                lstContentDistribution.add(cd);
            }
            
            System.debug('@@@ before insert lstContentDistribution: ' + lstContentDistribution);
            insert lstContentDistribution;
            System.debug('@@@ after insert lstContentDistribution: ' + lstContentDistribution);
            
            System.debug('@@@ before update lstOpps: ' + lstOpps);
            
            for (Opportunity opp : lstOpps){
                System.debug('@@@ SELECT 1 ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id ]);
                
                att = new Attachment(description='PAS', ParentId= opp.Id, Name='PAS',Body=beforeblob);
                att1 = new Attachment(description='CSH', ParentId= opp.Id, Name='CSH',Body=beforeblob);
                att2 = new Attachment(description='CVA', ParentId= opp.Id, Name='CVA',Body=beforeblob);
                att3 = new Attachment(description='ECA', ParentId= opp.Id, Name='ECA',Body=beforeblob);
                lstAtts.add(att);
                lstAtts.add(att1);
                lstAtts.add(att2);
                lstAtts.add(att3);
                
                System.debug('@@@ SELECT 2 ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id ]);
                
                opp.StageName = AP_CONSTANT.STAGE_QUALIFY_ALIGN;
                //System.debug('@@@ Opp after add doc: ' + opp);
                
                lstUpdOpps.add(opp);
            }
            
            if (lstAtts.size() > 0 ){
                insert lstAtts;
            }
            
            if (lstUpdOpps.size() > 0 ){
                try{
                    update lstUpdOpps;   
                }catch(Exception e){
                    System.Assert(e.getMessage().contains(System.Label.Attachment_MissingDocumentTrigger));
                }
            }
            
            Test.stopTest();
        }
    }
    
    
    @IsTest
    static void handleBeforeUpdateTest_Lgt(){
        System.runAs(testUser){
            AP_Constant.themeLightning = true;
            Test.startTest();
            
            ContentVersion contentVersion = new ContentVersion(
                Title = 'PAS',
                PathOnClient = 'Doc2.jpg',
                VersionData = Blob.valueOf('PAS'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            ContentVersion contentVersion1 = new ContentVersion(
                Title = 'CSH',
                PathOnClient = 'Doc3.jpg',
                VersionData = Blob.valueOf('CSH'),
                IsMajorVersion = true
            );
            insert contentVersion1;    
            ContentVersion contentVersion2 = new ContentVersion(
                Title = 'CVA',
                PathOnClient = 'Doc4.jpg',
                VersionData = Blob.valueOf('CVA'),
                IsMajorVersion = true
            );
            insert contentVersion2;    
            ContentVersion contentVersion3 = new ContentVersion(
                Title = 'ECA',
                PathOnClient = 'Doc1.jpg',
                VersionData = Blob.valueOf('ECA'),
                IsMajorVersion = true
            );
            insert contentVersion3; 
            lstOpps = [SELECT Id, Name from Opportunity where Id = :opp1.Id OR Id = :opp2.Id OR Id = :opp3.Id];
            
            documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            System.debug('@@@ documents' + documents);
            System.debug('SELECT cdl doc 1: '+[SELECT ContentDocumentId, LinkedEntityId, Id FROM ContentDocumentLink WHERE ContentDocumentId = :documents[0].Id ]);
            
            lstCDLs = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp1.Id ,ContentDocumentId=documents[3].Id,ShareType='I'),
                    
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp2.Id ,ContentDocumentId=documents[3].Id,ShareType='I'),
                    
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[0].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[1].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[2].Id,ShareType='I'),
                    new contentDocumentLink(LinkedEntityId = opp3.Id ,ContentDocumentId=documents[3].Id,ShareType='I')
                    
                    };
                        
                        //insert lstCDLs;
                        
                        lstOpps = [SELECT Id, Name from Opportunity where Id = :opp1.Id OR Id = :opp2.Id OR Id = :opp3.Id];
            
            Map<Id,Id> mapDocEntity = new Map<Id,Id>();
            for (ContentDocumentLink cdl :lstCDLs){
                if (String.valueOf(cdl.LinkedEntityId).startsWith('006')){
                    mapDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
            List<ContentDistribution> lstContentDistribution = new List<ContentDistribution>();
            for (ContentVersion cv: [SELECT Id, Title,ContentDocument.title,contentDocumentId from ContentVersion Where Id = :contentVersion.Id OR Id = :contentVersion1.Id OR Id = :contentVersion2.Id OR Id = :contentVersion3.Id ] ){
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.contentDocument.title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowViewInBrowser= true;
                cd.PreferencesLinkLatestVersion=true;
                cd.PreferencesNotifyOnVisit=false;
                cd.PreferencesPasswordRequired=false;
                cd.PreferencesAllowOriginalDownload= true;
                cd.RelatedRecordId = mapDocEntity.get(cv.contentDocumentId);
                lstContentDistribution.add(cd);
            }
            
            System.debug('@@@ before insert lstContentDistribution: ' + lstContentDistribution);
            insert lstContentDistribution;
            System.debug('@@@ after insert lstContentDistribution: ' + lstContentDistribution);
            
            System.debug('@@@ before update lstOpps: ' + lstOpps);
            System.debug('@@@ SELECT : ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :documents[0].Id ]);
            
            for (Opportunity opp : lstOpps){
                System.debug('@@@ SELECT : ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id ]);
                
                //                    opp.StageName = AP_CONSTANT.STAGE_CONTRACTING;
                System.debug('@@@ Opp after add doc: ' + opp);
                
                lstUpdOpps.add(opp);
            }
            
            if (lstUpdOpps.size() > 0 ){
                System.debug('@@@ SELECT 1 confirm : ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstOpps[0].Id ]);
                System.debug('@@@ SELECT 2 confirm : ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstOpps[1].Id ]);
                System.debug('@@@ SELECT 3 confirm : ' + [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstOpps[2].Id ]);
                update lstUpdOpps;
            }
            
            Test.stopTest();
        } 
    }
    
    
    @isTest
    static void changeLastStage_Test(){
        System.runAs(testUser){
            Test.startTest();
            for(Opportunity opp: lstOpps){
                opp.Category__c = Label.OptyCategory_BAU;
                opp.StageName = AP_Constant.STAGE_QUALIFY_ALIGN;
            }
            update lstOpps;
            Test.stopTest();
        }
    }
}