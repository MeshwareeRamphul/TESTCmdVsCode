public class LC02_Sing_SelectAwardees {
 	@AuraEnabled
    public static map<string,object> updToPendingSelection(String RoundId){
           map<String,Object> mapOfResult = new map<String,Object>();
           list<Sourcing_Event__c>lstsrcEvent=new list<Sourcing_Event__c>();
           list<Negotiation_Round__c> sourcingEvent=[select Sourcing_Event__r.Sourcing_Status__c,Sourcing_Event__c
                                                     from Negotiation_Round__c where id=:RoundId];
           Sourcing_Event__c srcEvent = new Sourcing_Event__c(id=sourcingEvent[0].Sourcing_Event__c,
                                                              Sourcing_Status__c='Pending_Selection'
                                                             ); 
        	lstsrcEvent.add(srcEvent);
        
        try{
            update lstsrcEvent;
            mapOfResult.put('sourcingEventId',sourcingEvent[0].Sourcing_Event__c);
        }catch(Exception e){
            mapOfResult.put('error',e.getMessage());
        }

         return mapOfResult;
    }
}