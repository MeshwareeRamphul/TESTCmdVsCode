public with sharing class VFC03_OpportunityDetailDashboard {
/*
// VFC06_OpportunityDetailDashboard
----------------------------------------------------------------------
-- - Name          : VFC06_OpportunityDetailDashboard
-- - Author        : MRA
-- - Description   : Controller for VFP06_OpportunityDetailDashboard
--
-- Maintenance History:
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 28-MAY-2014  MRA    1.0      Intitial version 
-- 30-MAY-2014  MRA    1.1      Updated class - updated condition for clash opportunities /intermediary change
-- 10-JUN-2014  MRA    1.2      Updated class - display KAM info for clash/intermediary change
-- 04-NOV-2014	HDU	   1.3		Updated class - not applicable for renewable opportunity
-- 08-JAN-2015	HDU	   1.4		Updated class - Do not take cloning opportunity as clash
----------------------------------------------------------------------
**********************************************************************
*/
    public Opportunity opp {get;set;}
    public list<Opportunity> clashOppList {get;set;}
    public Opportunity opty {get;set;}
    public string selectStatement = '';
    public String mainProductName { get; set; }
    public String mainProductOwnerName { get; set; }
    public Boolean thereIsDuplicate { get; set; }
    
    public VFC03_OpportunityDetailDashboard(ApexPages.StandardController controller){
    	if (!Test.isRunningTest() ){
    		controller.addFields(new List<String> {'RecordType.DeveloperName', 'Account.Account_Manager__r.Name', 'LastModifiedDate', 'LastModifiedById', 'IsWon', 'Contracts1__r' });
    	}
        system.debug('##Start of Constructor>>VFC03_OpportunityDetailDashboard');
        clashOppList = new list<Opportunity>();
        
        this.opp = (Opportunity) controller.getRecord();
        
        system.debug('##opp id'+opp.id);
        opty = [SELECT Id, IsClosed, AccountId, Name, StageName, CreatedDate,
                    Product__c, Product__r.Product_Owner__r.Name, Product__r.Name 
	                FROM Opportunity
	                WHERE id = :opp.Id
	                ORDER By createdDate Desc];

        if (opty.Product__c != null) {
            mainProductName = opty.Product__r.Name;
            mainProductOwnerName = opty.Product__r.Product_Owner__r.Name;
        }
        
        //display message clash opportunities detected (only if one product and main is the same)
        if (opty.IsClosed == false && opty.AccountId != null && opty.Product__c != null) {                                     
            selectStatement = 'SELECT Id, Iswon, AccountId, Account.Name, Name, StageName, createdDate, ' +
                                        'Product__c, Product__r.Name ' +
                                        'FROM Opportunity ' + 
                                        'WHERE AccountId = \'' + opty.AccountId + '\' ' +            
                                        'AND Id != \'' + opp.id + '\'' +
                                        'AND Product__r.Name = \'' + mainProductName + '\'' +
                                        'AND IsClosed = false';   
                                                  
			for (Opportunity oppClash : Database.Query(selectStatement)) {    
                if (oppClash.Product__c != null) {
                    clashOppList.add(oppClash);
                }
            }
        }//end if
        system.debug('##clashOppList :  ' + clashOppList);        
       
        thereIsDuplicate = (clashOppList != null && clashOppList.size() > 0);
    }


    /*
    * Returns true if the current user updated the opportunity in the last 5 minutes
    */
    public Boolean getIsWonHasContractAndHasJustBeenUpdatedByCurrentUser() {
        return opp.IsWon && opp.LastModifiedDate.addMinutes(1)  >= DateTime.now() && UserInfo.getUserId() == opp.LastModifiedById && opp.Contracts1__r != null && opp.Contracts1__r.size() > 0;
    }
}