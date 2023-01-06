@isTest
private class AP22_IpadPurpose_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_IpadPurpose_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP22_IpadPurpose
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 05-JUN-2017  MRA    1.0     Initial version
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
          esignatory1.mobileTxt__c='54654654';
          esignatory2.mobileTxt__c='546546544';
          esignatory3.mobileTxt__c='54654754';
          esignatory4.mobileTxt__c='54654854';
          esignatoryLst.add(esignatory1);
          esignatoryLst.add(esignatory2);
          esignatoryLst.add(esignatory3);
          esignatoryLst.add(esignatory4);
          insert esignatoryLst;

        }    
    }

    static testmethod void updateSignLink_test(){
        system.runAs(testUser){
            
            esignatoryLst[0].SignURL__c='https://test.com';
            esignatoryLst[3].SignURL__c='https://test.com';
            update esignatoryLst;

            esignatoryLst[0].status__c=AP_Constant.esignatoryStatusReady;       
            esignatoryLst[3].status__c=AP_Constant.esignatoryStatusReady;

            test.startTest();
                update esignatoryLst;
            test.stopTest();

            List<Esignature__c> esignatures=[select signURL__c from Esignature__c where id IN:esignatureLst];
            system.assertEquals('https://test.com',esignatures[0].signURL__c);
            system.assertEquals('https://test.com',esignatures[1].signURL__c);
        }
    }   

}