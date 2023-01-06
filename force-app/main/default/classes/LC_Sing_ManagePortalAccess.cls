public without sharing class LC_Sing_ManagePortalAccess{
    /*----------------------------------------------------------------------
    -- - Name          : LC_Sing_ManagePortalAccess
    -- - Author        : Spoon
    -- - Description   : updates CountJustificationDocument__c on sourcing event when doc is uploaded / deleted
    -- - History:
    
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 06-OCT-2021  MRA  1.0      Initial version 
    -- 14-DEC-2021  ARA  2.0      SP-03021  access for Sourcing events tab on Vendor portal
    -- 02-FEB-2021  ARA  3.0      SP-03359  take the contact's language in the field "Prefered language" and add it to the language field on the community user
    -------------------------------------------------------------------------*/

    @AuraEnabled
    public static map<string,object> openAccess(String srcEventId){ 
        system.debug('## starting method openAccess srcEventId'+ srcEventId);
        //srcEventId='a1H3O000000eXBAUA2';
        list<user>lstNewUser = new list<User>();
        list<user>lstActivateExistingUser = new list<User>();
        map<string,object> mapResult = new map<string,object>();
        set<id> setContactAsPortalUser = new set<id>();
        map<id,contact> mapConIdContact = new map<id,Contact>();
        set<id> existingUsers = new set<id>();
        set<id> userToActivate = new set<id>();
        map<id,user> mapConIdUser = new map<id,User>();
        
        for(Bidder__c bidder: [select id,sourcing_event__r.NDA_Mandatory__c,Contact_Bidder__c,Bidder_Status__c
                               from bidder__c where sourcing_event__c=:srcEventId
                               and (Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_NDASIGNED or Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_CONFIRMED)]){
            if(!bidder.sourcing_event__r.NDA_Mandatory__c){
                if(bidder.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_CONFIRMED)
                    setContactAsPortalUser.add(bidder.Contact_Bidder__c);
            }else{
                system.debug('## bidder NDA signed');
                setContactAsPortalUser.add(bidder.Contact_Bidder__c);
            }                
        }
        
        system.debug('##setContactAsPortalUser'+setContactAsPortalUser);
        if(setContactAsPortalUser.size()>0){
            //Query active community users for each contact
            for (User user: [SELECT Id,isActive,contactId FROM User WHERE contactId IN:setContactAsPortalUser
                            and profile.name=:AP_Constant.esourcingVendorProfile]){
                if(user.isactive){
                    system.debug('## already activated');
                    existingUsers.add(user.contactId);
                }
                else{
                    system.debug('## NOT already activated');
                    userToActivate.add(user.contactId);  
                    mapConIdUser.put(user.contactId,user);
                }            
            }
            System.debug('User to activate : ' + userToActivate.size());

             //build map contactid => contact
            for(Contact con:[select id, firstname, lastname, email, cTin_PreferredLanguage__c from Contact where id IN:setContactAsPortalUser]){
                mapConIdContact.put(con.Id,con);
            }
            
            //Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community Plus User' Limit 1];
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name=:AP_Constant.esourcingVendorProfile Limit 1];
            System.debug('Existing Users' + existingUsers);
            for(id cId: setContactAsPortalUser){
                System.debug('CID ' + cId);
                if(!existingUsers.contains(cId)){
                    system.debug('## creating new user');
                    //create and activate community user
                    system.debug('## mapConIdContact.get(cId) '+mapConIdContact.get(cId));
                    String language = 'en_US';
                    String FirstName = ''; 
                    String FirstName2 = ''; 
                    if(mapConIdContact.get(cId).FirstName != null && mapConIdContact.get(cId).FirstName != ''){
                        FirstName = mapConIdContact.get(cId).FirstName.substring(0,1);
                        FirstName2 = mapConIdContact.get(cId).FirstName.substring(0,2);
                    }
                    string usrAlias = FirstName + mapConIdContact.get(cId).LastName;
                    if(usrAlias.length() > 8){
                        usrAlias = usrAlias.substring(0,8);
                    }
                    
                    switch on mapConIdContact.get(cId).cTin_PreferredLanguage__c {
                        when 'French' {
                            language = 'fr';
                        }
                        when 'German' {
                            language = 'de';
                        }
                        when else {
                            language = 'en_US';
                        }
                    }
                        
                    User usr = new User(
                            UserName = /*System.now().getTime() + */mapConIdContact.get(cId).email,
                            FirstName = mapConIdContact.get(cId).FirstName,
                            LastName = mapConIdContact.get(cId).LastName,
                            Alias =  usrAlias ,
                            email = mapConIdContact.get(cId).email,
                            ContactId = cId,
                            ProfileId = portalProfile.Id,
                            EmailEncodingKey = 'UTF-8',
                            CommunityNickname = FirstName2+mapConIdContact.get(cId).LastName + String.valueOf(Integer.valueof((Math.random() * 10))),
                            TimeZoneSidKey = 'Europe/Paris',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            isactive = true
                    );
                    lstNewUser.add(usr);
                }
            }
            
            if(userToActivate.size()>0){
                for(id cId: userToActivate){
                    system.debug('## activating existing user');
                    String language = 'en_US';
                    switch on mapConIdContact.get(cId).cTin_PreferredLanguage__c {
                        when 'French' {
                            language = 'fr';
                        }
                        when 'German' {
                            language = 'de';
                        }
                        when else {
                            language = 'en_US';
                        }
                    }
                    User usr = new User();
                    usr.Id = mapConIdUser.get(cId).Id;
                    usr.LanguageLocaleKey = language;
                    usr.isactive = true;
                    lstActivateExistingUser.add(usr);
                }
            }
            if(lstNewUser.size()>0){
                insert lstNewUser;
                mapResult.put('success','Access to portal successfully activated.');
            }
            
            system.debug('## lstActivateExistingUser'+lstActivateExistingUser.size());
            if(lstActivateExistingUser.size()>0){
                try{
                    update lstActivateExistingUser;
                    //send welcome / pwd reset email
                    for (User u : lstActivateExistingUser) {
                        System.resetPassword(u.Id,True);
                    }
                    mapResult.put('success','Access to portal successfully activated.');
                }
                catch(Exception e){
                    system.debug('## exception ' + e.getMessage());
                    mapResult.put('error',e.getMessage());
                }
            }
        }
        else{
             mapResult.put('error','This action cannot be performed because no participant is eligible for activation');
        }

        if(mapResult.size()==0)
            mapResult.put('success','Access to Portal is successfully activated');

        return mapResult;
    }

    @future 
    public static void closeAccess(set<id> setContactId){ 
        set<id> ContactsWithNoUpdt=new set <id>();
        set<id> ContactsToDeactivate=new set <id>();
        list<user> lstUserToDeactivate=new list<User>();
        for(Bidder__c bidder: [ SELECT Id,Contact_Bidder__c,Bidder_Status__c,Sourcing_event__r.Sourcing_Status__c, Sourcing_event__r.NDA_Mandatory__c
                                FROM Bidder__c 
                                WHERE Contact_Bidder__c IN:setContactId 
                                AND Bidder_Status__c != :AP_Constant.PARTICIPANT_STATUS_LOST 
                                AND Bidder_Status__c != :AP_Constant.PARTICIPANT_STATUS_DECLINED
                                AND Sourcing_event__r.Sourcing_Status__c!= :AP_Constant.SOURCING_EVENT_STATUS_CANCELLED
                                AND ((Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_NDASIGNED AND Sourcing_event__r.NDA_Mandatory__c = true)
                                    OR (Bidder_Status__c = :AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS AND Sourcing_event__r.NDA_Mandatory__c = false)
                                    OR Sourcing_event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED
                                    OR Sourcing_event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_COMPLETED
                                ) ]){
        	ContactsWithNoUpdt.add(bidder.Contact_Bidder__c);
        }
        
        for(id con:setContactId){
            if(!ContactsWithNoUpdt.contains(con)){
                ContactsToDeactivate.add(con);
            }
        }
        
        if(ContactsToDeactivate.size()>0){
            for (User usr: [SELECT Id,isActive,contactId FROM User WHERE contactId IN:ContactsToDeactivate
                            and profile.name=:AP_Constant.esourcingVendorProfile]){
                                usr.isActive=false;
                                lstUserToDeactivate.add(usr);
            }
            
            if(lstUserToDeactivate.size()>0)
                update lstUserToDeactivate;
        }
    }
    
    @future 
    public static void openAccessToBidder(List<Id> lstBidId){ 
    system.debug('## openAccessToBidder ##');
        set<id> existingUsers = new set<id>();
        set<id> userToActivate = new set<id>();
        set<id> setContactId = new set<id>();
        map<id,user> mapConIdUser = new map<id,User>();
        map<id,contact>mapConIdContact = new map<id,contact>();
        list<user>lstNewUser = new list<User>();
        list<user>lstActivateExistingUser = new list<User>();

        for(Bidder__c bid: [SELECT Id, Bidder_Status__c, Contact_Bidder__c, Sourcing_Event__r.Sourcing_Status__c, Sourcing_Event__r.NDA_Mandatory__c FROM Bidder__c WHERE Id IN :lstBidId]){
            
            system.debug('## bid.Bidder_Status__c '+bid.Bidder_Status__c);
            system.debug('## bid.Sourcing_Event__r.NDA_Mandatory__c '+bid.Sourcing_Event__r.NDA_Mandatory__c);
            system.debug('## bid.Sourcing_Event__r.Sourcing_Status__c '+bid.Sourcing_Event__r.Sourcing_Status__c);
            if((bid.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_NDASIGNED && bid.Sourcing_Event__r.NDA_Mandatory__c) 
            || (bid.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_CONFIRMED && !bid.Sourcing_Event__r.NDA_Mandatory__c) 
            || (bid.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS && bid.Sourcing_Event__r.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED)){
                setContactId.add(bid.Contact_Bidder__c);
            }
        }
        if(setContactId.size() > 0){
            //Query active community users for each contact
            for (User user: [SELECT Id,isActive,contactId FROM User WHERE contactId IN:setContactId
                            and profile.name=:AP_Constant.esourcingVendorProfile]){
                if(user.isactive){
                    existingUsers.add(user.contactId);
                }
                else{
                    userToActivate.add(user.contactId);  
                    mapConIdUser.put(user.contactId,user);
                }          
            }
            system.debug('## existingUsers '+existingUsers);
            system.debug('## userToActivate '+userToActivate);
            system.debug('## setContactId '+setContactId);

            //build map contactid => contact
            for(Contact con:[select id, firstname,lastname,email, cTin_PreferredLanguage__c from Contact where id IN:setContactId]){
                mapConIdContact.put(con.Id,con);
            }

            // ARA  13-12-21    Use the esourcing Vendor Profile instead of the Customer Community Plus User
            //Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community Plus User' Limit 1];
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name=:AP_Constant.esourcingVendorProfile Limit 1];
            
            for(id cId: setContactId){
                if(!existingUsers.contains(cId)){
                    String language = 'en_US';
                    string FirstName = ''; 
                    string FirstName2 = '';

                    if(mapConIdContact.get(cId).FirstName != null && mapConIdContact.get(cId).FirstName != ''){
                        FirstName = mapConIdContact.get(cId).FirstName.substring(0,1);
                        FirstName2 = mapConIdContact.get(cId).FirstName.substring(0,2);
                    }

                    switch on mapConIdContact.get(cId).cTin_PreferredLanguage__c {
                        when 'French' {
                            language = 'fr';
                        }
                        when 'German' {
                            language = 'de';
                        }
                        when else {
                            language = 'en_US';
                        }
                    }

                    string usrAlias = FirstName + mapConIdContact.get(cId).LastName;
                    if(usrAlias.length()>8)
                        usrAlias=usrAlias.substring(0,8);
                    //create and activate community user
                    User usr = new User(
                        UserName = /*System.now().getTime() + */mapConIdContact.get(cId).email,
                        FirstName = mapConIdContact.get(cId).FirstName,
                        LastName = mapConIdContact.get(cId).LastName,
                        Alias = usrAlias,
                        email =mapConIdContact.get(cId).email,
                        ContactId = cId,
                        ProfileId = portalProfile.Id,
                        EmailEncodingKey = 'UTF-8',
                        CommunityNickname = FirstName2+mapConIdContact.get(cId).LastName + string.valueOf(Integer.valueof((Math.random() * 10))),
                        TimeZoneSidKey = 'Europe/Paris',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = language
                    );
                    lstNewUser.add(usr);
                }
            }

            system.debug('## lstNewUser '+lstNewUser);
            if(userToActivate.size()>0){
                for(id cId: userToActivate){
                    String language = 'en_US';
                    switch on mapConIdContact.get(cId).cTin_PreferredLanguage__c {
                        when 'French' {
                            language = 'fr';
                        }
                        when 'German' {
                            language = 'de';
                        }
                        when else {
                            language = 'en_US';
                        }
                    }
                    User usr = new User();
                    usr.Id = mapConIdUser.get(cId).Id;
                    usr.LanguageLocaleKey = language;
                    usr.isactive = true;
                    lstActivateExistingUser.add(usr);
                }
            }
            system.debug('## lstActivateExistingUser '+lstActivateExistingUser);
        
            if(lstNewUser.size()>0){
                try{
                    insert lstNewUser;
                    // mapResult.put('success','Access to portal successfully activated.');
                    //send welcome / pwd reset email
                }
                catch(Exception e){
                    // mapResult.put('Error',e.getMessage());
                }
            }
            
            if(lstActivateExistingUser.size()>0){
                try{
                    update lstActivateExistingUser;
                    //mapResult.put('success','Access to portal successfully activated.');
                    //send welcome / pwd reset email
                    for (User u : lstActivateExistingUser) {
                        System.resetPassword(u.Id,True);
                    }
                }
                catch(Exception e){
                    //mapResult.put('Error',e.getMessage());
                }
            }
        }
    } 
}