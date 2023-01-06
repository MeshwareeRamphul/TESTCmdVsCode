@isTest
private class VFC07_ContractPdfManageAttachExt_Test {

    static User vUserOO, vUserPM;
    static Account vAccount,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    
    
    //@testSetup
    //public static void createTestsDatas() {
        //Create datas for the tests methods
        //
    static{
        
        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        vUserPM.PAD_BypassValidationRules__c = true;
        vUserPM.PAD_BypassWorkflows__c = true;
        update vUserPM;
        
        System.runAs(vUserPM) {

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            // Create the customer (aka entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);
           
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);
            
            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact); 
        }   
 
    }

    // start test
    @isTest 
    Public static void  ControllerTest() {

        System.runAs(vUserPM) {

            Test.startTest();
                String Msg = '';
                 
                Contract__c c = [SELECT Id, Account__r.MSA_Date__c, Account__r.MSA_Reference__c,
                SOW_Type__c, RecordType.developerName,Planned_Invoicing_Lines_Amount__c, 
                Signature_Type__c, PDF_Status__c, Status__c, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                EndDate__c, Global_Amount__c, StartDate__c, AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Method__c, 
                Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, Master_WBS_2__c,
                CustomerSignedBy__c,  RecordTypeId, RecordType.Name, Amendment_to__c, Account__r.MSA_ATS_Date__c, 
                Account__r.MSA_ATS_Reference__c FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
                Test.setCurrentPageReference(Page.VFP07_ContractManagePdf);
                VFC07_ContractPdfManageAttachExt controller = new VFC07_ContractPdfManageAttachExt(new ApexPages.StandardController(c));
                controller.getaBlankSpace();
                System.assert(controller.validated == False);

               //PInvoicingLine
                Planned_Invoicing_Line__c vInvoicingLine = AP05_TestDataFactory.createIL(c, 100,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);    
                insert vInvoicingLine;
                c = [SELECT Id, Account__r.MSA_Date__c, Account__r.MSA_Reference__c, SOW_Type__c, RecordType.developerName,Planned_Invoicing_Lines_Amount__c, Signature_Type__c, 
                PDF_Status__c, Status__c, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, 
                Global_Amount__c, StartDate__c, AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Method__c, 
                Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, 
                CustomerSignedBy__c,  RecordTypeId, RecordType.Name, Amendment_to__c, Account__r.MSA_ATS_Date__c, 
                Account__r.MSA_ATS_Reference__c FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
                controller = new VFC07_ContractPdfManageAttachExt(new ApexPages.StandardController(c));
                //System.assert(controller.validated == True, Msg);         

                c.StartDate__c = null;
                c.EndDate__c = null;
                c.SOW_Operational__c = null;
                c.Global_Amount__c = 0;
                c.AXA_GS_Signed_By__c = null;
                c.ServiceType__c = null; 
                c.InvoicingMethod__c = null;
                c.TacitRenewal__c = null;

                update(c);

                c = [SELECT Account__r.MSA_Date__c, Account__r.MSA_Reference__c, SOW_Type__c, RecordType.developerName,Planned_Invoicing_Lines_Amount__c, PDF_Status__c, Status__c, Id, 
                CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c, 
                AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Method__c, Invoicing_Condition__c, Language__c,
                 Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c,  RecordTypeId, 
                 RecordType.Name, Amendment_to__c, Account__r.MSA_ATS_Date__c, Account__r.MSA_ATS_Reference__c FROM Contract__c 
                 WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
                controller = new VFC07_ContractPdfManageAttachExt(new ApexPages.StandardController(c));
                System.assert(controller.validated == False);  
            
            Test.stopTest();        
        }
    }

    @isTest 
    Public static void  ControllerTest2() {

        System.runAs(vUserPM) {            
            String Msg = '';
                 
            Contract__c c = [SELECT Id,RecordType.developerName,Planned_Invoicing_Lines_Amount__c, Signature_Type__c, PDF_Status__c, 
            Status__c, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, 
            StartDate__c, AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Method__c, Invoicing_Condition__c, 
            Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c,  
            RecordTypeId, RecordType.Name, Amendment_to__c, Account__r.MSA_ATS_Date__c, Account__r.MSA_ATS_Reference__c 
            FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/
            id=:vContract.Id][0];
            c.Invoicing_Condition__c = null;
            c.Global_Amount__c = 1000;
            c.RecordType.developerName = AP_Constant.RT_ATS_EDIT;
            update c;

            Test.startTest(); 
                Test.setCurrentPageReference(Page.VFP07_ContractManagePdf);
                VFC07_ContractPdfManageAttachExt controller = new VFC07_ContractPdfManageAttachExt(new ApexPages.StandardController(c));
                controller.getaBlankSpace();
                System.assert(controller.validated == False);

                controller.aBlankSpace = null;
                controller.lstProdItems = null;
            
            Test.stopTest();        
        }
    }

    @isTest 
    Public static void  ControllerTest3() {

        System.runAs(vUserPM) {            
            String Msg = '';
                 
            Contract__c c = [SELECT Account__r.MSA_Reference__c, Account__r.MSA_Date__c, Id, 
            RecordType.developerName,Planned_Invoicing_Lines_Amount__c, Signature_Type__c, PDF_Status__c, Status__c, 
            CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c, 
            AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Method__c, Invoicing_Condition__c, 
            Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c,  
            RecordTypeId, RecordType.Name, Amendment_to__c, Account__r.MSA_ATS_Date__c, Account__r.MSA_ATS_Reference__c 
            FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
            c.Invoicing_Condition__c = null;
            c.RecordType.developerName = AP_Constant.RT_CONTRACT_EDIT;
            c.AXA_GO_Legal_Entity__c = System.Label.Ctr_AXA_LE_SAS;
            update c;

            Test.startTest(); 
                Test.setCurrentPageReference(Page.VFP07_ContractManagePdf);
                VFC07_ContractPdfManageAttachExt controller = new VFC07_ContractPdfManageAttachExt(new ApexPages.StandardController(c));
                controller.getaBlankSpace();
                System.assert(controller.validated == False);

                controller.aBlankSpace = null;
                controller.lstProdItems = null;
            
            Test.stopTest();        
        }
    }
}