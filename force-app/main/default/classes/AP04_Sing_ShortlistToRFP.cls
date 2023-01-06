public class AP04_Sing_ShortlistToRFP {
/*----------------------------------------------------------------------
-- - Name          : AP04_Sing_ShortlistToRFP
-- - Author        : Spoon
-- - Description   : sourcing event trigger handler - after insert
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 8-OCT-2021  MRA  1.0      Initial version 
-------------------------------------------------------------------------*/
    
    /*method queries all shortlisted participants from the RFI event and copies them on the new RFP*/
    public static void addShortlisted(map<string,string> mapRelatedRFIRFP){
        
        map<id, list<bidder__c>> mapRFIbidderlst=new map<id, list<bidder__c>>();
        set<string> uniqueBidder=new set<string>();
        list<bidder__c>lstRFPBidders=new list<bidder__c>();
        //Query shortlisted participants from RFI
        for(bidder__c bidder:[ select id,Sourcing_Event__c,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c
                              from bidder__c 
                              where Sourcing_Event__c IN:mapRelatedRFIRFP.keyset() 
                             and bidder_status__c='Short-listed'
                             ]){
            if(!uniqueBidder.contains(bidder.Sourcing_Event__c+'-'+bidder.Contact_Bidder__c)) {                 
                if(mapRFIbidderlst.containsKey(bidder.Sourcing_Event__c)) {
                    List<bidder__c> lstShortlisted = mapRFIbidderlst.get(bidder.Sourcing_Event__c);
                    lstShortlisted.add(bidder);
                    mapRFIbidderlst.put(bidder.Sourcing_Event__c, lstShortlisted);
                } else {
                    mapRFIbidderlst.put(bidder.Sourcing_Event__c, new List<bidder__c> {bidder});
                }
            }
                                 
            uniqueBidder.add(bidder.Sourcing_Event__c+'-'+bidder.Contact_Bidder__c);   
                                  
        }
        
        //loop in map
        for (id relatedRFI:mapRFIbidderlst.keyset()){
            if(mapRelatedRFIRFP.containsKey(relatedRFI)){
                id newRFP=mapRelatedRFIRFP.get(relatedRFI);
                for(bidder__c bidder:mapRFIbidderlst.get(relatedRFI)){
                    bidder__c newRFPBidder=bidder.clone();
                    newRFPBidder.bidder_status__c='Confirmed';
                    newRFPBidder.Sourcing_Event__c=newRFP;
                    //Contact_Bidder__c
                    lstRFPBidders.add(newRFPBidder);
                }
            }
        }
        
        if(lstRFPBidders.size()>0)
            insert lstRFPBidders;
    }
}