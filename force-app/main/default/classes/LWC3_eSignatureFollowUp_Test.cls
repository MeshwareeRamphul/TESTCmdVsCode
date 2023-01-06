@isTest
public class LWC3_eSignatureFollowUp_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : LWC3_eSignatureFollowUp_Test
-- - Author        : ARA
-- - Description   : test class for LWC3_eSignatureFollowUp
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 24-SEP-2021  ARA    1.0     Initial version
--------------------------------------------------------------------------------------*/
    static User                      testUser;
    static Esignature__c             esignature;
    static Contract__c               contract;
    static Contract__c               contract2;
    static list<Account>             vAccountLst   = new list<Account>();
    static list<Esignatory__c>       esignatoryLst = new list<Esignatory__c>();
    static list<Contact>             contactLst    = new list<Contact>();
    static Map<String,Object> mapOfResult = new Map<String,Object>();
    static ContentVersion            content;
    static ContentDistribution       cd;
    static Planned_Invoicing_Line__c pInvLine;
    static Id contractId;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    
    static{
        
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        
        system.runAs(testUser){// Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = testUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            vProduct = AP05_TestDataFactory.createProduct(testUser);
            
            Contact con1=TestFactory.createContact(vAccount,'James','Brown');
            Contact con2=TestFactory.createContact(vAccount,'Jim','Brown'); 
            Contact con3=TestFactory.createContact(vAccount,'Jane','Brown');
            Contact con4=TestFactory.createContact(vAccount,'Tom','Brown');
            Contact con15=new contact(lastname = 'Brown', AccountId = vAccount.Id);
            
            contactLst.add(con1);
            contactLst.add(con2); 
            contactLst.add(con3);
            contactLst.add(con4);
            contactLst.add(con15);
            insert contactLst;
            
            contract = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false); 
            contract2 = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);   
            List<contract__c> lstctr = new List<contract__c>();         
            lstctr.add(contract);
            lstctr.add(contract2);
            insert lstctr;
            
            pInvLine=TestFactory.createPInvoicingLine(contract,'description');
            insert pInvLine;
            
            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;
            
            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
            insert cd;
            
            ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                          from ContentDistribution 
                                          where id=: cd.Id ];  
            contract.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            contract.LinkToDocument__c= cdistr.DistributionPublicUrl;
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
            contactLst[2].MobilePhone='6585444';
            contactLst[2].Email='Janeb@email.com';
            contactLst[2].Title='Operator';
            update contactLst;

            contract.CustomerSignedBy2__c=contactLst[2].id;
            update contract;
            
            test.startTest();
                mapOfResult = LC49_CreateSignature.validateCreateSign(contractId);
                system.assertEquals(null, mapOfResult.get('error'));
                
                esignature__c esign=[select Id from esignature__c where contract__c=:contract.id];
            	esign.status__c = 'Sent';
            	update esign;
				LWC3_eSignatureFollowUp.ResultWrapper result = LWC3_eSignatureFollowUp.getEsignatory(contractId);
                system.assertEquals(3, result.esignatory.size());
            test.stopTest();
        }
    }
}