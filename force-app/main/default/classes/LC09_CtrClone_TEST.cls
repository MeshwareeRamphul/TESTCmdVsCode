@isTest
public with sharing class LC09_CtrClone_TEST {
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

    static Contract__c vContract;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static Contract__c vContract4;

    static ProductItem__c vCtrPItem;
    static ProductItem__c vCtrPItem2;

   
    static String result;
    static Opportunity vOpp= new Opportunity();

    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static List<Planned_Invoicing_Line__c> lstInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstUpdInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Contract__c> lstContracts = new List<Contract__c>();

    static List<ProductItem__c> lstCtrPItems = new List<ProductItem__c>();

    static{

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;

        testUser.PAD_BypassValidationRules__c = true;
        testUser.PAD_BypassTrigger__c = 'AP19;AP01;AP412';
        update testUser;

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
            vProduct = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct1');
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct3');


            //Create contracts
            vContract =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract2 =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            
            vContract3 =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract4 =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);

            lstContracts.add(vContract);  
            lstContracts.add(vContract2);  
            lstContracts.add(vContract3);  
            lstContracts.add(vContract4);  

            insert lstContracts;

            //SGO 2019/08/30 - create prod items for vContract
            vCtrPItem = AP05_TestDataFactory.createCtrProdItems(vContract, vProduct, 'inserting contract prod item');
            lstCtrPItems.add(vCtrPItem);
            vCtrPItem2 = AP05_TestDataFactory.createCtrProdItems(vContract, vProduct2, 'inserting contract prod item2');
            lstCtrPItems.add(vCtrPItem2);

            insert lstCtrPItems;
        }

    }
    // start test
    @isTest
    public static void  cloneAmendmentTest() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        System.runAs(testUser) {     
             vContract.AXA_GS_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_NEWLEGAL_ENTITY;
             update(vContract);


            test.StartTest();

               
                String returnvalue = LC09_CtrClone.cloneContract(vContract.Id);
                System.debug('error msg: ' + returnvalue);
                System.assert(returnvalue.startsWith('a0D'));        
                Contract__c clonedContr = [SELECT Id, recordtypeId FROM Contract__c WHERE id =:returnvalue LIMIT 1];
                System.assertEquals(clonedContr.recordtypeId, vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id ); 
                //SGO - 2019/08/30 - ctr prod items
                List<ProductItem__c> lstCtrPItemsInserted = [SELECT Id, Name, Product__c FROM ProductItem__c WHERE Contract__c = :returnvalue];
                System.assertEquals(0, lstCtrPItemsInserted.size() ); 
                
                //SGO - 2019/08/29 - amendment read only
                String returnvalue1 = LC09_CtrClone.cloneContract(vContract4.Id);
                System.debug('error msg: ' + returnvalue1);
                System.assert(returnvalue1.startsWith('a0D'));        
                Contract__c clonedContr1 = [SELECT Id, recordtypeId FROM Contract__c WHERE id =:returnvalue1 LIMIT 1];
                System.assertEquals(clonedContr1.recordtypeId, vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id ); 

               
            test.StopTest();
        }
    }  
    @isTest
    public static void  cloneContractTest() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');
        System.debug('@@vRecordTypes '+vRecordTypes);
                

        System.runAs(testUser) { 
            test.StartTest();

                LC09_CtrClone.pSOWNULL = true;
                
                String returnvalue = LC09_CtrClone.cloneContract(vContract2.Id);
                System.assert(returnvalue.startsWith('a0D'));        
                Contract__c clonedContr = [SELECT Id, recordtypeId FROM Contract__c WHERE id =:returnvalue LIMIT 1];
                System.assertEquals(clonedContr.recordtypeId, vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id); 
                

                //SGO - 2019/08/29 - contract read only
                String returnvalue1 = LC09_CtrClone.cloneContract(vContract3.Id);
                System.assert(returnvalue1.startsWith('a0D'));        
                Contract__c clonedContr1 = [SELECT Id, recordtypeId FROM Contract__c WHERE id =:returnvalue1 LIMIT 1];
                System.assertEquals(clonedContr1.recordtypeId, vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id); 
                
            test.StopTest();
        }
    }

    @isTest
    public static void  cloneContractTest2() {
        System.runAs(testUser) {

                vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
                vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
                vContract.Decision_maker__c = 'Entity';
                vContract.Cancelled_reason__c = 'Product';
                vContract.Status__c = 'Cancelled';
                //vContract.offerATS__c = null;
                update(vContract);
            //Test : a contract can't be cloned if it's service type is Project
           
            test.StartTest();
               

                String returnvalue = LC09_CtrClone.cloneContract(vContract.Id);
                System.debug('error msg: ' + returnvalue);
                System.assert(returnvalue.startsWith('You cannot clone the following'));             
            test.StopTest();
        }
    }

    //SGO - 2019/08/28 - code coverage 100%
    @isTest
    public static void ErrorThrown() {
        System.runAs(testUser) {
            
            test.StartTest();

                //insert ctr failed
                LC09_CtrClone.ErrorThrown = true;
                String returnvalue = LC09_CtrClone.cloneContract(vContract.Id);
                System.debug('error msg: ' + returnvalue);
                System.assert(returnvalue.startsWith('Technical error occured'));  
                
                //insert ctritem failed
                LC09_CtrClone.ErrorThrown2 = true;
                String returnvalue2 = LC09_CtrClone.cloneContract(vContract.Id);
                System.debug('@@ try error msg: ' + returnvalue2);
                System.assert(returnvalue2.startsWith('Technical error occured'));                      
                                    
            test.StopTest();
        }
    }

    @isTest
    public static void cloneContractNull() {
        System.runAs(testUser) {
            
            test.StartTest();

                LC09_CtrClone.ContractNull = true;
                String returnvalue = LC09_CtrClone.cloneContract(vContract.Id);
                System.debug('@@ try error msg: ' + returnvalue);
                System.assert(returnvalue.startsWith('The contract has not been found'));  
                                    
            test.StopTest();
        }
    }

    
    @isTest
    public static void  cloneContractActiveProductTest() {
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

        System.runAs(testUser) {
			vProduct.Status__c = System.Label.Product_status_retired;
            update vProduct;
            test.StartTest();

                String returnvalue = LC09_CtrClone.cloneContract(vContract.Id);
                System.assertEquals(0, [SELECT count() FROM ProductItem__c WHERE Contract__c = :returnvalue]);                
               
            test.StopTest();
        }
    }  
}