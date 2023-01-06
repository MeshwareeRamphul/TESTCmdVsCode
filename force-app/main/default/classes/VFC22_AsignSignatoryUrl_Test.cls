@isTest
public class VFC22_AsignSignatoryUrl_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_AsignSignatoryUrl_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC22_AsignSignatoryUrl
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
  static list<Account>supplierLst=new list<Account>();
  static list<Esignatory__c> esignatoryLst=new list<Esignatory__c>();
  static list<Contact> contactLst=new list<Contact>();

  static{
    testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
    insert testUser;

    system.runAs(testUser){
      Account supplier1 = TestFactory.createSupplier('supplier 1','Paris','France');
      Account supplier2 = TestFactory.createSupplier('supplier 2','Paris','France');
      supplierLst.add(supplier1);
      supplierLst.add(supplier2);
      insert supplierLst;

      Contact con1=TestFactory.createContact(supplier1,'James','Brown');
      Contact con2=TestFactory.createContact(supplier1,'Jim','Brown');
      Contact con3=TestFactory.createContact(supplier1,'Kate','Brown');
      Contact con4=TestFactory.createContact(supplier1,'Kim','Brown');
      contactLst.add(con1);
      contactLst.add(con2);
      contactLst.add(con3);
      contactLst.add(con4);
      insert contactLst;

      contract__c contract1 = TestFactory.createContract(supplier1.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
      contract__c contract2 = TestFactory.createContract(supplier2.Id,'Contract2',AP_Constant.contractCustValidationStatus);
      contractLst.add(contract1);  
      contractLst.add(contract2);               
      insert contractLst;

      Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
      Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
      esignatureLst.add(esignature1);
      esignatureLst.add(esignature2);
      insert esignatureLst;

      Esignatory__c esignatory1= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'James',contactLst[0].id,AP_Constant.esignatoryStatusNotStarted);
      Esignatory__c esignatory2= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'Jim',contactLst[1].id,AP_Constant.esignatoryStatusNotStarted);
      Esignatory__c esignatory3= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kate',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
      Esignatory__c esignatory4= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kim',contactLst[3].id,AP_Constant.esignatoryStatusNotStarted);
      esignatory1.mobileTxt__c='515655646';
      esignatory2.mobileTxt__c='5156556586';
      esignatory3.mobileTxt__c='51565586846';
      esignatory4.mobileTxt__c='5156578646';
      esignatoryLst.add(esignatory1);
      esignatoryLst.add(esignatory2);
      esignatoryLst.add(esignatory3);
      esignatoryLst.add(esignatory4);
      insert esignatoryLst;

      esignatoryLst[0].signURL__c='https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';
      esignatoryLst[1].signURL__c='https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e375';
      update esignatoryLst;

    }    
  }

  //test scenario - assign signatory url when signurl is populated
  static testMethod void assignUrlWithsignUrl_test(){
    system.runAs(testUser){
        VFC22_AsignSignatoryUrl controller;
        test.startTest();
            PageReference pageRef = Page.VFP22_AssignSignatoryUrl;
            pageRef.getParameters().put('eSignatureId',esignatureLst[0].Id);
            Test.setCurrentPage(pageRef);  
            controller = new VFC22_AsignSignatoryUrl();
            controller.asignURL();
        test.stopTest();
        //system.assertNotEquals(null,controller.asignURL());
    }

  }
  
  //test scenario - assign signatory url when signurl is not populated
  static testMethod void assignUrlWithoutsignUrl_test(){
    system.runAs(testUser){
        VFC22_AsignSignatoryUrl controller;
        test.startTest();
            PageReference pageRef = Page.VFP22_AssignSignatoryUrl;
            pageRef.getParameters().put('eSignatureId',esignatureLst[1].Id);
            Test.setCurrentPage(pageRef);  
            controller = new VFC22_AsignSignatoryUrl();
            controller.asignURL();
        test.stopTest();
        //system.assertEquals(null,controller.asignURL());
    }

  }
  
}