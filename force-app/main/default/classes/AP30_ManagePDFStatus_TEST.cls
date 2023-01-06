@isTest
private class AP30_ManagePDFStatus_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP30_ManagePDFStatus_TEST
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP30_ManagePDFStatus
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 02-AUG-2018  KZE    1.0     Initial version
-- 08-JUN-2020	ARA	   1.3	   Optimization
--------------------------------------------------------------------------------------*/
  
    static user testUser;
    static ContentWorkspace workspace;
    static User vUserPM;
    static User vUserOO;
    static User vUserPMOADV; 
    static Account vAccount;
    static Account vAccount1;
    static Account vEAccount;
    static Account vEAccount1;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Contract__c vContract1;
    static Contract__c vContract2;
    static opportunity vOpp;
    static List<Contract__c> lstContracts = new List<Contract__c>();
    static List<Contract__c> lstUpdCtrs = new List<Contract__c>();

    static{
        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUserLightning(AP_Constant.GS_ENTITY_AXA_GR_OP_HK,false);  // for lightning user with company
        //vUserPM.PAD_BypassValidationRules__c = true;
		// vUserPM.PAD_BypassWorkflows__c = true;
        //update vUserPM;
        
        System.runAs(vUserPM) {
            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;   

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);
            vEAccount1 = AP05_TestDataFactory.createEntityAccount(vUserPM, 'Parent Entity');

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            //Contract
            vContract = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, vUserPM, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);    
            vContract1 = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, vUserPM, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);    
            vContract2 = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, vUserPM, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);    

            lstContracts.add(vContract);
            lstContracts.add(vContract1);
            lstContracts.add(vContract2);

            insert lstContracts;
        }
    } // generate Data test
    
    
    static testmethod void sendMailNotification_Test(){
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        user1.PAD_BypassValidationRules__c = true;
        vUserPM.FirstName = 'firstUser';
        vUserPM.LastName = 'firstUser';
        vUserPM.Username = 'firstUser';
        insert user1; 

        system.runAs(user1){ 
            Local_information__c localInfo = [SELECT Id, Name, Related_Legal_Entity__c, AXA_GO_Entity__c, MSA_ATS_Reference__c FROM Local_information__c WHERE AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited' ];
            //update PDFStatus_lgt__c
            vContract.name = 'Contract with name longer than 53 characters abcdefghijklmnop';
            vContract.PDFStatus_lgt__c ='Updated';
            vContract.Local_information__c = localInfo.Id;
            lstUpdCtrs.add(vContract);

            vContract1.name= 'Contract1 with name longer than 53 characters abcdefghijklmnop';
            vContract1.PDFStatus_lgt__c ='Updated';
            vContract1.Local_information__c = localInfo.Id;
            vContract1.OwnerId = user1.Id;
            lstUpdCtrs.add(vContract1);

            vContract2.name= 'Contract2 with name longer than 53 characters abcdefghijklmnop';
            vContract2.Status__c='Signed';
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Local_information__c = localInfo.Id;
            lstUpdCtrs.add(vContract2);
            try{
                update lstUpdCtrs;
            }
            catch(Exception e){
            }
            //to activate validation rule
            user1.PAD_BypassValidationRules__c = false;
            update user1;
            
            test.startTest();
               	localInfo.MSA_ATS_Reference__c = 'test';
                update localInfo;
            test.stopTest();
        }
    }

    static testmethod void updateContractEntity_Test(){
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), false, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert user1;
        user1.PAD_BypassValidationRules__c = true;
        update user1;

        system.runAs(user1){ 
            vAccount1 = new Account();
            vAccount1.Name = 'Account01';
            vAccount1.OwnerId = user1.Id;
            vAccount1.Account_Manager__c = user1.Id;
            vAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_LEGAL_ENTITY_ACCOUNT).getRecordTypeId();
            vAccount1.SAP_Account_Number__c = '235';
            vAccount1.Signature_Type__c = 'Manual';
            vAccount1.Active__c = true;
            vAccount1.Language__c = 'English';
            vAccount1.GIE_AXA_GS_Member__c = 'No';
            insert vAccount1;

            vAccount1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount1);
            test.startTest();
                // Change Customer Legal Entity
                vContract1.Account__c = vAccount1.Id;
                update vContract1;
                // Update Parent Entity
                vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount1, vAccount1);
            test.stopTest();
            
        }
    }
    

    static testmethod void updateFromAccount_Test(){
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), false, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert user1;
        user1.PAD_BypassValidationRules__c = true;
        update user1;

        system.runAs(user1){ 
            // Create the entity account

            vContract.name= 'Contract1';
            vContract.Account__c = vAccount.Id;
            vContract.Status__c='Draft';
            vContract.PDFStatus_lgt__c ='Updated';
            lstUpdCtrs.add(vContract);

            vContract1.name= 'Contract2';
            vContract1.Account__c = vAccount.Id;
            vContract1.Status__c='Signed';
            vContract1.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Single_Contract_process_Read_Only_OpCo360').getRecordTypeId();
            vContract1.PDFStatus_lgt__c ='Updated';
            lstUpdCtrs.add(vContract1);
            
            update lstUpdCtrs;

            test.startTest();
                vAccount.Name = 'Test Supplier Edited';
                update vAccount;
                // Change Customer Legal Entity
                vAccount1 = new Account();
                vAccount1.Name = 'Account01';
                vAccount1.OwnerId = user1.Id;
                vAccount1.Account_Manager__c = user1.Id;
                vAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_LEGAL_ENTITY_ACCOUNT).getRecordTypeId();
                vAccount1.SAP_Account_Number__c = '235';
                vAccount1.Signature_Type__c = 'Manual';
                vAccount1.Active__c = true;
                vAccount1.Language__c = 'English';
                vAccount1.GIE_AXA_GS_Member__c = 'No';
                insert vAccount1;

                vAccount1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount1);
                vContract1.Account__c = vAccount1.Id;
                update vContract1;
                // Update Parent Entity
                vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount1, vAccount1);
            test.stopTest();
            
        }
    }
    
    static testmethod void updateFromLocal_Test(){       
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert user1;

        system.runAs(user1){
            Local_information__c localInfo = [SELECT Id, Name, Related_Legal_Entity__c, AXA_GO_Entity__c, MSA_ATS_Reference__c FROM Local_information__c WHERE AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited' ];
            //update PDFStatus_lgt__c
            vContract.name= 'Contract1';
            vContract.PDFStatus_lgt__c ='Updated';
            vContract.Local_information__c = localInfo.Id;

            //update PDFStatus_lgt__c
            vContract1.name= 'Contract2';
            vContract1.PDFStatus_lgt__c ='Updated';
            vContract1.Local_information__c = localInfo.Id;

            //dont update PDFStatus_lgt__c
            vContract2.name= 'Contract3';
            vContract2.Status__c='Signed';
            vContract2.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Single_Contract_process_Read_Only_OpCo360').getRecordTypeId();
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Local_information__c = localInfo.Id;

            List<Contract__c> lstContracts = new List<Contract__c>();
            lstContracts.add(vContract);
            lstContracts.add(vContract1);
            lstContracts.add(vContract2);

            try{
                update lstContracts;
            }
            catch(Exception e){
            }

            test.startTest();
                localInfo.MSA_ATS_Reference__c = 'test';
                update localInfo;
            test.stopTest();
        }
    }
    
    static testmethod void updateFromLocalWithMSAWarning_Test(){       
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert user1;

        system.runAs(user1){
            Local_information__c localInfo = [SELECT Id, Name, Related_Legal_Entity__c, AXA_GO_Entity__c, MSA_ATS_Reference__c FROM Local_information__c WHERE AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited' ];
            //update PDFStatus_lgt__c
            vContract.name= 'Contract1';
            vContract.PDFStatus_lgt__c ='Updated';
            vContract.Local_information__c = localInfo.Id;

            //update PDFStatus_lgt__c
            vContract1.name= 'Contract2';
            vContract1.PDFStatus_lgt__c ='Updated';
            vContract1.Local_information__c = localInfo.Id;

            //dont update PDFStatus_lgt__c
            vContract2.name= 'Contract3';
            vContract2.Status__c='Signed';
            vContract2.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Single_Contract_process_Read_Only_OpCo360').getRecordTypeId();
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Local_information__c = localInfo.Id;

            List<Contract__c> lstContracts = new List<Contract__c>();
            lstContracts.add(vContract);
            lstContracts.add(vContract1);
            lstContracts.add(vContract2);

            try{
                update lstContracts;
                localInfo.MSA_ATS_Reference__c = 'test';
                update  localInfo;
            }
            catch(Exception e){
            }

            test.startTest();
                localInfo.MSA_ATS_Reference__c = '';
                update localInfo;
            test.stopTest();
        }
    } 

    static testmethod void updateFromContract_Test(){
        User user1 = TestFactory.createUserLightning('TestUser', UserInfo.getProfileId(), true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert user1; 

        system.runAs(user1){ 
            // Create the entity account
            List<Contract__c> lstContracts = new List<Contract__c>();

            vContract.name= 'Contract1';
            vContract.Account__c = vAccount.Id;
            vContract.PDFStatus_lgt__c ='Updated';
            vContract.Signature_Type__c='Electronic';
            lstContracts.add(vContract);

            vContract1.name= 'Contract2';
            vContract.Account__c = vAccount.Id;
            vContract1.PDFStatus_lgt__c ='Updated';
            lstContracts.add(vContract1);
            
            try{
                update lstContracts;
            }
            catch(Exception e){
            }

            test.startTest();
                vContract.Signature_Type__c='Manual';
                vContract1.Status__c='Signed';
                update vContract;
                update vContract1;
            test.stopTest();

            List<Contract__c> lstUpdated = [SELECT id, name, PDFStatus_lgt__c FROM Contract__c WHERE Id in :lstContracts ];

//            system.assertEquals( lstUpdated[0].PDFStatus_lgt__c, 'Not updated!');
//            system.assertEquals( lstUpdated[1].PDFStatus_lgt__c, 'Updated');

        }
    }
}