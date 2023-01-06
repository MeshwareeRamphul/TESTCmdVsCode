@IsTest
public with sharing class LC14_ILClone_Test {
    /**************************************************************************************
    -- - Author        : Spoon consulting
    -- - Description   : Class to clone an invoicing line
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    --              USA    1.0      Initial version
    -- 14-MAY-2020  ARA    1.1      SP-00252 
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    static user userCanClone;
    static user userCannotClone;
    static user testUser;
    static User vUserOO;
    
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;
    
    static Contract__c vContract;
    
    static String result;
    
    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static List<Planned_Invoicing_Line__c> lstInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstUpdInvLines = new List<Planned_Invoicing_Line__c>();
    
    static Planned_Invoicing_Line__c RetInvLine2;
    static Planned_Invoicing_Line__c RetInvLine1;
    
    
    static{
        
        userCannotClone = TestFactory.createUser('UsrPO',TestFactory.getProfileCannotClone(),true);
        insert userCannotClone;
        userCanClone = TestFactory.createUser('UsrPO',TestFactory.getProfileCanClone(),true);
        insert userCanClone;
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        system.runAs(testUser){
            //AP_Constant.themeLightning = true;
            //System.debug('//Theme updated:' + UserInfo.getUiThemeDisplayed());
            // Create user
            vUserOO = AP05_TestDataFactory.createOOUser();
            
            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
            
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);
            //vProduct2 = AP05_TestDataFactory.createProduct(vOffer, vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');
            
            //Create contracts
            vContract =  AP05_TestDataFactory.createContract2(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, true); 
            
            vInvoicingLine = AP05_TestDataFactory.createIL(vContract, 50,'Description 1', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            vInvoicingLine2 = AP05_TestDataFactory.createIL(vContract, 50,'Description 2', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            
            lstInvLines.add(vInvoicingLine);
            lstInvLines.add(vInvoicingLine2);
            
            insert lstInvLines;
            
        }
        
    }
     
    @IsTest
    static void allowedCloneIL(){
        System.runAs(userCanClone){
            Test.startTest();
            result = LC14_ILClone.cloneInvoicingLine(lstInvLines[0].Id);
            Test.stopTest();
            System.assertEquals(System.Label.IL_Not_Found_To_Clone, result);
        }
    }
    
    @IsTest
    static void notAllowedCloneIL(){
        System.runAs(userCannotClone){
            Test.startTest();
            result = LC14_ILClone.cloneInvoicingLine(lstInvLines[0].Id);
            Test.stopTest();
            System.assertEquals(System.Label.IL_Clone_No_Right_Error, result);
        }
    }
     
    @IsTest
    static void cloneIL(){
        System.runAs(testUser){
            Test.startTest();    
            String result2 = LC14_ILClone.cloneInvoicingLine(lstInvLines[1].Id);           
            RetInvLine2 = [SELECT Id, Name, Status__c, RecordTypeId FROM Planned_Invoicing_Line__c
                           WHERE Id=:result2]; 
            result = LC14_ILClone.cloneInvoicingLine(lstInvLines[0].Id);    
            system.debug('*** result : '+result)  ;
            RetInvLine1 = [SELECT Id, Name, Status__c, RecordTypeId FROM Planned_Invoicing_Line__c
                           WHERE Id=:result];
                     
            Test.stopTest();
            
            System.assert(result.startsWith('a07'));
            System.assertEquals(AP_Constant.INVLINE_STATUS_DRAFT,RetInvLine1.Status__c);
            System.assertEquals(vInvoicingLine.RecordTypeId,RetInvLine1.RecordTypeId);
            
            System.assert(result.startsWith('a07'));
            System.assertEquals(AP_Constant.INVLINE_STATUS_DRAFT,RetInvLine2.Status__c);
            //System.assertEquals(vInvoicingLine2.RecordTypeId,RetInvLine2.RecordTypeId);
        }     
    }
    
    @IsTest
    static void handleException(){
        System.runAs(testUser){
            Test.startTest();
            
            // vInvoicingLine2.Status__c = 'Wrong status';
            // update vInvoicingLine2;
            
            // String result = LC14_ILClone.cloneInvoicingLine(vInvoicingLine2.Id);
            // System.debug('##lc14 result ' + result);
            
            // try{
            //     Planned_Invoicing_Line__c RetInvLine2 = [SELECT Id, Name, Status__c, RecordTypeId FROM Planned_Invoicing_Line__c
            //     WHERE Id=:result];
            //     System.debug('##lc14 RetInvLine2 ' + RetInvLine2);
            // }
            // catch(Exception e){
            //     System.debug('##lc14 catch result 111 ' + result);
            //     System.assert(result.contains('Technical error occured'));
            //     System.debug('##lc14 e.getMessage() ' + e.getMessage());
            //     //System.assert(e.getMessage().contains('List has no rows'));
            // }
            
            delete vInvoicingLine2;           
            String result2 = LC14_ILClone.cloneInvoicingLine(lstInvLines[1].Id);
            try{
                Planned_Invoicing_Line__c RetInvLine2 = [SELECT Id, Name, Status__c, RecordTypeId FROM Planned_Invoicing_Line__c
                                                         WHERE Id=:result2];
            }
            catch(Exception e){
                System.assert(result2.contains('not been found'));
                System.assert(e.getMessage().contains('List has no rows'));
            }
            Test.stopTest();
        }
    }
}