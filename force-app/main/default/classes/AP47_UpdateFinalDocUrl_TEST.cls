@IsTest
public class AP47_UpdateFinalDocUrl_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP47_UpdateFinalDocUrl_TEST
-- - Author        : Spoon
-- - Description   : Test class for AP47_UpdateFinalDocUrl
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 13-APR-2020  MRA 1.0     UAT Ticket : SP-00190
*************************************************************************************/

    static Contract__c vContract = new Contract__c();
    static Contract__c vContractin = new Contract__c();
    static List<Account> lstSuppliers;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static List<ContentDocument> lstDocuments = new List<ContentDocument>();
    static Map<string,Id> mapAcctRecordTypes;
    static Account supplier;
    static Account AxaAcc;
    static Contact AxaREP;
    static Contact AxaSUP;
    static cTin_Entity__c entity;
    static Map<String,ID> MapContactRT = new Map<String,ID>(); 
    static Map<String,ID> MapAccRT = new Map<String,ID>(); 	
    static User user00 = TestFactory.createUser('Testuser00' , UserInfo.getProfileId(), true);
    
    @IsTest
    static void testGenerateDocURL(){
        insert user00;
        system.runAs(user00){
            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(user00);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(user00);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            vProduct = AP05_TestDataFactory.createProduct(user00);                                             
            
            //lstContract.add(AP05_TestDataFactory.createContractAdmin('Test 356 v21', vProduct, vAccount, user00, vEntityContact));
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, user00, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false); 
            insert vContract;

            List<ContentVersion> lstCV = new List<ContentVersion>();
            lstCV.add(new ContentVersion(Title = 'Document1',PathOnClient = 'Document1.pdf',VersionData = Blob.valueOf('Document1'),IsMajorVersion = true));
            lstCV.add(new ContentVersion(Title = 'Document2',PathOnClient = 'Document2.pdf',VersionData = Blob.valueOf('Document1'),IsMajorVersion = true));
            insert lstCV; 

            List<ContentDistribution> lstContentDistribution = new List<ContentDistribution>();
            for (ContentVersion cv: [SELECT Id, Title,ContentDocument.title,contentDocumentId from ContentVersion WHERE Id IN :lstCV] ){
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.contentDocument.title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowViewInBrowser= true;
                cd.PreferencesLinkLatestVersion=true;
                cd.PreferencesNotifyOnVisit=false;
                cd.PreferencesPasswordRequired=false;
                cd.PreferencesAllowOriginalDownload= true;
                cd.RelatedRecordId = vContract.Id; 
                lstContentDistribution.add(cd);
            }
            insert lstContentDistribution;

            lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument order by createddate ASC];

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId = vContract.Id, ContentDocumentId = lstDocuments[0].Id),
                new contentDocumentLink(LinkedEntityId = vContract.Id, ContentDocumentId = lstDocuments[1].Id)
            };
            insert lstCDL;
            test.startTest();
            vContract.Tech_RecoverLinkToDocument__c = true;
                update vContract;
                delete lstDocuments[1];
            test.stopTest();
        }
    }
    
    @IsTest
    static void testGenerateDocURLCTin(){
        insert user00;
        system.runAs(user00){
            MapAccRT = TestFactory.MapRecordType('Account');
            MapContactRT = TestFactory.MapRecordType('Contact');
            AxaAcc = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            AxaAcc.RecordTypeId = MapAccRT.get('cTin_AXA') ;
            insert AxaAcc;

            AxaREP= TestFactory.createContact(AxaAcc, 'TestFname' , 'TestlName');
            AxaREP.RecordTypeID = MapContactRT.get('cTin_AXA');
            AxaREP.cTin_RelatedUser__c = user00.Id;
            AxaREP.cTin_LegalRepresentative__c = true;
            AxaREP.MobilePhone = '+212667849903';
            AxaREP.cTin_Active__c = true;
            insert AxaREP;

            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier; 

            AxaSUP = TestFactory.createContact(supplier, 'TestFname 1', 'TestLname 1');
            AxaSUP.RecordTypeID = MapContactRT.get('cTin_Supplier');
            AxaSUP.cTin_RelatedUser__c = user00.Id;
            AxaSUP.cTin_LegalRepresentative__c = true;
            AxaSUP.MobilePhone = '+2126655565645';
            AxaSUP.cTin_Active__c = true;
            AxaSUP.email ='elhaddad.amine@gmail.com' ; 
            AxaSUP.FirstName='Amine' ; 
            AxaSUP.LastName = 'ElHaddad' ; 
            insert AxaSUP;

            entity = TestFactory.createEntity();
            insert entity;           

            //create contracts
            Contract__c ctr = new Contract__c(Name = 'Test Contract__c', 
                Status__c = 'In Signature', 
                cTin_TypeofDocument__c = 'Contract', 
                cTin_BusinessOwner__c = UserInfo.getUserId(),  
                cTin_ShortDescription__c = 'Test Description', 
                StartDate__c = Date.today(), 
                EndDate__c = Date.today(), 
                cTin_Reminder__c = 'None',
                cTin_FinancialEngagement__c = 'No', 
                cTin_SupplierAccount__c = supplier.id, 
                cTin_CRClause__c = 'Standard',
                cTin_AntiBriberyClause__c = 'Standard', 
                cTin_TerminationClause__c ='Standard', 
                OwnerId = UserInfo.getUserId(), 
                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                cTin_FairTransparentSelectionProcess__c = 'No',
                cTin_MainAPCL2__c='1103-Towing',
                cTin_eSourcingReferenceId__c = 'WS111111111', 
                cTin_AXAMainLegalSignatoryEntity__c= entity.Id, 
                cTin_SupplierSignatoryRepresentative__c = AxaSUP.Id,
                cTin_AXASignatoryRepresentative__c = AxaREP.Id,
                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId());
            insert ctr;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c=true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= ctr.Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            ContentDocument contDoc = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument LIMIT 1];
            contentDocumentLink cdl = new contentDocumentLink(LinkedEntityId=ctr.Id, ContentDocumentId=contDoc.Id);
            insert cdl;

            System.debug('***** '+[SELECT Id, Tech_RecoverLinkToDocument__c, TECH_IsContractIn__c FROM Contract__c WHERE Id = :ctr.Id]);
            test.startTest();
                ctr.Tech_RecoverLinkToDocument__c = true;
                update ctr;
                delete contDoc;
            test.stopTest();
        }
    }
    
    
    @IsTest
    static void testUpdateFinaldocUrl(){
        User adminUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert adminUser;

        adminUser.PAD_BypassValidationRules__c = true;
        adminUser.PAD_BypassTrigger__c = 'AP19;AP01;AP412';
        update adminUser;

        system.runAs(adminUser){
            MapAccRT = TestFactory.MapRecordType('Account');
            MapContactRT = TestFactory.MapRecordType('Contact');
            AxaAcc = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            AxaAcc.RecordTypeId = MapAccRT.get('cTin_AXA') ;
            insert AxaAcc;

            AxaREP= TestFactory.createContact(AxaAcc, 'TestFname' , 'TestlName');
            AxaREP.RecordTypeID = MapContactRT.get('cTin_AXA');
            AxaREP.cTin_RelatedUser__c = adminUser.Id;
            AxaREP.cTin_LegalRepresentative__c = true;
            AxaREP.MobilePhone = '+212667849903';
            AxaREP.cTin_Active__c = true;
            insert AxaREP;

            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier; 

            AxaSUP = TestFactory.createContact(supplier, 'TestFname 1', 'TestLname 1');
            AxaSUP.RecordTypeID = MapContactRT.get('cTin_Supplier');
            AxaSUP.cTin_RelatedUser__c = adminUser.Id;
            AxaSUP.cTin_LegalRepresentative__c = true;
            AxaSUP.MobilePhone = '+2126655565645';
            AxaSUP.cTin_Active__c = true;
            AxaSUP.email ='elhaddad.amine@gmail.com' ; 
            AxaSUP.FirstName='Amine' ; 
            AxaSUP.LastName = 'ElHaddad' ; 
            insert AxaSUP;

            entity = TestFactory.createEntity();
            insert entity;           

            //create contracts
            Contract__c ctr = new Contract__c(Name = 'Test Contract__c', 
                Status__c = 'Draft', 
                cTin_TypeofDocument__c = 'Contract', 
                cTin_BusinessOwner__c = UserInfo.getUserId(),  
                cTin_ShortDescription__c = 'Test Description', 
                StartDate__c = Date.today(), 
                EndDate__c = Date.today(), 
                cTin_Reminder__c = 'None',
                cTin_FinancialEngagement__c = 'No', 
                cTin_SupplierAccount__c = supplier.id, 
                cTin_CRClause__c = 'Standard',
                cTin_AntiBriberyClause__c = 'Standard', 
                cTin_TerminationClause__c ='Standard', 
                OwnerId = UserInfo.getUserId(), 
                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                cTin_FairTransparentSelectionProcess__c = 'No',
                cTin_MainAPCL2__c='1103-Towing',
                cTin_eSourcingReferenceId__c = 'WS111111111', 
                cTin_AXAMainLegalSignatoryEntity__c= entity.Id, 
                cTin_SupplierSignatoryRepresentative__c = AxaSUP.Id,
                cTin_AXASignatoryRepresentative__c = AxaREP.Id,
                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId());
            insert ctr;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.PDF',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c=false
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= ctr.Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            ContentDocument contDoc = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument LIMIT 1];
            contentDocumentLink cdl = new contentDocumentLink(LinkedEntityId=ctr.Id, ContentDocumentId=contDoc.Id);
            insert cdl;

            test.startTest();
                cv.sign_able__c = true;
                update cv;
            test.stopTest();
        }
    }
}