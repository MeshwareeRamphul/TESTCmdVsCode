public without sharing class AP61_SendEmail_ESourcing {
    

    public static void sendTo_ConfirmedParticipant (List<Sourcing_Event__c> lstSourcEvt){

        //String emTemp = System.Label.L61_EmailTemplate_SourcingPublished;
        map<string,EmailTemplate > mapLanguageTemplate=new map<string,EmailTemplate >();
        set<id>setConid=new set<id>();
        map<string,User>mapcontactLang=new map<string,User>();
       // map<id,string> mapConIdTimezone=new map<id, string>();
       // list<user> lstUsrTbUdt=new list<User>();
        //Get template id for set the template En / FR
        for (EmailTemplate temp :[SELECT Id,Subject,Description,name, HtmlValue,DeveloperName,Body
                                        FROM EmailTemplate 
                                        WHERE (DeveloperName = :'Sourcing_Event_Name_Published_Eng' OR
                                        DeveloperName = :'Sourcing_Event_Name_Published_FR'
                                        OR DeveloperName = :'Sourcing_Event_Name_Published_GE')]){
                   if(temp.DeveloperName=='Sourcing_Event_Name_Published_Eng' ) 
                      mapLanguageTemplate.put('En',temp);
                   if(temp.DeveloperName=='Sourcing_Event_Name_Published_FR' )  
                       mapLanguageTemplate.put('FR',temp);  
                   if(temp.DeveloperName=='Sourcing_Event_Name_Published_GE' ) 
                      mapLanguageTemplate.put('GE',temp);                
         }                
        emailtemplate emToParticipant ;
        //= [SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'Sourcing_Event_Name_Published_Eng' ];
        //System.debug('email@@@ ' + emToParticipant);
        List<Bidder__c> lstParticipant= new List<Bidder__c>();
        for(bidder__c part:[SELECT id, contact_bidder__r.cTin_PreferredLanguage__c,Contact_Bidder__r.Email,Sourcing_Event__r.Preferred_Time_Zone2__c,
                            Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,
                            Sourcing_Event__r.owner.name,Sourcing_Event__r.BusinessOwner__r.email,Contact_Bidder__r.cTin_RelatedUser__r.username,
                                                Bidder_Status__c , Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.Bid_Due_Date__c
                                        FROM Bidder__c 
                                        WHERE Sourcing_Event__c IN: lstSourcEvt 
                                           AND ( Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_CONFIRMED 
                                                OR Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_NDASIGNED)]){
            lstParticipant.add(part); 
            setConid.add(part.Contact_Bidder__c);
           // mapConIdTimezone.put(part.Contact_Bidder__c,part.Sourcing_Event__r.Preferred_Time_Zone2__c.split(' ')[1]);
        }
        
        // MRA 08/11/2022 - Added update Timezone functionality after publish
         for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,timezonesidKey,username FROM User WHERE ContactId IN:setConid]){   
             /*if(mapConIdTimezone.containsKey(usr.ContactId)){
                 usr.timezonesidKey =  mapConIdTimezone.get(usr.ContactId); 
                 lstUsrTbUdt.add(usr);
             }  */    
             mapcontactLang.put(usr.ContactId,usr);             
         }
         
        // if(lstUsrTbUdt.size()>0)
            // update lstUsrTbUdt;
        
        System.debug('lstPart@@@' + lstParticipant);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        
        
        List<String> lstCcDestinataire = new List<String>();

        Set<id> setRecipient = new Set<id>();
        if(lstParticipant.size()> 0){

            for(Bidder__c part : lstParticipant){
                if(setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )){
                    List<String> lstDestinataire = new List<String>();
                    lstDestinataire.add(part.Contact_Bidder__r.Email);
                    lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);
                    //AMA 29/09/2022 add business owner to cc
                    lstCcDestinataire.add(part.Sourcing_Event__r.BusinessOwner__r.Email);
                    //System.debug('Name@@   ' +part.Sourcing_Event__r.Name + 'pubDate@@@   '+ part.Sourcing_Event__r.Publish_start_date_time__c + 'bid@@@   '+ part.Sourcing_Event__r.Bid_Due_Date__c);
        
                    
                    Datetime publishDate = part.Sourcing_Event__r.Publish_start_date_time__c;
                    Datetime bidDate = part.Sourcing_Event__r.Bid_Due_Date__c;
                    
                    system.debug('## part.contact_bidder__r.cTin_PreferredLanguage__c'+part.contact_bidder__r.cTin_PreferredLanguage__c);
                    system.debug('##mapLanguageTemplate' +mapLanguageTemplate);
                    /*if(part.contact_bidder__r.cTin_PreferredLanguage__c=='English')
                        emToParticipant=mapLanguageTemplate.get('En');                   
                    if(part.contact_bidder__r.cTin_PreferredLanguage__c=='French')
                        emToParticipant=mapLanguageTemplate.get('FR');
                    if(part.contact_bidder__r.cTin_PreferredLanguage__c=='German' || part.contact_bidder__r.cTin_PreferredLanguage__c=='Dutch')
                        emToParticipant=mapLanguageTemplate.get('GE');
                    if(emToParticipant == null){
                        emToParticipant=mapLanguageTemplate.get('En');
                    }*/
                    if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='fr'){                        emToParticipant=mapLanguageTemplate.get('FR');                    }
                    else if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='de'){                        emToParticipant=mapLanguageTemplate.get('GE');                    }
                    else{
                        emToParticipant=mapLanguageTemplate.get('En');
                    }
                    String body = string.valueOf(emToParticipant.HtmlValue);
                    body = body.replace('{CONTACT_NAME}', part.Contact_Bidder__r.Name);
                    body = body.replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
                    //body =body.replace('{PUBLISHED_DATE}', publishDate.day() + '/' + publishDate.month() +'/' + publishDate.year() + '/' + publishDate );
                    body =body.replace('{PUBLISHED_DATE}', string.valueOf(publishDate) );
                    //body =body.replace('{BID_DUE_DATE}', bidDate.day() + '/' + bidDate.month() +'/' + bidDate.year());
                    body =body.replace('{BID_DUE_DATE}', string.valueOf(bidDate));
                    body=body.replace ('GMT+1', string.valueOf(part.Sourcing_Event__r.Preferred_Time_Zone2__c.split(' ')[0]));
                    body = body.replace('{URL_Vendor_Portal}', System.label.L31_urlVendorPortal);
                    body =body.replace('{Record_Owner}',string.valueOf(part.Sourcing_Event__r.owner.name));
                    //AMA SP-04475 13/12/2022 16:38
                    body = body.replace('{username}', mapcontactLang.get(part.Contact_Bidder__c).username);
                    System.debug('body@@ ' + body);
        
                    String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
        
                    String conId = string.valueOf(part.Contact_Bidder__c);
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToaddresses(lstDestinataire);
                    email.setCcaddresses(lstCcDestinataire);                    
                    email.setTemplateID(emToParticipant.Id);
                   
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
                    AP74_ManageNotificationHistory.CreateNotificationHistory(lstParticipant,results,'Notification to participants when sourcing event is published');

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

    public static void sendTo_ShortlistedOrInProgress_Participant (List<Sourcing_Event__c> lstSrcEvt){

       // String emTemp = System.Label.L61_EmailTemplate_SourcingCanceled;
        map<string,EmailTemplate >mapLanguageTemplate=new map<string,EmailTemplate >();
        for (EmailTemplate temp :[SELECT Id,Subject,Description,name, HtmlValue,DeveloperName,Body
                                        FROM EmailTemplate 
                                        WHERE (DeveloperName = :'Sourcing_Event_Name_Canceled_Eng' OR
                                        DeveloperName = :'Sourcing_Event_Name_Canceled_FR'
                                        OR DeveloperName = :'Sourcing_Event_Name_Canceled_GE')]){
                   if(temp.DeveloperName=='Sourcing_Event_Name_Canceled_Eng' ) 
                      mapLanguageTemplate.put('En',temp);
                   if(temp.DeveloperName=='Sourcing_Event_Name_Canceled_FR' )  
                       mapLanguageTemplate.put('FR',temp); 
                   if(temp.DeveloperName=='Sourcing_Event_Name_Canceled_GE' )  
                       mapLanguageTemplate.put('GE',temp);                  
         }   
        EmailTemplate emToParticipant;
        // = [SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'Sourcing_Event_Name_Canceled_Eng' LIMIT 1];
        set<id> setConid=new set<id>();
        map<string,user> mapcontactLang=new map<string,user>();
        List<Bidder__c> lstParticipant= new List<Bidder__c>();
        for(bidder__c bidder: [SELECT id, Contact_Bidder__r.Email, Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,Contact_Bidder__r.cTin_RelatedUser__r.username,
                                Sourcing_Event__r.Owner.name,Bidder_Status__c , Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.Bid_Due_Date__c,Contact_Bidder__c
                                        FROM Bidder__c 
                                        WHERE Sourcing_Event__c IN: lstSrcEvt
                                            AND ( (Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_SHORTLISTED)
                                                 OR (Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_NDASIGNED)
                                                 OR (Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS) )]){
            lstParticipant.add(bidder);
            setConid.add(bidder.Contact_Bidder__c);
            
        }
        
        for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:setConid]){            mapcontactLang.put(usr.ContactId,usr);                }
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        
        List<String> lstCcDestinataire = new List<String>();

        Set<id> setRecipient = new Set<id>();
        if(lstParticipant.size()> 0){
            for(Bidder__c part : lstParticipant){
                if(setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )){
                    
                    List<String> lstDestinataire = new List<String>();
                    lstDestinataire.add(part.Contact_Bidder__r.Email);
                    lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);
                
                    String body;
                     //= string.valueOf(emToParticipant.HtmlValue);
                        
                    if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                        emToParticipant=mapLanguageTemplate.get('FR');
                    }
                    else if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='de'){
                        emToParticipant=mapLanguageTemplate.get('GE');
                    }
                    else{
                        emToParticipant=mapLanguageTemplate.get('En');
                    }
                    
                    body=emToParticipant.HtmlValue;
                    body = body.replace('{CONTACT_NAME}', part.Contact_Bidder__r.Name);
                    body = body.replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);
                    body=body.replace('{SOURCING_EVENT_Owner}',part.Sourcing_Event__r.Owner.name);
                    //AMA 16/12/222
                    body = body.replace('{username}', mapcontactLang.get(part.Contact_Bidder__c).username);
                    System.debug('body@@ ' + body);

                    String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToaddresses(lstDestinataire);
                    email.setCcaddresses(lstCcDestinataire);
                    
                    if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                        email.setTemplateId( mapLanguageTemplate.get('FR').Id);
                    }
                    else if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='de'){
                         email.setTemplateId( mapLanguageTemplate.get('GE').Id);
                    }
                    else{
                        email.setTemplateId( mapLanguageTemplate.get('En').Id);
                    }
                    
                    
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
                    AP74_ManageNotificationHistory.CreateNotificationHistory(lstParticipant,results,'Notification to participants when sourcing event is cancelled');

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

    public static void sendWhen_PendingStatus(List<Sourcing_Event__c> lstSrcEvt) {
        system.debug('## startig method sendWhen_PendingStatus');
        EmailTemplate emToParticipant;
        map<string,EmailTemplate >mapLanguageTemplate=new map<string,EmailTemplate >();
        for(emailTemplate temp : [SELECT id , HtmlValue, Subject, DeveloperName, Body 
                                  FROM EmailTemplate WHERE (DeveloperName = 'Sourcing_Event_Name_Pending_Eng' 
                   OR DeveloperName ='Sourcing_Event_Name_Pending_FR'
                   OR DeveloperName ='Sourcing_Event_Name_Pending_GE')]){
               if(temp.DeveloperName=='Sourcing_Event_Name_Pending_Eng' ) 
                  mapLanguageTemplate.put('En',temp);
               if(temp.DeveloperName=='Sourcing_Event_Name_Pending_FR' )  
                   mapLanguageTemplate.put('FR',temp); 
               if(temp.DeveloperName=='Sourcing_Event_Name_Pending_GE' )  
                   mapLanguageTemplate.put('GE',temp);     
                   
        }
        
        system.debug('emToParticipant'+emToParticipant);
        List<Bidder__c> lstParticipant= new List<Bidder__c>();
        set<id> setConid=new set<id>();
        map<string,user> mapcontactLang=new map<string,user>();
        
       for (bidder__c bid : [SELECT id, Contact_Bidder__r.Email, Sourcing_Event__c, Sourcing_Event__r.Owner.Email,Sourcing_Event__r.Name,Contact_Bidder__r.Name,
                                                Bidder_Status__c ,TECH_EventOwner__c, Sourcing_Event__r.Publish_start_date_time__c,Sourcing_Event__r.Bid_Due_Date__c
                                        FROM Bidder__c 
                                        WHERE Sourcing_Event__c IN: lstSrcEvt
                                            AND ( Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_SHORTLISTED 
                                                    OR Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS 
                                                    OR Bidder_Status__c =: AP_Constant.PARTICIPANT_STATUS_CONFIRMED)
                                                    AND (TECH_IsfromLastRound__c=true)]){
           setConid.add(bid.Contact_Bidder__c);
           lstParticipant.add(bid);
           
       }
       
        for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:setConid]){            mapcontactLang.put(usr.ContactId,usr);                }
        system.debug('|## mapcontactLang'+ mapcontactLang);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        
      
        List<String> lstCcDestinataire = new List<String>();

        Set<id> setRecipient = new Set<id>();
        if(lstParticipant.size()> 0){
            system.debug('## has participants');
            for(Bidder__c part : lstParticipant){
                String body;
                if(setRecipient.size() > 0 && !setRecipient.contains(part.Contact_Bidder__c) || (setRecipient.size() == 0 )){
                    List<String> lstDestinataire = new List<String>();
                    lstDestinataire.add(part.Contact_Bidder__r.Email);
                    lstCcDestinataire.add(part.Sourcing_Event__r.Owner.Email);

                    if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='fr'){                        emToParticipant=mapLanguageTemplate.get('FR');                    }
                    else if(mapcontactLang.get(part.Contact_Bidder__c).LanguageLocaleKey=='de'){                        emToParticipant=mapLanguageTemplate.get('GE');                    }
                    else{                        emToParticipant=mapLanguageTemplate.get('En');                    }
                
                    body = emToParticipant.HtmlValue;
                    body = body.replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);body = body.replace('{SOURCING_EVENT_OWNER}', part.TECH_EventOwner__c);
                    //AMA SP-04475 16/12/2022
                    body = body.replace('{username}', mapcontactLang.get(part.Contact_Bidder__c).username);
                    
                    System.debug('body@@ ' + body);

                    String subject = string.valueOf(emToParticipant.Subject).replace('{SOURCING_EVENT_NAME}', part.Sourcing_Event__r.Name);

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); email.setToaddresses(lstDestinataire);email.setCcaddresses(lstCcDestinataire);                    email.setTemplateId(emToParticipant.Id);email.setSubject(subject); email.setHtmlBody(body);
                    //email.setToaddress(string.valueOf(part.Contact_Bidder__r.Email));email.setCcaddresses(lstCcDestinataire);                    email.setTemplateId(emToParticipant.Id);email.setSubject(subject); email.setHtmlBody(body);

                    messages.add(email);
                    setRecipient.add(part.Contact_Bidder__c);
                }
            }
            
            if(!test.isRunningTest()){
                if(messages.size() > 0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

                    //AMA
                    AP74_ManageNotificationHistory.CreateNotificationHistory(lstParticipant,results,'Email notification to participants when sourcing event is pending for selection');

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

    // 04-FEB-2022  HSO - Send mail to awardee participant when sourcing event is completed
    public static void sendWhen_EventCompleted(List<Sourcing_Event__c> lstSourcEvt){
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        Set<Id> setRecipient = new Set<Id>();
        EmailTemplate emToParticipant;
        map<string,emailtemplate>mapLanguageTemplate=new map<string,emailtemplate>();
        for(EmailTemplate temp : [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName ='Sourcing_Event_Completed_Eng' or developername='Sourcing_Event_Completed_FR' or developername='Sourcing_Event_Completed_GE')]){
             if(temp.DeveloperName=='Sourcing_Event_Completed_Eng' ) 
                  mapLanguageTemplate.put('En',temp);
             if(temp.DeveloperName=='Sourcing_Event_Completed_FR' )  
                   mapLanguageTemplate.put('FR',temp);
             if(temp.DeveloperName=='Sourcing_Event_Completed_GE' )  
                   mapLanguageTemplate.put('GE',temp);
        
        }
        List<Bidder__c> lstBid=new list<Bidder__c>();
        set<id> setConid=new set<id>();
        map<string,user> mapcontactLang=new map<string,user>();
        for (Bidder__c bid : [SELECT Id, TECH_EventOwner__c,Contact_Bidder__c, Contact_Bidder__r.Email, Sourcing_Event__r.Owner.Email,Com_SourcingEventName__c,Contact_Bidder__r.cTin_RelatedUser__r.username FROM Bidder__c WHERE Sourcing_Event__c IN :lstSourcEvt AND Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_AWARDEE  AND (TECH_IsfromLastRound__c=true)]){
            lstBid.add(bid);
            setConid.add(bid.Contact_Bidder__c);
        }
        
        for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:setConid]){
            mapcontactLang.put(usr.ContactId,usr);        
        }
        
        if(lstBid.size() > 0){
            for(Bidder__c bidder : lstBid){
                if(setRecipient.size() > 0 && !setRecipient.contains(bidder.Contact_Bidder__c) || (setRecipient.size() == 0 )){

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        
                if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                    emToParticipant=mapLanguageTemplate.get('FR');
                }
                else if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='de'){
                    emToParticipant=mapLanguageTemplate.get('GE');
                }
                else{
                    emToParticipant=mapLanguageTemplate.get('En');
                }
                       
                //email.setTemplateID(emToParticipant.Id);
                //AMA 16/12/2022
                String body = string.valueOf(emToParticipant.Body);
                body = body.replace('{username}', mapcontactLang.get(bidder.Contact_Bidder__c).username);
                email.setPlainTextBody(body);
                String subject = string.valueOf(emToParticipant.Subject).replace('{!Bidder__c.Com_SourcingEventName__c}', bidder.Com_SourcingEventName__c);
                email.setSubject(subject);

                email.setTargetObjectId(bidder.Contact_Bidder__c);
                email.setWhatId(bidder.Id);
                email.setToAddresses(new List<String>{bidder.Contact_Bidder__r.Email});
                email.setCcAddresses(new List<String>{bidder.Sourcing_Event__r.Owner.Email});
        
                lstEmails.add(email);
                setRecipient.add(bidder.Contact_Bidder__c);
                }
            }
        }

        if(lstEmails.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);

            //AMA
            AP74_ManageNotificationHistory.CreateNotificationHistory(lstBid,results,'Notification to participant when sourcing event is completed');
        }

    }
    
    // 04/02/2022  MRA - Send mail to participant(shortlisted + in progress) 24hrs before bid due date is reached
    public static void NotifyBidDueDateReached(List<Sourcing_Event__c> lstSourcEvt){
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        set<id>setRecipient=new set<id>();
        map<string,emailtemplate>mapLanguageTemplate=new map<string,emailtemplate>();
        EmailTemplate emToParticipant; 
        for(EmailTemplate temp : [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE (DeveloperName ='Round_BidDueDate_Ending_Eng' or developername='Round_BidDueDate_Ending_FR' or developername='Round_BidDueDate_Ending_GE')]){
            if(temp.DeveloperName=='Round_BidDueDate_Ending_Eng' ) 
                  mapLanguageTemplate.put('En',temp);
            if(temp.DeveloperName=='Round_BidDueDate_Ending_FR' )  
                   mapLanguageTemplate.put('FR',temp);
            if(temp.DeveloperName=='Round_BidDueDate_Ending_GE' )  
                   mapLanguageTemplate.put('GE',temp);
        
        }
        List<Bidder__c> lstBid = new list<Bidder__c>();
        set<id> setConid=new set<id>();
        map<string,user> mapcontactLang=new map<string,user>();
        for (bidder__c bid: [SELECT Id, Contact_Bidder__c, Contact_Bidder__r.Email, Sourcing_Event__r.Owner.Email,Contact_Bidder__r.cTin_RelatedUser__r.username,Com_SourcingEventName__c,TECH_ParticipantName__c,TECH_EventOwner__c FROM Bidder__c WHERE Sourcing_Event__c IN :lstSourcEvt
                                  AND (Bidder_Status__c =:AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS
                                 or Bidder_Status__c =:AP_Constant.PARTICIPANT_STATUS_SHORTLISTED)]){
       
          setConid.add(bid.Contact_Bidder__c);
          lstBid.add(bid);
       }
       
       for(User usr: [SELECT Id,Name,Email,ContactId,LanguageLocaleKey,Username FROM User WHERE ContactId IN:setConid]){
            mapcontactLang.put(usr.ContactId,usr);        
        }
        
        if(lstBid.size() > 0){
            for(Bidder__c bidder : lstBid){
               if(setRecipient.size() > 0 && !setRecipient.contains(bidder.Contact_Bidder__c) || (setRecipient.size() == 0 )){

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
                if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                    emToParticipant=mapLanguageTemplate.get('FR');
                }
                else if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='de'){
                     emToParticipant=mapLanguageTemplate.get('GE');
                }
                else{
                    emToParticipant=mapLanguageTemplate.get('En');
                }
                //email.setTemplateID(emToParticipant.Id);
                //AMA 16/12/2022
                String body = string.valueOf(emToParticipant.Body);
                if(mapcontactLang.get(bidder.Contact_Bidder__c).LanguageLocaleKey=='de'){
                    body = body.replace('{!Bidder__c.TECH_EventOwner__c}', bidder.TECH_EventOwner__c);
                }
                body = body.replace('{!Bidder__c.Com_SourcingEventName__c}', bidder.Com_SourcingEventName__c);
                body = body.replace('{!Bidder__c.Contact_Bidder__c}', bidder.TECH_ParticipantName__c);
                body = body.replace('{username}', mapcontactLang.get(bidder.Contact_Bidder__c).username);
                email.setPlainTextBody(body);
                String subject = string.valueOf(emToParticipant.Subject).replace('{!Bidder__c.Com_SourcingEventName__c}', bidder.Com_SourcingEventName__c);
                email.setSubject(subject);

                email.setTargetObjectId(bidder.Contact_Bidder__c);
                email.setWhatId(bidder.Id);
                email.setToAddresses(new List<String>{bidder.Contact_Bidder__r.Email});
                email.setCcAddresses(new List<String>{bidder.Sourcing_Event__r.Owner.Email});
        
                lstEmails.add(email);
                setRecipient.add(bidder.Contact_Bidder__c);
               }
            }
        }

        if(lstEmails.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);

            //AMA
            AP74_ManageNotificationHistory.CreateNotificationHistory(lstBid,results,'Email notification to participants 24hrs before round bid due date is reached');
        }

    }
}