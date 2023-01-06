@isTest
public class VFC51_SendTOPSMass_Test {
    static user testUser;
    static User vUserOO;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    /*static Quartile__c vQuartile;
    static Petal__c vDomain;
    static Offer__c vOffer;*/
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;

    static Contract__c vContract;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static list<Contract__c> lstContracts = new List<Contract__c>();
    static list<Contract__c> lstUpdatedContracts = new list<Contract__c>();

    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static list<Planned_Invoicing_Line__c> lstInvLines = new list<Planned_Invoicing_Line__c>();

    static{

        testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK); // SGO - 09/19 - Added company
        testUser.PAD_BypassTrigger__c = 'AP01;AP19;AP412;AP51;AP22;';
        testUser.PAD_BypassWorkflows__c = true;
        testUser.PAD_BypassValidationRules__c = true;
        insert testUser;

        system.runAs(testUser){
            AP_Constant.themeLightning = true;
            System.debug('//Theme updated:' + UserInfo.getUiThemeDisplayed());
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
            
            //Quartile (business area)
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(testUser);

            //Petal (Domain)
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, testUser);

            //Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, testUser);*/
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            vProduct2 = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct3');

            //Create contracts
            vContract =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29',/*vOffer,*/ vProduct, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract);
            vContract2 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29',/*vOffer,*/vProduct2, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract2);
            vContract3 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29',/*vOffer,*/vProduct3, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract3);
            insert lstContracts;

            //Invoicing Line
            for (Contract__c theCon : lstContracts){
                vInvoicingLine = AP05_TestDataFactory.createPInvoicingLineAdmin(theCon, 'TestInvLine', 'Testing error message');
                vInvoicingLine.Master_WBS_Structure__c = theCon.Master_WBS_2__c;
                lstInvLines.add(vInvoicingLine);

                vInvoicingLine2 = AP05_TestDataFactory.createPInvoicingLineAdmin(theCon, 'TestInvLine2', 'Testing error message');
                vInvoicingLine2.Master_WBS_Structure__c = theCon.Master_WBS_2__c;
                lstInvLines.add(vInvoicingLine2);
            }
            insert lstInvLines;
        }
    }

	@isTest
    public static void sendToPS(){
        Test.startTest();
        Test.setCurrentPage(Page.VFP51_SendTOPSMass);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstContracts);
            VFC51_SendTOPSMass sentoPS = new VFC51_SendTOPSMass(stdSetController);
            sentoPS.redirectToLC();
        Test.stopTest();
    }
}