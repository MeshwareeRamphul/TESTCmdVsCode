public without sharing class LC_RoundParticipantSelection {
/*
----------------------------------------------------------------------
-- - Name          : LC_RoundParticipantSelection
-- - Author        : MRA
-- - Description   : Controller for lighning component LC_RoundParticipantSelection
--                  
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 02-JUN-2021   MRA    1.0      Initial version
-- 07-OCT-2021   MRA    1.1      Clone participant which are shortlisted instead of updating it.
-- 17-FEB-2022   ARA    1.2      Don't update particpant to eliminated
-- 09-MAR-2022   MRA    1.3      Added logic to send email notif w.r.t user language  
-- 05-AUG-2022   ARA    1.4      SP-03349 (Invert "Participation in Progress" and "Shortlisted" status.)
--------------------------------------------------------------------------- */
    public static boolean shortlistAction=false;
    @AuraEnabled
    public static id sourcingEventId(string roundId){
        list<Negotiation_Round__c> sourcingEvent = [SELECT name, Sourcing_Event__c,TECH_ShowLaunhRound__c FROM Negotiation_Round__c WHERE id = :roundId];
        return sourcingEvent[0].Sourcing_Event__c;
        
    }

    @AuraEnabled
    public static map<string,object> buildParticipantlst(string roundId){
        map<string,object>result=new map<string,object>();
        list<Bidder__c>lstParticipants=new list<Bidder__c>();
        lstParticipants.clear();
        // list<Negotiation_Round__c> sourcingEvent=[SELECT Sourcing_Event__c FROM Negotiation_Round__c WHERE id=:roundId];
        Id srcEventId=sourcingEventId(roundId);
        
        if(srcEventId!=null){
            set<id> alreadyshortlisted=new set<id>();
            for(bidder__c existing: [SELECT Contact_Bidder__c FROM bidder__c WHERE Negotiation_Round__c = :roundId]){
                alreadyshortlisted.add(existing.Contact_Bidder__c);
            }
            
            list<Negotiation_Round__c> previousRound = [SELECT id FROM Negotiation_Round__c 
                                                        WHERE Sourcing_Event__c = :srcEventId 
                                                        AND id <> :roundId 
                                                        ORDER BY name DESC LIMIT 1];
            if(previousRound.size() > 0){
                lstParticipants = [ SELECT id,Contact_Bidder__c,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,Contact_Bidder__r.firstname,Contact_Bidder__r.lastname
                                    FROM Bidder__c 
                                    WHERE Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS
                                    /*WHERE Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_SHORTLISTED*/
                                    AND Contact_Bidder__c NOT IN :alreadyshortlisted
                                    AND Negotiation_Round__c = :previousRound[0].Id ];

                if(lstParticipants.size()>0){
                    result.put('lst',lstParticipants);
                }
            }
        }
        if(!result.containsKey('lst')){
            result.put('lst','No participants found');
        }
        
        return result;
    }

    @AuraEnabled
    public static map<string,object> updteParticipantlst(string roundId, List<id> selectedParticipant, List<Bidder__c> lstParticipant){
        shortlistAction=true; // used in partcipant before insert trigger to bypass block duplicate vendor
        map<string,object>result=new map<string,object>();
        list<Bidder__c> participantuptlst=new list<Bidder__c>();
        Map<Id, Bidder__c> mapNewParticipant = new Map<Id, Bidder__c>();
        list<Bidder__c> shortlistedlst=new list<Bidder__c>();
        set<id> shortlistedcontacts=new set<id>();
        
        map<string,user>mapcontactLang=new map<string,user>();
        set<id>conIdSet=new set<id>();
                
        system.debug('##selectedParticipant'+selectedParticipant.size());
        //set<string> uniqueBidder=new set<string>();
        Id srcEventId=sourcingEventId(roundId);
        if(selectedParticipant.size()>0){
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            List<String> lstCcDestinataire = new List<String>();
            String emTemp;
            Boolean sendMail;

            //AMA
            List<Bidder__c> lstBidNotifHist = new List<Bidder__c>();
            
            for(Bidder__c bidder:[SELECT id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,
                                Contact_Bidder__c,Sing_Account__c,TECH_EventOwner__c,
                                Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c,
                                Contact_Bidder__r.Email,Sourcing_Event__c,Sourcing_Event__r.Owner.Email,
                                Sourcing_Event__r.Name,Contact_Bidder__r.Name ,
                                Sourcing_Event__r.Publish_start_date_time__c,
                                Sourcing_Event__r.Bid_Due_Date__c
                                FROM Bidder__c 
                                WHERE Sourcing_Event__c = :srcEventId
                                AND Negotiation_Round__c != :roundId
                                AND Id IN :lstParticipant
                                AND Bidder_Status__c != :AP_Constant.PARTICIPANT_STATUS_LOST]){
                if(selectedParticipant.contains(bidder.Id)){
                    if(!shortlistedcontacts.contains(bidder.Contact_Bidder__c)){
                        // 05-AUG-2022   ARA    SP-03349
                        Bidder__c newbidder = new Bidder__c(Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS/*'Short-listed'*/,
                                                            Negotiation_Round__c = roundId,
                                                            Sourcing_Event__c = srcEventId,
                                                            Contact_Bidder__c = bidder.Contact_Bidder__c,
                                                            Sing_Account__c = bidder.Sing_Account__c);
                        mapNewParticipant.put(bidder.Contact_Bidder__c, newbidder);
                        shortlistedcontacts.add(bidder.Contact_Bidder__c);
                        // change bidder status to ShortListed for the previous round
                        shortlistedlst.add(new Bidder__c(Id=bidder.Id, Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_SHORTLISTED));
                    }
                }else{
                    bidder.Bidder_Status__c='Lost';
                    participantuptlst.add(bidder);
                }
                conIdSet.add(bidder.Contact_Bidder__c);
            }
            
            for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:conIdSet]){
                mapcontactLang.put(usr.ContactId,usr);        
            }
         
            // 17-FEB-2022   ARA
            if(participantuptlst.size()>0){
                system.debug('## participantuptlst'+ participantuptlst);
                Set<id> setRecipient = new Set<id>();     
                update participantuptlst;
                // emTemp= System.Label.L61_EmailTemplate_ParticipantEliminated;
                EmailTemplate emToParticipant;
                map<string,emailtemplate>mapLanguageTemplate=new map<string,emailtemplate>();
               
                
                for(Emailtemplate temp : [SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName =: 'LC_Participant_Eliminated_Eng' OR DeveloperName =: 'LC_Participant_Eliminated_FR' OR DeveloperName =: 'LC_Participant_Eliminated_GE']){
                    if(temp.DeveloperName=='LC_Participant_Eliminated_Eng') 
                      mapLanguageTemplate.put('En',temp);
                    if(temp.DeveloperName=='LC_Participant_Eliminated_FR')  
                      mapLanguageTemplate.put('FR',temp);  
                    if(temp.DeveloperName=='LC_Participant_Eliminated_GE')  
                      mapLanguageTemplate.put('GE',temp);                 
                }
                
                for(Bidder__c part : [SELECT id,name,Contact_Bidder__r.Email, Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,Bidder_Status__c , Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.Bid_Due_Date__c,Bidder__c.Negotiation_Round__c,TECH_EventOwner__c,Contact_Bidder__r.cTin_RelatedUser__r.username
                                    FROM Bidder__c 
                                    WHERE id in: participantuptlst
                                    AND Contact_Bidder__c NOT IN :shortlistedcontacts]){
                    if( setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )  ){                    
                        List<String> lstDestinataire = new List<String>();
                        lstDestinataire.add(part.Contact_Bidder__r.Email);
                        lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);
                       // String urlRound = System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ part.Negotiation_Round__c;
                     
                        String urlRound=system.label.Sing_siteUrl+part.id+'/'+ string.valueOf(part.name).deleteWhitespace();
                        System.debug('Name@@   ' +part.Sourcing_Event__r.Name + 'Contact@@'+ part.Contact_Bidder__r.Name + 'SourcingE Name@@ '+ part.Sourcing_Event__r.Name);
                                            
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
                        body = body.replace('{ROUND_URL}', urlRound);
                        body = body.replace('{EVENT_OWNER}', part.TECH_EventOwner__c);
                        //AMA 16/12/2022
                        body = body.replace('{username}', mapcontactLang.get(part.Contact_Bidder__c).username);
        
                        String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
                        
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToaddresses(lstDestinataire);
                        email.setCcaddresses(lstCcDestinataire);
                        email.setTemplateId(emToParticipant.Id);
                        email.setSubject(subject);
                        email.setHtmlBody(body);
        
                        messages.add(email);

                        //AMA
                        lstBidNotifHist.add(part);

                        setRecipient.add(part.Contact_Bidder__c);
                    }
                }
            }
            
            if(mapNewParticipant.size()>0){
                system.debug('## newParticipantlst' + mapNewParticipant);
                Set<id> setRecipient = new Set<id>();
                List<Bidder__c> lstNewParticipant = mapNewParticipant.values();
                insert lstNewParticipant;
                //emTemp= System.Label.L61_EmailTemplate_ParticipantShortlisted;
                EmailTemplate emToParticipant;
                map<string,emailtemplate>mapLanguageTemplate=new map<string,emailtemplate>();
                for(EmailTemplate temp :[SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName =: 'Participant_Shortlisted_Eng' OR developername=:'Participant_Shortlisted_FR' OR developername=:'Participant_Shortlisted_GE')]){
                    if(temp.DeveloperName=='Participant_Shortlisted_Eng') 
                      mapLanguageTemplate.put('En',temp);
                    if(temp.DeveloperName=='Participant_Shortlisted_FR')  
                      mapLanguageTemplate.put('FR',temp);  
                    if(temp.DeveloperName=='Participant_Shortlisted_GE')  
                      mapLanguageTemplate.put('GE',temp);  
                }
                for(Bidder__c part : [SELECT id,name, Contact_Bidder__r.Email, Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,Bidder_Status__c , Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.Bid_Due_Date__c,Bidder__c.Negotiation_Round__c,Sourcing_Event__r.BusinessOwner__r.email,Contact_Bidder__r.cTin_RelatedUser__r.username
                                            FROM Bidder__c 
                                            WHERE id IN: lstNewParticipant]){
                    if( setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )  ){                    
                        List<String> lstDestinataire = new List<String>();
                        lstDestinataire.add(part.Contact_Bidder__r.Email);
                        lstCcDestinataire.add(part.Sourcing_Event__r.BusinessOwner__r.Email);
                        //AMA 29/09/2022 add business owner into cc
                        lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);
                        //String urlRound = System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ part.Negotiation_Round__c;
                        String urlRound=system.label.Sing_siteUrl+part.id+'/'+ string.valueOf(part.name).deleteWhitespace();
                        System.debug('Name@@   ' +part.Sourcing_Event__r.Name + 'Contact@@'+ part.Contact_Bidder__r.Name + 'SourcingE Name@@ '+ part.Sourcing_Event__r.Name);
                        
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
                        body = body.replace('{ROUND_URL}', urlRound);
                        //AMA SP-04475 13/12/2022 16:38
                        body = body.replace('{username}', part.Contact_Bidder__r.cTin_RelatedUser__r.username);
        
                        String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
                        
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToaddresses(lstDestinataire);
                        email.setCcaddresses(lstCcDestinataire);
                        email.setTemplateId(emToParticipant.Id);
                        email.setSubject(subject);
                        email.setHtmlBody(body);
        
                        messages.add(email);

                        //AMA
                        lstBidNotifHist.add(part);

                        setRecipient.add(part.Contact_Bidder__c);
                    }
                }
            }
            
            // update bidder status to ShortListed for the previous round
            if(shortlistedlst.size()>0){
                update shortlistedlst;
            }

            if(!test.isRunningTest()){
                if(messages.size() > 0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

                    //AMA
                    AP74_ManageNotificationHistory.CreateNotificationHistory(lstBidNotifHist,results,'Notification to participant when participant is eliminated or shortlisted');

                    if (results[0].success) 
                    {
                    System.debug('The email was sent successfully.');
                    } else {
                    System.debug('The email failed to send: ' +  results[0].errors[0].message);
                    }
                }            
            }
            Negotiation_Round__c currRound = new Negotiation_Round__c(id=roundId, TECH_ShowLaunhRound__c=true);
                
            update currRound;
            result.put('success','Your changes have been saved');
        }          
        
        return result;
    }
}