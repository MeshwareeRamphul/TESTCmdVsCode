@isTest
private class AP54_MassSendToPeopleSoft_Test {

    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static User adminUser;
    static Set<Id> setContractId;

    static contract__c ctr;
    static Planned_Invoicing_Line__c pil;
    static Planned_Invoicing_Line__c pil00;
    static Planned_Invoicing_Line__c pil01;
    static List<Planned_Invoicing_Line__c> lstIL = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstPILs = new List<Planned_Invoicing_Line__c>();

    static{
        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName();
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        //adminUser.PAD_BypassValidationRules__c = true;
        //adminUser.PAD_BypassTrigger__c = 'AP25a'; //'AP12;AP112;AP120';

        insert adminUser;

        System.runAs(adminUser) {

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();

            // Create PM user
            vUserPM = AP05_TestDataFactory.createPMUser(true);
            
            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = adminUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            AccountModification_Flag__c accModifFlag = new AccountModification_Flag__c(SetupOwnerId=vUserPM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
            insert accModifFlag;

            vUserPM1 = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];

            // Get the offer
            vProduct1 = [SELECT Id, OwnerId, name FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];

            // Create the customer (aka entity) account
            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(vUserPM1, AP05_TestDataFactory.ACCOUNT_NAME);

            // Create the entity account
            vEntity1 = AP05_TestDataFactory.createEntityAccount(vUserPM1, 'testEntity');

            // Create the master entity account
            vMEntity1 = AP05_TestDataFactory.createMasterEntityAccount(vUserPM1, 'Master Entity');

            // Get the legal entity
            vLegalEntity1 = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];

            // Create the entity contact related to the account
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLegalEntity1);

            ctr = AP05_TestDataFactory.createContract2('AXA GS France', vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', true);
            setContractId = new Set<Id>{ctr.Id};
            
            lstIL.add(AP05_TestDataFactory.createIL(ctr, 100,'Description 1', '02', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(ctr, 100,'Description 1', '02', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(ctr, 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL[0].N_Purchase_Order__c = 'abc';
            lstIL[2].N_Purchase_Order__c = 'abc';
            insert lstIL;

            pil = [SELECT Id,AXA_GS_Legal_Entity__c,Tech_AXA_GS_Legal_Entity__c,SAP_Account_Number__c,N_Purchase_Order__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Contract2__c,
                    Material_SAPEXP__c,Man_days__c,Activity_Type__c,Header_Text__c,SAP_ID__c,RecordTypeId,Customer_contact_name__c,
                    TECH_SynchroSAP__c, Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,Service_Type__c,Contract_Start_Date__c,
                    Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c
                    FROM Planned_Invoicing_Line__c
                    WHERE Id = :lstIL[0].id];

            pil00 = [SELECT Id,AXA_GS_Legal_Entity__c,Tech_AXA_GS_Legal_Entity__c,SAP_Account_Number__c,N_Purchase_Order__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Contract2__c,
                    Material_SAPEXP__c,Man_days__c,Activity_Type__c,Header_Text__c,SAP_ID__c,RecordTypeId,Customer_contact_name__c,
                    TECH_SynchroSAP__c, Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,Service_Type__c,Contract_Start_Date__c,
                    Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c
                    FROM Planned_Invoicing_Line__c
                    WHERE Id = :lstIL[1].id];
        }
    }
   
    @isTest 
    static void WS02_SAPInvoiceLineSuccessTEST() {
        Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('S', pil.Id, ctr.Id));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

    @isTest 
    static void WS02_SAPInvoiceLineNoPOTEST() {
        Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('S', pil00.Id, ctr.Id));
        /*system.runAs(adminUser){
            pil.N_Purchase_Order__c = '';
            update pil;
        }*/
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

    @isTest 
    static void WS02_SAP_TEST() {
        Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('E_ID', pil.id, pil.contract2__c));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

    @isTest 
    static void WS02_SAPInvoiceLineErrorNO_ILTEST() {
        Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('E_NO_IL', pil.Id, ctr.Id));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

    @isTest 
    static void WS02_SAPInvoiceLineErrorNO_ILTEST_Status_01() {
        system.runAs(adminUser){
            Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('E_ID', pil.id, ctr.id));
            test.starttest();
                AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
            test.stoptest();
        }
    }

    @isTest 
    static void WS02_SAPInvoiceLineErrorExpTEST() {
        Test.setMock(WebServiceMock.class, new AP54_MassSendToPeopleSoftMock('EXP', pil.Id, ctr.Id));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }
    
    @isTest 
    static void WS02_SAPInvoiceLineErrorSuccess_ETDocTEST() { 
        Test.setMock(WebServiceMock.class, new WS02_CallSAPWSMock('S_DOC', pil.Id, ctr.Id));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

    @isTest 
    static void WS02_SAPInvoiceLineErrorILTEST() {
        Test.setMock(WebServiceMock.class, new WS02_CallSAPWSMock('E_IL', pil.Id, ctr.Id));
        test.starttest();
        system.runAs(adminUser){
            AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
        }
        test.stoptest();
    }

   /* @isTest 
    static void SendToEmailTEST() {
        test.starttest();
        system.runAs(adminUser){
            AP00_CSVParser resultMail = new AP00_CSVParser();
            if(!resultMail.hasHeader) resultMail.writeHeader(new list<String>{'Contract Number', 'Contract Name', 'PS LOG', 'Status', 'Error message'});
            resultMail.addToLine('contractNumber');
            resultMail.addToLine('contractName');
            resultMail.addToLine('logName');
            resultMail.addToLine('typeError');
            resultMail.addToLine('error');
            resultMail.createLine();
            AP54_MassSendToPeopleSoft.sendMailResult('test', resultMail, userinfo.getUserEmail());
        }
        test.stoptest();
    }*/
}