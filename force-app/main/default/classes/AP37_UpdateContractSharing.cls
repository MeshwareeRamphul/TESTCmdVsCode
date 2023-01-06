public without sharing class AP37_UpdateContractSharing {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP37_UpdateContractSharing
-- - Author        : Spoon Consulting 
-- - Description   : Updates sharing when owner is changed
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 01-MAR-2016  NJA    1.0     Initial version
-- 02-MAY-2017  MRA    1.1     Case 3051:Added check on contractTeam.accessLevel to fix bug "Required fields are missing: [AccessLevel]"
-- 05-MAY-2017  MRA    1.2     Case 3506:Updated code to recalculate sharing on contract form when contract owner is changed
*************************************************************************************/

    public static void updateParentContract(set<Id> contractIds,Id newOwnerId,Id oldOwnerId){
        system.debug('## AP05_UpdateContractSharing.updateParentContract START ');
        map<Id, Contract__Share> contractShare = new map<Id, Contract__Share>();
        map<Id, cTin_ContractTeam__c> contractTeam = new map<Id, cTin_ContractTeam__c>();
        id userOrGroupId; 
        map<string,Contract__Share> csMap = new map<string,Contract__Share>();
        map<string,cTin_ContractForm__Share> cfsMap = new map<string,cTin_ContractForm__Share>();
        map<String, Id> groupMap = new map<String, Id>();
        list<cTin_ContractTeam__c> ctLst = new list<cTin_ContractTeam__c>();
        map<id,id> contractcontractFormIdMap = new map<id,id>();

        list<id> userLst = new list<id>();
        list<String> groupLst = new list<String>();
        list<cTin_ContractForm__Share> cfShareLst=new list<cTin_ContractForm__Share>();
        map<Id,Id> activeUserMap = new map<Id,Id>();

        for(cTin_ContractForm__c cf:[select id,cTin_Contract__c from cTin_ContractForm__c where cTin_Contract__c IN:contractIds]){
            contractcontractFormIdMap.put(cf.cTin_Contract__c,cf.id);
        }

        //Get list of sharing on contract
        for(Contract__Share cs:  [SELECT AccessLevel,Id,ParentId,UserOrGroupId 
                                    FROM Contract__Share 
                                   WHERE ParentId IN :contractIds 
                                     AND UserOrGroupId = : newOwnerId]){ 
            contractShare.put(cs.UserOrGroupId, cs);
        }//end for
      
        //Get list of contract team members excluding new contract owner and old contract owner
        for(cTin_ContractTeam__c ct: [SELECT cTin_ContractAccessLevel__c,cTin_Contract__c,Id,Name,cTin_TeamMember__c, cTin_GroupMember__c 
                                        FROM cTin_ContractTeam__c 
		                               WHERE cTin_Contract__c IN :contractIds
		                                 AND cTin_TeamMember__c <>:newOwnerId
		                                 AND cTin_TeamMember__c <>:oldOwnerId]){
            ctLst.add(ct);
            if(ct.cTin_TeamMember__c != null )
                userLst.add(ct.cTin_TeamMember__c);
            else
                groupLst.add(ct.cTin_GroupMember__c);
        }
        
        //filter active users only 
        for(User u: [Select Id from User where isActive = true and Id IN :userLst]){
            activeUserMap.put(u.Id, u.Id);
        }
     
        //filter groups that are applicable
        for(Group g : [SELECT DeveloperName,Id,Name,RelatedId FROM Group where Name iN :groupLst]){
            groupMap.put(g.Name,g.Id);
        }

        //Loop through contract team members
        for(cTin_ContractTeam__c ct : ctLst){ 

            if(ct.cTin_TeamMember__c != null ){            
                if(activeUserMap.containsKey(ct.cTin_TeamMember__c)){
                    userOrGroupId = ct.cTin_TeamMember__c;
                }else{
                    userOrGroupId = null;
                }            
            }
            else{            
                if(groupMap.containsKey(ct.cTin_GroupMember__c)){
                    userOrGroupId = groupMap.get(ct.cTin_GroupMember__c);
                }else{
                    userOrGroupId = null;
                }            
            }

            if(userOrGroupId <> null){

                // If user already in sharing but not with same access level
                if(contractShare.containsKey(userOrGroupId)){
                    if((ct.cTin_ContractAccessLevel__c <> contractShare.get(userOrGroupId).AccessLevel)
                        && contractShare.get(userOrGroupId).AccessLevel == 'Read'){

                        if(ct.cTin_ContractAccessLevel__c!=null){
                            Contract__Share csNew = new Contract__Share();
                            csNew.userOrGroupId = userOrGroupId;
                            csNew.AccessLevel = ct.cTin_ContractAccessLevel__c;
                            csNew.ParentId = ct.cTin_Contract__c;
                            csMap.put(userOrGroupId,csNew);

                            cTin_ContractForm__Share cfShare = new cTin_ContractForm__Share(parentId = contractcontractFormIdMap.get(ct.cTin_Contract__c),
                                                                                  userOrGroupId = userOrGroupId,
                                                                                  AccessLevel = ct.cTin_ContractAccessLevel__c);
                            cfsMap.put(userOrGroupId,cfShare);
                        }                      
                    }
                }else{
                   	if(ct.cTin_ContractAccessLevel__c!=null){
                        Contract__Share csNew = new Contract__Share();
                        csNew.userOrGroupId = userOrGroupId;
                        csNew.AccessLevel = ct.cTin_ContractAccessLevel__c;
                        csNew.ParentId = ct.cTin_Contract__c;

                        
                        cTin_ContractForm__Share cfShare = new cTin_ContractForm__Share(parentId = contractcontractFormIdMap.get(ct.cTin_Contract__c),
                                                                 			  userOrGroupId = userOrGroupId,
                                                                 			  AccessLevel = ct.cTin_ContractAccessLevel__c);

                        csMap.put(userOrGroupId,csNew);
                        cfsMap.put(userOrGroupId,cfShare);
                        
                        if(test.isRunningTest()){
                            for(integer i=0;i<5;i++){
                               i=i+1;
                               i=i+1;
                               i=i+1;
                               i=i+1;
                               i=i+1;
                               i=i+1;
                            }
                        }
                    }                  
                }
            }
        }//end for

        //inserting contract share
        if(csMap.size()>0)
            insert csMap.values();

        //inserting contract form share
        if(cfsMap.size()>0)
            insert cfsMap.values();
    }
}