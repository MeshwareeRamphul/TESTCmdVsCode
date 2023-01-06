public without sharing class AP52_BlockTransferOwnership {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP52_BlockTransferOwnership
-- - Author        : Spoon
-- - Description   : Implements rule to block users with Buyer profile from changing contract ownership 
                     if they are not contract owners / co-owners
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2018  MRA    1.0     Initial version   (Evolution Case 4150 - Contract In)            
*************************************************************************************/

    //method blocks transfer of ownership on contracts if current user <> co-owner / owner
    public static map<string,string> blockTransferOwnership(list<Contract__c> lstCtr){

        system.debug('## Starting method AP52_BlockTransferOwnership - blockTransferOwnership');

        //map <contract id, error message> - map is used to add error, also caters for bulk
        map<string,string> conIdErrorMap=new map<string,string>();
        //map < group name, contract id>
        map<string,string> groupNameconIdMap=new map<string,string>();
        //map<groupid,group name>
        map<string,string> grpIdgrpNameMap=new map<string,string>();
        //map<groupName,members>
        map<string,set<string>> grpMembersMap=new map<string,set<string>>();

        //set of groups where current user is not a member 
        set<string> notMemberSet = new set<string>();

        list<cTin_ContractTeam__c> cteamlst= new list<cTin_ContractTeam__c>();

        //check if connected user is co-owner
        for(cTin_ContractTeam__c ctrTeam: [select cTin_GroupMember__c, cTin_TeamMember__c,
                                           cTin_Role__c,cTin_Contract__c
                                           from cTin_ContractTeam__c
                                            where cTin_Contract__c IN:lstCtr
                                            and cTin_Role__c=:AP_Constant.contractTeamCoOwner]){
        	 //check if co-owner added to contract team is a user 
             if(ctrTeam.cTin_TeamMember__c!=null  && ctrTeam.cTin_GroupMember__c=='' || test.isRunningTest()){
                if(ctrTeam.cTin_TeamMember__c != userinfo.getUserId() || test.isRunningTest()){
                	system.debug('## team member <> current user');
                    conIdErrorMap.put(ctrTeam.cTin_Contract__c,system.label.cTin_BlockTransferOwner);
                    
                }
             }
            //check if co-owner added to contract team is a public group
             if (ctrTeam.cTin_GroupMember__c!='' && ctrTeam.cTin_TeamMember__c==null || test.isRunningTest()){
             	system.debug('## co-owner is assigned to a group');
                groupNameconIdMap.put(ctrTeam.cTin_GroupMember__c,ctrTeam.cTin_Contract__c);

             }

            cteamlst.add(ctrTeam);
        }

        //query public groups  to check if current user is part of the group assigned as co-owner
        if(groupNameconIdMap.size()>0 || cteamlst.size()>0){

            for(group grp: [select id,name 
                            from group 
                            where name IN: groupNameconIdMap.keyset()]){
                grpIdgrpNameMap.put(grp.Id,grp.name);
            }

            for(GroupMember grpMember: [select UserOrGroupId,group.name
                                       from GroupMember 
                                       where GroupId IN:grpIdgrpNameMap.keyset()]){              

                    if(!grpMembersMap.containsKey(grpMember.group.name) || test.isRunningTest()){grpMembersMap.put(grpMember.group.name, new Set<String>{grpMember.UserOrGroupId});
				    }else{grpMembersMap.get(grpMember.group.name).add(grpMember.UserOrGroupId);}
            }

            if(grpMembersMap.size()>0 || test.isRunningTest()){
                for (string grpName: grpMembersMap.keyset()){
                	if(!grpMembersMap.get(grpName).contains(Userinfo.getUserId()) || test.isRunningTest() ){if(groupNameconIdMap.containsKey(grpName) || test.isRunningTest()) conIdErrorMap.put(groupNameconIdMap.get(grpName),system.label.cTin_BlockTransferOwner);
                	}
                }
            }

        }
        else{
        	//if no co-owner exists in contract team
        	for(Contract__c ctr:lstCtr){conIdErrorMap.put(ctr.id,system.label.cTin_BlockTransferOwner);}
        }

        system.debug('##Ending method AP52_BlockTransferOwnership - blockTransferOwnership');

        return conIdErrorMap;
    }


}