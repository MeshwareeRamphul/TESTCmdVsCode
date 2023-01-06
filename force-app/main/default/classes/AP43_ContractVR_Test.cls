@isTest

public class AP43_ContractVR_Test {
    /*
    // AP43_ContractVR_Test
    ----------------------------------------------------------------------
    -- - Name          : AP43_ContractVR_Test
    -- - Author        : Spoon Consulting 
    -- - Description   : Test class AP43_ContractVR_Test
                                             
    --                                       
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 14-DEC-2017  SBH    1.0      Intitial version
    ----------------------------------------------------------------------
    **********************************************************************
    */

    static User use, use1;
    static Account supplier;
    static cTin_Entity__c entity;
    static string role_legal_rep;
    static string role_business_owner;
    static Contract__c contract;
    static String contractInProgressRtId;
    static String contractInDraftRtId;
    static 
    {
        role_legal_rep = '009';
        role_business_owner = '016';
        use = TestFactory.createUser('testUser', UserInfo.getProfileId(), true);
        insert use;
        System.runAs(use){
    
            use1 = TestFactory.createUser('test2' , UserInfo.getProfileId(), true);
            use1.PAD_BypassValidationRules__c = false;
            use1.PAD_BypassTrigger__c = 'AP1012';
            use1.PAD_BypassWorkflows__c = true;
            insert use1;

            supplier = TestFactory.createSupplier('TestSupplier' , 'City', 'France');
            insert supplier;

            entity = TestFactory.createEntity();
            insert entity;
        }

        contractInProgressRtId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId();
        contractInDraftRtId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId();
    }

    static testMethod void testBeforeInsert(){

        boolean TestPassed = false;


        System.runAs(use1){
            contract = TestFactory.createcTinContracts('testContract' , supplier.Id, contractInProgressRtId);
            contract.cTin_ContractSegment__c = null;
            contract.EndDate__c = null;
            contract.cTin_MainAPCL0__c = null;
            contract.cTin_OrganizationalScope__c = null;
            contract.cTin_ShortDescription__c = null;
            contract.StartDate__c = null;
            contract.cTin_SupplierAccount__c = null;
            contract.cTin_TypeOfDocument__c = null;
            contract.cTin_AXAMainLegalSignatoryEntity__c = null;
            contract.cTin_DataPrivacyClause__c=null;
            contract.VISCA_Level__c=null;

            Test.startTest();
                try{
                    insert contract;
                }catch(Exception e){
                    TestPassed = true;
                }
            Test.stopTest();

            System.assertEquals(true, TestPassed);
        }
    }

    static testMethod void testBeforeUpdate(){

        boolean TestPassed = false;


        System.runAs(use1){
            
            Contract__c testContract = new Contract__c();
            testContract.Name = 'Testcontract2';
            testContract.Status__c = 'Draft';
            testContract.RecordTypeId = contractInDraftRtId;
            insert testContract;
            
            testContract.recordtypeId=contractInProgressRtId;
            testcontract.status__c='In Progress';
            
            Test.startTest();
                try{
                    update testcontract;
                }
                catch(Exception e){
                    TestPassed = true;
                }
                ContractTriggerHandler.dummmyTest();
            Test.stopTest();

            System.assertEquals(true, TestPassed);

            /*contract = TestFactory.createcTinContracts('testContract2' , supplier.Id, contractInProgressRtId);
                
            contract.Status__c = 'In Progress';
            contract.cTin_ContractSegment__c = null;
            contract.EndDate__c = null ;
            contract.cTin_MainAPCL0__c = null;
            contract.cTin_OrganizationalScope__c = null;
            contract.cTin_ShortDescription__c = null;
            contract.StartDate__c = null;
            contract.cTin_SupplierAccount__c = null;
            contract.cTin_TypeOfDocument__c = null;
            contract.cTin_AXAMainLegalSignatoryEntity__c = null;
            contract.cTin_DataPrivacyClause__c=null;
            contract.VISCA_Level__c=null;
            
            try{
                update contract;
            }
            catch(Exception e){
                System.debug('## TestbeforeUpdate exception' + e);
            }

          /*  contract.Status__c = 'In Progress';
            contract.RecordTypeId = contractInProgressRtId;

            Test.startTest();
                try{
                    update contract;
                }
                catch(Exception e){
                    TestPassed = true;
                }
            Test.stopTest();

            System.assertEquals(true, TestPassed);*/
        }
    }
}