public class LC02_Sing_FinalSelection {
/*
----------------------------------------------------------------------
-- - Name          : LC02_Sing_FinalSelection
-- - Author        : MRA
-- - Description   : Controller for lighning component LC02_Sing_FinalSelection
--                  
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 05-OCT-2021   MRA    1.0      Initial version                                 
--------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static list<Negotiation_Round__c> retrieveLastRound(id eventId){
        list<Negotiation_Round__c> lastRound=[select id,name,Sourcing_Event__c
                                               from Negotiation_Round__c 
                                               where Sourcing_Event__c =:eventId                                              
                                               order by name desc limit 1];
        return lastRound;
    }
    
    @AuraEnabled
    public static map<string,object> sourcingEventId(id eventId){
         list<Bidder__c> lstParticipants=new list<Bidder__c>();
         map<string,object>result=new map<string,object>();
        //get last round from sourcing event
         list<Negotiation_Round__c> lastRound=retrieveLastRound(eventId);
        /*[select name,Sourcing_Event__c
                                               from Negotiation_Round__c 
                                               where Sourcing_Event__c =:eventId
                                               order by name desc limit 1];*/
        
        if(lastRound.size()>0){
        //get all short-listed partcipants from the round
         lstParticipants=[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,Contact_Bidder__r.firstname,
                             Contact_Bidder__r.lastname,Sing_AwardDetails__c 
                             from Bidder__c 
                             where (Bidder_Status__c=:'Short-listed' OR Bidder_Status__c=:'Participation in Progress')
                             and Negotiation_Round__c=:lastRound[0].Id];
        
         if(lstParticipants.size()>0){
            result.put('lst',lstParticipants);
         }
         else{
            result.put('lst','No participants availalble for selection');
         }
        }
        else{
            result.put('lst','No active rounds available');
        }
         return result;
     }
    
     @AuraEnabled
     public static map<string,object> updteParticipantlst(id eventId,list<id>participantList,list<Bidder__c>updatedlist){
         map<string,object>result=new map<string,object>();
         list<Negotiation_Round__c> lastRound=retrieveLastRound(eventId);
         system.debug('## lastRound'+lastRound);
         list<Bidder__c> updtparticipantlst=new list<Bidder__c>();
         list<Bidder__c> newparticipantlst=new list<Bidder__c>();
         system.debug('##participantList'+participantList.size());
         map<id,string> mapParticipantDetails=new map<id,string>();
        // system.debug('##updatedlist'+updatedlist[0].Allocation_Key__c);
         string srcEventId=eventId;
         system.debug('##srcEventId'+srcEventId);
         decimal totalAllocation=0.0;
         set<string>uniqueBidderKey=new set<string>();
         
         if(updatedlist.size()>0){
             for(Bidder__c bid: updatedlist){
                 mapParticipantDetails.put(bid.id,bid.Sing_AwardDetails__c);
                /* decimal allocationkey=0.0;
                 if(bid.Allocation_Key__c==null)
                 allocationkey=0.0;
                 else*/
                /* if(participantList.contains(bid.Id)){
                     if(bid.Allocation_Key__c==null || bid.Allocation_Key__c<1){
                     result.put('validAllocation','false');
                     result.put('error','Please enter an allocation key for each participant.');
                     }
                     else{
                         decimal allocationkey=0.0;
                         if(bid.Allocation_Key__c==null)
                            allocationkey=0.0;
                         else
                            allocationkey=bid.Allocation_Key__c; 
                            totalAllocation=totalAllocation+allocationkey;
                     }
                 }  */
             }
            /* if(totalAllocation>100){
                 result.put('validAllocation','false');
                 result.put('error','Total percentage cannot exceed 100%.Please review allocation key specified for each participant.');
             } 
             else if(totalAllocation==0){
                 result.put('validAllocation','false');
                 result.put('error','Please enter an allocation key for each participant.');
             }  
            else{
                 result.put('validAllocation','true');
             }*/
             
         }
         
          for(Bidder__c bidder:[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,
                                Contact_Bidder__c,Sing_Account__c,Sourcing_Event__c,
                                Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c
                                from Bidder__c 
                                where sourcing_event__c=:eventId
                                and id IN:participantList]){
           uniqueBidderKey.add( bidder.Contact_Bidder__c+ '' +bidder.Sing_Account__c);                         
        }
       //system.debug('##mapParticipantAllocation'+mapParticipantAllocation);
         //if(result.get('validAllocation')=='true' ){
         if(participantList.size()>0){
           
             for(Bidder__c bidder:[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,
                                   Contact_Bidder__c,Sing_Account__c,Sourcing_Event__c,
                             Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c
                             from Bidder__c 
                             where  (Bidder_Status__c=:'Short-listed' OR Bidder_Status__c=:'Participation in Progress')
                             and Negotiation_Round__c=:lastRound[0].Id]){
                              
                      if(participantList.contains(bidder.Id)){
                          //mra 23/11/2021
                          bidder.Bidder_Status__c='Short-listed';
                          // create new participant with status Awardee + link to sourcing event
                          system.debug('## creating new participant');
                          /*Bidder__c newParticipant=new Bidder__c();
                          newParticipant.Sourcing_Event__c=srcEventId;
                          newParticipant.Bidder_Status__c='Short-listed';
                          newParticipant.Contact_Bidder__c=bidder.Contact_Bidder__c;
                          newParticipant.Sing_Account__c=bidder.Sing_Account__c;
                          if(mapParticipantDetails.containsKey(bidder.Id)  ){
                              newParticipant.Sing_AwardDetails__c =mapParticipantDetails.get(bidder.Id);
                            
                          }
                          //newParticipant.Negotiation_Round__c='';   
                          newparticipantlst.add(newParticipant);*/
                          updtparticipantlst.add(bidder);
                      }
                      else{
                          system.debug('## updating  participant');
                          //update existig participant record to eliminated
                          if(uniqueBidderKey.contains(bidder.Contact_Bidder__c+ '' +bidder.Sing_Account__c)){
                              bidder.Bidder_Status__c='Short-listed';
                          }
                          else{
                            bidder.Bidder_Status__c='Lost';
                          }
                          updtparticipantlst.add(bidder);
                      }
                      
                  }
             
             if(!result.containsKey('error')){
                 try{
                     if(updtparticipantlst.size()>0){
                          try{update updtparticipantlst;} catch(exception e){system.debug('## updtparticipantlst'+ e.getMessage());}
                     }
                    
                 
                    /* if(newparticipantlst.size()>0){
                       try{insert newparticipantlst;} catch(exception e){system.debug('## newparticipantlst'+ e.getMessage());}  
                     }*/
                      result.put('proceeed','true');
                     result.put('success','Your changes have been saved');
                 }
                 catch(exception e){system.debug('## failed '+ e.getMessage());}
             }
             else{
                 result.put('error','Please enter an allocation key for each selected participant');
                 result.put('proceeed','false');
             }
         
         }
        // }
         // else{
          //      result.put('proceeed','false');
          //     result.put('error','Please select a participant');
         // }
         //}
        /* else{
            // result.put('proceeed','false');
             result.put('error','Please specify an allocation key for each selected participant.The total allocation key should not exceed 100%.');
         }*/
         
          
         return result;
     }
}