@isTest
public with sharing class VFC07_ContractDetailDashboard_Test { 

    static User vUserOO, vUserPM, userAdmin, vUserPMOADV;
    static Contract__c c,vContract ;
    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
    static Planned_Invoicing_Line__c vInvoicingLine;
    static Account vAccount,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Master_WBS_Structure__c vMasterWBS;
    static User adminUser;
    
    static{
        //Create datas for the tests methods

        // Create PM user
        //vUserPM = AP05_TestDataFactory.createPMUser(); 
        vUserPM = AP05_TestDataFactory.createPMOUser();  
        
        
        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName(); //'userAdmin@User.com';
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        adminUser.PAD_BypassValidationRules__c = true;
        insert adminUser;
        
        System.runAs(vUserPM) {            

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

            // Create the customer (aka entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);
            vAccount.Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC;
            update vAccount;

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            // Create the couple Entity - Billing Entity on Parent Entity 
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
                
            //Product
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            vMasterWBS = AP05_TestDataFactory.createActivityCode('L21FS_GC_000001', AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY);

            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact);
            vContract.Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC;
            vContract.Master_WBS_2__c = vMasterWBS.id;
            vContract.PDFStatus_lgt__c ='Updated';
            vContract.TacitRenewal__c = 'No';
            update vContract;            

            //Planned Inv Line
            vInvoicingLine = AP05_TestDataFactory.createIL(vContract, 100,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);    
            insert vInvoicingLine;
            
            c = [SELECT Customer_Operational_Contact__r.Email, Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c/*Invoicing_Parameter__c*/, PDFContrAtt__c, RecordType.DeveloperName 
            FROM Contract__c WHERE id=:vContract.Id ][0];
            System.debug('## c queried test ## : ' + c);
        }
    }
  
    @isTest 
    public static void changeEndedContractTest() {         

        // generate line
        System.runAs(adminUser){
        System.debug('## c test ## : ' + c);
            Invoicing_Line__c iline = AP05_TestDataFactory.createInvoicingLine(c, null);
            iline.Status__c = AP_Constant.INVLINE_STATUS_DRAFT;
            update iline;

            System.assertEquals(AP_Constant.INVLINE_STATUS_DRAFT, iline.Status__c);

            Test.startTest();

            c.PDFStatus_lgt__c = 'Updated';
            c.Status__c = System.Label.ContractStatus_Ended;
            update c;
            c = [SELECT Status__c, Id FROM Contract__c WHERE  id=:vContract.Id][0];
            System.assert(System.Label.ContractStatus_Ended == c.Status__c,c.Status__c);

            //Test.startTest();

            iline.Activity_Type__c = '';  
            update(iline); 

            Test.stopTest();

            iline = [SELECT Id, Status__c, Contract_Status__c FROM Invoicing_Line__c WHERE Contract2__c =: c.Id][0];
            System.assertEquals(iline.Status__c,AP_Constant.INVLINE_STATUS_DRAFT);
        }
    }

    @isTest 
    public static void changeTerminatedContractTest() {         

        // generate line
        System.runAs(vUserPM) { 
            Invoicing_Line__c iline = AP05_TestDataFactory.createInvoicingLine(c, null);
            iline.Status__c = AP_Constant.INVLINE_STATUS_DRAFT;
            update iline;

            System.assertEquals(iline.Status__c,AP_Constant.INVLINE_STATUS_DRAFT);

            Test.startTest();
                c.Status__c = System.Label.ContractStatus_Terminated;
                update c;
                c = [SELECT Status__c, Id FROM Contract__c WHERE  id=:vContract.Id][0];
                System.assert(System.Label.ContractStatus_Terminated == c.Status__c,c.Status__c);

                iline.Activity_Type__c = '';  
                update(iline); 

                iline = [SELECT Id, Status__c, Contract_Status__c FROM Invoicing_Line__c WHERE Contract2__c =: c.Id][0];
                System.assertEquals(iline.Status__c, AP_Constant.INVLINE_STATUS_DRAFT);

            Test.stopTest();        
        }
    }

    
    /**
     * Method fromDraftToCustomerValidation
     */
    @isTest
    public static void toDraft(){
        //Variables declarations
        String Msg = '';     
        System.runAs(vUserPM) { 
            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c 
            FROM Contract__c WHERE  id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            //Link the contract to a pdfContractAttached
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Not updated!';
            insert pdfContractAttached;
            c.PDFContrAtt__c = pdfContractAttached.id;
            update c ;
            //Passing the Contract to Draft
            controller.toDraft();

            Test.stopTest();
        }
    }

    @isTest
    public static void ToInternalValidation(){

          //Variables declarations
        String Msg = ''; 
        System.runAs(vUserPM) {     

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c FROM Contract__c LIMIT 1];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

             //Testing the toInternalValidation command
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            c.PDFContrAtt__c = pdfContractAttached.id;
            update c ;
            controller.toInternalValidation();
            System.assert(AP_Constant.CONTRACT_STATUS_INTERNAL_VALIDATION == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void ToInternalValidationWithError(){

          //Variables declarations
        String Msg = ''; 
        System.runAs(vUserPM) {     

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c FROM Contract__c LIMIT 1];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

             //Testing the toInternalValidation command
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            controller.toInternalValidation();
            System.assert(AP_Constant.CONTRACT_STATUS_INTERNAL_VALIDATION == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void fromInternalValidationToCustomerValidation(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c 
            FROM Contract__c WHERE  id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
          

            //Testing the toValidated command
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            controller.toValidated();
            System.assert(AP_Constant.CONTRACT_STATUS_VALIDATED == c.Status__c,c.Status__c);

            //Testing toCustomerValidation command
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            controller.toCustomerValidation();
            System.assert(AP_Constant.CONTRACT_STATUS_CUSTOMER_VALIDATION == c.Status__c, c.Status__c);

            Test.stopTest();
        }
    }

    /**
     * Method fromDraftToCustomerValidation
     */
    @isTest
    public static void fromCustomerValidationToReadyForSignature(){
        //Variables declarations
        String Msg = '';   

        System.runAs(vUserPM) {   

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            //Link the contract to a pdfContractAttached
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            c.PDFContrAtt__c = pdfContractAttached.id;
            c.PDFStatus_lgt__c  = 'Updated';
            update c ;

            //Testing the toReadyForSignature command
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            controller.toReadyForSignature();
            System.assert(AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE == c.Status__c, c.Status__c);
            System.assert(controller.errorMsg == null, controller.errorMsg);
            System.assertEquals(controller.shouldRedirect, TRUE);
            Test.stopTest();
        }
    }

    @isTest
    public static void fromReadeyForSignatureToSentForSignature(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c, RecordType.DeveloperName
             FROM Contract__c WHERE  id=:vContract.Id][0];

            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            //Link the contract to a pdfContractAttached
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            c.PDFContrAtt__c = pdfContractAttached.id;
            update c ;
            //Testing the toSentForSignature command
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            controller.toSentForSignature();
            System.assert(AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void fromSendToSignatureToSigned(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c,  Account__r.Name, Account__r.Purchase_Order__c 
            FROM Contract__c WHERE  id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            c.PDFContrAtt__c = pdfContractAttached.Id;
            update c; 

            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c
             FROM Contract__c WHERE  id=:vContract.Id][0];

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(ctr_updated));
            controller.toSigned();
            System.assert(AP_Constant.CONTRACT_STATUS_SIGNED == ctr_updated.Status__c, ctr_updated.Status__c);

            Test.stopTest();
        }
    }

    @isTest
    public static void fromSendToSignatureToSignedwithError(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c
             FROM Contract__c WHERE  id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            controller.toSigned();
            System.assert(AP_Constant.CONTRACT_STATUS_SIGNED == c.Status__c, c.Status__c);

            Test.stopTest();
        }
    }

    @isTest
    public static void toRejectedByCustomer(){

        //Variables declarations
        String Msg = '';  

        System.runAs(vUserPM) {    

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c FROM Contract__c LIMIT 1];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

             //Testing the toInternalValidation command
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            controller.toRejectedByCustomer();
            System.assert(AP_Constant.CONTRACT_STATUS_REJECTED_BY_CUSTOMER == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void toCancelled(){

          //Variables declarations
        String Msg = '';    

        System.runAs(vUserPM) {  

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c,/* Invoicing_Parameter__c,*/ Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c,/* Notify_Validation__c,*/ Account__r.Name, Account__r.Purchase_Order__c FROM Contract__c LIMIT 1];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

             //Testing the toInternalValidation command
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            insert pdfContractAttached;
            controller.toCancelled();
            System.assert(AP_Constant.CONTRACT_STATUS_CANCELLED == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void toTerminated(){

          //Variables declarations
        String Msg = '';   

        System.runAs(vUserPM) {   

            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c,/* Notify_Validation__c,*/ Account__r.Name, Account__r.Purchase_Order__c FROM Contract__c LIMIT 1];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

             //Testing the toInternalValidation command
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));
            insert pdfContractAttached;
            controller.toTerminated();
            System.assert(AP_Constant.CONTRACT_STATUS_TERMINATED == c.Status__c, c.Status__c);
            Test.stopTest();
        }
    }

    @isTest
    public static void toDraftException(){
        //Variables declarations
        String Msg = '';     
        System.runAs(vUserPM) { 
            //Test start
            Test.startTest();

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c 
            FROM Contract__c WHERE  id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            //Link the contract to a pdfContractAttached
            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Not updated!';
            insert pdfContractAttached;
            c.PDFContrAtt__c = pdfContractAttached.id;
            update c ;
            //Passing the Contract to Draft
            controller.toDraft();

            Test.stopTest();
        }
    }

    @isTest
    public static void sendtoPeopleSoftInsufficientPriv(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                             EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, 
                             SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, 
                             Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                             FROM Contract__c 
                             WHERE 
                             id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            c.PDFContrAtt__c = pdfContractAttached.Id;
            update c; 

            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                                       EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, /*Invoicing_Parameter__c, */Language__c, 
                                       Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, 
                                       RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                                       FROM Contract__c 
                                       WHERE 
                                       id=:vContract.Id][0];

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(ctr_updated));
            controller.sendToPeopleSoft();
            System.assertEquals('You do not have sufficient rights to send ILs to PeopleSoft', Controller.errorMsg);

            Test.stopTest();
        }
    }

    @isTest
    public static void sendtoPeopleSoftCtrExists(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPM) { 

            //Test start
            Test.startTest();

            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                             EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c,/* Invoicing_Parameter__c,*/ Language__c, Account__r.MSA__c, 
                             SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, 
                             Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                             FROM Contract__c 
                             WHERE 
                             id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            c.PDFContrAtt__c = pdfContractAttached.Id;
            c.Peoplesoft_Sync__c = true;
            update c; 

            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                                       EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, 
                                       Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, 
                                       RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                                       FROM Contract__c 
                                       WHERE 
                                       id=:vContract.Id][0];

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(ctr_updated));
            controller.sendToPeopleSoft();
            System.assertEquals('This contract has already been sent to PeopleSoft.', Controller.errorMsg);

            Test.stopTest();
        }
    }

    @isTest
    public static void sendtoPeopleSoftPMOADV(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPMOADV) { 

            //Test start
            Test.startTest();

            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                             EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, 
                             SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, 
                             Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c, Customer_Operational_Contact__c
                             FROM Contract__c 
                             WHERE 
                             id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            c.PDFContrAtt__c = pdfContractAttached.Id;
            update c; 

            lstPIL.add(AP05_TestDataFactory.createIL(c, 50,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), null));
            lstPIL.add(AP05_TestDataFactory.createIL(c, 50,'Description 2', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), null));

            insert lstPIL;

            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                                       EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, 
                                       Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, 
                                       RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                                       FROM Contract__c 
                                       WHERE 
                                       id=:vContract.Id][0];

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(ctr_updated));
            controller.sendToPeopleSoft();
            System.assertEquals(null, Controller.errorMsg);

            Test.stopTest();
        }
    }

    @isTest
    public static void sendtoPeopleSoftPMOADV02(){
        //Variables declarations
        String Msg = '';     

        System.runAs(vUserPMOADV) { 

            //Test start
            Test.startTest();

            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;

            //Getting back the Contract and attached it to the controller
            Contract__c c = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                             EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, 
                             SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, 
                             Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c, Customer_Operational_Contact__c
                             FROM Contract__c 
                             WHERE 
                             id=:vContract.Id][0];
            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

            c.PDFContrAtt__c = pdfContractAttached.Id;
            update c; 

            delete vInvoicingLine;

            /*lstPIL.add(AP05_TestDataFactory.createIL(c, 50,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), null));
            lstPIL.add(AP05_TestDataFactory.createIL(c, 50,'Description 2', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), null));

            insert lstPIL;*/

            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
                                       EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, 
                                       Account__r.MSA__c, SOW_Operational__c, Service_Type__c, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, 
                                       RecordTypeId, Amendment_to__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
                                       FROM Contract__c 
                                       WHERE 
                                       id=:vContract.Id][0];

            //Testing the toSigned
            controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(ctr_updated));
            controller.sendToPeopleSoft();
            System.assertEquals('At least one Draft Invoicing Line is required to complete this action', Controller.errorMsg);

            Test.stopTest();
        }
    }
    
    @isTest
    public static void DummyTest(){
        System.runAs(vUserPMOADV) { 
            Test.startTest();
            
                VFC07_ContractDetailDashboard.DummyTest();
            Test.stopTest();
        }
    }
}