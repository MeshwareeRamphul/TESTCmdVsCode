public without sharing class LegalInformationHandler {
    
/*----------------------------------------------------------------------
-- - Name          : LegalInformationHandler
-- - Author        : ARA
-- - Description   : trigger handler for Legal_Information__c
-- - @Last Modified By   : AMA
-- - Last Modified On   : 01-April-2022, 12:00
-- - History:
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 21-03-2022   ARA    1.1      Initial version
-- 24-06-2022   MRA    1.2      Added bypass on block creation of Legal Info if current user is not added to team as legal owner if Transact is being launched
-------------------------------------------------------------------------*/

  public static void afterInsert(List<Legal_Information__c> lstLegalInfo){
        Set<Id> setCtrId = new Set<Id>();
        
        for(Legal_Information__c legalInfo : lstLegalInfo){
            if(legalInfo.Contract__c != null){
                setCtrId.add(legalInfo.Contract__c);
            }
        }
        
        // recalculate sharing
        if(setCtrId.size() > 0){
            AP40_ContractTeamManageSharing.recalculateSharing(setCtrId);
        }
    }
     
    // Allow creation legal information if current user is in contract team (Team Member or Group Member) with role leagal owner
    public static void beforeInsert(List<Legal_Information__c> lstLegalInfo){
        //system.debug('## starting legalinfoHandler Before insert');
       
        Map<ID,List<Legal_Information__c>> mapIdCtrLstLI = new Map<ID,List<Legal_Information__c>>();
        for(Legal_Information__c LI :lstLegalInfo){
            if(!LI.Imported__c){// Allow user to import Legal Clauses from parent
                if(mapIdCtrLstLI.containsKey(LI.Contract__c)){
                    mapIdCtrLstLI.get(LI.Contract__c).add(LI);
                } else {
                    List<Legal_Information__c> lstLI = new List<Legal_Information__c>();
                    lstLI.add(LI);
                    mapIdCtrLstLI.put(LI.Contract__c,lstLI);
                }
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
        
        /*List<cTin_ContractTeam__c> lstTeam = [select id,name,cTin_Role__c,cTin_TeamMember__c,Legal_Access_Level__c,cTin_GroupMember__c,cTin_Contract__c from cTin_ContractTeam__c where cTin_Role__c='004' and cTin_Contract__c in :mapIdCtrLstLI.keyset() and Legal_Access_Level__c=:'Edit'];
        Set<ID> setIdCtr = new Set<ID>();
        for(cTin_ContractTeam__c ctrTeam :lstTeam){
            if(!String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(ctrTeam.cTin_TeamMember__c != userinfo.getuserid()){
                    setIdCtr.add(ctrTeam.cTin_Contract__c);
                }
            } else if(String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(mapGrpNamSetIdGM.containsKey(ctrTeam.cTin_GroupMember__c)){
                    Set<ID> SetIdGM = mapGrpNamSetIdGM.get(ctrTeam.cTin_GroupMember__c);
                    if(!SetIdGM.contains(userinfo.getuserid())){
                        setIdCtr.add(ctrTeam.cTin_Contract__c);
                    }
                }
            }
        }*/

        list<cTin_ContractTeam__c>lstTeam=new list<cTin_ContractTeam__c>();
        map<id,set<id>>mapCtrMembers=new map<id,set<id>>();
        for(cTin_ContractTeam__c ctrTeam:[select id,name,cTin_Role__c,cTin_TeamMember__c,
                                            Legal_Access_Level__c,cTin_GroupMember__c,
                                            cTin_Contract__c 
                                            from cTin_ContractTeam__c
                                            where (cTin_Role__c='004' or cTin_Role__c='012' or cTin_Role__c='026')
                                            and Legal_Access_Level__c='Edit'
                                            and cTin_Contract__c in :mapIdCtrLstLI.keyset() ]){
            lstTeam.add(ctrTeam);    
            if(!String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(mapCtrMembers.containsKey(ctrTeam.cTin_Contract__c)) {
                    set<Id> usersId = mapCtrMembers.get(ctrTeam.cTin_Contract__c);
                    usersId.add(ctrTeam.cTin_TeamMember__c);
                    mapCtrMembers.put(ctrTeam.cTin_Contract__c, usersId);
                } else {
                    mapCtrMembers.put(ctrTeam.cTin_Contract__c, new set<Id> {ctrTeam.cTin_TeamMember__c});
                }
                
            } else if(String.isBlank(ctrTeam.cTin_TeamMember__c)){
                if(mapGrpNamSetIdGM.containsKey(ctrTeam.cTin_GroupMember__c)){
                    Set<ID> SetIdGM = mapGrpNamSetIdGM.get(ctrTeam.cTin_GroupMember__c);
                    for(id grpM : SetIdGM ){
                         if(mapCtrMembers.containsKey(ctrTeam.cTin_Contract__c)) {
                            set<Id> usersId = mapCtrMembers.get(ctrTeam.cTin_Contract__c);
                            usersId.add(grpM);
                            mapCtrMembers.put(ctrTeam.cTin_Contract__c, usersId);
                        } else {
                            mapCtrMembers.put(ctrTeam.cTin_Contract__c, new set<Id> {grpM});
                        }
                    }
                }
            }
        }
        
        system.debug('## slstTeam' +lstTeam);
        system.debug('## mapIdCtrLstLI' +mapIdCtrLstLI);
        system.debug('## mapCtrMembers' +mapCtrMembers);
        
        Profile profile = [select id, name from profile where id=:userinfo.getProfileid()];
        
        if(lstTeam.size() > 0 && profile.name != AP_Constant.systemAdmin /*&& !LC35_TransactContract.allowClone*/){
           //system.debug('## if');
            for(ID idCtr :mapIdCtrLstLI.keyset()){
                 //system.debug('## idCtr ' +idCtr );
                 //system.debug('## userinfo.getuserid()' +userinfo.getuserid());
                if(mapCtrMembers.containsKey(idCtr) && !(mapCtrMembers.get(idCtr)).contains(userinfo.getuserid())){
                    for(Legal_Information__c LI :mapIdCtrLstLI.get(idCtr)){
                        LI.addError(Label.Error_new_legal_information);
                    }
                }
            }
        } else if(lstTeam.size() == 0 && profile.name !=  AP_Constant.systemAdmin  /*&& !LC35_TransactContract.allowClone*/){
           //system.debug('## else if');
            for (ID idCtr : mapIdCtrLstLI.keySet()){
                for(Legal_Information__c LI :mapIdCtrLstLI.get(idCtr)){
                    LI.addError(Label.Error_new_legal_information);
                }
            }
        }
    }
}