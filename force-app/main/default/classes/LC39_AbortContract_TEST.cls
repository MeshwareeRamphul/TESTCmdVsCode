@IsTest
public with sharing class LC39_AbortContract_TEST {
/*
----------------------------------------------------------------------
-- - Name          : LC39_AbortContract_TEST
-- - Author        : SPOON
-- - Description   : Test class for controller LC39_AbortContract
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 26-FEB-2020   SGO    1.0       Initial version 
--------------------------------------------------------------------------- 
*/

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

        lstUsers[0].PAD_BypassTrigger__c = 'AP40';
        lstUsers[1].PAD_BypassTrigger__c = 'AP40';
        update lstUsers;

        System.runAs(lstUsers[0]){
            supplier = TestFactory.createSupplier('testAcc' , 'BillingCity' , 'France');
            insert supplier;
            
            entity = new cTin_Entity__c(Name = 'testEntity');
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
    static void testAbortContractDraft(){
        
        System.runAs(lstUsers[0]){

            Test.startTest();

                String message = LC39_AbortContract.abort(lstCtrs[0].Id);
                System.debug('message ' + message);
                
            Test.stopTest();

            System.assertEquals(System.Label.LC39_CtrAbortSuccess, message);
        }
        
    }

    @IsTest
    static void testAbortContractInProgress(){
        
        System.runAs(lstUsers[0]){
            // Status In progress
            lstCtrs[0].Status__c = 'In Progress';
            update lstCtrs;

            Test.startTest();

                String message = LC39_AbortContract.abort(lstCtrs[0].Id);
                System.debug('message ' + message);
                
            Test.stopTest();

            System.assertEquals(System.Label.LC39_CtrAbortSuccess, message);
        }
        
    }

    @IsTest
    static void testAbortContractOtherStatus(){
        
        System.runAs(lstUsers[0]){
            // Status Expired
            lstCtrs[0].Status__c = 'Expired';
            update lstCtrs;

            Test.startTest();

                String message = LC39_AbortContract.abort(lstCtrs[0].Id);
                System.debug('message ' + message);
                
            Test.stopTest();

            System.assertEquals(System.Label.LC39_CtrAbortFailed, message);
        }
        
    }

      @IsTest
    static void testAbortContractAborted(){
        
        System.runAs(lstUsers[0]){
            // Status Aborted
            lstCtrs[0].Status__c = 'Aborted';
            update lstCtrs;

            Test.startTest();

                String message = LC39_AbortContract.abort(lstCtrs[0].Id);
                System.debug('message ' + message);
                
            Test.stopTest();

            System.assertEquals(System.Label.LC39_AlreadyAbort, message);
        }
        
    }

     @IsTest
    static void testException(){
        
        System.runAs(lstUsers[0]){
            // No contract => Exception
            delete lstCtrs;

            Test.startTest();

                String message = LC39_AbortContract.abort(lstCtrs[0].Id);
                System.debug('message ' + message);
                
            Test.stopTest();

            System.assertEquals('List index out of bounds: 0', message);
        }
        
    }

   
}