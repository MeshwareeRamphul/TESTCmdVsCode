/**
 * <b>Class AP01_Opportunities_Test </b>: test class for AP01_Opportunities
 * @author ARA, ...
 * @version 0.1
 */
@isTest
public with sharing class AP01_Opportunities_Test {

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
            
            vAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            lstOpps = new List<Opportunity>{
                opp1 = new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Single Opportunity process OpCo360').getRecordTypeId(),
                Name = 'opp1', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id, AccountId = vAccount.Id),
                opp2 = new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Single Opportunity process OpCo360').getRecordTypeId(),
                Name = 'opp2', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id),
                opp3 = new Opportunity(RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Single Opportunity process OpCo360').getRecordTypeId(),
                Name = 'opp3', Category__c = Label.OptyCategory_Project, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today(), OwnerId = testUser.Id)
            };         
        }
    }


    @IsTest
    static void handleAfterInsertTest(){       
        System.runAs(testUser){
            Test.startTest();
            	insert lstOpps;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void handleAfterUpdateTest(){
        System.runAs(testUser){
            insert lstOpps;
            lstOpps[0].Amount = 1500;
            lstOpps[0].Assigned_to__c = testUser2.Id;
            lstOpps[1].Amount = 1600;
            lstOpps[1].Assigned_to__c = testUser2.Id;
            lstOpps[2].Amount = 1700;
            lstOpps[2].Assigned_to__c = testUser2.Id;
            
            Test.startTest();
				update lstOpps;
            Test.stopTest();
        }      
    }
}