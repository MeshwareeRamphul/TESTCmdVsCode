@isTest
private class WS06_UpdateInvoicingLine_TEST {

    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static User adminUser;

    static WS06_UpdateInvoicingLine.RequestWrapper request;
    static List<Contract__c> lstCon = new List<Contract__c>();
    static Planned_Invoicing_Line__c pil;
    static List<Planned_Invoicing_Line__c> lstIL = new List<Planned_Invoicing_Line__c>();

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
        insert adminUser;

        System.runAs(adminUser){

            //Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();

            //Create PM user
            vUserPM = AP05_TestDataFactory.createPMUser(true);

            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = adminUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            //Create Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            AccountModification_Flag__c accModifFlag = new AccountModification_Flag__c(SetupOwnerId=vUserPM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
            insert accModifFlag;

            vUserPM1 = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];

            //Get the offer
            vProduct1 = [SELECT Id, OwnerId, name FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];

            //Create the customer (aka entity) account
            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(vUserPM1, AP05_TestDataFactory.ACCOUNT_NAME);

            //Create the entity account
            vEntity1 = AP05_TestDataFactory.createEntityAccount(vUserPM1, 'testEntity');

            //Create the master entity account
            vMEntity1 = AP05_TestDataFactory.createMasterEntityAccount(vUserPM1, 'Master Entity');

            //Get the legal entity
            //vLegalEntity1 = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];

            //Create the entity contact related to the account
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLEntity1);

            //Create List of Contracts
            for(Integer i=0; i < 4; i++){
                lstCon.add(AP05_TestDataFactory.createContract2('AXA GS France', vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false));
            }
            insert lstCon;

            //Create List of PILS
            lstIL.add(AP05_TestDataFactory.createIL(lstCon[0], 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(lstCon[1], 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(lstCon[2], 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(lstCon[2], 50,'Description 1', '01', System.Today().addMonths(4), System.Today().addMonths(8), vEntityContact1.Id));

            insert lstIL;

            //Query fields of ILs
            lstIL = [SELECT Id, AXA_GS_Legal_Entity__c, Tech_AXA_GS_Legal_Entity__c, SAP_Account_Number__c, N_Purchase_Order__c, Bill_form_SAPEXP__c, Customer_Operational_Contact__c, Solution__c, Contract2__c,
            Material_SAPEXP__c, Man_days__c, Activity_Type__c, Header_Text__c, SAP_ID__c, RecordTypeId,
            TECH_SynchroSAP__c, Activity_Description__c, ViewCurrency__c, WBS_Element_SAPEXP__c, Rate__c,Invoicing_Date__c, Service_Type__c, Contract_Start_Date__c,
            Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c FROM Planned_Invoicing_Line__c WHERE Id IN:lstIL];
            
            //Create new wrapper object
            request = new WS06_UpdateInvoicingLine.RequestWrapper();
            //Create ET_DOCS object
            request.ET_DOCS = new WS06_UpdateInvoicingLine.ET_DOCS();
			request.ET_DOCS.item = new List<WS06_UpdateInvoicingLine.item3>();
            //Create ET_LOG object
			request.ET_LOG = new WS06_UpdateInvoicingLine.ET_LOG();
			request.ET_LOG.item = new List<WS06_UpdateInvoicingLine.item4>(); 
			WS06_UpdateInvoicingLine.item4 item4_a0 = new WS06_UpdateInvoicingLine.item4();
			WS06_UpdateInvoicingLine.item4 item4_a1 = new WS06_UpdateInvoicingLine.item4();
			WS06_UpdateInvoicingLine.item3 item3_a0 = new WS06_UpdateInvoicingLine.item3();
			WS06_UpdateInvoicingLine.item3 item3_a1 = new WS06_UpdateInvoicingLine.item3();

            //If in Success
            item4_a0.CONTRACT_ID = (lstCon[0].Id+'').substring(0,15);
			item4_a0.INVOICING_LINE_ID = lstIL[0].Id;
			item4_a0.MSGTYPE  = 'S';
			item4_a0.ERROR_MESSAGE = AP_Constant.PS_SUCCESS;
			request.ET_LOG.item.add(item4_a0);

			item3_a0.CONTRACT_ID = (lstCon[0].Id+'').substring(0,15);
			item3_a0.INVOICING_LINE_ID = lstIL[0].Id;
			item3_a0.SALES_ORDER_NUMBER = 'SO123';
			item3_a0.SALES_ORDER_ITEM = '1';
			request.ET_DOCS.item.add(item3_a0);
			
			item4_a1.CONTRACT_ID = (lstCon[0].Id+'').substring(0,15);
			item4_a1.INVOICING_LINE_ID = lstIL[1].Id;
			item4_a1.MSGTYPE  = 'S';
			item4_a1.ERROR_MESSAGE = AP_Constant.PS_SUCCESS;
			request.ET_LOG.item.add(item4_a1);

			item3_a1.CONTRACT_ID = (lstCon[0].Id+'').substring(0,15);
			item3_a1.INVOICING_LINE_ID = lstIL[1].Id;
			item3_a1.SALES_ORDER_NUMBER = 'SO123';
			item3_a1.SALES_ORDER_ITEM = '1';
			request.ET_DOCS.item.add(item3_a1);

            //If in Error
            WS06_UpdateInvoicingLine.item4 item4_b0 = new WS06_UpdateInvoicingLine.item4();
			WS06_UpdateInvoicingLine.item3 item3_b0 = new WS06_UpdateInvoicingLine.item3();
			item4_b0.CONTRACT_ID = (lstCon[1].Id+'').substring(0,15);
			item4_b0.INVOICING_LINE_ID = lstIL[2].Id;
			item4_b0.MSGTYPE  = 'E';
			item4_b0.ERROR_MESSAGE = 'Error';
			request.ET_LOG.item.add(item4_b0);

			item3_b0.CONTRACT_ID = (lstCon[1].Id+'').substring(0,15);
			item3_b0.INVOICING_LINE_ID = lstIL[2].Id;
			item3_b0.SALES_ORDER_NUMBER = 'SO123';
			item3_b0.SALES_ORDER_ITEM = '1';
			request.ET_DOCS.item.add(item3_b0);

            //If in error blank IL
			WS06_UpdateInvoicingLine.item4 item4_c0 = new WS06_UpdateInvoicingLine.item4();
			WS06_UpdateInvoicingLine.item3 item3_c0 = new WS06_UpdateInvoicingLine.item3();
            WS06_UpdateInvoicingLine.item4 item4_d0 = new WS06_UpdateInvoicingLine.item4();
			WS06_UpdateInvoicingLine.item3 item3_d0 = new WS06_UpdateInvoicingLine.item3();

			item4_c0.CONTRACT_ID = (lstCon[2].Id+'').substring(0,15);
			item4_c0.INVOICING_LINE_ID = '';
			item4_c0.MSGTYPE  = 'E';
			item4_c0.ERROR_MESSAGE = 'Error';
			request.ET_LOG.item.add(item4_c0);

			item3_c0.CONTRACT_ID = (lstCon[2].Id+'').substring(0,15);
			item3_c0.INVOICING_LINE_ID = '';
			item3_c0.SALES_ORDER_NUMBER = 'SO123';
			item3_c0.SALES_ORDER_ITEM = '1';
			request.ET_DOCS.item.add(item3_c0);

            item4_d0.CONTRACT_ID = (lstCon[2].Id+'').substring(0,15);
			item4_d0.INVOICING_LINE_ID = '';
			item4_d0.MSGTYPE  = 'E';
			item4_d0.ERROR_MESSAGE = 'Error';
			request.ET_LOG.item.add(item4_d0);
            
			item3_d0.CONTRACT_ID = (lstCon[2].Id+'').substring(0,15);
			item3_d0.INVOICING_LINE_ID = '';
			item3_d0.SALES_ORDER_NUMBER = 'SO123';
			item3_d0.SALES_ORDER_ITEM = '1';
			request.ET_DOCS.item.add(item3_d0);
        }
    }

    @isTest
    static void WS06_UpdateInvoicingLineTestMethod(){
        system.runAs(adminUser){
            Test.startTest();
                List<WS06_UpdateInvoicingLine.WrapperResponse> lstWR = WS06_UpdateInvoicingLine.doPost(request);
            Test.stopTest();
        }
    }
}