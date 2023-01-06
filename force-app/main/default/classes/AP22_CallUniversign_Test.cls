@isTest
private class AP22_CallUniversign_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_CallUniversign_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP22_CallUniversign
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
          Contact con2=TestFactory.createContact(supplier1,'Jim',null);
          Contact con3=TestFactory.createContact(supplier1,null,'Brown');
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
          esignatory1.code__c='email';
          esignatory2.code__c='email';
          esignatory3.code__c='email';
          esignatory4.code__c='email';
          esignatory1.EmailTxt__c='email1@test.com';
          esignatory2.EmailTxt__c='email2@test.com';
          esignatory3.EmailTxt__c='email3@test.com';
          esignatory4.EmailTxt__c='email4@test.com';
          
        
        
        
         // esignatory1.mobileTxt__c='54654654';
          //esignatory2.mobileTxt__c='546546544';
          //esignatory3.mobileTxt__c='54654754';
          //esignatory4.mobileTxt__c='54654854';
          
          esignatoryLst.add(esignatory1);
          esignatoryLst.add(esignatory2);
          esignatoryLst.add(esignatory3);
          esignatoryLst.add(esignatory4);
          insert esignatoryLst;
          

        }    
    }
    static testmethod void callAP22_Test(){
        test.startTest();
        Set<id> SetIdSignat=new set<id>();
        for(esignatory__c esignatory: esignatoryLst){
            SetIdSignat.add(esignatory.id);
        }
        AP22_CallUniversign.getSignatories(SetIdSignat);
        AP22_CallUniversign.dummy();
        test.stopTest();
    }
    static testmethod void getSignatoriesFnameLname_test(){
        system.runAs(testUser){
            esignatureLst[0].collecteDone__c=true;
            esignatureLst[0].ExternalId__c = 'cc9e3c80-c0ea-31e4-aa39-848a9596e374';
            esignatureLst[1].collecteDone__c=true;
            esignatureLst[1].ExternalId__c='cc9e3c80-c0ea-31e4-aa39-848a9596e375';

            test.startTest();
                update esignatureLst;
            test.stopTest();

            esignatureLst[0].collecteDone__c=false;
            esignatureLst[1].collecteDone__c=false;
            update esignatureLst;
           // contactLst[0].firstname=null;
           // update contactLst;

            esignatureLst[0].collecteDone__c=true;
            esignatureLst[1].collecteDone__c=true;
            update esignatureLst;
            
            //List<Esignatory__c> esignatories=[select signURL__c from esignatory__c where id IN:esignatoryLst];
            //system.assertNotEquals(null,esignatories[0].signURL__c);
        }
    }   
}