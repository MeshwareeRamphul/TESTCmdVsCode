public class LC_Sing_GenerateCtrFromRFP {
	
    @AuraEnabled
    public static map<string,object>validateDisplay(String eventId){
        map<string,object> mapResult=new map<string,object>();
        id currentUserId= userinfo.getUserId();
        string currprofileId=userinfo.getProfileId();
        string currprofilename=[select id,name from profile where id=:currprofileId limit 1].name;
        
        list<Sourcing_Event_Team__c> srcTeamBuyer=[select id from Sourcing_Event_Team__c 
                                                   where Role__c='001' and 
                                                   sourcing_event__c=:eventId and Team_Member__c=:currentUserId];
            
        list<bidder__c> bidderlst=[select id,Sourcing_Event__c                           
                              from bidder__c
                              where bidder_status__c=:'Awardee'
                              and Sourcing_Event__c=:eventId];
       
        if(bidderlst.size()>0 && (srcTeamBuyer.size()>0 || currprofilename.contains('System Administrator')))
            mapResult.put('show','show');
        else {
            
              mapResult.put('hide','hide');
          
        }
        
        return mapResult;
    }
        
    @AuraEnabled
    public static map<string,object> generateCtr(String eventId){
        map<string,object> mapResult=new map<string,object>();
        /*list<Sourcing_Event__c> lstEvent=[select id, name,BusinessOwner__c ,APC_Level_0__c,APC_Level_1__c,APC_Level_2__c,APC_Level_3__c,Sing_Beneficiary_entities__c,
                                          Legal_Entity__c from Sourcing_Event__c where id=:eventId];*/
        list<Sourcing_Event__c> lstEvent=[select id,TECH_RFPCreatedFromSrcReq__c,Sourcing_Request__c from Sourcing_Event__c where id=:eventId];
        list<Contract__c> lstCtr=new list<Contract__c>();
        list<Sourcing_Event_Team__c> srcTeamLst=new list<Sourcing_Event_Team__c>();
        
        map<id,list<Sourcing_Event_Team__c>> mapIdSrcTeam=new map<id,list<Sourcing_Event_Team__c>>();
        for(Sourcing_Event_Team__c TeamSrc:[select id,Event_Access_Level__c,Member_Group__c,Role__c,
                                                Sourcing_Event__c,Team_Member__c from Sourcing_Event_Team__c
                                             where Sourcing_Event__c=:eventId]){
                  srcTeamLst.add(TeamSrc);                               
                 if(mapIdSrcTeam.containsKey(TeamSrc.Sourcing_Event__c)) {
                    List<Sourcing_Event_Team__c> lstTeamSrc = mapIdSrcTeam.get(TeamSrc.Sourcing_Event__c);
                    lstTeamSrc.add(TeamSrc);
                    mapIdSrcTeam.put(TeamSrc.Sourcing_Event__c, lstTeamSrc);
                } else {
                    mapIdSrcTeam.put(TeamSrc.Sourcing_Event__c, new List<Sourcing_Event_Team__c> { TeamSrc });
                }                                
         }
        
        list<bidder__c> bidderlst=[select id,Sing_Account__c,Sourcing_Event__r.BusinessOwner__c,bidder_status__c,Sourcing_Event__c,Sing_Account__r.name,
                             Sourcing_Event__r.APC_Level_0__c,Sourcing_Event__r.ContractAlreadyGenerated__c,
                              Sourcing_Event__r.APC_Level_1__c,
                              Sourcing_Event__r.APC_Level_2__c,
                              Sourcing_Event__r.APC_Level_3__c,
                              Sourcing_Event__r.Sing_Beneficiary_entities__c,
                              Sourcing_Event__r.Legal_Entity__c,Contact_Bidder__c,
                              Sourcing_Event__r.name                             
                              from bidder__c
                              where bidder_status__c=:'Awardee'
                              and Sourcing_Event__c=:eventId];
                              
        if(bidderlst.size()>0){
            for(bidder__c bidder:bidderlst){
                Contract__c newctr=new Contract__c(name=bidder.Sourcing_Event__r.name + '-' + bidder.Sing_Account__r.name,
                                              cTin_BusinessOwner__c=bidder.Sourcing_Event__r.BusinessOwner__c,
                                              cTin_OrganizationalScope__c=bidder.Sourcing_Event__r.Sing_Beneficiary_entities__c,
                                              cTin_MainAPCL0__c=bidder.Sourcing_Event__r.APC_Level_0__c,
                                              cTin_MainAPCL1__c=bidder.Sourcing_Event__r.APC_Level_1__c,
                                              cTin_MainAPCL2__c=bidder.Sourcing_Event__r.APC_Level_2__c,
                                              cTin_MainAPCL3__c=bidder.Sourcing_Event__r.APC_Level_3__c,
                                              cTin_SupplierAccount__c=bidder.Sing_Account__c,
                                              Sing_SouricngEvent__c=bidder.Sourcing_Event__c,
                                              recordtypeId= Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId()
											  ,Participant__c=bidder.id,
                                              SourcingContact__c=bidder.Contact_Bidder__c,
                                              status__c='Draft');
                //MRA 09/06/2022 - link contract to sourcing request if contract.sourcingevent.TECH_RFPCreatedFromSrcReq__c=true   
                if(lstEvent[0].TECH_RFPCreatedFromSrcReq__c)
                        newctr.Sourcing_Request__c=lstEvent[0].Sourcing_Request__c;
                	lstCtr.add(newctr);
                }
        }
        else{
            mapResult.put('error','Alteast one awardee is required to generated a Draft contract');
        }
        
        if(lstCtr.size()>0){
            try{
                list<cTin_ContractTeam__c>lstnewctrTeams=new list<cTin_ContractTeam__c>();
            	insert lstCtr;
                mapResult.put('success','Draft contract has been generated');
                if(srcTeamLst.size()>0){
                    for(Contract__c ctr:lstCtr){
                        for(Sourcing_Event_Team__c srcTeam: mapIdSrcTeam.get(ctr.Sing_SouricngEvent__c)){
                        	cTin_ContractTeam__c ctrTeam=new cTin_ContractTeam__c(
                                                        cTin_GroupMember__c=srcTeam.Member_Group__c,
                                                        cTin_ContractAccessLevel__c=srcTeam.Event_Access_Level__c,
                                                        cTin_Role__c=srcTeam.Role__c,
                                                        cTin_TeamMember__c=srcTeam.Team_Member__c,
                                                        cTin_ApprovalOrder__c='Not in Approval Process',
                                                        cTin_Contract__c=ctr.Id);
                                
                           lstnewctrTeams.add(ctrTeam);    
                        }
                        
                    }
                    insert lstnewctrTeams;
                }
                
                Sourcing_Event__c event=new Sourcing_Event__c(id=eventId,
                                                             ContractAlreadyGenerated__c=true);
                update event;
            }
            catch(Exception e){
                mapResult.put('error',e.getMessage());
            }
        }
                             
        /*Contract__c newctr=new Contract__c(name=
                                          cTin_BusinessOwner__c,
                                          cTin_OrganizationalScope__c=
                                          cTin_MainAPCL0__c=
                                          cTin_MainAPCL1__c=
                                          cTin_MainAPCL2__c=
                                          cTin_MainAPCL3__c=
                                          cTin_SupplierAccount__c=
                                          status__c=);*/
        
       // 
        
        return mapResult;
    } 
    
}