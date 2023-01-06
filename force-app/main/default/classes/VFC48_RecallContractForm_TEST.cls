@isTest
private class VFC48_RecallContractForm_TEST{
/*
----------------------------------------------------------------------
-- - Name          : VFC48_RecallContractForm_TEST
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC48_RecallContractForm_
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 11-MAI-2020  MRA    1.0      Intitial version 
----------------------------------------------------------------------
**********************************************************************
*/


     static Contract__c contract;
     static List<cTin_ContractForm__c> contractFormList;
     static User testUser;
     static Account supplier;
     static cTin_Entity__c entity;
     static ContentVersion testCV = new ContentVersion();
     static ContentDistribution testCD = new ContentDistribution();
     static List<cTin_ContractTeam__c> lstContractTeam;
     static esignature__c esignature;
     static Contact con;
     static esignatory__c esignatory;
     
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
          contract = TestFactory.createContract(supplier.id, 'TestContractName','In Signature');
          insert contract; 
          
           lstContractTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = contract.Id, cTin_TeamMember__c = testUser.Id,cTin_ApprovalOrder__c = 'Not in Approval process', cTin_ContractAccessLevel__c = 'Read')
          };
           insert lstContractTeam;
    
         //creating contract form
          contractFormList = TestFactory.createContractForm(testUser.id, contract.Id);
          insert contractFormList;  
          
          //creating entity
          entity=new cTin_Entity__c (name='AXA', recordtypeId=Schema.SObjectType.cTin_Entity__c .getRecordTypeInfosByName().get('Legal Entity').getRecordTypeId());
          insert entity;
          
           testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            //testCV.sign_able__c = true;
            insert testCV;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, contract.Id);          
            insert testCD;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = contract.Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
            
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
     
     /* method tests if approvers having pending approvals are notified by mail*/
     static testmethod void recallApprovalTest(){
        system.debug('Starting method recallApprovalTest');

        //update contract + contract form to match entry criteria of approval process
        //contract.FinalDocumentURL__c='https://google.com';
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
            contract.cTin_DataPrivacyClause__c='test';
            update contract;
        
        //contractFormList[0].cTin_ApproverName1__c=testUser.id;
        //contractFormList[0].cTin_EnableParallelApproval__c=false;
//update contractFormList;
        
        /*submit contract form for approval
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(contractFormList[0].id);
        Approval.ProcessResult result = Approval.process(app);*/
    
        system.runAs(testUser){  
            PageReference pageRef = Page.VFP48_RecallContractForm;
            Test.setCurrentPage(pageRef);            
            ApexPages.standardController controller = new ApexPages.standardController(contract); 
            ApexPages.currentPage().getParameters().put('contractId',contract.Id);   
            VFC48_RecallContractForm pg = new VFC48_RecallContractForm (controller); 
            //call sendreminder method
            test.startTest();      
                pg.recallApproval();      
            test.stopTest();
          }
          system.debug('Ending method recallApprovalTest');
      }
  
}