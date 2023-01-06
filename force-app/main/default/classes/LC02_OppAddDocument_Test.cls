@isTest
private class LC02_OppAddDocument_Test {
/*
----------------------------------------------------------------------
-- - Name          : LC02_OppAddDocument_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC02_OppAddDocument
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 24-APRIL-2019   ZHE    1.0    Intitial version
-- 23-AUG-2019     SGO    2.0    Replaced hardcoded values
-- 27-AUG-2019     SGO    3.0    Enabled for lightning user - company
-- 23-SEP-2019     SGO    4.0    Workspace added
----------------------------------------------------------------------
**********************************************************************
*/
	static user testUser;
    static User vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static opportunity vOpp;
    static opportunity vOpp2;
    static opportunity vOpp3;
    static list<Opportunity> lstOpp = new List<Opportunity>();
    static Blob beforeblob;
    static String description;
    static ContentWorkspace workspace;

    static{
        testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert testUser;
        system.runAs(testUser){

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            //vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            vOpp = new Opportunity();
			vOpp.AccountId = vEAccount.Id;
			vOpp.StageName = AP_Constant.STAGE_LEADS_GATHERING;
			vOpp.closeDate = Datetime.now().date();
			vOpp.Name = 'OptyNoCategory';
			lstOpp.add(vOpp);

            vOpp2 = new Opportunity();
            vOpp2.AccountId = vEAccount.Id;
            vOpp2.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpp2.closeDate = Datetime.now().date();
            vOpp2.Name = 'OptyProject';
            vOpp2.Category__c = Label.OptyCategory_Project; //AP_Constant.CAT_BAU;
            vOpp2.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK; //Hong kong to override required docs
            lstOpp.add(vOpp2);

            vOpp3 = new Opportunity();
            vOpp3.AccountId = vEAccount.Id;
            vOpp3.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpp3.closeDate = Datetime.now().date();
            vOpp3.Name = 'OptyProject';
            vOpp3.Category__c = Label.OptyCategory_Project;
            lstOpp.add(vOpp3);
            insert lstOpp;

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  


            beforeblob = Blob.valueOf('Unit Test Attachment Body');
		}
	}
	
	@IsTest
    public static void testLoadDataRequiredDoc(){
        System.runAs(testUser) {
            test.StartTest();

                ContentVersion cv = new ContentVersion();
                cv.title = 'test content trigger';      
                cv.PathOnClient = 'test';           
                cv.VersionData = beforeblob;          
                insert cv;         

                ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = lstOpp[0].id;
                contentlink.ShareType = 'I';
                contentlink.ContentDocumentId = testcontent.ContentDocumentId;
                contentlink.Visibility = 'AllUsers'; 
                insert contentlink;

                list<LC02_OppAddDocument.DocumentWrapper> resultWrap = LC02_OppAddDocument.loadData(lstOpp[0].Id);
            test.StopTest();

//            System.assertEquals(null, resultWrap[0].required);
//            System.assertEquals(null, resultWrap[1].required);
//            System.assertEquals(null, resultWrap[2].required);
        }
    }
    @IsTest
    public static void testLoadDataOptionalDoc(){
        System.runAs(testUser) {
            test.StartTest();

                ContentVersion cv = new ContentVersion();
                cv.title = 'test content trigger';      
                cv.PathOnClient = 'test';           
                cv.VersionData = beforeblob;          
                insert cv;         

                ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = lstOpp[1].id;
                contentlink.ShareType = 'I';
                contentlink.ContentDocumentId = testcontent.ContentDocumentId;
                contentlink.Visibility = 'AllUsers'; 
                insert contentlink;

                list<LC02_OppAddDocument.DocumentWrapper> resultWrap = LC02_OppAddDocument.loadData(lstOpp[1].Id);
            test.StopTest();

            System.assertEquals(false, resultWrap[0].required);
            System.assertEquals(false, resultWrap[1].required);
            System.assertEquals(false, resultWrap[2].required);
        }
    }
    @IsTest
    public static void testLoadDataOppProject(){
        System.runAs(testUser) {
            test.StartTest();

                ContentVersion cv = new ContentVersion();
                cv.title = 'test content trigger';      
                cv.PathOnClient ='test';           
                cv.VersionData = beforeblob;          
                insert cv;         

                ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = lstOpp[2].id;
                contentlink.ShareType = 'I';
                contentlink.ContentDocumentId = testcontent.ContentDocumentId;
                contentlink.Visibility = 'AllUsers'; 
                insert contentlink;

                list<LC02_OppAddDocument.DocumentWrapper> resultWrap = LC02_OppAddDocument.loadData(lstOpp[2].Id);
            test.StopTest();

//            System.assertEquals(true, resultWrap[0].required);
//            System.assertEquals(true, resultWrap[1].required);
//            System.assertEquals(true, resultWrap[2].required);
        }
    }
    @IsTest
    public static void testUpdateFiles(){
        System.runAs(testUser) {
            test.StartTest();

                ContentVersion cv = new ContentVersion();
                cv.title = 'test content trigger';      
                cv.PathOnClient = 'test';           
                cv.VersionData = beforeblob;          
                insert cv;         

                ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = lstOpp[0].id;
                contentlink.ShareType = 'I';
                contentlink.ContentDocumentId = testcontent.ContentDocumentId;
                contentlink.Visibility = 'AllUsers'; 
                insert contentlink;

                List<ContentDocument> lstDocument = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
                List<Id> lstDocId = new List<Id>();
                for(ContentDocument contentDoc : lstDocument){
                    lstDocId.add(contentDoc.Id);
                }

                LC02_OppAddDocument.UpdateFiles(lstDocId[0], 'PAS', lstOpp[0].Id);

                try{
                    description = 'Some string which is longer than 1000 characters: 4u6OvQPLeJkVTWAId27Wx1YEhcmKdvuKlDSQr9A6vbEjdpvehfoLEfgOs1573eiys2nfD2eMBadzTNtaHZ3SmeeU0UZTdQgLcIVioCegACvryRqxRKXsfgiPduQ7faRAFCihNgsKNmZbI2sAhsNdBMnfgMVb51tTuY4drgXshdtwuGpGBCzLHapGwHxxl024NkalPkY441G7J6Y5IwfJX623vJPoIwDdzTElPcwOVKeELrSTzqSCgnSmGKgrThrfwWwLK7Be22cERWA86clc2ENBnGLl7TmbM4rExRWRVyjlz86Yi2aCRUqBcs8mZcqCUHv78PVrMUsAkhiHxGJjj5A8G8fkvgYHPoioVRBxNlXfxEwfn2CBptlDqzGYOGCIWJhRJG6iymXaAH9Rqo0svy4EmeUIGo2FWO2q17KkrTpgwS71Bs5JbYKJ6Mr5H14KKZfTwrPYkU0WjNwazyn1aVguzf4Dgkpy6ysmgVjAX79OuRFhoeaqwKPnir4JgbXwxr3pvspaRvHvB6opGDguucgI89AqTiv9apMlJFh9mEuI48av3nLLGYZpLh4I6zZygXASZKQpfEHubWxpcP2lP3VXri3Bn90ngw4wRelrSwYz9gVWDT8TDOIoNGx9kgXOAb7K8NRhvzO9jkvv4MmWaidgGQ1px83BW46JyKaKjNzMqOcje63e8QfN5ujkGxvmP8N0BsuWioo2ZiwgHEhlKj7RGTM1j44HHkNegmqEfE0gO4rosHLXwMkhhlNvkKq1GZIz37EYGl6wpYfaMRXMFFPDw0ZqGPcnljuLQxtKGqstvbOlpEhu865PVvTkjecboZCfQIpHLsfRKPfH1brgdLPGpPLFjWv3O6BC5Imie5GDTKndKpAGdrTJ2etiboaMZ9ztgNyslCUcvWTiTUuyVAyENSEI071krGjw94nNzrwfgVHSObnZZJKnuERckclXC9LeYrw1SuCWyNHv98Am0nTyeB2Q298WYOyFmJQ0A';
                    LC02_OppAddDocument.UpdateFiles(lstDocId[0], description, lstOpp[0].Id);
                }
                catch(DMLException e){
                    System.assert(e.getMessage().contains('Exception'));
                }
                
            test.StopTest();

            ContentDocument contentDoc = [select id,description from ContentDocument where Id = :lstDocId[0]];
            system.assertEquals('PAS', contentDoc.description);
        }

    }

    
}