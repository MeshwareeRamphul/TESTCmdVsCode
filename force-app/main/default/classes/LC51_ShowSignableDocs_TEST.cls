@isTest
public with sharing class LC51_ShowSignableDocs_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC51_ShowSignableDocs_TEST
-- - Author        : MRA
-- - Description   : Test class for controller LC51_ShowSignableDocs
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 30-SEP-2021   MRA    1.0       Initial version 
--------------------------------------------------------------------------- */
    static List<Contract__c> lstCtrs;
    static List<Contact> lstContacts;
    static List<cTin_ContractForm__c> lstCtrForm = new List<cTin_ContractForm__c>();
    static ContentWorkspace workspace;
    static Account axaRep;
    static Account supplier;
    static User testUser;
    static cTin_Entity__c entity;


    static{

        cTin_Entity__c entity;
        cTin_LegalEntity__c legalEntity;
        cTin_Location__c Location;

         //creating user 
        testUser = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
        testUser.PAD_BypassValidationRules__c= true;
        testUser.PAD_BypassWorkflows__c = true;
       
        testUser.cTin_LegalRepresentative__c = true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c=true;
        insert testUser;
        testUser.PAD_BypassTrigger__c = 'AP412;AP43;AP44;';
        update testUser;
        
        System.runAs(testUser){
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  

            axaRep = TestFactory.createSupplier('testAXARep' , 'Paris' , 'France');
            axaRep.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            insert axaRep;
            supplier = TestFactory.createSupplier('testAcc' , 'BillingCity' , 'France');
            insert supplier;
            
            entity = new cTin_Entity__c(Name = 'test');
            insert entity;

             lstContacts = new List<Contact>{
                TestFactory.createContactAXARep('test', 'AxaRep', axaRep.Id, 'testAXAREP@invalid.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test', 'Contact2')
            };
            lstContacts[1].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[1].email ='testSupplier@invalid.com';
            insert lstContacts;

            lstCtrs = new List<Contract__c>{
                TestFactory.createContract(supplier.id, 'TestCtr1', 'Draft')
            };
            // lstCtrs[0].cTin_DataPrivacyClause__c='Standard';
            // lstCtrs[0].cTin_DataPrivacyRisk__c='Low Risk';
            insert lstCtrs;

            legalEntity = TestFactory.createLegalEntity(lstCtrs[0].id, entity.id);
            insert legalEntity;

            Location = TestFactory.createLocation(lstCtrs[0].id);
            insert Location;

            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            content.sign_able__c=true;
            insert content;
           

            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, lstCtrs[0].Id);          
            insert cd;

            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            // List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
            //     new contentDocumentLink(LinkedEntityId=lstCtrs[0].Id, ContentDocumentId=lstDocuments[0].Id)
            // };
            // insert lstCDL;

            ContentDistribution cdistr = [SELECT id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId FROM ContentDistribution 
                                                WHERE id=: cd.Id ];  
            System.debug('@@ cdistr ' + cdistr);
            // lstCtrs[0].FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            lstCtrs[0].cTin_ContractSegment__c ='test';
            lstCtrs[0].EndDate__c = system.today();
            lstCtrs[0].cTin_MainAPCL0__c = 'test';
            lstCtrs[0].cTin_OrganizationalScope__c = 'test';
            lstCtrs[0].cTin_ShortDescription__c = 'test';
            lstCtrs[0].StartDate__c = system.today();
            lstCtrs[0].cTin_SupplierAccount__c = supplier.id;
            lstCtrs[0].cTin_TypeOfDocument__c = 'test';
            lstCtrs[0].cTin_AXAMainLegalSignatoryEntity__c = entity.id;
            lstCtrs[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstCtrs[0].cTin_SupplierSignatoryRepresentative__c = lstContacts[1].Id;
            lstCtrs[0].Status__c = 'In Progress';
            lstCtrs[0].LinkToDocument__c='https://google.com';
            lstCtrs[0].cTin_NumberSignablePDF__c =1;
            update lstCtrs;

            lstCtrForm = [SELECT Id, Name, cTin_Contract__c, cTin_Contract__r.LinkToDocument__c FROM cTin_ContractForm__c WHERE cTin_Contract__c IN :lstCtrs];
            lstCtrForm[0].cTin_ApproverName1__c = testUser.Id;
            lstCtrForm[0].cTin_EnableParallelApproval__c=false;
            update lstCtrForm;
            System.debug('@@ lstCtrForm ' + lstCtrForm);
             
            AP44_BlockNewContractTeam.bypassSpecial=true;
             
            List<cTin_ContractTeam__c> lstCtrTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_ContractForm__c=lstCtrForm[0].Id, cTin_Contract__c=lstCtrs[0].Id, cTin_ApprovalOrder__c='1', cTin_TeamMember__c=testUser.Id)
            };
            insert lstCtrTeam;
           
        }
    }
    
    //test for non confidential contracts + atleast 1 signable doc
    @IsTest
    static void getAttributesCase1Test(){
        System.runAs(testUser){
            AP44_BlockNewContractTeam.bypassSpecial=true;
            Test.startTest();
                Map<string,object> mapResult = LC51_ShowSignableDocs.getAttributes(string.valueOf(lstCtrForm[0].Id));
                system.assert(mapResult.containskey('displaydoc'));
            Test.stopTest();
        }
    }
    
    //test for no signable doc
    @IsTest
    static void getAttributesCase2Test(){
        System.runAs(testUser){
            lstCtrs[0].cTin_NumberSignablePDF__c =0;
            update lstCtrs;
            AP44_BlockNewContractTeam.bypassSpecial=true;
            Test.startTest();
                Map<string,object> mapResult = LC51_ShowSignableDocs.getAttributes(string.valueOf(lstCtrForm[0].Id));
                system.assert(mapResult.containskey('Nodocument'));
            Test.stopTest();
        }
    }
    
    //test for confidential contract + atleast 1 signable doc + current user is approver
    @IsTest
    static void getAttributesCase3Test(){
        System.runAs(testUser){
            lstCtrs[0].cTin_Confidential__c =true;
            update lstCtrs;
            AP44_BlockNewContractTeam.bypassSpecial=true;
            Test.startTest();
                Map<string,object> mapResult = LC51_ShowSignableDocs.getAttributes(string.valueOf(lstCtrForm[0].Id));
                system.assert(mapResult.containskey('displaydoc'));
            Test.stopTest();
        }
    }
    
        
}