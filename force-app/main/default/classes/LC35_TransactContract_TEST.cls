@isTest
public with sharing class LC35_TransactContract_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC35_TransactContract_TEST
-- - Author        : SGO
-- - Description   : Test class for class LC35_TransactContract
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 06-JAN-2020   SGO    1.0       Initial version 
--------------------------------------------------------------------------- */
    static List<User> lstUsers = new List<user>();
    static List<Contract__c> lstCtrs;
    
    static{
        
        Account supplier;
        cTin_Entity__c entity;
        cTin_LegalEntity__c legalEntity;
        cTin_Location__c Location;

        String profNames = 'System Administrator;cTin - Stakeholder / Legal / Audit';
        List<Profile> lstProfiles = new List<Profile>();
        List<String> lstProfNames = profNames.split(';');
        lstProfiles = [select Id, Name from Profile Where Name in :lstProfNames ORDER BY Name ASC];
        
        for (Profile currentProf : lstProfiles){
            lstUsers.add(TestFactory.createUser('usrTest' , currentProf.Id, true));
        }
        insert lstUsers;

        lstUsers[1].PAD_BypassTrigger__c = 'AP40';
        lstUsers[1].Bypass_FieldFilter__c=true;
        lstUsers[1].PAD_BypassValidationRules__c = true;
        update lstUsers;

        System.runAs(lstUsers[1]){
            supplier = TestFactory.createSupplier('testAcc' , 'BillingCity' , 'France');
			insert supplier;
			
			entity = new cTin_Entity__c(Name = 'test');
			insert entity;

			lstCtrs = new List<Contract__c>{
                TestFactory.createContract(supplier.id, 'TestCtr1', 'Draft')
            };
			insert lstCtrs;

			legalEntity = TestFactory.createLegalEntity(lstCtrs[0].id, entity.id);
			insert legalEntity;

			Location = TestFactory.createLocation(lstCtrs[0].id);
			insert Location;

        }
    }

    @IsTest
    static void testTransactContract(){
        
        System.runAs(lstUsers[1]){
            Test.startTest();

                Map<string,object> mapResult = LC35_TransactContract.validateTransact(lstCtrs[0].Id);

            Test.stopTest();

            System.assert(mapResult.keySet().contains('newcontact'));
            System.assert(String.valueOf(mapResult.get('newcontact')).startsWith('a0D'));
        }
        
    }


     @IsTest
    static void testTransactContractErrorStakeholder(){
        
        System.runAs(lstUsers[0]){
            Test.startTest();

                Map<string,object> mapResult = LC35_TransactContract.validateTransact(lstCtrs[0].Id);
               
            Test.stopTest();

            System.assert(mapResult.keySet().contains('error'));
            System.assertEquals(system.label.cTin_btnDuplicateError, String.valueOf(mapResult.get('error')));
        }
        
    }

    

    
}