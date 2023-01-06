public without sharing class AP33_GrantVisibilityContract {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : AP33_GrantVisibilityContract
-- - Author        : Spoon Consulting 
-- - Description   : Grant visibility to Parent Contract
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 24-DEC-2015  NJA    1.0     Initial version
-- 08-JUL-2016  MRA    1.1     Corrected bug: outbound index
-- 18-OCT-2017  MRA    1.2     Reworked to reference correct fields - Merge All In + contract In
*************************************************************************************/

    public  static void grantAccessToParent(set<Id> contractIds) {
        system.debug('## AP33_GrantVisibilityContract START ');
        //map of key and ContractTeam
        list<cTin_ContractTeam__c> tempContractTeamList = new list<cTin_ContractTeam__c>();
        map<String,cTin_ContractTeam__c> mapKeyContractTeam = new map<String, cTin_ContractTeam__c>();
        map<String,Group> existingGroupMap = new map<String,Group>();
        list<cTin_ContractTeam__c> contractTeamToInsert = new list<cTin_ContractTeam__c>();
        set<Id> parentIds = new set<Id>();
        map<Id, Id> mapContractParent = new map<Id, Id>();
        
        string key;

        system.debug('>### HVA contractIds: '+contractIds);
        
        for(Contract__c c: [Select Id, cTin_ParentContract__c from Contract__c 
                                where cTin_ParentContract__c <> null 
                                and Id IN :contractIds
                               and (Status__c = :AP_Constant.CONTRACT_STATUS_INSIGNATURE
                                or Status__c = :system.label.cTin_AP10_ContractStatusApproval)]){
            mapContractParent.put(c.Id, c.cTin_ParentContract__c); 
            parentIds.add(c.cTin_ParentContract__c);
        }
        system.debug('>### HVA parentIds: '+parentIds);

        if(parentIds.size()>0){
            list<cTin_ContractTeam__c> contractTeamList  = [SELECT Id, cTin_GroupMember__c, cTin_ApprovalOrder__c, 
                                                        cTin_Active__c, cTin_Contract__c, 
                                                        cTin_ContractAccessLevel__c, cTin_Role__c, cTin_TeamMember__c,
                                                        cTin_UniqueApprover__c, cTin_UniqueOrder__c
                                                        FROM cTin_ContractTeam__c 
                                                        WHERE cTin_Contract__c IN :contractIds
                                                        AND (cTin_Role__c = :system.label.cTin_role_business_owner
                                                        OR cTin_Role__c = :system.label.cTin_role_legal_rep)
                                                        Order By cTin_ApprovalOrder__c] ;
            

            list<cTin_ContractTeam__c> parentContractTeamList  = [SELECT Id, cTin_GroupMember__c, cTin_ApprovalOrder__c, 
                                                        cTin_Active__c, cTin_Contract__c, 
                                                        cTin_ContractAccessLevel__c, cTin_Role__c, cTin_TeamMember__c,
                                                        cTin_UniqueApprover__c, cTin_UniqueOrder__c
                                                        FROM cTin_ContractTeam__c 
                                                        WHERE cTin_Contract__c IN :parentIds
                                                        AND (cTin_Role__c = :system.label.cTin_role_business_owner
                                                        OR cTin_Role__c = :system.label.cTin_role_legal_rep)
                                                        Order By cTin_ApprovalOrder__c] ;    

            System.debug('>### HVA contractTeamList: '+contractTeamList);
            System.debug('>### HVA parentContractTeamList: '+parentContractTeamList);

            if(contractTeamList.size()>0){
                tempContractTeamList = contractTeamList.deepClone();
            } 
           
            /*Get all groups*/
            for(Group g :[Select Name , Type from Group]){
                existingGroupMap.put(g.Name, g);
            }

            System.debug('>### HVA existingGroupMap: '+existingGroupMap);
            
            /*Filter all Contract Teams*/   
            for(cTin_ContractTeam__c ct : parentContractTeamList){

                System.debug('>### HVA ct.cTin_GroupMember__c: '+ct.cTin_GroupMember__c);
               
                if(ct.cTin_GroupMember__c != null && ct.cTin_GroupMember__c.trim() != ''){
                    
                    if(existingGroupMap.containsKey(ct.cTin_GroupMember__c)){
                        key = ct.cTin_GroupMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                        system.debug('## key: '+key);
                        mapKeyContractTeam.put(key,ct);
                    }
                }

                if(ct.cTin_TeamMember__c != null) {
                    key = ct.cTin_TeamMember__c;//+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                    system.debug('## key: '+key);
                    mapKeyContractTeam.put(key,ct);
                }
            }//end for

            // Build Contract Team
            for(cTin_ContractTeam__c ct : tempContractTeamList){

                System.debug('>### ct ' + ct);
                
                if(ct.cTin_GroupMember__c != null && ct.cTin_GroupMember__c.trim() != ''){
                    key = ct.cTin_GroupMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                    if(!mapKeyContractTeam.containsKey(key)){
                        cTin_ContractTeam__c new_ct = new cTin_ContractTeam__c();
                        new_ct.cTin_GroupMember__c = ct.cTin_GroupMember__c;
                        new_ct.cTin_TeamMember__c = null;
                        new_ct.cTin_Role__c = ct.cTin_Role__c;
                        new_ct.cTin_Contract__c = mapContractParent.get(ct.cTin_Contract__c); 
                        new_ct.cTin_ContractAccessLevel__c = ct.cTin_ContractAccessLevel__c;
                        new_ct.cTin_Active__c= ct.cTin_Active__c; 
                        //new_ct.cTin_ApprovalOrder__c = ct.cTin_ApprovalOrder__c;
                        //new_ct.UniqueApprover__c = ct.UniqueApprover__c;
                        //new_ct.UniqueOrder__c = ct.UniqueOrder__c;
                        contractTeamToInsert.add(new_ct);
                    }


                }else if(ct.cTin_TeamMember__c != null){
                    key = ct.cTin_TeamMember__c;//+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                    if(!mapKeyContractTeam.containsKey(key)){
                        cTin_ContractTeam__c new_ct = new cTin_ContractTeam__c();
                        new_ct.cTin_TeamMember__c = ct.cTin_TeamMember__c;
                        new_ct.cTin_GroupMember__c = null;
                        new_ct.cTin_Role__c = ct.cTin_Role__c;
                        new_ct.cTin_ContractAccessLevel__c = ct.cTin_ContractAccessLevel__c;
                        new_ct.cTin_Active__c= ct.cTin_Active__c; 
                        new_ct.cTin_Contract__c = mapContractParent.get(ct.cTin_Contract__c);
                        //new_ct.cTin_ApprovalOrder__c = ct.cTin_ApprovalOrder__c; 
                        //new_ct.UniqueApprover__c = ct.UniqueApprover__c;
                        //new_ct.UniqueOrder__c = ct.UniqueOrder__c;
                        contractTeamToInsert.add(new_ct);
                    }
                }
            }

            if(contractTeamToInsert.size()>0){
               try{ insert contractTeamToInsert; } catch(Exception e){}
            }
        }// End if
        
        system.debug('## AP33_GrantVisibilityContract END ');
    }
}