@isTest(SeeAllData=true)
private class WS02_CallRestESG_TEST {
    static User adminUser;
    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static List<Account> vLegalEntity1 = new List<Account>();
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static Contract__c testContract;
    static Planned_Invoicing_Line__c pil;
    static List<Planned_Invoicing_Line__c> lstIL = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstPILs = new List<Planned_Invoicing_Line__c>();
    static MaaMAuthToken__c maamTokenTest;
   
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
            User vUserPM = AP05_TestDataFactory.createPMUser(true);

            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = adminUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            //Create Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer, */vUserOO);

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

            //Create Contract
            testContract = AP05_TestDataFactory.createContract2('AXA GS France', vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', true);

            //Create List of Planned Invoicing Lines
            lstIL.add(AP05_TestDataFactory.createIL(testContract, 50,'Description 1', '02', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));
            lstIL.add(AP05_TestDataFactory.createIL(testContract, 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id));

            insert lstIL;
  
            //Query fields of lstPILS
            pil = [ SELECT Id,Contract2__c,SAP_Synchronisation_Error__c,Connexion_Error__c, Customer_contact_name__c,
                    SAP_Account_Number__c,N_Purchase_Order__c,PurchaseOrder__r.PO_Client__c,/*Customer_contact__c,
                    Customer_contact__r.Name,*/Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Service_Type__c,
                    Contract_Start_Date__c,Contract_End_Date__c,Material_SAPEXP__c,Man_days__c,Activity_Type__c,
                    Activity_Description__c,ViewCurrency__c,Master_WBS_Structure__c,Master_WBS_Structure__r.Name,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,ADV_GoNoGo__c,
                    Status__c,isInPS__c,RecordTypeId,SO__c,ITEM__c,TECH_SynchroSAP__c,Header_Text__c,Header_Text_2_SAPEXP__c,
                    Header_Text_3_SAPEXP__c,Header_Text_4_SAPEXP__c, Contract2__r.TECH_PS_SalesOrganization__c, AmountIL__c, Tech_UpdatedByPS__c,
                    Inv_Predefined_Date__c , Contract2__r.Peoplesoft_Sync__c,
                    Contract2__r.name, Contract2__r.ContractNumber__c,Contract2__r.Status__c,Contract2__r.Tech_MSARef__c, Contract2__r.Tech_isSendingToPS__c, StartDate__c, EndDate__c
                    FROM Planned_Invoicing_Line__c 
                    WHERE Id =:lstIL[0].id];

            //Create maam token
            maamTokenTest = new MaaMAuthToken__c(Access_token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkFUMjAxODA0MjMifQ.eyJhdWQiOiJzYWxlc2ZvcmNlX3Blb3BsZXNvZnQiLCJybG0iOiJjbGllbnQiLCJjZWkiOiIxMThhNjdlZSIsInNjb3BlIjoidXJuOmF4YTpmcmFuY2U6c2FsZXNmb3JjZSIsImlzcyI6Imh0dHBzOlwvXC9tYWFtLWRldi5heGEuY29tXC9tYWFtXC92MiIsImV4cCI6MTYzNTQxNzkxNSwiaWF0IjoxNjM1NDE0MzE1LCJqdGkiOiJmYzYzNjU3MC0xYTc5LTQwZjctODIyYy05YTk4YmFlNjAyNDIiLCJjbGllbnRfaWQiOiIxOWQ1MDY5ZiJ9.dS9KiS8oxGpWMjHYtHJVbtMhP4jdfrZJuIBrxMkAodOWBV7Mvlf2xR0l0ZZ_fzaAN8Q813BgzWwEQbib6r1TrVK60UfGqup_yIlA_Lp09agtUi7DRK344aVPW85ZSbTs6qqSFC0e2tB6et7L8xMsRiDfki75e-aZCt_bDFoHL8lB3TlCeE8kcYfJtJJmCsnKUcJK-pIDuphVRWRCqeHPFJcrCRzVZNaj7qsycXSM_O1sX_8jyKaxVmgcuvPuueWUU64zkWqZcUFTNjzk-D8Sbcghd6Jh1lIkWNgdKdzB_n6WiPvzNC7TWdn2t-Nbfav2GRcAclL3LPElLTP0YcpfbQ',
            Token__c = 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&scope=urn:axa:france:salesforce&grant_type=client_credentials&client_id=19d5069f&client_assertion=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxOWQ1MDY5ZiIsInN1YiI6IjE5ZDUwNjlmIiwiYXVkIjoiaHR0cHM6Ly9tYWFtLWRldi5heGEuY29tL21hYW0vdjIvdG9rZW4iLCJqdGkiOiJNanl1Q2U0MUc0U2ltTGwwIiwiZXhwIjoxNjM1NDIwMzE2fQ.NuqU87mReer4M6yjhJbeAgQF6o516ewitCPILkvWsFM');
            insert maamTokenTest;
        }
    }

    @isTest(SeeAllData=true)
    static void WS02_CallRestESGTestMethod(){
        Test.setMock(HttpCalloutMock.class, new WS02_CallRestESGMock(200));
        Map<id, List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo = new Map<id, List<Planned_Invoicing_Line__c>>();
        lstPILs.add(pil);
        mapInvoiceLineInfo.put(pil.contract2__c, lstPILs);
        Test.startTest();
        system.runAs(adminUser){      
            WS02_CallRestESG callRestESG = new WS02_CallRestESG(mapInvoiceLineInfo);    
            callRestESG.getErroMessage();
            callRestESG.getErrorLog();
        }
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    static void WS02_CallRestESGTestBadRequest(){
        Test.setMock(HttpCalloutMock.class, new WS02_CallRestESGMock(400));
        Map<id, List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo = new Map<id, List<Planned_Invoicing_Line__c>>();
        lstPILs.add(pil);
        mapInvoiceLineInfo.put(pil.contract2__c, lstPILs);
        Test.startTest();
        system.runAs(adminUser){      
            WS02_CallRestESG callRestESG = new WS02_CallRestESG(mapInvoiceLineInfo);    
            callRestESG.getErroMessage();
            callRestESG.getErrorLog();
        }
        Test.stopTest();
    }
}