public class LC02_Sing_ConfirmFinalAwardee {
/*
----------------------------------------------------------------------
-- - Name          : LC02_ConfirmFinalAwardee
-- - Author        : MRA
-- - Description   : Controller for lighning component LC02_ConfirmFinalAwardee
--                  
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 05-OCT-2021   MRA    1.0      Initial version     
-- 09-MAR-2022   MRA    1.1      Added logic to send email notif w.r.t user language                      
--------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static list<Negotiation_Round__c> retrieveLastRound(id eventId){
        list<Negotiation_Round__c> lastRound=[select id,name,Sourcing_Event__c
                                               from Negotiation_Round__c 
                                               where Sourcing_Event__c =:eventId                                              
                                               order by name desc limit 1];
        return lastRound;
    }
    
    @AuraEnabled
    public static map<string,object> sourcingEventId(id eventId){
         list<Bidder__c> lstParticipants=new list<Bidder__c>();
         map<string,object>result=new map<string,object>();
         set<id> existingAwardee=new set<id>();
          for (bidder__c bidder: [ select id,Contact_Bidder__c,Bidder_Status__c from bidder__c 
                                  where Sourcing_Event__c=:eventId 
                                  and Bidder_Status__c=:'Awardee' ] ){
            existingAwardee.add(bidder.Contact_Bidder__c);
        }
        //get last round from sourcing event
         list<Negotiation_Round__c> lastRound=retrieveLastRound(eventId);
        /*[select name,Sourcing_Event__c
                                               from Negotiation_Round__c 
                                               where Sourcing_Event__c =:eventId
                                               order by name desc limit 1];*/
        
        if(lastRound.size()>0){
        //get all short-listed partcipants from the round
         lstParticipants=[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,Contact_Bidder__r.firstname,
                             Contact_Bidder__r.lastname,Sing_AwardDetails__c,Contact_Bidder__c
                             from Bidder__c 
                             where (Bidder_Status__c=:'Short-listed' OR Bidder_Status__c=:'Participation in Progress')
                             and Negotiation_Round__c=:lastRound[0].Id
                             and Contact_Bidder__c NOT IN: existingAwardee];
        
         if(lstParticipants.size()>0){
            result.put('lst',lstParticipants);
         }
         else{
            result.put('lst','No participants availalble for selection');
         }
        }
        else{
            result.put('lst','No active rounds available');
        }
         return result;
     }
    
     @AuraEnabled
     public static map<string,object> updteParticipantlst(id eventId,list<id>participantList,list<Bidder__c>updatedlist){
         map<string,object>result=new map<string,object>();
         list<Negotiation_Round__c> lastRound=retrieveLastRound(eventId);
         system.debug('## lastRound'+lastRound);
         list<Bidder__c> updtparticipantlst=new list<Bidder__c>();
         list<Bidder__c> updtparticipantshortlisted=new list<Bidder__c>();
         list<Bidder__c> updtparticipantEliminatedlst=new list<Bidder__c>();
         set<id> uniqueEliminatedCon=new set<id>();
         system.debug('##participantList'+participantList.size());
         map<id,string> mapParticipantDetails=new map<id,string>();
        // system.debug('##updatedlist'+updatedlist[0].Allocation_Key__c);
         string srcEventId=eventId;
         system.debug('##srcEventId'+srcEventId);
         decimal totalAllocation=0.0;
         set<string> uniqueBidderKey=new set<string>();
        
         List<Messaging.SingleEmailMessage> lstEmailsEliminated = new List<Messaging.SingleEmailMessage>();
         List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
         //EmailTemplate emailTemplateAwardee = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName ='Participant_awardee_Eng'];
         //EmailTemplate emailTemplateEliminated = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName ='Participant_Eliminated_Eng'];
         EmailTemplate emailTemplateAwardee ,emailTemplateEliminated;
         map<string,emailtemplate>mapLanguageTempAwardee=new map<string,emailtemplate>();
         map<string,emailtemplate>mapLanguageTempEliminated=new map<string,emailtemplate>();
         map<string,user>mapcontactLang=new map<string,User>();
         set<id>conIdSet=new set<id>();
         for(Emailtemplate temp : [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName ='Participant_awardee_Eng' or DeveloperName ='Participant_awardee_FR' OR DeveloperName ='Participant_awardee_GE'
         OR DeveloperName ='Participant_Eliminated_Eng' OR DeveloperName ='Participant_Eliminated_FR'
         OR DeveloperName ='Participant_Eliminated_GE')]){
           if(temp.DeveloperName=='Participant_Eliminated_Eng') 
                  mapLanguageTempEliminated.put('En',temp);
           if(temp.DeveloperName=='Participant_Eliminated_FR')  
                   mapLanguageTempEliminated.put('FR',temp); 
           if(temp.DeveloperName=='Participant_Eliminated_GE')  
                   mapLanguageTempEliminated.put('GE',temp); 
           if(temp.DeveloperName=='Participant_awardee_Eng') 
                  mapLanguageTempAwardee.put('En',temp);
           if(temp.DeveloperName=='Participant_awardee_FR')  
                   mapLanguageTempAwardee.put('FR',temp); 
           if(temp.DeveloperName=='Participant_awardee_GE')  
                   mapLanguageTempAwardee.put('GE',temp); 
       
         }
         
         system.debug('## mapLanguageTempEliminated'+mapLanguageTempEliminated);
         system.debug('## mapLanguageTempAwardee'+mapLanguageTempAwardee);
          // stores the bidder name + account id
         if(updatedlist.size()>0){
             for(Bidder__c bid: updatedlist){
                 mapParticipantDetails.put(bid.id,bid.Sing_AwardDetails__c);
                /* decimal allocationkey=0.0;
                 if(bid.Allocation_Key__c==null)
                 allocationkey=0.0;
                 else*/
                /* if(participantList.contains(bid.Id)){
                     if(bid.Allocation_Key__c==null || bid.Allocation_Key__c<1){
                     result.put('validAllocation','false');
                     result.put('error','Please enter an allocation key for each participant.');
                     }
                     else{
                         decimal allocationkey=0.0;
                         if(bid.Allocation_Key__c==null)
                            allocationkey=0.0;
                         else
                            allocationkey=bid.Allocation_Key__c; 
                            totalAllocation=totalAllocation+allocationkey;
                     }
                 }  */
             }
            /* if(totalAllocation>100){
                 result.put('validAllocation','false');
                 result.put('error','Total percentage cannot exceed 100%.Please review allocation key specified for each participant.');
             } 
             else if(totalAllocation==0){
                 result.put('validAllocation','false');
                 result.put('error','Please enter an allocation key for each participant.');
             }  
            else{
                 result.put('validAllocation','true');
             }*/
             
         }
         system.debug('## participantList'+ participantList);
         for(Bidder__c bidder:[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,
                                Contact_Bidder__c,Sing_Account__c,Sourcing_Event__c,Sourcing_Event__r.name,
                                Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c, Contact_Bidder__r.Email
                                from Bidder__c 
                                where sourcing_event__c=:eventId
                                and id IN:participantList]){
           uniqueBidderKey.add( bidder.Contact_Bidder__c+ '' +bidder.Sing_Account__c); 
          // conIdSet.add(bidder.Contact_Bidder__c);                        
       }
         
       for(Bidder__c bidder:[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,
                                Contact_Bidder__c,Sing_Account__c,Sourcing_Event__c,Sourcing_Event__r.name,
                                Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c, Contact_Bidder__r.Email
                                from Bidder__c 
                                where sourcing_event__c=:eventId
                                ]){
           //uniqueBidderKey.add( bidder.Contact_Bidder__c+ '' +bidder.Sing_Account__c); 
           conIdSet.add(bidder.Contact_Bidder__c);                        
       }
       
       for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:conIdSet]){
            mapcontactLang.put(usr.ContactId,usr);        
         }
         system.debug('##mapcontactLang'+mapcontactLang);
       //system.debug('##mapParticipantAllocation'+mapParticipantAllocation);
         //if(result.get('validAllocation')=='true' ){
         if(participantList.size()>0){
            
            for(Bidder__c bidder:[select id,Bidder_Status__c,TECH_AccountName__c,TECH_ParticipantName__c,Sourcing_Event__r.name,Com_SourcingEventName__c,
                    Contact_Bidder__c,Sing_Account__c,Sourcing_Event__c,Sourcing_Event__r.Owner.Email,Contact_Bidder__r.Name,
                    Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Negotiation_Round__c, Contact_Bidder__r.Email,Contact_Bidder__r.cTin_RelatedUser__r.username
                    from Bidder__c 
                    where  (Bidder_Status__c=:'Short-listed' OR Bidder_Status__c=:'Participation in Progress')
                    and sourcing_event__c=:eventId /*and Negotiation_Round__c=:lastRound[0].Id*/]){
                              
                    if(participantList.contains(bidder.Id)){
                          // create new participant with status Awardee + link to sourcing event
                          //mra 23/11/2021
                         
                          
                        if(bidder.Negotiation_Round__c==lastRound[0].Id){
                            bidder.Bidder_Status__c='Awardee';
                                
                            /* system.debug('## creating new participant');
                            Bidder__c newParticipant=new Bidder__c();
                            newParticipant.Sourcing_Event__c=srcEventId;
                            newParticipant.Bidder_Status__c='Awardee';
                            newParticipant.Contact_Bidder__c=bidder.Contact_Bidder__c;
                            newParticipant.Sing_Account__c=bidder.Sing_Account__c;
                            if(mapParticipantDetails.containsKey(bidder.Id)  ){
                                newParticipant.Sing_AwardDetails__c =mapParticipantDetails.get(bidder.Id);
                            }
                            //newParticipant.Negotiation_Round__c='';   
                            newparticipantlst.add(newParticipant);*/

                            //HSO - 03/02/2022 - send email to participant awardee
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                            if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                                emailTemplateAwardee=mapLanguageTempAwardee.get('FR');
                            }
                            else if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='de'){
                                emailTemplateAwardee=mapLanguageTempAwardee.get('GE');
                            }
                            else{
                                emailTemplateAwardee=mapLanguageTempAwardee.get('En');
                            }
                       
                            //.setTemplateID(emailTemplateAwardee.Id);
                            //AMA 16/12/2022
                            String body = string.valueOf(emailTemplateAwardee.Body);
                            body = body.replace('{username}', mapcontactLang.get(bidder.Contact_Bidder__c).username);
                            email.setPlainTextBody(body);
                            String subject = string.valueOf(emailTemplateAwardee.Subject).replace('{!Bidder__c.Com_SourcingEventName__c}', bidder.Com_SourcingEventName__c);
                            email.setSubject(subject);

                            email.setTargetObjectId(bidder.Contact_Bidder__c);
                            email.setWhatId(bidder.Id);
                            email.setToAddresses(new List<String>{bidder.Contact_Bidder__r.Email});
                            email.setCcaddresses(new List<String>{bidder.Sourcing_Event__r.Owner.Email});
                            lstEmails.add(email);
                             system.debug('##lstEmails'+lstEmails);
                            updtparticipantlst.add(bidder);
                        }
                    }
                    else{
                        system.debug('## updating  participant');
                        system.debug('## uniqueBidderKey'+uniqueBidderKey);
                        //update existig participant record to eliminated
                        /*commented by MRA 29/09/2022 - non awardee should be eliminated
                         if(uniqueBidderKey.contains(bidder.Contact_Bidder__c+ '' +bidder.Sing_Account__c)){
                            bidder.Bidder_Status__c='Short-listed';
                            updtparticipantshortlisted.add(bidder);
                        }*/
                        //else{
                        if(bidder.Negotiation_Round__c==lastRound[0].Id){

                            bidder.Bidder_Status__c='Lost';
                            system.debug('## contact id of eliminated participant'+ bidder.Contact_Bidder__c);
                            //String body = string.valueOf(emailTemplateEliminated.HtmlValue);
                            //body = body.replace('{CONTACT_NAME}', bidder.Contact_Bidder__r.Name);
                           // body = body.replace('{SOURCING_EVENT_NAME}', bidder.Sourcing_Event__r.Name);
                           // body = body.replace('{ROUND_URL}', urlRound);
    
                            //String subject = string.valueOf(emailTemplateEliminated.Subject).replace('{SOURCING_EVENT_NAME}', bidder.Sourcing_Event__r.Name);
                            if(!uniqueEliminatedCon.contains(bidder.Contact_Bidder__c)){
                               system.debug('##mapLanguageTempEliminated'+mapLanguageTempEliminated);
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                            if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                                system.debug('## language is FR');
                                emailTemplateEliminated=mapLanguageTempEliminated.get('FR');
                            }
                            else if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='de'){
                                emailTemplateEliminated=mapLanguageTempEliminated.get('GE');
                            }
                            else{
                                system.debug('## language is En');
                                emailTemplateEliminated=mapLanguageTempEliminated.get('En');
                            }
                            
                            
                            //email.setTemplateID(emailTemplateEliminated.Id);
                            //AMA 16/12/2022
                            String body = string.valueOf(emailTemplateEliminated.Body);
                            body = body.replace('{username}', mapcontactLang.get(bidder.Contact_Bidder__c).username);
                            email.setPlainTextBody(body);
                            String subject = string.valueOf(emailTemplateEliminated.Subject).replace('{!Bidder__c.Com_SourcingEventName__c}', bidder.Com_SourcingEventName__c);
                            email.setSubject(subject);

                            email.setTargetObjectId(bidder.Contact_Bidder__c);
                            email.setWhatId(bidder.Id);
                            email.setToAddresses(new List<String>{bidder.Contact_Bidder__r.Email});
                            email.setCcaddresses(new List<String>{bidder.Sourcing_Event__r.Owner.Email});
                    
                            lstEmailsEliminated.add(email);
                            uniqueEliminatedCon.add(bidder.Contact_Bidder__c);
                            }
                            updtparticipantEliminatedlst.add(bidder);
                            system.debug('##lstEmailsEliminated'+lstEmailsEliminated);
                        }
                        
                    }
                      
            }
             
             if(!result.containsKey('error')){
                 system.debug('##updtparticipantlst'+updtparticipantlst);
                 system.debug('##updtparticipantEliminatedlst'+updtparticipantEliminatedlst);
                 system.debug('##updtparticipantlst'+updtparticipantlst);
                 try{
                     if(updtparticipantlst.size()>0){
                        try{
                            update updtparticipantlst;
                            system.debug('## try updtparticipantlst');
                            //HSO - 03/02/2022 - send email to participant awardee
                            if(lstEmails.size() > 0){
                                system.debug('## lstEmails >0');
                                try{ system.debug('## try lstEmails >0'); 
                                    Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);

                                    //AMA
                                    AP74_ManageNotificationHistory.CreateNotificationHistory(updtparticipantlst,results,'Notification to participant selected as Awardee');
                                   }
                                catch(exception e)
                                {
                                    system.debug('## catch lstEmails >0' + e.getMessage());
                                }
                            }

                        } catch(exception e){
                            system.debug('## updtparticipantlst'+ e.getMessage());
                        }
                     }//end if for awardee
                     
                     if(updtparticipantshortlisted.size()>0){
                        try{
                            update updtparticipantshortlisted; 
                        } catch(exception e){
                            system.debug('## updtparticipantshortlisted'+ e.getMessage());
                        }
                     }//end if for shortlisted
                   
                      if(updtparticipantEliminatedlst.size()>0){
                        try{
                            update updtparticipantEliminatedlst; 
                            if(lstEmailsEliminated.size() > 0){
                                system.debug('## lstEmailsEliminated >0');
                                try{
                                    Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmailsEliminated);

                                    //AMA
                                    AP74_ManageNotificationHistory.CreateNotificationHistory(updtparticipantEliminatedlst,results,'Notification to participant who have been eliminated');

                                    system.debug('## try lstEmailsEliminated >0');
                                }
                                catch(Exception e){
                                    system.debug('## catch lstEmailsEliminated >0' + e.getMessage());
                                }
                            }
                        } catch(exception e){
                            system.debug('## updtparticipantEliminatedlst'+ e.getMessage());
                        }
                     }//end if for shortlisted
                    
                 
                     /*if(newparticipantlst.size()>0){
                       try{insert newparticipantlst;} catch(exception e){system.debug('## newparticipantlst'+ e.getMessage());}  
                     }*/
                      result.put('proceeed','true');
                     result.put('success','Your changes have been saved');
                 }//end try
                 catch(exception e){system.debug('## failed '+ e.getMessage());}
             }//end if!result.error
             else{
                 result.put('error','Please enter an allocation key for each selected participant');
                 result.put('proceeed','false');
             }
         
         }
        // }
         // else{
          //      result.put('proceeed','false');
          //     result.put('error','Please select a participant');
         // }
         //}
        /* else{
            // result.put('proceeed','false');
             result.put('error','Please specify an allocation key for each selected participant.The total allocation key should not exceed 100%.');
         }*/
         
          
         return result;
     }
    
}