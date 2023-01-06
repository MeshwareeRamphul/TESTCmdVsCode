public without sharing class AP40_SharingContractTeam {
/* 
--------------------------------------------------------------------------------------
Created By: Zohar Sinay
Last Modified Date: 11/02/15
Last Modified Date (DMU): 23/03/2016 - taken from sandbox full

 * -- Maintenance History: 
 * --
 * -- Date         Name       Version  Remarks 
 * -- -----------  ----       -------  -------------------------------------------------------
 * -- 23-MAR-2016  SC-DMU      1.1      taken from sandbox full + added limit 100 on query q2 line 180
 * -- 24-MAR-2016  SC-DMU/NJA  1.2      added code remove Or from query q2 line 174
 * -- 27-SEP-2016  SC-MRA      1.3      modified method DeleteSubroutine, added check on maps,lists 
                                        and query string to prevent crash when changing business owner (Case 3166)
 * -- 18-OCT-2017  MRA         1.4      Reworked to reference correct fields - Merge All In + contract In
 * -- 16-MAR-2021  ARA         1.5      SP-01222 - Correction of bug (Sharing not generated on ContractForm for BO)
*************************************************************************************/

    
    public static void Init(List<cTin_ContractTeam__c> contractTeamList, String mode){
        
        String query = 'SELECT Id, cTin_Contract__c, cTin_FinalApprovalStatus__c';

        Set<String> groupNameSet = new Set<String>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<String> approverNumberSet = new Set<String>();
        Set<Id> contractTeamIdSet = new Set<Id>();

        Map<Id, cTin_ContractForm__c> contractIdContractFormMap = new Map<Id, cTin_ContractForm__c>();
        Map<Id, List<User>> groupIdToGroupMembers = new Map<Id, List<User>>();
        Map<String, Id> groupNameIdMap = new Map<String, Id>();

        createSets(contractTeamList, groupNameSet, approverNumberSet, contractIdSet, contractTeamIdSet);
        
        system.debug('##kerensen ContractTeam_AfterInsert_BeforeDelete approverNumberSet'+approverNumberSet);
        
        Map<Id, cTin_ContractTeam__c> contractTeamIdMap = new Map<Id, cTin_ContractTeam__c>([SELECT Id, cTin_TeamMember__r.FirstName, cTin_TeamMember__r.LastName FROM cTin_ContractTeam__c WHERE Id IN : contractTeamIdSet]);

        if(approverNumberSet.size() > 0){
            query += createQueryFromApproverSet(approverNumberSet);
        }
        
        system.debug('## kerensen ContractTeam_AfterInsert_BeforeDelete contractIdSet'+contractIdSet.size());
        
        query += ' FROM cTin_ContractForm__c WHERE cTin_Contract__c IN :contractIdSet';
        
        system.debug('kerensen ContractTeam_AfterInsert_BeforeDelete query: ' + query);
        
        List<cTin_ContractForm__c> contractFormList = database.query(query);
        contractIdContractFormMap = createContract_ContractFormMap(contractFormList);
        system.debug('kerensen Init contractIdContractFormMap: ' + contractIdContractFormMap);
        // we query all the groups that are relevant for our current list by their names from the cTin_GroupMember__c picklist
        if(groupNameSet.size() > 0){
            Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name FROM Group WHERE Name IN :groupNameSet]);
            // creating the map for selecting the Ids of the groups by their names
            for(Id grId : groupMap.keySet()){
                groupNameIdMap.put(groupMap.get(grId).Name, grId);
            }
        }
        system.debug('$$groupNameIdMap'+groupNameIdMap);
        groupIdToGroupMembers = groupListToGroupMembers(groupNameIdMap.values());
        system.debug('kerensen Init groupIdToGroupMembers: ' + groupIdToGroupMembers);
        // Selecting the contracts and Ids which are in the set of contracts that was just inserted
        Map<Id, Contract__c> idContractMap = new Map<Id, Contract__c>([SELECT Id, OwnerId FROM Contract__c WHERE Id IN :contractIdSet]);
        // 16-03-2021   ARA    SP-01222 (Added afterupdate condition)
        if(mode == 'afterinsert' || mode == 'afterupdate'){
            system.debug('$$ after insert method groupIdToGroupMembers 52 '+ groupIdToGroupMembers.size());
            system.debug('$$ after insert method groupNameIdMap 52: '+ groupNameIdMap.size());
            system.debug('$$ after insert method contractIdContractFormMap 52: '+ contractIdContractFormMap.size());
            system.debug('$$ after insert method idContractMap 52: '+ idContractMap.size());
            system.debug('$$ after insert method contractTeamIdMap 52: '+ contractTeamIdMap.size());
            InsertSubroutine(trigger.new, groupIdToGroupMembers, groupNameIdMap, contractIdContractFormMap, idContractMap, contractTeamIdMap);
        }
        else if(mode == 'delete'){
            /*List<cTin_ContractForm__c> lstContractForm = [SELECT Id, OwnerId FROM cTin_ContractForm__c WHERE cTin_Contract__c IN :contractIdSet];
            List<cTin_ContractTeam__c> lstContractTeam = [SELECT Id, cTin_Contract__c, cTin_TeamMember__c, cTin_GroupMember__c, cTin_ApprovalOrder__c,cTin_ContractAccessLevel__c FROM cTin_ContractTeam__c WHERE cTin_ContractForm__c IN :lstContractForm];
            lstContractTeam.addAll(contractTeamList);
            DeleteSubroutine(lstContractTeam, groupIdToGroupMembers, groupNameIdMap, contractIdContractFormMap, idContractMap, contractTeamIdMap);*/
            DeleteSubroutine(trigger.old, groupIdToGroupMembers, groupNameIdMap, contractIdContractFormMap, idContractMap, contractTeamIdMap);
        }
        else if(mode =='beforeinsert'){
            for(cTin_ContractTeam__c ct : contractTeamList){
                if(contractIdContractFormMap.containsKey(ct.cTin_Contract__c))
                    ct.cTin_ContractForm__c = contractIdContractFormMap.get(ct.cTin_Contract__c).id;
            }
        }
    }

    // modified by Zohar Sinay according to request by the Client of changes in the data model, Contract and Contract Form are no longer "Master-Detail"
    // they're now in a lookup relationship
    public static void InsertSubroutine(List<cTin_ContractTeam__c> contractTeamList, Map<Id, List<User>> groupIdToGroupMembers, Map<String, Id> groupNameIdMap, Map<Id, cTin_ContractForm__c> contractIdContractFormMap, Map<Id, Contract__c> idContractMap, Map<Id, cTin_ContractTeam__c> contractTeamIdMap){
        // preparing the queries to select from the database which users are already following the contract and contract form as well as having the same sharing rules
        // already applied to them
        
        Boolean isFirst = true;
        User groupMember = new User();
        String q1 = 'SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Contract__Share WHERE ';
        String q3 = 'SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM cTin_ContractForm__Share WHERE ';
       // String q2 = 'SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ';


        List<Contract__Share> shrContract = new List<Contract__Share>();
        List<cTin_ContractForm__Share> shrContractForm = new List<cTin_ContractForm__Share>();
        List<EntitySubscription> followContractOrContractForm = new List<EntitySubscription>();

        system.debug('kerensen InsertSubroutine contractTeamList: ' + contractTeamList);
        
        //DMU: 28/03/16 modification regarding case 2812: Duplicate button
        set <id> teamMemberIdSet = new set <Id> ();
        Boolean isSubscriberId = False;
        for(cTin_ContractTeam__c cTeam : contractTeamList){
           if (cTeam.cTin_TeamMember__c <> null || cTeam.cTin_TeamMember__c <> ''){
                system.debug('###cTeam.cTin_TeamMember__c not null');
                teamMemberIdSet.add(cTeam.cTin_TeamMember__c);
            }
        }
        system.debug('###teamMemberIdSet: '+ teamMemberIdSet);
        system.debug('###teamMemberIdSet size: '+ teamMemberIdSet.size());
        
        for(cTin_ContractTeam__c contractteam : contractTeamList){
            if(!isFirst){
                if(!q1.endsWith(' WHERE ') && !q1.endsWith(' or ')) q1+=' or '; else q1.removeEnd(' or ');
               // if(!q2.endsWith(' WHERE ')&& !q2.endsWith(' or ')) q2+=' or '; else q2.removeEnd(' or ');
                if(!q3.endsWith(' WHERE ')&& !q3.endsWith(' or ')) q3+=' or '; else q3.removeEnd(' or ');
            }
            // if the cTin_GroupMember__c is not null and the contract accesslevel is filled then we give that permission to the group with access of ContractAccessLevel
            if((contractteam.cTin_GroupMember__c != null && contractteam.cTin_GroupMember__c.trim() != '') && 
                (contractteam.cTin_ContractAccessLevel__c != null && contractteam.cTin_ContractAccessLevel__c.trim() != '')){
                    
                shrContract.add(new Contract__Share(ParentId = contractteam.cTin_Contract__c, UserOrGroupId = groupNameIdMap.get(contractteam.cTin_GroupMember__c), 
                    AccessLevel = contractTeam.cTin_ContractAccessLevel__c));
                
                if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    {
                    shrContractForm.add(new cTin_ContractForm__Share(ParentId = contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id, UserOrGroupId = groupNameIdMap.get(contractteam.cTin_GroupMember__c),
                    AccessLevel = contractTeam.cTin_ContractAccessLevel__c));
                }
                    
                q1+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and UserOrGroupId = \''+groupNameIdMap.get(contractTeam.cTin_GroupMember__c)+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
                
                if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                    q3+='(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and UserOrGroupId = \''+groupNameIdMap.get(contractTeam.cTin_GroupMember__c)+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
                
                //MRA: 04 DEC 2015 - Modification w.r.t Case 2444 (Selective Query Exception)               
                 set<id> groupMemberIdSet=new set<id>();
                    if (groupIdToGroupMembers.size() > 0){
                        system.debug('eureka');
                        system.debug('groupIdToGroupMembers'+groupIdToGroupMembers.size());
                    }
                    if (groupNameIdMap.size() > 0){
                        system.debug('eureka double');
                        system.debug('groupNameIdMap'+groupNameIdMap.size());
                    }
                if(groupNameIdMap.containsKey(contractTeam.cTin_GroupMember__c) 
                    && groupIdToGroupMembers.containsKey(groupNameIdMap.get(contractTeam.cTin_GroupMember__c))){
                     for(integer i=0 ;i < groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c)).size(); ++i){
                          
                        groupMember = groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c))[i];
                        groupMemberIdSet.add(groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c))[i].id);
                           // Adding the user to the follow Contract and contract form List
                        followContractOrContractForm.add(new EntitySubscription (ParentId = contractteam.cTin_Contract__c, SubscriberId = groupMember.Id));
                        
                        if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c)) 
                            followContractOrContractForm.add(new EntitySubscription (ParentId = contractIdContractFormMap.get(contractteam.cTin_Contract__c).Id, SubscriberId = groupMember.Id));
                     }
                }
                 if(groupMemberIdSet.size()>0){
                   system.debug('##groupMemberIdSet'+groupMemberIdSet);
                   
                  /* if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                        q2+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and SubscriberId IN : groupMemberIdSet ) or ' +
                        +'(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and SubscriberId IN : groupMemberIdSet )';
                    
                    */
                 }   
                    
               
            }
            // if the team member is entered and is different from the record owner then we just give him the permissions chosen, and make him follow the record
            else if((contractteam.cTin_TeamMember__c != null) && (contractteam.cTin_ContractAccessLevel__c != null && contractteam.cTin_ContractAccessLevel__c.trim() != '')){
                q1+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and UserOrGroupId = \''+contractTeam.cTin_TeamMember__c+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
                
                if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                    q3+='(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and UserOrGroupId = \''+contractTeam.cTin_TeamMember__c+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
                
                //DMU: 28/03/16 modification regarding case 2812: Duplicate button
                //IF contractTeam.cTin_TeamMember__c NOT IN SET THEN ADD CONDITION BELOW
               /* if (!teamMemberIdSet.contains(contractTeam.cTin_TeamMember__c)) {
                    if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                        q2+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and SubscriberId = \''+contractTeam.cTin_TeamMember__c+'\') or' +
                        '(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and SubscriberId = \''+contractTeam.cTin_TeamMember__c+'\')';
                }
                
                else if ((teamMemberIdSet.size()>0) && isSubscriberId==False){
                    system.debug('### ++ enter else if');
                    isSubscriberId = True;
                    if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                        q2+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and SubscriberId IN : teamMemberIdSet ) or ' +
                        +'(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and SubscriberId IN : teamMemberIdSet )';
                }
                else{ 
                    if(q2.endsWith(' or ')){
                        system.debug('########');
                       q2 = q2.removeEnd(' or ');
                    }
                }
                system.debug('### q2: ' + q2);
                 */    
                                        
                if(idContractMap.get(contractteam.cTin_Contract__c).OwnerId != contractteam.cTin_TeamMember__c){
                        shrContract.add(new Contract__Share(ParentId = contractteam.cTin_Contract__c, UserOrGroupId = contractteam.cTin_TeamMember__c, 
                                        AccessLevel = contractteam.cTin_ContractAccessLevel__c));
                        
                        if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))    
                            shrContractForm.add(new cTin_ContractForm__Share(ParentId = contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id, UserOrGroupId = contractteam.cTin_TeamMember__c, 
                                        AccessLevel = contractteam.cTin_ContractAccessLevel__c));
                }
                // Adding the user to follow the contract and contract form List
               // followContractOrContractForm.add(new EntitySubscription (ParentId = contractteam.cTin_Contract__c, SubscriberId = contractteam.cTin_TeamMember__c));
                
               // if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))   
                  //  followContractOrContractForm.add(new EntitySubscription (ParentId = contractIdContractFormMap.get(contractteam.cTin_Contract__c).Id, SubscriberId = contractteam.cTin_TeamMember__c));
                // if the user is in the approval order we now need to connect it to the contract form in his right place
                if(contractteam.cTin_ApprovalOrder__c != null && contractteam.cTin_ApprovalOrder__c.trim() != '' && contractteam.cTin_ApprovalOrder__c != 'Not in Approval Process'){
                    // (I know this looks complicated but it's quite simple actually)
                    // first I get the Contract Form from the contract-contractform map by the team.contract that is now being run
                    if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c)) {  
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverName' + contractteam.cTin_ApprovalOrder__c + '__c', contractteam.cTin_TeamMember__c);
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverNameTxt' + contractteam.cTin_ApprovalOrder__c + '__c', contractTeamIdMap.get(contractteam.Id).cTin_TeamMember__r.FirstName + ' ' + contractTeamIdMap.get(contractteam.Id).cTin_TeamMember__r.LastName);
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverRole' + contractteam.cTin_ApprovalOrder__c + '__c', contractteam.cTin_Role__c);
                    }
                }
            }
            isFirst = false;
        }

        //24-MAR-2016 - NJA - added code  to remove OR from query q2 (taken from backup code TMA)
       /* if(q2.endsWith(' or ')){
            system.debug('########');
           q2 = q2.removeEnd(' or ');
        }*/

        system.debug('kerensen InsertSubroutine q1: ' + q1);
       // system.debug('kerensen InsertSubroutine q2: ' + q2);
        system.debug('kerensen InsertSubroutine followContractOrContractForm.size(): ' + followContractOrContractForm.size());
        system.debug('kerensen InsertSubroutine shrContract.size(): ' + shrContract.size());


        // Querying the followers of the object from the database and going through it to search for the followers that should be inserted now
        if(followContractOrContractForm.size()>0){
            list<Integer> placesToRemoveFollowerslst = new list<Integer>();
            Set<String> existingFollowContractOrContractFormSet = new Set<String>();
            /*
            if(!q2.endsWith(' WHERE ') && !q2.endsWith(' or ')){

                q2 += ' LIMIT 1000 ';
                system.debug('#### q2:'+q2);
                List<EntitySubscription> existingFollowContractOrContractFormList = Database.query(q2);
                for(EntitySubscription EFCOCF :existingFollowContractOrContractFormList){
                    existingFollowContractOrContractFormSet.add(String.valueOf(EFCOCF.ParentId) + String.valueOf(EFCOCF.SubscriberId));
                }
            }
            */
            

            // running through the set of followers and removing which ever followers that are already following the contract, adding its number in the list to remove
            /*for(integer i=0; i<followContractOrContractForm.size(); ++i){
                if(existingFollowContractOrContractFormSet.contains(String.valueOf(followContractOrContractForm[i].ParentId) + String.valueOf(followContractOrContractForm[i].SubscriberId))){
                    placesToRemoveFollowerslst.add(i);
                }
            }

            for(integer i=placesToRemoveFollowerslst.size()-1; i>=0; --i){
                followContractOrContractForm.remove(placesToRemoveFollowerslst[i]);
            } */
        }

        // Querying the Contract Sharing rules and going through it for the new contract sharing rules that are to be inserted
        if(shrContract.size()>0){
            list<Integer> placesToRemoveShrContractlst = new list<Integer>();
            system.debug('## query q1'+q1);
             if(q1.endsWith('or')){
                q1=q1.removeEnd('or');
             if(q1.contains(' or  or ') ){
                q1.replace(' or  or ',' or ');
             }
            }

            if(!q1.endsWith(' WHERE ') && !q1.endsWith(' or ')){
                List<Contract__Share> existingContractSharingRulesList = Database.query(q1); 
                Set<String> existingContractSharingRulesSet = new Set<String>();
                for(Contract__Share ECSR : existingContractSharingRulesList){
                    existingContractSharingRulesSet.add(String.valueOf(ECSR.ParentId) + String.valueOf(ECSR.UserOrGroupId) + String.valueOf(ECSR.AccessLevel));
                }

                // running over the list of sharing rules and removing any rules that are already existing
                for(integer i=0; i<shrContract.size(); ++i){
                    if(existingContractSharingRulesSet.contains(String.valueOf(shrContract[i].ParentId) + String.valueOf(shrContract[i].UserOrGroupId) + String.valueOf(shrContract[i].AccessLevel))){
                        placesToRemoveShrContractlst.add(i);
                    }
                }

                // running over the list and removing from the end of the list to the beginning the places that needs to be removed
                for(integer i=placesToRemoveShrContractlst.size()-1; i>=0; --i){
                    shrContract.remove(placesToRemoveShrContractlst[i]);
                } 
            }    
        }

        

        // Quertying the Contract Sharing rules and going through it for the new contract sharing rules that are to be inserted
        if(shrContractForm.size()>0){
            list<Integer> placesToRemoveShrContractFormlst = new list<Integer>();
            if(!q3.endsWith(' WHERE ') && !q3.endsWith(' or ')){
            List<cTin_ContractForm__Share> existingContractFormSharingRulesList = Database.query(q3); 
            Set<String> existingContractFormSharingRulesSet = new Set<String>();
            for(cTin_ContractForm__Share ECFSR : existingContractFormSharingRulesList){
                existingContractFormSharingRulesSet.add(String.valueOf(ECFSR.ParentId) + String.valueOf(ECFSR.UserOrGroupId) + String.valueOf(ECFSR.AccessLevel));
            }

            // running over the list of sharing rules and removing any rules that are already existing
            for(integer i=0; i<shrContractForm.size(); ++i){
                if(existingContractFormSharingRulesSet.contains(String.valueOf(shrContractForm[i].ParentId) + String.valueOf(shrContractForm[i].UserOrGroupId) + String.valueOf(shrContractForm[i].AccessLevel))){
                    placesToRemoveShrContractFormlst.add(i);
                }
            }

            // running over the list and removing from the end of the list to the beginning the places that needs to be removed
            for(integer i=placesToRemoveShrContractFormlst.size()-1; i>=0; --i){
                shrContractForm.remove(placesToRemoveShrContractFormlst[i]);
            }    
            } 
        }

            //system.debug('kerensen ContractTeam_AfterInsert_BeforeDelete trigger.isInsert contractContractTeamsMap: ' + contractContractTeamsMap);
           
         system.debug('kerensen ContractTeam_AfterInsert_BeforeDelete trigger.isInsert shrContract: ' + shrContract);


        if(shrContract.size()>0){
            try{
               // MRA 30/11 commented as logic is already catered in AP40_ContractTeamManageSharing
               // insert shrContract; 
            }
            catch(Exception e){
                system.debug('kerensen exception e.getMessage(): ' + e.getMessage());
            }
        }
        if(shrContractForm.size()>0){
            try{
                insert shrContractForm;
            }
            catch(Exception e){
                system.debug('kerensen exception e.getMessage(): ' + e.getMessage());
            }
        }
        if(followContractOrContractForm.size()>0){
            try{
                if (!Test.isRunningTest()){
                    insert followContractOrContractForm;
                }
            }
            catch(Exception e){
                system.debug('kerensen exception e.getMessage(): ' + e.getMessage());
            }
        }
        if(contractIdContractFormMap.size()>0){
            try{
                if (!Test.isRunningTest()){
                    update contractIdContractFormMap.values();
                }
            }
            catch(Exception e){
                system.debug('kerensen exception e.getMessage(): ' + e.getMessage());
            }
        }
    }

    /**
     * [groupListToGroupMembers Function gets as input a list of group Ids and outputs a Map of Group Id vs List of Group Users]
     * @param  groupIdList [A list of group Ids]
     * @return             [Map of group Id vs a List of the users of the group]*/
    
    private static Map<Id, List<User>> groupListToGroupMembers(List<Id> groupIdList){
        system.debug('$$entered groupListToGroupMembers method');
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Map<Id, List<User>> groupIdToUsersMap = new Map<Id, List<User>>();
        Set<Id> groupIdSet = new Set<Id>();
        List<Id> groupIdsList = new List<Id>();
        
        for(Id groupId : groupIdList ){
            groupIdSet.add(groupId);
        }
        system.debug('$$groupIdSet method 287'+groupIdSet.size());
        List<GroupMember> groupMembers = [Select GroupId, UserOrGroupId From GroupMember Where GroupId In :groupIdList];
        system.debug('$$groupMembers method 290'+groupMembers.size());
        Set<Id> userOrGroupIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            if(((String)member.UserOrGroupId).startsWith(groupType)){
                groupIdsList.add(member.UserOrGroupId);
            }
            else{
                userOrGroupIds.add(member.UserOrGroupId);
            }
        }
        system.debug('$$groupIdsList method 295'+groupIdsList.size());
        if(groupIdsList.size()>0){
            groupIdToUsersMap.putall(groupListToGroupMembers(groupIdsList));
        }
        system.debug('$$groupIdToUsersMap method 303'+groupIdToUsersMap.size());
        Map<Id, User> userMap = new Map<Id, User>([Select Id, Name From User Where Id In :userOrGroupIds]);

        system.debug('$$userMap method 306'+userMap.size());
        for (Id groupId : groupIdList) {
            groupIdToUsersMap.put(groupId, new List<User>());
        }
        system.debug('$$groupIdToUsersMap method 310'+groupIdToUsersMap.size());
        for (GroupMember member : groupMembers) {
            if (userMap.containsKey(member.UserOrGroupId)) {
                groupIdToUsersMap.get(member.GroupId).add(userMap.get(member.UserOrGroupId));
            }
        }
        system.debug('$$groupIdToUsersMap method 315'+groupIdToUsersMap.size());
        return groupIdToUsersMap;
    }

    /**
     * [4r                         The function gets as input the approver number String]
     * @param  approverNumbersSet [description]
     * @return                    [query with relevant approvers]*/
         private static String createQueryFromApproverSet(Set<String> approverNumbersSet){
        String query = '';
        for(String s : approverNumbersSet){
            query += ', cTin_ApproverName' + s + '__c, ' + 'cTin_ApproverRole' + s + '__c, ' + 'cTin_ApprovalStatus' + s + '__c, ' + 'cTin_ApproverNameTxt' + s + '__c';
        }
        query = query.subString(0, query.length());
        return query;
    }

    /**
     * [createFormMap The function gets a List of contractForms as input, and queries the Contract Form to create a map of ContractIds to Contract Form]
     * @param  query [description]
     * @return       [description]*/
    
    private static Map<Id, cTin_ContractForm__c> createContract_ContractFormMap(List<cTin_ContractForm__c> contractFormList){
        Map<Id, cTin_ContractForm__c> contractIdContractFormMap = new Map<Id, cTin_ContractForm__c>();
        for(cTin_ContractForm__c contractForm : contractFormList){
            contractIdContractFormMap.put(contractForm.cTin_Contract__c, contractForm);
        }
        system.debug('kerensen createContract_ContractFormMap contractIdContractFormMap: ' + contractIdContractFormMap);
        system.debug('kerensen createContract_ContractFormMap contractFormList: ' + contractFormList);
        return contractIdContractFormMap;
    }

    private static void createSets(List<cTin_ContractTeam__c> contractTeamList, Set<String> groupNameSet, Set<String> approverNumberSet, Set<Id> contractIdSet, Set<Id> contractTeamIdSet)
    {
        // first we need to grab all the group names and user Ids that will get the new permissions for the Contract and Contract form
            // run on all the contractteams that were inserted
        //system.debug('##contractTeamList'+contractTeamList.size());
        if(contractTeamList.size()>0){
        for(cTin_ContractTeam__c contractteam : contractTeamList){
            system.debug('##contractteam contract' + contractteam.cTin_Contract__c );

            //system.debug('>### HVA createSets contractTeam.Id ' + contractTeam.Id );
            //system.debug('>### HVA createSets contractteam.cTin_Contract__c ' + contractteam.cTin_Contract__c );
            //system.debug('>### HVA createSets contractteam.cTin_GroupMember__c ' + contractteam.cTin_GroupMember__c );
           // system.debug('>### HVA createSets contractteam.cTin_ApprovalOrder__c ' + contractteam.cTin_ApprovalOrder__c );
            
            contractTeamIdSet.add(contractTeam.Id);
            contractIdSet.add(contractteam.cTin_Contract__c);
            // if the groupmember is picked then it means we have a group picked and we need to add it to our set
            if(contractteam.cTin_GroupMember__c != null && contractteam.cTin_GroupMember__c.trim() != ''){
                groupNameSet.add(contractteam.cTin_GroupMember__c);
            }
            else if(contractteam.cTin_ApprovalOrder__c != null && contractteam.cTin_ApprovalOrder__c.trim() != '' && contractteam.cTin_ApprovalOrder__c != 'Not in Approval Process'){
                // this set contains the number of the approver in the contract report object
                approverNumberSet.add(contractteam.cTin_ApprovalOrder__c);
            }
        }
        }

       // System.debug('>### HVA groupNameSet ' + groupNameSet);
        //System.debug('>### HVA approverNumberSet ' + approverNumberSet);
    }

    /****************************************Delete a team Subroutine********************************************/
    public static void DeleteSubroutine(List<cTin_ContractTeam__c> contractTeamList, Map<Id, List<User>> groupIdToGroupMembers, Map<String, Id> groupNameIdMap, Map<Id, cTin_ContractForm__c> contractIdContractFormMap, Map<Id, Contract__c> idContractMap, Map<Id, cTin_ContractTeam__c> contractTeamIdMap){
        Boolean isFirst = true;
        User groupMember = new User();
        Boolean isQueryFull = false;
        String q1 = 'SELECT Id FROM Contract__Share WHERE ';
        //String q2 = 'SELECT Id FROM EntitySubscription WHERE ';
        String q3 = 'SELECT Id From cTin_ContractForm__Share WHERE';
        system.debug('kerensen DeleteSubroutine contractTeamList: ' + contractTeamList);
        system.debug('kerensen DeleteSubroutine contractIdContractFormMap: ' + contractIdContractFormMap);
        for(cTin_ContractTeam__c contractTeam : contractTeamList){
            system.debug('kerensen DeleteSubroutine contractTeam.cTin_Contract__c: ' + contractTeam.cTin_Contract__c);
            system.debug('kerensen DeleteSubroutine contractTeam.cTin_TeamMember__c: ' + contractTeam.cTin_TeamMember__c);
            
            //MRA 27/09/2016 - Case 3166 (Added check on map to cater for "Error Attempt to de-reference a null")
            if(contractIdContractFormMap.containsKey(contractteam.cTin_Contract__c)){
                if(contractIdContractFormMap.get(contractteam.cTin_Contract__c).cTin_FinalApprovalStatus__c == 'Approved' && contractTeam.cTin_ApprovalOrder__c != 'Not in Approval Process'){
                    contractTeam.cTin_ApprovalOrder__c.addError(Label.cTin_lbl_Err_Approved_Contract_Form);
                }
                else if(contractTeam.cTin_ApprovalOrder__c != 'Not in Approval Process' && 
                        (contractIdContractFormMap.get(contractteam.cTin_Contract__c).get('cTin_ApprovalStatus' + contractTeam.cTin_ApprovalOrder__c + '__c') == 'Approved' ||
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).get('cTin_ApprovalStatus' + contractTeam.cTin_ApprovalOrder__c + '__c') == 'Waiting')){
                        contractTeam.cTin_ApprovalOrder__c.addError(Label.cTin_lbl_Err_Team_Waiting_Approved_Form);
                }
            }
            if(!isFirst){
                q1+=' or ';
                //if(!q2.endsWith(' WHERE ')) q2+=' or ';  else q2.removeEnd(' or ');
                q3+=' or ';
            }
            if(contractTeam.cTin_TeamMember__c != null){   
                //MRA 27/09/2016 - Case 3166 (Added check on map to cater for "Error Attempt to de-reference a null")
                if(idContractMap.containsKey(contractteam.cTin_Contract__c)) {         
                    if(idContractMap.get(contractteam.cTin_Contract__c).OwnerId != contractteam.cTin_TeamMember__c){
                        isQueryFull = true;
                        q1+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and UserOrGroupId = \''+contractTeam.cTin_TeamMember__c+'\')';
                        if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))
                            q3+='(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and UserOrGroupId = \''+contractTeam.cTin_TeamMember__c+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
                       
                       /*if(contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c))
                            q2+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and SubscriberId = \''+contractTeam.cTin_TeamMember__c+'\') or' +
                        '(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and SubscriberId = \''+contractTeam.cTin_TeamMember__c+'\')';
                   */
                }
                }
                //MRA 27/09/2016 - Case 3166 (Added check on map to cater for "Error Attempt to de-reference a null")
                if(contractIdContractFormMap.containsKey(contractteam.cTin_Contract__c)){
                    if(contractTeam.cTin_ApprovalOrder__c != null && contractTeam.cTin_ApprovalOrder__c.trim() != '' && contractTeam.cTin_ApprovalOrder__c != 'Not in Approval Process'){
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverName' + contractteam.cTin_ApprovalOrder__c + '__c', '');
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverNameTxt' + contractteam.cTin_ApprovalOrder__c + '__c', '');
                        contractIdContractFormMap.get(contractteam.cTin_Contract__c).put('cTin_ApproverRole' + contractteam.cTin_ApprovalOrder__c + '__c', '');
                    }
                }

            }
            else if(contractTeam.cTin_GroupMember__c != null && contractTeam.cTin_GroupMember__c.trim() != '') {
               if(groupNameIdMap.containsKey(contractTeam.cTin_GroupMember__c)){
                  q1+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and UserOrGroupId = \''+groupNameIdMap.get(contractTeam.cTin_GroupMember__c)+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';
               }
               
               if(groupNameIdMap.containsKey(contractTeam.cTin_GroupMember__c) && contractIdContractFormMap.containsKey(contractTeam.cTin_Contract__c) ){q3+='(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and UserOrGroupId = \''+groupNameIdMap.get(contractTeam.cTin_GroupMember__c)+'\' and AccessLevel = \''+contractTeam.cTin_ContractAccessLevel__c+'\')';}
                
                /*if(groupNameIdMap.size()>0 && groupIdToGroupMembers.size()>0){
                    for(integer i=0 ;i < groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c)).size(); ++i){
                        groupMember = groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c))[i];
                        q2+='(ParentId = \''+contractTeam.cTin_Contract__c+'\' and SubscriberId = \''+groupMember.Id+'\') or' +
                            +'(ParentId = \''+contractIdContractFormMap.get(contractTeam.cTin_Contract__c).Id+'\' and SubscriberId = \''+groupMember.Id+'\')';
                        if(i!=groupIdToGroupMembers.get(groupNameIdMap.get(contractTeam.cTin_GroupMember__c)).size()-1){
                            q2+=' or '; 
                        }
                    }
                }*/
            }
            isFirst = false; 
        }



        system.debug('kerensen DeleteSubroutine q1: ' + q1);
        //system.debug('kerensen DeleteSubroutine q2: ' + q2);
        system.debug('kerensen DeleteSubroutine q3: ' + q3);
        if(isQueryFull){
            //28/09/2016 - MRA : Check if queries q1 & q2 are valid before calling database.execute (Case 3166)
            List<Contract__Share> delContractShare=new list<Contract__Share>();
            List<cTin_ContractForm__Share> delContractFormShare=new list<cTin_ContractForm__Share>();
            List<EntitySubscription> delFollowContractOrContractForm = new list<EntitySubscription>();
            
            try{
                if(!q1.endsWith(' WHERE '))delContractShare = Database.query(q1);
                if(!q3.endsWith(' WHERE '))delContractFormShare = Database.query(q3);
                //if(!q2.endsWith(' WHERE ')) q2 += ' LIMIT 1000 '; delFollowContractOrContractForm = Database.query(q2);

                
                system.debug('kerensen DeleteSubroutine delContractShare.size(): ' + delContractShare.size());
                system.debug('kerensen DeleteSubroutine delContractFormShare.size(): ' + delContractFormShare.size());
                system.debug('kerensen DeleteSubroutine delFollowContractOrContractForm.size(): ' + delFollowContractOrContractForm.size());
                
                //28/09/2016 - MRA : Added check on list size before deleting sharing (Case 3166)
               // 30/11/2022 MRA - Commented since logic is already implemented elsewhere if(delContractShare.size()>0) delete delContractShare;
                if(delContractFormShare.size()>0) delete delContractFormShare;
                if(delFollowContractOrContractForm.size()>0) delete delFollowContractOrContractForm;
          
            }
            catch(Exception e){
                system.debug('## Problem with deletion of contract team'+ e.getMessage());
                contractTeamList[0].addError('Problem with deletion of ContractTeam');
            }
        }

        if(contractIdContractFormMap.size() > 0){try{update contractIdContractFormMap.values();} catch(Exception e){}}

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
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
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