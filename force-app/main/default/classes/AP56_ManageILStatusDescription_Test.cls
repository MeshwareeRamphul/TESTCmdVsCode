@isTest
public class AP56_ManageILStatusDescription_Test {
    
	static PDFContractAttached__c pdfContractAttached;
    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static ProductItem__c vPItem1;
    static ProductItem__c vPItem2;
    static ProductItem__c vPItem3;
    static ProductItem__c vPItem4;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static Account vEAccount;
    static Product__c vProduct;
    static List<Opportunity> lstOpp;
    static List<Contract__c> lstContract;
    static List<ProductItem__c> lstPItems;
    static Planned_Invoicing_Line__c vPlannedInvLine;
    static Planned_Invoicing_Line__c vPInvLine0;
    static Planned_Invoicing_Line__c vPInvLine1;
    static Planned_Invoicing_Line__c vPInvLine2;
    static Planned_Invoicing_Line__c vPInvLine3;
    static Planned_Invoicing_Line__c vPInvLine4;
    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
    static Map<Id, String> mapOppStatus;
    static Map<Id, Contract__c> mapContracts;
    static Opportunity vOpp1;
    static Opportunity vOpp2;
    static Opportunity vOpp3;
    static Contract__c vContract;
    static Contract__c vContract1;
    static Contract__c vContract2;
    static Master_WBS_Structure__c vMasterWBS;
    static Master_WBS_Structure__c vMasterWBS_1;
    static Master_WBS_Structure__c vMasterWBS_2;
    static User adminUser;

    static{
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
        insert adminUser;
        
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        update vUserPM;

        System.runAs(adminUser) {

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
            
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            AccountModification_Flag__c accModifFlag = new AccountModification_Flag__c(SetupOwnerId=vUserPM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
            insert accModifFlag;

            vUserPM1 = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];

            // Get the offer
            vProduct1 = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];

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
            
            //Create an attached file
            pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            
            // Create contracts
            lstContract = new List<Contract__c>();
            vContract1 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract1.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            vContract1.Global_Amount__c = 500;
            vContract1.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract1);
            
            vContract2 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract2.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            vContract2.Global_Amount__c = 500;
            vContract2.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract2);          
            
            insert lstContract;
            
            vPInvLine0 = AP05_TestDataFactory.createIL(lstContract[0], 250,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine1 = AP05_TestDataFactory.createIL(lstContract[0], 250,'Description 2', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine2 = AP05_TestDataFactory.createIL(lstContract[1], 500,'Description 3', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact1.Id);

            lstPIL.add(vPInvLine0);
            lstPIL.add(vPInvLine1);
            lstPIL.add(vPInvLine2);
            insert lstPIL;
            
            
			//Create Product Item
			lstPItems = new List<ProductItem__c>();
            vPItem1 = AP05_TestDataFactory.createCtrProdItems(lstContract[0], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem1);
            vPItem2 = AP05_TestDataFactory.createCtrProdItems(lstContract[1], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem2);
            insert lstPItems;
        }
    }
    
    @isTest
    public static void notSigned_NoPoOnIL_LIUncheckedPO(){
        System.runAs(adminUser) {
            vContract1 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[0].Id];

            Test.startTest();
            	Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract1.Local_information__c];
                localInfo.Purchase_Order__c = true;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes 'PO missing'
            vPInvLine0 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id];
            System.assertEquals(System.Label.InvoicingLine_StatusDescription_PoMissing, vPInvLine0.Status_Description__c);
        }
    }
    
    @isTest
    public static void notSigned_PoOnIL_UncheckedPoOnLI(){
        System.runAs(adminUser) {
            vContract1 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[0].Id];
            lstPIL[0].N_Purchase_Order__c = '1';
            update lstPIL[0];
            
            Test.startTest();
            	Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract1.Local_information__c];
                localInfo.Purchase_Order__c = true;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes empty (NULL)
            vPInvLine0 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id];
            System.assertEquals(System.Label.InvoicingLine_StatusDescription_PendingBillingRequesterGO, vPInvLine0.Status_Description__c);
        }
    }
    
    @isTest
    public static void notSigned_checkedPoOnLI(){
        System.runAs(adminUser) {
            vContract1 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[0].Id];
            Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract1.Local_information__c];
            localInfo.Purchase_Order__c = true;
            update localInfo;
            
            Test.startTest();
                localInfo.Purchase_Order__c = false;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes 'Signature missing'
            vPInvLine0 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id];
            System.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, vPInvLine0.Status_Description__c);
        }
    }
    
    @isTest
    public static void signed_NoPoOnIL_UncheckedPoOnLI(){
        System.runAs(adminUser) {
            vContract2 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[1].Id];
            vPInvLine0 = [SELECT Id, PurchaseOrder__c, N_Purchase_Order__c, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Contract2__c = :vContract2.Id][0];
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Contract_Signed_Date__c = System.Today();
            vContract2.Status__c='Signed';
            update vContract2;

            Test.startTest();
            	Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract2.Local_information__c];
                localInfo.Purchase_Order__c = true;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes 'PO missing'
            vPInvLine0 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[2].Id];
            System.assertEquals(System.Label.InvoicingLine_StatusDescription_PoMissing, vPInvLine0.Status_Description__c);
        }
    }
    
    @isTest
    public static void signed_PoOnIL_UncheckedPoOnLI(){
        System.runAs(adminUser) {
            vContract2 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[1].Id];
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Contract_Signed_Date__c = System.Today();
            vContract2.Status__c='Signed';
            update vContract2;
            
            lstPIL[2].N_Purchase_Order__c = '1';
            update lstPIL[2];
            
            Test.startTest();
            	Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract2.Local_information__c];
                localInfo.Purchase_Order__c = true;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes empty (NULL)
            vPInvLine0 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[2].Id];
            System.assertEquals(System.label.InvoicingLine_StatusDescription_PendingBillingRequesterGO, vPInvLine0.Status_Description__c);
        }
    }
    
    @isTest
    public static void signed_CheckedPoOnLI(){
        System.runAs(adminUser) {
            vContract2 = [SELECT Id, Local_information__c FROM Contract__c WHERE ID = :lstContract[1].Id];
            vContract2.PDFStatus_lgt__c ='Updated';
            vContract2.Contract_Signed_Date__c = System.Today();
            vContract2.Status__c='Signed';
            update vContract2;
            
            Local_information__c localInfo = [SELECT Id, Purchase_Order__c FROM Local_information__c WHERE ID = :vContract2.Local_information__c];
            localInfo.Purchase_Order__c = true;
            update localInfo;
            
            Test.startTest();
                localInfo.Purchase_Order__c = false;
                update localInfo;
            Test.stopTest();
            
            //Status description on IL becomes empty (NULL)
            vPInvLine2 = [SELECT Id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[2].Id];
            System.assertEquals(System.label.InvoicingLine_StatusDescription_PendingBillingRequesterGO, vPInvLine2.Status_Description__c);
        }
    }
}