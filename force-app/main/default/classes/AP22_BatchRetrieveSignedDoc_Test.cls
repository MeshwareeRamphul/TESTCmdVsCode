@isTest
private class AP22_BatchRetrieveSignedDoc_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_BatchRetrieveSignedDoc_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for batch AP22_BatchRetrieveSignedDoc
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 02-JUN-2017  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
  static list<Contentversion> contentVersionLst=new list<Contentversion>();
  static list<ContentDistribution> contentDistributionLst=new list<ContentDistribution>();
  static list<Esignature__c> esignatureLst=new list<Esignature__c>();
  static list<Contract__c> contractLst=new list<Contract__c>();
  static list<Account>supplierLst=new list<Account>();
  static id batchId;
  static User testUser;

  static{
     testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
     insert testUser;

     system.runAs(testUser){

      Account supplier1 = TestFactory.createSupplier('supplier 1','Paris','France');
      Account supplier2 = TestFactory.createSupplier('supplier 2','Paris','France');
      supplierLst.add(supplier1);
      supplierLst.add(supplier2);
      insert supplierLst;

      contract__c contract1 = TestFactory.createContract(supplier1.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
      contract__c contract2 = TestFactory.createContract(supplier2.Id,'Contract2',AP_Constant.contractCustValidationStatus);
      contract__c contract3 = TestFactory.createContract(supplier2.Id,'Contract3',AP_Constant.contractCustValidationStatus);

      contractLst.add(contract1);  
      contractLst.add(contract2);    
      contractLst.add(contract3);           
      insert contractLst;

      Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
      Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
      Esignature__c esignature3=TestFactory.createEsignature(contractLst[2],'esign3', AP_Constant.eSignatureCreatedStatus);
      esignatureLst.add(esignature1);
      esignatureLst.add(esignature2);
      esignatureLst.add(esignature3);
      insert esignatureLst;

      ContentVersion cv1=TestFactory.createContentVersion('contractXYZ_signed.pdf', 'contract_signed.pdf', 'Content',false);
      ContentVersion cv2=TestFactory.createContentVersion('contractABC', 'contract.pdf', 'Content',false);
      ContentVersion cv3=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
      ContentVersion cv4=TestFactory.createContentVersion('contractHIJ_signed.pdf', 'contract_signed.pdf', 'Content',false);
      ContentVersion cv5=TestFactory.createContentVersion('contractHIJ_signed.pdf', 'contract_signed.pdf', 'Content',false);
      contentVersionLst.add(cv1);
      contentVersionLst.add(cv2);
      contentVersionLst.add(cv3);
      contentVersionLst.add(cv4);
      contentVersionLst.add(cv5);
      insert contentVersionLst;

      ContentDistribution cd1=TestFactory.createContentDistribution(contentVersionLst[0].id, contentVersionLst[0].title, contractLst[0].Id);          
      ContentDistribution cd2=TestFactory.createContentDistribution(contentVersionLst[1].id, contentVersionLst[1].title, contractLst[0].Id);
      ContentDistribution cd3=TestFactory.createContentDistribution(contentVersionLst[2].id, contentVersionLst[2].title, contractLst[1].Id);          
      ContentDistribution cd4=TestFactory.createContentDistribution(contentVersionLst[3].id, contentVersionLst[3].title, contractLst[1].Id);
      ContentDistribution cd5=TestFactory.createContentDistribution(contentVersionLst[4].id, contentVersionLst[4].title, contractLst[2].Id);           
      contentDistributionLst.add(cd1);
      contentDistributionLst.add(cd2);
      contentDistributionLst.add(cd3);
      contentDistributionLst.add(cd4);
      insert contentDistributionLst;

      esignatureLst[0].status__c=AP_Constant.eSignatureCompletedStatus;
      esignatureLst[0].externalId__c='sdsadasd5454';
      esignatureLst[0].cTin_SignatureDate__c=system.today();
      esignatureLst[1].status__c=AP_Constant.eSignatureCompletedStatus;
      esignatureLst[1].externalId__c='sdsadasd54544';
      esignatureLst[1].cTin_SignatureDate__c=system.today();
      esignatureLst[2].status__c=AP_Constant.eSignatureCompletedStatus;
      esignatureLst[2].externalId__c='sd2sadasd54544';
      esignatureLst[2].cTin_SignatureDate__c=system.today();
      update esignatureLst;

    }
  }

  static testMethod void retrieveSignedContent_test(){
    system.runAs(testUser){
        AP22_BatchRetrieveSignedDoc batch = new AP22_BatchRetrieveSignedDoc();
        test.startTest();
          batchId=database.executeBatch(batch);      
        test.stopTest();
        //assert batch success
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email 
                              from AsyncApexJob 
                              where Id = :batchId];
       
        system.assertEquals('Completed',a.Status);
 
    }

  }
  
  //test for schedular
  static testMethod void schedulable_test(){
    system.runAs(testUser){
      String CRON_EXP = '0 0 23 * * ?';
      test.starttest();
        AP22_BatchRetrieveSignedDoc batch_schedular = new AP22_BatchRetrieveSignedDoc();
        string jobId=system.schedule('Schedular for batch', CRON_EXP, batch_schedular);
      test.stopTest();
      
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                                NextFireTime
                                FROM CronTrigger WHERE id = :jobId];
        
      // Verify the expressions are the same
      System.assertEquals(CRON_EXP,ct.CronExpression);
      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);
   }
  }


}