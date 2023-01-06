public without sharing class AP75_ManageNotificationSE_ctin{
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP75_ManageNotificationSE_ctin
    -- - Author        : Spoon Consulting 
    -- - Description   : Manage Sourcing Event Notification
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 01-DEC-2022  AMA    1.0     Initial version
    -- 22-DEC-2022  ARA    2.0     SP-00183 & SP-04621
    --------------------------------------------------------------------------------------*/

    public static void sendNotif(List<ContentVersion> lstCV,List<ContentDocument> lstCD,Boolean fromPortal){
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        List<String> lstEmailTemplate = new List<String>{'Ctin_SourcingEventOwnerUploadDoc_ENG','Ctin_SourcingEventOwnerUploadDoc_FR','Ctin_SourcingEventOwnerUploadDoc_GE','Ctin_Portal_New_document_uploaded_GE','Ctin_Portal_New_document_uploaded_FR','Ctin_Portal_New_document_uploaded_ENG'};
        Map<Id,ContentDocument> mapIdCD = new Map<Id,ContentDocument>();
        Map<Id,Set<Id>> mapIdSeSetCOnBid = new Map<Id,Set<Id>>();
        Map<Id,List<Bidder__c>> mapIdSELstBid = new Map<Id,List<Bidder__c>>();
        Map<Id,List<Sourcing_Event_Team__c>> mapIdSElstSEteam = new Map<Id,List<Sourcing_Event_Team__c>>();
        Map<Id,User> mapIdConUser = new Map<Id,User>();
        Map<Id,List<GroupMember>> mapGrpMember = new Map<Id,List<GroupMember>>();
        Map<Id,String> mapIdMailUser = new Map<Id,String>();
        Map<String,ID> mapNameIdGrp = new Map<String,ID>();
        Map<String,emailtemplate> mapLanguageTemplate = new Map<String,emailtemplate>();
        Map<String,emailtemplate> mapLanTempupload = new Map<String,emailtemplate>();
        Set<Id> setIdSE = new Set<Id>();
        Set<Id> setIdContact = new Set<Id>();
        Set<Id> setIdCV =(new Map<Id,ContentVersion>(lstCV)).keySet();
        Set<String> setGrpName = new Set<String>();
        Set<String> setUserId = new Set<String>();

        if(lstCD.size()>0){
            mapIdCD = new Map<Id,ContentDocument>(lstCD); 
        }

        if(lstCV.size()>0){
            for(Emailtemplate temp : [SELECT id ,HtmlValue,Subject,DeveloperName,Body FROM EmailTemplate WHERE DeveloperName IN :lstEmailTemplate]){
                if(temp.DeveloperName=='Ctin_SourcingEventOwnerUploadDoc_ENG') 
                    mapLanguageTemplate.put('EN',temp);
                if(temp.DeveloperName=='Ctin_SourcingEventOwnerUploadDoc_FR')  
                    mapLanguageTemplate.put('FR',temp);
                if(temp.DeveloperName=='Ctin_SourcingEventOwnerUploadDoc_GE')  
                    mapLanguageTemplate.put('GE',temp); 
                if(temp.DeveloperName=='Ctin_Portal_New_document_uploaded_ENG')  
                    mapLanTempupload.put('EN',temp);
                if(temp.DeveloperName=='Ctin_Portal_New_document_uploaded_FR')  
                    mapLanTempupload.put('FR',temp);
                if(temp.DeveloperName=='Ctin_Portal_New_document_uploaded_GE')  
                    mapLanTempupload.put('GE',temp);
            }

            lstCV = [SELECT Id,contentDocumentId,Sourcing_Event__c,Sourcing_Event__r.ownerid,Sourcing_Event__r.Sourcing_Status__c,ownerid,Sourcing_Event__r.Name,Sourcing_Event__r.Owner.Email,Participant__r.Bidder_Status__c,
                    Negotiation_Round__r.Name,Participant__c,Participant__r.TECH_ParticipantName__c,Participant__r.Contact_Bidder__c,Sharing_Logic__c,Participant__r.Contact_Bidder__r.cTin_RelatedUser__r.username,
                    Participant__r.Contact_Bidder__r.cTin_RelatedUser__r.LanguageLocaleKey,Sourcing_Event__r.owner.Name,owner.ContactId 
                    FROM ContentVersion 
                    WHERE id IN :setIdCV AND Sourcing_Event__r.Sourcing_Status__c = 'Published'];
            for(ContentVersion cv : lstCV){
                if(cv.Sourcing_Event__c!=null){
                    setIdSE.add(cv.Sourcing_Event__c);
                }
            }

            List<Sourcing_Event_Team__c> lstSEteam = [SELECT id,Sourcing_Event__c,Role__c,Team_Member__c,Team_Member__r.email,Member_Group__c FROM Sourcing_Event_Team__c WHERE Sourcing_Event__c =:setIdSE AND Role__c = '019'];
            System.debug('***lstSEteam '+lstSEteam);
            if(lstSEteam.size()>0){
                for(Sourcing_Event_Team__c team : lstSEteam){
                    if(!mapIdSElstSEteam.containsKey(team.Sourcing_Event__c)){
                        mapIdSElstSEteam.put(team.Sourcing_Event__c,new List<Sourcing_Event_Team__c>{team});
                    }else if(mapIdSElstSEteam.containsKey(team.Sourcing_Event__c)){
                        mapIdSElstSEteam.get(team.Sourcing_Event__c).add(team);
                    }

                    if(team.Member_Group__c!=null){
                        setGrpName.add(team.Member_Group__c);
                    }
                }

                if(setGrpName.size()>0){
                    for(Group grp : [SELECT Id,Name,Developername FROM Group WHERE Name IN :setGrpName]){
                        mapNameIdGrp.put(grp.Name,grp.id);
                    }
                    if(mapNameIdGrp.size()>0){
                        for(GroupMember grpMbr : [SELECT id,GroupId,UserOrGroupId FROM GroupMember WHERE GroupId IN :mapNameIdGrp.values()]){
                            if(!mapGrpMember.containsKey(grpMbr.GroupId)){
                                mapGrpMember.put(grpMbr.GroupId,new List<GroupMember>());
                            }
                            mapGrpMember.get(grpMbr.GroupId).add(grpMbr);
    
                            if(grpMbr.UserOrGroupId!=null){
                                setUserId.add(grpMbr.UserOrGroupId);
                            }
                        }
                    
                        if(setUserId.size()>0){
                            for(User user : [SELECT id,email FROM user WHERE id IN :setUserId]){
                                mapIdMailUser.put(user.id,user.Email);
                            }
                        }
                    }
                }
            }
            System.debug('***mapNameIdGrp '+mapNameIdGrp);

            if(setIdSE.size()>0){
                List<Bidder__c> lstBid = [SELECT id,Bidder_Status__c,Sourcing_Event__c,TECH_ParticipantName__c,Contact_Bidder__r.cTin_RelatedUser__r.username,Contact_Bidder__c,Contact_Bidder__r.cTin_RelatedUser__r.LanguageLocaleKey,Contact_Bidder__r.Email
                                          FROM Bidder__c WHERE Sourcing_Event__c =:setIdSE AND(Bidder_Status__c = 'Participation in Progress' OR Bidder_Status__c = 'Short-listed')];
                if(lstBid.size()>0){
                    for(Bidder__c bid : lstBid){
                        if(!mapIdSELstBid.containsKey(bid.Sourcing_Event__c)){
                            mapIdSELstBid.put(bid.Sourcing_Event__c,new List<Bidder__c>{bid});
                        }else if(mapIdSELstBid.containsKey(bid.Sourcing_Event__c)){
                            mapIdSELstBid.get(bid.Sourcing_Event__c).add(bid);
                        }

                        if(!mapIdSeSetCOnBid.containsKey(bid.Sourcing_Event__c)){
                            mapIdSeSetCOnBid.put(bid.Sourcing_Event__c,new Set<Id>{bid.Contact_Bidder__c});
                        }else if(mapIdSeSetCOnBid.containsKey(bid.Sourcing_Event__c)){
                            mapIdSeSetCOnBid.get(bid.Sourcing_Event__c).add(bid.Contact_Bidder__c);
                        }

                        if(bid.Contact_Bidder__c!=null){
                            setIdContact.add(bid.Contact_Bidder__c);
                        }
                    }

                    if(setIdContact.size()>0){
                        for(User user : [SELECT Id,username,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN :setIdContact]){
                            mapIdConUser.put(user.ContactId,user);
                        }
                    }
                }
            }
            
            for(ContentVersion cv : lstCV){
                if(cv.ownerid==cv.Sourcing_Event__r.ownerid && mapIdCD.containsKey(cv.contentDocumentId) && 
                    mapIdCD.get(cv.contentDocumentId).Description=='Other Document External'/* && cv.Sourcing_Event__r.Sourcing_Status__c=='Published'*/){
                    
                    if(cv.Sharing_Logic__c=='Specific Vendor' && cv.Participant__c!=null && cv.Participant__r.Contact_Bidder__c!=null &&
                      (cv.Participant__r.Bidder_Status__c=='Participation in Progress' || cv.Participant__r.Bidder_Status__c=='Short-listed')){
                        Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                        System.debug('***If Specific Vendor');
                        String body = '';
                        if(mapIdConUser.get(cv.Participant__r.Contact_Bidder__c).LanguageLocaleKey=='en_US'){
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('EN').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanguageTemplate.get('EN').HtmlValue);
                        }else if(mapIdConUser.get(cv.Participant__r.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('FR').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanguageTemplate.get('FR').HtmlValue);
                            body = body.replace('{SOURCING_EVENT_OWNER}',cv.Sourcing_Event__r.owner.Name);
                        }
                        else if(mapIdConUser.get(cv.Participant__r.Contact_Bidder__c).LanguageLocaleKey=='de'){
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('GE').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanguageTemplate.get('GE').HtmlValue);
                        }
                        
                        body = body.replace('{CONTACT_NAME}',cv.Participant__r.TECH_ParticipantName__c);
                        body = body.replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name);
                        body = body.replace('{vendor_participant_user_id}',mapIdConUser.get(cv.Participant__r.Contact_Bidder__c).username);

                        email.setHtmlBody(body);
                        email.setTargetObjectId(cv.Participant__r.Contact_Bidder__c);
                        email.setWhatId(cv.Participant__c);
                        //email.setToAddresses(new List<String>{bid.Contact_Bidder__r.Email});

                        List<String> cc = new List<String>{cv.Sourcing_Event__r.Owner.Email};
                        if(mapIdSElstSEteam.containsKey(cv.Sourcing_Event__c) && mapIdSElstSEteam.get(cv.Sourcing_Event__c).size()>0){
                            System.debug('***If 1');
                            for(Sourcing_Event_Team__c team : mapIdSElstSEteam.get(cv.Sourcing_Event__c)){
                                if(team.Team_Member__c!=null){
                                    System.debug('***if 2');
                                    cc.add(team.Team_Member__r.email);
                                }else if(team.Member_Group__c!=null && mapNameIdGrp.containsKey(team.Member_Group__c)
                                           && mapGrpMember.containsKey(mapNameIdGrp.get(team.Member_Group__c)) && mapGrpMember.get(mapNameIdGrp.get(team.Member_Group__c)).size()>0){
                                    System.debug('***else if 1');
                                    for(GroupMember grpMbr : mapGrpMember.get(mapNameIdGrp.get(team.Member_Group__c))){
                                        System.debug('***for 2');
                                        cc.add(mapIdMailUser.get(grpMbr.UserOrGroupId));
                                    }
                                }
                            }
                        }
                        System.debug('***cc '+cc);
                        email.setCcaddresses(cc);
                        lstEmails.add(email);
                    }
                    
                    else if(cv.Sharing_Logic__c=='All Vendors' && mapIdSELstBid.containsKey(cv.Sourcing_Event__c) && mapIdSELstBid.get(cv.Sourcing_Event__c).size()>0){
                        System.debug('***If All Vendors');

                        for(Bidder__c bid : mapIdSELstBid.get(cv.Sourcing_Event__c)){
                            Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                            System.debug('***For');
                            String body = '';
                            if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='en_US'){
                                email.setSubject(string.valueOf(mapLanguageTemplate.get('EN').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                                body = string.valueOf(mapLanguageTemplate.get('EN').HtmlValue);
                            }else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                                email.setSubject(string.valueOf(mapLanguageTemplate.get('FR').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                                body = string.valueOf(mapLanguageTemplate.get('FR').HtmlValue);
                                body = body.replace('{SOURCING_EVENT_OWNER}',cv.Sourcing_Event__r.owner.Name);
                            }
                            else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='de'){
                                email.setSubject(string.valueOf(mapLanguageTemplate.get('GE').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                                body = string.valueOf(mapLanguageTemplate.get('GE').HtmlValue);
                            }

                            
                            body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
                            body = body.replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name);
                            body = body.replace('{vendor_participant_user_id}',mapIdConUser.get(bid.Contact_Bidder__c).username);

                            email.setHtmlBody(body);
                            email.setTargetObjectId(bid.Contact_Bidder__c);
                            email.setWhatId(bid.id);
                            //email.setToAddresses(new List<String>{bid.Contact_Bidder__r.Email});

                            List<String> cc= new List<String>{cv.Sourcing_Event__r.Owner.Email};
                            if(mapIdSElstSEteam.containsKey(cv.Sourcing_Event__c) && mapIdSElstSEteam.get(cv.Sourcing_Event__c).size()>0){
                                for(Sourcing_Event_Team__c team : mapIdSElstSEteam.get(cv.Sourcing_Event__c)){
                                    if(team.Team_Member__c!=null){
                                        cc.add(team.Team_Member__r.email);
                                    }else if(team.Member_Group__c!=null && mapNameIdGrp.containsKey(team.Member_Group__c)){
                                        for(GroupMember grpMbr : mapGrpMember.get(mapNameIdGrp.get(team.Member_Group__c))){
                                            cc.add(mapIdMailUser.get(grpMbr.UserOrGroupId));
                                        }
                                    }
                                }
                            }
                            email.setCcaddresses(cc);
                            lstEmails.add(email);
                        }
                    }
                }
                
//////////////////////////////////////////
                if(mapIdSeSetCOnBid.containsKey(cv.sourcing_event__c) && mapIdSeSetCOnBid.get(cv.sourcing_event__c).size()>0 && mapIdSeSetCOnBid.get(cv.sourcing_event__c).contains(cv.owner.ContactId) && mapIdCD.containsKey(cv.contentDocumentId) && fromPortal==true){
                    System.debug('***participant upload');

                    Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                    System.debug('***mapIdSELstBid '+mapIdSELstBid.get(cv.Sourcing_Event__c));
                    for(Bidder__c bid : mapIdSELstBid.get(cv.Sourcing_Event__c)){
                        System.debug('***for');
                        String body = '';
                        System.debug('***LanguageLocaleKey'+mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey);
                        if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='en_US'){
                            System.debug('***if ENG');
                            email.setSubject(string.valueOf(mapLanTempupload.get('EN').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanTempupload.get('EN').HtmlValue);
                        }else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                            System.debug('***if FR');
                            email.setSubject(string.valueOf(mapLanTempupload.get('FR').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanTempupload.get('FR').HtmlValue);
                            body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
                        }
                        else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='de'){
                            System.debug('***if GE');
                            email.setSubject(string.valueOf(mapLanTempupload.get('GE').Subject).replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name));
                            body = string.valueOf(mapLanTempupload.get('GE').HtmlValue);
                            body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
                        }
                        
                        //body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
                        body = body.replace('{SOURCING_EVENT_NAME}',cv.Sourcing_Event__r.Name);
                        body = body.replace('{username}',mapIdConUser.get(bid.Contact_Bidder__c).username);

                        email.setHtmlBody(body);
                        email.setTargetObjectId(bid.Contact_Bidder__c);
                        email.setWhatId(bid.id);
                        //email.setCcaddresses(cc);
                        
                        lstEmails.add(email);
                    }
                }
            }

            System.debug('***lstEmails : '+lstEmails);
            if(lstEmails.size()>0 && !test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);
                System.debug('***results '+results);
            }
        }
    }

    // 22-DEC-2022  ARA  SP-04621
    public static void sendNotifNewChatter(List<feedItem> lstFI){
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        Set<String> setGrpName = new Set<String>();
        Set<String> setUserId = new Set<String>();
        Set<Id> setIdSE = new Set<Id>();
        Map<Id,List<Bidder__c>> mapBid = new Map<Id,List<Bidder__c>>();
        Map<Id,List<String>> mapCC = new Map<Id,List<String>>();
        Map<Id,List<Id>> mapUserSE = new Map<Id,List<Id>>();
        Map<Id,List<GroupMember>> mapGrpMember = new Map<Id,List<GroupMember>>();
        Map<Id,String> mapIdMailUser = new Map<Id,String>();
        Map<Id,List<Sourcing_Event_Team__c>> mapSE_Team = new Map<Id,List<Sourcing_Event_Team__c>>();
        Map<String,ID> mapNameIdGrp = new Map<String,ID>();
        Map<String,emailtemplate> mapLanguageTemplate = new Map<String,emailtemplate>();

        Id buyerProfileId = [SELECT Id FROM profile WHERE name = :Label.profile_cTin_Contract_Buyer].Id;
        for(FeedItem fi : lstFI){
            if(!mapUserSE.containskey(fi.InsertedById)){
                mapUserSE.put(fi.InsertedById,new List<Id>());
            }
            mapUserSE.get(fi.InsertedById).add(fi.parentid);
        }
        for(User user: [SELECT Id FROM User WHERE Id IN : mapUserSE.keySet() AND ProfileId = :buyerProfileId]){
            setIdSE.addAll(mapUserSE.get(user.Id));
        }

        if(setIdSE.size()>0){
            Map<Id,Sourcing_Event__c> mapSE = new Map<Id,Sourcing_Event__c>([SELECT Id,Name,OwnerId,Owner.Email,Owner.Name FROM Sourcing_Event__c WHERE Id IN :setIdSE AND Sourcing_Status__c!=:AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS  AND Sourcing_Status__c!=:AP_Constant.SOURCING_EVENT_STATUS_CANCELLED]);
            List<String> lstEmailTemplate = new List<String>{'sing_NewPostNotification_ENG','sing_NewPostNotification_FR','sing_NewPostNotification_GE'};
            system.debug('*** *** mapSE : '+mapSE);
            for(Emailtemplate temp : [SELECT id ,HtmlValue,Subject,DeveloperName,Body FROM EmailTemplate WHERE DeveloperName IN :lstEmailTemplate]){
                if(temp.DeveloperName.endsWith('_ENG'))
                    mapLanguageTemplate.put('EN',temp);
                if(temp.DeveloperName.endsWith('_FR'))
                    mapLanguageTemplate.put('FR',temp);
                if(temp.DeveloperName.endsWith('_GE'))
                    mapLanguageTemplate.put('GE',temp); 
            }

            if(mapSE.size()>0){
                for(Sourcing_Event_Team__c team :  [SELECT Id,Sourcing_Event__c,Team_Member__c,Team_Member__r.Email,Member_Group__c FROM Sourcing_Event_Team__c WHERE Sourcing_Event__c IN :mapSE.keySet() AND Role__c = '019']){
                    if(!mapSE_Team.containsKey(team.Sourcing_Event__c)){
                        mapSE_Team.put(team.Sourcing_Event__c,new List<Sourcing_Event_Team__c>());
                    }
                    mapSE_Team.get(team.Sourcing_Event__c).add(team);

                    if(!mapCC.containsKey(team.Sourcing_Event__c)){
                        mapCC.put(team.Sourcing_Event__c,new List<String>());
                    }

                    if(team.Team_Member__c!=null && !mapCC.get(team.Sourcing_Event__c).contains(team.Team_Member__r.Email)){
                        mapCC.get(team.Sourcing_Event__c).add(team.Team_Member__r.Email);
                    }else if(team.Member_Group__c!=null){
                        setGrpName.add(team.Member_Group__c);
                    }
                }
                if(setGrpName.size()>0){
                    for(Group grp : [SELECT id,name,developername FROM group WHERE name IN :setGrpName]){
                        if(!mapNameIdGrp.containsKey(grp.Name)){
                            mapNameIdGrp.put(grp.Name,grp.id);
                        }
                    }
                    if(mapNameIdGrp.size()>0){
                        for(GroupMember gm : [SELECT id,GroupId,UserOrGroupId FROM GroupMember WHERE GroupId IN :mapNameIdGrp.values()]){
                            if(!mapGrpMember.containsKey(gm.GroupId)){
                                mapGrpMember.put(gm.GroupId,new List<GroupMember>());
                            }
                            mapGrpMember.get(gm.GroupId).add(gm);

                            if(gm.UserOrGroupId!=null){
                                setUserId.add(gm.UserOrGroupId);
                            }
                        }
                        if(setUserId.size()>0){
                            for(User user : [SELECT Id,Email FROM User WHERE Id IN :setUserId]){
                                if(!mapIdMailUser.containsKey(user.id)){
                                    mapIdMailUser.put(user.id,user.Email);
                                }
                            }
                        }
                        for(Id IdSE : mapSE_Team.keySet()){
                            for(Sourcing_Event_Team__c team : mapSE_Team.get(IdSE)){
                                if(team.Member_Group__c!=null && mapNameIdGrp.containsKey(team.Member_Group__c) && mapGrpMember.containsKey(mapNameIdGrp.get(team.Member_Group__c)) && mapGrpMember.get(mapNameIdGrp.get(team.Member_Group__c)).size()>0){
                                    for(GroupMember grpMbr : mapGrpMember.get(mapNameIdGrp.get(team.Member_Group__c))){
                                        if(!mapCC.get(team.Sourcing_Event__c).contains(mapIdMailUser.get(grpMbr.UserOrGroupId))){
                                            mapCC.get(team.Sourcing_Event__c).add(mapIdMailUser.get(grpMbr.UserOrGroupId));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                List<Bidder__c> lstBid = [SELECT id,Bidder_Status__c,Sourcing_Event__c,TECH_ParticipantName__c,Contact_Bidder__c,Contact_Bidder__r.cTin_PreferredLanguage__c,Contact_Bidder__r.Email
                                        FROM Bidder__c WHERE Sourcing_Event__c =:mapSE.keySet() AND(Bidder_Status__c = 'Participation in Progress' OR Bidder_Status__c = 'Short-listed')];
                
                system.debug('*** *** lstBid : '+lstBid);
                if(lstBid.size()>0){
                    Map<Id,User>  mapUser = new Map<Id,User>();
                    Set<Id> setIdContact = new Set <Id>();
                    for(Bidder__c bid : lstBid){
                        setIdContact.add(bid.Contact_Bidder__c);
                    }
                    for(User user : [SELECT Id,username,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN :setIdContact]){
                        mapUser.put(user.ContactId,user);
                    }
                    for(Bidder__c bid : lstBid){
                        Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                        String body = '';
                        if(bid.Contact_Bidder__r.cTin_PreferredLanguage__c=='French' || mapUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('FR').Subject).replace('{SOURCING_EVENT_NAME}',mapSE.get(bid.Sourcing_Event__c).Name));
                            body = string.valueOf(mapLanguageTemplate.get('FR').HtmlValue);
                            body = body.replace('{SOURCING_EVENT_OWNER}',mapSE.get(bid.Sourcing_Event__c).Owner.Name);
                        }
                        else if(bid.Contact_Bidder__r.cTin_PreferredLanguage__c=='German' || mapUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='de'){
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('GE').Subject).replace('{SOURCING_EVENT_NAME}',mapSE.get(bid.Sourcing_Event__c).Name));
                            body = string.valueOf(mapLanguageTemplate.get('GE').HtmlValue);
                        }else{/*(bid.Contact_Bidder__r.cTin_PreferredLanguage__c=='English' || mapUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='en_US'){*/
                            email.setSubject(string.valueOf(mapLanguageTemplate.get('EN').Subject).replace('{SOURCING_EVENT_NAME}',mapSE.get(bid.Sourcing_Event__c).Name));
                            body = string.valueOf(mapLanguageTemplate.get('EN').HtmlValue);
                        }
                        
                        body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
                        body = body.replace('{SOURCING_EVENT_NAME}',mapSE.get(bid.Sourcing_Event__c).Name);
                        body = body.replace('{VENDOR_URL}',Label.L31_urlVendorPortal);
                        body = body.replace('{VENDOR_USER_NAME}',mapUser.get(bid.Contact_Bidder__c).username);

                        email.setHtmlBody(body);
                        email.setTargetObjectId(bid.Contact_Bidder__c);
                        email.setWhatId(bid.Id);
                        //email.setToAddresses(new List<String>{bid.Contact_Bidder__r.Email});

                        if(!mapCC.containsKey(bid.Sourcing_Event__c)){
                            mapCC.put(bid.Sourcing_Event__c,new List<String>());
                        }
                        if(!mapCC.get(bid.Sourcing_Event__c).contains(mapSE.get(bid.Sourcing_Event__c).Owner.Email)){
                            mapCC.get(bid.Sourcing_Event__c).add(mapSE.get(bid.Sourcing_Event__c).Owner.Email);
                        }

                        if(mapCC.containsKey(bid.Sourcing_Event__c)){
                            if(mapCC.get(bid.Sourcing_Event__c).contains(bid.Contact_Bidder__r.Email)){
                                for(Integer i = mapCC.get(bid.Sourcing_Event__c).size() - 1; i >= 0; i--){
                                    if(mapCC.get(bid.Sourcing_Event__c)[i].equals(bid.Contact_Bidder__r.Email)){
                                        mapCC.get(bid.Sourcing_Event__c).remove(i);
                                    }
                                }
                            }
                            if(mapCC.get(bid.Sourcing_Event__c).size()>0){
                                email.setCcaddresses(mapCC.get(bid.Sourcing_Event__c));
                            }
                        }
                        lstEmails.add(email);
                    }
                }
            }
            system.debug('*** *** lstEmails : '+lstEmails);
            if(lstEmails.size()>0 && !test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);
            }
        }
    }

    public static void sendNotifDecline(List<Bidder__c> lstBid){
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        List<String> lstEmailTemplate = new List<String>{'Ctin_Decline_participation_ENG','Ctin_Decline_participation_FR','Ctin_Decline_participation_GE'};
        Map<Id,User>  mapIdConUser = new Map<Id,User>();
        Map<String,emailtemplate> mapLanguageTemplate = new Map<String,emailtemplate>();
        Set<Id> setIdContact = new Set <Id>();

        for(Emailtemplate temp : [SELECT id ,HtmlValue,Subject,DeveloperName,Body FROM EmailTemplate WHERE DeveloperName IN :lstEmailTemplate]){
            if(temp.DeveloperName=='Ctin_Decline_participation_ENG') 
                mapLanguageTemplate.put('EN',temp);
            if(temp.DeveloperName=='Ctin_Decline_participation_FR')  
                mapLanguageTemplate.put('FR',temp);
            if(temp.DeveloperName=='Ctin_Decline_participation_GE')  
                mapLanguageTemplate.put('GE',temp); 
        }
        for(Bidder__c bid : lstBid){
            setIdContact.add(bid.Contact_Bidder__c);
        }
        for(User user : [SELECT Id,username,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN :setIdContact and isActive=true]){
            mapIdConUser.put(user.ContactId,user);
        }
        for(Bidder__c bid : lstBid){
            Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
            String body = '';
            if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='en_US'){
                email.setSubject(string.valueOf(mapLanguageTemplate.get('EN').Subject).replace('{SOURCING_EVENT_NAME}',bid.Sourcing_Event__r.Name));
                body = string.valueOf(mapLanguageTemplate.get('EN').HtmlValue);
            }else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='fr'){
                email.setSubject(string.valueOf(mapLanguageTemplate.get('FR').Subject).replace('{SOURCING_EVENT_NAME}',bid.Sourcing_Event__r.Name));
                body = string.valueOf(mapLanguageTemplate.get('FR').HtmlValue);
                body = body.replace('{SOURCING_EVENT_OWNER}',bid.Sourcing_Event__r.owner.Name);
            }
            else if(mapIdConUser.get(bid.Contact_Bidder__c).LanguageLocaleKey=='de'){
                email.setSubject(string.valueOf(mapLanguageTemplate.get('GE').Subject).replace('{SOURCING_EVENT_NAME}',bid.Sourcing_Event__r.Name));
                body = string.valueOf(mapLanguageTemplate.get('GE').HtmlValue);
            }
            
            body = body.replace('{CONTACT_NAME}',bid.TECH_ParticipantName__c);
            body = body.replace('{SOURCING_EVENT_NAME}',bid.Sourcing_Event__r.Name);
            body = body.replace('{username}',mapIdConUser.get(bid.Contact_Bidder__c).username);

            //email.setReplyTo('support@acme.com');
            email.setHtmlBody(body);
            email.setTargetObjectId(bid.Contact_Bidder__c);
            email.setWhatId(bid.id);
            lstEmails.add(email);
        }

        if(lstEmails.size()>0 && !test.isRunningTest()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);
        }
    }

    // 22-DEC-2022  ARA   SP-00183
    public static void sendNotifDocumentApprouved(Set<Id> setIdCtr){
        system.debug('**** *** sendNotifDocumentApprouved Begin');
        List<cTin_ContractTeam__c> lstCtrTeam = new List<cTin_ContractTeam__c>();
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        List<String> lstRole = new List<String>{'015','016'};// Role(Contract co-owner,Business Owner)
        List<String> lstEmailTemplate = new List<String>{'ctin_ContractDocumentApproved_ENG','ctin_ContractDocumentApproved_FR'};
        Map<Id,User> mapUser = new Map<Id,User>();
        Map<Id,List<String>> mapCC = new Map<Id,List<String>>();
        Map<Id,List<GroupMember>> mapGrpMember = new Map<Id,List<GroupMember>>();
        Map<String,Id> mapNameIdGrp = new Map<String,Id>();
        Map<String,emailtemplate> mapLanguageTemplate = new Map<String,emailtemplate>();
        Set<Id> setUserId = new Set<Id>();
        Set<String> setGrpName = new Set<String>();

        List<Contract__c> lstCtr = [SELECT Id,Name,OwnerId,Owner.Email,(SELECT Id,cTin_Contract__c,cTin_TeamMember__c,cTin_TeamMember__r.Email,cTin_GroupMember__c FROM Contract_Teams__r WHERE cTin_Role__c IN :lstRole) FROM Contract__c WHERE Id IN :setIdCtr];
        
        if(lstCtr.size()>0){
            for(Emailtemplate temp : [SELECT id ,HtmlValue,Subject,DeveloperName,Body FROM EmailTemplate WHERE DeveloperName IN :lstEmailTemplate]){
                if(temp.DeveloperName.endsWith('_ENG'))
                    mapLanguageTemplate.put('EN',temp);
                if(temp.DeveloperName.endsWith('_FR'))
                    mapLanguageTemplate.put('FR',temp);
                if(temp.DeveloperName.endsWith('_GE'))
                    mapLanguageTemplate.put('GE',temp); 
            }
            for(Contract__c ctr: lstCtr){
                if(ctr.Contract_Teams__r!=null && ctr.Contract_Teams__r.size()>0){
                    for(cTin_ContractTeam__c team: ctr.Contract_Teams__r){
                        if(team.cTin_Contract__c==ctr.Id){
                            lstCtrTeam.add(team);
                        }
                    }
                }
                setUserId.add(ctr.OwnerId);
            }
        }
        for(cTin_ContractTeam__c team : lstCtrTeam){
            if(!mapCC.containsKey(team.cTin_Contract__c)){
                mapCC.put(team.cTin_Contract__c,new List<String>());
            }
            if(team.cTin_TeamMember__c!=null && !mapCC.get(team.cTin_Contract__c).contains(team.cTin_TeamMember__r.Email)){
                mapCC.get(team.cTin_Contract__c).add(team.cTin_TeamMember__r.Email);
            }else if(team.cTin_GroupMember__c!=null){
                setGrpName.add(team.cTin_GroupMember__c);
            }
        }

        // for group member
        if(setGrpName.size()>0){
            for(Group grp : [SELECT Id,Name,Developername FROM Group WHERE Name IN :setGrpName]){
                if(!mapNameIdGrp.containsKey(grp.Name)){
                    mapNameIdGrp.put(grp.Name,grp.Id);
                }
            }
            if(mapNameIdGrp.size()>0){
                for(GroupMember gm : [SELECT id,GroupId,UserOrGroupId FROM GroupMember WHERE GroupId IN :mapNameIdGrp.values()]){
                    if(!mapGrpMember.containsKey(gm.GroupId)){
                        mapGrpMember.put(gm.GroupId,new List<GroupMember>());
                    }
                    mapGrpMember.get(gm.GroupId).add(gm);

                    if(gm.UserOrGroupId!=null){
                        setUserId.add(gm.UserOrGroupId);
                    }
                }
            }
        }
        if(setUserId.size()>0){
            for(User user : [SELECT Id,Email,Name,ContactId,LanguageLocaleKey FROM User WHERE Id IN :setUserId]){
                if(!mapUser.containsKey(user.Id)){
                    mapUser.put(user.Id,user);
                }
            }
        }
        if(setGrpName.size()>0){
            for(cTin_ContractTeam__c team : lstCtrTeam){
                if(team.cTin_GroupMember__c!=null && mapNameIdGrp.containsKey(team.cTin_GroupMember__c) && mapGrpMember.containsKey(mapNameIdGrp.get(team.cTin_GroupMember__c)) && mapGrpMember.get(mapNameIdGrp.get(team.cTin_GroupMember__c)).size()>0){
                    for(GroupMember grpMbr : mapGrpMember.get(mapNameIdGrp.get(team.cTin_GroupMember__c))){
                        if(!mapCC.get(team.cTin_Contract__c).contains(mapUser.get(grpMbr.UserOrGroupId).Email)){
                            mapCC.get(team.cTin_Contract__c).add(mapUser.get(grpMbr.UserOrGroupId).Email);
                        }
                    }
                }
            }
        }
        
        for(Contract__c ctr : lstCtr){
            Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
            String body = '';
            if(mapUser.get(ctr.OwnerId).LanguageLocaleKey=='fr'){
                email.setSubject(string.valueOf(mapLanguageTemplate.get('FR').Subject).replace('{CONTRACT_NAME}',ctr.Name));
                body = string.valueOf(mapLanguageTemplate.get('FR').HtmlValue);
            }else{/*mapUser.get(ctr.OwnerId).LanguageLocaleKey=='en_US'){*/
                email.setSubject(string.valueOf(mapLanguageTemplate.get('EN').Subject).replace('{CONTRACT_NAME}', ctr.Name));
                body = string.valueOf(mapLanguageTemplate.get('EN').HtmlValue);
            }
            
            body = body.replace('{CONTRACT_OWNER_NAME}',mapUser.get(ctr.OwnerId).Name);
            body = body.replace('{CONTRACT_NAME}',ctr.Name);
            body = body.replace('{CONTRACT_URL}',URL.getOrgDomainUrl().toExternalForm() + '/'+ ctr.Id);
            email.setHtmlBody(body);
            email.setWhatId(ctr.Id);
            email.setToAddresses(new List<String>{ctr.Owner.Email});
            if(mapCC.containsKey(ctr.Id)){
                if(mapCC.get(ctr.Id).contains(mapUser.get(ctr.OwnerId).Email)){
                    for(Integer i = mapCC.get(ctr.Id).size() - 1; i >= 0; i--){
                        if(mapCC.get(ctr.Id)[i].equals(mapUser.get(ctr.OwnerId).Email)){
                            mapCC.get(ctr.Id).remove(i);
                        }
                    }
                }
                if(mapCC.get(ctr.Id).size()>0){
                    email.setCcaddresses(mapCC.get(ctr.Id));
                }
            }
            lstEmails.add(email);
        }
        system.debug('**** *** lstEmails : '+lstEmails);
        if(lstEmails.size()>0 && !test.isRunningTest()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);
        }
        system.debug('**** *** sendNotifDocumentApprouved End');
    }
}