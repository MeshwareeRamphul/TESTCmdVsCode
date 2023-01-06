/*----------------------------------------------------------------------
-- - Name          : AP73_ManageSrcReqSharing
-- - Author        : AMA
-- - Description   : class to manage sourcing request sharing
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 22-JUN-2022  AMA  1.0      Initial version 
-- 19-JUL-2022  MRA  1.1      Converted methods into @future
-------------------------------------------------------------------------*/

public without sharing class AP73_ManageSrcReqSharing {
	public static boolean IsRunningAp73=false;
    public static void AfterInsertSharing(map<Id,Sourcing_Request__c> mapNewSrcReq){
        system.debug('##mapNewSrcReq after insert'+mapNewSrcReq);
        set<id>setSrcReqId=new set<id>();
        for(id srcReqID:mapNewSrcReq.keyset()){
            setSrcReqId.add(srcReqID);
        }
        if(setSrcReqId.size()>0) RecalculateSharing(setSrcReqId, 'insert');
    //RecalculateSharing(mapNewSrcReq, 'insert');
    } 

    public static void AfterUpdateSharing(map<Id,Sourcing_Request__c> mapNewSrcReq){
        //RecalculateSharing(mapNewSrcReq, 'update');
        set<id>setSrcReqId=new set<id>();
        for(id srcReqID:mapNewSrcReq.keyset()){
            setSrcReqId.add(srcReqID);
        }
        if(setSrcReqId.size()>0) RecalculateSharing(setSrcReqId, 'update');
    }
	
    //method called after update of sourcing request lookups / after insert of sourcing request / after insert of contract linked to a src request
    //recalculates sharing- copies sharing from src request on sourcing event / contracts 
    @future
    public static void RecalculateSharing(set<id>mapNewSrcReq/*map<Id,Sourcing_Request__c> mapNewSrcReq*/, string mode){
        IsRunningAp73=true;
        System.debug(' RecalculateSharing '+mapNewSrcReq);
        System.debug(' mode'+ mode);
        Map<Id,List<Sourcing_Event__c>> mapIdSrcReqLstSrcEvt = new Map<Id,List<Sourcing_Event__c>>();
        Map<Id,List<Contract__c>> mapIdSrcReqLstCtr = new Map<Id,List<Contract__c>>();
        List<Sourcing_Event__c> lstSrcEvt = new List<Sourcing_Event__c>();
        List<Contract__c> lstCtr = new List<Contract__c>();

        //get fields by custom Label
        List<String> lstFields = System.Label.SrcReqFieldsSharing.split(';');

        //var for sharing Sourcing_Request__Share/Sourcing_Event__Share/Contract__Share
        List<Sourcing_Request__Share> lstSrcReqShrIns = new List<Sourcing_Request__Share>();
        List<Sourcing_Event__Share> lstSrcEvtShrIns = new List<Sourcing_Event__Share>();
        List<Contract__Share> lstCtrIns = new List<Contract__Share>();

        //var to delete sharing Sourcing_Request__Share/Sourcing_Event__Share/Contract__Share
        List<Sourcing_Request__Share> lstSrcReqShrDel = new List<Sourcing_Request__Share>();
        List<Sourcing_Event__Share> lstSrcEvtShrDel = new List<Sourcing_Event__Share>();
        List<Contract__Share> lstCtrShrDel = new List<Contract__Share>();
		set<string> setShareWithId=new set<string>();
         //get sharing to delete for contract
        Set<ID> setIdCtr = new Set<ID>();
        //get liste Sourcing_Event and liste Contract if trigger update(mode)
        if (mode=='update') {
        //system.debug();
           //lstSrcEvt = [select id,BusinessOwner__c,Sourcing_Request__c from Sourcing_Event__c where Sourcing_Request__c ='a045E00001eKshr'];
            lstSrcEvt = [select id,BusinessOwner__c,Sourcing_Request__c from Sourcing_Event__c where Sourcing_Request__c in :mapNewSrcReq];
            lstCtr = [select id,cTin_BusinessOwner__c,Sourcing_Request__c from Contract__c where Sourcing_Request__c in :mapNewSrcReq];
        }
        //populate liste Sourcing_Event
        system.debug('## lstSrcEvt'+lstSrcEvt);
        if (lstSrcEvt.size()>0) {
            for (Sourcing_Event__c srcEvt : lstSrcEvt) {
                system.debug('## srcEvt.Sourcing_Request__c'+srcEvt.Sourcing_Request__c);
                if (mapIdSrcReqLstSrcEvt.containsKey(srcEvt.Sourcing_Request__c)) {
                    mapIdSrcReqLstSrcEvt.get(srcEvt.Sourcing_Request__c).add(srcEvt);
                }
                else {
                    mapIdSrcReqLstSrcEvt.put(srcEvt.Sourcing_Request__c, new List<Sourcing_Event__c>{srcEvt});
                }
            }
        }
        system.debug('## mapIdSrcReqLstSrcEvt'+mapIdSrcReqLstSrcEvt);
        //populate liste Contract
        if (lstCtr.size()>0) {
            for (Contract__c ctr : lstCtr) {
                if (mapIdSrcReqLstCtr.containsKey(ctr.Sourcing_Request__c)) {
                    mapIdSrcReqLstCtr.get(ctr.Sourcing_Request__c).add(ctr);
                }
                else {
                    mapIdSrcReqLstCtr.put(ctr.Sourcing_Request__c, new List<Contract__c>{ctr});
                }
            }
        }

        for (Sourcing_Request__c SrcReq :[select id,Business_Owner__c,Data_Privacy_Expert__c,
                                          Legal_Counsel__c,Other_Proc__c,SBP__c,
                                          vendor_riskuser__c,Buyer_Lead__c,Financial_control__c
                                          from Sourcing_Request__c where id in :mapNewSrcReq] /*mapNewSrcReq.values()*/) {
        system.debug('## looping in map mapNewSrcReq.values()'+mapNewSrcReq);
            //Add sourcing request sharing for Business_Owner if not null
            if (SrcReq.Business_Owner__c != null) {
                system.debug('## SrcReq.Business_Owner__c not null'+SrcReq.Business_Owner__c);
                lstSrcReqShrIns.add(new Sourcing_Request__Share(ParentId=SrcReq.id, UserOrGroupId=SrcReq.Business_Owner__c, AccessLevel='Read', RowCause=Schema.Sourcing_Request__Share.RowCause.Manual));
                //Add sourcing request sharing and contract sharing for sourcing request Business_Owner__c if mode update
                if (mode=='update') {
                    system.debug('## mapIdSrcReqLstSrcEvt'+ mapIdSrcReqLstSrcEvt);
                    system.debug('## SrcReq.id'+ SrcReq.id);
                    if (mapIdSrcReqLstSrcEvt.containsKey(SrcReq.id) && mapIdSrcReqLstSrcEvt.get(SrcReq.id).size() > 0) {
                        for (Sourcing_Event__c srcEvt : mapIdSrcReqLstSrcEvt.get(SrcReq.id)) {
                            lstSrcEvtShrIns.add(new Sourcing_Event__Share(ParentId=srcEvt.id, UserOrGroupId=SrcReq.Business_Owner__c, AccessLevel='Read', RowCause=Schema.Sourcing_Event__Share.RowCause.Manual));
                        }
                    }
                    
                    if( mapIdSrcReqLstCtr.size()>0){
                        if (mapIdSrcReqLstCtr.containsKey(SrcReq.id) && mapIdSrcReqLstCtr.get(SrcReq.id).size() > 0) {
                            for (Contract__c ctr : mapIdSrcReqLstCtr.get(SrcReq.id)) {
                                lstCtrIns.add(new Contract__Share(ParentId=ctr.id, UserOrGroupId=SrcReq.Business_Owner__c, AccessLevel='Read', RowCause=Schema.Contract__Share.RowCause.Manual));
                            }
                        }
                    }
                }
            }

            //Add sourcing request sharing, sourcing event sharing and contract sharing for user lookup in SrcReqFieldsSharing custom label (dynamique)
            for (String field : lstFields) {
                system.debug('##### fields '+SrcReq.get(field));
                if (SrcReq.get(field) != null && SrcReq.get(field) !='') {
                    lstSrcReqShrIns.add(new Sourcing_Request__Share(ParentId=SrcReq.id, UserOrGroupId=(String)SrcReq.get(field), AccessLevel='Edit', RowCause=Schema.Sourcing_Request__Share.RowCause.Manual));
                    //add sharing if mode update
                    if (mode=='update') {
                        if (mapIdSrcReqLstSrcEvt.containsKey(SrcReq.id) && mapIdSrcReqLstSrcEvt.get(SrcReq.id).size() > 0) {
                            for (Sourcing_Event__c srcEvt : mapIdSrcReqLstSrcEvt.get(SrcReq.id)) {
                                lstSrcEvtShrIns.add(new Sourcing_Event__Share(ParentId=srcEvt.id, UserOrGroupId=(String)SrcReq.get(field), AccessLevel='Read', RowCause=Schema.Sourcing_Event__Share.RowCause.Manual));
                            }
                        }
                        
                        if(mapIdSrcReqLstCtr.size()>0){
                            if (mapIdSrcReqLstCtr.containsKey(SrcReq.id) && mapIdSrcReqLstCtr.get(SrcReq.id).size() > 0) {
                                for (Contract__c ctr : mapIdSrcReqLstCtr.get(SrcReq.id)) {
                                    setShareWithId.add((String)SrcReq.get(field));
                                    lstCtrIns.add(new Contract__Share(ParentId=ctr.id, UserOrGroupId=(String)SrcReq.get(field), AccessLevel='Read', RowCause=Schema.Contract__Share.RowCause.Manual));
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (mode=='update') {
            //get sharing to delete for sourcing request
            lstSrcReqShrDel = [Select id from Sourcing_Request__Share where ParentId in :mapNewSrcReq/*mapNewSrcReq.keySet()*/ and RowCause=:Schema.Sourcing_Request__Share.RowCause.Manual];

            //get sharing to delete for sourcing event
            Set<ID> setIdSrcEvt = new Set<ID>();
            for (List<Sourcing_Event__c> lstSrcEvt2 : mapIdSrcReqLstSrcEvt.values()) {
                for (Sourcing_Event__c srcEvt : lstSrcEvt2) {
                    setIdSrcEvt.add(srcEvt.id);
                }
            }
            //get team member to exclude delete manual sharing for sourcing event
            //List<Sourcing_Event_Team__c> lstSrcEvtTeam = [select Team_Member__c from Sourcing_Event_Team__c where Sourcing_Event__c in:setIdSrcEvt];
            Set<ID> setSrcEvtTeamMember = new Set<ID>();
            //if (lstSrcEvtTeam.size()>0) {
            for (Sourcing_Event_Team__c srcEvt : [select Team_Member__c from Sourcing_Event_Team__c where Sourcing_Event__c in:setIdSrcEvt]) {
                setSrcEvtTeamMember.add(srcEvt.Team_Member__c);
            }
            //}
            //get sourcing event sharing to delete
            if (setSrcEvtTeamMember.size()>0) {
                lstSrcEvtShrDel = [Select id from Sourcing_Event__Share where ParentId in :setIdSrcEvt and RowCause=:Schema.Sourcing_Event__Share.RowCause.Manual and UserOrGroupId not in :setSrcEvtTeamMember];
            } else {
                lstSrcEvtShrDel = [Select id from Sourcing_Event__Share where ParentId in :setIdSrcEvt and RowCause=:Schema.Sourcing_Event__Share.RowCause.Manual];
            }
            
           
            if(mapIdSrcReqLstCtr.size()>0){
                for (List<Contract__c> lstCtr2 : mapIdSrcReqLstCtr.values()) {
                    for (Contract__c ctr : lstCtr2) {
                        setIdCtr.add(ctr.id);
                    }
                }
            }
            //get team member to exclude delete manual sharing for contract
           /* if(setIdCtr.size()>0){
                List<cTin_ContractTeam__c> lstCtrTeam = [select cTin_TeamMember__c from cTin_ContractTeam__c where cTin_Contract__c in:setIdCtr];
                Set<ID> setCtrTeamMember = new Set<ID>();
                if (lstCtrTeam.size()>0) {
                    for (cTin_ContractTeam__c ctr : lstCtrTeam) {
                        setCtrTeamMember.add(ctr.cTin_TeamMember__c);
                    }
                }
                //get contract sharing to delete
                if (setCtrTeamMember.size()>0 && setShareWithId.size()>0 && setIdCtr.size()>0) {
                    lstCtrShrDel = [Select id from Contract__Share where ParentId in :setIdCtr and RowCause=:'Manual' 
                    and (UserOrGroupId not in :setCtrTeamMember and UserOrGroupId not in : setShareWithId)];
                } else {
                    //lstCtrShrDel = [Select id from Contract__Share where ParentId in :setIdCtr and RowCause=:Schema.Contract__Share.RowCause.Manual];
                }
        	}*/
            
            //deleting sharing
            if (lstSrcEvtShrDel.size()>0) {
                Database.DeleteResult[] srlstSrcEvtShrDel = Database.delete(lstSrcEvtShrDel,false);
            }
            //if (lstCtrShrDel.size()>0) {
               // Database.DeleteResult[] srlstCtrShrDel = Database.delete(lstCtrShrDel,false);
            //}
            if (lstSrcReqShrDel.size()>0) {
                Database.DeleteResult[] srlstSrcReqShrDel = Database.delete(lstSrcReqShrDel,false);
            }
        }

        //insert sharing for sourcing request
        if (lstSrcReqShrIns.size()>0) {
            Database.SaveResult[] srlstSrcReqShrIns = Database.insert(lstSrcReqShrIns,false);
            system.debug(' lstSrcReqShrIns' + lstSrcReqShrIns);
            for (Integer i = 0; i < srlstSrcReqShrIns.size(); i++) {
                Database.SaveResult sr = srlstSrcReqShrIns[i];

                if(sr.isSuccess()){
                    
                    system.debug(' isSuccess rq' + sr);
                   
                }else{
                    system.debug(' isFailed rq' + sr);
                }
            }

        }

        //insert sharing for sourcing event and contract if mode update
        if (mode=='update') {
            if (lstSrcEvtShrIns.size()>0) {
                Database.SaveResult[] srlstSrcEvtShrIns = Database.insert(lstSrcEvtShrIns,false);
                system.debug(' lstSrcEvtShrIns' + lstSrcEvtShrIns);
                
                for (Integer i = 0; i < srlstSrcEvtShrIns.size(); i++) {
                    Database.SaveResult sr = srlstSrcEvtShrIns[i];
    
                    if(sr.isSuccess()){
                        
                        system.debug(' isSuccess sv' + sr);
                       
                    }else{
                        system.debug(' isFailed sv' + sr);
                    }
                }
            }
            if (lstCtrIns.size()>0) {
                Database.SaveResult[] srlstCtrIns = Database.insert(lstCtrIns,false);
                system.debug(' lstCtrIns' + lstCtrIns);
                for (Integer i = 0; i < srlstCtrIns.size(); i++) {
                    Database.SaveResult sr = srlstCtrIns[i];
    
                    if(sr.isSuccess()){
                        
                        system.debug(' isSuccess ct' + sr);
                       
                    }else{
                        system.debug(' isFailed ct' + sr);
                    }
                }
            }  
        }
    }
    
    //copies sharing from sourcing pipeline on new sourcing event => called from AP05_Sing_mangageEventTeam method manageEventSharing (line 164)
    public static void calculateSharingEventCreation(set<id>setEventId){
    
        map<id,list<Sourcing_Request__Share >>maplstReqShare=new map<id,list<Sourcing_Request__Share>>();
        map<id,id>mapsrcReIdEventId=new map<id,id>();
        list<Sourcing_Event__c>lstSrcEvt =new list<Sourcing_Event__c>();
        list<Sourcing_Event__Share> lstSrcEvtShare=new list<Sourcing_Event__Share>();
         
         //query event linked to sourcing request  => build map src req. Event
        for( Sourcing_Event__c  srcEvt:[select id,BusinessOwner__c,Sourcing_Request__c 
                                    from Sourcing_Event__c 
                                    where Sourcing_Request__c !=null
                                    and id in :setEventId]){          
           mapsrcReIdEventId.put(srcEvt.Sourcing_Request__c ,srcEvt.Id);                                                             
        }
        system.debug('srcEvt linked to request '+mapsrcReIdEventId);
        
        //query all manualsharing on sourcing request => build map<src req.id, sharing>
        for( Sourcing_Request__Share  reqShare : [Select id,parentId,UserOrGroupId,AccessLevel,RowCause from Sourcing_Request__Share 
                     where ParentId in :mapsrcReIdEventId.keyset()
                     and RowCause=:'Manual']){
              system.debug('##'+reqShare );
              lstSrcEvtShare.add(new Sourcing_Event__Share(ParentId=mapsrcReIdEventId.get(reqShare.ParentId),
                                                           UserOrGroupId=(String)reqShare.UserOrGroupId, 
                                                           AccessLevel=reqShare.AccessLevel, 
                                                           RowCause='Manual'));
        }
        
        system.debug('##lstSrcEvtShare'+lstSrcEvtShare.size());
        
        if(lstSrcEvtShare.size()>0){
             try{//database.insert(lstSrcEvtShare,false);
             insert lstSrcEvtShare;
             }
             catch(Exception e){system.debug('## Exception'+e.getMessage());}
         }
         
    }
    
    /*MRA 19/07/2022 separate method to delete sharing on contract when lookups on src requ is modified. 
      Could not be handled in RecalculateSharing due to conflicts / internal Sf error*/
    public static void deleteContractSharing(Map<ID,string> mapSrcReqOldSharing){
        system.debug('## to delete map 1'+mapSrcReqOldSharing);
        map<id,id> mapReqCtr=new map<id,id>();
        map<id,set<string>> mapCtrSharingTodel=new map<id,set<string>>();
        list<Contract__Share>lsttbdCtrShare=new list<Contract__Share>();
        
        for(Contract__c ctr:[select id,Sourcing_Request__c from contract__c where Sourcing_Request__c IN:mapSrcReqOldSharing.keyset()]){
            mapReqCtr.put(ctr.Sourcing_Request__c,ctr.Id);
            string userIds=mapSrcReqOldSharing.get(ctr.Sourcing_Request__c);
            system.debug('## userIds'+ userIds);
            if(!string.isblank(userIds)){
                
                for(string str: userIds.split(';')){
                    system.debug('##str'+str);
                    if (mapCtrSharingTodel.containsKey(ctr.Id)) {
                        mapCtrSharingTodel.get(ctr.Id).add(str);
                    }
                    else {
                        mapCtrSharingTodel.put(ctr.Id, new set<string>{str});
                    }
                }
                
             }
            system.debug('## mapCtrSharingTodel'+ mapCtrSharingTodel);
        }
        
      for(Contract__Share ctrShare:[SELECT Id, parentId, UserOrGroupId,rowCause 
                                    FROM Contract__Share 
                                    WHERE parentId IN :mapCtrSharingTodel.keyset()
                                   and rowCause=:'Manual']){
                system.debug('##ctrShare.parentId'+ctrShare.parentId);
                system.debug('##ctrShare.UserOrGroupId'+ctrShare.UserOrGroupId); 
                                       
                string usrgrpId=string.valueOf(ctrShare.UserOrGroupId);
                string shortenedId=usrgrpId.substring(0,15);
                                       
                if(mapCtrSharingTodel.get(ctrShare.parentId).contains(shortenedId))
                    lsttbdCtrShare.add(ctrShare); 
                    
      }
      
       system.debug('## lsttbdCtrShare'+lsttbdCtrShare);
        
       if(lsttbdCtrShare.size()>0)  {
            try {delete lsttbdCtrShare;}
        	catch(exception e){system.debug('##e'+e.getMessage());}
        }
        
    }
    
}