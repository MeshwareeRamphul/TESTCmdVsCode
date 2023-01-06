public without sharing class AP35_updateCTeamDomainGroup {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP35_updateCTeamDomainGroup
-- - Author        : Spoon Consulting 
-- - Description   : add/remove group corresponding to sourcing domain in
                     contract team when sourcing domain is updated /filled
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 21-OCT-2015  NJA    1.0     Initial version
-- 29-MAY-2017  MRA    1.1     Case 3480 (enhancement): 
                               add/remove group corresponding to sourcing domain in
                               contract team when sourcing domain is updated /filled  
-- 17-APR-2019   MRA   1.2     4330: Added code to remove AIM Local Admins,AIM Legal Team,AIM Contract Co-Owner from contract team if owner entity changes
-- 07-DEC-2021  MRA    1.3     remove AIM legal, AIM Audit and AIM Procurement Office from contract team if contract entity changes
************************************************************************************/
    
    //method adds/removes group to contract team after insert/after update when sourcing domain is specified or changed
    public static void addRemoveGroup(map<id,string>conIdNewDomainMap, map<id,string>conIdOldDomainMap,set<id>contractIdSet){

        map<string,string> domainGroupMap = new map<string,string>{'General Expenses' => 'AIM Genex Procurement',
                                                                   'IT & Contractors' => 'AIM IT Procurement',
                                                                   'Market Data' => 'AIM MD Procurement' };
        list<cTin_ContractTeam__c>cTeamToAddLst=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c>cTeamToDelLst=new list<cTin_ContractTeam__c>();

        for(id conId : conIdNewDomainMap.keyset()){

            if(conIdNewDomainMap.get(conId)!=null){

                cTin_ContractTeam__c cTeam = new cTin_ContractTeam__c(cTin_GroupMember__c = domainGroupMap.get(conIdNewDomainMap.get(conId)),
                                                                      cTin_contract__c = conId,
                                                                      cTin_active__c = true,
                                                                      cTin_role__c = '015',
                                                                      cTin_ContractAccessLevel__c = 'Edit');
                cTeamToAddLst.add(cTeam);
            }
        }

        for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, cTin_GroupMember__c
                                          FROM cTin_ContractTeam__c
                                         WHERE cTin_contract__c IN: conIdOldDomainMap.keyset() 
                                           AND cTin_role__c = :'015']){
            if(domainGroupMap.get(conIdOldDomainMap.get(cTeam.cTin_contract__c)) == cTeam.cTin_GroupMember__c){
                cTeamToDelLst.add(cTeam);
            }
        }


        if(contractIdSet.size()>0){
           for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, cTin_GroupMember__c
                                          FROM cTin_ContractTeam__c
                                          WHERE cTin_contract__c IN: contractIdSet 
                                          AND  (cTin_GroupMember__c = 'AIM Local Admins'
                                          OR  cTin_GroupMember__c = 'AIM Legal Team'
                                          OR  cTin_GroupMember__c = 'AIM Contract Co-Owner'
                                          OR cTin_GroupMember__c='cTin_AIM_Procurement_Office'
                                          OR cTin_GroupMember__c='cTin_AIM_Audit'
                                          OR cTin_GroupMember__c='AIM_Legal_Team')]){
           
                  cTeamToDelLst.add(cTeam);
              
          }
        }
        if(cTeamToAddLst.size()>0)
            Insert cTeamToAddLst;

        if(cTeamToDelLst.size()>0)
            Delete cTeamToDelLst;
    }
}