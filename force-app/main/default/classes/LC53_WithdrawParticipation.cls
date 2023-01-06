public without sharing class LC53_WithdrawParticipation{
    
    @AuraEnabled
    public static Map<String, Object> showWithdrawBtn(String participantId){
        Map<String, Object> mapResult = new Map<String, Object>();
        List<Bidder__c> lstBidder = [SELECT bidder_status__c FROM Bidder__c WHERE id = :participantId];
        if(lstBidder[0].bidder_status__c == 'Lost' || lstBidder[0].bidder_status__c == 'Declined')
            mapResult.put('hide','hide');
        else
            mapResult.put('show','show');
        
        return mapResult;
    }

    @AuraEnabled
    public static Map<String, Object> withdraw(String participantId){ 
        Map<String, Object> mapResult = new Map<String, Object>();
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        map<string,EmailTemplate> mapLanguageTemplate= new map<string,EmailTemplate>();
        EmailTemplate emToParticipant; 
        List<Bidder__c> lstBidder=new list<Bidder__c>();
        map<string,string> mapcontactLang=new map<string,string>();
        set<id>setConId=new set<id>();
        
        for(Emailtemplate temp : [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName ='Participant_withdraw_Eng' or DeveloperName ='Participant_withdraw_FR' or DeveloperName ='Participant_withdraw_GE')]){
           if(temp.DeveloperName=='Participant_withdraw_Eng' ) 
                  mapLanguageTemplate.put('En',temp);
           if(temp.DeveloperName=='Participant_withdraw_FR' )  
                   mapLanguageTemplate.put('FR',temp); 
           if(temp.DeveloperName=='Participant_withdraw_GE' )  
                   mapLanguageTemplate.put('GE',temp); 
       
        }
        
        for(Bidder__c bid:[SELECT Id,TECH_EventOwner__c,Contact_Bidder__c, Contact_Bidder__r.Email, Sourcing_Event__r.Owner.Email FROM Bidder__c WHERE Id = :participantId]){
             lstBidder.add(bid);
             setConid.add(bid.Contact_Bidder__c);
        }
        
        for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN:setConid]){
            mapcontactLang.put(usr.ContactId,usr.LanguageLocaleKey);        
        }
        
        Bidder__c currBidder = new Bidder__c();

        currBidder.id = participantId;
        currBidder.bidder_status__c = 'Declined';

        //HSO - 28/01/2022 - add system to send email to participant on participation withdrawal
        if(lstBidder.size() > 0){
            for(Bidder__c bidder : lstBidder){
                Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                
                if(mapcontactLang.get(bidder.Contact_Bidder__c)=='fr'){
                    emToParticipant=mapLanguageTemplate.get('FR');
                }
                else if(mapcontactLang.get(bidder.Contact_Bidder__c)=='de'){
                     emToParticipant=mapLanguageTemplate.get('GE');
                }
                else{
                    emToParticipant=mapLanguageTemplate.get('En');
                }
                      
                email.setTemplateID(emToParticipant.Id);
                email.setTargetObjectId(lstBidder[0].Contact_Bidder__c);
                email.setWhatId(bidder.Id);
                email.setToAddresses(new List<String>{bidder.Contact_Bidder__r.Email});
                email.setCcAddresses(new List<String>{bidder.Sourcing_Event__r.Owner.Email});
        
                lstEmails.add(email);
            }
        }
        
        try{
            System.debug('### try');
            update currBidder;

            if(lstEmails.size() > 0){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);

                //AMA
                AP74_ManageNotificationHistory.CreateNotificationHistory(lstBidder,results,'Notification to participant after he chose to withdraw his participation');
            }
        }
        catch(Exception e){
            System.debug('### catch' + e.getMessage());
            mapResult.put('Error', e.getMessage());
        }
       
        System.debug('##mapResult' + mapResult);
        return mapResult;
    }
}