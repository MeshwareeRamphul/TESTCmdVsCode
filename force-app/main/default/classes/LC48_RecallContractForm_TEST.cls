@isTest
 private class LC48_RecallContractForm_TEST{
  /* 
  --------------------------------------------------------------------------------------
  -- - Name          : LC48_RecallContractForm_TEST
  -- - Author        : Spoon
  -- - Description   : resets contract status to In Progress and automatically rejects contract form
  --
  -- Maintenance History: 
  --
  -- Date         Name  Version  Remarks 
  -- -----------  ----  -------  -------------------------------------------------------
  -- 11-Jun-2020  MRA    1.0     (Bundle 3.4 =>SP-00185/SP-00319)
  *************************************************************************************/
  static Contract__c contract;
  static List<cTin_ContractForm__c> contractFormList;
  static User testUser;
  static esignature__c esignature;
  static Contact con;
  static esignatory__c esignatory;
  
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
      contract = TestFactory.createContract(supplier.Id, 'cTinSuplierName', 'In Signature');
      insert contract; 

      //--CTIN--//
      contractFormList = TestFactory.createContractForm(testUser.id, contract.Id);
      insert contractFormList;
      //--END CTIN--//
      
      con=TestFactory.createContact(supplier,'Kim','Brown2');
      insert con;
      
      //create esignature
      esignature= TestFactory.createEsignature(contract, 'Test Esignature', AP_Constant.eSignatureCreatedStatus);
      insert eSignature;
         
      //creating esignatory  
      esignatory=TestFactory.createEsignatory(contract, esignature, 'James', con.id, AP_Constant.esignatoryStatusNotStarted);
      insert esignatory;
        
    }//end runAs
          
  }//end static
  
 
  static testmethod void CfStatusNullTest(){
    system.debug('Starting method CfStatusNullTest');
    
    system.runAs(testUser){
  
        test.startTest();      
            LC48_RecallContractForm.callVFCMethod(contract.id);
        test.stopTest();
      }
      system.debug('Ending method CfStatusNullTest');
    }
    
 
  }