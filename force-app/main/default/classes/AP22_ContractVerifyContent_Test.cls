@isTest
private class AP22_ContractVerifyContent_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_ContractVerifyContent_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP22_ContractVerifyContent
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 01-JUN-2017  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
    static User testUser;
    static list<Account>supplierLst=new list<Account>();
    static list<Contract__c>contractLst=new list<Contract__c>();
    static list<ContentVersion>cVersionLst=new list<ContentVersion>();
    static list<ContentDistribution> contentDistributionLst=new list<ContentDistribution>();
    static list<ContentVersion> contentVersionLst=new list<ContentVersion>();
    static list<ContentDistribution> lstcd = new list<ContentDistribution>();
    
    static{
      
      testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
      insert testUser;

      system.runAs(testUser){
          Account supplier1 = TestFactory.createSupplier('supplier 1','Paris','France');
          Account supplier2 = TestFactory.createSupplier('supplier 2','Paris','France');
          supplierLst.add(supplier1);
          supplierLst.add(supplier2);
          insert supplierLst;

          contract__c contract1 = TestFactory.createContract(supplier1.Id,'Contract1',AP_Constant.contractReadyStatus); 
          contract__c contract2 = TestFactory.createContract(supplier2.Id,'Contract2',AP_Constant.contractReadyStatus);
          contractLst.add(contract1);  
          contractLst.add(contract2);               
          insert contractLst;
          
          //new contentversions
          contentVersionLst=new list<ContentVersion>{ 
                    new ContentVersion(Title ='sampleContentWithTitleEXceedingNumberOfAllowedCharacters_signed1',
                        versiondata=blob.valueOf('test.pdf'),
                        PathOnClient='test.pdf'),
                    new ContentVersion(Title ='contractABC_signed2.pdf',
                        versiondata=blob.valueOf('test2.pdf'),
                        PathOnClient='test2.pdf'),
                    new ContentVersion(Title ='testabdhshdgshdg3',
                        versiondata=blob.valueOf('test3.pdf'),
                        PathOnClient='test3.pdf'),
                    new ContentVersion(Title ='testabdhshdgshdg4',
                        versiondata=blob.valueOf('test4.pdf'),
                        PathOnClient='test4.pdf')

                  };
        insert contentVersionLst;  
        
         lstcd = new list<ContentDistribution>{
                         new ContentDistribution(
                         name = 'TstContentDistribution1',
                         ContentVersionId = contentVersionLst[0].Id,
                         PreferencesAllowOriginalDownload = true,
                         PreferencesAllowPDFDownload = true,
                         PreferencesAllowViewInBrowser = true,
                         RelatedRecordId = contractLst[0].Id,
                         preferencesExpires=true,
                         expiryDate=date.today() +30),

                         new ContentDistribution(
                         name = 'TstContentDistribution2',
                         ContentVersionId = contentVersionLst[1].Id,
                         PreferencesAllowOriginalDownload = true,
                         PreferencesAllowPDFDownload = true,
                         PreferencesAllowViewInBrowser = true,
                         RelatedRecordId = contractLst[1].Id,
                         preferencesExpires=true,
                         expiryDate=date.today() +30) 
                        };

           insert lstcd;    

         /* ContentVersion cv1=TestFactory.createContentVersion('sampleContentWithTitleEXceedingNumberOfAllowedCharacters_signed1', 'sampleContentWithTitleEXceedingNumberOfAllowedCharacters_signed.doc', 'Content',true);
          ContentVersion cv2=TestFactory.createContentVersion('contractABC_signed2.pdf', 'contractABC_signed.pdf', 'Content',true);
          cVersionLst.add(cv1);
          cVersionLst.add(cv2);
          insert cVersionLst;

          ContentDistribution cd1=TestFactory.createContentDistribution(cVersionLst[0].id, cVersionLst[0].title, contractLst[0].Id);          
          ContentDistribution cd2=TestFactory.createContentDistribution(cVersionLst[1].id, cVersionLst[1].title, contractLst[1].Id);
          
          contentDistributionLst.add(cd1);
          contentDistributionLst.add(cd2);
          insert contentDistributionLst; */

      }   
    }
   
  static testmethod void validateContent_Test(){
    system.runAs(testUser){
        list<ContentDistribution> cDistributionLst=[select id,DistributionPublicUrl,name 
                                                   from ContentDistribution
                                                   where id IN:lstcd 
                                                   order by name asc];
        
        contractLst[0].finalDocumentUrl__c= cDistributionLst[0].DistributionPublicUrl;
        contractLst[1].finalDocumentUrl__c=  cDistributionLst[1].DistributionPublicUrl; 
        string errorMsg='';
        test.startTest();
            try{
              update contractLst;
            }
            catch(Exception e){
              errorMsg=e.getMessage();
            }
           
        test.stopTest();
        
        //system.assert(errorMsg!='');
        //system.assert(errorMsg.contains(system.label.AP10_ErrMsgPDFIncorrect));
       
    }
  }

  static testmethod void validateContentNoErrors_Test(){
    system.runAs(testUser){
        list<ContentDistribution> cDistributionLst=[select id,DistributionPublicUrl,name 
                                                   from ContentDistribution
                                                   where name =:'contractABC_signed2.pdf'
                                                   ];
        
       /* contractLst[0].finalDocumentUrl__c= cDistributionLst[0].DistributionPublicUrl;
        contractLst[1].finalDocumentUrl__c=  cDistributionLst[0].DistributionPublicUrl; 
        string errorMsg='';
        test.startTest();
            try{
              update contractLst;
            }
            catch(Exception e){
              errorMsg=e.getMessage();
            }
           
        test.stopTest();
        
        system.assert(!errorMsg.contains(system.label.AP10_ErrMsgLengthIncorrect));
       */
    }
  }

}