public class LC_Sing_NewRound {
    @AuraEnabled
    public static String cloneAnySobjet(String recordId){ 
        string returnId; 
        Negotiation_Round__c newRound;
        list<Bidder__c>lstParticipants=new list<Bidder__c>();
        
        list<Negotiation_Round__c> round =[select id,Sourcing_Event__c,Round_Start_Date__c,Round_Topic__c,Sing_Round_Bid_Due_Date__c,
                                           Sing_Completion_comments__c
                                           from Negotiation_Round__c where id=:recordId];

        newRound=round[0].clone();
        newRound.Round_Start_Date__c=system.now();
        newRound.Round_Topic__c='';
        newRound.Sing_Round_Bid_Due_Date__c=null;
        newRound.Sing_Completion_comments__c='';
        try{
          insert newRound;
          
          returnId=newRound.Id;
         /*for (Bidder__c participant:[select id,Bidder_Status__c,Sourcing_Event__c,Contact_Bidder__c,Sing_Account__c,Negotiation_Round__c
                                       from Bidder__c 
                                       where Bidder_Status__c=:'Short-listed' 
                                       and Negotiation_Round__c=:round[0].Id]){
                   Bidder__c newParticipant=participant.clone();             
                   newParticipant.Negotiation_Round__c=newRound.id;
                   lstParticipants.add(newParticipant);
         }
            if(lstParticipants.size()>0){
                insert lstParticipants;
           		returnId=newRound.Id;
            }
           */
        }
        catch(exception e){
            system.debug('##exception' +e.getMessage());
           returnId=''; 
        }
 
        return returnId;
    }
}