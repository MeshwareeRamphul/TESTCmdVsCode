@isTest
private class  LC05_SendToPeopleSoft_Test {
/*
----------------------------------------------------------------------
-- - Name          : LC05_SendToPeopleSoft_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC05_SendToPeopleSoft
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 26-APRIL-2019   ZHE    1.0    Intitial version
-- 24-SEP-2019     SGO    2.0    testSendUnauthorised() added
----------------------------------------------------------------------
**********************************************************************
*/
	static user testUser;
	static user vUserFunctionalAdmin;
    static ContentWorkspace workspace;
    static User vUserOO;
    static User vUserPMOADV; 
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract1;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static List<Planned_Invoicing_Line__c> lstvPlannedInvLine; 

    static{

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        system.runAs(testUser){

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();
            vUserFunctionalAdmin =TestFactory.createUser('UsrFunctionalAdmin',TestFactory.getProfileIdByName(AP_Constant.functionalAdmin),true);

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;   

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = testUser.Id, SkipProcessBuilder__c = true);
            insert settings;
     
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            //Contract
            vContract1 = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false );  
            vContract2 = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false );  
            vContract3 = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false ); 
            vContract3.Peoplesoft_Sync__c = true;

            List<Contract__c> lstCtrs = new List<Contract__c>();
            lstCtrs.add(vContract1);
            lstCtrs.add(vContract2);
            lstCtrs.add(vContract3);
            
            for(Contract__c ctr: lstCtrs){
                ctr.Status__c = AP_Constant.CONTRACT_STATUS_SIGNED;
                ctr.Contract_Signed_Date__c = System.today();
            }
            insert lstCtrs;

            lstvPlannedInvLine = new List<Planned_Invoicing_Line__c>{
                AP05_TestDataFactory.createIL(vContract1, 400,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id),
                AP05_TestDataFactory.createIL(vContract1, 300,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id),
                AP05_TestDataFactory.createIL(vContract3, 400,'Description 3', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id)
            };
            insert lstvPlannedInvLine;
        }
    }
    
    @IsTest
    public static void testSendCtrlightoPeopleSoft(){
        System.runAs(vUserFunctionalAdmin) {
            test.StartTest();
                String result = LC05_SendToPeopleSoft.setToSendingtoPS(vContract1.Id);
                Integer numLog = [Select Count() from Log__c where Contract__c = :vContract1.Id];
                Contract__c cont = [Select id, Tech_isSendingToPS__c, PeopleSoftConnectionMessage__c  from Contract__c where Id = :vContract1.Id];
                System.assertEquals('',result);
                System.assertEquals(0, numLog);
                String result2 = LC05_SendToPeopleSoft.sendCtrlightoPeopleSoft(vContract1.Id);
            test.StopTest();
        }
    }
    
    @IsTest
    public static void testSendCtrlightoPeopleSoftNoInvoice_Error(){
        System.runAs(vUserFunctionalAdmin) {
            test.StartTest();
                String Result = LC05_SendToPeopleSoft.sendCtrlightoPeopleSoft(vContract2.Id);
                Integer numLog = [Select Count() from Log__c where Contract__c = :vContract2.Id];
			    Contract__c cont = [Select id,PeopleSoftConnectionMessage__c  from Contract__c where Id = :vContract2.Id];
            test.StopTest();
			System.assertEquals(Label.LC51_NoNewInformationToSend, Result);
            System.assertEquals(0, numLog);
            System.assertEquals(null, cont.PeopleSoftConnectionMessage__c);
        }
    }
    
    @IsTest
    public static void testIsSendingToPS_Error(){
        System.runAs(vUserFunctionalAdmin) {
            test.StartTest();
                vContract2.Tech_isSendingToPS__c = true;
                update vContract2;
                String Result = LC05_SendToPeopleSoft.setToSendingtoPS(vContract2.Id);           
            test.StopTest();
			System.assertEquals(Label.ErrorMessage_SentToPS, Result);
        }
    }
    
    @IsTest
    public static void testIsPeoplesoftSync_Error(){
        System.runAs(vUserFunctionalAdmin) {
            test.StartTest();
                vContract2.Peoplesoft_Sync__c = true;
                update vContract2;
                String Result = LC05_SendToPeopleSoft.setToSendingtoPS(vContract2.Id);          
            test.StopTest();
			System.assertEquals(Label.ErrorMessage_PeoplesoftSync, Result);
        }
    }

    @IsTest
    public static void testSendUnauthorised_Error(){
        System.runAs(vUserPMOADV) {
            test.StartTest();
                String Result = LC05_SendToPeopleSoft.setToSendingtoPS(vContract3.Id);
            test.StopTest();
            System.assertEquals(System.Label.LC05_HaveNoSufficientRights, Result);
        }
    }
    
    @IsTest
    public static void updateTech_IsSendingToPS(){
        System.runAs(vUserFunctionalAdmin) {
            test.StartTest();
                LC05_SendToPeopleSoft.setToSendingtoPS(vContract3.Id);
                vContract3 = [SELECT Id, Tech_isSendingToPS__c FROM Contract__c WHERE Id = :vContract3.Id];
                System.assert(vContract3.Tech_isSendingToPS__c);
            test.StopTest();
        }
    }
}