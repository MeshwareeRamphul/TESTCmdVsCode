public without sharing class AP72_ManageCTeamListView {
    /*----------------------------------------------------------------------
    -- - Name          : AP72_ManageCTeamListView
    -- - Author        : 
    -- - Description   : trigger handler for AP72_ManageCTeamListView
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 13-Jun-2022  AMA    1.0      init
    -------------------------------------------------------------------------*/

    // 13-Jun-2022  AMA    SP-03969
    @future
    public static void setEventContractTeamMember(Set<Id> setIdCtr){
        Map<Id, String> mapNewTeamMember = new Map<Id, String>();
        Map<Id, String> mapNewTeamMember2 = new Map<Id, String>();
        List<Contract__c> lstCtr = new List<Contract__c>();
        String teamMember='';
        String teamMember2='';
        Integer len = 0;

        List<cTin_ContractTeam__c> lstCtrTeam = [SELECT Id, cTin_Contract__c, cTin_TeamMember__c/*,cTin_TeamMember__r.profile.name*/ FROM cTin_ContractTeam__c WHERE cTin_Contract__c IN :setIdCtr AND cTin_TeamMember__c != null /*AND cTin_TeamMember__r.profile.name='cTin - Stakeholder / Legal / Audit'*/];
        if(lstCtrTeam.size() > 0){
            for(cTin_ContractTeam__c team : lstCtrTeam){
                teamMember = mapNewTeamMember.get(team.cTin_Contract__c) == null ? '' : mapNewTeamMember.get(team.cTin_Contract__c);
                teamMember2 = mapNewTeamMember2.get(team.cTin_Contract__c) == null ? '' : mapNewTeamMember2.get(team.cTin_Contract__c);
                if (len <= 255) {
                    len = teamMember.length() + String.valueOf(team.cTin_TeamMember__c).length() + 1;
                }
                
                if(teamMember == '' || teamMember == null){
                    teamMember = team.cTin_TeamMember__c + ';';
                }else if(!teamMember.contains(team.cTin_TeamMember__c) && len <= 255 ){
                    teamMember += team.cTin_TeamMember__c + ';';
                }else {
                    teamMember2 += team.cTin_TeamMember__c + ';';
                }

                if (len <= 255) {
                    mapNewTeamMember.put(team.cTin_Contract__c, teamMember);
                } else{
                    mapNewTeamMember2.put(team.cTin_Contract__c, teamMember2);
                }
                
            }

            for(Id seId : mapNewTeamMember.keySet()){
                if (len <= 255) {
                    lstCtr.add(new Contract__c(Id = seId, ContractTeamMember__c = mapNewTeamMember.get(seId), ContractTeamMember2__c = ''));
                } else {
                    lstCtr.add(new Contract__c(Id = seId, ContractTeamMember__c = mapNewTeamMember.get(seId), ContractTeamMember2__c = mapNewTeamMember2.get(seId)));
                }
            }

            if(lstCtr.size() > 0){
                update lstCtr;
            }
        }
    }
}