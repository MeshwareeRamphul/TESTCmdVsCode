@isTest
private class LC49_CreateSignature_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : LC49_CreateSignature_Test
-- - Author        : ARA
-- - Description   : test class for LC49_CreateSignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 19-OCT-2020  ARA    1.0     Initial version
--------------------------------------------------------------------------------------*/
    static User                      testUser;
    static Esignature__c             esignature;
    static Contract__c               contract;
    static Contract__c               contract2;
    static Account                   supplier;
    static list<Account>             supplierLst   = new list<Account>();
    static list<Esignatory__c>       esignatoryLst = new list<Esignatory__c>();
    static list<Contact>             contactLst    = new list<Contact>();
    static Map<String,Object> mapOfResult = new Map<String,Object>();
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
            
            pInvLine = AP05_TestDataFactory.createIL(contract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), supplier.Id);
            insert pInvLine;
            
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
    static testMethod void createEsignature1_test(){
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
            test.stopTest();
            system.assertEquals(null, mapOfResult.get('error'));
            //check if esignatories and esignature are generated with correct status
            /*list<esignatory__c> esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                              from esignatory__c 
                                              where eSignature__r.contract__c=:contract.id
                                              and status__c=:AP_Constant.esignatoryStatusNotStarted];
            system.assertEquals(3,esignatories.size());
            system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c);*/
        }
    }
    
    //test scenario - create esignature and esignatories
    static testMethod void createEsignature3_test(){
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
            test.startTest();
            	mapOfResult = LC49_CreateSignature.validateCreateSign(contractId);
            //check if esignatories and esignature are generated with correct status
            list<esignatory__c> esignatories=[select eSignature__r.status__c,eSignature__r.contract__c,status__c 
                                              from esignatory__c 
                                              where eSignature__r.contract__c=:contract.id
                                              and status__c=:AP_Constant.esignatoryStatusNotStarted];
            test.stopTest();
            system.assertEquals(null, mapOfResult.get('error'));
            system.assertEquals(3,esignatories.size());
            system.assertEquals(AP_Constant.eSignatureCreatedStatus,esignatories[0].eSignature__r.status__c); 
        }
    }
    
    //test scenario - attempt to create esignature with missing information
    static testMethod void createEsignatureMissingEmailError_test(){
        system.runAs(testUser){
            Contract__c contract = [SELECT Id, AXA_GS_Signed_By__r.Name, CustomerSignedBy__r.Name  FROM Contract__c WHERE id =: contract.id][0];
            test.startTest();
                //create esignature when esignatories have no email and phone
                mapOfResult = LC49_CreateSignature.validateCreateSign(contract.Id);
                system.assertEquals('Signatory ' + contract.AXA_GS_Signed_By__r.Name + ' ' + system.label.ErrorMessageNoActiveMail, mapOfResult.get('error'));
            
            	//create esignature when esignatories have no email and phone
                contactLst[1].MobilePhone='6585444';
                contactLst[1].Email='Jb@email.com';
                update contactLst;
                mapOfResult = LC49_CreateSignature.validateCreateSign(contract.Id);
                system.assertEquals('Signatory ' + contract.CustomerSignedBy__r.Name + ' ' + system.label.ErrorMessageNoActiveMail, mapOfResult.get('error'));
            test.stopTest();
        }
    }
    
    //test scenario - attempt to create esignature with esignatories have same email
    static testMethod void createEsignatureSameEmailError_test(){
        system.runAs(testUser){
            Contract__c contract = [SELECT Id, AXA_GS_Signed_By__r.Name, CustomerSignedBy__r.Name  FROM Contract__c WHERE id =: contract.id][0];
            test.startTest();
            	//create esignature when esignatories have no email and phone
                contactLst[0].MobilePhone='6585444';
                contactLst[0].Email='Jb@email.com';
                contactLst[1].MobilePhone='6585444';
                contactLst[1].Email='Jb@email.com';
                update contactLst;
                mapOfResult = LC49_CreateSignature.validateCreateSign(contract.Id);
                system.assertEquals(system.label.SameContactEmail, mapOfResult.get('error'));
            test.stopTest();
        }
    }
}