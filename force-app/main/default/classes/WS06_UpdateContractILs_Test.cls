@isTest
private class WS06_UpdateContractILs_Test {

    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static User adminUser;

	static WS06_UpdateContractILs.wrapperResult result;
    static List<contract__c> lstCtr; 
    static Planned_Invoicing_Line__c pil;
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

            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer, */vUserOO);

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

			lstCtr = new List<contract__c>();
			for(integer i=0; i<5; i++){
            	lstCtr.add(AP05_TestDataFactory.createContract2('AXA GS France', vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false));
			}
			insert lstCtr;

            lstIL.add(new Planned_Invoicing_Line__c(
                                                Type__c = 'Invoicing Line',
                                                Status__c = '02',
                                                TECH_SynchroSAP__c = false,
                                                N_Purchase_Order__c = 'abc',
                                                contract2__c = lstCtr[0].id,
                                                RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                            ));
            lstIL.add(new Planned_Invoicing_Line__c(
                                                Type__c = 'Invoicing Line',
                                                Status__c = '01',
                                                TECH_SynchroSAP__c = false,
                                                N_Purchase_Order__c = 'abc',
                                                contract2__c = lstCtr[0].id,
                                                RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                            ));
            lstIL.add(new Planned_Invoicing_Line__c(
                                                Type__c = 'Invoicing Line',
                                                Status__c = '01',
                                                TECH_SynchroSAP__c = false,
                                                N_Purchase_Order__c = 'abc',
                                                contract2__c = lstCtr[1].id,
                                                RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                            ));
			lstIL.add(new Planned_Invoicing_Line__c(
                                                Type__c = 'Invoicing Line',
                                                Status__c = '01',
                                                TECH_SynchroSAP__c = false,
                                                N_Purchase_Order__c = 'abc',
                                                contract2__c = lstCtr[2].id,
                                                RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                            ));

            insert lstIL;

            lstIL = [Select Id,AXA_GS_Legal_Entity__c,Tech_AXA_GS_Legal_Entity__c,SAP_Account_Number__c,N_Purchase_Order__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Contract2__c,
                    Material_SAPEXP__c,Man_days__c,Activity_Type__c,Header_Text__c,SAP_ID__c,RecordTypeId,
                    TECH_SynchroSAP__c, Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,Service_Type__c,Contract_Start_Date__c,
                	Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c
					From Planned_Invoicing_Line__c
					Where Id IN :lstIL];

			result = new WS06_UpdateContractILs.wrapperResult();
			result.ET_DOCS = new WS06_UpdateContractILs.ET_DOCS();
			result.ET_DOCS.item = new list <WS06_UpdateContractILs.item3>();
			result.ET_LOG = new WS06_UpdateContractILs.ET_LOG();
			result.ET_LOG.item = new list <WS06_UpdateContractILs.item4>(); 
			WS06_UpdateContractILs.item4 item4_a0 = new WS06_UpdateContractILs.item4();
			WS06_UpdateContractILs.item4 item4_a1 = new WS06_UpdateContractILs.item4();
			WS06_UpdateContractILs.item3 item3_a0 = new WS06_UpdateContractILs.item3();
			WS06_UpdateContractILs.item3 item3_a1 = new WS06_UpdateContractILs.item3();
			
			// Success
			item4_a0.CONTRACT_ID = lstCtr[0].Id;
			item4_a0.INVOICING_LINE_ID = lstIL[0].Id;
			item4_a0.SEQ = 1;
			item4_a0.MSGTYPE = 'S';
			item4_a0.ERROR_MESSAGE = 'Success';
			result.ET_LOG.item.add(item4_a0);

			item3_a0.CONTRACT_ID = lstCtr[0].Id;
			item3_a0.INVOICING_LINE_ID = lstIL[0].Id;
			item3_a0.SALES_ORDER_NUMBER = 'SO123';
			item3_a0.SALES_ORDER_ITEM = '1';
			result.ET_DOCS.item.add(item3_a0);
			
			item4_a1.CONTRACT_ID = lstCtr[0].Id;
			item4_a1.INVOICING_LINE_ID = lstIL[1].Id;
			item4_a1.SEQ = 1;
			item4_a1.MSGTYPE = 'S';
			item4_a1.ERROR_MESSAGE = 'Success';
			result.ET_LOG.item.add(item4_a1);

			item3_a1.CONTRACT_ID = lstCtr[0].Id;
			item3_a1.INVOICING_LINE_ID = lstIL[1].Id;
			item3_a1.SALES_ORDER_NUMBER = 'SO123';
			item3_a1.SALES_ORDER_ITEM = '1';
			result.ET_DOCS.item.add(item3_a1);

			// Error
			WS06_UpdateContractILs.item4 item4_b0 = new WS06_UpdateContractILs.item4();
			WS06_UpdateContractILs.item3 item3_b0 = new WS06_UpdateContractILs.item3();
			item4_b0.CONTRACT_ID = lstCtr[1].Id;
			item4_b0.INVOICING_LINE_ID = lstIL[2].Id;
			item4_b0.SEQ = 1;
			item4_b0.MSGTYPE = 'E';
			item4_b0.ERROR_MESSAGE = 'Error';
			result.ET_LOG.item.add(item4_b0);

			item3_b0.CONTRACT_ID = lstCtr[1].Id;
			item3_b0.INVOICING_LINE_ID = lstIL[2].Id;
			item3_b0.SALES_ORDER_NUMBER = 'SO123';
			item3_b0.SALES_ORDER_ITEM = '1';
			result.ET_DOCS.item.add(item3_b0);

			// Error blank IL Id
			WS06_UpdateContractILs.item4 item4_c0 = new WS06_UpdateContractILs.item4();
			WS06_UpdateContractILs.item3 item3_c0 = new WS06_UpdateContractILs.item3();
			item4_c0.CONTRACT_ID = lstCtr[2].Id;
			item4_c0.INVOICING_LINE_ID = '';
			item4_c0.SEQ = 1;
			item4_c0.MSGTYPE = 'E';
			item4_c0.ERROR_MESSAGE = 'Error';
			result.ET_LOG.item.add(item4_c0);

			item3_c0.CONTRACT_ID = lstCtr[2].Id;
			item3_c0.INVOICING_LINE_ID = '';
			item3_c0.SALES_ORDER_NUMBER = 'SO123';
			item3_c0.SALES_ORDER_ITEM = '1';
			result.ET_DOCS.item.add(item3_c0);
        }
    }
   
    @isTest 
    static void WS02_SAPInvoiceLineSuccessTEST() {
        system.runAs(adminUser){
        test.starttest();
            List<WS06_UpdateContractILs.WrapperResponse> lstWR = WS06_UpdateContractILs.updateContractILs(result);
			lstIL = [SELECT Id, Status__c, Tech_UpdatedByPS__c FROM Planned_Invoicing_Line__c WHERE Id IN :lstIL];
			system.assertEquals('02', lstIL[1].Status__c);
        test.stoptest();
        }
    }
}