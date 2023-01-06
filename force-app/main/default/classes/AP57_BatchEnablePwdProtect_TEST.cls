@isTest
public with sharing class   AP57_BatchEnablePwdProtect_TEST {
/*  
----------------------------------------------------------------------
-- - Name          : AP57_BatchEnablePwdProtect_TEST 
-- - Author        : SC
-- - Description   : Test class for controller AP57_BatchEnablePwdProtect
-- -                 
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 13-AUG-2020  MRA  1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
    static String CRON_EXP = '0 0 0 15 3 ? 2070';

    static User usrAdmin;
    static Account supplier;
    static Account axaRep;
    static cTin_Entity__c entity;
    static List<User> lstUsers = new List<User>();
    static List<Contract__c> lstContracts;
    static List<Contact> lstContacts;
    static List<Esignature__c> lstESignatureRet = new List<Esignature__c>();
    static List<eSignatory__c> lsteSignatory;
    static List<Esignature__c> lstESignature;
    static List<ContentDocumentLink> lstCDLEmpty = new List<ContentDocumentLink>();
    static List<ContentVersion> lstCV = new List<ContentVersion>();

    static{
        
        // create users
        usrAdmin = TestFactory.createUser('usrAdmin', TestFactory.getProfileAdminId(), true);
        usrAdmin.PAD_BypassTrigger__c = 'AP40;AP22';
        insert usrAdmin;

        System.runAs(usrAdmin){
            //create AXA rep
            axaRep = TestFactory.createSupplier('testAXARep' , 'Paris' , 'France');
            axaRep.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            insert axaRep;
            //create supplier
            supplier = TestFactory.createSupplier('testSupplier' , 'Paris' , 'France');
            supplier.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            insert supplier;

            // Create contact
            lstContacts = new List<Contact>{
                TestFactory.createContactAXARep('Test', 'AxaRep', axaRep.Id, 'testAXAREP@invalud.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test', 'Supplier'),
                // Not used as signatory but spare contact
                TestFactory.createContactAXARep('Test2', 'AxaRep2', axaRep.Id, 'testAXAREP@invalud.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test2', 'Supplier2')
            };
            lstContacts[1].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[1].email ='testSupplier@invalid.com';

            lstContacts[3].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[3].email ='testSupplier2@invalid.com';

            insert lstContacts;

            //create entity
            entity = new cTin_Entity__c(Name = 'testEntity');
            insert entity;
           
            //create contracts
            lstContracts =  new List<Contract__c>{
                TestFactory.createContract(supplier.id, 'TestCtr1', AP_Constant.CONTRACT_STATUS_DRAFT)
                ,TestFactory.createContract(supplier.id, 'TestCtr2', AP_Constant.CONTRACT_STATUS_DRAFT)
                // ,TestFactory.createContract(supplier.id, 'TestCtr3', AP_Constant.CONTRACT_STATUS_DRAFT),
            };
            // System.debug('@@@ lstContracts : ' + lstContracts);
            lstContracts[0].cTin_DataPrivacyClause__c='Standard';
            lstContracts[0].cTin_DataPrivacyRisk__c='Low Risk';
            lstContracts[1].cTin_DataPrivacyClause__c='Standard';
            lstContracts[1].cTin_DataPrivacyRisk__c='Low Risk';
            insert lstContracts;

            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;
            lstContracts[0].cTin_UnilateralSupplier__c = true;
            lstContracts[0].cTin_UnilateralAXARepresentative__c = true;
            lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;
            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;
            // lstContracts[0].tech_isContractIn__c= true;
            lstContracts[0].tech_migratedFile__c= false;

            lstContracts[1].cTin_SupplierAccount__c = supplier.Id;
            lstContracts[1].cTin_UnilateralSupplier__c = true;
            lstContracts[1].cTin_UnilateralAXARepresentative__c = true;
            lstContracts[1].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts[1].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;
            lstContracts[1].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;
            // lstContracts[1].tech_isContractIn__c= true;
            lstContracts[1].tech_migratedFile__c= true;

            
            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            lstContracts[1].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            // Create eSignature
            lstESignature = new List<ESignature__c>{
                TestFactory.createEsignature(lstContracts[0], 'eSign1', AP_Constant.eSignatureCreatedStatus),
                TestFactory.createEsignature(lstContracts[1], 'eSign2', AP_Constant.eSignatureCreatedStatus)
            };
            insert lstESignature;

            // insert doc in pdf
            for (Integer i=0; i<4; i++){
                lstCV.add(new ContentVersion(Title = 'ACH_signed.pdf'+i, PathOnClient = 'Doc'+i+'.pdf', VersionData = Blob.valueOf('ACH'+i), IsMajorVersion = true, sign_able__c=true));
            }
            insert lstCV;

            List<ContentDistribution> lstCD= new List<ContentDistribution>{
                new ContentDistribution(Name = lstCV[0].Title, ContentVersionId = lstCV[0].Id, RelatedRecordId= lstContracts[0].Id, PreferencesAllowViewInBrowser= true, PreferencesLinkLatestVersion=true, PreferencesNotifyOnVisit=false, PreferencesPasswordRequired=false, PreferencesAllowOriginalDownload= true),
                new ContentDistribution(Name = lstCV[1].Title, ContentVersionId = lstCV[1].Id, RelatedRecordId= lstContracts[1].Id, PreferencesAllowViewInBrowser= true, PreferencesLinkLatestVersion=true, PreferencesNotifyOnVisit=false, PreferencesPasswordRequired=false, PreferencesAllowOriginalDownload= true),
                new ContentDistribution(Name = lstCV[2].Title, ContentVersionId = lstCV[2].Id, RelatedRecordId= lstESignature[0].Id, PreferencesAllowViewInBrowser= true, PreferencesLinkLatestVersion=true, PreferencesNotifyOnVisit=false, PreferencesPasswordRequired=false, PreferencesAllowOriginalDownload= true),
                new ContentDistribution(Name = lstCV[3].Title, ContentVersionId = lstCV[3].Id, RelatedRecordId= lstESignature[1].Id, PreferencesAllowViewInBrowser= true, PreferencesLinkLatestVersion=true, PreferencesNotifyOnVisit=false, PreferencesPasswordRequired=false, PreferencesAllowOriginalDownload= true)
            };
            insert lstCD;

           // List<ContentDocumentLink> lstCDLs = new List<ContentDocumentLink>([SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstContracts[0].Id OR LinkedEntityId = :lstContracts[1].Id OR LinkedEntityId = :lstESignature[0].Id OR LinkedEntityId = :lstESignature[1].Id]);
            
           // System.assertEquals(lstCDLEmpty, lstCDLs);

        }
    }

    @IsTest
    static void testGenerateFileForContract(){
        
        System.runAs(usrAdmin){
           

            Test.startTest();
                AP57_BatchEnablePwdProtect batchEnablePwd= new AP57_BatchEnablePwdProtect();
                Id batchId = Database.executeBatch(batchEnablePwd);
                System.debug('@@ batchId ' + batchId);
            Test.stopTest();

            List<ContentDistribution> lstCD = new List<ContentDistribution>([SELECT PreferencesPasswordRequired 
                                                                            from contentdistribution 
                                                                            where relatedRecordId IN: lstContracts 
                                                                            and PreferencesPasswordRequired =: true]);
           

            System.assertEquals(2, lstCD.size());

           
        }
    }

    @IsTest
    static void testExecutionCode(){
        
        System.runAs(usrAdmin){
            Test.startTest();
                Id batchId = System.schedule('ScheduleApexClassTest', CRON_EXP, new AP57_BatchEnablePwdProtect ());
            Test.stopTest();    
                   
            AP00_CSVParser csvparser=new AP00_CSVParser();
            list<string> lststr=new list<string>();
            lststr.add('a');
            csvparser.writeHeader(lststr);
            csvparser.formatData('s');
            csvparser.createLine();
            csvparser.addToLine('s');
            
            AP00_FormatEmailSend emailSend = new AP00_FormatEmailSend();
            String filename='test.pdf';
            blob body=blob.valueOf('test');
            String fileFormat='PDF';
            emailSend.generateAttachment(filename,body,fileFormat);
        }
    }
}