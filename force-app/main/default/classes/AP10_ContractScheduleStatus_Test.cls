@isTest
public class AP10_ContractScheduleStatus_Test {
    
    static User vUserPM;
    static User adminUser;
    static ContentWorkspace workspace;
    static Contract__c vContract;
    static List<Contract__c> lstCtr = new List<Contract__c>();

    static map<String, Schema.RecordTypeInfo> mapRecTypeInfo;
    static set<Id> setCtrRecTypesOpCo;
    static Id idRecLightContract;
    static Id idRecOpCoSingleEdit;
    static Id idRecOpCoSingleReadOnly;
    static Id idRecOpCoAmendEdit;
    static Id idRecOpCoAmendReadOnly;
    
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
        //adminUser.PAD_BypassValidationRules__c = true;
        //adminUser.PAD_BypassTrigger__c = 'AP52;AP1012;AP22;';
        insert adminUser;
        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        vUserPM.PAD_BypassValidationRules__c = true;
        vUserPM.PAD_BypassWorkflows__c = true;
        update vUserPM;
        
        // Record Type IDs of contract object
        mapRecTypeInfo = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName();
        idRecLightContract       = mapRecTypeInfo.get(AP_Constant.RT_LIGHTCONTRACT).getRecordTypeId();
        idRecOpCoSingleEdit      = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).getRecordTypeId();
        idRecOpCoSingleReadOnly  = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).getRecordTypeId();
        idRecOpCoAmendEdit       = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).getRecordTypeId();
        idRecOpCoAmendReadOnly   = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).getRecordTypeId();
    
        setCtrRecTypesOpCo  = new set<Id>{idRecLightContract, idRecOpCoSingleEdit, idRecOpCoSingleReadOnly, idRecOpCoAmendEdit, idRecOpCoAmendReadOnly};
        
        System.runAs(vUserPM) {
    
            //Create datas for the tests methods
    
            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
    
            // Create the customer (aka entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);
    
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  
            
            // Create the entity account
            Account vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);
    
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
    
            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            
            //Contract
            lstCtr.add(AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact, 'Signed'));
            lstCtr.add(AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact, 'Signed'));
            lstCtr[0].recordTypeId = idRecOpCoSingleReadOnly;
            lstCtr[0].TacitRenewal__c = 'Yes';
            lstCtr[1].recordTypeId = idRecOpCoSingleReadOnly;
            lstCtr[1].TacitRenewal__c = 'No';
            update lstCtr;
        }
    }

    // start test
    @isTest 
    Public static void statusChangedTest() {
        System.runAs(vUserPM) {
            Contract__c c = [SELECT Status__c FROM Contract__c WHERE Status__c =: System.Label.ContractStatus_Signed AND EndDate__c < TODAY][0];
            System.assertEquals(c.Status__c,System.Label.ContractStatus_Signed);         
            Test.startTest();
                
                AP10_ContractScheduleStatus csStatus = new AP10_ContractScheduleStatus();
                Database.executeBatch(csStatus);
                
            Test.stopTest();      
            
            System.assertEquals(1, [SELECT count() FROM Contract__c WHERE Status__c =: System.Label.ContractStatus_Ended]);
        }
    }

    // start test
    @isTest 
    Public static void statusChangedErrorTest() {   
        Test.startTest();
        
            AP10_ContractScheduleStatus csStatus = new AP10_ContractScheduleStatus();
            Database.executeBatch(csStatus);
        
        Test.stopTest();      
        
        //System.assertEquals(2, [SELECT count() FROM Contract__c WHERE Status__c =: System.Label.ContractStatus_Ended]);
    }
}