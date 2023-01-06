@istest
public class VFC54_EsignatoryRelatedList_Test {
   /* 
    --------------------------------------------------------------------------------------
    -- - Name          : VFC54_EsignatoryRelatedList
    -- - Author        : Spoon Consulting 
    -- - Description   : test class for VFC54_EsignatoryRelatedList
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 26-JUL-2021  MRA    1.0     Initial version
    --------------------------------------------------------------------------------------*/

    static User testAdmin;
    static User testPM;
    static List<User> lstUsers = new List<User>();
    static Contract__c ctr;
    static eSignature__c esignature;
    static Map<String,String> message;
    static Account vLEntity1;
    static Contact vEntityContact1;
    static List<Contact> lstCons;

    static Account vEntity1;
    static Account vMEntity1;
    static Opportunity vOpp;
    static ContentWorkspace workspace;

    static{
        testAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testAdmin.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
        lstUsers.add(testAdmin);

        //testPM = TestFactory.createUser('UsrPM',TestFactory.getProfileIdByName('Project Manager'),true);
        //testPM.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;

        //lstUsers.add(testPM);

        insert lstUsers;
      
        testAdmin.Bypass_FieldFilter__c=true;
        update testAdmin;
        
        System.runAs(testAdmin){
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(testAdmin);

            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(testAdmin, 'testLegalEntity');
            vEntity1 = AP05_TestDataFactory.createEntityAccount(testAdmin, 'testEntity');
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEntity1, vLEntity1);
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLEntity1);
           
            Account supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;

            lstCons = new List<Contact>{
                new Contact(lastname = 'Brown',AccountId=supplier.Id,Email='testBrown@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'James',AccountId=supplier.Id,Email='testJames@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'Boof',AccountId=supplier.Id,Email='testBoof@email.com',MobilePhone='6585444')
            };
            insert lstCons;

            //ctr = new Contract__c(Name='contract1', Status__c=AP_Constant.CONTRACT_STATUS_DRAFT, RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();)
            ctr = AP05_TestDataFactory.createContract(vProduct, vLEntity1, testAdmin, vEntityContact1, 'Draft', false);
            ctr.Name='contract1';
            ctr.Account__c=vLEntity1.Id;
            //ctr.SOW_Type__c=AP_Constant.SOW_ENVELOPPE;
            ctr.Global_Amount__c=245;
            ctr.RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();
            
            System.debug('## ctr '+ctr);
            insert ctr;
            System.debug('###SGO### ctr select ' + [SELECT Id,/* Invoicing_Parameter__c, */ Invoicing_condition__c, Language__c, Global_Amount__c, Name, StartDate__c, EndDate__c, CurrencyIsoCode, Master_WBS_2__c /*, Master_WBS__c */
                   FROM Contract__c 
                   WHERE Id = :ctr.Id Limit 1]);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;
        }
    }

    @isTest
    static void testGetlstEsignatory(){
        System.runAs(testAdmin){
            Test.startTest();
                ctr.StartDate__c = System.Date.Today();
                ctr.EndDate__c = System.Date.Today();
                ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                ctr.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
                ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
                //LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
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

                List<Esignatory__c> lstEsignatory = new List<Esignatory__c>();
                Esignatory__c esignatory1= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[0].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory1.Order__c=1;
                esignatory1.OrderCachet__c=1;
                esignatory1.MobileTxt__c='45648464';
                esignatory1.Status__c='Ready';
                esignatory1.EmailTxt__c='esignatory1@gmail.com';
                lstEsignatory.add(esignatory1);
            
                Esignatory__c esignatory2= TestFactory.createEsignatory(ctr, esignature,'Jane',lstCons[1].id,AP_Constant.esignatoryStatusNotStarted);
                esignatory2.Order__c=2;
                esignatory2.OrderCachet__c=2;
                esignatory2.MobileTxt__c='45648465';
                esignatory2.Status__c='Awaiting';
                esignatory2.EmailTxt__c='esignatory2@gmail.com';
                lstEsignatory.add(esignatory2);
                insert lstEsignatory;

                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update ctr;
                VFC54_EsignatoryRelatedList chMode = new VFC54_EsignatoryRelatedList();
                chMode.esign = lstEsignatory[0];
                chMode.getlstEsignatory();
                //System.assertEquals(2, lstEsignatory.size());
            Test.stopTest();
        }
    }
}