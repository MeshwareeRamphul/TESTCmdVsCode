/**
* This class covers all opportunities trigger event (from AP01 to AP04)
*/
@isTest
private class OpportunityHandler_Test {


    Static User testUser;
    Static User testUser2;
    Static User testUser3;
    Static List<Opportunity> lstOpps;
    static Opportunity opp1;
    static Opportunity opp2;
    static Opportunity opp3;
    static Account vAccount;
    static Product__c vProduct;
    static Product__c vProduct2;
    Static Contact vEntityContact;

    static ContentWorkspace workspace;

    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
        testUser2 = TestFactory.createUser('UsrAdmin2',TestFactory.getProfileAdminId(),true);
        testUser2.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser2;
        testUser3 = TestFactory.createUser('UsrAdmin2',TestFactory.getProfileAdminId(),true);
        insert testUser3;

        System.runAs(testUser){
            
            // Create the account related to the offer
            vAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Produc
            vProduct = AP05_TestDataFactory.createProduct(testUser);
            vProduct2 = AP05_TestDataFactory.createProduct(testUser, AP_Constant.PRODUCT_STATUS_IDEA, 'Product 2');
            
            lstOpps = new List<Opportunity>();
            for(integer i=0; i<5; i++){
                lstOpps.add(new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Ap_Constant.RT_OPP_LIGHTNING_FULL_LABEL).getRecordTypeId(),
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
        }
    }
    
    @isTest
    static void VerifyStage_Test(){
        System.runAs(testUser){
            lstOpps[0].StageName = AP_Constant.STAGE_QUALIFY_ALIGN;
            Test.startTest();
            try{
                insert lstOpps;
            }catch(Exception e){
				System.Assert(e.getMessage().contains(System.Label.Opty_Err_Status_Creation));
            }
            Test.stopTest();
        }      
    }
    
    @isTest
    static void handleBeforeInsertError_Test(){
        System.runAs(testUser3){
            Test.startTest();
            try{
                insert lstOpps;
            }catch(Exception e){
				System.Assert(e.getMessage().contains('Cannot find picklist value'));
            }
            Test.stopTest();
        }      
    }
    
    @isTest
    static void handleInsert_Test(){
        System.runAs(testUser){        
            Test.startTest();	
            	insert lstOpps;
            Test.stopTest();
        }
    }

    
    @IsTest
    static void handleUpdate_Test(){
        System.runAs(testUser){
            insert lstOpps;
            for (Opportunity opp : lstOpps){
                opp.StageName = AP_Constant.STAGE_LOST;
            }
            
            Test.startTest();
				update lstOpps;
            Test.stopTest();
        }
    }
    
    
    @isTest
    static void AP28_CreateCtrfromOpp_Test(){
        System.runAs(testUser){
            for(Opportunity opp : lstOpps){
                opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId();
            }
            insert lstOpps;
            for (Opportunity opp : lstOpps){
                opp.StageName = AP_Constant.STAGE_CONTRACTING;
            }
            
            Test.startTest();
				update lstOpps;
            Test.stopTest();
        }
    }
    
    
    @isTest
    static void AP03_Opportunities_Test(){
        System.runAs(testUser){
            for(Opportunity opp : lstOpps){
                opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId();
                opp.Category__c = Label.OptyCategory_Project;
            }
            insert lstOpps;
            for (Opportunity opp : lstOpps){
                opp.StageName = AP_Constant.STAGE_CONTRACTING;
            }
            
            Test.startTest();
            try{
                update lstOpps;   
            }catch(Exception e){
				System.Assert(e.getMessage().contains(System.Label.Attachment_MissingDocumentTrigger));
            }
            Test.stopTest();
        }
    }
}