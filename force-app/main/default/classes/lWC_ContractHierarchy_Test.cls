/* --------------------------------------------------------------------------------------
    -- - Name          : lWC_ContractHierarchy_Test
    -- - Author        : AMA
    -- - Description   : test class for lWC_ContractHierarchy
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 09-JUN-2022  AMA    1.0     Initial version
    --------------------------------------------------------------------------------------*/
@isTest
public with sharing class lWC_ContractHierarchy_Test {
    static List<User> lstUser = new list<User>();
    static User testUser;
    static List<contract__c> lstCtr;
    
    static{      
        for(integer i=0;i<3;i++){
            lstUser.add(TestFactory.createUsercTin('Testuser'+ i , UserInfo.getProfileId(), true));          
        }
        insert lstUser;

        //lstUser[0].PAD_BypassTrigger__c = 'AP40;AP25';
        lstUser[0].PAD_BypassValidationRules__c =true;
        //lstUser[0].cTin_Universign__c = true;
        update lstUser;
        testUser = lstUser[0];


        System.runAs(testUser){
            //Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(lstUser[0]);

            Account vAccount = new Account();
            vAccount.Name = 'account test';
            vAccount.OwnerId = lstUser[0].Id;
            vAccount.Account_Manager__c = lstUser[0].Id;
            vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_LEGAL_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
            vAccount.SAP_Account_Number__c = '234';
            vAccount.Signature_Type__c = 'Manual';
            vAccount.Active__c = true;
            vAccount.Language__c = 'English';
            vAccount.GIE_AXA_GS_Member__c = 'No';
            //vAccount.Delegation__c = 'No';
            //vAccount.cTin_TOBA_needed__c = 'No';
            insert vAccount;

			//create contract
            lstCtr = new List<contract__c>{
                TestFactory.createContract(vAccount.Id, 'Ctr racine', 'Draft'),
                TestFactory.createContract(vAccount.Id, 'Ctr child1', 'Draft'),
                TestFactory.createContract(vAccount.Id, 'Ctr child2', 'Draft'),
                TestFactory.createContract(vAccount.Id, 'Ctr child child1', 'Draft')
            };
            insert lstCtr;

            lstCtr[1].cTin_ParentContract__c = lstCtr[0].id;
            lstCtr[2].cTin_ParentContract__c = lstCtr[0].id;
            lstCtr[3].cTin_ParentContract__c = lstCtr[1].id;
            update lstCtr;
        }
    }

    @isTest
    static void getHierarchy(){
        System.runAs(testUser){
            test.startTest();
            lWC_ContractHierarchy.getContractHierarchy(lstCtr[3].id);
            test.stopTest();
        }
    }
}