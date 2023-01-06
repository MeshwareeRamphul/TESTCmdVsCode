public class BidderTriggerHandler {
    
  public static void afterUpdateHandler(map<Id,bidder__c> mapOldBidder, map<Id,bidder__c> mapNewBidder){
    /*   set<id> setRoundId=new set<id>();
       set<id> seteventId=new set<id>();
       set<id> setBidderId=new set<id>();
       set<string>toExclude=new set<string>();
       list<bidder__c>lstupdtBidder=new list<bidder__c>();
       
      for(bidder__c newBidder:mapNewBidder.values()){
            bidder__c oldBidder = mapOldBidder.get(newBidder.Id);
            if(oldBidder.bidder_Status__c!=newBidder.bidder_Status__c && newBidder.bidder_Status__c=='Short-Listed' && newBidder.Negotiation_Round__c!=null
             ){
               seteventId.add(newBidder.sourcing_event__c);
               setRoundId.add(newBidder.Negotiation_Round__c);
               setBidderId.add(newBidder.Id);
               toExclude.add(newBidder.Contact_Bidder__c+''+newBidder.Sing_Account__c);
            } 
       }
      
      system.debug('## seteventId'+seteventId);
      system.debug('## setRoundId'+setRoundId);
      system.debug('## setBidderId'+setBidderId);
      system.debug('## toExclude'+toExclude);
      
      if(seteventId.size()>0){
         list<Negotiation_Round__c> lstRound=[select id,name from Negotiation_Round__c where sourcing_event__c in: seteventId order by name desc limit 1];
          
          for(bidder__c bidder : [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c,Negotiation_Round__c,Negotiation_Round__r.name 
                                    from bidder__c 
                                    where sourcing_event__c IN:seteventId
                                    and bidder_status__c=:'Participation in Progress'
                                    and Negotiation_Round__c NOT IN:lstRound
                                    and id NOT IN: setBidderId]){
               if(toExclude.contains(bidder.Contact_Bidder__c+''+bidder.Sing_Account__c)){
                                     bidder.Bidder_Status__c='Short-Listed';
                                     lstupdtBidder.add(bidder);
              }
        }
          if(lstupdtBidder.size()>0)
            update lstupdtBidder;
    */
        List<Bidder__c> lstBidDecline = new List<Bidder__c>();

        //AMA 07/11/2022 SP-03791
        Map<ID, List<Bidder__c>> mapIdSELstBid = new Map<ID, List<Bidder__c>>();
        Map<ID, User> mapIdConBidUser = new Map<ID, User>();
        for (Bidder__c bid : mapNewBidder.values()) {
          if(/*mapOldBidder.get(bid.id).Bidder_Status__c != bid.Bidder_Status__c ||*/ bid.Bidder_Status__c == 'Participation in Progress'){
              if (mapIdSELstBid.containsKey(bid.sourcing_event__c) == false) {
                mapIdSELstBid.put(bid.sourcing_event__c, new List<Bidder__c>{bid});
              } else {
                mapIdSELstBid.get(bid.sourcing_event__c).add(bid);
              }
  
              if (bid.Contact_Bidder__c != null) {
                mapIdConBidUser.put(bid.Contact_Bidder__c, null);
              }
          }

          //AMA
          /*if (bid.Bidder_Status__c == 'Declined') {
            lstBidDecline.add(bid);
          }*/
        }

        //AMA
        //AP75_ManageNotificationSE_ctin.sendNotifDecline(lstBidDecline); 

        if (mapIdConBidUser.keySet().size()>0) {
          List<User> lstUsr = [select id,IsActive,TimeZoneSidKey,ContactId from User where ContactId IN:mapIdConBidUser.keySet() and IsActive=true];
          mapIdConBidUser.clear();
          if(lstUsr.size()>0) {
            for (User usr : lstUsr) {
              mapIdConBidUser.put(usr.ContactId, usr);
            }
          }
        }
        
        List<Sourcing_Event__c> lstSE = [select id,Preferred_Time_Zone2__c,Sourcing_Status__c from Sourcing_Event__c where id IN:mapIdSELstBid.keySet()];
        if (lstSE.size()>0) {
          List<User> lstUserUpd = new List<User>();
          for(Sourcing_Event__c SE : lstSE) {
            if (mapIdSELstBid.containsKey(SE.id) ==true && mapIdSELstBid.get(SE.id).size()>0 && SE.Sourcing_Status__c == 'Published') {
              for (bidder__c bid : mapIdSELstBid.get(SE.id)) {
                  if (mapIdConBidUser.containsKey(bid.Contact_Bidder__c)) {
                      mapIdConBidUser.get(bid.Contact_Bidder__c).TimeZoneSidKey = SE.Preferred_Time_Zone2__c.split(' ')[1];
                      lstUserUpd.add(mapIdConBidUser.get(bid.Contact_Bidder__c));
                  }
              }
            }
          }
          if (lstUserUpd.size()>0) {
            update lstUserUpd;
          }
        }
  } 
}