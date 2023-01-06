trigger FeedItemTrigger on feedItem (after insert) {
    Map<ID,ID> mapIdFeedItemIdParent = new map<ID,ID>();
    Map<ID,feedItem> mapIdParentFeedItem = new map<ID,feedItem>();
    String preFixSrcEvt = Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getKeyPrefix();
    List<Bidder__c> lstParticipant;
    Map<ID,List<Bidder__c>> mapIdSrcEvtLstParti = new map<ID,List<Bidder__c>>();
    List<feedItem> lstTchatterIns = new List<feedItem>();
    List<feedItem> lstFI = new List<feedItem>();

    if (Trigger.isAfter && Trigger.isInsert) {
        for (feedItem fi : Trigger.newMap.values()) {
            if (String.valueof(fi.parentid).startsWith(preFixSrcEvt)) {
                mapIdFeedItemIdParent.put(fi.Id,fi.parentid);
                mapIdParentFeedItem.put(fi.parentid,fi);
                lstFI.add(fi);
            }
        }
    }

    if (mapIdFeedItemIdParent != null && mapIdFeedItemIdParent.size()>0) {
        lstParticipant = [select id,Sourcing_Event__c,Bidder_Status__c,Contact_Bidder__r.Email,TECH_ParticipantName__c,Com_SourcingEventName__c,Participant_Name__c from Bidder__c where Sourcing_Event__c in :mapIdFeedItemIdParent.values() and Bidder_Status__c = 'Participation in Progress'];
    }

    if (lstParticipant != null && lstParticipant.size()>0) {
        for (Bidder__c participant : lstParticipant) {
            if (mapIdSrcEvtLstParti.containskey(participant.Sourcing_Event__c) == false) {
                mapIdSrcEvtLstParti.put(participant.Sourcing_Event__c, new List<Bidder__c>{participant});
            } else {
                mapIdSrcEvtLstParti.get(participant.Sourcing_Event__c).add(participant);
            }
        }
    }

    List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();

    
    //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { Email });   

    if (mapIdParentFeedItem != null && mapIdParentFeedItem.size()>0) {
        for (ID idSrcEvt : mapIdParentFeedItem.keyset()) {
            if (mapIdSrcEvtLstParti != null && mapIdSrcEvtLstParti.size()>0) {
                for (Bidder__c participant : mapIdSrcEvtLstParti.get(idSrcEvt)) {
                    feedItem cloneChatter = mapIdParentFeedItem.get(idSrcEvt).clone();
                    cloneChatter.parentid = participant.id;
                    cloneChatter.visibility='AllUsers';
                    lstTchatterIns.add(cloneChatter);

                    // Commented by ARA 22/12/2022 new rule SP-04475 - line 26 in excel
                    /*Messaging.SingleEmailMessage Email = new Messaging.SingleEmailMessage();
                    Email.setToAddresses(new String[] { participant.Contact_Bidder__r.Email });
                    String subject = 'AXA has sent you a message';
                    Email.setSubject(subject);
                    String bidderUrl = String.valueof(System.URL.getSalesforceBaseURL()).replace('Url:[delegate=','').replace(']','/'+participant.id);
                    String body = '<p>Dear ' + participant.TECH_ParticipantName__c +',</p><p>You have received a message on the '+ participant.Com_SourcingEventName__c +'. You can consult your messages here '+ bidderUrl +'.</p><p>Thank you</p>';
                    Email.setHtmlBody(Body);
                    Email.saveAsActivity = false; 

                    lstEmail.add(Email);*/
                }
            }
        }
    }

    //AMA
    //Messaging.SendEmailResult[] results;

    if (lstTchatterIns != null && lstTchatterIns.size()>0) {
        insert lstTchatterIns;
        //results = Messaging.sendEmail(lstEmail);
    }

    if(lstFI.size()>0){
        AP75_ManageNotificationSE_ctin.sendNotifNewChatter(lstFI);
    }
}