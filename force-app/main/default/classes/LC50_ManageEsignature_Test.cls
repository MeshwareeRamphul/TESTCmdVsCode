@isTest
public class LC50_ManageEsignature_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : LC50_ManageEsignature_Test
-- - Author        : ARA
-- - Description   : test class for LC50_ManageEsignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 20-OCT-2020  ARA    1.0     Initial version
--------------------------------------------------------------------------------------*/
    static User                      testUser;
    static Esignature__c             esignature;
    static Contract__c               contract;
    static Contract__c               contract2;
    static Account                   supplier;
    static list<Account>             supplierLst   = new list<Account>();
    static list<Esignatory__c>       esignatoryLst = new list<Esignatory__c>();
    static list<Contact>             contactLst    = new list<Contact>();
    static Map<String,Object> 		 mapOfResult = new Map<String,Object>();
    static ContentVersion            content;
    static ContentDistribution       cd;
    static Planned_Invoicing_Line__c pInvLine;
    static Id contractId;
    static list<esignatory__c> esignatories;
    
    static{
        
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Bypass_FieldFilter__c = true;
        testUser.PAD_BypassValidationRules__c = true;
        testUser.cTin_Universign__c = true;
        insert testUser;
        
        system.runAs(testUser){
            supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;
            
            Contact con1=TestFactory.createContact(supplier,'James','Brown');
            con1.MobilePhone='6585444';
            con1.Email='Jb@email.com';
            Contact con2=TestFactory.createContact(supplier,'Jim','Brown'); 
            con2.MobilePhone='6585444';
            con2.Email='JimB@email.com';
            Contact con3=TestFactory.createContact(supplier,'Jane','Brown');
            con3.MobilePhone='6585444';
            con3.Email='JaneB@email.com';
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
            
            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;
            
            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
            insert cd;
            
            ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                          from ContentDistribution 
                                          where id=: cd.Id ];  
            contract.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            contract.status__c = AP_Constant.contractReadyStatus;
            contract.CustomerSignedBy__c = contactLst[0].id;
            contract.AXA_GS_Signed_By__c = contactLst[1].id;
            contract.Customer_Operational_Contact__c = contactLst[2].id;
            update contract;
            
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            contractId=[select id from Contract__c where id =: contract.id].id;
            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=contractId, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;
            
            
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void getSObject_test(){
        system.runAs(testUser){
            test.startTest();
            system.assertEquals(1, LC50_ManageEsignature.getSObject('Contact', contactLst[2].id).size());
            test.stopTest();
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void saveChanges_test(){
        system.runAs(testUser){
            
            test.startTest();
                LC49_CreateSignature.validateCreateSign(contractId);
                
                esignature = [SELECT Id 
                              FROM esignature__c 
                              WHERE contract__c = :contractId];
                
                esignatories = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,Tech_OriginalSignatory__c,OrderCachet__c,orderToSend__c
                                ,Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c 
                                FROM esignatory__c 
                                WHERE eSignature__c = :esignature.Id
                                ORDER BY  Order__c ASC];
                
                esignatories[0].Code__c = 'email';
                esignatories[1].Code__c = 'email';
                esignatories[1].Order__c = 3;
                    
                Esignatory__c esignatory3 = TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory3.Order__c = 2;
                esignatory3.MobileTxt__c = '45648464';
                esignatory3.Code__c = 'email';
                esignatory3.EmailTxt__c = contactLst[2].Email;
                esignatory3.TECH_defaultSignatory__c = false;
                esignatory3.Tech_OriginalSignatory__c = false;
                esignatory3.EntityName__c = contactLst[2].Account.Id;
                esignatories.add(esignatory3);
            
            	LC50_ManageEsignature.saveChanges(esignature.Id, esignatories);
            test.stopTest();
            system.assertEquals(null, mapOfResult.get('error'));
            //check if esignatories and esignature are generated with correct status
            esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                              from esignatory__c 
                                              where eSignature__r.contract__c=:contract.id
                                              and status__c=:AP_Constant.esignatoryStatusNotStarted];
            system.assertEquals(3,esignatories.size());
            system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c);
        }
    }
    
    //test scenario - save the edited esignatories
    /*@isTest
    static void saveChangesError_test(){
        system.runAs(testUser){
            
            test.startTest();
                LC49_CreateSignature.validateCreateSign(contractId);
                
                esignature = [SELECT Id 
                              FROM esignature__c 
                              WHERE contract__c = :contractId];
                
                esignatories = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,Tech_OriginalSignatory__c,OrderCachet__c,orderToSend__c
                                ,Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c 
                                FROM esignatory__c 
                                WHERE eSignature__c = :esignature.Id
                                ORDER BY  Order__c ASC];
                                    
                esignatories[0].MobileTxt__c = '';
                esignatories[0].Code__c = 'sms';
                esignatories[1].Code__c = 'email';

            	mapOfResult = LC50_ManageEsignature.saveChanges(esignature.Id, esignatories);
            test.stopTest();
            system.assertEquals(System.label.MessageMobileBlock, mapOfResult.get('error'));
        }
    }*/
    
    //test scenario - save the edited esignatories
    @isTest
    static void buildSignatorylst_test(){
        system.runAs(testUser){
            
            test.startTest();
                LC49_CreateSignature.validateCreateSign(contractId);
                
                esignature = [SELECT Id 
                              FROM esignature__c 
                              WHERE contract__c = :contractId];

            	mapOfResult = LC50_ManageEsignature.buildSignatorylst(esignature.Id);
            test.stopTest();
           // system.assertEquals(2, ((list<Esignatory__c>)mapOfResult.get('lst')).size());
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void getSObjectList_test(){
        system.runAs(testUser){
            test.startTest();
            	List<Contact> lstContact = LC50_ManageEsignature.getSObjectList('Brown');
            	system.assertEquals(15, lstContact.size());
            test.stopTest();
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void getCodes_test(){
        system.runAs(testUser){
            test.startTest();
            	Map<String, String> mapCode = LC50_ManageEsignature.getCodes();
            	system.assertEquals(2, mapCode.size());
            test.stopTest();
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void submitEsignatureNotAllow_test(){
        system.runAs(testUser){
            test.startTest();
            	LC49_CreateSignature.validateCreateSign(contractId);
            	esignature = [SELECT Id 
                              FROM esignature__c 
                              WHERE contract__c = :contractId];
            	esignature.Status__c = AP_Constant.eSignatureSentStatus;
            	eSignature.TransactionID__c = 'eee1261rg3513d_51g631g6_5g5gfc6';
            	update eSignature;
            
            	mapOfResult = LC50_ManageEsignature.submitEsignature(esignature.Id);
            test.stopTest();
            system.assertEquals(system.label.EsignatureSubmitError, mapOfResult.get('error'));
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void submitEsignature_test(){
        system.runAs(testUser){
            Test.startTest();
            
                pInvLine = AP05_TestDataFactory.createIL(contract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), supplier.Id);
                //pInvLine=TestFactory.createPInvoicingLine(contract,'description');
                insert pInvLine;
                Map<string,object> mapResult = LC49_CreateSignature.validateCreateSign(contractId);
    
                /*lstESignatureRet = [select Id, name, Contract__c, Status__c, TransactionID__c, eSignatory_Name__c, eSignatory_Name__r.Status__c, eSignatory_Name__r.signURL__c, cTin_TECH_IsContractIn__c FROM Esignature__c WHERE Contract__c = :lstContracts[0].Id];
               
                update lstESignatureRet;*/
                Esignature__c esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
                insert esignature;
                
    
                List<eSignatory__c> lsteSignatory = new List<eSignatory__c>{
                    TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[0].id,AP_Constant.esignatoryStatusNotStarted),
                    TestFactory.createEsignatory(contract, esignature,'John',contactLst[1].id,AP_Constant.esignatoryStatusNotStarted)
                };
                lsteSignatory[0].Order__c=3;
                lsteSignatory[0].OrderCachet__c=3;
                lsteSignatory[0].OrderToSend__c=3;
                lsteSignatory[0].OrderCreation__c=3;
                lsteSignatory[0].MobileTxt__c='45648464';
    
                lsteSignatory[1].Order__c=4;
                lsteSignatory[1].OrderCachet__c=4;
                lsteSignatory[1].OrderToSend__c=4;
                lsteSignatory[1].OrderCreation__c=4;
                lsteSignatory[1].MobileTxt__c='45648464';
    
                insert lsteSignatory;
          
                Map<string,object> mapofResult1 = LC50_ManageEsignature.getAllSignatories(esignature.Id);
                System.assert(mapofResult1.containsKey('data'));
              //  AP22_XmlRpcWrapper.dummyResponse =new TestFactory.WSResponse_Success_CreateXmlRpc().respond(new HTTPRequest());
                Map<string,object> mapofResult2 = LC50_ManageEsignature.submitEsignature(esignature.Id);
            Test.stopTest();
        }
    }
    
    //test scenario - save the edited esignatories
    @isTest
    static void submitEsignature2_test(){
        system.runAs(testUser){
            Test.startTest();
                Map<string,object> mapResult = LC49_CreateSignature.validateCreateSign(contractId);
                Esignature__c esignature=TestFactory.createEsignature(contract,'esign1', AP_Constant.eSignatureCreatedStatus);
                insert esignature;
                
    
                List<eSignatory__c> lsteSignatory = new List<eSignatory__c>{
                    TestFactory.createEsignatory(contract, esignature,'Jane',contactLst[0].id,AP_Constant.esignatoryStatusNotStarted),
                    TestFactory.createEsignatory(contract, esignature,'John',contactLst[1].id,AP_Constant.esignatoryStatusNotStarted)
                };
                lsteSignatory[0].Order__c=3;
                lsteSignatory[0].OrderCachet__c=3;
                lsteSignatory[0].OrderToSend__c=3;
                lsteSignatory[0].OrderCreation__c=3;
                lsteSignatory[0].MobileTxt__c='45648464';
    
                lsteSignatory[1].Order__c=4;
                lsteSignatory[1].OrderCachet__c=4;
                lsteSignatory[1].OrderToSend__c=4;
                lsteSignatory[1].OrderCreation__c=4;
                lsteSignatory[1].MobileTxt__c='45648464';
    
                insert lsteSignatory;
          
                Map<string,object> mapofResult1 = LC50_ManageEsignature.getAllSignatories(esignature.Id);
                System.assert(mapofResult1.containsKey('data'));
              //  AP22_XmlRpcWrapper.dummyResponse =new TestFactory.WSResponse_Success_CreateXmlRpc().respond(new HTTPRequest());
                Map<string,object> mapofResult2 = LC50_ManageEsignature.submitEsignature(esignature.Id);
            Test.stopTest();
        }
    }
}