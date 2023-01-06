@isTest
private class AP22_BatchDeleteOldContents_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_BatchDeleteOldContents_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for batch AP22_BatchDeleteOldContents
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
  static list<Attachment>attachmentLst=new list<Attachment>();
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
      contractLst.add(contract1);  
      contractLst.add(contract2);               
      insert contractLst;

      Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
      Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
      esignatureLst.add(esignature1);
      esignatureLst.add(esignature2);
      insert esignatureLst;

      ContentVersion cv1=TestFactory.createContentVersion('contractXYZ_signed.pdf', 'contract_signed.pdf', 'Content',false);
      ContentVersion cv2=TestFactory.createContentVersion('contractABC', 'contract.pdf', 'Content',false);
      ContentVersion cv3=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
      ContentVersion cv4=TestFactory.createContentVersion('contractHIJ_signed.pdf', 'contract_signed.pdf', 'Content',false);
      contentVersionLst.add(cv1);
      contentVersionLst.add(cv2);
      contentVersionLst.add(cv3);
      contentVersionLst.add(cv4);
      insert contentVersionLst;

      ContentDistribution cd1=TestFactory.createContentDistribution(contentVersionLst[0].id, contentVersionLst[0].title, contractLst[0].Id);          
      ContentDistribution cd2=TestFactory.createContentDistribution(contentVersionLst[1].id, contentVersionLst[1].title, contractLst[0].Id);
      ContentDistribution cd3=TestFactory.createContentDistribution(contentVersionLst[2].id, contentVersionLst[2].title, contractLst[1].Id);          
      ContentDistribution cd4=TestFactory.createContentDistribution(contentVersionLst[3].id, contentVersionLst[3].title, contractLst[1].Id);          
      contentDistributionLst.add(cd1);
      contentDistributionLst.add(cd2);
      contentDistributionLst.add(cd3);
      contentDistributionLst.add(cd4);
      insert contentDistributionLst;

      Attachment att1=TestFactory.createAttachment('body of attachment1', contentDistributionLst[0].name, contractLst[0].Id);
      Attachment att2=TestFactory.createAttachment('body of attachment2', contentDistributionLst[1].name, contractLst[0].Id);
      Attachment att3=TestFactory.createAttachment('body of attachment3', contentDistributionLst[2].name, contractLst[1].Id);
      Attachment att4=TestFactory.createAttachment('body of attachment4', contentDistributionLst[3].name, contractLst[1].Id);
      attachmentLst.add(att1);
      attachmentLst.add(att2);
      attachmentLst.add(att3);
      attachmentLst.add(att4);
      insert attachmentLst;

    }//end runAs
  }

  //test scenario : check if batch deletes old contents / attachments
  static testMethod void deleteContent_test(){
    system.runAs(testUser){
        AP22_BatchDeleteOldContents batch = new AP22_BatchDeleteOldContents(false);
        test.startTest();
          batchId=database.executeBatch(batch);      
        test.stopTest();
        //assert batch success
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email 
                              from AsyncApexJob 
                              where Id = :batchId];
       
        system.assertEquals('Completed',a.Status);

        list<Attachment> attList=[select id,parentId,name
                                 from Attachment 
                                 where parentId IN:contractLst];
        system.assertEquals(2,attList.size());
        //assert to check if signed docs are retained
        system.assert(attList[0].Name.contains('_signed.pdf'));
        system.assert(attList[1].Name.contains('_signed.pdf'));

        list<ContentDistribution> cDistLst=[select relatedRecordId,name 
                                            from ContentDistribution 
                                            where relatedRecordId IN:contractLst];
        system.assertEquals(2,cDistLst.size());        
        //assert to check if signed docs are retained
        system.assert(cDistLst[0].Name.contains('_signed.pdf'));
        system.assert(cDistLst[1].Name.contains('_signed.pdf'));
    }

  }

  //test scenario: test error when deleting attachments and contents
  static testMethod void deleteDummy_test(){
        AP22_BatchDeleteOldContents batch = new AP22_BatchDeleteOldContents(true);
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

  
  //test for schedular
  static testMethod void schedulable_test(){
    system.runAs(testUser){
      String CRON_EXP = '0 0 23 * * ?';
      test.starttest();
        AP22_BatchDeleteOldContents batch_schedular = new AP22_BatchDeleteOldContents(false);
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