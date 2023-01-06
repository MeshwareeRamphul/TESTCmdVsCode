@isTest
public class AP55_UncheckPeopleSoftSync_Test {
    static user testUser;
    static User vUserOO;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Invoicing_Parameter__c vInvCond;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;
    static Product__c vProduct4;

    static Contract__c vContract;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static Contract__c vContract4;
    static list<Contract__c> lstContracts = new List<Contract__c>();
    static list<Contract__c> lstUpdatedContracts = new list<Contract__c>();

    static{
        testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK); // SGO - 09/19 - Added company
        insert testUser;

        system.runAs(testUser){
            AP_Constant.themeLightning = true;
            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //InvoicingCondition
            vInvCond = AP05_TestDataFactory.createInvoicingParameter(true);
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct3');
            vProduct4 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct4');

            //Create contracts
            vContract =  AP05_TestDataFactory.createContractAdmin('Test Contract AP55',vProduct, vAccount, vUserOO, vEntityContact);
            vContract.Peoplesoft_Sync__c = true;
            lstContracts.add(vContract);
            vContract2 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP55',/*vOffer,*/vProduct2, vAccount, vUserOO, vEntityContact);
            vContract2.Peoplesoft_Sync__c = true;
            lstContracts.add(vContract2);
            vContract3 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP55',/*vOffer,*/vProduct3, vAccount, vUserOO, vEntityContact);
            vContract3.Peoplesoft_Sync__c = true;
            lstContracts.add(vContract3);
            
            vContract4 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP55',/*vOffer,*/vProduct4, vAccount, vUserOO, vEntityContact);
            vContract4.Invoicing_Condition__c = vInvCond.Name;
            vContract4.Global_Amount__c = 1000;
            lstContracts.add(vContract4);
            
            insert lstContracts;
        }
    }

    @isTest
    public static void uncheckPeopleSoftSync_Test(){
        system.runAs(testUser){
            test.StartTest();
                
                for (Contract__c con : lstContracts){
                    con.Decision_maker__c = 'Entity';
                    con.Cancelled_reason__c = 'Price';
                    con.Status__c = AP_Constant.CONTRACT_STATUS_CANCELLED;
                }
                update lstContracts;
            
            test.StopTest();
            
            //System.assertEquals(4, [SELECT count() FROM Contract__c WHERE Peoplesoft_Sync__c = false]);
        }
    }
}