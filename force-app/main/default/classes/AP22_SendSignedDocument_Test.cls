@isTest
public with sharing class AP22_SendSignedDocument_Test {
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP22_SendSignedDocument_Test
    -- - Author        : Spoon Consulting 
    -- - Description   : test class for AP22_SendSignedDocument
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 19-MAY-2021  ARA    1.0     Initial version
    --------------------------------------------------------------------------------------*/

    static User testAdmin;
    static List<User> lstUsers = new List<User>();
    static Contract__c ctr;
    static eSignature__c esignature;
    static Map<String,String> message;
    static List<Contact> lstCons;
    static LC03_GenerateInvoicingLines.WrapperLine line1 = new LC03_GenerateInvoicingLines.WrapperLine();
    static List<LC03_GenerateInvoicingLines.WrapperLine> lstLines = new List<LC03_GenerateInvoicingLines.WrapperLine>();
    static String lines;
    static Master_WBS_Structure__c vActivityCode1;
    static Account vEntity1;
    static Account vMEntity1;
    static Opportunity vOpp;
    static ContentWorkspace workspace;
    static Blob beforeblob;

    
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;

    static{
        testAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testAdmin.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
        insert testAdmin;

        testAdmin.PAD_BypassTrigger__c = 'AP52';
        testAdmin.cTin_Universign__c = true;
        testAdmin.Bypass_FieldFilter__c= true;
        update testAdmin;
    
        System.runAs(testAdmin){

            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(testAdmin);
            vActivityCode1 = AP05_TestDataFactory.createActivityCode('L21FS_FM_000023', 'AXA Group Operations SAS - Sucursal em Portugal');

            
            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testAdmin);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testAdmin);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);

            Account supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;

            lstCons = new List<Contact>{
                new Contact(lastname = 'Brown',AccountId=supplier.Id,Email='testBrown@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'James',AccountId=supplier.Id,Email='testJames@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'Boof',AccountId=supplier.Id,Email='testBoof@email.com',MobilePhone='6585444')
            };
            insert lstCons;

            //ctr = new Contract__c(Name='contract1', Status__c=AP_Constant.CONTRACT_STATUS_DRAFT, RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();)
            /*ctr = AP05_TestDataFactory.createContract(vProduct, vLEntity1, testAdmin, vEntityContact1, 'Draft', false);
            ctr.Name='contract1';
            ctr.Account__c=supplier.Id;
            ctr.SOW_Type__c=AP_Constant.SOW_PRODUCT_TEMPLATE;
            ctr.Global_Amount__c=245;
            ctr.RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();*/
            

            ctr =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vAccount, testAdmin, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            System.debug('## ctr '+ctr);
            insert ctr;
            
            /*beforeblob = Blob.valueOf('Unit Test Attachment Body');
            ContentVersion cv = new ContentVersion();
            cv.title = 'test_SOW_signed.pdf';      
            cv.PathOnClient = 'test';           
            cv.VersionData = beforeblob;
            insert cv;

            ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = ctr.id;
            contentlink.ShareType = 'I';
            contentlink.ContentDocumentId = testcontent.ContentDocumentId;
            contentlink.Visibility = 'AllUsers'; 
            insert contentlink;*/

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;
        }
    }

    @isTest
    static void testGetlstEsignatory(){
        System.runAs(testAdmin){
            Test.startTest();
                system.debug('******************testAdmin '+testAdmin.PAD_BypassTrigger__c);
                line1.ContractId = ctr.Id;
                line1.ActivityCode = vActivityCode1;
                line1.Amount = 25000;
                lstLines.add(line1);
                lines = Json.serialize(lstLines);

                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
                ctr.AXA_GS_Signed_By__c = vEntityContact.Id;
                LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                ctr.PDFStatus_lgt__c = 'Updated';

                ctr.Customer_Operational_Contact__c = vEntityContact.Id;
                ctr.CustomerSignedBy__c=lstCons[0].id;
                ContentVersion content=TestFactory.createContentVersion('test_SOW_signed.pdf', 'test_SOW_signed.pdf', 'Content',false);
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

                List<Esignatory__c> lstEsignatory = new List<Esignatory__c>();
                Esignatory__c esignatory1= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[0].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory1.Order__c=1;
                esignatory1.OrderCachet__c=1;
                esignatory1.cTin_Role__c='Signer';
                esignatory1.MobileTxt__c='45648464';
                esignatory1.Status__c='Ready';
                esignatory1.EmailTxt__c='esignatory1@gmail.com';
                lstEsignatory.add(esignatory1);
            
                Esignatory__c esignatory2= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[1].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory2.Order__c=2;
                esignatory2.OrderCachet__c=2;
                esignatory2.cTin_Role__c='Signer';
                esignatory2.MobileTxt__c='45648465';
                esignatory2.Status__c='Awaiting';
                esignatory2.EmailTxt__c='esignatory2@gmail.com';
                lstEsignatory.add(esignatory2);
                insert lstEsignatory;

                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update ctr;
                VFC53_EsignatoryChaining chMode = new VFC53_EsignatoryChaining();
                chMode.esign = lstEsignatory[0];
                lstEsignatory = chMode.getlstEsignatory();
            
                lstEsignatory[0].Status__c = 'Signed';
                lstEsignatory[1].Status__c = 'Signed';
                update lstEsignatory;
                esignature.Status__c = 'Completed';
                update esignature;
                ctr.Signature_Type__c = 'Electronic';
                ctr.Status__c = 'Signed';
                update ctr;
            AP22_SendSignedDocument.sendToSignatories(new List<ContentDistribution>{cdistr});
            Test.stopTest();
        }
    }
    
    @isTest
    static void testcTinSendNotif(){
        System.runAs(testAdmin){
            Test.startTest();
                Account acct = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
                insert acct;

            	Contract__c con=TestFactory.createcTinContracts('Test Contract1', acct.Id, Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId());
                con.cTin_Reminder__c='N/A';
                con.cTin_SendMonthlyReminder__c =false;
                con.cTin_MonthlyReminderDate__c =system.today();
				insert con;
              
                ContentVersion content=TestFactory.createContentVersion('test_signed.pdf', 'test_signed.pdf', 'Content',false);
                insert content;

                ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
                insert cd;

                ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                                from ContentDistribution 
                                                where id=: cd.Id ];  
                con.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
                con.status__c='In Signature';

                con.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Read Only').getRecordTypeId();
				update con;
            
                esignature=TestFactory.createEsignature(con,'esign1', AP_Constant.eSignatureCreatedStatus);
                esignature.transactionId__c='5454sdsadaf';
                insert esignature;
				
                List<Esignatory__c> lstEsignatory = new List<Esignatory__c>();
                Esignatory__c esignatory1= TestFactory.createEsignatory(con, esignature,'Jane',lstCons[0].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory1.Order__c=1;
                esignatory1.OrderCachet__c=1;
                esignatory1.cTin_Role__c='Signer';
                esignatory1.MobileTxt__c='45648464';
                esignatory1.Status__c='Ready';
                esignatory1.EmailTxt__c='esignatory1@gmail.com';
                esignatory1.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByDeveloperName().get('cTin_AXA_Representative').getRecordTypeId();
                lstEsignatory.add(esignatory1);
            
                Esignatory__c esignatory2= TestFactory.createEsignatory(con, esignature,'Jane',lstCons[1].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory2.Order__c=2;
                esignatory2.OrderCachet__c=2;
                esignatory2.cTin_Role__c='Signer';
                esignatory2.MobileTxt__c='45648465';
                esignatory2.Status__c='Awaiting';
                esignatory2.EmailTxt__c='esignatory2@gmail.com';
                lstEsignatory.add(esignatory2);
                insert lstEsignatory;
				lstEsignatory[0].Status__c = 'Signed';
                lstEsignatory[1].Status__c = 'Signed';
                update lstEsignatory;
            	esignature.status__c='Completed';
            	update esignature;
                
            	AP22_SendSignedDocument.sendToSignatories(new List<ContentDistribution>{cdistr});
            Test.stopTest();
        }
    }
}