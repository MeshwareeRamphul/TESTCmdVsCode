@isTest
public class AP19_OpptiesUnfollow_Test {

    Static User testUser;
    Static User testUser2;
    Static List<Opportunity> lstOpps;
    Static List<Opportunity> lstUpdOpps = new List<Opportunity>();
    static Opportunity opp1;
    static Opportunity opp2;
    static Opportunity opp3;
    static Account vAccount;

    static ContentWorkspace workspace;

    static{    
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
        testUser2 = TestFactory.createUser('UsrAdmin2',TestFactory.getProfileAdminId(),true);
        testUser2.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser2;

        System.runAs(testUser){
            
            // Create the account related to the offer
            vAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            
            // Create the entity contact related to the account
            Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(testUser);
            
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
            insert lstOpps;
        }
    }

    
    @IsTest
    static void handleBeforeUpdate(){
        System.runAs(testUser){
            for (Opportunity opp : lstOpps){
                opp.StageName = 'Opportunity Lost';
            }
            
            Test.startTest();
				update lstOpps;
            Test.stopTest();
        }      
    }
}