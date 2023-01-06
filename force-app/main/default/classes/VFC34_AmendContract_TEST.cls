@isTest
private class VFC34_AmendContract_TEST {
/*
----------------------------------------------------------------------
-- - Name          : VFC34_AmendContract_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class for VFC34_AmendContract
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 18-JAN-2016  RLA    1.0      Intitial version
-- 23-OCT-2017  HVA    1.1      Reworked - All In merge contract In 
-- 14-JAN-2020  SGO    1.2      Reworked - Contract In 
----------------------------------------------------------------------
**********************************************************************
*/

    static Profile profile;
    static User user, user1, user2;
    static Account supplier;
    static cTin_Entity__c entity;
    static string role_legal_rep;
    static string role_business_owner;
    static string role_other;
    static List<Contract__c> lstContracts;
    static Group grp; 
    static List<cTin_ContractTeam__c> lstContractTeams;
    static List<cTin_LegalEntity__c> lstLegalEntity;
    static List<cTin_Location__c> lstLocation;
    static List<Contact> lstContacts; 
    static Account axaRep;

    static {
        role_legal_rep = '009';
        role_business_owner = '016';
        role_other = '001';

        List<Profile> profileList = [SELECT id FROM profile where NAME like '%sys%'];

        List<RecordType> lstRecordTypes = [SELECT Id,
                                                  developerName,
                                                  Name,
                                                  sObjectType
                                             FROM RecordType
                                            WHERE sObjectType = 'Contract__c'
                                              AND DeveloperName LIKE 'cTin_%'];

        if (profileList.size()>0) profile = profileList.get(0); 
        else throw new System.Nullpointerexception();

        user = TestFactory.createUser('Testing', profile.Id, true); 
        insert user;
        user.PAD_BypassTrigger__c = 'AP40';
        user.Bypass_FieldFilter__c=true;
        update user;

        System.runAs(user){

            user1 = TestFactory.createUser('Testing', profile.Id, true); 
            insert user1;
            user1.PAD_BypassTrigger__c = 'AP40';
            user1.Bypass_FieldFilter__c=true;
            update user1;
            user2 = TestFactory.createUser('Testing2', profile.Id, true); 
            user2.Bypass_FieldFilter__c=true;
            insert user2;
            user2.PAD_BypassTrigger__c = 'AP40';
            update user2;

            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier;
            axaRep = TestFactory.createSupplier('testAXARep' , 'Paris' , 'France');
            axaRep.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            insert axaRep;

            entity = TestFactory.createEntity();
            insert entity;

            lstContacts = new List<Contact>{
                TestFactory.createContactAXARep('test', 'AxaRep', axaRep.Id, 'testAXAREP@invalid.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test', 'Contact2')
            };
            lstContacts[1].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[1].email ='testSupplier@invalid.com';
            lstContacts[0].cTin_RelatedUser__c =user1.Id;
            insert lstContacts;

            /*lstContracts = new List<Contract__c>{TestFactory.createcTinContracts('Test Contract 01', supplier.Id, lstRecordTypes[0].id),
                                                 TestFactory.createcTinContracts('Test Contract 02', supplier.Id, lstRecordTypes[0].id)};
            lstContracts[0].OwnerId = UserInfo.getUserId();
            lstContracts[1].OwnerId = UserInfo.getUserId(); 
            lstContracts[0].cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;

            insert lstContracts;*/


            List<cTin_ContractTeam__c> lstContractTeam = new List<cTin_ContractTeam__c>();
            
            lstContracts = new List<Contract__c>();
            Contract__c contract = TestFactory.createContract(supplier.Id, 'TestContract', 'Draft');
            Contract__c contract2 = TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft');
            contract.OwnerId = UserInfo.getUserId();
            contract2.OwnerId = UserInfo.getUserId(); 
            contract.cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            lstContracts.add(contract);
            lstContracts.add(contract2);
            insert lstContracts;

            contract.OwnerId = UserInfo.getUserId();
            update contract;
            
            Group testGroup = new Group();
            testGroup.Name = 'testGroup';
            testGroup.DeveloperName = 'ABC';
            Insert testGroup;
            
            
            cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContracts[0].Id, cTin_TeamMember__c = user1.Id,
                                                                cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');
            cTin_ContractTeam__c ContractTeam2 = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContracts[1].Id, cTin_TeamMember__c = user1.Id,
                                                                cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');

            lstContractTeam.add(ContractTeam);
            lstContractTeam.add(ContractTeam2);

            insert lstContractTeam;

            lstLegalEntity = new List<cTin_LegalEntity__c>{ TestFactory.createLegalEntity(lstContracts[0].Id, entity.Id), 
                                                            TestFactory.createLegalEntity(lstContracts[1].Id, entity.Id)};
            insert lstLegalEntity;

            lstLocation = new List<cTin_Location__c>{TestFactory.createLocation(lstContracts[0].Id),
                                                     TestFactory.createLocation(lstContracts[1].Id)};                                                             
            insert lstLocation;
            
        }
    }

    static testMethod void test_InsertContractAndRelatedLists01(){

        System.runAs(user){
          
            test.startTest();
                PageReference pageRef = Page.VFP34_AmendContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[0].Id);
                VFC34_AmendContract ctrl = new VFC34_AmendContract(new ApexPages.StandardController(lstContracts[0]));
                ctrl.InsertContractAndRelatedLists();
                ctrl.newContractId();
            test.stopTest();
        }
    }

    static testMethod void test_InsertContractAndRelatedLists02(){

        System.runAs(user){
           
            test.startTest();
                PageReference pageRef = Page.VFP34_AmendContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[1].Id);
                VFC34_AmendContract ctrl = new VFC34_AmendContract(new ApexPages.StandardController(lstContracts[1]));
                ctrl.InsertContractAndRelatedLists();
            test.stopTest();
        }
    }

    static testMethod void test_InsertContractAndRelatedLists03(){
        System.runAs(user){
            test.startTest();
                VFC34_AmendContract ctrl = new VFC34_AmendContract(lstContracts[1].Id);
            test.stopTest();
        }
    }

    static testMethod void test_cloneStatus(){

        System.runAs(user){
           
            test.startTest();
                PageReference pageRef = Page.VFP34_AmendContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[1].Id);
                VFC34_AmendContract ctrl = new VFC34_AmendContract(new ApexPages.StandardController(lstContracts[1]));
                ctrl.cloneStatus();
            test.stopTest();
        }
    }

}