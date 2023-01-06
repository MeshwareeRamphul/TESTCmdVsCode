public class AP01_Sing_UpdateBidDueDateOnSourcing {
/*----------------------------------------------------------------------
-- - Name          : NegotiationRoundTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Negotiation_Round__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 30-SEP-2021  MRA  1.0      Initial version 
                              - update bid due date on sourcing event with bid due date of last round which is In progress
                              - notifies all participants which are in 'Participation in progress' of a round when bid due date is changed 
                                and notify participants (on round) is checked
-- 08-FEB-2022  ARA  1.0      SP-03260 (Translation in French for lightning components)
-- 08-MARS-2022 MRA  1.1      Release 1 esourcing - send email w.r.t user language 
-------------------------------------------------------------------------*/
    
    //method queries sourcing events related to rounds and updates event.bid due date with round.bid due date
    public static void updateBidDueDate(Map<Id, Negotiation_Round__c> mapNegotiationRound){
        list<Sourcing_Event__c> lstEventsToUpdt=new list<Sourcing_Event__c>();
        set<id> setRoundIdWithNotif=new set<id>(); // set of rounds ids for which participants needs to be notified

        Negotiation_Round__c negotiationRound;

        for(Negotiation_Round__c round:[select id,Sourcing_Event__c,
                                        Sourcing_Event__r.Bid_Due_Date__c,
                                        Sing_Round_Bid_Due_Date__c,
                                        Sing_NotifyParticipants__c
                                        from Negotiation_Round__c
                                        where id IN:mapNegotiationRound.keyset()]){
                Sourcing_Event__c srcEvent=new Sourcing_Event__c(id=round.Sourcing_Event__c,
                                                                Bid_Due_Date__c=round.Sing_Round_Bid_Due_Date__c);                            
        
                lstEventsToUpdt.add(srcEvent);
                negotiationRound = round;
                //build list of rounds where notify option is ticked and duration is changed                            
                if(round.Sing_NotifyParticipants__c){
                   setRoundIdWithNotif.add(round.id);                              
                }                        
        }   

        //update bid due date on sourcing evet with round bid due date
        if(lstEventsToUpdt.size()>0){
            try{
                update lstEventsToUpdt;
            }catch (Exception e){
            }
        }
        
        //call method to notify round participants
        /*if(setRoundIdWithNotif.size()>0)
            notifyAllParticipants(setRoundIdWithNotif);*/
    }
    
     /* MRA 09/02/2022 - commented - not valid anymore
    //method notifies participants in 'Participation in progress' when round duration changes
    public static void notifyAllParticipants(set<Id> setRoundIdWithNotif){
       
       //list<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress where address=:'admin.contract-in@axa.com' limit 1];
       List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();  
       list<string> lstAddresses=new list<string>();
       //system.debug('##owa'+owa[0].Address);
       for(Bidder__c participant: [select id,Negotiation_Round__c,Bidder_Status__c,Contact_Bidder__r.email,
                                   Contact_Bidder__r.firstname,Contact_Bidder__r.lastname,Sourcing_Event__c,
                                   Negotiation_Round__r.Round_Start_Date__c,
                                   Negotiation_Round__r.Sing_Round_Bid_Due_Date__c
                                   from Bidder__c 
                                   where Negotiation_Round__c IN:setRoundIdWithNotif
                                   and Bidder_Status__c=:'Participation in Progress']){
          
                                       
                    //set<string> keyctremail=new set<string>();
                    
                   // string ctEndDate= cteam.cTin_contract__r.EndDate__c.day() + '/' + cteam.cTin_contract__r.EndDate__c.month() + '/' + cteam.cTin_contract__r.EndDate__c.year();
                    
                    //keyctremail.add(cteam.cTin_TeamMember__r.email+''+cteam.cTin_contract__c);
                    lstAddresses.add(participant.Contact_Bidder__r.email);
                    string roundStartDate=participant.Negotiation_Round__r.Round_Start_Date__c.day() +'/'+participant.Negotiation_Round__r.Round_Start_Date__c.month()+'/'+participant.Negotiation_Round__r.Round_Start_Date__c.year();
                    string roundBidDueDate=participant.Negotiation_Round__r.Sing_Round_Bid_Due_Date__c.day() +'/'+participant.Negotiation_Round__r.Sing_Round_Bid_Due_Date__c.month()+'/'+participant.Negotiation_Round__r.Sing_Round_Bid_Due_Date__c.year();
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(lstAddresses);                   
                    //mail.setTargetObjectId(participant.id);
                    //mail.setOrgWideEmailAddressId(owa[0].id); 
                    //string mailsubject=string.format(system.label.cTin_ReminderToBOLegalSubject, new string[]{cteam.cTin_contract__r.Name, cteam.cTin_contract__r.cTin_SupplierAccount__r.name,
                    //string.valueOf(ctEndDate)});  
                    mail.setSubject('Alert: Round Duration Changed');
                  
                    mail.setSaveAsActivity(false);
                
                    string linkToRound= URL.getSalesforceBaseUrl().toExternalForm() + '/'+ participant.Negotiation_Round__c; 
                    string linkToEvent= URL.getSalesforceBaseUrl().toExternalForm() + '/'+ participant.Sourcing_Event__c;
                                       
                    string body = string.format(system.label.sing_AP01_NotifToParticipants, new string[]{string.valueOf(participant.Contact_Bidder__r.firstname + ' ' +participant.Contact_Bidder__r.lastname),
                    linkToRound,
                    linkToEvent,
                    string.valueOf(roundStartDate),
                    string.valueOf(roundBidDueDate)});
                    system.debug('##body'+body);
                    mail.setHTMLBody(body);
                 
                    allmsg.add(mail);                                     
       }
       system.debug('##allmsg'+allmsg);
       //send mail list participants >0
       if(allmsg.size()>0)
           try{ Messaging.sendEmail(allmsg);}
        catch(exception e){
            system.debug('##Exception'+e.getMessage());
        }
    }*/

    @AuraEnabled
    public static map<string,object> launchParticipation(String objID){
        Map<String,Object> mapResult = new Map<String,Object>();
        List<String> setContact = new List<String>();
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        map<string,string> mapLanguageTemplate=new map<string,string>();
        map<string,EmailTemplate> mapLanguageTemplateGE=new map<string,EmailTemplate>();
        EmailTemplate emToParticipant;
        //Get template id for set the template En / FR
        for (EmailTemplate temp :[SELECT Id,Subject,Description,name, HtmlValue,DeveloperName,Body
                                        FROM EmailTemplate 
                                        WHERE (name =:'Bidder participation confirmation' OR
                                        name=:'Bidder participation confirmation FR'
                                        OR name=:'Bidder participation confirmation HTMLGE')]){
                   if(temp.name=='Bidder participation confirmation' ) 
                      mapLanguageTemplate.put('En',temp.Id);
                   if(temp.name=='Bidder participation confirmation FR' )  
                       mapLanguageTemplate.put('FR',temp.Id); 
                   if(temp.name=='Bidder participation confirmation HTMLGE' )  
                       mapLanguageTemplateGE.put('GE',temp);                 
         }                               
        //Get Selected Participant
        List<Bidder__c> lstBidder = [SELECT Id, Contact_Bidder__c, Contact_Bidder__r.Email,
                                     contact_bidder__r.cTin_PreferredLanguage__c,
                                     Sourcing_Event__r.RecordType.name,Sourcing_Event__r.owner.email,
                                     TECH_ContactName__c,
                                     Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.TECH_GMT__c,
                                     Sourcing_Event__r.Name
                                    FROM Bidder__c
                                    WHERE Sourcing_Event__c = :objID
                                    AND Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_SELECTED];
        if(lstBidder.size() > 0){ 
            for(Bidder__c bid : lstBidder){
                Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();

                if(bid.contact_bidder__r.cTin_PreferredLanguage__c=='French'){
                    email.setTemplateID(mapLanguageTemplate.get('FR')); email.setTargetObjectId(lstBidder[0].Contact_Bidder__c);
                    //email.setSenderDisplayName('Admin Contract-In');
                    //message.setReplyTo('no-reply@company.com');
                    //This is important for the merge fields in template to work
                    email.setWhatId(bid.ID);email.setTreatTargetObjectAsRecipient(false); email.setToAddresses(new List<String>{bid.Contact_Bidder__r.Email});email.setCcaddresses(new List<String>{bid.Sourcing_Event__r.owner.email});
                }
                else if(bid.contact_bidder__r.cTin_PreferredLanguage__c=='German'){
                     //email.setTemplateID(mapLanguageTemplate.get('GE'));
                    emToParticipant=mapLanguageTemplateGE.get('GE');
                    String body = string.valueOf(emToParticipant.HtmlValue);
                    string link=system.label.AP01_ConfirmParticipationLink+bid.ID;
                    body= body.replace('{!Bidder__c.Id}',link);body= body.replace('{!Bidder__c.TECH_ContactName__c}',bid.TECH_ContactName__c); body= body.replace('{!Sourcing_Event__c.Name}',bid.Sourcing_Event__r.Name);body= body.replace('{!Sourcing_Event__c.Publish_start_date_time__c}',string.valueOf(bid.Sourcing_Event__r.Publish_start_date_time__c));
                    body=body.replace('{!Sourcing_Event__c.TECH_GMT__c}',bid.Sourcing_Event__r.TECH_GMT__c);
                    //String subject = string.valueOf(emToParticipant.subject);
                    string subject='Einladung von AXA zur Teilnahme an der Ausschreibung ' + bid.Sourcing_Event__r.RecordType.name+ ' - '+ bid.Sourcing_Event__r.Name;
                    //String conId = string.valueOf(part.Contact_Bidder__c);
                    //Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToaddresses(new List<String>{bid.Contact_Bidder__r.Email}); email.setCcaddresses(new List<String>{bid.Sourcing_Event__r.owner.email});
                    //email.setCcaddresses(lstCcDestinataire);                    
                    email.setTemplateID(emToParticipant.Id);email.setSubject(subject);email.setHtmlBody(body);
        
                }
                else{
                    email.setTemplateID(mapLanguageTemplate.get('En'));
                    email.setTargetObjectId(lstBidder[0].Contact_Bidder__c);
                    //email.setSenderDisplayName('Admin Contract-In');
                    //message.setReplyTo('no-reply@company.com');
                    //This is important for the merge fields in template to work
                    email.setWhatId(bid.ID);
                    email.setTreatTargetObjectAsRecipient(false);
                    email.setToAddresses(new List<String>{bid.Contact_Bidder__r.Email});email.setCcaddresses(new List<String>{bid.Sourcing_Event__r.owner.email});
                }
                    
                lstEmails.add(email);
            }

            Messaging.SendEmailResult[] results;
            
            // 08-FEB-2022  ARA  SP-03260
            if(!test.isRunningTest()){
                results = Messaging.sendEmail(lstEmails);
                //AMA
                AP74_ManageNotificationHistory.CreateNotificationHistory(lstBidder,results,'Notification to participant to confirm his participation');

                if (results[0].success){
                    mapResult.put('success', System.Label.AP01_ConfirmationEmailSent);
                }
                else{                                    mapResult.put('error', System.Label.AP01_ConfirmationEmailFailed + results[0].errors[0].message);                }
            }else{
                //AMA
                AP74_ManageNotificationHistory.CreateNotificationHistory(lstBidder,results,'Notification to participant to confirm his participation');
                
                mapResult.put('success', System.Label.AP01_ConfirmationEmailSent);
            }
        }
        else{             
            mapResult.put('error', System.Label.AP01_SendingInvitationFailed);
        }
        return mapResult;
    }
}