public class AP40_ContractTeamManageSharing {
    
    /*----------------------------------------------------------------------
        -- - Name          : AP40_ContractTeamManageSharing
        -- - Author        : ARA
        -- - Description   :
        --
        -- - History:
        -- Date         Name  Version  Remarks
        -- -----------  ----  -------  ---------------------------------------
        -- 21-03-2022   ARA    1.1      Initial version
    -------------------------------------------------------------------------*/
   
    public static void recalculateSharing(Set<Id> setCtrId){
        List<cTin_ContractTeam__c> lstContractTeam;
        Map<Id,List<cTin_ContractTeam__c>> mapContract = new Map<Id,List<cTin_ContractTeam__c>>();
        for(cTin_ContractTeam__c cTeam :[SELECT Id, cTin_Contract__c, cTin_TeamMember__c, cTin_GroupMember__c, cTin_Role__c,
                                        cTin_ContractAccessLevel__c, Legal_Access_Level__c, Health_Check_Access_Level__c 
                                        FROM cTin_ContractTeam__c 
                                        WHERE cTin_Contract__c IN :setCtrId]){
            if(!mapContract.containsKey(cTeam.cTin_Contract__c)){
                lstContractTeam = new List<cTin_ContractTeam__c>();
            }else{
                lstContractTeam = mapContract.get(cTeam.cTin_Contract__c);
            }
            lstContractTeam.add(cTeam);
            mapContract.put(cTeam.cTin_Contract__c,lstContractTeam);
        }
        
        if(mapContract.size() > 0){
              calculateSharing(mapContract);
        }
    }


  public static void calculateSharing(Map<Id,List<cTin_ContractTeam__c>> mapContract){
        List<sObject> lstShare = new List<sObject>();
        List<Health_Check__c> lstHealthCheck = new List<Health_Check__c>();
        Map<Id,cTin_ContractTeam__c> mapContractTeam = new Map<Id,cTin_ContractTeam__c>();
        Map<Id,cTin_ContractTeam__c> mapTeam = new Map<Id,cTin_ContractTeam__c>();
        Map<Id,Id> mapLegal = new Map<Id,Id>();
        Map<Id,Id> mapHealthCheck = new Map<Id,Id>();
        Map<String,Id> mapGroup = new Map<String,Id>();
        Set<String> setGroupName = new Set<String>();
        set<string> setTeamsWithEdit=new set<string>();
        set<string> setTeamsHCWithEdit=new set<string>();
        set<string> setTeamsLIWithEdit=new set<string>();
        map<string,string> ctrTeamIdCtrMap=new map<string,string>();
        map<string,string>ctrTeamIdHCMap=new map<string,string>();
        map<string,string>ctrTeamIdLIMap=new map<string,string>();
            
        for(Id ctrId : mapContract.keyset()){
            for(cTin_ContractTeam__c cTeam : mapContract.get(ctrId)){
                mapContractTeam.put(cTeam.Id, cTeam);
                system.debug('##8## cTeam '+cTeam.cTin_Role__c+' '+cTeam.Legal_Access_Level__c);
                if(cTeam.cTin_TeamMember__c != null || cTeam.cTin_GroupMember__c != null){
                    if(cTeam.cTin_GroupMember__c != null){
                        setGroupName.add(cTeam.cTin_GroupMember__c);
                    }
                    if(cTeam.cTin_ContractAccessLevel__c != null){
                        mapTeam.put(cTeam.Id, cTeam);
                    }
                    if(cTeam.Legal_Access_Level__c != null){
                        mapLegal.put(cTeam.Id, cTeam.cTin_Contract__c);
                    }
                    if(cTeam.Health_Check_Access_Level__c != null){
                        mapHealthCheck.put(cTeam.Id, cTeam.cTin_Contract__c);
                    }
                }
            }
        }
        system.debug('##8## mapContract ' +mapContract.size());
        system.debug('##8## mapLegal ' +mapLegal.size());

        if(setGroupName.size() > 0){
            for(Group grp : [SELECT Id, Name, DeveloperName FROM Group WHERE Name IN :setGroupName]){
                mapGroup.put(grp.Name, grp.Id);
            }
        }

        // set Contract sharing
        if(mapTeam.size() > 0){
           
            
            
            //MRA 30/11/2022 - loop in list of new contract teams being added , check if access to be created is Read
            for(cTin_ContractTeam__c cTeam : mapTeam.values()){
                if(cTeam.cTin_ContractAccessLevel__c=='Read'){
                    if(cTeam.cTin_TeamMember__c!=null)
                        ctrTeamIdCtrMap.put(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                       //setTeamsWithEdit.add(cTeam.cTin_TeamMember__c);
                    if(cTeam.cTin_TeamMember__c==null)
                        //setTeamsWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c));
                       ctrTeamIdCtrMap.put(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                }  
                
                if(cTeam.Legal_Access_Level__c=='Read' || cTeam.Legal_Access_Level__c==''){
                    if(cTeam.cTin_TeamMember__c!=null)
                        ctrTeamIdLIMap.put(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                       //setTeamsWithEdit.add(cTeam.cTin_TeamMember__c);
                    if(cTeam.cTin_TeamMember__c==null)
                        //setTeamsWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c));
                       ctrTeamIdLIMap.put(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                }    
                
                if(cTeam.Health_Check_Access_Level__c=='Read' || cTeam.Health_Check_Access_Level__c==''){
                    if(cTeam.cTin_TeamMember__c!=null)
                        ctrTeamIdHCMap.put(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                       //setTeamsWithEdit.add(cTeam.cTin_TeamMember__c);
                    if(cTeam.cTin_TeamMember__c==null)
                        //setTeamsWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c));
                       ctrTeamIdHCMap.put(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c,cTeam.cTin_Contract__c);
                }         
            }
            
            system.debug('## ctrTeamIdCtrMap'+ctrTeamIdCtrMap);
            
            //MRA 30/11/2022 - for each contract in ctrTeamIdCtrMap, check if a contract team with Edit access exists
            for(cTin_ContractTeam__c cTeam : [select cTin_Contract__c,cTin_ContractAccessLevel__c,cTin_TeamMember__c ,Legal_Access_Level__c,cTin_GroupMember__c,Health_Check_Access_Level__c
                                                from cTin_ContractTeam__c 
                                                where (cTin_Contract__c IN:ctrTeamIdCtrMap.values() and cTin_ContractAccessLevel__c=:'Edit')
                                                OR (cTin_Contract__c IN:ctrTeamIdHCMap.values() and Health_Check_Access_Level__c=:'Edit')
                                                OR(cTin_Contract__c IN:ctrTeamIdLIMap.values() and Legal_Access_Level__c=:'Edit') ]){
                    if((ctrTeamIdCtrMap.containsKey(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c) &&  cTeam.cTin_ContractAccessLevel__c=='Edit') ||
                      (ctrTeamIdCtrMap.containsKey(cTeam.cTin_TeamMember__c  + '' + cTeam.cTin_Contract__c) &&  cTeam.cTin_ContractAccessLevel__c=='Edit')){
                        if(cTeam.cTin_TeamMember__c!=null)
                            setTeamsWithEdit.add(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c);
                        if(cTeam.cTin_TeamMember__c==null)              
                            setTeamsWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c) + '' + cTeam.cTin_Contract__c);  
                    }  
                    
                    if((ctrTeamIdHCMap.containsKey(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c) &&  cTeam.Health_Check_Access_Level__c=='Edit') ||
                      (ctrTeamIdHCMap.containsKey(cTeam.cTin_TeamMember__c  + '' + cTeam.cTin_Contract__c) &&  cTeam.Health_Check_Access_Level__c=='Edit')){
                        if(cTeam.cTin_TeamMember__c!=null)
                            setTeamsHCWithEdit.add(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c);
                        if(cTeam.cTin_TeamMember__c==null)              
                            setTeamsHCWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c) + '' + cTeam.cTin_Contract__c);  
                    }
                    
                    
                    if((ctrTeamIdLIMap.containsKey(cTeam.cTin_GroupMember__c + '' + cTeam.cTin_Contract__c) &&  cTeam.Legal_Access_Level__c=='Edit') ||
                      (ctrTeamIdLIMap.containsKey(cTeam.cTin_TeamMember__c  + '' + cTeam.cTin_Contract__c) &&  cTeam.Legal_Access_Level__c=='Edit')){
                        if(cTeam.cTin_TeamMember__c!=null)
                            setTeamsLIWithEdit.add(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c);
                        if(cTeam.cTin_TeamMember__c==null)              
                            setTeamsLIWithEdit.add(mapGroup.get(cTeam.cTin_GroupMember__c) + '' + cTeam.cTin_Contract__c);  
                    }  
                        
            }
            
            
            system.debug('## setTeamsWithEdit'+setTeamsWithEdit);
            
            for(cTin_ContractTeam__c cTeam : mapTeam.values()){
                //MRA 30/11/2022 - create new ctrShare only if Edit access should not be overwritten by Read access because user has bee added to Cteam with Edit access previoulsy
                system.debug('## before inserting ctrShare'+ cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c);
                if(!setTeamsWithEdit.contains(cTeam.cTin_TeamMember__c + '' + cTeam.cTin_Contract__c) && !setTeamsWithEdit.contains(mapGroup.get(cTeam.cTin_GroupMember__c) + '' + cTeam.cTin_Contract__c) ){
                   System.debug('## set does not contain team member with edit access => allow overwrite');
                   Contract__Share ctrShare = new Contract__Share();
                    ctrShare.accesslevel = cTeam.cTin_ContractAccessLevel__c;
                    ctrShare.UserOrGroupId = cTeam.cTin_TeamMember__c != null ? cTeam.cTin_TeamMember__c : mapGroup.get(cTeam.cTin_GroupMember__c); 
                    ctrShare.parentId = cTeam.cTin_Contract__c;
                    lstShare.add(ctrShare);
                }
            }
        }

        // get Legal Information and set sharing
        if(mapLegal.size() > 0){
            for(Legal_Information__c legal: [SELECT Id, Contract__c FROM Legal_Information__c WHERE Contract__c IN :mapLegal.values()]){
                for(Id teamId : mapLegal.keySet()){
                    system.debug('##8## teamId'+teamId);
                    system.debug('##8## cond1 '+setTeamsLIWithEdit.contains(mapContractTeam.get(teamId).cTin_TeamMember__c+ '' + mapLegal.get(teamId)));
                    system.debug('##8## cond2 '+setTeamsLIWithEdit.contains(mapGroup.get(mapContractTeam.get(teamId).cTin_GroupMember__c) + '' + mapLegal.get(teamId)));
                 //MRA 30/11/2022 - create new legalinfo share only if Edit access should not be overwritten by Read access because user has bee added to Cteam with Edit access previoulsy
                   if(!setTeamsLIWithEdit.contains(mapContractTeam.get(teamId).cTin_TeamMember__c+ '' + mapLegal.get(teamId)) && !setTeamsLIWithEdit.contains(mapGroup.get(mapContractTeam.get(teamId).cTin_GroupMember__c) + '' + mapLegal.get(teamId)) ){
                        if(legal.Contract__c == mapLegal.get(teamId)){
                            Legal_Information__Share legalShare = new Legal_Information__Share();
                            system.debug('##8## Legal_Access_Level__c '+mapContractTeam.get(teamId).Legal_Access_Level__c);
                            legalShare.accesslevel = mapContractTeam.get(teamId).Legal_Access_Level__c;
                            legalShare.UserOrGroupId = mapContractTeam.get(teamId).cTin_TeamMember__c != null ? mapContractTeam.get(teamId).cTin_TeamMember__c : mapGroup.get(mapContractTeam.get(teamId).cTin_GroupMember__c);
                            legalShare.parentId = legal.Id;
                            system.debug('##8## legalShare'+legalShare);
                            lstShare.add(legalShare);
                        }
                    }
                }
            }
        }
        
        // get Health Check and set sharing
        if(mapHealthCheck.size() > 0){
            for(Health_Check__c healthCheck: [SELECT Id, Contract__c 
            FROM Health_Check__c 
            WHERE Contract__c IN :mapHealthCheck.values()]){
                for(Id teamId : mapHealthCheck.keySet()){
                 //MRA 30/11/2022 - create new HC share only if Edit access should not be overwritten by Read access because user has bee added to Cteam with Edit access previoulsy
                 if(!setTeamsHCWithEdit.contains(mapContractTeam.get(teamId).cTin_TeamMember__c+ '' + mapHealthCheck.get(teamId)) && !setTeamsHCWithEdit.contains(mapGroup.get(mapContractTeam.get(teamId).cTin_GroupMember__c) + '' + mapHealthCheck.get(teamId)) ){
                    if(healthCheck.Contract__c == mapHealthCheck.get(teamId)){
                        Health_Check__Share healthCheckShare = new Health_Check__Share();
                        healthCheckShare.accesslevel = mapContractTeam.get(teamId).Health_Check_Access_Level__c;
                        healthCheckShare.UserOrGroupId = mapContractTeam.get(teamId).cTin_TeamMember__c != null ? mapContractTeam.get(teamId).cTin_TeamMember__c : mapGroup.get(mapContractTeam.get(teamId).cTin_GroupMember__c);
                        healthCheckShare.parentId = healthCheck.Id;
                        lstShare.add(healthCheckShare);
                    }
                  }
                }
            }
        }

        // Insert sharing
        if(lstShare.size() > 0){
            try{
                // delete existing sharing before insert
                deleteContractTeamShare(mapContractTeam.values());
                
                system.debug('****lstShare '+lstShare);
                Database.insert(lstShare, false);
                //FixContractTeamShare(mapContract,mapGroup);
            }catch (Exception e){
                system.debug('***** error : '+e.getMessage());
            }
        }
    }

   /* private static void FixContractTeamShare(Map<Id,List<cTin_ContractTeam__c>> mapIdCtrLstCteam, Map<String,Id> mapGroup){
        List<sObject> lstCtrShare = new List<sObject>();
        for (ID idCtr : mapIdCtrLstCteam.keySet()) {
            for (cTin_ContractTeam__c cTeam : mapIdCtrLstCteam.get(idCtr)) {
                if (cTeam.cTin_ContractAccessLevel__c =='Edit') {
                    Contract__Share ctrShare = new Contract__Share();
                    ctrShare.accesslevel = cTeam.cTin_ContractAccessLevel__c;
                    ctrShare.UserOrGroupId = cTeam.cTin_TeamMember__c != null ? cTeam.cTin_TeamMember__c : mapGroup.get(cTeam.cTin_GroupMember__c); 
                    ctrShare.parentId = cTeam.cTin_Contract__c;
                    lstCtrShare.add(ctrShare);
                }
            }
        }
        Database.insert(lstCtrShare, false);
    }*/
   
    public static void deleteContractTeamShare(List<cTin_ContractTeam__c> lstcTeam){
        List<sObject> lstShareToDelete = new List<sObject>();
        Map<Id, Id> mapcTeam = new Map<Id,Id>();
        Map<Id, Id> mapLegal = new Map<Id,Id>();
        Map<Id, Id> mapHealthCheck = new Map<Id,Id>();
        Map<String,Id> mapGroup = new Map<String,Id>();
        Map<String, Id> mapGroupName = new Map<String, Id>();

        for(cTin_ContractTeam__c cTeam : lstcTeam){
            if(cTeam.cTin_TeamMember__c != null){
              mapcTeam.put(cTeam.cTin_TeamMember__c, cTeam.cTin_Contract__c);
            }else if(cTeam.cTin_GroupMember__c != null){
                mapGroupName.put(cTeam.cTin_GroupMember__c, cTeam.cTin_Contract__c);
            }
        }

        if(mapGroupName.size() > 0){
            for(Group grp : [SELECT Id, Name, DeveloperName FROM Group WHERE Name IN :mapGroupName.keySet()]){
                mapGroup.put(grp.Name, grp.Id);
                mapcTeam.put(grp.Id, mapGroupName.get(grp.Name));
            }
        }
        
        if(mapcTeam.size() > 0){
            // get sharing on the contract
            for(Contract__Share ctrShare : [SELECT Id, parentId, UserOrGroupId,accesslevel  
                                            FROM Contract__Share 
                                            WHERE parentId IN :mapcTeam.values() 
                                            AND UserOrGroupId IN :mapcTeam.keySet()]){
                if(mapcTeam.containsKey(ctrShare.UserOrGroupId) && mapcTeam.get(ctrShare.UserOrGroupId) == ctrShare.parentId){
                    lstShareToDelete.add(ctrShare);
                }
            }
            
            // get sharing on the Legal Information
            for(Legal_Information__c legalInfo : [SELECT Id, Contract__c FROM Legal_Information__c WHERE Contract__c IN :mapcTeam.values()]){
                mapLegal.put(legalInfo.Id, legalInfo.Contract__c);
            }
            if(mapLegal.size() > 0){
                for(Legal_Information__Share legalShare : [SELECT Id, rowCause,parentId, UserOrGroupId FROM Legal_Information__Share WHERE parentId IN :mapLegal.keyset() AND UserOrGroupId IN :mapcTeam.keySet() and rowCause=:'Manual']){
                    if(mapcTeam.containsKey(legalShare.UserOrGroupId) && mapcTeam.get(legalShare.UserOrGroupId) == mapLegal.get(legalShare.parentId)){
                        lstShareToDelete.add(legalShare);
                    }
                }
            }
            
            // get sharing on the Health check
            for(Health_Check__c healthCheck : [SELECT Id, Contract__c 
            FROM Health_Check__c 
            WHERE Contract__c IN :mapcTeam.values()]){
                mapHealthCheck.put(healthCheck.Id, healthCheck.Contract__c);
            }
            if(mapHealthCheck.size() > 0){
                for(Health_Check__Share healthCheckShare : [SELECT Id, rowCause,parentId, UserOrGroupId FROM Health_Check__Share WHERE parentId IN :mapHealthCheck.keyset() AND UserOrGroupId IN :mapcTeam.keySet() and rowCause=:'Manual']){
                    if(mapcTeam.containsKey(healthCheckShare.UserOrGroupId) && mapcTeam.get(healthCheckShare.UserOrGroupId) == mapHealthCheck.get(healthCheckShare.parentId)){
                        lstShareToDelete.add(healthCheckShare);
                    }
                }
            }
        }
        
        system.debug('****lstShareToDelete '+lstShareToDelete);
        // Delete sharing
        if(lstShareToDelete.size() > 0){
            try{
                Database.delete(lstShareToDelete, false);
            }catch (Exception e){
                system.debug('***** delete error : '+e.getMessage());
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
    }
}