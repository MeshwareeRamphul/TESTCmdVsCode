public with sharing class VFC04_DistributorHome{
/*
----------------------------------------------------------------------
-- - Name          : VFC04_DistributorHome 
-- - Author        : Spoon
-- - Description   : 
--                   
-- Maintenance History:
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
--                    1.0      Initial version
-- 21-NOV-2014  YRA   1.1      Updated version
----------------------------------------------------------------------
**********************************************************************
*/
    /*Integer Variables*/
    public Integer MeetingCounter {get;set;}   
    public Integer OpptyCounter {get;set;}
    public Integer ContractNSCounter {get; set;}
    public Integer ContractPOMissingCounter {get; set;}
    public Integer OptyToApproveCounter {get; set;}
   
    
    public Distributor_Home_Icons_Visibility__c csDisHomeIcons {get;set;}

    
    public String UserId;

    public String ratesString {get;set;}
               
    public boolean isLinkActivated{get;set;}
  
    public VFC04_DistributorHome(){
        system.debug('## >>> Starting Class constructor VFC04_DistributorHome by ' + userInfo.getName());
        UserId = UserInfo.getUserId();
                               
        //initialize var       
        MeetingCounter = 0;
        OpptyCounter = 0;
        OptyToApproveCounter = 0;
       
        isLinkActivated = false;
        //call method
        checkIconsVisisbility();
    }
    
    public void activateLink(){
        isLinkActivated = true;
    }
    public void checkIconsVisisbility(){
        csDisHomeIcons = Distributor_Home_Icons_Visibility__c.getInstance(userInfo.getProfileId());
        system.debug('##csDisHomeIcons'+csDisHomeIcons);
        
        if (csDisHomeIcons != null){
            //ServiceCounter            
            //MeetingCounter
            if(csDisHomeIcons.Meetings_For_Today__c){
                DateTime StartTime = system.now();
                DateTime EndTime = DateTime.newInstance(StartTime .year(),StartTime .month(),StartTime .day()+1);

                MeetingCounter = (Integer)[select count(Id) e from Event where OwnerId =: UserInfo.getUserId() and ((StartDateTime >: StartTime and StartDateTime <: EndTime) or (EndDateTime <: EndTime and EndDateTime >: StartTime))][0].get('e');
            }
            
            //OpptyCounter
            if(csDisHomeIcons.NB_Opportunities__c){
                 OpptyCounter = (Integer) [SELECT count(Id) o from Opportunity where (ownerid =: UserInfo.getUserId() OR Account.Account_Manager__c = :UserInfo.getUserId()) and IsClosed = false][0].get('o');
            }   

            //Contract with PO Missing
            if(csDisHomeIcons.Contract_with_PO_Missing__c){
                ContractPOMissingCounter = (Integer) [SELECT count(Id) c FROM Contract__c WHERE (ownerid =: UserInfo.getUserId()) AND (TECH_IsPOMissing__c = 'PO MISSING') AND (LastModifiedDate != YESTERDAY)][0].get('c');
            } 

            //Contract waiting signature
            if(csDisHomeIcons.Contract_waiting_Signature__c){
                ContractNSCounter = (Integer) [SELECT count(Id) c FROM Contract__c WHERE (ownerid =: UserInfo.getUserId()) AND (Status__c NOT IN ('Ended','Signed','Terminated','Cancelled'))AND (LastModifiedDate != LAST_MONTH)][0].get('c');
            }

            //Oppty to approve counter
            if(csDisHomeIcons.NB_OpportunitiesToApprove__c){
                List<ProcessInstance> vProcessInstances = [Select Id, TargetObjectId, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems WHERE ActorId = :UserInfo.getUserId()) FROM ProcessInstance];
                for (ProcessInstance vPI : vProcessInstances) {
                    if (vPI.TargetObjectId.getSObjectType() == Schema.Opportunity.getSObjectType()) {
                        OptyToApproveCounter += vPI.workItems != null ? vPI.workItems.size() : 0;
                    } 
                }
            }          
        }
    }
}