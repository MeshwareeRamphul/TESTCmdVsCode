public without sharing class LC_TimeCounter {
  /*----------------------------------------------------------------------
  -- - Name          : LC_TimeCounter
  -- - Author        : Spoon
  -- - Description   : Controller for Aura component LC_TimeCounter
  -- - History:
  
  -- Date         Name  Version  Remarks
  -- -----------  ----  -------  ---------------------------------------
  -- 05-APR-2021  MRA  1.0      Initial version 
  -- 14-JAN-2022  ARA  2.0      Optimization
  -------------------------------------------------------------------------*/

  @AuraEnabled
  public static datetime defaultRemainingTime(string recId){
    datetime dte;
    String sObjectRound = 'Negotiation_Round__c';
    String sObjectParticipant = 'Bidder__c';
    Schema.SObjectType sObjTypeRound = Schema.getGlobalDescribe().get(sObjectRound);
    Schema.SObjectType sObjTypeParticipant = Schema.getGlobalDescribe().get(sObjectParticipant);
    
    if(recId.startsWith(sObjTypeRound.getDescribe().getKeyPrefix())){
      list<Negotiation_Round__c> rounlst=[select id, Sourcing_Event__r.Bid_Due_Date__c,
                                          Sing_Round_Bid_Due_Date__c,Round_Start_Date__c
                                          from Negotiation_Round__c
                                          where id =:recId];
      dte=rounlst[0].Sing_Round_Bid_Due_Date__c;
    }
    else if(recId.startsWith(sObjTypeParticipant.getDescribe().getKeyPrefix())){
      list<bidder__c> eventlst=[select id, Sourcing_Event__r.Bid_Due_Date__c,Sourcing_Event__c                                              
                                from bidder__c
                                where id =:recId];
      list<Negotiation_Round__c> lastRound=[select id,name,Sourcing_Event__c
                                            from Negotiation_Round__c 
                                            where Sourcing_Event__c =:eventlst[0].Sourcing_Event__c 
                                            and (Round_Status__c=:'In Progress' or Round_Status__c=:'Preparation') 
                                            order by name desc limit 1];
      if(lastRound.size()>0){
        list<bidder__c> bidderlst=[select id, Sourcing_Event__r.Bid_Due_Date__c,Sourcing_Event__c,Negotiation_Round__c,
                                  Negotiation_Round__r.Sing_Round_Bid_Due_Date__c
                                  from bidder__c
                                  where Sourcing_Event__c =:eventlst[0].Sourcing_Event__c
                                  and Negotiation_Round__c=:lastRound[0].id
                                  and id=:recId];
                                    
        dte=bidderlst[0].Negotiation_Round__r.Sing_Round_Bid_Due_Date__c;
      }
        
      //else{
        //   dte=eventlst[0].Sourcing_Event__r.Bid_Due_Date__c;
      //}
        // dte=bidderlst[0].Negotiation_Round__r.Sing_Round_Bid_Due_Date__c;
    }
    else{
      list<Sourcing_event__c> event=[select id, Bid_Due_Date__c 
                                    from Sourcing_Event__c 
                                    where id = : recId];       
      dte=event[0].Bid_Due_Date__c;
    }
      
      /*String defaultTimeLeft='';
      Long dt1Long = event[0].Bid_Due_Date__c.getTime();
      Long dt2Long = DateTime.now().getTime();
      Long milliseconds = dt2Long - dt1Long;
      Long seconds = milliseconds / 1000;
      Long minutes = seconds / 60;
      Long hours = minutes / 60;
      Long days = hours / 24;
      
      defaultTimeLeft= hours + ':'+ minutes + ':' + seconds ;*/
    return dte;
  }
}