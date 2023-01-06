@isTest
private class AP51_ManageProductonContract_TEST {
 /*----------------------------------------------------------------------
    -- - Name          : AP51_ManageProductonContract_TEST
    -- - Author        : Spoon
    -- - Description   : Test Class for AP51_ManageProductonContract
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 19-MAR-2018  MRA    1.0      Initial version    
    -- 09-SEP-2020  ARA    1.1      SP-00439
-------------------------------------------------------------------------*/ 

    static User testUser;
    static Account vAccount,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Master_WBS_Structure__c vMasterWBS_1;
    static list<Contract__c> lstContract;
    static list<PDFContractAttached__c> lstpdfContractAtt;
    static List<ProductItem__c> lstCtrPItems = new List<ProductItem__c>();

    static{

        testUser = AP05_TestDataFactory.createPMUser();

        //User vUserPM = AP05_TestDataFactory.createPMUser();

        system.runAs(testUser){

            vMasterWBS_1 = AP05_TestDataFactory.createActivityCode('L21FS_GC_000001', AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY);
    
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
    
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);
    
            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
    
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser,'Legal Account');
    
            // Create the couple Entity - Billing Entity on Parent Entity
            // vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
    
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
    
    
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(testUser);
    
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, testUser);
    
            vOffer = AP05_TestDataFactory.createOffer(vDomain, testUser);*/
    
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ testUser, AP_Constant.PRODUCT_LIVE, 'TestProduct1');
    
            lstpdfContractAtt = new list<PDFContractAttached__c>{new PDFContractAttached__c(),
                                        new PDFContractAttached__c(),
                                        new PDFContractAttached__c()};
            insert lstpdfContractAtt;
    
            lstContract=new list<Contract__c>{
                new Contract__c(Name='Contract1',AXA_GS_Signed_By__c=vEntityContact.Id, Signature_Type__c = 'Manual',
                CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                Account__c = vAccount.Id,/*Notify_Validation__c = testUser.Id,*/PDFContrAtt__c=lstpdfContractAtt[0].id,
                Status__c = AP_Constant.CONTRACT_STATUS_DRAFT,StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY,
                ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(), Master_WBS_2__c = vMasterWBS_1.Id),
                new Contract__c(Name='Contract2',AXA_GS_Signed_By__c=vEntityContact.Id,PDFContrAtt__c=lstpdfContractAtt[1].id, Signature_Type__c = 'Manual',
                CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                Account__c = vAccount.Id,/*Notify_Validation__c = testUser.Id,*/
                Status__c = AP_Constant.CONTRACT_STATUS_DRAFT,StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY,
                ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(), Master_WBS_2__c = vMasterWBS_1.Id),
                new Contract__c(Name='Contract3',AXA_GS_Signed_By__c=vEntityContact.Id,PDFContrAtt__c=lstpdfContractAtt[2].id, Signature_Type__c = 'Manual',
                CustomerSignedBy__c = vEntityContact.Id,Customer_Operational_Contact__c = vEntityContact.Id,
                Account__c = vAccount.Id,/*Notify_Validation__c = testUser.Id,*/
                Status__c = AP_Constant.CONTRACT_STATUS_DRAFT,StartDate__c = System.Today().addMonths(-5),EndDate__c = System.Today().addMonths(-1),
                AXA_GO_Legal_Entity__c = AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY,
                ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU,
                InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
                Global_Amount__c = 100,SOW_Operational__c = '123',Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService,
                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(), Master_WBS_2__c = vMasterWBS_1.Id)
            };
        }
    }

    //check if creation of product items is blocked if contract status is 'Ready for signature' or above
    static testMethod void blockCreationPItem_test(){
        system.runAs(testUser){
            string errorMsg = '';
            lstContract[0].status__c = AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;
            lstContract[0].Signature_Type__c = 'Manual';
            lstContract[0].Master_WBS_2__c = vMasterWBS_1.Id;
            insert lstContract;

            ProductItem__c pItem = new  ProductItem__c (contract__c = lstContract[0].Id,product__c = vProduct.id);

            test.startTest();
              try{
                insert pItem;
              } 
              catch(Exception e){
                errorMsg=e.getMessage();
              }
            test.stopTest();

            //system.assertNotEquals('',errorMsg);
        }
    }
/*
    //check if PDFStatus__c on contract is updated to  'Not Updated' when pItem is deleted/updated/created and status is below 'Ready for signature' 
    static testMethod void createPItemOnInsert_test(){
        system.runAs(testUser){
            string errorMsg = '';
            lstContract[0].OfferATS__c = vOffer.id;
            lstContract[1].OfferATS__c = vOffer.id;
            lstContract[2].OfferATS__c = vOffer.id;
            lstContract[0].Master_WBS_2__c = vMasterWBS_1.Id;
            lstContract[1].Master_WBS_2__c = vMasterWBS_1.Id;
            lstContract[2].Master_WBS_2__c = vMasterWBS_1.Id;
            insert lstContract;

            list<ProductItem__c> lstpItem = [select id from ProductItem__c where contract__c IN: lstContract ];
            ProductItem__c pItem = new ProductItem__c(contract__c=lstContract[2].id,product__c = vProduct.id);
            test.startTest();
                update lstpItem[0];//update product item
                delete lstpItem[1];//delete product item
                insert pItem; //insert product item          
            test.stopTest();

            list<Contract__c> Updatedcontract1 = [select PDF_Status__c,id from contract__c where id =: lstContract[0].id];
            system.assertEquals(Updatedcontract1[0].PDF_Status__c,'Not Updated');

            list<Contract__c> Updatedcontract2 = [select PDF_Status__c,id from contract__c where id =: lstContract[1].id];
            system.assertEquals(Updatedcontract2[0].PDF_Status__c,'Not Updated');

             list<Contract__c> Updatedcontract3 = [select PDF_Status__c,id from contract__c where id =: lstContract[2].id];
            system.assertEquals(Updatedcontract3[0].PDF_Status__c,'Not Updated');
        }
    }*/
}