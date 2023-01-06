@isTest
public with sharing class LWC5_CloneRecord_Test {
    static user testUser,vUserOO;
    static Account vAccount,vAccount1,vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct,vProduct2,vProduct3;
    static Contract__c vContract2,vContract3,vContract4;
    static ProductItem__c vCtrPItem,vCtrPItem2;    static String result;
    static Opp_ProductItem__c vOppPItem,vOppPItem2;

    static Planned_Invoicing_Line__c vInvoicingLine,vInvoicingLine2;
    static List<Planned_Invoicing_Line__c> lstInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Planned_Invoicing_Line__c> lstUpdInvLines = new List<Planned_Invoicing_Line__c>();
    static List<Contract__c> lstContracts = new List<Contract__c>();
    Static List<Opportunity> lstOpps = new List<Opportunity>();
    static List<ProductItem__c> lstCtrPItems = new List<ProductItem__c>();
    static List<Opp_ProductItem__c> lstOppPItems = new List<Opp_ProductItem__c>();
    static List<Id> setRecTypesId = new List<Id>();
    static Map<String, recordType> vRecordTypes;
    static Legal_Information__c legalInfo;

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

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
			vAccount1 = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct1');
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_LIVE, 'TestProduct3');
            
            //Create contracts
            vContract2 =  AP05_TestDataFactory.createContractLEX(AP_Constant.strContractLightRecType, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract3 =  AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);

            lstContracts.add(vContract2);  
            lstContracts.add(vContract3);
            insert lstContracts;
            
        	vRecordTypes = AP_Constant.getRecordTypes('Contract__c');
            
            // Opportunity
            for (RecordType recType: [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType ='Opportunity' 
                                                                        AND (DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL OR 
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL_RO OR
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE OR
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO)
                                                                        ]){
                setRecTypesId.add(recType.Id);
            	vRecordTypes.put(recType.DeveloperName,recType);
            }
            system.debug('##lc06 setRecTypesId : ' + setRecTypesId.size());
            lstOpps = new List<Opportunity>();
            for(integer i=0; i<setRecTypesId.size(); i++){
                lstOpps.add(new Opportunity(RecordTypeId = setRecTypesId[i],
                                            Name = 'opp'+i,
                                            Category__c = Label.OptyCategory_BAU, 
                                            StageName = AP_Constant.STAGE_LEADS_GATHERING, 
                                            CloseDate = System.Today(), 
                                            OwnerId = testUser.Id, 
                                            AccountId = vAccount1.Id, 
                                            Amount = 1000, 
                                            Answer_due_date__c = System.Today().addDays(3), 
                                            Answer_sent_date__c = System.Today().addDays(5), 
                                            Project_start_Date__c = System.Today().addDays(10), 
                                            Go_live_date__c = System.Today().addDays(20),
                                            CurrencyIsoCode = 'EUR',
                                            Entity_contact__c = vEntityContact.Id,
                                            Answer_cinematic__c = 'Proposal (ppt)',
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited'));
            }
            
            insert lstOpps;
            
            //create prod items for vOpp
            vOppPItem = AP05_TestDataFactory.createOppProdItems(testUser, vProduct, lstOpps[0], false);
            lstOppPItems.add(vOppPItem);
            vOppPItem2 = AP05_TestDataFactory.createOppProdItems(testUser, vProduct2, lstOpps[2], false);
            lstOppPItems.add(vOppPItem2);

            insert lstOppPItems;

            //create legalInfo for ctin
            legalInfo = new Legal_Information__c();
            insert legalInfo;
        }
    }
    
    @isTest
    public static void  cloneContractTest() {
        System.runAs(testUser) { 
            test.StartTest();

            LC09_CtrClone.pSOWNULL = true;
            
            // Light Contract
            Map<String, Object> mapResult = LWC5_CloneRecord.fetchRecord(vContract2.Id);
            System.assert(mapResult.containsKey('record'));
            System.assertEquals(((Contract__c) mapResult.get('record')).recordtypeId, vRecordTypes.get(AP_Constant.RT_LIGHTCONTRACT).Id); 
                
            // SOW
            Map<String, Object> mapResult2 = LWC5_CloneRecord.fetchRecord(vContract3.Id);
            System.assert(mapResult2.containsKey('record'));
            System.assertEquals(((Contract__c) mapResult2.get('record')).recordtypeId, vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id); 
                
            test.StopTest();
        }
    }

    @isTest
    public static void cloneContractError() {
        System.runAs(testUser) {
            test.StartTest();

            delete vContract2;
            Map<String, Object> mapResult = LWC5_CloneRecord.fetchRecord(vContract2.Id);
            System.assert(mapResult.containsKey('error'));
            System.assertEquals('This contract does not exist and cannot be cloned.',mapResult.get('error'));

            vContract3.Status__c = AP_Constant.CONTRACT_STATUS_CANCELLED;
            update vContract3;
            Map<String, Object> mapResult2 = LWC5_CloneRecord.fetchRecord(vContract3.Id);
            System.assert(mapResult2.containsKey('error'));
            System.assertEquals('A cancelled contract cannot be cloned.',mapResult2.get('error'));
                                    
            test.StopTest();
        }
    }
    
    @isTest
    static void cloneOppTest(){
        System.runAs(testUser){
            Test.startTest();
            
            Map<String, Object> mapResult = LWC5_CloneRecord.fetchRecord(lstOpps[0].Id);
            System.assert(mapResult.containsKey('record'));
            System.assertEquals(((Opportunity) mapResult.get('record')).recordtypeId, vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_FULL).Id);
            
            Map<String, Object> mapResult2 = LWC5_CloneRecord.fetchRecord(lstOpps[2].Id);
            System.assert(mapResult2.containsKey('record'));
            System.assertEquals(((Opportunity) mapResult2.get('record')).recordtypeId, vRecordTypes.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).Id);

            Test.stopTest();
        }      
    }

    @isTest
    public static void cloneOppError() {
        System.runAs(testUser) {
            test.StartTest();

            delete lstOpps[0];
            Map<String, Object> mapResult = LWC5_CloneRecord.fetchRecord(lstOpps[0].Id);
            System.assert(mapResult.containsKey('error'));
            System.assertEquals('This opportunity does not exist and cannot be cloned.',mapResult.get('error'));
                                    
            test.StopTest();
        }
    }

    @isTest
    public static void cloneClauseInfo() {
        System.runAs(testUser) {
            test.StartTest();

            Map<String, Object> mapResult = LWC5_CloneRecord.fetchRecord(legalInfo.id);
                                    
            test.StopTest();
        }
    }
}