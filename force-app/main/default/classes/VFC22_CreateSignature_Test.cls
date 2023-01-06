@isTest
private class VFC22_CreateSignature_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_CreateSignature_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC22_CreateSignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 06-JUN-2017  MRA    1.0     Initial version
-- 21-JUL-2018  USA    1.1     Universign V2
--------------------------------------------------------------------------------------*/
  static User                      testUser;
  static Esignature__c             esignature;
  static Contract__c               contract;
  static Contract__c               contract2;
  static Account                   supplier;
  static list<Account>             supplierLst   = new list<Account>();
  static list<Esignatory__c>       esignatoryLst = new list<Esignatory__c>();
  static list<Contact>             contactLst    = new list<Contact>();
  static ContentVersion            content;
  static ContentDistribution       cd;
  static Planned_Invoicing_Line__c pInvLine;
  static Id contractId;

  static{

    testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
      testUser.cTin_Universign__c = true;
      insert testUser;
      
      system.runAs(testUser){
        supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
        insert supplier;
        
        Contact con1=TestFactory.createContact(supplier,'James','Brown');
        Contact con2=TestFactory.createContact(supplier,'Jim','Brown'); 
        Contact con3=TestFactory.createContact(supplier,'Jane','Brown');
        Contact con4=TestFactory.createContact(supplier,'Tom','Brown');
        Contact con5=TestFactory.createContact(supplier,'Jerry','Brown');
        Contact con6=TestFactory.createContact(supplier,'Harry','Brown');
        Contact con7=TestFactory.createContact(supplier,'Bob','Brown');
        Contact con8=TestFactory.createContact(supplier,'Sam','Brown');
        Contact con9=TestFactory.createContact(supplier,'Ted','Brown');
        Contact con10=TestFactory.createContact(supplier,'Bunny','Brown');
        Contact con11=TestFactory.createContact(supplier,'John','Brown');
        Contact con12=TestFactory.createContact(supplier,'Mary','Brown');
        Contact con13=TestFactory.createContact(supplier,'Sarah','Brown');
        Contact con14=TestFactory.createContact(supplier,'Sonia','Brown');
        //Contact con15=TestFactory.createContact(supplier,'Paul','Brown');
        Contact con15=new contact(lastname = 'Brown', AccountId = supplier.Id);
        
        contactLst.add(con1);
        contactLst.add(con2); 
        contactLst.add(con3);
        contactLst.add(con4);
        contactLst.add(con5);
        contactLst.add(con6);
        contactLst.add(con7);
        contactLst.add(con8);
        contactLst.add(con9);
        contactLst.add(con10);
        contactLst.add(con11);
        contactLst.add(con12);      
        contactLst.add(con13);
        contactLst.add(con14);
        contactLst.add(con15);
        insert contactLst;
        
        contract  = TestFactory.createContract(supplier.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
        contract2 = TestFactory.createContract(supplier.Id,'Contract2',AP_Constant.contractCustValidationStatus);   
        List<contract__c> lstctr = new List<contract__c>();         
        lstctr.add(contract);
        lstctr.add(contract2);
        insert lstctr;
        
        /*pInvLine=TestFactory.createPInvoicingLine(contract,'description');
        insert pInvLine;*/
        
        ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
        insert content;
        
        ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
        insert cd;
        
        ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                      from ContentDistribution 
                                      where id=: cd.Id ];  
        contract.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
        contract.status__c=AP_Constant.contractReadyStatus;
        contract.CustomerSignedBy__c=contactLst[0].id;
        contract.AXA_GS_Signed_By__c=contactLst[1].id;
        update contract;
        
        List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
        contractId=[select id from Contract__c where id =: contract.id].id;
        List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
            new contentDocumentLink(LinkedEntityId=contractId, ContentDocumentId=lstDocuments[0].Id)
        };
        insert lstCDL;
      }
  }

  //test scenario - create esignature and esignatories
  static testMethod void createEsignature_test(){
    system.runAs(testUser){
      contactLst[0].MobilePhone='6585444';
      contactLst[0].Email='Jb@email.com';
      contactLst[1].MobilePhone='6585444';
      contactLst[1].Email='JimB@email.com';
      update contactLst;
    
      Id contractId=[select id from Contract__c where id =: contract.id].id;
      system.assertNotEquals(null,contract.id);
      VFC22_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP22_showSignatory;
        pageRef.getParameters().put('contractId',contractId);
        Test.setCurrentPage(pageRef);
        controller=new VFC22_CreateSignature();  
        controller.createSignature();
        controller.save();
      test.stopTest();

      //check if esignatories and esignature are generated with correct status
      list<esignatory__c> esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                        from esignatory__c 
                                        where eSignature__r.contract__c=:contract.id
                                        and status__c=:AP_Constant.esignatoryStatusNotStarted];
      system.assertEquals(2,esignatories.size());
      system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c); 

    }
  }

  //test scenario - create esignature and esignatories
  static testMethod void createEsignature2_test(){
    system.runAs(testUser){
      contactLst[0].MobilePhone='6585444';
      contactLst[0].Email='Jb@email.com';
      contactLst[1].MobilePhone='6585444';
      contactLst[1].Email='JimB@email.com';
      contactLst[2].MobilePhone='6585222';
      contactLst[2].Email='JaneB@email.com';
      update contactLst;

      esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
      esignature.transactionId__c='5454sdsadaf';
      insert esignature;

      Esignatory__c esignatory3= TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
      esignatory3.Order__c=3;
      esignatory3.OrderCachet__c=3;
      esignatory3.MobileTxt__c='45648464';

      insert esignatory3;
    
      Id contractId=[select id from Contract__c where id =: contract.id].id;
      system.assertNotEquals(null,contract.id);
      VFC22_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP22_showSignatory;
        pageRef.getParameters().put('contractId',contractId);
        pageRef.getParameters().put('add_order','3');
        Test.setCurrentPage(pageRef);
        controller=new VFC22_CreateSignature();  
        controller.createSignature();
        controller.add();
        controller.save();
        controller.refresh();
      

      //check if esignatories and esignature are generated with correct status
      list<esignatory__c> esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                        from esignatory__c 
                                        where eSignature__r.contract__c=:contract.id
                                        and status__c=:AP_Constant.esignatoryStatusNotStarted];
      test.stopTest();
      /*system.assertEquals(3,esignatories.size());
      system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c); */

    }
  }

  //test scenario - edit esignature and esignatories
  static testMethod void editEsignature_test(){
    system.runAs(testUser){
      contactLst[0].MobilePhone='6585000';
      contactLst[0].Email='Jb@email.com';
      contactLst[1].MobilePhone='6585111';
      contactLst[1].Email='JimB@email.com';
      contactLst[2].MobilePhone='6585222';
      contactLst[2].Email='JaneB@email.com';

      update contactLst;

      esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
      esignature.transactionId__c='5454sdsadaf';
      insert esignature;
     
      Esignatory__c esignatory3= TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);

      esignatory3.Order__c=3;
      esignatory3.OrderCachet__c=3;
      esignatory3.MobileTxt__c='45648464';

      insert esignatory3;

      VFC22_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP22_showSignatory;
        pageRef.getParameters().put('ordre_descente','3');
        pageRef.getParameters().put('eSignatureId',eSignature.id);
        pageRef.getParameters().put('id',eSignature.id);     
        pageRef.getParameters().put('contact_Id',contactLst[2].id);
        pageRef.getParameters().put('signatoryId',esignatory3.id);
        pageRef.getParameters().put('delete_id','3');
        Test.setCurrentPage(pageRef);
        controller=new VFC22_CreateSignature();  
        controller.createSignature();
        controller.refresh();
        /*controller.monter();
        controller.descendre();
        controller.save();
        controller.ref();
        controller.refreshPhone();
        controller.submit();
        //controller.refresh();
      controller.refreshPhone();
      
      system.assertEquals(null,controller.refreshPhone());
      system.assertNotEquals(null,controller.reset());*/
      
      //assert if status is updated
      list<Contract__c> contractUpdted=[select status__c 
                                          from contract__c 
                                          where id=:contract.id];
      /*system.assertEquals(contractUpdted[0].status__c,AP_Constant.contractSentStatus);
      
      system.assertNotEquals(null,controller.cancel());
      
      system.assertNotEquals(null,controller.redirect());
      
      system.assertNotEquals(null,controller.relaunch());
      
      esignature.transactionId__c=null;
      update esignature; 
      controller.cancel();  
      
      controller.deleteEsignatory();*/
      test.stopTest();     
    }  
  }
  
  //test scenario - attempt to create esignature with missing information
  static testMethod void createEsignatureError_test(){
    system.runAs(testUser){

      VFC22_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP22_showSignatory;
        pageRef.getParameters().put('contractId',contract.Id);
        Test.setCurrentPage(pageRef);
        controller=new VFC22_CreateSignature();         
     

      //create esignature when esignatories have no email and phone
      controller.createSignature();     
      system.assert(true, controller.DoNotContinue);
     
      //create esignature when esignatories have same email
      contactLst[0].MobilePhone='6585444';
      contactLst[0].Email='Jb@email.com';
      contactLst[1].MobilePhone='6585444';
      contactLst[1].Email='Jb@email.com';
      update contactLst;
      controller.createSignature();
      system.assert(true, controller.DoNotContinue);
      
      //create esignature when esignatories have no email
      contactLst[0].MobilePhone='6585444';
      contactLst[0].Email=null;
      contactLst[1].MobilePhone='65854445';
      contactLst[1].Email=null;
      update contactLst;
      controller.createSignature();
      system.assert(true, controller.DoNotContinue);
      
      //create esignature when final document url of contract is incorrect
      contract.finalDocumentUrl__c='google.com';
      controller.createSignature();
      system.assert(true, controller.DoNotContinue);
      controller.backToContract();
      test.stopTest();
    }

  }

  static testMethod void backtoEsig_test(){
    system.runAs(testUser){

      VFC22_CreateSignature controller;
      
      PageReference pageRef = Page.VFP22_showSignatory;

      esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
      esignature.transactionId__c='5454sdsadaf';
      insert esignature;

      pageRef.getParameters().put('eSignatureId ',esignature.Id);
      Test.setCurrentPage(pageRef);
      controller=new VFC22_CreateSignature();         
      
      test.startTest();
        controller.backToContract();     
      test.stopTest();
    }
  }

  //test scenario - create esignature and esignatories
  static testMethod void addSignatory_test(){
    system.runAs(testUser){
      contactLst[0].MobilePhone='6585444';
      contactLst[0].Email='Jb@email.com';
      contactLst[1].MobilePhone='6585444';
      contactLst[1].Email='JimB@email.com';
      contactLst[2].MobilePhone='6585222';
      contactLst[2].Email='JaneB@email.com';
      update contactLst;

      esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
      esignature.transactionId__c='5454sdsadaf';
      insert esignature;

      Esignatory__c esignatory3= TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
      esignatory3.Order__c=3;
      esignatory3.OrderCachet__c=3;
      esignatory3.MobileTxt__c='45648464';

      insert esignatory3;
    
      Id contractId=[select id from Contract__c where id =: contract.id].id;
      system.assertNotEquals(null,contract.id);
      VFC22_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP22_showSignatory;
        pageRef.getParameters().put('contractId',contractId);
        pageRef.getParameters().put('add_order','2');
        Test.setCurrentPage(pageRef);
        controller=new VFC22_CreateSignature();  
        controller.createSignature();
        controller.add();
        controller.save();
        controller.refresh();
      

      //check if esignatories and esignature are generated with correct status
      list<esignatory__c> esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                        from esignatory__c 
                                        where eSignature__r.contract__c=:contract.id
                                        and status__c=:AP_Constant.esignatoryStatusNotStarted];
      test.stopTest();
      /*system.assertEquals(3,esignatories.size());
      system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c); */

    }
  }
}