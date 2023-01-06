@isTest
private class VFC37_CreateSignature_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC37_CreateSignature_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class for VFC37_CreateSignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 06-NOV-2017  HVA    1.0     Initial version
*************************************************************************************/

    static User testUser;   
    static Contract__c contract;
    static Account supplier;
    static list<Account>supplierLst=new list<Account>();
    static list<Esignatory__c> esignatoryLst=new list<Esignatory__c>();
    static list<Contact> lstContacts = new list<Contact>();
    static ContentVersion content;
    static ContentDistribution cd;
    static id rtConDraftId;

    static List<Account> lstSuppliers;
    
    static ContentVersion testContentInsert;
    static Map<string,Id> mapAcctRecordTypes;
    static Map<string,Id> mapContactRecordTypes;
    static Map<string,Id> mapEsignatoryRecordTypes;
    static ESignature__c eSignature;
    static List<eSignatory__c> lstEsignatories;
    static id localAdminProfileId;


    static{
        localAdminProfileId=[select id,name from profile where name =:'cTin - Local Admin'].id;

        testUser = TestFactory.createUser('UsrAdmin',localAdminProfileId,true);
        testUser.cTin_LegalRepresentative__c = true;
        testUser.PAD_BypassTrigger__c = 'AP412;AP43;';
        testuser.PAD_BypassValidationRules__c=true;
        testUser.PAD_BypassWorkflows__c  =true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c = true;
        testUser.Bypass_FieldFilter__c=true;
        insert testUser;

        system.runAs(testUser){

            rtConDraftId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId();
            
            //record types
            mapAcctRecordTypes = TestFactory.MapRecordType('Account');
            mapContactRecordTypes = TestFactory.MapRecordType('Contact');
            mapEsignatoryRecordTypes = TestFactory.MapRecordType('eSignatory__c');

            //creating accounts
            lstSuppliers = new List<Account>{TestFactory.createSupplier('Test Supplier1', 'Florange', 'France'),
                                             TestFactory.createSupplier('Test Supplier2', 'Florange', 'France'),
                                             TestFactory.createSupplier('Test Supplier3', 'Florange', 'France')};
            lstSuppliers[1].RecordTypeId = mapAcctRecordTypes.get('cTin_Supplier');
            lstSuppliers[2].RecordTypeId = mapAcctRecordTypes.get('cTin_AXA');
            insert lstSuppliers;

            //creating contacts
            lstContacts = new List<Contact>{TestFactory.createContact(lstSuppliers[1],'James','Brown1'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown2'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown3'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown4'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown5'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown6'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown7'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown8'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown9'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown10'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown11'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown12'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown13'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown14'),
                                            TestFactory.createContact(lstSuppliers[1],'Kim','Brown15')};
                                                                    


            lstContacts[0].RecordTypeId = mapContactRecordTypes.get('cTin_Supplier');
            lstContacts[0].cTin_RelatedUser__c = testUser.Id;
            lstContacts[0].cTin_LegalRepresentative__c = true;
            lstContacts[0].MobilePhone = '+2126655565645';
            lstContacts[0].cTin_Active__c = true;
            lstContacts[0].email ='james.brown@gmail.com'; 

            lstContacts[1].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[1].cTin_RelatedUser__c = testUser.Id;
            lstContacts[1].cTin_LegalRepresentative__c = true;
            lstContacts[1].MobilePhone = '+212667849903';
            lstContacts[1].email ='kim.brown23@gmail.com'; 
            lstContacts[1].cTin_Active__c = true;

            lstContacts[2].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[2].cTin_RelatedUser__c = testUser.Id;
            lstContacts[2].cTin_LegalRepresentative__c = true;
            lstContacts[2].MobilePhone = '+222667849903';
            lstContacts[2].email ='kim.brown22@gmail.com'; 
            lstContacts[2].cTin_Active__c = true;

            lstContacts[3].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[3].cTin_RelatedUser__c = testUser.Id;
            lstContacts[3].cTin_LegalRepresentative__c = true;
            lstContacts[3].MobilePhone = '+212667849903';
            lstContacts[3].email ='kim.brown1@gmail.com'; 
            lstContacts[3].cTin_Active__c = true;

            lstContacts[4].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[4].cTin_RelatedUser__c = testUser.Id;
            lstContacts[4].cTin_LegalRepresentative__c = true;
            lstContacts[4].MobilePhone = '+242667849903';
            lstContacts[4].email ='kim.brown2@gmail.com'; 
            lstContacts[4].cTin_Active__c = true;

            lstContacts[3].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[3].cTin_RelatedUser__c = testUser.Id;
            lstContacts[3].cTin_LegalRepresentative__c = true;
            lstContacts[3].MobilePhone = '+232667849903';
            lstContacts[3].email ='kim.brown3@gmail.com'; 
            lstContacts[3].cTin_Active__c = true;

            lstContacts[4].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[4].cTin_RelatedUser__c = testUser.Id;
            lstContacts[4].cTin_LegalRepresentative__c = true;
            lstContacts[4].MobilePhone = '+242667849903';
            lstContacts[4].email ='kim.brown4@gmail.com'; 
            lstContacts[4].cTin_Active__c = true;

            lstContacts[5].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[5].cTin_RelatedUser__c = testUser.Id;
            lstContacts[5].cTin_LegalRepresentative__c = true;
            lstContacts[5].MobilePhone = '+252667849903';
            lstContacts[5].email ='kim.brown5@gmail.com'; 
            lstContacts[5].cTin_Active__c = true;

            lstContacts[6].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[6].cTin_RelatedUser__c = testUser.Id;
            lstContacts[6].cTin_LegalRepresentative__c = true;
            lstContacts[6].MobilePhone = '+262667849903';
            lstContacts[6].email ='kim.brown6@gmail.com'; 
            lstContacts[6].cTin_Active__c = true;

            lstContacts[7].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[7].cTin_RelatedUser__c = testUser.Id;
            lstContacts[7].cTin_LegalRepresentative__c = true;
            lstContacts[7].MobilePhone = '+272667849903';
            lstContacts[7].email ='kim.brown7@gmail.com'; 
            lstContacts[7].cTin_Active__c = true;

            lstContacts[8].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[8].cTin_RelatedUser__c = testUser.Id;
            lstContacts[8].cTin_LegalRepresentative__c = true;
            lstContacts[8].MobilePhone = '+282667849903';
            lstContacts[8].email ='kim.brown8@gmail.com'; 
            lstContacts[8].cTin_Active__c = true;

            lstContacts[9].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[9].cTin_RelatedUser__c = testUser.Id;
            lstContacts[9].cTin_LegalRepresentative__c = true;
            lstContacts[9].MobilePhone = '+292667849903';
            lstContacts[9].email ='kim.brown9@gmail.com'; 
            lstContacts[9].cTin_Active__c = true;

            lstContacts[10].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[10].cTin_RelatedUser__c = testUser.Id;
            lstContacts[10].cTin_LegalRepresentative__c = true;
            lstContacts[10].MobilePhone = '+2102667849903';
            lstContacts[10].email ='kim.brown10@gmail.com'; 
            lstContacts[10].cTin_Active__c = true;

            lstContacts[11].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[11].cTin_RelatedUser__c = testUser.Id;
            lstContacts[11].cTin_LegalRepresentative__c = true;
            lstContacts[11].MobilePhone = '+2112667849903';
            lstContacts[11].email ='kim.brown11@gmail.com'; 
            lstContacts[11].cTin_Active__c = true;

            lstContacts[12].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[12].cTin_RelatedUser__c = testUser.Id;
            lstContacts[12].cTin_LegalRepresentative__c = true;
            lstContacts[12].MobilePhone = '+2122667849903';
            lstContacts[12].email ='kim.brown12@gmail.com'; 
            lstContacts[12].cTin_Active__c = true;


            lstContacts[13].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[13].cTin_RelatedUser__c = testUser.Id;
            lstContacts[13].cTin_LegalRepresentative__c = true;
            lstContacts[13].MobilePhone = '+2132667849903';
            lstContacts[13].email ='kim.brown13@gmail.com'; 
            lstContacts[13].cTin_Active__c = true;

            lstContacts[14].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[14].cTin_RelatedUser__c = testUser.Id;
            lstContacts[14].cTin_LegalRepresentative__c = true;
            lstContacts[14].MobilePhone = '+2142667849903';
            lstContacts[14].email ='kim.brown14@gmail.com'; 
            lstContacts[14].cTin_Active__c = true;



            insert lstContacts;
          
            //creating contract
            contract = TestFactory.createcTinContracts('Test Contract1', lstSuppliers[0].Id, rtConDraftId);
            insert contract;            
            //contract.FinalDocumentUrl__c='https://wwww.google.com';
            //update contract;

            //create content version
            testContentInsert = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            insert testContentInsert;

            //create esignature
           // eSignature = TestFactory.createEsignature(contract, 'Test Esignature', AP_Constant.eSignatureCreatedStatus);
           // insert eSignature;

           /* //creating esignatory  
            lstEsignatories = new List<eSignatory__c>{TestFactory.createEsignatory(contract, eSignature, 'James', lstContacts[1].id, AP_Constant.esignatoryStatusNotStarted),
                                                      TestFactory.createEsignatory(contract, eSignature, 'James', lstContacts[0].id, AP_Constant.esignatoryStatusNotStarted)};

            lstEsignatories[0].RecordTypeId = mapEsignatoryRecordTypes.get('cTin_AXA_Representative');
            lstEsignatories[0].EmailTxt__c = lstContacts[1].Email;
            lstEsignatories[0].Status__c = 'Ready';
            lstEsignatories[0].Contact__c = lstContacts[1].Id;
            lstEsignatories[0].cTin_Role__c = 'AXA Representative';
            lstEsignatories[0].MobileTxt__c = lstContacts[1].Phone;
            lstEsignatories[0].Order__c = 2;
            lstEsignatories[0].cTin_SupplierAccount__c = lstSuppliers[2].Id; 
            lstEsignatories[0].signURL__c = 'https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';

            lstEsignatories[1].RecordTypeId = mapEsignatoryRecordTypes.get('cTin_Supplier_Representative');
            lstEsignatories[1].EmailTxt__c = lstContacts[0].Email;
            lstEsignatories[1].MobileTxt__c = lstContacts[0].Phone;
            lstEsignatories[1].Status__c = 'Ready';
            lstEsignatories[1].cTin_Role__c = 'Supplier Representative';
            lstEsignatories[1].Order__c = 1;
            lstEsignatories[1].signURL__c = 'https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';
            lstEsignatories[1].Contact__c = lstContacts[0].Id;
            lstEsignatories[1].cTin_SupplierAccount__c = lstSuppliers[1].Id;

            insert lstEsignatories;*/
            

            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;

            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
            insert cd;

            ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, 
                                         ContentVersionId 
                                         from ContentDistribution 
                                         where id=: cd.Id ];  

            contract.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            contract.status__c='In Signature';
            contract.cTin_AXASignatoryRepresentative__c = lstContacts[1].Id;
            contract.cTin_SupplierSignatoryRepresentative__c=lstContacts[0].id;
            update contract;  


        }
    }

    //test scenario - create esignature 
    static testMethod void createEsignature_test(){
        system.runAs(testUser){
          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;
        
          string errorMsg;

          Id contractId=[select id from Contract__c where id =: contract.id].id;
          system.assertNotEquals(null,contract.id);
          VFC37_CreateSignature controller;

          test.startTest();
            PageReference pageRef = Page.VFP37_showSignatory;
            pageRef.getParameters().put('contractId',contractId);
            Test.setCurrentPage(pageRef);
            controller=new VFC37_CreateSignature();  
            try{
            controller.createSignature();
            //controller.save();
            }
            catch(Exception e){
                errorMsg=e.getMessage();
            }
          test.stopTest();

          list<esignature__c> esignature=[select contract__c, id 
                                         from esignature__c 
                                         where contract__c=:contract.id];

          system.assertEquals(1,esignature.size());  
          system.assertEquals(null,errorMsg);                           
        }

    }

    
    static testMethod void createEsignatureError_test(){
        system.runAs(testUser){
          contract.status__c='Draft';
          contract.FinalDocumentURL__c='';        
          update contract;

          lstContacts[0].MobilePhone='';
          lstContacts[0].Email='JimB@email.com';

          lstContacts[1].MobilePhone='';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;
        
          string errorMsg;

          Id contractId=[select id from Contract__c where id =: contract.id].id;
          system.assertNotEquals(null,contract.id);
          VFC37_CreateSignature controller;

          test.startTest();
            PageReference pageRef = Page.VFP37_showSignatory;
            pageRef.getParameters().put('contractId',contractId);
            pageRef.getParameters().put('contact_Id',lstContacts[0].name);
            Test.setCurrentPage(pageRef);
            controller=new VFC37_CreateSignature();  
            try{
            controller.createSignature();
            controller.refresh();
            //controller.save();
            }
            catch(Exception e){
                errorMsg=e.getMessage();
            }
          test.stopTest();

          list<esignature__c> esignature=[select contract__c, id 
                                         from esignature__c 
                                         where contract__c=:contract.id];

          //system.assertEquals(0,esignature.size());  
          //system.assertNotEquals(null,errorMsg);                           
        }
    }


    //create 
     //test scenario - edit esignature and esignatories
  static testMethod void editEsignature_test(){
    system.runAs(testUser){
      lstContacts[0].MobilePhone='6585444';
      lstContacts[0].Email='Jb@email.com';
      lstContacts[1].MobilePhone='6585444';
      lstContacts[1].Email='JimB@email.com';

      lstContacts[2].MobilePhone='6585444';
      lstContacts[3].Email='JimB@email.com';
      update lstContacts;

      esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
      esignature.transactionId__c='5454sdsadaf';
      insert esignature;
     
      Esignatory__c esignatory1= TestFactory.createEsignatory(contract, esignature,'James',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
      Esignatory__c esignatory2= TestFactory.createEsignatory(contract, esignature,'Jim',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted);
      Esignatory__c esignatory3= TestFactory.createEsignatory(contract, esignature,'Jim3',lstContacts[2].id,AP_Constant.esignatoryStatusNotStarted);
      
      esignatory1.Order__c=1;
      esignatory1.OrderCachet__c=1;
      esignatory1.MobileTxt__c='45646464';
      esignatory1.cTin_Role__c = system.label.cTin_RoleNegotiator;
      esignatory1.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();

      esignatory2.Order__c=2;
      esignatory2.OrderCachet__c=2;
      esignatory2.MobileTxt__c='45647464';
      esignatory2.cTin_Role__c = system.label.cTin_RoleNegotiator;
      esignatory2.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();

      esignatory3.Order__c=3;
      esignatory3.OrderCachet__c=3;
      esignatory3.MobileTxt__c='45647364';
      esignatory3.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();

      esignatoryLst.add(esignatory1);
      esignatoryLst.add(esignatory2);
      esignatoryLst.add(esignatory3);

      insert esignatoryLst;

      VFC37_CreateSignature controller;
      test.startTest();
        PageReference pageRef = Page.VFP37_showSignatory;
        pageRef.getParameters().put('ordre_descente','1');
        pageRef.getParameters().put('eSignatureId',eSignature.id);
        pageRef.getParameters().put('id',eSignature.id);     
        pageRef.getParameters().put('contact_Id',lstContacts[0].id);
        //pageRef.getParameters().put('contractId',contract.id);
        pageRef.getParameters().put('signatoryId',esignatoryLst[0].id);
        pageRef.getParameters().put('add_order','3');
        pageRef.getParameters().put('delete_id','3');
        Test.setCurrentPage(pageRef);
        controller=new VFC37_CreateSignature();  
        controller.createSignature();
        controller.eSignatoryList.addAll(esignatoryLst);
        
        try{controller.monter();} catch(Exception e){}
        try{controller.descendre();}catch(Exception e){}
        controller.add();   
        controller.save();
        try{controller.deleteEsignatory();} catch(Exception e){}
        controller.ref();
        controller.refreshPhone();
        controller.submit();
        controller.relaunch();
        controller.cancel();
        controller.redirect();
        controller.back();
        controller.refresh();
        // system.assertEquals(null,controller.refreshPhone());
        system.assertNotEquals(null,controller.reset());
      
        //assert if status is updated
        list<Contract__c> contractUpdted=[select status__c from contract__c where id=:contract.id];

        system.assertEquals(AP_Constant.CONTRACT_STATUS_INSIGNATURE,contractUpdted[0].status__c);
          
        system.assertNotEquals(null,controller.cancel());
          
        system.assertNotEquals(null,controller.redirect());
          
        system.assertNotEquals(null,controller.relaunch());
          
        esignature.transactionId__c=null;
        update esignature; 
        controller.cancel();  
        test.stopTest();     
    }  
  }

  //test scenario : add Axa signatory, add supplier signatory
  static testMethod void addSignatory_test(){ 
     system.runAs(testUser){
          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;

          esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
          esignature.transactionId__c='5454sdsadaf';
          insert esignature;
     
          Esignatory__c esignatory1= TestFactory.createEsignatory(contract, esignature,'James',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
          Esignatory__c esignatory2= TestFactory.createEsignatory(contract, esignature,'Jim',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted);
          esignatory1.Order__c=1;
          esignatory1.OrderCachet__c=1;
          esignatory1.MobileTxt__c='45646464';
          esignatory1.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();

          esignatory2.Order__c=2;
          esignatory2.OrderCachet__c=2;
          esignatory2.MobileTxt__c='45647464';
          esignatory2.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();

          esignatoryLst.add(esignatory1);
          esignatoryLst.add(esignatory2);   
          insert esignatoryLst;

          VFC37_CreateSignature controller;

          test.startTest();
           PageReference pageRef = Page.VFP37_showSignatory;
           pageRef.getParameters().put('eSignatureId',eSignature.id);
           Test.setCurrentPage(pageRef);
           controller=new VFC37_CreateSignature();  
           controller.createSignature();
           controller.eSignatoryList.addAll(esignatoryLst);
           controller.addSignatory();
           controller.addAxaSignatory();
          test.stopTest();
    }
  }

  //test scenario : Unilateral supplier
  static testMethod void unilateralSupplier_test(){ 
    system.runAs(testUser){
          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;

          esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
          esignature.transactionId__c='5454sdsadaf';
          insert esignature;

          contract.cTin_UnilateralSupplier__c=true;
          update contract;
     
          Esignatory__c esignatory1= TestFactory.createEsignatory(contract, esignature,'James',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
          Esignatory__c esignatory2= TestFactory.createEsignatory(contract, esignature,'Jim',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted);
          esignatory1.Order__c=1;
          esignatory1.OrderCachet__c=1;
          esignatory1.MobileTxt__c='45646464';
          esignatory1.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();

          esignatory2.Order__c=2;
          esignatory2.OrderCachet__c=2;
          esignatory2.MobileTxt__c='45647464';
          esignatory2.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();

          esignatoryLst.add(esignatory1);
          esignatoryLst.add(esignatory2);   
          insert esignatoryLst;

          VFC37_CreateSignature controller;

          test.startTest();
           PageReference pageRef = Page.VFP37_showSignatory;
           pageRef.getParameters().put('eSignatureId',eSignature.id);
           Test.setCurrentPage(pageRef);
           controller=new VFC37_CreateSignature();  
           controller.createSignature();
           controller.eSignatoryList.addAll(esignatoryLst);
           //controller.addSignatory();
           //controller.addAxaSignatory();
          test.stopTest();
    }
  }

  //test scenario: unilateral AXA Rep
  static testMethod void unilateralAXA_test(){ 
    system.runAs(testUser){
          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;

          esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
          esignature.transactionId__c='5454sdsadaf';
          insert esignature;

          contract.cTin_UnilateralAXARepresentative__c=true;
          update contract;
     
          Esignatory__c esignatory1= TestFactory.createEsignatory(contract, esignature,'James',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted);
          Esignatory__c esignatory2= TestFactory.createEsignatory(contract, esignature,'Jim',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted);
          esignatory1.Order__c=1;
          esignatory1.OrderCachet__c=1;
          esignatory1.MobileTxt__c='';
          esignatory1.Code__c='sms';
          esignatory1.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();

          esignatory2.Order__c=2;
          esignatory2.OrderCachet__c=2;
          esignatory2.MobileTxt__c='45647464';
          esignatory2.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();

          esignatoryLst.add(esignatory1);
          esignatoryLst.add(esignatory2);   
          insert esignatoryLst;

          VFC37_CreateSignature controller;

          test.startTest();
           PageReference pageRef = Page.VFP37_showSignatory;
           pageRef.getParameters().put('eSignatureId',eSignature.id);
           Test.setCurrentPage(pageRef);
           controller=new VFC37_CreateSignature();  
           controller.createSignature();
           controller.eSignatoryList.addAll(esignatoryLst);
           //controller.addSignatory();
           //controller.addAxaSignatory();
          test.stopTest();
    }
  }

  //test scenario: having upto 15 signatories
  static testMethod void multipleSignatories_test(){ 
    System.debug('## START multipleSignatories_test');
    system.runAs(testUser){
          //testUser.cTin_EntityLocalCode__c='ACH';
          //update testuser;

          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          lstContacts[2].MobilePhone='7585444';
          lstContacts[2].Email='Jimc@email.com';
          lstContacts[3].MobilePhone='7582444';
          lstContacts[3].Email='Jimd@email.com';
          update lstContacts;

          esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
          esignature.transactionId__c='5454sdsadaf';
          insert esignature;

          contract.cTin_UnilateralAXARepresentative__c=true;
          contract.cTin_OwnerEntityLocalCode__c='ACH';

          update contract;
          
         
          esignatoryLst=new list<eSignatory__c>{
                        TestFactory.createEsignatory(contract, esignature,'James',lstContacts[0].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim',lstContacts[1].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James2',lstContacts[2].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim2',lstContacts[3].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James3',lstContacts[4].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim3',lstContacts[5].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James3',lstContacts[6].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim3',lstContacts[7].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James4',lstContacts[8].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim4',lstContacts[9].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James5',lstContacts[10].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim5',lstContacts[11].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James6',lstContacts[12].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim6',lstContacts[13].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James7',lstContacts[2].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim7',lstContacts[3].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James8',lstContacts[2].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim8',lstContacts[3].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'James9',lstContacts[2].id,AP_Constant.esignatoryStatusNotStarted),
                        TestFactory.createEsignatory(contract, esignature,'Jim9',lstContacts[3].id,AP_Constant.esignatoryStatusNotStarted)
                        };

            esignatoryLst[0].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[1].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 
            esignatoryLst[2].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[3].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 

            esignatoryLst[4].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[5].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 
            esignatoryLst[6].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[7].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 
            esignatoryLst[8].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[9].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 
            esignatoryLst[10].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[11].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();    
            esignatoryLst[12].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[13].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
            esignatoryLst[14].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[15].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
            esignatoryLst[14].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[16].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(); 
            esignatoryLst[17].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            esignatoryLst[18].recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();     
           
            
            insert esignatoryLst;

            
            for(integer i=0;i<esignatoryLst.size();i++){
                esignatoryLst[i].Order__c=i+1;
                esignatoryLst[i].OrderCachet__c=i+1;
                esignatoryLst[i].MobileTxt__c='435436546'+string.valueOf(i);
                System.debug('##OrderCachet__c : ' + esignatoryLst[i].OrderCachet__c);
            }
            eSignatoryLst[0].cTin_ParenteSignatory__c=eSignatoryLst[1].id;

            update esignatoryLst;

            VFC37_CreateSignature controller;

            test.startTest();
               PageReference pageRef = Page.VFP37_showSignatory;
               pageRef.getParameters().put('eSignatureId',eSignature.id);
               pageRef.getParameters().put('esignatoryBis_Id',eSignatoryLst[0].id);
               pageRef.getParameters().put('contact_Id',lstContacts[0].name);          
               pageRef.getParameters().put('add_order','15');               
               Test.setCurrentPage(pageRef);
               controller=new VFC37_CreateSignature();  
               controller.createSignature();
               controller.eSignatoryList.addAll(esignatoryLst);
               controller.add();
               controller.save();
               controller.refresh();
               pageRef.getParameters().put('eSignatureId',eSignature.id);
               pageRef.getParameters().put('esignatoryBis_Id',eSignatoryLst[1].id);
               pageRef.getParameters().put('contact_Id',lstContacts[0].name);              
               Test.setCurrentPage(pageRef);
               controller=new VFC37_CreateSignature();  
               controller.createSignature();
               controller.refresh();
            test.stopTest();

            System.debug('## END multipleSignatories_test');


    }
  }

   //test scenario - create esignature 
    static testMethod void createEsignatureDiffUrl_test(){
        system.runAs(testUser){
          lstContacts[0].MobilePhone='6585444';
          lstContacts[0].Email='Jb@email.com';
          lstContacts[1].MobilePhone='6585444';
          lstContacts[1].Email='JimB@email.com';
          update lstContacts;
        
          string errorMsg;
          contract.FinalDocumentURL__c ='http://google.com';
          contract.cTin_UnilateralAXARepresentative__c=true;
          contract.cTin_OwnerEntityLocalCode__c='ACH';
          update contract;

          Id contractId=[select id from Contract__c where id =: contract.id].id;

          system.assertNotEquals(null,contract.id);
          VFC37_CreateSignature controller;

          test.startTest();
            PageReference pageRef = Page.VFP37_showSignatory;
            pageRef.getParameters().put('contractId',contractId);
            Test.setCurrentPage(pageRef);
            controller=new VFC37_CreateSignature();  
            try{
            controller.createSignature();
            //controller.save();
            }
            catch(Exception e){
                errorMsg=e.getMessage();
            }
          test.stopTest();

          /*list<esignature__c> esignature=[select contract__c, id 
                                         from esignature__c 
                                         where contract__c=:contract.id];8/

          //system.assertEquals(1,esignature.size());  
          //system.assertEquals(null,errorMsg); */                          
        }

    }



}