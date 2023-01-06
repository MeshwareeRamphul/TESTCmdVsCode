@isTest
private class LC06_OppClone_Test {


    Static User testUser;
    Static User vUserMO;
    Static List<Opportunity> lstOpps;
    static Opportunity opp1;
    static Opportunity opp2;
    static Opportunity opp3;
    static Account vAccount;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;
    Static Contact vEntityContact;
    static Opp_ProductItem__c vOppPItem;
    static Opp_ProductItem__c vOppPItem2;
    
    static List<Product__c> lstProds = new List<Product__c>();
    static List<Opp_ProductItem__c> lstOppPItems = new List<Opp_ProductItem__c>();
    static List<Id> setOppRecTypesId = new List<Id>();
    static List<Id> setRecTypesId = new List<Id>();

    static ContentWorkspace workspace;
    
    static String result;

    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;

        System.runAs(testUser){
            
            // Create the account related to the offer
            vAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_LIVE, 'TestProduct1', false);
            vProduct2 = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_LIVE, 'TestProduct2', false);
            vProduct3 = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_LIVE, 'TestProduct3', false);
            
            lstProds.add(vProduct);
            lstProds.add(vProduct2);
            lstProds.add(vProduct3);

            insert lstProds;
            
            for (RecordType recType: [SELECT Id, Name FROM RecordType WHERE SObjectType ='Opportunity' 
                                                                        AND (DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL OR 
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL_RO OR
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE OR
                                                                        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO)
                                                                        ]){
                setRecTypesId.add(recType.Id);
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
                                            AccountId = vAccount.Id, 
                                            Amount = 1000, 
                                            Answer_due_date__c = System.Today().addDays(3), 
                                            Answer_sent_date__c = System.Today().addDays(5), 
                                            Project_start_Date__c = System.Today().addDays(10), 
                                            Go_live_date__c = System.Today().addDays(20),
                                            CurrencyIsoCode = 'EUR',
                                            Entity_contact__c = vEntityContact.Id,
                                            Answer_cinematic__c = 'Proposal (ppt)' ));
            }
            
            insert lstOpps;
            
            //create prod items for vOpp
            vOppPItem = AP05_TestDataFactory.createOppProdItems(testUser, vProduct, lstOpps[0], false);
            lstOppPItems.add(vOppPItem);
            vOppPItem2 = AP05_TestDataFactory.createOppProdItems(testUser, vProduct2, lstOpps[2], false);
            lstOppPItems.add(vOppPItem2);

            insert lstOppPItems;
        }
    }
    
    @isTest
    static void testCloneOpp(){
        System.runAs(testUser){
            Test.startTest();
                //full edit
                result = LC06_OppClone.cloneOpportunity(lstOpps[0].Id);

                Opportunity testopp = [select id,CountProductItems__c from opportunity where id = :lstOpps[0].Id];
                system.debug('##lc06 testopp : ' + testopp);

                List<Opp_ProductItem__c> lstRetProdItems = [SELECT Opportunity__c,Product__c,ProductDescription__c
                                                            FROM Opp_ProductItem__c 
                                                            WHERE Opportunity__c= :result ];
                system.debug('##lc06 lstRetProdItems : ' + lstRetProdItems);

                //single RO
                String result1 = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
                List<Opp_ProductItem__c> lstRetProdItems1 = [SELECT Opportunity__c,Product__c,ProductDescription__c
                                                            FROM Opp_ProductItem__c 
                                                            WHERE Opportunity__c= :result1 ];

                for (Opportunity clonedOpp: [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id = :result OR Id = :result1]){
                    setOppRecTypesId.add(clonedOpp.RecordTypeId);
                }

            Test.stopTest();

            System.assert(result.startsWith('006'));
            System.assert(result1.startsWith('006'));
            //Test if recordtype has been changed to Single Edit
            System.assertEquals(setRecTypesId[2],setOppRecTypesId[1]);
        }      
    }

    @IsTest
    static void testNoOpp(){
        System.runAs(testUser){
            Test.startTest();
                delete lstOpps[2];
                result = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
                System.debug('##lc06 canBeClonedFalse results ' + result);
            Test.stopTest();

            System.assert(result.startsWith('The opportunity has not been found'));
        }
    }

    @IsTest
    static void testCloneOppGSFrance(){
        System.runAs(testUser){
            Test.startTest();
            lstOpps[0].AXA_GO_Entity__c = 'AXA Group Operations France';
            update lstOpps[0];
            //full edit
            result = LC06_OppClone.cloneOpportunity(lstOpps[0].Id);

            Opportunity testopp = [select id from opportunity where id = :lstOpps[0].Id];
            system.debug('##lc06 testopp : ' + testopp);

            List<Opp_ProductItem__c> lstRetProdItems = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result ];
            system.debug('##lc06 lstRetProdItems : ' + lstRetProdItems);

            //single RO
            String result1 = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
            List<Opp_ProductItem__c> lstRetProdItems1 = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result1 ];

            for (Opportunity clonedOpp: [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id = :result OR Id = :result1]){
                setOppRecTypesId.add(clonedOpp.RecordTypeId);
            }

            Test.stopTest();

            System.assert(result.startsWith('006'));
            System.assert(result1.startsWith('006'));
            //Test if recordtype has been changed to Single Edit
            System.assertEquals(setRecTypesId[2],setOppRecTypesId[1]);
        }
    }

    @IsTest
    static void testCloneOppHongKong(){
        System.runAs(testUser){
            Test.startTest();
            lstOpps[0].AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited';
            update lstOpps[0];
            //full edit
            result = LC06_OppClone.cloneOpportunity(lstOpps[0].Id);

            Opportunity testopp = [select id from opportunity where id = :lstOpps[0].Id];
            system.debug('##lc06 testopp : ' + testopp);

            List<Opp_ProductItem__c> lstRetProdItems = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result ];
            system.debug('##lc06 lstRetProdItems : ' + lstRetProdItems);

            //single RO
            String result1 = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
            List<Opp_ProductItem__c> lstRetProdItems1 = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result1 ];

            for (Opportunity clonedOpp: [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id = :result OR Id = :result1]){
                setOppRecTypesId.add(clonedOpp.RecordTypeId);
            }

            Test.stopTest();

            System.assert(result.startsWith('006'));
            System.assert(result1.startsWith('006'));
            //Test if recordtype has been changed to Single Edit
            System.assertEquals(setRecTypesId[2],setOppRecTypesId[1]);
        }
    }

    @IsTest
    static void testCloneOppSpain(){
        System.runAs(testUser){
            Test.startTest();
            lstOpps[0].AXA_GO_Entity__c = 'AXA Group Operations Spain, S.A.';
            update lstOpps[0];
            //full edit
            result = LC06_OppClone.cloneOpportunity(lstOpps[0].Id);

            Opportunity testopp = [select id from opportunity where id = :lstOpps[0].Id];
            system.debug('##lc06 testopp : ' + testopp);

            List<Opp_ProductItem__c> lstRetProdItems = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result ];
            system.debug('##lc06 lstRetProdItems : ' + lstRetProdItems);

            //single RO
            String result1 = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
            List<Opp_ProductItem__c> lstRetProdItems1 = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result1 ];

            for (Opportunity clonedOpp: [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id = :result OR Id = :result1]){
                setOppRecTypesId.add(clonedOpp.RecordTypeId);
            }

            Test.stopTest();

            System.assert(result.startsWith('006'));
            System.assert(result1.startsWith('006'));
            //Test if recordtype has been changed to Single Edit
            System.assertEquals(setRecTypesId[2],setOppRecTypesId[1]);
        }
    }

    @IsTest
    static void testCloneOppSwitzerland(){
        System.runAs(testUser){
            Test.startTest();
            lstOpps[0].AXA_GO_Entity__c = 'AXA Group Operations Switzerland AG';
            update lstOpps[0];
            //full edit
            result = LC06_OppClone.cloneOpportunity(lstOpps[0].Id);

            Opportunity testopp = [select id from opportunity where id = :lstOpps[0].Id];
            system.debug('##lc06 testopp : ' + testopp);

            List<Opp_ProductItem__c> lstRetProdItems = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result ];
            system.debug('##lc06 lstRetProdItems : ' + lstRetProdItems);

            //single RO
            String result1 = LC06_OppClone.cloneOpportunity(lstOpps[2].Id);
            List<Opp_ProductItem__c> lstRetProdItems1 = [SELECT Opportunity__c,Product__c,ProductDescription__c
            FROM Opp_ProductItem__c
            WHERE Opportunity__c= :result1 ];

            for (Opportunity clonedOpp: [SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id = :result OR Id = :result1]){
                setOppRecTypesId.add(clonedOpp.RecordTypeId);
            }

            Test.stopTest();

            System.assert(result.startsWith('006'));
            System.assert(result1.startsWith('006'));
            //Test if recordtype has been changed to Single Edit
            System.assertEquals(setRecTypesId[2],setOppRecTypesId[1]);
        }
    }
}