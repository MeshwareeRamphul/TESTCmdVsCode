@isTest
public without sharing class LC36_ManageEsignature_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC36_ManageEsignature
-- - Author        : SPOON
-- - Description   : Test class for lightning component LC36_ManageEsignature
--                  
--
-- Maintenance History:
--
-- Date             Name   Version   Remarks
-- -----------      ----   -------   ---------------------------------------
-- 20-JAN-2020      SGO     1.0     Initial version                                
-- 06-FEB-2020      SGO     1.1     Increase coverage   
--------------------------------------------------------------------------- */


    static User usrAdmin;
    static User testAdminAuth;
    static Account supplier;
    static Account axaRep;
    static cTin_Entity__c entity;
    static List<User> lstUsers = new List<User>();
    static List<Contract__c> lstContracts;
    static List<Contact> lstContacts;
    static List<Esignature__c> lstESignatureRet = new List<Esignature__c>();
    static List<eSignatory__c> lsteSignatory;
 
    static{
        
        // create users
        usrAdmin = TestFactory.createUser('usrAdmin', TestFactory.getProfileAdminId(), true);
        testAdminAuth = TestFactory.createUser('testAdmin', TestFactory.getProfileAdminId(), true);
        testAdminAuth.cTin_EntityLocalCode__c = AP_Constant.entityLocalCodeCORE;
        testAdminAuth.cTin_Universign__c = true;
        usrAdmin.PAD_BypassTrigger__c = 'AP40';
        testAdminAuth.PAD_BypassTrigger__c = 'AP40';
        usrAdmin.Bypass_FieldFilter__c = true;
        testAdminAuth.Bypass_FieldFilter__c = true;

        lstUsers.add(testAdminAuth);
        lstUsers.add(usrAdmin);
        
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
                // ,TestFactory.createContract(supplier.id, 'TestCtr2', AP_Constant.CONTRACT_STATUS_DRAFT)
                // ,TestFactory.createContract(supplier.id, 'TestCtr3', AP_Constant.CONTRACT_STATUS_DRAFT),
            };
            // System.debug('@@@ lstContracts : ' + lstContracts);
            lstContracts[0].cTin_DataPrivacyClause__c='Standard';
            lstContracts[0].cTin_DataPrivacyRisk__c='Low Risk';
            insert lstContracts;

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
                sign_able__c=true
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

            // Contract Form
            List<cTin_ContractForm__c> lstCtrForm = [SELECT Id, Name FROM cTin_ContractForm__c WHERE cTin_Contract__c=:lstContracts[0].Id];
            // System.debug('@@@ lstCtrForm ' + lstCtrForm);

            lstContracts[0].Status__c = AP_Constant.contractInSignatureStatus;
            update lstContracts;
   
        }

    }

  
    // test scenario: Delete eSignatory
    @IsTest
    static void testDeleteSignatory(){
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
            //lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
                 
            //update lstESignatureRet;
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
           // esignature.transactionId__c='5454sdsadaf';
            insert esignature;
           
           /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, 
           eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];*/


            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='3333333';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='444444';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;

            List<eSignatory__c> lsteSignatory = new List<eSignatory__c>([SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c  FROM esignatory__c WHERE eSignature__c = :esignature.Id]);
           
            Test.startTest();

                // Get Signatory List
                map<string,object>  mapDisplay = LC36_ManageEsignature.buildSignatorylst(esignature.Id);

                Map<String, String> mapCodes = LC36_ManageEsignature.getCodes();

                // Delete Signatory
                list<esignatory__c> lstSignatoryRet = LC36_ManageEsignature.deleteSignatory((String)lsteSignatory[1].Id, (String)esignature.Id,(Integer) lsteSignatory[1].Order__c);

            Test.stopTest();

            System.AssertEquals(lsteSignatory.size() - 1, lstSignatoryRet.size());
            System.AssertNotEquals(null, mapDisplay.get('lst'));
            System.AssertEquals(true, mapDisplay.get('disableSignbtn'));
        }
        
    }


  
    // test scenario: Change Order eSignatory
    @IsTest
    static void testChangeOrder(){
        System.runAs(usrAdmin){
            list<esignatory__c> lstSignatoryRetDown = new list<esignatory__c>();
            list<esignatory__c> lstSignatoryRetUp =new list<esignatory__c>();
            
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);          
           // lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
          
           // update lstESignatureRet;
           
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
             
            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='3333333333';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='444444444';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;

            List<eSignatory__c> lsteSignatoryRet = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c  FROM esignatory__c WHERE eSignature__c = :esignature.Id];
          
            Test.startTest();

                // increase order - move down
                LC36_ManageEsignature.changeOrder((String)esignature.Id, '', 'down', lsteSignatory[0].Order__c, lsteSignatory[0]);
               
                // decrease order - move up
                LC36_ManageEsignature.changeOrder((String)esignature.Id, '', 'up', lsteSignatory[1].Order__c, lsteSignatory[1]);
              
             
            Test.stopTest();


        }
        
    }

    
    // test scenario: Refresh lstSignatory
    @IsTest
    static void testRefreshSignatory(){
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
            // System.debug('@@@ mapResult ' + mapResult);

           /* lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
            // System.debug('@@@ lstESignatureRet ' + lstESignatureRet);        
            update lstESignatureRet;*/
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            
            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='3333333333';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='444444444';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;

            List<eSignatory__c> lsteSignatoryRet = [SELECT Id,Name,Order__c,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,
            TECH_defaultSignatory__c,orderToSend__c,cTin_PreviousContact__c  FROM esignatory__c WHERE eSignature__c = :esignature.Id];

            Test.startTest();

                list<esignatory__c> lstSignatoryRet = LC36_ManageEsignature.refreshSignatoryLst((String)esignature.Id, true, (String)lsteSignatoryRet[0].Id, (String)lstContacts[0].Id, lsteSignatoryRet[0].Name, 'eSignatory', 'sms', lsteSignatoryRet[0].MobileTxt__c, (Integer) lsteSignatoryRet[0].Order__c);
              

                list<esignatory__c> lstSignatoryRet2 = LC36_ManageEsignature.refreshSignatoryLst((String)esignature.Id, true, null, (String)lstContacts[1].Id, lsteSignatoryRet[1].Name, 'eSignatory', 'sms', lsteSignatoryRet[1].MobileTxt__c, (Integer) lsteSignatoryRet[1].Order__c);
                
                //list<esignatory__c> lstSignatoryRet3 = LC36_ManageEsignature.refreshSignatoryLst((String)esignature.Id, false, (String)lsteSignatoryRet[1].Id, (String)lstContacts[1].Id, lsteSignatoryRet[1].Name, 'eSignatory', 'sms', lsteSignatoryRet[1].MobileTxt__c, (Integer) lsteSignatoryRet[1].Order__c);
              
                list<esignatory__c> lstSignatoryRet4 = LC36_ManageEsignature.refreshSignatoryLst((String)esignature.Id, false, null, (String)lstContacts[1].Id, lsteSignatoryRet[1].Name, 'eSignatory', 'sms', lsteSignatoryRet[1].MobileTxt__c, (Integer) lsteSignatoryRet[1].Order__c);
               
               
               lsteSignatoryRet[0].cTin_PreviousContact__c='Tbd';
               update lsteSignatoryRet[0];
               LC36_ManageEsignature.cancelChanges(esignature.Id);
               
            
               
                LC36_ManageEsignature.getSObject('eSignatory__c',string.valueOf(lsteSignatory[0].id));

            Test.stopTest();

        }
        
    }


    // test scenario: Cancel changes
    @IsTest
    static void testCancel(){
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
 
            /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, 
            eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c 
            FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
                  
            update lstESignatureRet;*/
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            
            if(lstESignatureRet.size()>0){
            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='333333';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();
            lsteSignatory[0].cTin_PreviousContact__c = lstContacts[2].Id;
            lsteSignatory[0].EntityName__c = null;
            lsteSignatory[0].cTin_Role__c = 'AXA Representative';

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='4444444';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();
            lsteSignatory[1].cTin_Role__c = 'Supplier Representative';
            lsteSignatory[1].cTin_PreviousContact__c = 'tbd';

            insert lsteSignatory;

            List<eSignatory__c> lsteSignatory = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c  FROM esignatory__c WHERE eSignature__c IN :lstESignatureRet];
            
            Test.startTest();

                // get eSignatory List
                List<Contact> lstQueryAXA = LC36_ManageEsignature.getSObjectList('Contact', 'Test','AXA Representative', esignature.Id);
               
                List<Contact> lstQuerySupplier = LC36_ManageEsignature.getSObjectList('Contact', 'Test', 'Supplier Representative',esignature.Id);

                List<LC36_ManageEsignature.AuraObject> lstSupplier = LC36_ManageEsignature.getSObject('Contact', lstContacts[0].Id);
               
                list<esignatory__c> lstSignatoryRet = LC36_ManageEsignature.cancelChanges((String)esignature.Id);

            Test.stopTest();

            System.AssertEquals('email', lstSignatoryRet[0].Code__c);
            }

        }
        
    }

    //test scenario: Save changes
    @IsTest
    static void testSave(){
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
           
            /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
                   
            update lstESignatureRet;*/
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            

            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature, 'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature, 'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='333333';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='4444444';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;

            Test.startTest();

                // get eSignatory List
                List<Contact> lstQueryAXA = LC36_ManageEsignature.getSObjectList('Contact', 'Test', 'AXA Representative',esignature.Id);
              
                List<Contact> lstQuerySupplier = LC36_ManageEsignature.getSObjectList('Contact', 'Test', 'Supplier Representative',esignature.Id);
               
                // Change Code
                lsteSignatory[0].Code__c = 'sms';
              
                map<string,object> mapResult1 = LC36_ManageEsignature.saveChanges((String)esignature.Id, lsteSignatory);

            Test.stopTest();
            List<eSignatory__c> lsteSignatory = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c  FROM esignatory__c WHERE eSignature__c =:esignature.Id];
            System.AssertNotEquals(null, mapResult1.get('success'));
           
            lsteSignatory[1].contact__c=lstContacts[3].id;
            lsteSignatory[1].cTin_PreviousContact__c=lstContacts[1].id;
            lsteSignatory[1].cTin_Role__c='Supplier Representative';
            update lsteSignatory[1];
            //LC36_ManageEsignature.cancelChanges(esignature.Id);
               

        }
        
    }

    //test scenario : submit esignature
    @IsTest
    static void testSubmitESignature(){
       
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);

            /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
           
            update lstESignatureRet;*/
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            

            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='45648464';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='45648464';
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;
          
            Test.startTest();
              //  AP22_XmlRpcWrapper.dummyResponse =new TestFactory.WSResponse_Success_CreateXmlRpc().respond(new HTTPRequest());
                Map<string,object> mapofResult = LC36_ManageEsignature.submitEsignature(esignature.Id);
                

            Test.stopTest();

            List<Esignature__c> lstSignRet = new List<ESignature__c>([SELECT Id, Name, Status__c, RecordTypeId FROM ESignature__c WHERE Id =:esignature.Id]);

            List<Esignatory__c> lsteSignatoryRet = new List<Esignatory__c>([SELECT Id, Name, Status__c FROM Esignatory__c WHERE Id IN :lsteSignatory]);

            //System.AssertEquals(false, mapofResult.containsKey('error'));
            /*System.AssertEquals(AP_Constant.eSignatureSentStatus, lstSignRet[0].Status__c);
            System.AssertEquals(Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_InEsignature').getRecordTypeId(), lstSignRet[0].RecordTypeId);

            System.AssertEquals(AP_Constant.esignatoryStatusReady, lsteSignatoryRet[0].status__c);
            System.AssertEquals(AP_Constant.esignatoryStatusAwaiting, lsteSignatoryRet[1].status__c);*/
        }
        
    }
    
    //test scenario : submit esignature error
    @IsTest
    static void testSubmitESignatureError(){
        
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
           
            /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
            
            update lstESignatureRet;*/
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;

            lsteSignatory = new List<eSignatory__c>{
                TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                TestFactory.createEsignatory(lstContracts[0], esignature,'John',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted)
            };
            lsteSignatory[0].Order__c=3;
            lsteSignatory[0].OrderCachet__c=3;
            lsteSignatory[0].OrderToSend__c=3;
            lsteSignatory[0].OrderCreation__c=3;
            lsteSignatory[0].MobileTxt__c='45648464';
            lsteSignatory[0].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

            lsteSignatory[1].Order__c=4;
            lsteSignatory[1].OrderCachet__c=4;
            lsteSignatory[1].OrderToSend__c=4;
            lsteSignatory[1].OrderCreation__c=4;
            lsteSignatory[1].MobileTxt__c='45648464';
        
            lsteSignatory[1].RecordTypeId = Schema.getGlobalDescribe().get('eSignatory__c').getDescribe().getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();

            insert lsteSignatory;
            
           
            Test.startTest();

                Map<string,object> mapofResult = LC36_ManageEsignature.submitEsignature(esignature.Id);
               
            Test.stopTest();

            List<Esignature__c> lstSignRet = new List<ESignature__c>([SELECT Id, Name, Status__c, RecordTypeId FROM ESignature__c WHERE Id =:esignature.Id]);

            List<Esignatory__c> lsteSignatoryRet = new List<Esignatory__c>([SELECT Id, Name, Status__c FROM Esignatory__c WHERE Id IN :lsteSignatory]);

            System.AssertNotEquals(null, mapofResult.get('error'));

        }
        
    }
    
    //test scenario: submit esignature (not allowed)
    @IsTest
    static void testSubmitESignatureNotAllowed(){
     
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
       

           /* lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
                  
            lstESignatureRet[0].Status__c = AP_Constant.eSignatureSentStatus;
            lstESignatureRet[0].TransactionID__c = '3467929565575';
            update lstESignatureRet;*/
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            
            esignature.Status__c = AP_Constant.eSignatureSentStatus;
            esignature.TransactionID__c = '3467929565575';
            update esignature;

            Esignatory__c esignatory= TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory.Order__c=3;
            esignatory.OrderCachet__c=3;
            esignatory.OrderToSend__c=3;
            esignatory.OrderCreation__c=3;
            esignatory.MobileTxt__c='45648464';
            esignatory.Status__c=AP_Constant.esignatoryStatusReady;
            esignatory.signURL__c = 'https://sample.com';
            insert esignatory;
           
            Test.startTest();

                Map<string,object> mapofResult = LC36_ManageEsignature.submitEsignature(esignature.Id);
               
            Test.stopTest();

            System.AssertEquals(system.label.EsignatureSubmitError, mapofResult.get('error'));

        }
        
    }

    //test scenario : test sign Approved contract ->Error
    @IsTest
    static void testSignApprovedCtrNotSignatory(){
        // Status of eSignatory = created
        
        System.runAs(usrAdmin){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);
         
            //lstESignatureRet = [select Id, name, Contract__c, Status__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
           
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            
            Test.startTest();

                Map<string,object> mapofResult = LC36_ManageEsignature.assignSignatoryURL(esignature.Id);
            

            Test.stopTest();

            System.AssertEquals(System.label.eSignatoryErrNotSignatory, mapofResult.get('error'));
        }
        
    }

    //test scenario : test sign Approved contract 
  /*  @IsTest
    static void testSignApprovedCtr(){
        // Status of eSignatory = ready

        System.runAs(testAdminAuth){
            Map<string,object> mapResult = LC16_CreateSignature.validateCreateSign(lstContracts[0].Id);

           // lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
               
            //lstESignatureRet[0].Status__c = AP_Constant.eSignatureSentStatus;
           // lstESignatureRet[0].TransactionID__c = '3467929565575';
           // update lstESignatureRet;
            
            Esignature__c esignature=TestFactory.createEsignature(lstContracts[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            esignature.Status__c = AP_Constant.eSignatureSentStatus;
            esignature.TransactionID__c = '3467929565575';
            update esignature;

            Esignatory__c esignatory= TestFactory.createEsignatory(lstContracts[0], esignature,'Jane',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory.Order__c=3;
            esignatory.OrderCachet__c=3;
            esignatory.OrderToSend__c=3;
            esignatory.OrderCreation__c=3;
            esignatory.MobileTxt__c='45648464';
            esignatory.Status__c=AP_Constant.esignatoryStatusReady;
            esignatory.signURL__c = 'https://sample.com';
            insert esignatory;
          
            Test.startTest();

                map<string,object>  mapDisplay = LC36_ManageEsignature.buildSignatorylst(esignature.Id);

                Map<string,object> mapofResult = LC36_ManageEsignature.assignSignatoryURL(esignature.Id);

                List<Esignatory__c> lsteSignatoryRet = new List<eSignatory__c>([SELECT Id, Name FROM eSignatory__c WHERE eSignature__c =:esignature.Id]);

            Test.stopTest();

            System.AssertEquals(esignatory.signURL__c, mapofResult.get('success'));
            System.AssertNotEquals(null, mapDisplay.get('lst'));
            System.AssertEquals(true, mapDisplay.get('disablebtn'));

        }
        
    }*/
}