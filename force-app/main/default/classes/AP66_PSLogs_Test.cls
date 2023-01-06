@isTest
public class AP66_PSLogs_Test {

    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static User adminUser;

    static WS06_UpdateInvoicingLine.RequestWrapper request;
    static WS06_UpdateInvoicingLine.RequestWrapper request2;
    static List<Contract__c> lstCon = new List<Contract__c>();
    static Planned_Invoicing_Line__c pil;
    static List<Planned_Invoicing_Line__c> lstIL = new List<Planned_Invoicing_Line__c>();
    static List<Log__c> lstLog = new List<Log__c>();

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
            lstIL.add(AP05_TestDataFactory.createIL(lstCon[3], 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            
            insert lstIL;

            //Query fields of ILs
            lstIL = [SELECT Id, AXA_GS_Legal_Entity__c, Tech_AXA_GS_Legal_Entity__c, SAP_Account_Number__c, N_Purchase_Order__c, Bill_form_SAPEXP__c, Customer_Operational_Contact__c, Solution__c, Contract2__c,
            Material_SAPEXP__c, Man_days__c, Activity_Type__c, Header_Text__c, SAP_ID__c, RecordTypeId,
            TECH_SynchroSAP__c, Activity_Description__c, ViewCurrency__c, WBS_Element_SAPEXP__c, Rate__c,Invoicing_Date__c, Service_Type__c, Contract_Start_Date__c,
            Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c FROM Planned_Invoicing_Line__c WHERE Id IN:lstIL];
            
            lstLog.add(new log__c(
                Call_Status__c      = 'S', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = AP_Constant.PS_SUCCESS, 
                Contract__c         = lstCon[0].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG'
            ));
            lstLog.add(new log__c(
                Call_Status__c      = 'E', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = 'Flow2 - Error 1', 
                Contract__c         = lstCon[0].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG',
                LastPSLog__c = true
            ));
            lstLog.add(new log__c(
                Call_Status__c      = 'S', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = AP_Constant.PS_SUCCESS, 
                Contract__c         = lstCon[1].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG'
            ));
            lstLog.add(new log__c(
                Call_Status__c      = 'E', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = 'Error fatal', 
                Contract__c         = lstCon[1].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG',
                LastPSLog__c = true
            ));
            lstLog.add(new log__c(
                Call_Status__c      = 'S', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = AP_Constant.PS_SUCCESS, 
                Contract__c         = lstCon[2].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG',
                LastPSLog__c = true
            ));
            lstLog.add(new log__c(
                Call_Status__c      = 'E', 
                Date_of_log__c      = System.now(), 
                Source__c           = AP_Constant.PS_FLOW_2,
                Error_Message__c    = 'Error fatal', 
                Contract__c         = lstCon[3].Id, 
                Response_ET_DOC__c  = 'Response_ET_DOC', 
                Response_ET_LOG__c  = 'Response_ET_LOG',
                LastPSLog__c = true
            ));
            insert lstLog;
        }
    }

    @isTest
    static void insertNewPSLog(){
        system.runAs(adminUser){
            Test.startTest();
                List<Log__c> lstLog = [SELECT Id, LastPSLog__c FROM Log__c WHERE Contract__c IN :lstCon AND LastPSLog__c = true];

                lstLog = new List<Log__c>();

                lstLog.add(new log__c(
                    Call_Status__c      = 'E', 
                    Date_of_log__c      = System.now(), 
                    Source__c           = AP_Constant.PS_FLOW_2,
                    Error_Message__c    = 'Error fatal', 
                    Contract__c         = lstCon[0].Id, 
                    Response_ET_DOC__c  = 'Response_ET_DOC', 
                    Response_ET_LOG__c  = 'Response_ET_LOG',
                    LastPSLog__c = true
                ));
                lstLog.add(new log__c(
                    Call_Status__c      = 'E', 
                    Date_of_log__c      = System.now(), 
                    Source__c           = AP_Constant.PS_FLOW_2,
                    Error_Message__c    = 'Error fatal', 
                    Contract__c         = lstCon[1].Id, 
                    Response_ET_DOC__c  = 'Response_ET_DOC', 
                    Response_ET_LOG__c  = 'Response_ET_LOG',
                    LastPSLog__c = true
                ));
                lstLog.add(new log__c(
                    Call_Status__c      = 'S', 
                    Date_of_log__c      = System.now(), 
                    Source__c           = AP_Constant.PS_FLOW_2,
                    Error_Message__c    = AP_Constant.PS_SUCCESS, 
                    Contract__c         = lstCon[2].Id, 
                    Response_ET_DOC__c  = 'Response_ET_DOC', 
                    Response_ET_LOG__c  = 'Response_ET_LOG',
                    LastPSLog__c = true
                ));
                lstLog.add(new log__c(
                    Call_Status__c      = 'E', 
                    Date_of_log__c      = System.now(), 
                    Source__c           = AP_Constant.PS_FLOW_2,
                    Error_Message__c    = 'Error fatal', 
                    Contract__c         = lstCon[3].Id, 
                    Response_ET_DOC__c  = 'Response_ET_DOC', 
                    Response_ET_LOG__c  = 'Response_ET_LOG',
                    LastPSLog__c = true
                ));
                insert lstLog;
            	
                System.assertEquals(4, lstLog.size());
            Test.stopTest();
        }
    }
}