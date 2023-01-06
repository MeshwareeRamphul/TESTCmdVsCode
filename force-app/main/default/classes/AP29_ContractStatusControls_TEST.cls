/**
 * @File Name          : AP29_ContractStatusControls_TEST.cls
 * @Description        : 
 * @Author             : SGO
 * @Group              : 
 * @Last Modified By   : SGO
 * @Last Modified On   : 8/21/2019, 09:50:25 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    19/08/2019, 16:05:18   SGO     Initial Version
**/

@isTest
public with sharing class AP29_ContractStatusControls_TEST {

    static user testUser;
    static User vUserOO;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
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
            vContract =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29', vProduct, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract);
            vContract2 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29', vProduct2, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract2);
            vContract3 =  AP05_TestDataFactory.createContractAdmin('Test Contract AP29', vProduct3, vAccount, vUserOO, vEntityContact);
            lstContracts.add(vContract3);
            insert lstContracts;

            //Invoicing Line
            for (Contract__c theCon : lstContracts){
                lstInvLines.add(AP05_TestDataFactory.createIL(theCon, 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
                lstInvLines.add(AP05_TestDataFactory.createIL(theCon, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
            }
            insert lstInvLines;
        }
    }

    @isTest
    public static void contractStatusControls (){
        system.runAs(testUser){
            test.StartTest();
                
                lstContracts = [SELECT Id, Name, Status__c, Account__c, StartDate__c, EndDate__c, Invoicing_Method__c, Invoicing_Condition__c, Global_Amount__c, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, SOW_Type__c FROM Contract__c WHERE Id in :lstContracts];
                //select invoicing lines from only 1 contract to delete
                lstInvLines = [SELECT Id, Name, Contract2__c FROM Planned_Invoicing_Line__c WHERE Contract2__c = :vContract.Id];
                
                for (Contract__c con : lstContracts){
                    System.debug('// Con: ' + con);

                    con.Status__c=AP_Constant.CONTRACT_STATUS_INTERNAL_VALIDATION;
                    con.Account__c = vAccount.Id;
                    con.Account__c = null;
                    con.StartDate__c = null;
                    con.EndDate__c = null;
                    //con.Invoicing_Method__c = null;
                    con.Invoicing_Condition__c = null;
                    con.AXA_GS_Signed_By__c = null;
                    //con.AXA_GS_Signed_By__r.Title = null;
                    //con.SOW_Type__c = null;

                    lstUpdatedContracts.add(con);
                }
                //change amount for only 1 contract
                vContract2.Global_Amount__c = 0;
                
                try{
                    delete lstInvLines;
                    update lstUpdatedContracts;
                }
                catch(Exception e){
                    System.debug('//Exception: ' + e.getMessage());
                    System.assert(e.getMessage().contains(label.AP29_ErrMsgLegalEntityMandatory));
                    System.assert(e.getMessage().contains(label.AP29_ErrMsgStartDateMandatory));
                    System.assert(e.getMessage().contains(label.AP29_ErrMsgEndDateMandatory));
                    System.assert(e.getMessage().contains(label.AP29_ErrMsgInvoicingMethodMandatory));
                    System.assert(e.getMessage().contains(label.AP29_ErrMsgInvoicingConditionMandatory));
        
                    //Only for contract which has invoicing line and whose amount has been changed
                    for (Contract__c ctr:lstContracts){
                        if (ctr == vContract2 ){
                            System.assert(e.getMessage().contains(label.AP29_ErrMsgGlobalAmountDifferent));
                        }
                    }
                }
            test.StopTest();
        }
    }
}