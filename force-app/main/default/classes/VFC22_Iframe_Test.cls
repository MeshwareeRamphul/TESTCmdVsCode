@isTest
private class VFC22_Iframe_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_Iframe_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC22_Iframe
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 06-JUN-2017  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
  static User testUser;
  static list<Esignature__c> esignatureLst=new list<Esignature__c>();
  static list<Contract__c> contractLst=new list<Contract__c>();
  static Account supplier;

  static{
    testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
    insert testUser;

    system.runAs(testUser){
      supplier = TestFactory.createSupplier('supplier 1','Paris','France');
      insert supplier;

      contract__c contract1 = TestFactory.createContract(supplier.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
      contract__c contract2 = TestFactory.createContract(supplier.Id,'Contract2',AP_Constant.contractCustValidationStatus);
      contractLst.add(contract1);  
      contractLst.add(contract2);               
      insert contractLst;

      Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
      Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
      esignatureLst.add(esignature1);
      esignatureLst.add(esignature2);
      insert esignatureLst;

    }    
  }

  //test scenario - redirect to esignature id passed in url
  static testMethod void redirect_test(){
    system.runAs(testUser){
        VFC22_Iframe controller;
        test.startTest();
            PageReference pageRef = Page.VFP22_AxaExecSign;
            pageRef.getParameters().put('eSignatureId',esignatureLst[0].Id);
            Test.setCurrentPage(pageRef);  
            controller = new VFC22_Iframe();
        test.stopTest();
        system.assertNotEquals(null,controller.redirect());        
    }

  }

}