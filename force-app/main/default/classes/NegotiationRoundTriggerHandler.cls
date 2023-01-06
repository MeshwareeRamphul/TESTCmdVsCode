public class NegotiationRoundTriggerHandler {
/*----------------------------------------------------------------------
-- - Name          : NegotiationRoundTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Negotiation_Round__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 30-SEP-2021  MRA  1.0      Initial version 
							  - update bid due date on sourcing event with bid due date of last round which is In progress
-- 24-Dec-2021  ARA  2.0
-- 07-MAR-2022  ARA  3.0      SP-03276  automatically associate the docs to the current round when event published
-------------------------------------------------------------------------*/
    
    public static void BeforeInsertHandler(List<Negotiation_Round__c> lstNewRound){
        for(Negotiation_Round__c round : lstNewRound){
            round.TECH_ShowNewRound__c = true;
        }
    }
    
    public static void afterInsertHandler(List<Negotiation_Round__c> lstNewRound){
        Map<Id,Id> mapRound0 = new Map<Id,Id>();
        Map<Id, Id> mapEventId = new Map<Id, Id>();
        List<Negotiation_Round__c> lstRound = new List<Negotiation_Round__c>();

        for(Negotiation_Round__c round : lstNewRound){
            mapEventId.put(round.Id, round.Sourcing_Event__c);
            if(round.Name.contains(' - Round 0')){
                mapRound0.put(round.Sourcing_Event__c, round.Id);
            }
        }
        
        for(Negotiation_Round__c round : [SELECT Id, Sourcing_Event__r.name, name, TECH_ShowNewRound__c from Negotiation_Round__c
                                        WHERE Sourcing_Event__c IN :mapEventId.values()
                                        AND Id NOT IN :lstNewRound]){
           round.TECH_ShowNewRound__c = false;
           lstRound.add(round);
        }
        
        if(lstRound.size() > 0){
            update lstRound;
        }
        
        // 07-MAR-2022  ARA  SP-03276 
        if(mapRound0.size() > 0){
            AP02_sing_countJustificationDoc.addDocumentsToRound(mapRound0);
        }
        
        /*// Update ContentVersion
        List<ContentVersion> lstCV = new List<ContentVersion>();
        for(ContentVersion cv : [SELECT Id, contentDocumentId,Sing_DocumentName__c, Negotiation_Round__c, Participant__c FROM ContentVersion WHERE Sourcing_Event__c IN :mapEventId.values()]){
            System.debug('********** cv.Sing_DocumentName__c '+ cv.Sing_DocumentName__c);
            lstCV.add(new ContentVersion(
                Sing_DocumentName__c = cv.Sing_DocumentName__c, 
                Participant__c = cv.Participant__c, 
                Negotiation_Round__c = mapEventId.get(cv.Participant__c),
                Sharing_Logic__c = 'Specific Vendor'));
        }
        System.debug('********** lstCV '+ lstCV);
        if(lstCV.size() > 0){
            insert lstCV;
        }*/
        
      /*   if(round.CountRounds__c>1){
                integer countRounds=round.CountRounds__c-1;
                if(round.name== round.Sourcing_Event__r.name + ' - ' + 'Round ' + string.valueOf(countRounds)){
                    
                }
            }*/
            
       
       /* map<id,id> mapsrcRound=new map<id,id>();
        set<id> firstround=new set<id>();
        set<string>round1=new set<string>();
        set<string>toExclude=new set<string>();
        list<bidder__c> lstupdtBidder=new list<bidder__c>();
        for(Negotiation_Round__c round :[select id,Sourcing_Event__c,name from Negotiation_Round__c where id IN :lstNewRound]){
            if(round.name.Contains('Round 1')){
                mapsrcRound.put(round.Sourcing_Event__c,round.id);
                round1.add(round.id);
            }
            firstround.add(round.Id);
        }
        
        for(bidder__c bidder : [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c,Negotiation_Round__c,Negotiation_Round__r.name 
                                from bidder__c 
                                where sourcing_event__c IN :mapsrcRound.keyset() 
                               and Negotiation_Round__c  IN:round1]){
            toExclude.add(bidder.Contact_Bidder__c+''+bidder.Sing_Account__c);
        }
        
        for(bidder__c bidder : [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c,Negotiation_Round__c,Negotiation_Round__r.name 
                                from bidder__c 
                                where sourcing_event__c IN:mapsrcRound.keyset() 
                                and bidder_status__c=:'Participation in Progress'
                                and Negotiation_Round__c NOT IN:firstround]){
                                    if(toExclude.contains(bidder.Contact_Bidder__c+''+bidder.Sing_Account__c)){
                                        bidder.Bidder_Status__c='Short-Listed';
                                        lstupdtBidder.add(bidder);
                                    }
        }
        
        if(lstupdtBidder.size()>0)
        	update lstupdtBidder;*/
    }
    
    /*public static void BeforeDeleteHandler(map<Id,Negotiation_Round__c> mapOldRound){
        set<id> setEventId=new set<id>();
        set<string> setroundId=new set<string>();
        list<Negotiation_Round__c> lstRound=new list<Negotiation_Round__c>();
        
        for(Negotiation_Round__c round :[select id,Sourcing_Event__r.name,name, Sourcing_Event__r.CountRounds__c from Negotiation_Round__c
                                         where id IN :mapOldRound.keyset()]){
            setEventId.add(round.Sourcing_Event__c);
            setroundId.add(round.Sourcing_Event__r.name + ' - ' + 'Round ' + string.valueOf(round.Sourcing_Event__r.countRounds__c));
        }

        for(Negotiation_Round__c round :[select id,Sourcing_Event__r.name,name,TECH_ShowNewRound__c from Negotiation_Round__c
                                          where Sourcing_Event__c IN :setEventId and id NOT IN:mapOldRound.keyset()
                                          order by name desc limit 1]){
           round.TECH_ShowNewRound__c=true;
           lstRound.add(round);
         }
        
        if(lstRound.size()>0)
            update lstRound;
    }*/
    
    /*public static void BeforeUpdateHandler(map<Id,Negotiation_Round__c> mapOldRound, map<Id,Negotiation_Round__c> mapNewRound){
     
    }*/
    
    //after update trigger handler
    public static void afterUpdateHandler( map<Id,Negotiation_Round__c> mapNewRound,map<Id,Negotiation_Round__c> mapOldRound){
        Map<Id, Negotiation_Round__c> mapNegotiationRound= new Map<Id, Negotiation_Round__c>();
        List<Negotiation_Round__c> lstRound = new List<Negotiation_Round__c>();
        for(Negotiation_Round__c newRound: mapNewRound.values()){
            Negotiation_Round__c oldRound = mapOldRound.get(newRound.Id);
            if((oldRound.Sing_Round_Bid_Due_Date__c != newRound.Sing_Round_Bid_Due_Date__c 
               && newRound.Round_Status__c == 'In Progress') 
              || (oldRound.Round_Status__c != newRound.Round_Status__c && newRound.Round_Status__c == 'In Progress') ){
                mapNegotiationRound.put(newRound.Id, newRound);
            }

            //GRA -- send email to participants when Round bid due date is updated and notifyParticipant is checked
            if(oldRound.Sing_Round_Bid_Due_Date__c != newRound.Sing_Round_Bid_Due_Date__c 
               && newRound.Sing_Round_Bid_Due_Date__c != null 
               && newRound.Round_Status__c == 'In Progress' && newRound.Sing_NotifyParticipants__c){
                lstRound.add(newRound);
            }
        }
        if(mapNegotiationRound.size()>0){
            AP01_Sing_UpdateBidDueDateOnSourcing.updateBidDueDate(mapNegotiationRound);
        }

        if(lstRound.size() > 0 ){
            AP61_SendEmail_Round.sendTo_ShortlistedOrInProgress_Participant(lstRound);
        }
    }
}