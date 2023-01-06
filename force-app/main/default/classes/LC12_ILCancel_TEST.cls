@isTest
private class LC12_ILCancel_TEST {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC12_ILCancel_TEST
    -- - Author        : Spoon Consulting 
    -- - Description   : Test class of LC12_ILCancel
    --                   
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 27-AUG-2019   KZE    1.0    Intitial version
    -- 11-SEP-2019   SGO    1.1    User Lightning + Method testThrowError1 Added (%)
    -- 14-MAY-2020   ARA    1.1    SP-00252 
    ----------------------------------------------------------------------
    **********************************************************************
    */
    
    static user userCanDelete;
    static user userCannotDelete;
    static user testUser;
    static User vUserOO;
    static User vUserPMOADV;
    static User vUserPMO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;
    static List<Product__c> lstProds = new List<Product__c>();
    
    static Contract__c vContract;
    static String result;
    
    
    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static List<Planned_Invoicing_Line__c> lstInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstUpdInvLines = new List<Planned_Invoicing_Line__c>();
    
    static{
        userCannotDelete = TestFactory.createUser('UsrPO',TestFactory.getProfileCannotDelete(),true);
        insert userCannotDelete;
        userCanDelete = TestFactory.createUser('UsrPO',TestFactory.getProfileCanDelete(),true);
        insert userCanDelete;
        testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert testUser;
        system.runAs(testUser){
            AP_Constant.themeLightning = true;
            System.debug('//Theme updated:' + UserInfo.getUiThemeDisplayed());
            // Create user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();
            vUserPMO = AP05_TestDataFactory.createPMOUser();        
            
            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
            
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct1', false);
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2', false);
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct3',false);
            
            lstProds.add(vProduct);
            lstProds.add(vProduct2);
            lstProds.add(vProduct3);
            
            insert lstProds;
            
            //Create contracts
            // vContract =  AP05_TestDataFactory.createContractAdmin('Test Contract LC11',vOffer, vProduct, vAccount, vUserOO, vEntityContact);
            // System.debug('// vContract1: ' + vContract);
            //vContract =  AP05_TestDataFactory.createContract( vProduct, vAccount, vUserOO, vEntityContact);
            vContract = AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL,vProduct, vAccount, vUserOO, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);

            Master_WBS_Structure__c vActCode = new Master_WBS_Structure__c();
            vActCode.Name='testActCode';
            vActCode.Active__c = true;
            vActCode.GIE_GO_SAS__c = AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY;
            insert vActCode;

            vContract.Master_WBS_2__c = vActCode.Id;
            insert vContract;
            
            //Invoicing Line
            vInvoicingLine = AP05_TestDataFactory.createPInvoicingLine(vContract, 'TestIL', 'Credit note test for Invoiced status', false);
            vInvoicingLine2 = AP05_TestDataFactory.createPInvoicingLine(vContract, 'TestIL2', 'Credit note test for Paid status', false);
            
            RecordType rtReadOnly = [SELECT Id, name FROM RecordType WHERE DeveloperName = 'InvLine_ReadOnly' AND SObjectType = 'Planned_Invoicing_Line__c'];
            vInvoicingLine.RecordTypeId = rtReadOnly.Id;
            vInvoicingLine.Master_WBS_Structure__c = vActCode.Id;
            vInvoicingLine2.RecordTypeId = rtReadOnly.Id;
            vInvoicingLine2.Status__c = System.Label.InvLineStatus_Draft;
            vInvoicingLine2.Master_WBS_Structure__c = vActCode.Id;
            
            System.debug('// vInvoicingLine: ' + vInvoicingLine);
            System.debug('// vInvoicingLine2: ' + vInvoicingLine2);
            
            lstInvLines.add(vInvoicingLine);
            lstInvLines.add(vInvoicingLine2);
            
            System.debug('// lstInvLines: ' + lstInvLines);
            insert lstInvLines;          
        }    
    }
    
    @IsTest
    public static void testcancelDraft(){
        System.runAs(testUser) {
            test.StartTest();
            try{
                LC12_ILCancel.cancelIL(lstInvLines[1].Id);
                System.assert(true);
            }catch(Exception e) {
                System.assert(false);
            }               
            test.StopTest();
        }
    }
    
    @IsTest
    public static void testcancelNotDraft(){
        System.runAs(testUser) {
            lstInvLines[1].Status__c = System.Label.InvLineStatusCancelled;
            update lstInvLines;
            
            test.StartTest();
            try{
                LC12_ILCancel.cancelIL(lstInvLines[1].Id);
                System.assert(false);
            }catch(Exception e) {
                System.assert(true);
                System.debug(e.getMessage());
            }               
            test.StopTest();
        }
    }
    
    @IsTest
    public static void testNoIL(){
        System.runAs(testUser) {
            test.StartTest();
            delete lstInvLines[0];   
            try{
                LC12_ILCancel.cancelIL(lstInvLines[0].Id);
                System.assert(false);
            }catch(Exception e) {
                System.assert(true);
                System.debug(e.getMessage());
            }               
            test.StopTest();       
        }
    }
    
    @IsTest
    static void allowedDeleteIL(){
        System.runAs(userCanDelete){
            Test.startTest();
            try{
                LC12_ILCancel.cancelIL(lstInvLines[0].Id);
                System.assert(false);
            }catch(Exception e) {
                System.assert(true);
            } 
            Test.stopTest();
        }
    }
    
    @IsTest
    static void notAllowedDeleteIL(){
        System.runAs(userCannotDelete){
            Test.startTest();
            try{
                LC12_ILCancel.cancelIL(vInvoicingLine.Id);    
            }catch(AuraHandledException e){
                System.assertEquals(System.Label.IL_Cancel_No_Right_Error, e.getMessage());
            }
            Test.stopTest();
        }
    }
}