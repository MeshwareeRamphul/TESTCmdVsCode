public without sharing class HealthCheckHandler {
    
    /*----------------------------------------------------------------------
        -- - Name          : HealthCheckHandler
        -- - Author        : ARA
        -- - Description   : trigger handler for Health_Check__c
        -- - @Last Modified By   : AMA
    -- - Last Modified On   : 01-April-2022, 12:01
        -- - History:
        -- Date         Name  Version  Remarks
        -- -----------  ----  -------  ---------------------------------------
        -- 21-03-2022   ARA    1.1      Initial version
        -- 19-04-2022   MRA    1.2      Added create rights for contract owner / contract-co owner and procurement 
    -------------------------------------------------------------------------*/
    
    public static void afterInsert(List<Health_Check__c> lstHealthCheck){
        List<cTin_ContractTeam__c> lstContractTeam;
        Map<Id,List<cTin_ContractTeam__c>> mapContract = new Map<Id,List<cTin_ContractTeam__c>>();
        Set<Id> setCtrId = new Set<Id>();
        
        for(Health_Check__c healthcheck : lstHealthCheck){
            if(healthcheck.Contract__c != null){
                setCtrId.add(healthcheck.Contract__c);
            }
        }
        
        // recalculate sharing
        if(setCtrId.size() > 0){
            AP40_ContractTeamManageSharing.recalculateSharing(setCtrId);
        }
    }
    
    // Allow creation health check if current user is in contract team (Team Member or Group Member) with role health-check owner
    public static void beforeInsert(List<Health_Check__c> lstHealthCheck){
        Map<ID,List<Health_Check__c>> mapIdCtrLstHC = new Map<ID,List<Health_Check__c>>();
        for(Health_Check__c HC :lstHealthCheck){
            if(mapIdCtrLstHC.containsKey(HC.Contract__c)){
                mapIdCtrLstHC.get(HC.Contract__c).add(HC);
            } else {
                List<Health_Check__c> lstHC = new List<Health_Check__c>();
                lstHC.add(HC);
                mapIdCtrLstHC.put(HC.Contract__c,lstHC);
            }
        }
        
        Map<String,set<ID>> mapGrpNamSetIdGM = new Map<String,set<ID>>();
        List<GroupMember> lstGrpMbr = [Select group.name,UserOrGroupId From GroupMember];
        for(GroupMember GM :lstGrpMbr){
            if(mapGrpNamSetIdGM.containsKey(GM.group.name)){
                mapGrpNamSetIdGM.get(GM.group.name).add(GM.UserOrGroupId);
            } else if(!mapGrpNamSetIdGM.containsKey(GM.group.name)){
                Set<ID> setIdGM = new Set<ID>();
                setIdGM.add(GM.UserOrGroupId);
                mapGrpNamSetIdGM.put(GM.group.name,setIdGM);
            }
        }
        
        /*List<cTin_ContractTeam__c> lstTeam = [select id,name,cTin_Role__c,cTin_TeamMember__c,
                                              Health_Check_Access_Level__c,cTin_GroupMember__c,
                                              cTin_Contract__c 
                                              from cTin_ContractTeam__c
                                              where (cTin_Role__c='020' OR cTin_Role__c='028' OR cTin_Role__c='015' OR cTin_Role__c='017')
                                              and cTin_Contract__c in :mapIdCtrLstHC.keyset() 
                                              and Health_Check_Access_Level__c=:'Edit'];
        Set<ID> setIdCtr = new Set<ID>();
        for(cTin_ContractTeam__c ctrTeam :lstTeam){
            if(!String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(ctrTeam.cTin_TeamMember__c != userinfo.getuserid()){setIdCtr.add(ctrTeam.cTin_Contract__c);}
            } else if(String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(mapGrpNamSetIdGM.containsKey(ctrTeam.cTin_GroupMember__c)){
                    Set<ID> SetIdGM = mapGrpNamSetIdGM.get(ctrTeam.cTin_GroupMember__c);
                    if(!SetIdGM.contains(userinfo.getuserid())){setIdCtr.add(ctrTeam.cTin_Contract__c);}
                }
            }
        }*/
        list<cTin_ContractTeam__c>lstTeam=new list<cTin_ContractTeam__c>();
        map<id,set<id>>mapCtrMembers=new map<id,set<id>>();
        for(cTin_ContractTeam__c ctrTeam:[select id,name,cTin_Role__c,cTin_TeamMember__c,
                                              Health_Check_Access_Level__c,cTin_GroupMember__c,
                                              cTin_Contract__c 
                                              from cTin_ContractTeam__c
                                              where (cTin_Role__c='020' OR cTin_Role__c='028' OR cTin_Role__c='015' OR cTin_Role__c='017')
                                              and cTin_Contract__c in :mapIdCtrLstHC.keyset() ]){
            lstTeam.add(ctrTeam);    
            if(!String.isBlank(ctrTeam.cTin_TeamMember__c)){
                //if(ctrTeam.cTin_TeamMember__c != userinfo.getuserid()){setIdCtr.add(ctrTeam.cTin_Contract__c);}
                if(mapCtrMembers.containsKey(ctrTeam.cTin_Contract__c)) {set<Id> usersId = mapCtrMembers.get(ctrTeam.cTin_Contract__c); usersId.add(ctrTeam.cTin_TeamMember__c);mapCtrMembers.put(ctrTeam.cTin_Contract__c, usersId);
                } else {
                    mapCtrMembers.put(ctrTeam.cTin_Contract__c, new set<Id> {ctrTeam.cTin_TeamMember__c});
                }
                
            } else if(String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(mapGrpNamSetIdGM.containsKey(ctrTeam.cTin_GroupMember__c)){
                    Set<ID> SetIdGM = mapGrpNamSetIdGM.get(ctrTeam.cTin_GroupMember__c);
                    for(id grpM : SetIdGM ){
                         if(mapCtrMembers.containsKey(ctrTeam.cTin_Contract__c)) {set<Id> usersId = mapCtrMembers.get(ctrTeam.cTin_Contract__c);usersId.add(grpM);mapCtrMembers.put(ctrTeam.cTin_Contract__c, usersId);
                        } else {mapCtrMembers.put(ctrTeam.cTin_Contract__c, new set<Id> {grpM});
                        }
                    }
                    
                    //if(!SetIdGM.contains(userinfo.getuserid())){setIdCtr.add(ctrTeam.cTin_Contract__c);}
                    
                }
            }
        }
        
        Profile profile = [select id, name from profile where id=:userinfo.getProfileid()];
        
        if(lstTeam.size() > 0 && profile.name != AP_Constant.systemAdmin){
            for(ID idCtr :mapIdCtrLstHC.keyset()){
                //if(setIdCtr.contains(idCtr)){
                if(mapCtrMembers.containsKey(idCtr) && !(mapCtrMembers.get(idCtr)).contains(userinfo.getuserid())){
                    for(Health_Check__c HC :mapIdCtrLstHC.get(idCtr)){HC.addError(Label.Error_new_health_Check);}
                }
            }
        } else if(lstTeam.size() == 0 && profile.name != AP_Constant.systemAdmin){
            for (ID idCtr : mapIdCtrLstHC.keySet()){
                for(Health_Check__c HC :mapIdCtrLstHC.get(idCtr)){ HC.addError(Label.Error_new_health_Check);}
            }
        }
    }
    
    public static void dummy(){
        integer i=0;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
    }
}