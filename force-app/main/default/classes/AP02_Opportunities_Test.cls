@isTest
public class AP02_Opportunities_Test {
    Static User testUser;
    Static List<Opportunity> lstOpps;
    Static List<Opportunity> lstUpdOpps = new List<Opportunity>();
    static Opportunity opp1;
    static Opportunity opp2;
    static Opportunity opp3;
    
	static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
        
        System.runAs(testUser){
            
            lstOpps = new List<Opportunity>{
                opp1 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                       Name = 'opp1', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today()),
                opp2 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                       Name = 'opp2', Category__c = Label.OptyCategory_BAU, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today()),
                opp3 = new Opportunity(RecordtypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppLgtContract).getRecordTypeId(), 
                                       Name = 'opp3', Category__c = Label.OptyCategory_Project, StageName = AP_Constant.STAGE_LEADS_GATHERING, CloseDate = System.Today())
                    };
            
        }
    }
    
    @isTest
    static void errorStatus_Test(){
        System.runAs(testUser){
            Test.startTest();
            lstOpps[0].StageName = AP_Constant.STAGE_QUALIFY_ALIGN;
            lstOpps[1].AXA_GO_Entity__c = 'AXA Group Operations France';
            AP02_Opportunities.handleBeforeInsert(lstOpps);
            try{
            	insert lstOpps;
            }catch(Exception e){
                System.Assert(e.getMessage().contains(System.Label.Opty_Err_Status_Creation));
            }
            Test.stopTest();
        }
    }
}