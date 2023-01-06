public with sharing class AP61_SendEmail_Round {
    public static void sendTo_ShortlistedOrInProgress_Participant(List<Negotiation_Round__c> lstRound){
        //String emTempName = System.Label.L61_EmailTemplate_RoundBidDate;
        EmailTemplate emToParticipant;
        map<string,EmailTemplate> mapLanguageTemplate= new map<string,EmailTemplate>();
        for(emailTemplate temp : [SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName = 'Round_BidDueDate_Updated_Eng' or DeveloperName = 'Round_BidDueDate_Updated_FR' or DeveloperName = 'Round_BidDueDate_Updated_GE')]){
            if(temp.DeveloperName=='Round_BidDueDate_Updated_Eng' ) 
                  mapLanguageTemplate.put('En',temp);
            if(temp.DeveloperName=='Round_BidDueDate_Updated_FR' )  
                   mapLanguageTemplate.put('FR',temp);
            if(temp.DeveloperName=='Round_BidDueDate_Updated_GE' )  
                   mapLanguageTemplate.put('GE',temp);        
        }
        set<id> setConid=new set<id>();
        List<Bidder__c> lstParticipant= new list<Bidder__c>();
        map<string,user> mapcontactLang=new map<string,user>();
        for(Bidder__c bid :[SELECT id, Contact_Bidder__r.Email, Sourcing_Event__r.Preferred_Time_Zone2__c, Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,
                                                Bidder_Status__c , Negotiation_Round__c, Sourcing_Event__r.Bid_Due_Date__c,TECH_EventOwner__c,Contact_Bidder__c,Contact_Bidder__r.cTin_RelatedUser__r.username
                                        FROM Bidder__c
                                        WHERE Negotiation_Round__c IN: lstRound 
                                        AND ( Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_SHORTLISTED OR Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS )]){
        
            lstParticipant.add(bid);
            setConid.add(bid.Contact_Bidder__c);
        }
        
        for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:setConid]){
            mapcontactLang.put(usr.ContactId,usr);        
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        
        
        List<String> lstCcDestinataire = new List<String>();

        Set<id> setRecipient = new Set<id>();

        for(Bidder__c part : lstParticipant){
            if(setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )){
                List<String> lstDestinataire = new List<String>();
                lstDestinataire.add(part.Contact_Bidder__r.Email);
                lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);// aconfirmé
                datetime dateDue=part.Sourcing_Event__r.Bid_Due_Date__c;
                //string dateDue=part.Sourcing_Event__r.Bid_Due_Date__c.day() + '/' + part.Sourcing_Event__r.Bid_Due_Date__c.month() + '/' + part.Sourcing_Event__r.Bid_Due_Date__c.year();
                //String urlRound = System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ part.Negotiation_Round__c;
                //System.debug('url@@   ' + urlRound);
                
                if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                    emToParticipant=mapLanguageTemplate.get('FR');
                }
                else if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='de'){
                    emToParticipant=mapLanguageTemplate.get('GE');
                }
                else{
                    emToParticipant=mapLanguageTemplate.get('En');
                }
                       
                String body = string.valueOf(emToParticipant.HtmlValue);
                body = body.replace('{CONTACT_NAME}', part.Contact_Bidder__r.Name);
                body = body.replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
                body = body.replace('BIDDUEDATE', String.valueOf(dateDue));
                body = body.replace('{SOURCING_EVENT_OWNER}', String.valueOf(part.TECH_EventOwner__c));
                body=body.replace ('GMT+1', string.valueOf(part.Sourcing_Event__r.Preferred_Time_Zone2__c.split(' ')[0]));
                //AMA 16/12/2022
                body = body.replace('{username}', mapcontactLang.get(part.Contact_Bidder__c).username);
                System.debug('body@@ ' + body);
                String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToaddresses(lstDestinataire);
                email.setCcaddresses(lstCcDestinataire);
                email.setTemplateId(emToParticipant.Id);
                email.setSubject(subject);
                email.setHtmlBody(body);

                messages.add(email);

                setRecipient.add(part.Contact_Bidder__c);
            }
            
            
        }
        
        if(!test.isRunningTest()){
            if(messages.size() > 0){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

                //AMA
                AP74_ManageNotificationHistory.CreateNotificationHistory(lstParticipant,results,'Notification to participants when Round Bid Due date is updated');

                if (results[0].success) 
                {
                System.debug('The email was sent successfully.');
                } else {
                System.debug('The email failed to send: ' +  results[0].errors[0].message);
                }
            }
            
        }
    }
}