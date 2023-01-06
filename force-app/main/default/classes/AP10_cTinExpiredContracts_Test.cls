/**
 * @description       : 
 * @author            : JPI
 * @group             : 
 * @last modified on  : 20/10/2020
 * @last modified by  : JPI
 * Modifications Log 
 * Ver   Date         Author   Modification
    -- 20-OCT-2020  JPI     1.0     Initial Version
    -- 25-MAR-2022  ARA     1.1     SP-03319
**/
@isTest
public with sharing class AP10_cTinExpiredContracts_Test {
    
    static User adminUser;
    static ContentWorkspace workspace;
    static Contract__c vContract;
    static Account vEAccount;

    static Id idRecOpCoSingleDraft;

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
        adminUser.PAD_BypassWorkflows__c = true;
        adminUser.PAD_BypassValidationRules__c = true;
        insert adminUser;

        adminUser = [SELECT PAD_BypassValidationRules__c from User where Id = :adminUser.Id limit 1];
        adminUser.PAD_BypassValidationRules__c = true;
        adminUser.cTin_Universign__c = true;
        update adminUser;  

        idRecOpCoSingleDraft = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get(AP_Constant.RT_CTIN_DRAFT).getRecordTypeId();

        System.runAs(adminUser) {

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
    
            // Create the customer (aka entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(adminUser);
    
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;  
            
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(adminUser);
    
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
    
            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
            
            //Contract
            vContract = new Contract__c();
            vContract.recordTypeId = idRecOpCoSingleDraft;
            vContract.TacitRenewal__c = 'No';
            vContract.OwnerId = adminUser.Id;
            vContract.Name = 'Test 1';
            vContract.AXA_GS_Signed_By__c = vEntityContact.Id;
            vContract.CustomerSignedBy__c = vEntityContact.Id;
            vContract.Customer_Operational_Contact__c = vEntityContact.Id;
            vContract.Account__c = vAccount.Id;
            vContract.Status__c = 'Active';
            vContract.StartDate__c = System.Today().addMonths(-5);
            vContract.EndDate__c = System.Today().addMonths(-1);
            vContract.AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY;
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Global_Amount__c = AP05_TestDataFactory.PINVLINE_AMOUNT;
            vContract.SOW_Operational__c = '123';
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            vContract.cTin_MainAPCL0__c = '4 - Genex';
            vContract.cTin_ContractSegment__c = 'Strategic';
            vContract.cTin_OrganizationalScope__c = '405 - AXA Belgium';
            vContract.cTin_MainAPCL1__c = '21 - Sales, Marketing & Communication Services';
            vContract.cTin_MainAPCL2__c = '2101 - Creative Services';
            vContract.cTin_MainAPCL3__c = '210101 - Creative Services - Including Advertising';
           
        }
    }

    // start test
    @isTest 
    Public static void cTinstatusChangedTest() {
        System.runAs(adminUser) {
            
            insert vContract;
            Contract__c c = [SELECT Status__c FROM Contract__c WHERE Status__c =: AP_Constant.contractActive AND EndDate__c < TODAY][0];
            System.assertEquals(c.Status__c, AP_Constant.contractActive);         
            Test.startTest();
                
            AP10_cTinExpiredContracts cTinCsStatus = new AP10_cTinExpiredContracts();
            Database.executeBatch(cTinCsStatus);
                
            Test.stopTest();      
            
            c = [SELECT Status__c FROM Contract__c WHERE Status__c =: AP_Constant.contractExpired][0];
            System.assertEquals(c.Status__c,AP_Constant.contractExpired);
        }
    }

    // start test
    @isTest 
    Public static void cTinstatusChangedErrorTest() {
        System.runAs(adminUser) {
            insert vContract;
            //AP_Constant.isBypassed = true;
            Contract__c c = [SELECT Status__c FROM Contract__c WHERE Status__c =: AP_Constant.contractActive AND EndDate__c < TODAY][0];
            System.assertEquals(c.Status__c, AP_Constant.contractActive);         
            Test.startTest();
            try{
                AP10_cTinExpiredContracts cTinCsStatus = new AP10_cTinExpiredContracts();
                Database.executeBatch(cTinCsStatus);
            }catch(Exception e){
                System.debug('Error: ' + e);
            }
                
            Test.stopTest();      
            
            c = [SELECT Status__c FROM Contract__c WHERE Status__c =: AP_Constant.contractExpired][0];
            System.assertEquals(c.Status__c,AP_Constant.contractExpired);
           // AP_Constant.isBypassed =false;
        }
    }
}