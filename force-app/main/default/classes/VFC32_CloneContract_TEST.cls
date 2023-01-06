@isTest
/** 
 * This test class tests VF_CloneContract Controller
 * Created by: Zohar Sinay
 * Last Modified Date: 05/02/2015
 *
 * -- Maintenance History: 
 * --
 * -- Date         Name     Version  Remarks 
 * -- -----------  ----     -------  -------------------------------------------------------
 * -- 27-JUL-2015  SC-NJA   1.1      Contract Team, donot clone Legal Representatives & Business Owner
 * -- 18-JAN-2015  SC-RLA   1.2      Legal Enity and Location
 * -- 32-OCT-2017  SC-SBH   1.3      All in merge
 * -- 13-JAN-2020  SC-SGO   1.4      Reworked - cTin
 * -- 10-DEC-2021  SC-MBE   1.5      Reworked for Coverage Error 
 */

public class VFC32_CloneContract_TEST {

    static testMethod void testRoleBusinessOwner(){

        Account supplier;
        Account axaRep;
        Contract__c contract;
        Group testGroup;
        cTin_Entity__c entity;
        List<cTin_ContractTeam__c> lstContractTeams = new List<cTin_ContractTeam__c>();
        List<Contact> lstContacts;
        cTin_LegalEntity__c legalEntity;
        cTin_Location__c Location;
        List<User> lstUser;

        lstUser = new List<User>{
            TestFactory.createUser('testAdmin' , UserInfo.getProfileId(), true),
            TestFactory.createUser('testUser' , TestFactory.getProfileIdByName('cTin - Stakeholder / Legal / Audit'), true)
        };

        lstUser[1].PAD_BypassTrigger__c = 'AP40;AP39;';
        lstUser[1].Bypass_FieldFilter__c=true;
        lstUser[1].PAD_BypassValidationRules__c = true;
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40;AP39;';
        lstUser[0].Bypass_FieldFilter__c=true;
        lstUser[0].PAD_BypassValidationRules__c = true;
        update lstUser[0];

        System.runAs(lstUser[0]){
            AP44_BlockNewContractTeam.bypassSpecial=true;
            // Create Account
            supplier = TestFactory.createSupplier('testAccSupplier' , 'BillingCity' , 'France');
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
            insert lstContacts;

            // Create Contract
            contract = TestFactory.createContract(supplier.id, 'TestName', 'Draft');
            insert contract;
            contract.OwnerId = UserInfo.getUserId();
            contract.cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            update contract;

            // Create Group of ContractTeam
            testGroup = new Group(Name = 'testGroup' , DeveloperName='ABC');
            Insert testGroup;

            // Create Contract Team
            // role=businessowner, Teammember != contract.businessOwner
            lstContractTeams.add(TestFactory.createContractTeam('016', contract.id, lstUser[1].id, null, '1' , 'Read'));
            // Role=businessOwner, Teammember == contract.businessOwner
            lstContractTeams.add(TestFactory.createContractTeam('016', contract.id, lstUser[0].id, null, '2' , 'Read'));
            insert lstContractTeams;

            entity = new cTin_Entity__c(Name = 'test');
            insert entity;

            legalEntity = TestFactory.createLegalEntity(contract.id, entity.id);
            insert legalEntity;

            Location = TestFactory.createLocation(contract.id);
            insert Location;

            test.startTest();
                PageReference pageRef = Page.VFP32_CloneContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', contract.Id);
                VFC32_CloneContract cloneCtr = new VFC32_CloneContract(new ApexPages.StandardController(contract));
                cloneCtr.InsertContractAndRelatedLists();

                String err = cloneCtr.cloneStatus(); 
                String newConId = cloneCtr.newContractId();  

                System.assertEquals('', err);
                System.assertNotEquals(null, newConId);
            test.stopTest();    
        }

    }

    static testMethod void testRoleOther(){

        Account supplier;
        Account axaRep;
        Contract__c contract;
        Group testGroup;
        cTin_Entity__c entity;
        List<cTin_ContractTeam__c> lstContractTeams = new List<cTin_ContractTeam__c>();
        List<Contact> lstContacts;
        cTin_LegalEntity__c legalEntity;
        cTin_Location__c Location;
        List<User> lstUser;

        lstUser = new List<User>{
            TestFactory.createUser('testAdmin' , UserInfo.getProfileId(), true),
            TestFactory.createUser('testUser' , TestFactory.getProfileIdByName('cTin - Stakeholder / Legal / Audit'), true)
        };

        lstUser[1].PAD_BypassTrigger__c = 'AP40;AP39;';
        lstUser[1].Bypass_FieldFilter__c=true;
        lstUser[1].PAD_BypassValidationRules__c = true;
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40;AP39;';
        lstUser[0].Bypass_FieldFilter__c=true;
        lstUser[0].PAD_BypassValidationRules__c = true;
        update lstUser[0];

        System.runAs(lstUser[0]){
        
           AP44_BlockNewContractTeam.bypassSpecial=true;
            // Create Account
            supplier = TestFactory.createSupplier('testAccSupplier' , 'BillingCity' , 'France');
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
            insert lstContacts;

            // Create Contract
            contract = TestFactory.createContract(supplier.id, 'TestName', 'Draft');
            insert contract;
            contract.OwnerId = UserInfo.getUserId();
            contract.cTin_AXASignatoryRepresentative__c = lstContacts[0].Id;
            update contract;

            // Create Group of ContractTeam
            testGroup = new Group(Name = 'testGroup' , DeveloperName='ABC');
            Insert testGroup;

            // Create Contract Team
            // role=other
            lstContractTeams.add(TestFactory.createContractTeam('001', contract.id, lstUser[1].id, null, '1' , 'Read'));
            // Role=other
            lstContractTeams.add(TestFactory.createContractTeam('001', contract.id, lstUser[0].id, null, '2' , 'Read'));
            insert lstContractTeams;

            entity = new cTin_Entity__c(Name = 'test');
            insert entity;

            legalEntity = TestFactory.createLegalEntity(contract.id, entity.id);
            insert legalEntity;

            Location = TestFactory.createLocation(contract.id);
            insert Location;

            test.startTest();
                PageReference pageRef = Page.VFP32_CloneContract;
                Test.setCurrentPage(PageRef);
                ApexPages.currentPage().getParameters().put('id', contract.Id);
                VFC32_CloneContract cloneCtr = new VFC32_CloneContract(new ApexPages.StandardController(contract));
                cloneCtr.InsertContractAndRelatedLists();

                String err = cloneCtr.cloneStatus(); 
                String newConId = cloneCtr.newContractId();

                System.assertEquals('', err);
                System.assertNotEquals(null, newConId);
                VFC32_CloneContract cloneCtr2 = new VFC32_CloneContract(contract.Id);
            test.stopTest();    
        }

    }
}