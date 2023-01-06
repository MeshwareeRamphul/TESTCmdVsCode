public without sharing class AP05_Sing_mangageEventTeam {
    /*----------------------------------------------------------------------
    -- - Name          : AP05_Sing_mangageEventTeam
    -- - Author        : Spoon
    -- - Description   : trigger handler for AP05_Sing_mangageEventTeam
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 11-OCT-2021  MRA    1.0      Add business owner to sourcing team (on create of event / update of  BO)
    -- 21-DEC-2021  ARA    1.1      Share Sourcing Event with vendors
    -- 19-JAN-2022  ARA    1.2      Share Sourcing Event with new/activated users
    -- 21-JAN-2022  ARA    1.3      SP-02919    Delete sharing event for Eliminated participant
    -- 03-FEB-2022  ARA    1.4      SP-03335 populate SourcingTeamMember__c field on the contract by Team_Member__c
    -- 02-MAR-2022  ARA    1.5      SP-03490 recalculate sharing
    -- 03-MAR-2022  MRA    1.6      Release 1 -> Send email template w.r.t LanguageLocaleKey of user (en_US,fr,de)
    -------------------------------------------------------------------------*/

    public static void addBoToTeam(Map<String,String> mapEventIdBO/*,Set<id> setIdEvent*/){
        Set<id>eventIdSet=new Set<id>();
        List<Sourcing_Event_Team__c> lstTeam = new List<Sourcing_Event_Team__c>();
        //delete existing sourcing team for old business owner (added automatically via trigger first)
        List<Sourcing_Event_Team__c> lstTeamToDel = [SELECT id, Sourcing_Event__c 
                                                    FROM Sourcing_Event_Team__c
                                                    WHERE Role__c = '016'
                                                    AND Sourcing_Event__c IN :mapEventIdBO.keyset()
                                                    AND TECH_Sing_AutomaticEntry__c = :true];
        
        if(lstTeamToDel.size() > 0)
            delete lstTeamToDel;
        
        for(Id eventId : mapEventIdBO.keyset()){
            eventIdSet.add(eventId);
            if (mapEventIdBO.get(eventId) <> null ){
                Sourcing_Event_Team__c team = new Sourcing_Event_Team__c(Sourcing_Event__c = eventId,
                                                                    Team_Member__c = mapEventIdBO.get(eventId),
                                                                    Role__c = '016',
                                                                    Event_Access_Level__c = 'Read',
                                                                    TECH_Sing_AutomaticEntry__c = true);
                lstTeam.add(team);
            }
        }
        
        if(lstTeam.size() > 0)
            insert lstTeam;
        
        if(eventIdSet.size() > 0)
            manageEventSharing(eventIdSet);
    }

    public static void addOwnerToTeam(Map<String,String> mapEventIdOwner/*,Set<id> setIdEvent*/){
        Set<id>eventIdSet = new Set<id>();
        List<Sourcing_Event_Team__c> lstTeam = new List<Sourcing_Event_Team__c>();
        //delete existing sourcing team for old business owner (added automatically via trigger first)
        List<Sourcing_Event_Team__c> lstTeamToDel = [SELECT id, Sourcing_Event__c 
                                                    FROM Sourcing_Event_Team__c
                                                    WHERE Role__c = '001'
                                                    AND Sourcing_Event__c IN :mapEventIdOwner.keyset()
                                                    AND TECH_Sing_AutomaticEntry__c = :true];
        
        if(lstTeamToDel.size() > 0)
            delete lstTeamToDel;
        
        for(Id eventId : mapEventIdOwner.keyset()){
            eventIdSet.add(eventId);
            if (mapEventIdOwner.get(eventId) <> null ){
                Sourcing_Event_Team__c team = new Sourcing_Event_Team__c(Sourcing_Event__c = eventId,
                                                                        Team_Member__c = mapEventIdOwner.get(eventId),
                                                                        Role__c = '001',
                                                                        Event_Access_Level__c = 'Edit',
                                                                        TECH_Sing_AutomaticEntry__c = true);
                lstTeam.add(team);
            }
        }
        
        if(lstTeam.size() > 0)
            insert lstTeam;
        
        if(eventIdSet.size() > 0)
            manageEventSharing(eventIdSet);
    }
        
    public static void manageEventSharing(Set<id> setEventId){
        // Set<id>setEventId=new Set<id>();
        Map<String, List<Sourcing_Event_Team__c>> mapKeySharing = new Map<String,List<Sourcing_Event_Team__c>>();
        Set<String> setUniqueKey = new Set<String>();
        List<Sourcing_Event__share> lstSharingToDel = new List<Sourcing_Event__share>();
        List<Sourcing_Event__share> lstSharingToInsert = new List<Sourcing_Event__share>();
        Map<String,String> mapGrpNameId = new Map<String,String>();
        Set<String>groupNames = new Set<String>();
        
        if(setEventId.size() > 0){
            List<Sourcing_Event__share> lstShareSE = [SELECT id,parentId,accesslevel,
                                                      UserOrGroupId,RowCause
                                                    FROM Sourcing_Event__share  
                                                    WHERE parentid IN :setEventId
                                                    AND RowCause <> 'Owner'
                                                    AND RowCause = 'Manual'];

            if(lstShareSE.size() > 0){
                for(Sourcing_Event__share  eventshare:lstShareSE){
                    lstSharingToDel.add(eventshare);
                }
            }
        }
        
        if(lstSharingToDel.size() > 0)
            delete lstSharingToDel;
        if(setEventId.size() > 0){
            system.debug('***** setEventId '+setEventId);
            List<Sourcing_Event_Team__c> lstSETeam = [SELECT id,Sourcing_Event__c,Team_Member__c,
                                                      Role__c,Event_Access_Level__c,Member_Group__c,Sourcing_Event__r.ownerId
                                                    FROM Sourcing_Event_Team__c 
                                                    WHERE Sourcing_Event__c IN :setEventId /*AND Event_Access_Level__c!=:'Read'*/];
            if(lstSETeam.size() > 0){
                for(Sourcing_Event_Team__c team: lstSETeam){   
                    if(team.Sourcing_Event__r.ownerId != team.Team_Member__c) {                             
                        if(mapKeySharing.containsKey(team.Sourcing_Event__c)) {
                            List<Sourcing_Event_Team__c> lstTeam = mapKeySharing.get(team.Sourcing_Event__c);
                            lstTeam.add(team);
                            mapKeySharing.put(team.Sourcing_Event__c, lstTeam);
                        } else {
                            mapKeySharing.put(team.Sourcing_Event__c, new List<Sourcing_Event_Team__c> {team});
                        }
                    }
                                                    
                    //build mapGrpNameId for groups which needs to be queried   
                    if(!(String.isBlank(team.Member_Group__c)))                        groupNames.add(team.Member_Group__c);                       
                }
            }
        }

        if(groupNames.size() > 0){            for(group grp:[SELECT id,name FROM group WHERE name in:groupNames]){                mapGrpNameId.put(grp.name,grp.id);            }        }
        if(setEventId.size() > 0){
            for(String eventId:mapKeySharing.keyset()){    
                for(Sourcing_Event_Team__c team : mapKeySharing.get(eventId)){                  
                    if(!setUniqueKey.contains(eventId+'-'+team.Member_Group__c)){
                        Sourcing_Event__share newSharing = new Sourcing_Event__share ();
                        newSharing.accesslevel = team.Event_Access_Level__c;
                        if(!(String.isblank(team.Member_Group__c))){                            newSharing.UserOrGroupId = mapGrpNameId.get(team.Member_Group__c);                        }
                        else{
                            newSharing.UserOrGroupId = team.Team_Member__c;
                        }
                        
                        newSharing.parentId = team.Sourcing_Event__c;
                        lstSharingToInsert.add(newSharing);
                    }
                    //build setUniqueKey to ensure that duplicate Sourcing_Event__share is not generated
                    if(!(String.isblank(team.Member_Group__c)))                       setUniqueKey.add(eventId+'-'+team.Member_Group__c);
                    else
                        setUniqueKey.add(eventId+'-'+team.Team_Member__c);
                    
                }
            }
        }

        if(lstSharingToInsert.size() > 0)
            try{insert lstSharingToInsert;
                }
        catch(Exception e){system.debug('### sharing team lstSharingToInsert'+lstSharingToInsert + ' - error'+ e.getMessage());}
        //MRA 01/07 gerenerate sharing if linked to src requ (copy sharing from src req on event)
        AP73_ManageSrcReqSharing.calculateSharingEventCreation(setEventId);
        //shareWithAllBuyers(setEventId);
    }

    public static void shareWithAllBuyers(Set<Id> eventReadToAllBuyers){
        system.debug('##Starting method shareWithAllBuyers'+eventReadToAllBuyers);
        List<Sourcing_Event__share> lstSharingToInsert = new List<Sourcing_Event__share>();
        Id AllbuyerGroup = [SELECT Id FROM group WHERE developername=:'cTin_All_Buyers' LIMIT 1].Id;
        for(Id eventid : eventReadToAllBuyers){
            Sourcing_Event__share newSharing = new Sourcing_Event__share ();
            newSharing.accesslevel = 'Read';
            newSharing.UserOrGroupId = AllbuyerGroup; //to query dynamically
            newSharing.parentId = eventid;
            
            lstSharingToInsert.add(newSharing);
        }
        // system.debug('## number of sharing to insert'+lstSharingToInsert);
        try{
                system.debug('## ok');
                insert lstSharingToInsert;
        }
        catch(exception e){
            system.debug('##exception'+e.getMessage());
        }
    }

    public static void shareWithTeamOnly(Set<Id> eventPrivateToTeams){       
        manageEventSharing(eventPrivateToTeams);        
    }
            
    public static void shareWithEnityOnly(Set<Id> eventPrivateToEntity){   
        manageEventSharing(eventPrivateToEntity);        
        Map<String,String> mapEventEntity = new Map<String,String>();
        Map<Id, Id> mapEventOwnerId = new Map<Id, Id>();
        Map<String,List<User>> mapKeySharing = new Map<String,List<User>>();
        for(Sourcing_Event__c event : [SELECT id,TECH_OwnerEntity__c, OwnerId FROM Sourcing_Event__c WHERE id IN:eventPrivateToEntity]){
            mapEventEntity.put(event.id, event.TECH_OwnerEntity__c);
            if(event.OwnerId != null){
                mapEventOwnerId.put(event.id,event.OwnerId);
            }
        }
        Id buyerProfileId = [SELECT Id FROM profile WHERE name = :'cTin - Contract Buyer'].Id;
        for(User usr: [SELECT id,cTin_Entity__c FROM user WHERE profileId=:buyerProfileId AND cTin_Entity__c IN :mapEventEntity.values()
                    AND isactive = :true]){
            if(mapKeySharing.containsKey(usr.cTin_Entity__c)) {
                List<user> lstusr = mapKeySharing.get(usr.cTin_Entity__c);
                lstusr.add(usr);
                mapKeySharing.put(usr.cTin_Entity__c, lstusr);
            } else {
                mapKeySharing.put(usr.cTin_Entity__c, new List<User> {usr});
            }
        }
        
        List<Sourcing_Event__share>lstSharingToInsert = new List<Sourcing_Event__share>();
        for(String eventId: mapEventEntity.keyset()){
            String entitySrc = mapEventEntity.get(eventId);
            if(mapKeySharing.containsKey(entitySrc)){
                for(User u:mapKeySharing.get(entitySrc)){
                    if(u.Id != mapEventOwnerId.get(eventId)){
                        Sourcing_Event__share newSharing = new Sourcing_Event__share ();
                        newSharing.accesslevel = 'Read';
                        newSharing.UserOrGroupId = u.id; //to query dynamically
                        newSharing.parentId = eventId;
                        
                        lstSharingToInsert.add(newSharing);
                    }
                }
            }
        }
        
        if(lstSharingToInsert.size() > 0)
            insert lstSharingToInsert;
    }
        
    // 02-MAR-2022  ARA  SP-03490
    @future    
    public static void recalculateSharing(Id eventId){
        System.debug('***eventId '+ eventId);
        Set<Id> setIdSE;
        List<User> lstUser = new List<User>();
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, Set<Id>> mapContactBid = new Map<Id, Set<Id>>();
        Map<Id, Sourcing_Event__share> mapEventShare = new Map<Id, Sourcing_Event__share>();
        List<Sourcing_Event__share> lstEventShare = new List<Sourcing_Event__share>();
        String[] lstSEStatus = new String[]{AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED, AP_Constant.SOURCING_EVENT_STATUS_PENDING_SELECTION, AP_Constant.SOURCING_EVENT_STATUS_COMPLETED};
        String[] lstBidStatus = new String[]{AP_Constant.PARTICIPANT_STATUS_CONFIRMED, AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS, AP_Constant.PARTICIPANT_STATUS_SHORTLISTED, AP_Constant.PARTICIPANT_STATUS_AWARDEE};

        for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Participant_Name__c, Sourcing_Event__c, Sourcing_Event__r.Legal_Entity__c, Contact_Bidder__c, Contact_Bidder__r.Email, Contact_Bidder__r.Name, Sing_Account__c  FROM Bidder__c WHERE Contact_Bidder__c != NULL AND Sourcing_Event__c = :eventId]){

            setAccountId.add(bid.Sing_Account__c);
            if(lstBidStatus.contains(bid.Bidder_Status__c)){
                setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                if(setIdSE == null){                    setIdSE = new Set<Id>();                }
                setIdSE.add(bid.Sourcing_Event__c);
                mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
            }
        }
        
        System.debug('***setAccountId '+setAccountId);
        System.debug('***mapContactBid '+mapContactBid);

        if(setAccountId.size() > 0){         
            for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Participant_Name__c, Sourcing_Event__c, Sourcing_Event__r.Legal_Entity__c, Contact_Bidder__c, Contact_Bidder__r.Email, Contact_Bidder__r.Name, Sing_Account__c 
                                FROM Bidder__c
                                WHERE Contact_Bidder__c != NULL
                                AND Sourcing_Event__c = :eventId
                                AND Sourcing_Event__r.Sourcing_Status__c IN :lstSEStatus
                                AND Sing_Account__c IN :setAccountId
                                AND Bidder_Status__c IN :lstBidStatus]){

                setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                if(setIdSE == null){
                    setIdSE = new Set<Id>();
                }
                setIdSE.add(bid.Sourcing_Event__c);
                mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
            }
        }

        if(mapContactBid.size() > 0){
            //Give the sharing of all Sourcing Event related to account of the current user
            for(User user : [SELECT Id, Name, ContactId FROM User WHERE isActive = TRUE AND ContactId IN :mapContactBid.keyset()]){
                if(mapContactBid.containsKey(user.ContactId)){
                    for(Id seId : mapContactBid.get(user.ContactId)){
                        Sourcing_Event__share eventShare = new Sourcing_Event__share();
                        eventShare.UserOrGroupId = user.Id;
                        eventShare.ParentId = seId;
                        eventShare.AccessLevel = 'Edit';
                        eventShare.RowCause = 'Manual';
                        lstEventShare.add(eventShare);
                    }
                }
            }
        }

        System.debug('***lstEventShare size '+lstEventShare.size());
        
        if(lstEventShare.size() > 0){
            insert lstEventShare;
        }
    }
        
    @future    
    public static void shareWithPortalUsers(Set<Id> setEventIds){
        Set<Id> setIdSE;
        List<User> lstUser = new List<User>();
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, Set<Id>> mapContactBid = new Map<Id, Set<Id>>();
        Map<Id, Sourcing_Event__share> mapEventShare = new Map<Id, Sourcing_Event__share>();
        List<Sourcing_Event__share> lstEventShare = new List<Sourcing_Event__share>();
        String[] lstSEStatus = new String[]{AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED, AP_Constant.SOURCING_EVENT_STATUS_PENDING_SELECTION, AP_Constant.SOURCING_EVENT_STATUS_COMPLETED};
        String[] lstBidStatus = new String[]{AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS, AP_Constant.PARTICIPANT_STATUS_SHORTLISTED, AP_Constant.PARTICIPANT_STATUS_AWARDEE};

        for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Participant_Name__c, 
                             Sourcing_Event__c, Sourcing_Event__r.Legal_Entity__c, 
                             Contact_Bidder__c, Contact_Bidder__r.Email, Contact_Bidder__r.Name, 
                             Sing_Account__c 
                            FROM Bidder__c
                            WHERE Contact_Bidder__c != NULL
                            AND Sourcing_Event__c IN :setEventIds]){

            setAccountId.add(bid.Sing_Account__c);
            if(lstBidStatus.contains(bid.Bidder_Status__c)){
                setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                if(setIdSE == null){
                    setIdSE = new Set<Id>();
                }
                setIdSE.add(bid.Sourcing_Event__c);
                mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
            }
        }
        
        System.debug('***setAccountId '+setAccountId);
        System.debug('***mapContactBid '+mapContactBid);

        if(setAccountId.size() > 0){         
            for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Participant_Name__c, Sourcing_Event__c, 
                                 Sourcing_Event__r.Legal_Entity__c, Contact_Bidder__c, 
                                 Contact_Bidder__r.Email, Contact_Bidder__r.Name, Sing_Account__c 
                                FROM Bidder__c
                                WHERE Contact_Bidder__c != NULL
                                AND Sourcing_Event__c NOT IN :setEventIds
                                AND Sourcing_Event__r.Sourcing_Status__c IN :lstSEStatus
                                AND Sing_Account__c IN :setAccountId
                                AND Bidder_Status__c IN :lstBidStatus]){

                setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                if(setIdSE == null){
                    setIdSE = new Set<Id>();
                }
                setIdSE.add(bid.Sourcing_Event__c);
                mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
            }
        }

        if(mapContactBid.size() > 0){
            //Give the sharing of all Sourcing Event related to account of the current user
            for(User user : [SELECT Id, Name, ContactId FROM User WHERE isActive = TRUE AND ContactId IN :mapContactBid.keyset()]){
                if(mapContactBid.containsKey(user.ContactId)){
                    for(Id seId : mapContactBid.get(user.ContactId)){
                        Sourcing_Event__share eventShare = new Sourcing_Event__share();
                        eventShare.UserOrGroupId = user.Id;
                        eventShare.ParentId = seId;
                        eventShare.AccessLevel = 'Edit';
                        eventShare.RowCause = 'Manual';
                        lstEventShare.add(eventShare);
                    }
                }
            }
        }

        System.debug('***lstEventShare size '+lstEventShare.size());
        
        if(lstEventShare.size() > 0){
            insert lstEventShare;
        }
    }

    // 19-JAN-2021  ARA    1.2      Share Sourcing Event with new/activated users
    public static void shareWithPortalNewUsers(List<User> lstUser){
        Set<Id> setIdSE;
        Set<Id> setContactId = new Set<id>();
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> setEventIds = new Set<Id>();
        Map<Id, Set<Id>> mapContactBid = new Map<Id, Set<Id>>();
        List<Sourcing_Event__share> lstEventShare = new List<Sourcing_Event__share>();
        String[] lstSEStatus = new String[]{AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED, AP_Constant.SOURCING_EVENT_STATUS_PENDING_SELECTION, AP_Constant.SOURCING_EVENT_STATUS_COMPLETED};
        String[] lstBidStatus = new String[]{AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS,AP_Constant.PARTICIPANT_STATUS_CONFIRMED, AP_Constant.PARTICIPANT_STATUS_SHORTLISTED, AP_Constant.PARTICIPANT_STATUS_AWARDEE};
        
        for(User user : lstUser){
            setContactId.add(user.ContactId);
        }

        if(setContactId.size() > 0){
            for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Sourcing_Event__c, Contact_Bidder__c, Sing_Account__c 
                                FROM Bidder__c 
                                WHERE Contact_Bidder__c IN :setContactId
                                AND Bidder_Status__c IN :lstBidStatus
                                AND Sourcing_Event__r.Sourcing_Status__c IN :lstSEStatus]){
                
                setAccountId.add(bid.Sing_Account__c);
                setEventIds.add(bid.Sourcing_Event__c);
                setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                if(setIdSE == null){
                    setIdSE = new Set<Id>();
                }
                setIdSE.add(bid.Sourcing_Event__c);
                mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
            }

            if(setAccountId.size() > 0){     
                for(Bidder__c bid : [SELECT Id, Bidder_Status__c, Participant_Name__c, Sourcing_Event__c, Sourcing_Event__r.Legal_Entity__c, Contact_Bidder__c, Contact_Bidder__r.Email, Contact_Bidder__r.Name, Sing_Account__c 
                                    FROM Bidder__c
                                    WHERE Contact_Bidder__c != NULL
                                    AND Sourcing_Event__c NOT IN :setEventIds
                                    AND Sourcing_Event__r.Sourcing_Status__c IN :lstSEStatus
                                    AND Sing_Account__c IN :setAccountId
                                    AND Bidder_Status__c IN :lstBidStatus]){
    
                    setIdSE = mapContactBid.get(bid.Contact_Bidder__c);
                    if(setIdSE == null){
                        setIdSE = new Set<Id>();
                    }
                    setIdSE.add(bid.Sourcing_Event__c);
                    mapContactBid.put(bid.Contact_Bidder__c, setIdSE);
                }
            }

            if(mapContactBid.size() > 0){
                for(User user : lstUser){
                    if(mapContactBid.containsKey(user.ContactId)){
                        for(Id seId : mapContactBid.get(user.ContactId)){
                            Sourcing_Event__share eventShare = new Sourcing_Event__share();
                            eventShare.UserOrGroupId = user.Id;
                            eventShare.ParentId = seId;
                            eventShare.AccessLevel = 'Edit';
                            eventShare.RowCause = 'Manual';
                            lstEventShare.add(eventShare);
                        }
                    }
                }
            }

            System.debug('**** lstEventShare '+lstEventShare);
            if(lstEventShare.size() > 0){
                insert lstEventShare;
            }
        }
    }

    // 21-JAN-2021  ARA    1.3      Delete sharing event for eliminated participant
    public static void deleteSharingEvent(List<Bidder__c> lstBidder){
        Set<Id> setContactId = new Set<Id>();
        Map<Id, Id> mapUser = new Map<Id, Id>();
        Map<Id, Id> mapSE = new Map<Id, Id>();
        Map<Id, Id> mapUserId = new Map<Id, Id>();
        Map<Id, Sourcing_Event__share> mapEventShareToDelete = new Map<Id, Sourcing_Event__share>();
        //AMA
        List<bidder__c> lstBidToSetTechEliminated = new List<bidder__c>();

        for(Bidder__c bid : lstBidder){
            setContactId.add(bid.Contact_Bidder__c);
            mapSE.put(bid.Id, bid.Sourcing_Event__c);
        }

        //AMA
        List<Bidder__c> lstBidAllRound = [select id,Contact_Bidder__c,Sourcing_Event__c,Tech_eliminated__c from Bidder__c where Sourcing_Event__c in :mapSE.values() and Contact_Bidder__c in :setContactId];
        if(lstBidAllRound.size() > 0){
            for(Bidder__c bid : lstBidder){
                for(Bidder__c bidRound : lstBidAllRound){
                    if(bidRound.Sourcing_Event__c == bid.Sourcing_Event__c && bidRound.Contact_Bidder__c == bid.Contact_Bidder__c){
                        bidRound.Tech_eliminated__c=true;
                        lstBidToSetTechEliminated.add(bidRound);
                    }
                }
            }
        }

        if(setContactId.size() > 0){
            for(User user : [SELECT Id, Name, ContactId FROM User WHERE ContactId IN :setContactId]){
                mapUser.put(user.ContactId, user.Id);
                mapUserId.put(user.ContactId, user.Id);
            }

            List<Sourcing_Event__share> lstEventShare = [SELECT Id, parentId, UserOrGroupId 
                                                         FROM Sourcing_Event__share 
                                                         WHERE UserOrGroupId IN :mapUser.values() 
                                                         AND parentId = :mapSE.values()];

            if(lstEventShare.size() > 0){
                for(Bidder__c bid : lstBidder){
                    for(Sourcing_Event__share shareEvent : lstEventShare){
                        if(shareEvent.parentId == mapSE.get(bid.Id) && shareEvent.UserOrGroupId == mapUserId.get(bid.Contact_Bidder__c)){
                            mapEventShareToDelete.put(shareEvent.ID, shareEvent);
                        }
                    }
                }
            }

            if(mapEventShareToDelete.size() > 0){
                delete mapEventShareToDelete.values();
            }
            //AMA
            if(lstBidToSetTechEliminated.size() > 0){
                update lstBidToSetTechEliminated;
            }
        }
    }

    // 03-FEB-2021  ARA    SP-03335
    public static void setEventSourcingTeamMember(Set<Id> setIdSE){
        Map<Id, String> mapNewTeamMember = new Map<Id, String>();
        List<Sourcing_Event__c> lstSE = new List<Sourcing_Event__c>();
        String teamMember;

        List<Sourcing_Event_Team__c> lstSETeam = [SELECT Id, Sourcing_Event__c, Team_Member__c FROM Sourcing_Event_Team__c WHERE Sourcing_Event__c IN :setIdSE AND Team_Member__c != null];
        if(lstSETeam.size() > 0){
            for(Sourcing_Event_Team__c team : lstSETeam){
                teamMember = mapNewTeamMember.get(team.Sourcing_Event__c);
                if(teamMember == '' || teamMember == null){
                    teamMember = team.Team_Member__c;
                }else if(!teamMember.contains(team.Team_Member__c)){
                    teamMember += ';' + team.Team_Member__c;
                }
                mapNewTeamMember.put(team.Sourcing_Event__c, teamMember);
            }

            for(Id seId : mapNewTeamMember.keySet()){
                lstSE.add(new Sourcing_Event__c(Id = seId, SourcingTeamMember__c = mapNewTeamMember.get(seId)));
            }

            if(lstSE.size() > 0){
                update lstSE;
            }
        }
    }
    
    //04/02/2022 MRA - notify new member
    public static void notifyMember(List<Sourcing_Event_Team__c>lstNewTeam){
    system.debug('## notifyMember');
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Set<id>setRecipient = new Set<id>();
        set<string> SetGroupname=new set<string>();
        map<string,set<id>>mapGrpMembers=new map<string,set<id>>();
        map<id,user> mapUserIdDetails=new map<id,user>();
        set<id> setGrpmembers=new set<id>();
         //MAP EN
        Map<String, String> roleMapEN = new Map<String, String>{'000' => 'Buyer in charge (Contract Owner)', '001'=>'Buyer/Sourcing Expert', 
        '002'=> 'Procurement Manager','003'=>'CPO',
        '004'=>'Legal', '005'=>'Audit', '006'=>'Business Stakeholder',
        '007'=>'Business Expert', '008'=>'Senior Executive', '009'=>'Legal Signatory Representative',
        '010'=>'Budget Holder', '011'=>'IT Security', '012'=>'Data Privacy',
        '013'=>'Outsourcing Expert', '014'=>'Fiscal & Finance Expert', '015'=>'Contract co-owner',
        '016'=>'Business Owner', '017'=>'Contract Owner', '018'=>'Operational Resilience','Risk'=>'Risk',
        '019'=>'Co-Sourcing Owner',
        'Compliance'=>'Compliance'};
         //MAP FR
         Map<String, String> roleMapFR = new Map<String, String>{'000'=>'Acheteur', '001'=>'Acheteur', 
        '002'=> 'Procurement Manager','003'=>'CPO',
        '004'=>'Direction Juridique', '005'=>'Audit', '006'=>'Partenaire métier',
        '007'=>'Expert métier', '008'=>'Senior Executive', '009'=>'Représentant légal',
        '010'=>'Responsable Budget', '011'=>'Securité IT', '012'=>'Sécurité des données',
        '013'=>'Expert sous-traitance', '014'=>'Expert Finance & Fiscalité', '015'=>'Co-responsable du contrat',
        '016'=>'Partenaire métier', '017'=>'Propriétaire du contrat', '018'=>'Operational Resilience',
        '019'=>'Co-Acheteur',
        'Risk'=>'Risk',
        'Compliance'=>'Compliance'};
        //MAP de
        Map<String, String> roleMapde = new Map<String, String>{'000'=>'Verantwortlicher Einkäufer','001'=>'Verantwortlicher Einkäufer', 
        '002'=> 'Einkäufer / Sourcing Expert','003'=>'CPO',
        '004'=>'Rechtsabteilung', '005'=>'Revision', '006'=>'Ansprechpartner im Fachbereich',
        '007'=>'Fachbereichsexperte', '008'=>'Senior Management', '009'=>'rechtlicher/unterschriftsberechtigter Vertreter',
        '010'=>'Budgetverantwortlicher', '011'=>'Securité IT', '012'=>'Datenschutz',
        '013'=>'Outsourcing Experte', '014'=>'Steuer und Finanz Experte', '015'=>'Vertrags-Co-Owner',
        '016'=>'Ansprechpartner im Fachbereichr', '017'=>'Vertragseigentümer', '018'=>'Operational Resilience',
        '019'=>'Co-Sourcing-Eigentümer',
        'Risk'=>'Risk',
        'Compliance'=>'Compliance'};
        
        List<String>lstCcDestinataire = new List<String>();
        //EmailTemplate emailTemplateEng = AP_Constant.SourcingTeam_NewTeam_ENG;
        //EmailTemplate emailTemplateFR = AP_Constant.SourcingTeam_NewTeam_FR;
        emailtemplate temp;
        map<string,emailtemplate>mapLanguageTemp=new map<string,emailTemplate>();
        
        for(Emailtemplate template : [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE (
          DeveloperName ='SourcingTeam_NewTeam_ENG' OR DeveloperName ='SourcingTeam_NewTeam_FR' OR DeveloperName ='SourcingTeam_NewTeam_GE')]){
           if(template.DeveloperName=='SourcingTeam_NewTeam_ENG') 
                  mapLanguageTemp.put('En',template );
           if(template.DeveloperName=='SourcingTeam_NewTeam_GE') 
                  mapLanguageTemp.put('DE',template );
           if(template.DeveloperName=='SourcingTeam_NewTeam_FR') 
                  mapLanguageTemp.put('FR',template );      
                 
        }
        
        //get groupname if any
        for(Sourcing_Event_Team__c teams : [SELECT Id,Member_Group__c                                           
                                            FROM Sourcing_Event_Team__c WHERE id IN :lstNewTeam and Member_Group__c!='']){
                SetGroupname.add(teams.Member_Group__c);
        }
        
        //get user id for group
        if(SetGroupname.size()>0){
            for(Groupmember grpMember: [Select UserorGroupId,group.name From GroupMember WHERE group.name IN:SetGroupname ]){
                    setGrpmembers.add(grpMember.UserorGroupId);
                    if(!mapGrpMembers.containsKey(grpMember.group.name)){
                     mapGrpMembers.put(grpMember.group.name, new Set<id>{grpMember.UserorGroupId});
            
                    }else{
                         mapGrpMembers.get(grpMember.group.name).add(grpMember.UserorGroupId);
                    }
            }     
            
            //get firstname, lastname and email for each groupmember in mapGrpMembers   
            for(User usr: [select id,firstname,lastname,email,LanguageLocaleKey  from user where id IN:setGrpmembers]){
                mapUserIdDetails.put(usr.id,usr);
            }
        }                    
        /*List<Sourcing_Event_Team__c> lstteams = [SELECT Id, Sourcing_Event_Team__c.Role__c,Team_Member__c,Team_Member__r.email,
                                                 Sourcing_Event_Team__c.TECH_OwnerName__c,
                                                 Sourcing_Event__r.Owner.Email,
                                                 Sourcing_Event_Team__c.TECH_SourcingEventName__c
                                                FROM Sourcing_Event_Team__c WHERE id IN :lstNewTeam
                                                ];*/
        
        //if(lstteams.size() > 0){
            for(Sourcing_Event_Team__c teams : [SELECT Id, Sourcing_Event_Team__c.Role__c,Team_Member__c,Team_Member__r.email,
                                                 Sourcing_Event_Team__c.TECH_OwnerName__c,Team_Member__r.LanguageLocaleKey,
                                                 Sourcing_Event__r.Owner.Email,Team_Member__r.name,Sourcing_Event__c,Member_Group__c,
                                                 Sourcing_Event_Team__c.TECH_SourcingEventName__c,TECH_LinkToSrcEvent__c, Tech_TeamMemberName__c
                                                FROM Sourcing_Event_Team__c WHERE id IN :lstNewTeam ]){
                List<String> lstDestinataire = new List<String>();
                String body='';
                lstCcDestinataire.add(teams.Sourcing_Event__r.Owner.Email);
               
                if(setRecipient.size() > 0 && !setRecipient.contains(teams.Team_Member__c) || (setRecipient.size() == 0 )){
                if(teams.Team_Member__c!=null){
                    
                    lstDestinataire.add(teams.Team_Member__c);

                    if(teams.Team_Member__r.LanguageLocaleKey=='fr'){
                        temp=mapLanguageTemp.get('FR');
                        body = String.valueOf(temp.HtmlValue);
                        body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',teams.Team_Member__r.name );
                        body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapFR.get(teams.Role__c));
                    }
                    else if(teams.Team_Member__r.LanguageLocaleKey=='de'){
                        temp=mapLanguageTemp.get('DE');
                        body = String.valueOf(temp.HtmlValue);
                        body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',teams.Team_Member__r.name ); 
                        body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapde.get(teams.Role__c));
                        body=body.replace('{!Sourcing_Event_Team__c.Sourcing_EventId__c}',teams.Sourcing_Event__c);
                    }
                    else{
                        temp=mapLanguageTemp.get('En');
                        body = String.valueOf(temp.HtmlValue);
                        body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',teams.Team_Member__r.name );                        
                        body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapEN.get(teams.Role__c));
                       // body.replace('{!Sourcing_Event_Team__c.TECH_SourcingEventName__c}',teams.TECH_LinkToSrcEvent__c);


                    }
                    /*if(teams.Team_Member__r.LanguageLocaleKey=='de'){
                        body = String.valueOf(emailTemplateDE.HtmlValue);
                        body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapDE.get(teams.Role__c));
                    } */   
                        
                   

                    
                    
                    setRecipient.add(teams.Team_Member__c);
                    /*
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setTemplateID(emailTemplate.Id);
                    email.setTargetObjectId(teams.Team_Member__c);
                    email.saveAsActivity=false;
                    //email.setWhatId(teams.Id);
                    email.setToAddresses(new List<String>{teams.Team_Member__r.Email});
                    email.setCcAddresses(new List<String>{teams.Sourcing_Event__r.Owner.Email});
            
                    lstEmails.add(email);
                    setRecipient.add(teams.Team_Member__c);
                    */
                    }
                    else{
                       for(Id usrId: mapGrpMembers.get(teams.Member_Group__c)){
                           lstDestinataire.add(usrId);
                           if(mapUserIdDetails.get(usrId).LanguageLocaleKey=='fr'){
                                temp=mapLanguageTemp.get('FR');
                                body = String.valueOf(temp.HtmlValue);
                                body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',mapUserIdDetails.get(usrId).firstname + ' ' + mapUserIdDetails.get(usrId).lastname);
                                body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapFR.get(teams.Role__c));
                           }
                           else if(mapUserIdDetails.get(usrId).LanguageLocaleKey=='de'){
                                temp=mapLanguageTemp.get('DE');
                                body = String.valueOf(temp.HtmlValue);
                                body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',mapUserIdDetails.get(usrId).firstname + ' ' + mapUserIdDetails.get(usrId).lastname ); 
                                body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapde.get(teams.Role__c));
                                body=body.replace('{!Sourcing_Event_Team__c.Sourcing_EventId__c}',teams.Sourcing_Event__c);
                            }
                           else{
                                temp=mapLanguageTemp.get('En');
                                body = String.valueOf(temp.HtmlValue);
                                body = body.replace('{!Sourcing_Event_Team__c.Team_Member__r.name}',mapUserIdDetails.get(usrId).firstname + ' ' + mapUserIdDetails.get(usrId).lastname);                        
                                body = body.replace('{!Sourcing_Event_Team__c.Role__c}', roleMapEN.get(teams.Role__c));
                               // body.replace('{!Sourcing_Event_Team__c.TECH_SourcingEventName__c}',teams.TECH_LinkToSrcEvent__c);        
                            }
                            
                             setRecipient.add(usrId);
                       
                       }
                    
                    }
                   
                //body = body.replace('{!Sourcing_Event_Team__c.TECH_SourcingEventName__c}', teams.TECH_SourcingEventName__c);
                    body = body.replace('{!Sourcing_Event_Team__c.Tech_TeamMemberName__c}',teams.Tech_TeamMemberName__c);
                    body = body.replace('{!Sourcing_Event_Team__c.TECH_OwnerName__c}', teams.TECH_OwnerName__c);
                    body=body.replace('{!Sourcing_Event_Team__c.TECH_SourcingEventName__c}',teams.TECH_LinkToSrcEvent__c);
                
                   String subject = String.valueOf(temp.Subject).replace('{!Sourcing_Event_Team__c.TECH_SourcingEventName__c} ',teams.TECH_SourcingEventName__c);
                    
                   Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                   email.setToaddresses(lstDestinataire);
                   email.setCcaddresses(lstCcDestinataire);
                    
                   
                   email.setTemplateId(temp.Id);
                   email.setSubject(subject);
                   email.setHtmlBody(body);

                   messages.add(email); 
                }
            }
        //}

         if(!test.isRunningTest()){
            if(messages.size() > 0){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) 
                {
                System.debug('The email was sent successfully.');
                } else {
                System.debug('The email failed to send: ' +  results[0].errors[0].message);
                }
            }
        }
    }
}