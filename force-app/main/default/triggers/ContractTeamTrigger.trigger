trigger ContractTeamTrigger on cTin_ContractTeam__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  /* 
  --------------------------------------------------------------------------------------
  -- - Name          : ContractTeamTrigger
  -- - Author        : Team Kerensen (Initial author of AXA Contract-In trigger)
  -- - Description   : Trigger on Contract Team
  --
  -- Maintenance History: 
  --
  -- Date         Name  Version  Remarks 
  -- -----------  ----  -------  -------------------------------------------------------
  -- 10-OCT-2017  MRA    1.0     Initial version 
                                Reworked to reference correct fields - Merge All In + contract In
  
  -- 24-MAR-2020  MRA    1.1     Block creation of contract team 
                                if approval order is specified and 
                                no pdf with "send for signature" checked is available on ctr.
                                (REF: SP-00214 - UAT Support)
  -- 08-APR-2020  MRA    1.2     SP-00190 : Allow team members to be edited => regenerate sharing on update + update "Approval section" on contract form when order/user/role on cteam changes
  -- 16-MAR-2021  ARA    1.3     SP-01222 - Correction of bug (Sharing not generated on ContractForm for BO)
  *************************************************************************************/
  
  Set<Id> setContractIds = new Set<Id>();
  list<cTin_ContractTeam__c > lstCteam=new list<cTin_ContractTeam__c >();
  
  //AP44
  list<cTin_ContractTeam__c > lstCteams=new list<cTin_ContractTeam__c >();
  
  Set<Id> setConIds = new Set<Id>();
  list<cTin_ContractTeam__c > lstTeam=new list<cTin_ContractTeam__c >();
  set<string> setOrder=new set<string>();
  
  
  //before triggers
  if(PAD.canTrigger('AP1012')){
    
    //before triggers
    if(Trigger.isBefore){  
        //start before insert
        if(Trigger.isInsert){ 
        system.debug('## starting before insert trigger');   
          for(Integer i=0; i<trigger.new.size();i++){
            if(trigger.new[i].cTin_ApprovalOrder__c<>'Not in Approval Process'){
                setConIds.add(trigger.new[i].cTin_Contract__c);
                lstTeam.add(trigger.new[i]);
                setOrder.add(trigger.new[i].cTin_ApprovalOrder__c);
            }  
            if(trigger.new[i].cTin_ApprovalOrder__c<>'Not in Approval Process' 
                && (!LC34_AmendContract.allowClone && !LC32_CloneContract.allowClone 
                && !LC35_TransactContract.allowClone) ){
                lstCteams.add(trigger.new[i]);
            }
        }
          
        // MRA - to uncomment after deployment in Prod if(PAD.canTrigger('AP44')){
        for(Integer i=0; i<trigger.new.size();i++){
          if(trigger.new[i].cTin_ApprovalOrder__c<>'Not in Approval Process' && (!LC34_AmendContract.allowClone && !LC32_CloneContract.allowClone && !LC35_TransactContract.allowClone) )
            AP44_BlockNewContractTeam.blockCreationCt(trigger.new);  
        }
        
        if(PAD.canTrigger('AP44')){   
          if(lstCteams.size()>0)    
            AP44_BlockNewContractTeam.blockCreationCt(lstCteams);
        }
        
        if(PAD.canTrigger('AP40')){
          AP40_SharingContractTeam.Init(trigger.new, 'beforeinsert');
        }
        
        if(setConIds.size()>0){
          AP46_RecalculateCTOrder.blockInsert(setConIds,lstTeam,setOrder);
        }
      }
        //end before insert
        
      //start before update         
      if(Trigger.isUpdate){ 
        system.debug('## starting before update trigger');    
        if(PAD.canTrigger('AP44')){
          for(Integer i=0; i<trigger.new.size();i++){
            if(trigger.new[i].cTin_ApprovalOrder__c<>'Not in Approval Process' 
              && (!LC34_AmendContract.allowClone && !LC32_CloneContract.allowClone && !LC35_TransactContract.allowClone) )
              lstCteams.add(trigger.new[i]);
          }
        }
          
        if(PAD.canTrigger('AP44')){
          if(lstCteams.size()>0)
            AP44_BlockNewContractTeam.blockCreationCt(lstCteams);
        }           
      } 
      //end before update 
      
      //start before delete
      if(Trigger.isDelete){ 
        system.debug('## starting before insert trigger');       
          for(Integer i=0; i<trigger.old.size();i++){
            if(trigger.old[i].cTin_ApprovalOrder__c <> 'Not in Approval Process')
              AP46_RecalculateCTOrder.blockDeletion(trigger.old);
          }
          
        if(PAD.canTrigger('AP40')){  
          AP40_SharingContractTeam.Init(trigger.old, 'delete');
        }  
      }
    //  end before delete        
    }      
  }
  //after triggers
  if(PAD.canTrigger('AP1012')){
    if(Trigger.isAfter){
      //start after insert
      if(Trigger.isInsert){
        system.debug('## starting after insert trigger');
        Map<Id,List<cTin_ContractTeam__c>> mapContract = new Map<Id,List<cTin_ContractTeam__c>>();
        List<cTin_ContractTeam__c> lstContractTeam;
        Set<Id> setctrId = new Set<Id>();
        for(Integer i=0; i<trigger.new.size();i++){
          if(trigger.new[i].cTin_ContractParent__c <> null
          && (trigger.new[i].cTin_Role__c == system.label.cTin_role_legal_rep
          || trigger.new[i].cTin_Role__c == system.label.cTin_role_business_owner)){
              setContractIds.add(trigger.new[i].cTin_Contract__c);
          }
          if(!mapContract.containsKey(trigger.new[i].cTin_Contract__c)){
            lstContractTeam = new List<cTin_ContractTeam__c>();
          }else{
            lstContractTeam = mapContract.get(trigger.new[i].cTin_Contract__c);
          }
          lstContractTeam.add(trigger.new[i]);
          mapContract.put(trigger.new[i].cTin_Contract__c,lstContractTeam);
          setctrId.add(trigger.new[i].cTin_Contract__c);
        }
        if(setContractIds.size()>0){          if(PAD.canTrigger('AP33'))           AP33_GrantVisibilityContract.grantAccessToParent(setContractIds);        }
        
        if(PAD.canTrigger('AP40')){          AP40_SharingContractTeam.Init(trigger.new, 'afterinsert');        }
        if(mapContract.size() > 0){
          AP40_ContractTeamManageSharing.calculateSharing(mapContract);
        } 
        
        //14/06/2022 AMA  populate Stakeholder Contract Team Member(ContractTeamMember__c)
        if(setctrId.size() > 0){
          AP72_ManageCTeamListView.setEventContractTeamMember(new Set<ID>(setctrId));
        } 
      }
    }
            
    //MRA 08-APR-2020 : SP-00190 Added call to AP40 to recalcule of sharing when contract team is updated and call to AP46 to reset order on team member
    if(Trigger.isUpdate){ 
      system.debug('## starting after update trigger');
      map<id,string> cTeamOrderMap=new map<id,string>();
      set<id>conIdSet=new set<id>();
      map<id,id>mapOldUserIdCtr=new map<id,id>();
      List<cTin_ContractTeam__c> lstContractTeam;
      Map<Id,List<cTin_ContractTeam__c>> mapContract = new Map<Id,List<cTin_ContractTeam__c>>();
      Set<Id> setctrId = new Set<Id>();
              
      for(Integer i=0; i<trigger.new.size();i++){
        //call method to reset orders of team members : executes only once => assuming that one contract team can be modififed at a time
        if(trigger.new[i].cTin_ApprovalOrder__c!=trigger.old[i].cTin_ApprovalOrder__c && !AP46_RecalculateCTOrder.hasRunResetOndel){
          //AP46_RecalculateCTOrder.resetOrder(trigger.new[i].id,trigger.new[i].cTin_ApprovalOrder__c,trigger.new[i].cTin_Contract__c,trigger.old[i].cTin_ApprovalOrder__c);                   
        }  
            
        //populate set of contact ids => to be able to update aproval section on contract form when approval order of a team changes
        if(trigger.new[i].cTin_ApprovalOrder__c!=trigger.old[i].cTin_ApprovalOrder__c && !AP46_RecalculateCTOrder.hasRunResetOndel){          conIdSet.add(trigger.new[i].cTin_Contract__c);        }
            
        //populate list of contract team => to be able to recalculte sharng for each member when user or role changes
        if((trigger.new[i].cTin_Role__c != trigger.old[i].cTin_Role__c)  ||
          (trigger.new[i].cTin_TeamMember__c != trigger.old[i].cTin_TeamMember__c ) ||
          (trigger.new[i].cTin_GroupMember__c != trigger.old[i].cTin_GroupMember__c ) ){            lstCteam.add(trigger.new[i]);            }
        
        if (trigger.new[i].cTin_TeamMember__c != trigger.old[i].cTin_TeamMember__c )          mapOldUserIdCtr.put(trigger.old[i].cTin_TeamMember__c,trigger.new[i].cTin_Contract__c);

        if((trigger.new[i].cTin_Role__c != trigger.old[i].cTin_Role__c)  ||
        (trigger.new[i].cTin_TeamMember__c != trigger.old[i].cTin_TeamMember__c ) ||
        (trigger.new[i].cTin_GroupMember__c != trigger.old[i].cTin_GroupMember__c )  ||
        (trigger.new[i].cTin_ContractAccessLevel__c != trigger.old[i].cTin_ContractAccessLevel__c )  ||
        (trigger.new[i].Legal_Access_Level__c != trigger.old[i].Legal_Access_Level__c )  ||
        (trigger.new[i].Health_Check_Access_Level__c != trigger.old[i].Health_Check_Access_Level__c ) ){
          if(!mapContract.containsKey(trigger.new[i].cTin_Contract__c)){            lstContractTeam = new List<cTin_ContractTeam__c>();          }else{            lstContractTeam = mapContract.get(trigger.new[i].cTin_Contract__c);          }
          lstContractTeam.add(trigger.new[i]);
          mapContract.put(trigger.new[i].cTin_Contract__c,lstContractTeam);
        }
        setctrId.add(trigger.new[i].cTin_Contract__c);
      }
              
      // map order of approval on contract form
      if(conIdSet.size()>0 )        AP46_RecalculateCTOrder.updateCf(conIdSet);
    
      // regenerate sharing for each team member after update
      if(lstCteam.size()>0)        AP40_SharingContractTeam.Init(lstCteam, 'afterinsert');
    
      //delete contract share after delete of a team member
      if(mapOldUserIdCtr.size()>0)        AP46_RecalculateCTOrder.deleteContractshare(mapOldUserIdCtr);

      // 16-03-2021   ARA    SP-01222 (Added afterupdate condition)
      if(PAD.canTrigger('AP40'))        AP40_SharingContractTeam.Init(trigger.new, 'afterupdate');
       
      if(mapContract.size() > 0)        AP40_ContractTeamManageSharing.calculateSharing(mapContract);
       
      
      //14/06/2022 AMA  populate Stakeholder Contract Team Member(ContractTeamMember__c)
      if(setctrId.size() > 0){
        AP72_ManageCTeamListView.setEventContractTeamMember(new Set<ID>(setctrId));
      }
    }
        
    if(Trigger.isDelete){
      set<id>conIdSetDel=new set<id>();
      List<cTin_ContractTeam__c> lstContractTeam;
      Map<Id,List<cTin_ContractTeam__c>> mapContract = new Map<Id,List<cTin_ContractTeam__c>>();
      Set<Id> setctrId = new Set<Id>();

      system.debug('##starting after delete trigger');
      for(Integer i=0; i<trigger.old.size();i++){
          if(trigger.old[i].cTin_ApprovalOrder__c!='Not in Approval Process' && !AP46_RecalculateCTOrder.hasRunResetOndel){
          	AP46_RecalculateCTOrder.resetOrderOnDel(trigger.old[i].id,trigger.old[i].cTin_Contract__c,trigger.old[i].cTin_ApprovalOrder__c);   
         	conIdSetDel.add(trigger.old[i].cTin_Contract__c);
          }
        
        /*if(!mapContract.containsKey(trigger.old[i].cTin_Contract__c)){
          lstContractTeam = new List<cTin_ContractTeam__c>();
        }else{
          lstContractTeam = mapContract.get(trigger.old[i].cTin_Contract__c);
        }
        lstContractTeam.add(trigger.old[i]);
        mapContract.put(trigger.old[i].cTin_Contract__c,lstContractTeam);*/
        setctrId.add(trigger.old[i].cTin_Contract__c);
      }
      
      // map order of approval on contract form
      if(conIdSetDel.size()>0 )
        AP46_RecalculateCTOrder.updateCf(conIdSetDel);

      //AP40_ContractTeamManageSharing.deleteContractTeamShare(trigger.old);
      
      //if(mapContract.size() > 0){
        //AP40_ContractTeamManageSharing.calculateSharing(mapContract);
        AP40_ContractTeamManageSharing.deleteContractTeamShare(trigger.old);
      //} 

      //14/06/2022 AMA  populate Stakeholder Contract Team Member(ContractTeamMember__c)
      if(setctrId.size() > 0){
        AP72_ManageCTeamListView.setEventContractTeamMember(new Set<ID>(setctrId));
      }
    } 
  }//end pad
}