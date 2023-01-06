@isTest
public class VFC35_TransactContract_TEST {
/*
----------------------------------------------------------------------
-- - Name          : VFC35_TransactContract_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class for VFC35_TransactContract
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 18-JAN-2016  RLA    1.0      Intitial version
-- 23-OCT-2017  SBH    1.1      Contract-in All-In merge
-- 15-JAN-2020  SGO    1.2      Rework - cTin
----------------------------------------------------------------------
**********************************************************************
*/
    static List<User> lstUsers;
    static Account supplier;
    static Account axaRep;
    static Profile profile;
    static cTin_Entity__c entity;
    static string role_legal_rep;
    static string role_business_owner;
    static List<Contract__c> lstContracts;
    static Group grp; 
    static List<cTin_ContractTeam__c> lstContractTeams;
    static List<cTin_LegalEntity__c> lstLegalEntity;
    static List<cTin_Location__c> lstLocation;
    static List<Contact> lstContacts;

    static{
        role_legal_rep = '009';
        role_business_owner = '016';

        List<Profile> profileList = [SELECT id FROM profile where NAME like '%cTin%'];

        List<RecordType> lstRecordTypes = [SELECT Id,
                                                  developerName,
                                                  Name,
                                                  sObjectType
                                             FROM RecordType
                                            WHERE sObjectType = 'Contract__c'
                                              AND DeveloperName LIKE 'cTin_%'];

        if (profileList.size()>0) profile = profileList.get(0); 
        else throw new System.Nullpointerexception();

        lstUsers = new List<User>{TestFactory.createUser('TestUser1', UserInfo.getProfileId(), true),
                                  TestFactory.createUser('TestUser2', profile.Id, true),
                                  TestFactory.createUser('TestUser3', profile.Id, true)};
        lstUsers[0].PAD_BypassTrigger__c = 'AP40';
        lstUsers[0].Bypass_FieldFilter__c=true;
        insert lstUsers;
        
        System.runAs(lstUsers[0]){
            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier;
            axaRep = TestFactory.createSupplier('testAXARep' , 'Paris' , 'France');
            axaRep.RecordTypeId=Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            insert axaRep;

            // Create contact
            lstContacts = new List<Contact>{
                TestFactory.createContactAXARep('test', 'AxaRep', axaRep.Id, 'testAXAREP@invalid.com', Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('AXA').getRecordTypeId()),

                TestFactory.createContact(supplier, 'Test', 'Contact2')
            };
            lstContacts[1].RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            lstContacts[1].email ='testSupplier@invalid.com';
            lstContacts[0].cTin_RelatedUser__c =lstUsers[1].Id;
            insert lstContacts;

            entity = new cTin_Entity__c (Name = 'test', cTin_Organization__c = '700 - AXA France', cTin_Country__c= 'France');
            insert entity;




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
            
            
            cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContracts[0].Id, cTin_TeamMember__c = lstUsers[0].Id,
                                                                cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');
            cTin_ContractTeam__c ContractTeam2 = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContracts[1].Id, cTin_TeamMember__c = lstUsers[0].Id,
                                                                cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');

            lstContractTeam.add(ContractTeam);
            lstContractTeam.add(ContractTeam2);

            insert lstContractTeam;

        }
    }

    static testmethod void test_InsertContractAndRelatedLists01(){
        
        System.runAs(lstUsers[0]){
         
            test.startTest();
                PageReference pageRef = Page.VFP35_TransactContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[0].Id);
                VFC35_TransactContract ctrl = new VFC35_TransactContract(new ApexPages.StandardController(lstContracts[0]));
                ctrl.InsertContractAndRelatedLists();
            test.stopTest();

            string name = /*label.cTin_tranName + ' '+*/lstContracts[0].Name;
            System.assertEquals (ctrl.newContract.Name,name);
            System.assertEquals (ctrl.newContract.cTin_TypeOfDocument__c,label.cTin_tranTypeOfDoc);
            System.assertEquals (ctrl.newContract.status__c,label.cTin_amendStatus);
            System.assertEquals (ctrl.newContract.cTin_ParentContract__c,lstContracts[0].Id);
            System.assertEquals (ctrl.newContract.cTin_Reminder__c,/*label.cTin_tranReminder*/'');
            System.assertEquals (ctrl.newContract.cTin_RetentionPeriod__c,label.cTin_tranRetentionPeriod);
            //System.assertEquals (ctrl.newContract.cTin_BusinessOwner__c,Null);
            System.assertEquals (ctrl.newContract.cTin_SignatureDate__c,Null);
            System.assertEquals (ctrl.newContract.StartDate__c,Null);
            System.assertEquals (ctrl.newContract.EndDate__c,Null);
            System.assertEquals (ctrl.newContract.cTin_EarlyTerminationDate__c,Null);
            System.assertEquals (ctrl.newContract.cTin_NoticePeriodForTermination__c,Null);
            System.assertEquals (ctrl.newContract.cTin_AXAMainLegalSignatoryEntity__c,Null);
            System.assertEquals (ctrl.newContract.cTin_AXASignatoryRepresentative__c,Null);
            System.assertEquals (ctrl.newContract.cTin_LegacyId__c,'');
            System.assertEquals (ctrl.newContract.LinkToDocument__c,'');
            System.assertEquals (ctrl.newContract.cTin_TacitRenewalComments__c,'');
            System.assertEquals (ctrl.newContract.cTin_OtherAXASignatoryEntity__c,'');
            System.assertEquals (ctrl.newContract.cTin_Unlimited__c,false);
            System.assertEquals (ctrl.newContract.cTin_TacitRenewal__c,false);
            System.assertEquals (ctrl.newContract.cTin_confidential__c,false);
            System.assertEquals (ctrl.newContract.cTin_OtherAXASignatoryEntityPicklist__c,'No');
        }  

    }

    static testmethod void test_InsertContractAndRelatedLists02(){
        
        System.runAs(lstUsers[0]){
           
            test.startTest();
                PageReference pageRef = Page.VFP35_TransactContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[1].Id);
                VFC35_TransactContract ctrl = new VFC35_TransactContract(new ApexPages.StandardController(lstContracts[1]));
                ctrl.InsertContractAndRelatedLists();

                string name = /*label.cTin_tranName + ' '+*/lstContracts[1].Name;
                System.assertEquals (ctrl.newContract.Name,name);
                System.assertEquals (ctrl.newContract.cTin_TypeOfDocument__c,label.cTin_tranTypeOfDoc);
                System.assertEquals (ctrl.newContract.status__c,label.cTin_amendStatus);
                System.assertEquals (ctrl.newContract.cTin_ParentContract__c,lstContracts[1].Id);
                System.assertEquals (ctrl.newContract.cTin_Reminder__c,/*label.cTin_tranReminder*/'');
                System.assertEquals (ctrl.newContract.cTin_RetentionPeriod__c,label.cTin_tranRetentionPeriod);
                //System.assertEquals (ctrl.newContract.cTin_BusinessOwner__c,Null);
                System.assertEquals (ctrl.newContract.cTin_SignatureDate__c,Null);
                System.assertEquals (ctrl.newContract.StartDate__c,Null);
                System.assertEquals (ctrl.newContract.EndDate__c,Null);
                System.assertEquals (ctrl.newContract.cTin_EarlyTerminationDate__c,Null);
                System.assertEquals (ctrl.newContract.cTin_NoticePeriodForTermination__c,Null);
                System.assertEquals (ctrl.newContract.cTin_AXAMainLegalSignatoryEntity__c,Null);
                System.assertEquals (ctrl.newContract.cTin_AXASignatoryRepresentative__c,Null);
                System.assertEquals (ctrl.newContract.cTin_LegacyId__c,'');
                System.assertEquals (ctrl.newContract.LinkToDocument__c,'');
                System.assertEquals (ctrl.newContract.cTin_TacitRenewalComments__c,'');
                System.assertEquals (ctrl.newContract.cTin_OtherAXASignatoryEntity__c,'');
                System.assertEquals (ctrl.newContract.cTin_Unlimited__c,false);
                System.assertEquals (ctrl.newContract.cTin_TacitRenewal__c,false);
                System.assertEquals (ctrl.newContract.cTin_confidential__c,false);
                System.assertEquals (ctrl.newContract.cTin_OtherAXASignatoryEntityPicklist__c,'No');
                VFC35_TransactContract ctrl2 = new VFC35_TransactContract(lstContracts[1].Id);
            test.stopTest();
        }

    }

    static testmethod void test_cloneStatus(){
        System.runAs(lstUsers[0]){
            test.startTest();
                PageReference pageRef = Page.VFP35_TransactContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', lstContracts[1].Id);
                VFC35_TransactContract ctrl = new VFC35_TransactContract(new ApexPages.StandardController(lstContracts[1]));
                ctrl.cloneStatus();
            test.stopTest();
        }
    }
}