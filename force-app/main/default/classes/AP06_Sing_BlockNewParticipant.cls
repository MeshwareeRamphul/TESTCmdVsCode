public class AP06_Sing_BlockNewParticipant {
/*----------------------------------------------------------------------
-- - Name          : ParticpantTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Bidder__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 24-FeB-2022  MRA  1.0       Block creation of duplicate participant 
-- 20-JUL-2022  ARA  1.1       Set participant status to Lost
---------------------------------------------------------------------*/

    public static void blockCreation(list<bidder__c>lstParticipant,set<id>setEventIds){
        map<string,string> mapKeyEvent=new map<string,string>();
        //query all participants not eliminated per sourcing event
        for(bidder__c bid: [select Sourcing_Event__c,Bidder_Status__c,Contact_Bidder__c,Negotiation_Round__c 
                            from bidder__c 
                            where Sourcing_Event__c IN:setEventIds
                            and (Bidder_Status__c!=:AP_Constant.PARTICIPANT_STATUS_LOST
                            and Bidder_Status__c!=:AP_Constant.PARTICIPANT_STATUS_DECLINED)]){
            //build map mapKeyEvent contact Id  +eventId=>eventid
            mapKeyEvent.put(bid.Contact_Bidder__c+''+bid.Sourcing_Event__c,bid.Sourcing_Event__c);
        }
        
        //loop in lstParticipant, check if combination matches for the same eventid from map 'mapKeyEvent' => if yes, block / else allow creation
        for(bidder__c newBidder:lstParticipant){
            string comparisonKey=newBidder.Contact_Bidder__c+''+newBidder.Sourcing_Event__c;
            if(mapKeyEvent.size()>0 && mapKeyEvent.containsKey(comparisonKey)){
                if(mapKeyEvent.get(comparisonKey)==newBidder.Sourcing_Event__c){
                    newBidder.addError(system.label.AP06_Sing_DuplicateVendor);
                }  
            }    
        }
    }

    // 20/07/2022   ARA     Update participant status to lost
    public static void eliminateParticipants(set<Id> setEventIds){
        List<Bidder__c> lstParticipant= [SELECT id,Negotiation_Round__c,Bidder_Status__c,Sourcing_Event__c
                                        FROM Bidder__c 
                                        WHERE Sourcing_Event__c IN:setEventIds];

        if(lstParticipant.size() > 0){
            for(Bidder__c bid : lstParticipant){
                bid.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_LOST;
            }
            try{
                update lstParticipant;
            }catch(Exception e){}
        }
    }
}