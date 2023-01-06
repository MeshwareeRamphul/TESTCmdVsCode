@isTest
private class VFC10_ContractProgressTracker_TEST {
    static User vUserOO,vUserPMO,vUserPM,adminUser ;
    static Account vAccount,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Master_WBS_Structure__c vMasterWBS;
    static List<ProgressTrackerStatus__c> vPTSList;
    
    static  {
        //Create datas for the tests methods
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
        
        system.runas(adminUser){
        // Create OO user
        vUserOO = AP05_TestDataFactory.createOOUser();

        // Create PMO User
        vUserPMO = AP05_TestDataFactory.createPMOUser();

        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser();

        // Create the customer (aka entity) account
        vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

        // Create the entity account
        vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

        // Create the couple Entity - Billing Entity on Parent Entity
        vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

        // Create the entity contact related to the account
        vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
        
        //Product
        vProduct = AP05_TestDataFactory.createProduct(/*vOffer, */vUserOO);
        
        //Contract
        vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPMO, vEntityContact);   
         //Master WBS
        vMasterWBS = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', 'SAS', 'CSS', 'Digital', '2016', true);
        vContract.Master_WBS_2__c = vMasterWBS.id;
        update vContract;


        vPTSList = new List<ProgressTrackerStatus__c>();
        ProgressTrackerStatus__c vPTS1 = new ProgressTrackerStatus__c(name = 'CE_Draft', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Draft', StatusOrder__c = 1, IsFinalStage__c = false); vPTSList.add(vPTS1);
        ProgressTrackerStatus__c vPTS2 = new ProgressTrackerStatus__c(name = 'CE_Internal Validation', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Internal Validation', StatusOrder__c = 2, IsFinalStage__c = false); vPTSList.add(vPTS2);
        ProgressTrackerStatus__c vPTS3 = new ProgressTrackerStatus__c(name = 'CE_Validated', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Validated', StatusOrder__c = 3, IsFinalStage__c = false); vPTSList.add(vPTS3);
        ProgressTrackerStatus__c vPTS4 = new ProgressTrackerStatus__c(name = 'CE_Customer Validation', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Customer Validation', StatusOrder__c = 4, IsFinalStage__c = false); vPTSList.add(vPTS4);
        ProgressTrackerStatus__c vPTS25 = new ProgressTrackerStatus__c(name = 'CE_Rejected by Customer', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Rejected by Customer', StatusOrder__c = 2, IsFinalStage__c = false, DisplayOnlyOnMatch__c = true); vPTSList.add(vPTS25);
        ProgressTrackerStatus__c vPTS5 = new ProgressTrackerStatus__c(name = 'CE_Ready for Signature', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Ready for Signature', StatusOrder__c = 5, IsFinalStage__c = false); vPTSList.add(vPTS5);
        ProgressTrackerStatus__c vPTS6 = new ProgressTrackerStatus__c(name = 'CE_Sent for Signature', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Sent for Signature', StatusOrder__c = 6, IsFinalStage__c = false); vPTSList.add(vPTS6);
        ProgressTrackerStatus__c vPTS7 = new ProgressTrackerStatus__c(name = 'CE_Signed', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Signed', StatusOrder__c = 7, IsFinalStage__c = false); vPTSList.add(vPTS7);
        ProgressTrackerStatus__c vPTS8 = new ProgressTrackerStatus__c(name = 'CE_Terminated', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Terminated', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS8);
        ProgressTrackerStatus__c vPTS10 = new ProgressTrackerStatus__c(name = 'CE_Cancelled', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Cancelled', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS10);
        ProgressTrackerStatus__c vPTS11 = new ProgressTrackerStatus__c(name = 'CE_Ended', RecordTypeName__c = 'AGS_Asia_Edit', StatusMasterLabel__c = 'Ended', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS11);
        upsert vPTSLIST;

        vPTSList = new List<ProgressTrackerStatus__c>();
        vPTS1 = new ProgressTrackerStatus__c(name = 'CRO_Draft', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Draft', StatusOrder__c = 1, IsFinalStage__c = false); vPTSList.add(vPTS1);
        vPTS2 = new ProgressTrackerStatus__c(name = 'CRO_Internal Validation', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Internal Validation', StatusOrder__c = 2, IsFinalStage__c = false); vPTSList.add(vPTS2);
        vPTS3 = new ProgressTrackerStatus__c(name = 'CRO_Validated', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Validated', StatusOrder__c = 3, IsFinalStage__c = false); vPTSList.add(vPTS3);
        vPTS4 = new ProgressTrackerStatus__c(name = 'CRO_Customer Validation', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Customer Validation', StatusOrder__c = 4, IsFinalStage__c = false); vPTSList.add(vPTS4);
        vPTS25 = new ProgressTrackerStatus__c(name = 'CRO_Rejected by Customer', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Rejected by Customer', StatusOrder__c = 2, IsFinalStage__c = false, DisplayOnlyOnMatch__c = true); vPTSList.add(vPTS25);
        vPTS5 = new ProgressTrackerStatus__c(name = 'CRO_Ready for Signature', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Ready for Signature', StatusOrder__c = 5, IsFinalStage__c = false); vPTSList.add(vPTS5);
        vPTS6 = new ProgressTrackerStatus__c(name = 'CRO_Sent for Signature', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Sent for Signature', StatusOrder__c = 6, IsFinalStage__c = false); vPTSList.add(vPTS6);
        vPTS7 = new ProgressTrackerStatus__c(name = 'CRO_Signed', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Signed', StatusOrder__c = 7, IsFinalStage__c = false); vPTSList.add(vPTS7);
        vPTS8 = new ProgressTrackerStatus__c(name = 'CRO_Terminated', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Terminated', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS8);
        vPTS10 = new ProgressTrackerStatus__c(name = 'CRO_Cancelled', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Cancelled', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS10);
        vPTS11 = new ProgressTrackerStatus__c(name = 'CRO_Ended', RecordTypeName__c = 'AGS_Asia_ReadOnly', StatusMasterLabel__c = 'Ended', StatusOrder__c = 8, IsFinalStage__c = true); vPTSList.add(vPTS11);
        upsert vPTSLIST;
        }
 
    }

    @isTest 
    public static void getLastStepOrderContractDraftTest() {
        Contract__c vContract = [SELECT Id FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
        System.runAs(vUserPMO) {
            Test.startTest();

            VFC10_ContractProgressTracker vController = new VFC10_ContractProgressTracker();
            vController.mId = vContract.Id;

            //System.assert(vController.getLastStepOrder() == 7, 'Last stage is : ' + vController.getLastStepOrder() + '  but should be 7');
    
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void getLastStepOrderContractENDTest() {
        System.runAs(vUserPMO) {
        Contract__c vContract = [SELECT Id FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
        vContract.PDFStatus_lgt__c = 'Updated';
        vContract.Status__c = AP_Constant.CONTRACT_STATUS_ENDED;
        update vContract;       
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
        
             
            Test.startTest();       
            
            VFC10_ContractProgressTracker vController = new VFC10_ContractProgressTracker();
            vController.mId = vContract.Id;
            //System.assert(vController.getLastStepOrder() == 8, 'Last stage is : ' + vController.getLastStepOrder() + '  but should be 8');
            Test.stopTest();
        }
    } 
    
    @isTest 
    public static void getLastStepOrderContractRejectedTest() {
       system.runas(vUserPMO){
        Contract__c c= [SELECT Id FROM Contract__c WHERE /*Name =: AP05_TestDataFactory.CONTRACT_NAME*/ id=:vContract.Id][0];
        c.Status__c = AP_Constant.CONTRACT_STATUS_REJECTED_BY_CUSTOMER;
        update vContract;
        User vUserPMO = [SELECT Id FROM User WHERE userName = :AP05_TestDataFactory.USER_PMO_USERNAME];
        
         
            Test.startTest();       
            VFC10_ContractProgressTracker vController = new VFC10_ContractProgressTracker();
            vController.mId = c.Id;
            //System.assert(vController.getLastStepOrder() == 8, 'Last stage is : ' + vController.getLastStepOrder() + '  but should be 8');

            Integer vCurrentStatusOrder = vController.getCurrentStatusOrder();
            //System.assert(vCurrentStatusOrder != -1);

            Test.stopTest();            
        }
    }
}