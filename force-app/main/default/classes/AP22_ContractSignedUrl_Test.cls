@isTest
private class AP22_ContractSignedUrl_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_ContractSignedUrl_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP22_ContractSignedUrl
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 01-JUN-2017  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
  
  static User testUser;
  static list<ContentVersion> contentVersionLst=new list<ContentVersion>();
  static list<ContentVersion> cvLst=new list<ContentVersion>();
  static Account vAccount;
  static Account vEAccount;
  static Contact vEntityContact;
  static Product__c vProduct;
  
  static{ 
   AP45_ManageGroupMembers.bypassSpecial=true;
    //creating user 
    testUser = TestFactory.createUser('UsrUniversign',TestFactory.getProfileUniversignId(),true);
    insert testUser;
    
    system.runAs(testUser){
      
          // Create the legal entity (aka billing entity) account
          vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

          // Create the entity account
          vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

          // Create the couple Entity - Billing Entity on Parent Entity
          vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

          // Create the entity contact related to the account
          vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
          
          vProduct = AP05_TestDataFactory.createProduct(testUser);
    //  ContentVersion cv1=TestFactory.createContentVersion('contractXYZ_signed', 'contractXYZ_signed.pdf', 'Content',true);
    //  ContentVersion cv2=TestFactory.createContentVersion('contractABC_signed', 'contractABC_signed.pdf', 'Content',true);
    //  ContentVersion cv3=TestFactory.createContentVersion('contractEFG_signed', 'contractEFG_signed.pdf', 'Content',true);
    //  contentVersionLst.add(cv1);
    //  contentVersionLst.add(cv2);
    //  contentVersionLst.add(cv3);
    }//end runAs

   
  }//end static

  //test scenario - insert signed content document
  //static testmethod void updateFinalUrl_Test(){
  //  set<id>contentDocumentIdSet=new set<id>();

  //  system.runAs(testUser){   
  //    test.startTest();
  //      insert contentVersionLst;
  //    test.stopTest();

  //    for(ContentVersion cv: [select id, contentdocumentId from ContentVersion where id IN: contentVersionLst]){
  //      contentDocumentIdSet.add(cv.contentdocumentId);
  //    }
  //    system.assertEquals(3,contentDocumentIdSet.size());
  //  } 
  //}  
  static testmethod void updateFinalUrl_Test(){
    User use = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
    use.PAD_BypassValidationRules__c = true;
    insert use;           

    system.runAs(use){ 
          //lstContract.add(AP05_TestDataFactory.createContractAdmin('Test 356 v21', vProduct, vAccount, user00, vEntityContact));
        Contract__c contract = AP05_TestDataFactory.createContract(vProduct, vAccount, use, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false); 
  
        contract.cTin_AutoPopulateFinalDocumentURL__c=true;
        insert contract;      
                      
        eSignature__c esign = TestFactory.createEsignature(contract,contract.name,'Signed');
        insert esign;
      
        //ContentVersion cv1=TestFactory.createContentVersion('contractXYZ_signed', 'contractXYZ_signed.pdf', 'Content',true);
        //  ContentVersion cv2=TestFactory.createContentVersion('contractABC_signed', 'contractABC_signed.pdf', 'Content',true);
        //  ContentVersion cv3=TestFactory.createContentVersion('contractEFG_signed', 'contractEFG_signed.pdf', 'Content',true);
        //  contentVersionLst.add(cv1);
        //  contentVersionLst.add(cv2);
        //  contentVersionLst.add(cv3);
          
        ContentVersion cv1 =new ContentVersion();
        cv1.Title ='testjhgdjhghref_signed';  
        cv1.versiondata=blob.valueOf('test_signed.pdf');
        cv1.PathOnClient='test_signed.pdf';
        contentVersionLst.add(cv1);

        test.startTest();
          insert contentVersionLst;
          ContentDistribution cd = new ContentDistribution();
          cd.name = 'TstContentDistribution';       
          cd.ContentVersionId = cv1.Id;               
          cd.PreferencesAllowOriginalDownload = true;
          cd.PreferencesAllowPDFDownload = true;
          cd.PreferencesAllowViewInBrowser = true;             
          cd.RelatedRecordId = esign.Id;                
          insert cd;

          List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
          List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
              new contentDocumentLink(LinkedEntityId = esign.Id, ContentDocumentId = lstDocuments[0].Id)
          };
          insert lstCDL;
          AP22_ContractSignedUrl.updateFinalUrl(new set<id>{cv1.id});
        test.stopTest();
    }
  }  

  static testMethod void test_update_content(){
    AP45_ManageGroupMembers.bypassSpecial=true;
    User use = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
    use.PAD_BypassValidationRules__c = true;
    insert use;           

    system.runAs(use){ 
        Contract__c contract = AP05_TestDataFactory.createContract(vProduct, vAccount, use, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false); 
    
        contract.cTin_AutoPopulateFinalDocumentURL__c=true;
        contract.cTin_DataPrivacyClause__c='Standard';
        contract.cTin_DataPrivacyRisk__c='Low Risk';
        insert contract;      
                        
        eSignature__c esign = TestFactory.createEsignature(contract,contract.name,'Signed');
        insert esign;
        
        ContentVersion testContentInsert =new ContentVersion();
        testContentInsert.Title ='testjhgdjhghref_signed';  
        testContentInsert.versiondata=blob.valueOf('test_signed.pdf');
        testContentInsert.PathOnClient='test_signed.pdf';
        cvLst.add(testContentInsert);

        ContentVersion unsignedContent =new ContentVersion();
        unsignedContent.Title ='testabdhshdgshdg';
        unsignedContent.versiondata=blob.valueOf('test.pdf');
        unsignedContent.PathOnClient='test.pdf';
        cvLst.add(unsignedContent);

        test.startTest();
          insert cvLst;
    
          ContentDistribution cd = new ContentDistribution();
          cd.name = 'TstContentDistribution';       
          cd.ContentVersionId = testContentInsert.Id;               
          cd.PreferencesAllowOriginalDownload = true;
          cd.PreferencesAllowPDFDownload = true;
          cd.PreferencesAllowViewInBrowser = true;             
          cd.RelatedRecordId = esign.Id;                
          insert cd;

          set<id> contentDocumentIdSet=new set<id>();
          set<id> contentDistIdSet=new set<id>();
          contentDocumentIdSet.add(testContentInsert.id);
        
          AP22_ContractSignedUrl.cTin_updateFinalUrl(contentDocumentIdSet,contentDistIdSet);
  
        test.stopTest();
    }
  } 
}