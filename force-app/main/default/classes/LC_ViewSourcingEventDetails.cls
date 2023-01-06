public with sharing class LC_ViewSourcingEventDetails {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC_ViewSourcingEventDetails
    -- - Author        : MRA
    -- - Description   : Controller for lighning component LC_ViewSourcingEventDetails
    --                  
    --
    -- Maintenance History:
    --
    -- Date          Name   Version   Remarks
    -- -----------   ----   -------   ---------------------------------------
    -- 28-OCT-2021   MRA    1.0      Initial version                                 
    --------------------------------------------------------------------------- */
        
        @AuraEnabled
        public static map<string,object> FetchSrceventDetails(id bidderId){
            map<string,object>result=new map<string,object>();

            for(Bidder__c bidder: [select id,Sourcing_Event__r.name,
                                    Sourcing_Event__r.Publish_start_date_time__c,
                                    /*Sourcing_Event__r.Description__c,*/
                                    TECH_AccountName__c,sourcing_Event__r.Bid_Due_Date__c
                                    from Bidder__c where id =:bidderId]){

                result.put('eventname',bidder.Sourcing_Event__r.name);
                result.put('publishdate',bidder.Sourcing_Event__r.Publish_start_date_time__c);
               // result.put('description',bidder.Sourcing_Event__r.Description__c);
                result.put('axaentity',bidder.TECH_AccountName__c);
                result.put('bidduedate',bidder.sourcing_Event__r.Bid_Due_Date__c);
             }


            return result;


        }
        
       
 }