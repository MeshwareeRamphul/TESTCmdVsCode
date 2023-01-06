@isTest
private class VFC38_ReminderToAprovers_TEST{
/*
----------------------------------------------------------------------
-- - Name          : VFC38_ReminderToAprovers_TEST
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC38_ReminderToAprovers
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 13-AUG-2019  MRA    1.0      Intitial version 
----------------------------------------------------------------------
**********************************************************************
*/


     static Contract__c contract;
     static List<cTin_ContractForm__c> contractFormList;
     static User testUser;
     static Account supplier;
     static cTin_Entity__c entity;
     
     static{
        
        //creating user 
        testUser = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
        testUser.PAD_BypassValidationRules__c= true;
        testUser.PAD_BypassWorkflows__c = true;
        testUser.PAD_BypassTrigger__c = 'AP412;AP43;';
        testUser.cTin_LegalRepresentative__c = true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c=true;
        insert testUser;
        
        system.runAs(testUser){
          //creating account
          supplier = TestFactory.createSupplier('cTinTestSupplier' , 'tinTestaddr', 'France');
          insert supplier;
          
          //creating contract
          //contract = TestFactory.createcTinContracts ('Test Contract1',supplier.Id, Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId());
          contract = TestFactory.createContract(supplier.id, 'TestContractName','In approval');
          insert contract; 
    
         //creating contract form
          contractFormList = TestFactory.createContractForm(testUser.id, contract.Id);
          insert contractFormList;  
          
          //creating entity
          entity=new cTin_Entity__c (name='AXA', recordtypeId=Schema.SObjectType.cTin_Entity__c .getRecordTypeInfosByName().get('Legal Entity').getRecordTypeId());
          insert entity;
        }//end runAs
              
     }//end static
     
     /* method tests if approvers having pending approvals are notified by mail*/
     static testmethod void sendReminderTest(){
        system.debug('Starting method sendReminderTest');
        
        //update contract + contract form to match entry criteria of approval process
        contract.FinalDocumentURL__c='https://google.com';
        //contract.status__c='In approval';
        contract.cTin_ContractSegment__c ='test';
       contract.EndDate__c = system.today();
            contract.cTin_MainAPCL0__c = 'test';
            contract.cTin_OrganizationalScope__c = 'test';
            contract.cTin_ShortDescription__c = 'test';
            contract.StartDate__c = system.today();
            contract.cTin_SupplierAccount__c = supplier.id;
            contract.cTin_TypeOfDocument__c = 'test';
            contract.cTin_AXAMainLegalSignatoryEntity__c = entity.id;
            contract.FinalDocumentURL__c='https://www.google.com';
            contract.cTin_NumberSignablePDF__c =1;
           // contract.cTin_DataPrivacyClause__c='test';
        update contract;
        
        contractFormList[0].cTin_ApproverName1__c=testUser.id;
        contractFormList[0].cTin_EnableParallelApproval__c=false;
        update contractFormList;
        
        //submit contract form for approval
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(contractFormList[0].id);
        Approval.ProcessResult result = Approval.process(app);
    
        system.runAs(testUser){  
            PageReference pageRef = Page.VFP38_ReminderToAprovers;
            Test.setCurrentPage(pageRef);            
            ApexPages.standardController controller = new ApexPages.standardController(contractFormList[0]);         
            VFC38_ReminderToAprovers pg = new VFC38_ReminderToAprovers(controller); 
            //call sendreminder method
            test.startTest();      
                pg.sendReminder();
                system.assertEquals(pg.sendReminderSuccess,true);
            test.stopTest();
          }
          system.debug('Ending method sendReminderTest');
      }
  
}