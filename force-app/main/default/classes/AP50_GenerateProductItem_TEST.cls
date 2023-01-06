@isTest
private class AP50_GenerateProductItem_TEST {
 /*----------------------------------------------------------------------
    -- - Name          : AP50_GenerateProductItem_TEST
    -- - Author        : Spoon
    -- - Description   : Test Class for AP50_GenerateProductItem
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 19-MARS-2018  MRA    1.0      Initial version    
    -- 20-AUG-2019   SGO    1.1      createOppPItemOnUpdate_test Method
    -- 02-SEP-2019   SGO    1.2      createOppPItemOnInsert_test Method
    -- 08-JUN-2020  ARA     1.3      Optimization
-------------------------------------------------------------------------*/ 
        
        static User testUser,testUserAdmin;
        static Account vAccount,vEAccount,vAccount1,vEAccount1;
        static Contact vEntityContact;
        static Product__c vProduct;
        static Product__c vProduct1;
        static Product__c vProduct2;
        static list<Contract__c> lstContract;
        static list<Opportunity> lstOpps;
        
        static{
            testUser = TestFactory.createUser('UsrFunctionalAdmin',TestFactory.getProfileIdByName(AP_Constant.functionalAdmin),true);
            testUser.PAD_BypassTrigger__c = 'AP01;AP19;AP412;AP51;AP22;';
            testUser.PAD_BypassWorkflows__c = true;
            testUser.PAD_BypassValidationRules__c = false;
            insert testUser;

            //testUser = AP05_TestDataFactory.createPMUser();

            system.runAs(testUser){

                vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
                
                // Create the entity account
                vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);
    
                // Create the couple Entity - Billing Entity on Parent Entity
                vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
                            
                // Create the entity contact related to the account
                vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
                vProduct = AP05_TestDataFactory.createProduct(testUser);
                //SGO - 2019/08/30
                vProduct1 = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_STATUS_IDEA, 'Product 2');
                vProduct2 = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_STATUS_IDEA, 'Product 3');
                
                lstContract=new list<Contract__c>{
                    new Contract__c(Name='Contract1',AXA_GS_Signed_By__c=vEntityContact.Id,
                    CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                    Account__c = vAccount.Id ,Signature_Type__c = 'Manual',
                    Status__c = 'Draft',StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                    AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS',
                    ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                    InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                    Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                    recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId()),
                    new Contract__c(Name='Contract2',AXA_GS_Signed_By__c=vEntityContact.Id,
                    CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                    Account__c = vAccount.Id, Signature_Type__c = 'Manual',
                    Status__c = 'Draft',StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                    AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS',
                    ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                    InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                    Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                    recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId()),
                    new Contract__c(Name='Contract3',AXA_GS_Signed_By__c=vEntityContact.Id,
                    CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                    Account__c = vAccount.Id, Signature_Type__c = 'Manual',
                    Status__c = 'Draft',StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                    AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS',
                    ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                    InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                    Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                    recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId())
                    
                };
    
                // SGO - 2019/08/30 - FOR createOppProductItem METHOD
                lstOpps = new List<Opportunity>{
                    new Opportunity(Name='Opp1', AccountId=vEAccount.Id, StageName=AP_Constant.STAGE_LEADS_GATHERING, 
                    CloseDate=System.Today().addMonths(-1), AXA_GO_Entity__c=AP_Constant.GS_ENTITY_AXA_GR_OP_HK,
                    recordtypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()),
                    new Opportunity(Name='Opp2', AccountId=vEAccount.Id, StageName=AP_Constant.STAGE_LEADS_GATHERING, 
                    CloseDate=System.Today().addMonths(-1), AXA_GO_Entity__c=AP_Constant.GS_ENTITY_AXA_GR_OP_HK,
                    recordtypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()),
                    new Opportunity(Name='Opp3', AccountId=vEAccount.Id, StageName=AP_Constant.STAGE_LEADS_GATHERING, 
                    CloseDate=System.Today().addMonths(-1), AXA_GO_Entity__c=AP_Constant.GS_ENTITY_AXA_GR_OP_HK,
                    recordtypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId())
                };
            }
        }



        @isTest
        static void createPItemOnInsert_test(){
            system.runAs(testUser){
                Test.startTest();
                Contract__c ctr = new Contract__c(Name='Contract1',AXA_GS_Signed_By__c=vEntityContact.Id,
                    CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                    Account__c = vAccount.Id ,Signature_Type__c = 'Manual',
                    Status__c = 'Draft',StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                    AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS',
                    ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                    InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                    Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                    Product__c = vProduct1.Id,
                    recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('OpCo360 - Light Contract').getRecordTypeId());
                insert ctr;
                Test.stopTest();
            }
        }
        /*//check if product items is generated when offer is filled on creation of contract
        static testMethod void createPItemOnInsert_test(){
            system.runAs(testUser){
                lstContract[0].OfferATS__c=vOffer.id;
                lstContract[1].OfferATS__c=vOffer.id;
                lstContract[2].OfferATS__c=vOffer2.id; //should not generate prod item because 2 prods in offer
                
                test.startTest();
                   insert lstContract;
                test.stopTest();

                list<ProductItem__c>lstpItem=[select id,contract__r.name from ProductItem__c where Contract__c IN:lstContract];
                system.assertEquals(lstContract.size()-1, lstpItem.size());
            }

        }*/

        /*//check if product items is generated when offer is updated on contract
        static testMethod void createPItemOnUpdate_test(){
            system.runAs(testUser){
                insert lstContract;
                test.startTest();
                    // 06-07-2020 ARA
                    ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
                    lstContract[0].OfferATS__c=vOffer.id;
                    lstContract[1].OfferATS__c=vOffer.id;
                    lstContract[2].OfferATS__c=vOffer2.id; //should not generate prod item because 2 prods in offer
                    update lstContract;
                test.stopTest();
                list<ProductItem__c>lstpItem=[select id from ProductItem__c where Contract__c in:lstContract];
                System.assertEquals(lstContract.size()-1, lstpItem.size());
            }
        }*/


        /*// SGO - 2019/08/30 - FOR createOppProductItem METHOD
        static testMethod void createOppPItemOnInsert_test(){
            system.runAs(testUser){
                lstOpps[0].Offer__c=vOffer.id;
                lstOpps[1].Offer__c=vOffer.id;
                lstOpps[2].Offer__c=vOffer2.id; //should not generate opp prod item because 2 prods in offer
                
                test.startTest();
                   insert lstOpps;
                test.stopTest();

                list<Opp_ProductItem__c>lstOppPItem=[select id, Name, Opportunity__r.name from Opp_ProductItem__c where Opportunity__c in :lstOpps];
                System.assertEquals(lstOpps.size()-1, lstOppPItem.size());
            }
        }

        static testMethod void createOppPItemOnUpdate_test(){
            system.runAs(testUser){
                insert lstOpps;

                test.startTest();
                   lstOpps[0].Offer__c=vOffer.id;
                   lstOpps[1].Offer__c=vOffer.id;
                   lstOpps[2].Offer__c=vOffer2.id;  //should not generate prod item because 2 prods in offer
                
                   update lstOpps;
                test.stopTest();

                list<Opp_ProductItem__c>lstOppPItem=[select id, Name, Opportunity__r.name from Opp_ProductItem__c where Opportunity__c in :lstOpps];
                System.assertEquals(lstOpps.size()-1, lstOppPItem.size());
            }
        }*/
}