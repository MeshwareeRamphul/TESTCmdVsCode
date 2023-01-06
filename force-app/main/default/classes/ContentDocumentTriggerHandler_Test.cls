@isTest
public without sharing class ContentDocumentTriggerHandler_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : ContentDocumentTriggerHandler_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for ContentDocumentTriggerHandler
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- xxx          xxx    1.0     Initial version
-- 07-JAN-2022  HSO    1.1     Increase coverage
--------------------------------------------------------------------------------------*/
    static user testUser;
    static user universignUser;
    static ContentWorkspace workspace;
    static User vUserPM;
    static User vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    //static Quartile__c vQuartile;
    //static Petal__c vDomain;
    //static Offer__c vOffer;
    static Product__c vProduct;
    static Contract__c vContract;

    static Account vAccount1;
    static  Account vEAccount1;
    static Contact vEntityContact1;
    //static Quartile__c vQuartile1;
    //static Petal__c vDomain1;
    //static Offer__c vOffer1;
    static Product__c vProduct1;
    static Contract__c vContract1;

    static List<Sourcing_Event__c> lstSourcingEvent;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocument> lstContentDocument;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static List<Account> lstAccount;
    static List<Contact> lstContact = new list<Contact>();
    static List<User> lstUser = new List<User>();
    static Map<String, RecordType> mapSE;
    static Map<String, RecordType> mapRT;
	
	static List<User> lstUserPortal = new List<User>();

    static Blob beforeblob;

    static{
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name = 'AXA GO France'].Id;

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.UserRoleId = userRoleId;
        testUser.PAD_BypassValidationRules__c = true;
        insert testUser;

        // universignUser = TestFactory.createUser('UsrUniversign',TestFactory.getProfileUniversignId(),true);
        // insert universignUser;
        
        System.runAs(testUser){
            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;   

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Quartile (business area)
            //vQuartile = AP05_TestDataFactory.createBusinessArea(testUser);

            //Petal (Domain)
            //vDomain = AP05_TestDataFactory.createDomain(vQuartile, testUser);

            //Offer
            //vOffer = AP05_TestDataFactory.createOffer(vDomain, testUser);
            
            //Product
            //vProduct = AP05_TestDataFactory.createProduct(null, vUserOO);

            //Contract
            vContract = AP05_TestDataFactory.createContract(null, vAccount, testUser, vEntityContact);  

            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');

            lstSourcingEvent = new List<Sourcing_Event__c>{
                new Sourcing_Event__c(
                    Description__c = 'test event 777',
                    Documents_Uploaded__c = 'No',
                    Event_start_date__c = System.Today(),
                    Event_End_date__c = System.Today().addMonths(1),
                    Bid_Due_Date__c = System.Today().addDays(5),
                    NDA_Sent__c = true,
                    NDA_Mandatory__c = true,
                    Sourcing_Status__c = AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS,
                    RecordTypeId = mapSE.get('RFP').id,
                    SharingLogic__c = 'Restrict access to my sourcing team',
                    ContractAlreadyGenerated__c = true
                )
            };

            insert lstSourcingEvent;
           
            beforeblob = Blob.valueOf('Unit Test Attachment Body');

            // ContentVersion cv = new ContentVersion();
            // cv.title = 'test title trigger';      
            // cv.PathOnClient = 'test';           
            // cv.VersionData = beforeblob;
            // insert cv;

            // ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
            // ContentDocumentLink contentlink = new ContentDocumentLink();
            // contentlink.LinkedEntityId = vContract.id;
            // contentlink.ShareType = 'I';
            // contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            // contentlink.Visibility = 'AllUsers'; 
            // insert contentlink;

            lstContentVersion = new List<ContentVersion>{
                new ContentVersion(Title='Doc1', PathOnClient='Doc1.jpg', VersionData=beforeblob, IsMajorVersion=true),
                new ContentVersion(Title='Doc2', PathOnClient='Doc2.jpg', VersionData=beforeblob, IsMajorVersion=true),
                new ContentVersion(Title='Doc3', PathOnClient='Doc3.jpg', VersionData=beforeblob, IsMajorVersion=true)
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];
            
            lstContentDocument = [SELECT Id, Title, LatestPublishedVersionId, Description FROM ContentDocument];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                new contentDocumentLink(ContentDocumentId=lstContentVersion[0].ContentDocumentId, LinkedEntityId=vContract.Id, ShareType='I', Visibility = 'AllUsers')
               //new contentDocumentLink(ContentDocumentId=lstContentVersion[1].ContentDocumentId, LinkedEntityId=lstSourcingEvent[0].Id, ShareType='I', Visibility = 'AllUsers')
            };
            insert lstContentDocumentLink;

            //Profile
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];

            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');

            // Account
            lstAccount = TestFactory.createAccount(5, mapRT.get('cTin_Parent_Supplier').id);

            // Contact
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.Email = 'test1jamesbrown@gmail.com';
            
            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.Email = 'test2kimjah@gmail.com';
            

            lstContact.add(con1);
            lstContact.add(con2);

            insert lstContact;

            lstUserPortal.add(TestFactory.createUser('Testuser1', profile.Id, true));
            
            lstUserPortal[0].ContactId = lstContact[0].Id;
            lstUserPortal[0].IsActive = true;

            insert lstUserPortal;
            
        }
    }
    
    @IsTest
    public static void testUpdateFiles(){
        System.runAs(testUser) {    
            List<ContentDocument> lstDocument = [SELECT Id, Title FROM ContentDocument];

            for(ContentDocument contentDoc : lstDocument){
                contentDoc.title = contentDoc.title + '***';
            }
            
            Test.StartTest();   
                try{
                    update lstDocument;
                }
                catch(DMLException e){
                    System.assert(e.getMessage().contains(System.Label.ErrorMessageForDocsName));
                }
            Test.StopTest();
        }

    }

    @IsTest
    public static void testUpdateFiles2(){
        System.runAs(testUser) {    
            List<ContentDocument> lstDocument = [SELECT Id, Title FROM ContentDocument];

            for(ContentDocument contentDoc : lstDocument){
                contentDoc.title = contentDoc.title + 'test';
                contentDoc.Description = 'RFX Results';
            }

            Test.StartTest();   
                update lstDocument;
            Test.StopTest();
        }

    }

    @IsTest
    public static void testUpdateFiles3(){
        System.runAs(lstUserPortal[0]) {  
            System.debug('## the current user is : ' + lstUserPortal[0].Name);  
            List<ContentDocument> lstDocument = [SELECT Id, Title FROM ContentDocument];

            for(ContentDocument contentDoc : lstDocument){
                contentDoc.title = contentDoc.title + 'test';
                contentDoc.Description = 'RFX Results';
            }

            Test.StartTest();   
                update lstDocument;
            Test.StopTest();
        }

    }

    @IsTest
    public static void testDeleteFiles(){
        System.runAs(testUser) { 
            List<ContentDocument> lstDocument = [SELECT Id, Title FROM ContentDocument];  

            Test.StartTest();  
                delete lstDocument;
            Test.StopTest();
        }
    }
}