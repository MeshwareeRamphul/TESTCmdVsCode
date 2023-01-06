@isTest
public with sharing class LC13_CancelESignature_Test {

    static User testAdmin;
    static User testPM;
    static List<User> lstUsers = new List<User>();
    static Contract__c ctr;
    static eSignature__c esignature;
    static Map<String,String> message;
    static ContentWorkspace workspace;
    static Account vLEntity1;
    static Contact vEntityContact1;
    static List<Contact> lstCons;
    static Account vEntity1;
    static Account vMEntity1;
    static Opportunity vOpp;
    static{
        testAdmin = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        lstUsers.add(testAdmin);

        testPM = TestFactory.createUserLightning('UsrPM',TestFactory.getProfileIdByName('Project Manager'),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        lstUsers.add(testPM);

        insert lstUsers;
    
        System.runAs(testAdmin){
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(testAdmin);

            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(testAdmin, 'testLegalEntity');
            vEntity1 = AP05_TestDataFactory.createEntityAccount(testAdmin, 'testEntity');
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEntity1, vLEntity1);
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLEntity1);
           
            Account supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;

            
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  

            lstCons = new List<Contact>{
                new Contact(lastname = 'Brown',AccountId=vLEntity1.Id,Email='testBrown@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'James',AccountId=vLEntity1.Id,Email='testJames@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'Boof',AccountId=vLEntity1.Id,Email='testBoof@email.com',MobilePhone='6585444')
            };
            insert lstCons;

            //ctr = new Contract__c(Name='contract1', Status__c=AP_Constant.CONTRACT_STATUS_DRAFT, RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();)
            ctr = AP05_TestDataFactory.createContract(vProduct, vLEntity1, testPM, vEntityContact1, 'Draft', false);
            ctr.Name='contract1';
            ctr.Account__c=vLEntity1.Id;
            ctr.SOW_Type__c=AP_Constant.SOW_PRODUCT_TEMPLATE;
            ctr.Global_Amount__c=245;
            ctr.RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();
            
            System.debug('## ctr '+ctr);
            insert ctr;
            System.debug('###SGO### ctr select ' + [SELECT Id, Invoicing_condition__c, Language__c, Global_Amount__c, Name, StartDate__c, EndDate__c, CurrencyIsoCode, Master_WBS_2__c/*, Master_WBS__c */
                   FROM Contract__c 
                   WHERE Id = :ctr.Id Limit 1]);
        }
    }

    @IsTest
    static void cancelESignature_Test(){
        System.runAs(testAdmin){
            Test.startTest();
                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = 'Monthly';
                ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
                LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
                ctr.PDFStatus_lgt__c = 'Updated';

                ctr.Customer_Operational_Contact__c = vEntityContact1.Id;
                ctr.CustomerSignedBy__c=lstCons[0].id;
                ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
                insert content;

                ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
                insert cd;

                ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                                from ContentDistribution 
                                                where id=: cd.Id ];  
                ctr.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
                ctr.status__c=AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;

                ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();

                esignature=TestFactory.createEsignature(ctr,'esign1', AP_Constant.eSignatureCreatedStatus);
                esignature.transactionId__c='5454sdsadaf';
                insert esignature;

                Esignatory__c esignatory3= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[2].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory3.Order__c=3;
                esignatory3.OrderCachet__c=3;
                esignatory3.MobileTxt__c='45648464';

                insert esignatory3;
                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update ctr;

                eSignature__c eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret '+ eSignRet);

                
                message = LC13_CancelESignature.cancelESignature(ctr.Id);
                System.debug('## message '+message);

                eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret after cancel '+ eSignRet);

            Test.stopTest();

//            System.assert(message.startsWith('a0S'));
//            System.assertEquals(AP_Constant.eSignatureCancelledStatus,eSignRet.Status__c);
        }
    }
    

    @IsTest
    static void testStatusNotSent(){
        System.runAs(testAdmin){
            Test.startTest();
                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = 'Monthly';
                ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
                LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
                ctr.PDFStatus_lgt__c = 'Updated';

                ctr.Customer_Operational_Contact__c = vEntityContact1.Id;
                ctr.CustomerSignedBy__c=lstCons[0].id;
                ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
                insert content;

                ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
                insert cd;

                ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                                from ContentDistribution 
                                                where id=: cd.Id ];  
                ctr.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
                ctr.status__c=AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;

                ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();

                esignature=TestFactory.createEsignature(ctr,'esign1', AP_Constant.eSignatureCreatedStatus);
                esignature.transactionId__c='5454sdsadaf';

                esignature.Status__c = AP_Constant.eSignatureInprogressStatus;

                insert esignature;

                Esignatory__c esignatory3= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[2].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory3.Order__c=3;
                esignatory3.OrderCachet__c=3;
                esignatory3.MobileTxt__c='45648464';

                insert esignatory3;
                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update ctr;

                eSignature__c eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret '+ eSignRet);

                
                message = LC13_CancelESignature.cancelESignature(ctr.Id);
                System.debug('## message '+message);

                eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret after cancel '+ eSignRet);

            Test.stopTest();

            System.assertEquals('The eSignature cannot be cancelled.',message.get('error'));
            System.assertEquals(AP_Constant.eSignatureInprogressStatus,eSignRet.Status__c);
        }
    }

    @IsTest
    static void testTransactionIdBlank(){
        System.runAs(testAdmin){
            Test.startTest();
                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = 'Monthly';
                ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
                LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
                ctr.PDFStatus_lgt__c = 'Updated';

                ctr.Customer_Operational_Contact__c = vEntityContact1.Id;
                ctr.CustomerSignedBy__c=lstCons[0].id;
                ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
                insert content;

                ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
                insert cd;

                ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                                from ContentDistribution 
                                                where id=: cd.Id ];  
                ctr.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
                ctr.status__c=AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;

                ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();

                esignature=TestFactory.createEsignature(ctr,'esign1', AP_Constant.eSignatureCreatedStatus);
                //esignature.transactionId__c='5454sdsadaf';

                esignature.Status__c = AP_Constant.eSignatureSentStatus;
                
                insert esignature;

                Esignatory__c esignatory3= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[2].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory3.Order__c=3;
                esignatory3.OrderCachet__c=3;
                esignatory3.MobileTxt__c='45648464';

                insert esignatory3;
                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update ctr;

                eSignature__c eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret '+ eSignRet);

                message = LC13_CancelESignature.cancelESignature(ctr.Id);
                System.debug('## message '+message);

                eSignRet = [SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c,Contract__c
                                FROM eSignature__c
                                WHERE Contract__c = :ctr.Id ];
                System.debug('## ESign ret after cancel '+ eSignRet);

            Test.stopTest();

            System.assert(message.containsKey('success'));
            System.assertEquals(AP_Constant.eSignatureCancelledStatus,eSignRet.Status__c);
        }
    }


    @IsTest
    static void testNoESignature(){
        System.runAs(testAdmin){
            Test.startTest();
                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = 'Monthly';
                ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
                LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
                ctr.PDFStatus_lgt__c = 'Updated';

                ctr.Customer_Operational_Contact__c = vEntityContact1.Id;
                ctr.CustomerSignedBy__c=lstCons[0].id;
                ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
                insert content;

                ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
                insert cd;

                ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                                from ContentDistribution 
                                                where id=: cd.Id ];  
                ctr.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
                ctr.status__c=AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;

                ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();
                ctr.Status__c = AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;
                update ctr;

                try{
                    LC13_CancelESignature.cancelESignature(ctr.Id);
                    //System.debug('## message '+message);

                }
                catch(AuraHandledException e){
                    System.debug('## message 33 '+message);
                    System.debug('## message 33 '+e.getMessage());
                    System.debug(e);
                    System.assertEquals('The eSignature cannot be cancelled.', e.getMessage());
                }
            Test.stopTest();
        }
    }
}