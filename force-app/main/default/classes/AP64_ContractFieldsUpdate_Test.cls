@isTest
public class AP64_ContractFieldsUpdate_Test {
    static User testAdmin;
    static User testPM;
    static List<User> lstUsers = new List<User>();
    static Contract__c ctr;
    static eSignature__c esignature;
    static Esignatory__c esignatory1, esignatory2, esignatory3, esignatory4, esignatory5, esignatory6;
    static List<esignatory__c> esignatories = new List<esignatory__c>();
    static LC03_GenerateInvoicingLines.WrapperLine line1 = new LC03_GenerateInvoicingLines.WrapperLine();
    static List<LC03_GenerateInvoicingLines.WrapperLine> lstLines = new List<LC03_GenerateInvoicingLines.WrapperLine>();
    static String message;
    static ContentWorkspace workspace;
    static Account vLEntity1;
    static Contact vEntityContact1;
    static List<Contact> lstCons;
    static Account vEntity1;
    static Account vMEntity1;
    static Opportunity vOpp;
    static String lines;
    static Master_WBS_Structure__c vActivityCode1;

    static{
        testAdmin = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        lstUsers.add(testAdmin);

        testPM = TestFactory.createUserLightning('UsrPM',TestFactory.getProfileIdByName(Label.Profile_PM),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        lstUsers.add(testPM);
        insert lstUsers;
    
        System.runAs(testAdmin){
            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = testAdmin.Id, SkipProcessBuilder__c = true);
            insert settings;
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(testAdmin);

            vActivityCode1 = AP05_TestDataFactory.createActivityCode('L21FS_FM_000023', 'AXA Group Operations SAS - Sucursal em Portugal');

            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(testAdmin, 'testLegalEntity');
            vEntity1 = AP05_TestDataFactory.createEntityAccount(testAdmin, 'testEntity');
            //vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEntity1, vLEntity1);
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLEntity1);
            
            Account supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;
            
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;

            lstCons = new List<Contact>{
                new Contact(lastname = 'Brown',AccountId=vLEntity1.Id,Email='testBrown@email.com',MobilePhone='6585441'),
                new Contact(lastname = 'James',AccountId=vLEntity1.Id,Email='testJames@email.com',MobilePhone='6585442'),
                new Contact(lastname = 'Boof',AccountId=vLEntity1.Id,Email='testBoof@email.com',MobilePhone='6585443'),
                new Contact(lastname = 'Bob',AccountId=vLEntity1.Id,Email='testBob@email.com',MobilePhone='6585444'),
                new Contact(lastname = 'Daf',AccountId=vLEntity1.Id,Email='testDat@email.com',MobilePhone='6585445'),
                new Contact(lastname = 'Tom',AccountId=vLEntity1.Id,Email='testTom@email.com',MobilePhone='6585446'),
                new Contact(lastname = 'Jim',AccountId=vLEntity1.Id,Email='testJim@email.com',MobilePhone='6585447')
            };
            insert lstCons;

            //ctr = new Contract__c(Name='contract1', Status__c=AP_Constant.CONTRACT_STATUS_DRAFT, RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();)
            ctr = AP05_TestDataFactory.createContract(vProduct, vLEntity1, testPM, vEntityContact1, 'Draft', false);
            ctr.Name='contract1';
            ctr.Account__c=vLEntity1.Id;
            ctr.SOW_Type__c=AP_Constant.SOW_PRODUCT_TEMPLATE;
            ctr.Global_Amount__c=245;
            ctr.RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();
            
            ctr.StartDate__c = System.Date.Today();
            ctr.EndDate__c = System.Date.Today();
            ctr.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            ctr.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            ctr.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;
            ctr.AXA_GS_Signed_By__c = vEntityContact1.Id;
            ctr.Customer_Operational_Contact__c = vEntityContact1.Id;
            ctr.CustomerSignedBy__c=lstCons[0].id;
            insert ctr;
            
            line1.ContractId = ctr.Id;
            line1.ActivityCode = vActivityCode1;
            line1.Amount = 25000;
            lstLines.add(line1);
            lines = Json.serialize(lstLines);
            
            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;
            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, ctr.Id);          
            insert cd;
            ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                            from ContentDistribution 
                                            where id=: cd.Id ];  

            //LC03_GenerateInvoicingLines.GenerateAContractPInvoicingLine(ctr.Id);
            LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
            ctr.PDFStatus_lgt__c = 'Updated';
            ctr.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            ctr.status__c=AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;

            ctr.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();
            update ctr;
            
            
            esignature=TestFactory.createEsignature(ctr,'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
        }
    }


    @IsTest
    static void updateCtrPendingSince_Test(){
        System.runAs(testAdmin){
            Test.startTest();

            esignatory1= TestFactory.createEsignatory(ctr, esignature,lstCons[0].Name,lstCons[0].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory1.Order__c=1;
            esignatory1.OrderCachet__c=1;
            esignatory1.EmailTxt__c = lstCons[0].Email;
            esignatory1.Name=lstCons[0].lastname;
            esignatory1.Code__c = 'email';
            esignatory1.MobileTxt__c='45648461';
            esignatory1.ctin_Role__c = AP_Constant.esignRoleValidator;
            esignatories.add(esignatory1);

            esignatory2= TestFactory.createEsignatory(ctr, esignature,vEntityContact1.Name,vEntityContact1.id,AP_Constant.esignatoryStatusNotStarted);
            esignatory2.Order__c=2;
            esignatory2.OrderCachet__c=2;
            esignatory2.EmailTxt__c = vEntityContact1.Email;
            esignatory2.Name=lstCons[1].lastname;
            esignatory2.Code__c = 'email';
            esignatory2.MobileTxt__c='45648462';
            esignatory2.ctin_Role__c = AP_Constant.esignRoleValidator;
            esignatories.add(esignatory2);

            esignatory3= TestFactory.createEsignatory(ctr, esignature,lstCons[2].Name,lstCons[2].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory3.Order__c=3;
            esignatory3.OrderCachet__c=3;
            esignatory3.EmailTxt__c = lstCons[2].Email;
            esignatory3.Name=lstCons[2].lastname;
            esignatory3.Code__c = 'email';
            esignatory3.MobileTxt__c='45648463';
            esignatory3.ctin_Role__c = AP_Constant.esignRoleValidator;
            esignatories.add(esignatory3);

            esignatory4= TestFactory.createEsignatory(ctr, esignature,lstCons[3].Name,lstCons[3].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory4.Order__c=4;
            esignatory4.OrderCachet__c=4;
            esignatory4.EmailTxt__c = lstCons[3].Email;
            esignatory4.Name=lstCons[3].lastname;
            esignatory4.Code__c = 'email';
            esignatory4.MobileTxt__c='45648464';
            esignatory4.ctin_Role__c = AP_Constant.esignRoleValidator;
            esignatories.add(esignatory4);

            esignatory5= TestFactory.createEsignatory(ctr, esignature,lstCons[4].Name,lstCons[4].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory5.Order__c=5;
            esignatory5.OrderCachet__c=5;
            esignatory5.EmailTxt__c = lstCons[4].Email;
            esignatory5.Name=lstCons[4].lastname;
            esignatory5.Code__c = 'email';
            esignatory5.MobileTxt__c='45648465';
            esignatory5.ctin_Role__c = AP_Constant.esignRoleSigner;
            esignatories.add(esignatory5);

            esignatory6= TestFactory.createEsignatory(ctr, esignature,lstCons[5].Name,lstCons[5].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory6.Order__c=6;
            esignatory6.OrderCachet__c=6;
            esignatory6.EmailTxt__c = lstCons[5].Email;
            esignatory6.Name=lstCons[5].lastname;
            esignatory6.Code__c = 'email';
            esignatory6.MobileTxt__c='45648466';
            esignatory6.ctin_Role__c = AP_Constant.esignRoleSigner;
            esignatories.add(esignatory6);

            LC50_ManageEsignature.saveChanges(esignature.Id, esignatories);
            
            esignatories = [SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,
                            TECH_defaultSignatory__c,Tech_OriginalSignatory__c,OrderCachet__c,orderToSend__c,Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c 
                            FROM eSignatory__c 
                            WHERE esignature__c = :esignature.Id 
                            ORDER BY Order__c ASC];
            system.debug('*****esignatories '+esignatories.size());
            esignatory1= TestFactory.createEsignatory(ctr, esignature,lstCons[6].Name,lstCons[6].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory1.Order__c=1;
            esignatory1.OrderCachet__c=1;
            esignatory1.EmailTxt__c = lstCons[6].Email;
            esignatory1.Name=lstCons[6].lastname;
            esignatory1.Code__c = 'email';
            esignatory1.MobileTxt__c='45648461';
            esignatory1.ctin_Role__c = AP_Constant.esignRoleValidator;
            esignatories[0] = esignatory1;

            LC50_ManageEsignature.saveChanges(esignature.Id, esignatories);
            LC50_ManageEsignature.submitEsignature(esignature.Id);
            ctr = [SELECT ID,Validator1__c,Validator2__c,Validator3__c,Validator4__c, CurrentEsignatureStep__c FROM Contract__c WHERE Id = :ctr.Id];
            System.assert(ctr.Validator1__c != null && ctr.Validator2__c != null && ctr.Validator3__c != null && ctr.Validator4__c != null);
            System.assert(ctr.CurrentEsignatureStep__c == 'Validator 1');
            Test.stopTest();                
        }
    }

    @IsTest
    static void cancelEsignature_Test(){
        System.runAs(testAdmin){
            Test.startTest();
            LC13_CancelESignature.cancelESignature(ctr.Id);
            ctr = [SELECT ID,Validator1__c,Validator2__c,Validator3__c,Validator4__c, CurrentEsignatureStep__c FROM Contract__c WHERE Id = :ctr.Id];
            System.assert(ctr.Validator1__c == null && ctr.Validator2__c == null && ctr.Validator3__c == null && ctr.Validator4__c == null);
            Test.stopTest();      
        }
    }
}