@isTest(seeAllData=false)
private class cTin_contractFormHandler_TEST{
 /* 
--------------------------------------------------------------------------------------
-- - Name          : Test_ContractForm_AfterUpdate
-- - Author        : Spoon Consulting 
-- - Description   : test class for ContractForm_AfterUpdate
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 30-NOV-2015  MRA    1.0     Initial version
/*--------------------------------------------------------------------------------------*/

  static Contract__c contract;
  static List<cTin_ContractForm__c> contractFormList;
  static User testUser;

  static{
    
    //creating user with universign
    testUser = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
    testUser.PAD_BypassValidationRules__c = true;
    testUser.PAD_BypassWorkflows__c = true;
    testUser.cTin_LegalRepresentative__c = true;
    testUser.IsActive = true;
    testUser.cTin_UniverSign__c=true;
    insert testUser;
    
    system.runAs(testUser){
      //creating account
      Account supplier = TestFactory.createSupplier('cTinTestSupplier' , 'tinTestaddr', 'France');
      insert supplier;
      
      //creating contract
      contract = TestFactory.createContract(supplier.Id, 'cTinSuplierName', 'Draft');
      insert contract; 

      //--CTIN--//
      contractFormList = TestFactory.createContractForm(testUser.id, contract.Id);
      insert contractFormList;
      //--END CTIN--//
        
    }//end runAs
          
  }//end static
  
 
  static testmethod void CfStatusNullTest(){
    system.debug('Starting method CfStatusNullTest');
    
    system.runAs(testUser){
     
         /*List<cTin_ContractForm__c> contractFormList=[select cTin_Contract__c,cTin_FinalApprovalStatus__c 
                                                 from cTin_ContractForm__c 
                                                 where cTin_Contract__c=:contract.id];*/
         contractFormList[0].cTin_FinalApprovalStatus__c ='test';

          test.startTest();      
              update contractFormList;
          test.stopTest();
        }
        system.debug('Ending method CfStatusNullTest');
    }
    
    static testmethod void CfStatusNotNullTest(){
    system.debug('Starting method CfStatusNotNullTest');
    
    system.runAs(testUser){
     
     /*List<cTin_ContractForm__c> contractFormList=[select cTin_Contract__c,cTin_FinalApprovalStatus__c 
                                             from cTin_ContractForm__c 
                                             where cTin_Contract__c=:contract.id];*/
     contractFormList[0].cTin_FinalApprovalStatus__c ='test';
     update contractFormList;
     
     contractFormList[0].cTin_FinalApprovalStatus__c ='';
      test.startTest();      
          update contractFormList;
      test.stopTest();
      
      AP39_ContractInMethods.dummy();
    }
    system.debug('Ending method CfStatusNotNullTest');
    }
  }