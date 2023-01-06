public class SrcTeamTriggerHandler {
/*----------------------------------------------------------------------
-- - Name          : SrcTeamTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Sourcing_Event_Team__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
--  11-OCT-2021  MRA  1.0      Initial version
--  03-FEB-2021  ARA  2.0      SP-03335 populate SourcingTeamMember__c field on the contract by Team_Member__c
-------------------------------------------------------------------------*/
    public static void BeforeInsertHandler(List<Sourcing_Event_Team__c> lstNewTeam){
    }
        
    
    public static void afterInsertHandler(List<Sourcing_Event_Team__c> lstNewTeam){
		Set<Id> setEventId = new Set<Id>();

        for(Sourcing_Event_Team__c newTeam : lstNewTeam){
            if(newTeam.Sourcing_Event__c != null){
                setEventId.add(newTeam.Sourcing_Event__c); 
            }
        }
        
        if(setEventId.size()>0){
            AP05_Sing_mangageEventTeam.manageEventSharing(setEventId);
            // 03-FEB-2021  ARA  SP-03335
            AP05_Sing_mangageEventTeam.setEventSourcingTeamMember(setEventId);
            
        }
        
        if(lstNewTeam.size()>0)
            AP05_Sing_mangageEventTeam.notifyMember(lstNewTeam);
    }
    
    public static void BeforeUpdateHandler(map<Id,Sourcing_Event_Team__c> mapOldTeam, map<Id,Sourcing_Event_Team__c> mapNewTeam){
       
    }

    public static void afterUpdateHandler(map<Id,Sourcing_Event_Team__c> mapOldTeam, map<Id,Sourcing_Event_Team__c> mapNewTeam){
        Set<Id> setEventId = new Set<Id>();
        List<Sourcing_Event_Team__c> lstSETeam = new List<Sourcing_Event_Team__c>();

        for(Sourcing_Event_Team__c newTeam : mapNewTeam.values()){
            Sourcing_Event_Team__c oldTeam = mapOldTeam.get(newTeam.Id);
            if(oldTeam.Team_Member__c!=newTeam.Team_Member__c || oldTeam.Member_Group__c!=newTeam.Member_Group__c ||oldTeam.Role__c!=newTeam.Role__c){
                setEventId.add(newTeam.Sourcing_Event__c);
            }
        }
        
        if(setEventId.size()>0){
            AP05_Sing_mangageEventTeam.manageEventSharing(setEventId);
            // 03-FEB-2021  ARA  SP-03335
            AP05_Sing_mangageEventTeam.setEventSourcingTeamMember(setEventId);
        }
    }
    
    public static void afterDeleteHandler(map<Id,Sourcing_Event_Team__c> mapOldTeam){
        Set<Id> setEventId = new Set<Id>();

        for(Sourcing_Event_Team__c oldTeam : mapOldTeam.values()){
            if(oldTeam.Sourcing_Event__c != null){
                setEventId.add(oldTeam.Sourcing_Event__c);
            }
        }
        system.debug('## setEventId after delete'+setEventId);
        if(setEventId.size()>0){
            AP05_Sing_mangageEventTeam.manageEventSharing(setEventId);
            // 03-FEB-2021  ARA  SP-03335
            AP05_Sing_mangageEventTeam.setEventSourcingTeamMember(setEventId);
        }
    }
}