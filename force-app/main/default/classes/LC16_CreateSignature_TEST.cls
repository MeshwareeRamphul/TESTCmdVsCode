@isTest
public with sharing class LC16_CreateSignature_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC16_CreateSignature_TEST
-- - Author        : SPOON
-- - Description   : Test class for LC16_CreateSignature
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 08-JAN-2020   SGO    1.0       Initial version 
-- 11-MAR-2020   SGO    1.1       Implement signable
--------------------------------------------------------------------------- */

    static User usrAdmin;
    static User testAdminAuth;
    static Account supplier;
    static Account axaRep;
    static cTin_Entity__c entity;
    static List<User> lstUsers = new List<User>();
    static List<Contract__c> lstContracts;
    static List<Contact> lstContacts;
 
    static{
        
        // create users
        usrAdmin = TestFactory.createUser('usrAdmin', TestFactory.getProfileAdminId(), true);
        usrAdmin.cTin_Universign__c = true;
        lstUsers.add(usrAdmin);
        testAdminAuth = TestFactory.createUser('testAdmin', TestFactory.getProfileAdminId(), true);
        testAdminAuth.cTin_EntityLocalCode__c = AP_Constant.entityLocalCodeCORE;
        testAdminAuth.cTin_Universign__c = true;
        lstUsers.add(testAdminAuth);
        insert lstUsers;

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
                TestFactory.createContactAXARep('test', 'AxaRep', axaRep.Id, 'testAXAREP@invalud.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test', 'Contact2')
            };
            lstContacts[1].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[1].email ='testSupplier@invalid.com';
            insert lstContacts;

            //create entity
            entity = new cTin_Entity__c(Name = 'testEntity');
            insert entity;
           

            //create contracts
            lstContracts =  new List<Contract__c>{
                TestFactory.createContract(supplier.id, 'TestCtr1', AP_Constant.CONTRACT_STATUS_DRAFT)
                // ,TestFactory.createContract(supplier.id, 'TestCtr2', AP_Constant.CONTRACT_STATUS_DRAFT)
                // ,TestFactory.createContract(supplier.id, 'TestCtr3', AP_Constant.CONTRACT_STATUS_DRAFT),
            };
            // System.debug('@@@ lstContracts : ' + lstContracts);
            lstContracts[0].cTin_BusinessOwner__c = usrAdmin.Id;
            insert lstContracts;
            
        }

    }

    @IsTest
    static void testCreateESign(){
        
        System.runAs(usrAdmin){
            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

            lstContracts[0].cTin_UnilateralSupplier__c = true;
            lstContracts[0].cTin_UnilateralAXARepresentative__c = true;
            lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;

            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c = true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= lstContracts[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;

            // Add contract team

            // Contract Form
            List<cTin_ContractForm__c> lstCtrForm = [SELECT Id, Name FROM cTin_ContractForm__c WHERE cTin_Contract__c=:lstContracts[0].Id];
            // System.debug('@@@ lstCtrForm ' + lstCtrForm);

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();
                LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
               // Map<string,object> mapResult = 
                // System.debug('@@@ mapResult : ' + mapResult);

               // List<Esignature__c> lstESignatureRet = new List<Esignature__c>([select Id, name, Contract__c, Status__c, cTin_ContractForm__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id]);
               // List<ContentDocumentLink> lstCDLRet = new List<ContentDocumentLink>([select Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstESignatureRet[0].Id]);
                
            Test.stopTest();

           // System.assertEquals(1, lstESignatureRet.size());
            //System.assertEquals(1, lstCDLRet.size());
        }
        
    }

    @IsTest
    static void testCreateESignBilateral(){
        
        System.runAs(usrAdmin){
            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

            lstContracts[0].cTin_UnilateralSupplier__c = false;
            lstContracts[0].cTin_UnilateralAXARepresentative__c = false;
            lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;

            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c = true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= lstContracts[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;

            // Add contract team

            // Contract Form
            List<cTin_ContractForm__c> lstCtrForm = [SELECT Id, Name FROM cTin_ContractForm__c WHERE cTin_Contract__c=:lstContracts[0].Id];
            // System.debug('@@@ lstCtrForm ' + lstCtrForm);

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();
                LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
               // Map<string,object> mapResult = 
                // System.debug('@@@ mapResult : ' + mapResult);

               // List<Esignature__c> lstESignatureRet = new List<Esignature__c>([select Id, name, Contract__c, Status__c, cTin_ContractForm__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id]);
               // List<ContentDocumentLink> lstCDLRet = new List<ContentDocumentLink>([select Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstESignatureRet[0].Id]);
                
            Test.stopTest();

           // System.assertEquals(1, lstESignatureRet.size());
            //System.assertEquals(1, lstCDLRet.size());
        }
        
    }

    @IsTest
    static void testErrorBlockCreation(){
        
        System.runAs(usrAdmin){
            
            Test.startTest();

                Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
                // System.debug('@@@ mapResult : ' + mapResult);
                
            Test.stopTest();

            System.assertEquals(system.label.cTin_ErrorMessageBlckCreation, String.valueOf(mapResult.get('error')));
        }
        
    }

    @IsTest
    static void testErrorNoDoc(){
        
        System.runAs(usrAdmin){
            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();

                Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
                // System.debug('@@@ mapResult : ' + mapResult);
                
            Test.stopTest();

            System.assertEquals(system.label.ErrorMessageEsignNoDocs, String.valueOf(mapResult.get('error')));
        }
        
    }

     @IsTest
    static void testErrorNoPermission(){
        
        System.runAs(usrAdmin){
            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c = true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= lstContracts[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();

                Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
                // System.debug('@@@ mapResult : ' + mapResult);
                
            Test.stopTest();

            System.assertEquals(system.label.LC16_ErrorCurrentUser, String.valueOf(mapResult.get('error')));
        }
        
    }

     @IsTest
    static void testErrorSignatoryRequired(){
        
        System.runAs(testAdminAuth){
            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

            lstContracts[0].cTin_UnilateralSupplier__c = false;
            lstContracts[0].cTin_UnilateralAXARepresentative__c = false;
            lstContracts[0].cTin_AXASignatoryRepresentative__c = null;

            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c = true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= lstContracts[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();

                Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
                // System.debug('@@@ mapResult : ' + mapResult);
                
            Test.stopTest();

            System.assertEquals(system.label.LC16_ErrorBilateralSignatories, String.valueOf(mapResult.get('error')));
        }
        
    }

    @IsTest
    static void testErrorSameContactEmail(){
        
        System.runAs(testAdminAuth){
            lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

            lstContracts[0].cTin_UnilateralSupplier__c = false;
            lstContracts[0].cTin_UnilateralAXARepresentative__c = false;
            // emailAXA == emailSupplier
            lstContacts[0].email = 'testSameEmail@invalid.com';
            lstContacts[1].email = 'testSameEmail@invalid.com';
            update lstContacts;

            lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;

            lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c = true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= lstContracts[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            insert cd;
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;

            // Add contract team

            // Contract Form
            List<cTin_ContractForm__c> lstCtrForm = [SELECT Id, Name FROM cTin_ContractForm__c WHERE cTin_Contract__c=:lstContracts[0].Id];
            // System.debug('@@@ lstCtrForm ' + lstCtrForm);

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;

            Test.startTest();

                Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
                // System.debug('@@@ mapResult : ' + mapResult);

            Test.stopTest();
            System.assertEquals(system.label.LC16_ErrorSameContactEmail, String.valueOf(mapResult.get('error')));

        }
        
    }
    
    @isTest
    static void testdummy(){
    test.startTest();
    LC16_CreateSignature.dummy();
    test.stopTest();
     
    }

    // Cannot cover since validation rule already exists for doc type and title length
    //  @IsTest
    // static void testErrorDocTypeLength(){
        
    //     System.runAs(testAdminAuth){
    //         lstContracts[0].cTin_SupplierAccount__c = supplier.Id;

    //         lstContracts[0].cTin_UnilateralSupplier__c = true;
    //         lstContracts[0].cTin_UnilateralAXARepresentative__c = true;
    //         lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
    //         lstContracts[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;

    //         lstContracts[0].cTin_AXAMainLegalSignatoryEntity__c= entity.Id;

    //         // insert doc in pdf
    //         ContentVersion cv = new ContentVersion(
    //             Title = 'nkjU0PLmKO4YB35VRiyS8Cwnx8JYW8DHp6AzqYN0s2frETKJQBbcbjv6jqYI6IWubF0nx2bZuRrxtjIZoCY69PQ0GY', // Title > 89 
    //             PathOnClient = 'Doc1.docx', // File Type != pdf
    //             VersionData = Blob.valueOf('ACH'),
    //             IsMajorVersion = true
    //         );
    //         insert cv;
    //         ContentDistribution cd = new ContentDistribution(
    //             Name = cv.Title,
    //             ContentVersionId = cv.Id,
    //             RelatedRecordId= lstContracts[0].Id,
    //             PreferencesAllowViewInBrowser= true,
    //             PreferencesLinkLatestVersion=true,
    //             PreferencesNotifyOnVisit=false,
    //             PreferencesPasswordRequired=false,
    //             PreferencesAllowOriginalDownload= true
    //         );
    //         insert cd;
           
    //         List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
    //         System.debug('@@@ lstDocuments' + lstDocuments);

    //         List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
    //             new contentDocumentLink(LinkedEntityId=lstContracts[0].Id, ContentDocumentId=lstDocuments[0].Id)
    //         };
    //         insert lstCDL;

    //         lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
    //         update lstContracts;

    //         Test.startTest();

    //             Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
    //             System.debug('@@@ mapResult : ' + mapResult);

    //             List<Esignature__c> lstESignatureRet = new List<Esignature__c>([select Id, name, Contract__c, Status__c, cTin_ContractForm__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id]);
    //             List<ContentDocumentLink> lstCDLRet = new List<ContentDocumentLink>([select Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :lstESignatureRet[0].Id]);
                
    //         Test.stopTest();

    //         System.assertEquals(system.label.LC16_ErrorDocumentType, String.valueOf(mapResult.get('error')));
    //         System.assertEquals(system.label.LC16_ErrorDocumentLength, String.valueOf(mapResult.get('error')));
           
    //     }
        
    // }


    


}