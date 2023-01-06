public class ParticpantTriggerHandler {
/*----------------------------------------------------------------------
-- - Name          : ParticpantTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Bidder__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 12-Nov-2021  MRA  1.0       Deactivate Community user when bidder status = eliminated and bidder is not part of any other events
-- 14-JAN-2022  ARA  1.1       SP-03219: Send welcome email for confirmed participant
-- 27-JAN-2022  ARA  1.2       SP-03219: Share previously added documents to the new Participant
-- 24-FEB-2022  MRA  1.3       SP-02927  Block participants from being added in duplicate
-------------------------------------------------------------------------*/
    
    public static void BeforeInsertHandler(List<Bidder__c> lstParticipant){
        // add current round for Confirmed participant
        List<Bidder__c> lstBid = new List<Bidder__c>();
		set<id> setEventIds=new set<id>();
        
      
        // 14-JAN-2022  ARA  2.0       SP-03219
        for(Bidder__c bid : lstParticipant){
            setEventIds.add(bid.Sourcing_Event__c);
            if(bid.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_CONFIRMED){
                lstBid.add(bid);
            }
        }
        
        if(setEventIds.size()>0 && !LC_RoundParticipantSelection.shortlistAction){
            AP06_Sing_BlockNewParticipant.blockCreation(lstParticipant,setEventIds);
        }
        if(lstBid.size() > 0){
            AP02_sing_countJustificationDoc.addParticipantToRound(lstBid);
        }
    }
    
    public static void afterInsertHandler(List<Bidder__c> lstParticipant){
        List<Id> lstIdBid = new List<Id>();
        List<Bidder__c> lstBid = new List<Bidder__c>();
        Set<Id> setSEIdToShare = new Set<Id>();
        List<String> lstBidStatus = new List<String>{AP_Constant.PARTICIPANT_STATUS_CONFIRMED, AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS};

        // 14-JAN-2022  ARA  2.0       SP-03219
        for(Bidder__c bid : lstParticipant){
            system.debug('## bid.Bidder_Status__c '+bid.Bidder_Status__c);
            if(lstBidStatus.contains(bid.Bidder_Status__c)){
                setSEIdToShare.add(bid.Sourcing_Event__c);
                lstIdBid.add(bid.Id);
                lstBid.add(bid);
            }
            if(bid.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_SELECTED){
                lstBid.add(bid);
            }
        }
        system.debug('## lstIdBid '+lstIdBid);

        // 27-JAN-2022  ARA SP-03219
        if(lstBid.size() > 0){
            AP02_sing_countJustificationDoc.shareDocumentsWithParticipant(lstBid);
        }
        
        if(lstIdBid.size() > 0){
            AP05_Sing_mangageEventTeam.shareWithPortalUsers(setSEIdToShare);
            LC_Sing_ManagePortalAccess.openAccessToBidder(lstIdBid);
        }
    }
    
    public static void BeforeUpdateHandler(map<Id,Bidder__c> mapNewBidder, map<Id,Bidder__c> mapOldBidder){
     /* set<id>setEventIds=new set<id>();
      list<bidder__c>lstParticipant=new list<bidder__c>();
      for(Bidder__c newBidder: mapNewBidder.values()){
            Bidder__c OldBidder = mapOldBidder.get(newBidder.Id);
          if((OldBidder.Negotiation_Round__c != newBidder.Negotiation_Round__c)){
              setEventIds.add(newBidder.Sourcing_Event__c);
              lstParticipant.add(newBidder);
          }
      }
      if(setEventIds.size()>0){
            AP06_Sing_BlockNewParticipant.blockCreation(lstParticipant,setEventIds);
        }*/
    }
    
    //after update trigger handler
    public static void afterUpdateHandler( map<Id,Bidder__c> mapNewBidder,map<Id,Bidder__c> mapOldBidder){
        Set<Id> setContactId = new Set<Id>();
        Set<Id> setSEIdToShare = new Set<Id>();
        List<Bidder__c> lstEliminatedBid = new List<Bidder__c>();
        List<Id> lstBidToActivate = new List<Id>();
        
        for(Bidder__c newBidder: mapNewBidder.values()){
            Bidder__c OldBidder = mapOldBidder.get(newBidder.Id);
            if((OldBidder.Bidder_Status__c != newBidder.Bidder_Status__c && (newBidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_LOST || newBidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_DECLINED)) ){
                setContactId.add(newBidder.Contact_Bidder__c);
                if(newBidder.Contact_Bidder__c != null){
                    lstEliminatedBid.add(newBidder);
                }
            }
            if(OldBidder.Bidder_Status__c != newBidder.Bidder_Status__c){
                if(newBidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_NDASIGNED || newBidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_CONFIRMED){
                    lstBidToActivate.add(newBidder.Id);
                }
                if(newBidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS){
                    setSEIdToShare.add(newBidder.Sourcing_Event__c);
                    lstBidToActivate.add(newBidder.Id);
                }
            }
        }

        if(setContactId.size()>0){
            LC_Sing_ManagePortalAccess.closeAccess(setContactId);
        }
        
        if(lstBidToActivate.size()>0){
            LC_Sing_ManagePortalAccess.openAccessToBidder(lstBidToActivate);
        }
        
        if(setSEIdToShare.size()>0){
            AP05_Sing_mangageEventTeam.shareWithPortalUsers(setSEIdToShare);
        }
        
        if(lstEliminatedBid.size()>0){
            AP05_Sing_mangageEventTeam.deleteSharingEvent(lstEliminatedBid);
        }
    }

    public static void BeforeDeleteHandler(map<Id,Bidder__c> mapOldParticipant){
        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];
        Map<Id, Id> mapIdSE = new Map<Id, Id>();
        if (currentUser.profile.name == 'cTin - Contract Buyer'){
            for(Bidder__c participant : mapOldParticipant.values()){
                mapIdSE.put(participant.Sourcing_Event__c, participant.Id);
            }
            if(mapIdSE.size() > 0){
                for(Sourcing_Event__c event: [SELECT Id, Sourcing_Status__c FROM Sourcing_Event__c WHERE Id IN :mapIdSE.keySet()]){
                    if(event.Sourcing_Status__c != AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS){
                        mapOldParticipant.get(mapIdSE.get(event.Id)).addError('You do not have right to delete this participant at this status.');
                        break;
                    }
                }
            }
        }
    }
}