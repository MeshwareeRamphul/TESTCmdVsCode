/*----------------------------------------------------------------------
-- - Name          : SourcingEventTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Sourcing_Event__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
--                     1.0      Initial version
-- 29-SEP-2021  ARA    1.1      SP-02598 check justification document before changing the sourcing event status to completed
-- 11-OCT-2021  MRA    1.2      Add business owner to sourcing team (on create of event / update of  BO)
-- 16-NOV-2021  ARA    1.3      Check participants status before changing the sourcing event status to published
-- 02-DEC-2021  ARA    1.4      Block update to yes (document uploaded) if no doc is uploaded on event
-- 06-DEC-2021  ARA    1.5      Block update to Published/Completed when required documents are not uploaded
-- 08-FEB-2022  ARA    1.6      SP-03243 Populate Tech_BeneficiaryEntities__c field
-- 21-APR-2022  AMA    1.7      Build sourcing pipeline status
-- 20-JUL-2022  ARA    1.8      SP-04133 Participant status when Cancelled Sourcing Event
-- 07-DEC-2022  MRA    1.9      R9 (SP-04774)- commented check on Documents_Uploaded__c = Yes since Rule is no longer valid
-------------------------------------------------------------------------*/
public without sharing class SourcingEventTriggerHandler {
    
    public static void BeforeInsertHandler(List<Sourcing_Event__c> lstNewSourcingEvent){
        Map<Id, Sourcing_Event__c> mapUploadedDocCheck= new Map<Id, Sourcing_Event__c>();

        for(Sourcing_Event__c newEvent: lstNewSourcingEvent){
            // 02-DEC-2021  ARA
            /* 07/12/2022 - MRA commented since rule is obsolete (R9) 
            if(newEvent.Documents_Uploaded__c == 'Yes'){
                newEvent.Documents_Uploaded__c.addError(Label.AP03_Sing_ErrorDocumentUploadedYes);
            }*/
            
            // 08-FEB-2022  ARA  SP-03243
            if(newEvent.Sing_Beneficiary_entities__c != null){
                newEvent.Tech_BeneficiaryEntities__c = newEvent.Sing_Beneficiary_entities__c;
            }
        }
    }
    
    public static void afterInsertHandler(List<Sourcing_Event__c> lstNewSourcingEvent){
        System.debug(' RecalculateSharing afterInsertHandler');
        list<Sourcing_Event__c>lstNewRFP=new list<Sourcing_Event__c>();
        map<string,string> mapRelatedRFIRFP=new map<string,string>();
        map<string,string> mapEventIdBO=new map<string,string>();
        map<string,string> mapEventIdOwner=new map<string,string>();
        set<id>eventPrivateToTeams=new set<id>();
        set<id>eventReadToAllBuyers=new set<id>();
        set<id>eventPrivateToEntity=new set<id>();
       // set<id>setEventId=new set<id>();
       Map<ID,String> IdSrcReqStatusMap = new Map<ID,String>();
       //AMA
       Set<ID> setSrcReq = new Set<ID>();
       //AMA
       map<id,List<Request_Vendor__c>> mapIdSrcReqLstVendor = new map<id,List<Request_Vendor__c>>();
       List<Sourcing_Event__c> lstSrcEvt = new List<Sourcing_Event__c>();
       List<Bidder__c> lstSrcEvtVendorIns = new List<Bidder__c>();

        for(Sourcing_Event__c event:lstNewSourcingEvent ){
            if(Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(event.recordTypeId).getName()=='RFP'
            && event.TECH_CreatedFromRFI__c && event.Related_RFI__c!=null)
             //lstNewRFP.add(event);
             mapRelatedRFIRFP.put(event.Related_RFI__c,event.id);
            
            //add business owner as sourcing team
            if(event.BusinessOwner__c<>null){
                mapEventIdBO.put(event.Id,event.BusinessOwner__c);
            }
            
            if(event.ownerId<>null){
                mapEventIdOwner.put(event.Id,event.ownerId);
            }
            
           if(event.SharingLogic__c=='Restrict access to my entity'){
                eventPrivateToEntity.add(event.Id);
            }
            
             if(event.SharingLogic__c!='Restrict access to my sourcing team' && event.SharingLogic__c!='Restrict access to my entity' && event.id!=null ){
                 //system.debug('## sharing with all buyers 1');
                eventReadToAllBuyers.add(event.Id);
            }
            
            if(event.SharingLogic__c =='Restrict access to my sourcing team'){
                eventPrivateToTeams.add(event.Id);
            }

            if(event.Sourcing_Request__c != null){
                IdSrcReqStatusMap.put(event.Sourcing_Request__c,'Sourcing/Negotiation');
                //AMA
                mapIdSrcReqLstVendor.put(event.Sourcing_Request__c,new List<Request_Vendor__c>());
                lstSrcEvt.add(event);
            }

            System.debug(' RecalculateSharing for');
            //AMA
            if (event.Sourcing_Request__c != null) {
              System.debug('## event.Sourcing_Request__c'+ event.Sourcing_Request__c );  
              System.debug(' RecalculateSharing if not null');
                setSrcReq.add(event.Sourcing_Request__c);
            }
       }
       system.debug(' mapIdSrcReqLstVendor'+mapIdSrcReqLstVendor);
       system.debug(' lstSrcEvt'+lstSrcEvt);
     
       // 21/04/2022 AMA: Build sourcing pipeline status
       if(PAD.canTrigger('AP70')){
            AP70_UpdateSrcReqStatus.UpdateSourcingReqest(IdSrcReqStatusMap, new Map<ID,Contract__c>());
       }
         
       if(eventPrivateToTeams.size()>0)
            AP05_Sing_mangageEventTeam.shareWithTeamOnly(eventPrivateToTeams/*,setEventId*/);
        
       if(mapRelatedRFIRFP.size()>0)
           AP04_Sing_ShortlistToRFP.addShortlisted(mapRelatedRFIRFP);
        
       if(mapEventIdBO.size()>0)
            AP05_Sing_mangageEventTeam.addBoToTeam(mapEventIdBO/*,setEventId*/);
        
        if(mapEventIdOwner.size()>0)
            AP05_Sing_mangageEventTeam.addOwnerToTeam(mapEventIdOwner/*,setEventId*/);
        
          //system.debug('## sharing with all buyers 1' + eventReadToAllBuyers);
       if(eventReadToAllBuyers.size()>0)
            AP05_Sing_mangageEventTeam.shareWithAllBuyers(eventReadToAllBuyers/*,setEventId*/);
        
       if(eventPrivateToEntity.size()>0)
           AP05_Sing_mangageEventTeam.shareWithEnityOnly(eventPrivateToEntity/*,setEventId*/);  
        System.debug(' RecalculateSharing end for');
        //AMA
        if (setSrcReq.size()>0) {
            System.debug(' RecalculateSharing before AfterUpdateSharing');
            List<Sourcing_Request__c> lstSrcReq = [select id,Business_Owner__c,Buyer_Lead__c,Data_Privacy_Expert__c,Financial_control__c,Legal_Counsel__c,Other_Proc__c,SBP__c,vendor_riskuser__c from Sourcing_Request__c where id in :setSrcReq];
            
            System.debug(' RecalculateSharing lstSrcReq '+lstSrcReq);
            AP73_ManageSrcReqSharing.AfterUpdateSharing(new map<ID,Sourcing_Request__c>(lstSrcReq));
        }

        //AMA
        List<Request_Vendor__c> lstReqVend = [select id,name,Sourcing_Request__c,Vendor__c,Contact__c from Request_Vendor__c where Sourcing_Request__c in :mapIdSrcReqLstVendor.keyset()];
        System.debug(' lstReqVend'+ lstReqVend);
        if (lstReqVend.size()>0) {
            for (Request_Vendor__c vendor : lstReqVend) {
                mapIdSrcReqLstVendor.get(vendor.Sourcing_Request__c).add(vendor);
            }
            System.debug(' mapIdSrcReqLstVendor'+ mapIdSrcReqLstVendor);
            for (Sourcing_Event__c srcevt : lstSrcEvt) {
                if (mapIdSrcReqLstVendor.get(srcevt.Sourcing_Request__c).size()>0) {
                    for (Request_Vendor__c vendor : mapIdSrcReqLstVendor.get(srcevt.Sourcing_Request__c)) {
                        lstSrcEvtVendorIns.add(new Bidder__c(Sourcing_Event__c=srcevt.id, Bidder_Status__c='Selected', Sing_Account__c=vendor.Vendor__c,Contact_Bidder__c=vendor.Contact__c));
                    }
                }
            }
            insert lstSrcEvtVendorIns;
        }
    }
    
    public static void BeforeUpdateHandler(map<Id,Sourcing_Event__c> mapOldSourcingEvent, map<Id,Sourcing_Event__c> mapNewSourcingEvent){
        Map<Id, Sourcing_Event__c> mapRFXReqCheck= new Map<Id, Sourcing_Event__c>();
        Map<Id, Sourcing_Event__c> mapRFXResulCheck= new Map<Id, Sourcing_Event__c>();
        Map<Id, Sourcing_Event__c> mapNDACheck= new Map<Id, Sourcing_Event__c>();
        Map<Id, Sourcing_Event__c> mapUploadedDocCheck= new Map<Id, Sourcing_Event__c>();
        Map<Id, Sourcing_Event__c> mapPublished = new Map<Id, Sourcing_Event__c>();
        Map<Id, Sourcing_Event__c> mapCompleted = new Map<Id, Sourcing_Event__c>();

        for(Sourcing_Event__c newEvent: mapNewSourcingEvent.values()){
            Sourcing_Event__c oldEvent = mapOldSourcingEvent.get(newEvent.Id);

            // 08-FEB-2022  ARA  SP-03243
            if(oldEvent.Sing_Beneficiary_entities__c != newEvent.Sing_Beneficiary_entities__c){
                newEvent.Tech_BeneficiaryEntities__c = newEvent.Sing_Beneficiary_entities__c;
            }

            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED){
                mapPublished.put(newEvent.Id, newEvent);
                mapNDACheck.put(newEvent.Id, newEvent);
            }
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED){
                mapCompleted.put(newEvent.Id, newEvent);
            }
            
            /*if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED
              && Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(newEvent.recordTypeId).getName()=='RFI'){
                mapRFXResulCheck.put(newEvent.Id, newEvent);
            }*/
            
            /*if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED
              && Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(newEvent.recordTypeId).getName()=='RFP'){
                mapRFXReqCheck.put(newEvent.Id, newEvent);
            }*/

            /*if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED){
                if(Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(newEvent.recordTypeId).getName()=='RFP'){
                    mapRFXReqCheck.put(newEvent.Id, newEvent);
                }
                mapNDACheck.put(newEvent.Id, newEvent);
            }*/

            /* 07/12/2022 - MRA commented since rule is obsolete (R9) 
            if(oldEvent.Documents_Uploaded__c != newEvent.Documents_Uploaded__c && newEvent.Documents_Uploaded__c == 'Yes'){
                mapUploadedDocCheck.put(newEvent.Id, newEvent);
            }*/
        }

        if(mapPublished.size()>0){
            AP03_Sing_BlockEventCompletion.checkDocumentBeforePublish(mapPublished);
        }

        if(mapCompleted.size()>0){
            AP03_Sing_BlockEventCompletion.checkDocumentBeforeComplete(mapCompleted);
        }

        /*if(mapRFXResulCheck.size()>0){
            AP03_Sing_BlockEventCompletion.checkRFXResult(mapRFXResulCheck);
        }*/
        
        /*if(mapRFXReqCheck.size()>0){
            AP03_Sing_BlockEventCompletion.checkRFXReq(mapRFXReqCheck);
        }*/
        
        // 16-NOV-2021 ARA
        if(mapNDACheck.size()>0){
            AP03_Sing_BlockEventCompletion.checkNDA(mapNDACheck);
        }
        // 02-DEc-2021 ARA
       /* 07/12/2022 - MRA commented since rule is obsolete (R9) 
           if(mapUploadedDocCheck.size() > 0){
            AP03_Sing_BlockEventCompletion.checkUploadedDocuments(mapUploadedDocCheck);
            }*/
        
    }
    
    public static void afterUpdateHandler(map<Id,Sourcing_Event__c> mapOldSourcingEvent, map<Id,Sourcing_Event__c> mapNewSourcingEvent, List<Sourcing_Event__c> lstSourcingEvent){
        map<string,string> mapEventIdBO=new map<string,string>();
        map<string,string> mapEventIdOwner=new map<string,string>();
        set<id>setEventId=new set<id>();
        set<id>setRFIEventId=new set<id>();
        Set<Id> setEventIds = new Set<Id>();
        Set<Id> setCancelEventIds = new Set<Id>();
        
        set<id> eventPrivateToEntity=new set<id>();
        set<id> eventReadToAllBuyers=new set<id>();
        set<id> eventPrivateToTeams=new set<id>();
        list<bidder__c> lstUpdtBidder=new list<bidder__c>();

        List<Sourcing_Event__c> lstEventToSendEmailNotif_Published = new List<Sourcing_Event__c>();
        List<Sourcing_Event__c> lstEventToSendEmailNotif_Canceled = new List<Sourcing_Event__c>();
        List<Sourcing_Event__c> lstEventToSendEmailNotif_Pending = new List<Sourcing_Event__c>();
        List<Sourcing_Event__c> lstEventToSendEmailNotif_Completed = new List<Sourcing_Event__c>();
        List<Sourcing_Event__c> lstEventToSendEmailNotif_BidDueDate = new List<Sourcing_Event__c>();

        Map<ID,String> IdSrcReqStatusMap = new Map<ID,String>();
       
        for(Sourcing_Event__c newEvent:mapNewSourcingEvent.values()){
            Sourcing_Event__c oldEvent = mapOldSourcingEvent.get(newEvent.Id);
            if(oldEvent.BusinessOwner__c!=newEvent.BusinessOwner__c){
                mapEventIdBO.put(newEvent.Id,newEvent.BusinessOwner__c);
                //setEventId.add(newEvent.id);
            } 
            
            if(oldEvent.OwnerId!=newEvent.OwnerId){
                mapEventIdOwner.put(newEvent.Id,newEvent.OwnerId);
                //setEventId.add(newEvent.id);
            } 
            
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED
              && Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(newEvent.recordTypeId).getName()=='RFP'){
                setEventId.add(newEvent.Id);
            }
            
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED
              && Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(newEvent.recordTypeId).getName()=='RFI'){
                setRFIEventId.add(newEvent.Id);
            }
            if(oldEvent.SharingLogic__c != newEvent.SharingLogic__c && newEvent.SharingLogic__c=='Restrict access to my entity'){
                eventPrivateToEntity.add(newEvent.Id);
            }
            if(oldEvent.SharingLogic__c != newEvent.SharingLogic__c && newEvent.SharingLogic__c=='Restrict access to my sourcing team'){
                eventPrivateToTeams.add(newEvent.Id);
            }
            
            if(oldEvent.SharingLogic__c != newEvent.SharingLogic__c
               && newEvent.SharingLogic__c!='Restrict access to my sourcing team' 
              && newEvent.SharingLogic__c!='Restrict access to my entity'){
                 //system.debug('## sharing with all buyers 1');
                eventReadToAllBuyers.add(newEvent.Id);
            }
            //
            if((oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c) && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED
               &&  oldEvent.Sourcing_Status__c!=AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED){
                setEventIds.add(newEvent.Id);
                // GRA -- Add criteria for Sending email when status is published
                lstEventToSendEmailNotif_Published.add(newEvent);
            }

            // GRA -- send mail to participants when Sourcing event is Canceled
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_CANCELLED){
                lstEventToSendEmailNotif_Canceled.add(newEvent);
                setCancelEventIds.add(newEvent.Id);
            }
            // GRA -- send mail to participants when Sourcing event is in Pending Selection
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PENDING_SELECTION){
                lstEventToSendEmailNotif_Pending.add(newEvent);
            }

            // 04-FEB-2022  HSO - Send mail to awardee participant when sourcing event is completed
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED){
                lstEventToSendEmailNotif_Completed.add(newEvent);
            }

            // 28-APR-2022  AMA - SP-03786 #01: If related sourcing event status goes into in Progress status then the related sourcing request status goes into "Sourcing/Negotiation"
            if(oldEvent.Sourcing_Status__c != newEvent.Sourcing_Status__c && /*(*/newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS /*|| newEvent.Sourcing_Status__c == 'Cancelled')*/ && newEvent.Sourcing_Request__c != null){
                /*if (newEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS) {*/
                    IdSrcReqStatusMap.put(newEvent.Sourcing_Request__c, 'Sourcing/Negotiation');
                /*}*/
                // 03/08/2022 AMA - SP-03786 #14 : If we cancel a Sourcing Event created from a Request, the Request should be cancelled.
                /*else if (newEvent.Sourcing_Status__c == 'Cancelled') {
                    IdSrcReqStatusMap.put(newEvent.Sourcing_Request__c, 'Cancelled');
                }*/
            }
            
            // 04/02/2022 MRA -- send mail to participants 24 hrs before bid due date is reached 
            if(oldEvent.TECH_Notify24hrsBeforeDueDate__c != newEvent.TECH_Notify24hrsBeforeDueDate__c && newEvent.TECH_Notify24hrsBeforeDueDate__c == true
              && newEvent.TECH_LT3DaysLeft__c==true){
               lstEventToSendEmailNotif_BidDueDate.add(newEvent);
            }
        }

        if(PAD.canTrigger('AP70')){
            AP70_UpdateSrcReqStatus.UpdateSourcingReqest(IdSrcReqStatusMap, new Map<ID,Contract__c>());
       }
        
        if(eventPrivateToEntity.size()>0)
            AP05_Sing_mangageEventTeam.shareWithEnityOnly(eventPrivateToEntity/*,setEventId*/);  
        
        if(eventPrivateToTeams.size()>0)
            AP05_Sing_mangageEventTeam.shareWithTeamOnly(eventPrivateToTeams/*,setEventId*/);        
     
        if(mapEventIdBO.size()>0)
            AP05_Sing_mangageEventTeam.addBoToTeam(mapEventIdBO/*,setEventId*/);
        
        if(mapEventIdOwner.size()>0)
           AP05_Sing_mangageEventTeam.addOwnerToTeam(mapEventIdOwner/*,setEventId*/);
        
         if(eventReadToAllBuyers.size()>0)
           AP05_Sing_mangageEventTeam.shareWithAllBuyers(eventReadToAllBuyers/*,setEventId*/);
        
        if(setEventId.size()>0){
            set<string>setAwardees=new set<string>(); // key contact + account
           
            for (bidder__c awardee: [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c from bidder__c where Sourcing_Event__c IN:setEventId and Bidder_Status__c='Awardee']){
                setAwardees.add(awardee.Contact_Bidder__c+ '' + awardee.Sing_Account__c);
            }
            if(setAwardees.size()>0){
                for (bidder__c bidderInProgress: [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c from bidder__c where Sourcing_Event__c IN:setEventId and Bidder_Status__c='Participation in Progress']){
                    if(!setAwardees.contains(bidderInProgress.Contact_Bidder__c+ '' + bidderInProgress.Sing_Account__c)){
                        bidderInProgress.Bidder_Status__c='Lost';
                        lstUpdtBidder.add(bidderInProgress);
                    }
                }
            }
        }
           
        if(setRFIEventId.size()>0){
            set<string>setshortlisted=new set<string>(); // key contact + account
            //list<bidder__c> lstUpdtBidder=new list<bidder__c>();
            for (bidder__c shortlisted: [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c from bidder__c where Sourcing_Event__c IN:setEventId and Bidder_Status__c='Short-listed']){
                setshortlisted.add(shortlisted.Contact_Bidder__c+ '' + shortlisted.Sing_Account__c);
            }
            if(setshortlisted.size()>0){
                for (bidder__c bidderInProgress: [select id,Contact_Bidder__c,Sing_Account__c,Bidder_Status__c from bidder__c where Sourcing_Event__c IN:setEventId and Bidder_Status__c='Participation in Progress']){
                    if(!setshortlisted.contains(bidderInProgress.Contact_Bidder__c+ '' + bidderInProgress.Sing_Account__c)){
                        bidderInProgress.Bidder_Status__c='Lost';
                        lstUpdtBidder.add(bidderInProgress);
                    }
                }
            }          
        }

        if (lstUpdtBidder.size()>0)
            update lstUpdtBidder;
        
        if(setEventIds.size() > 0){
            AP05_Sing_mangageEventTeam.shareWithPortalUsers(setEventIds);
        }
        // GRA -- call AP61_SendEmail_ESourcing
        if(lstEventToSendEmailNotif_Published.size() > 0){
            AP61_SendEmail_ESourcing.sendTo_ConfirmedParticipant(lstEventToSendEmailNotif_Published);
        }

        if(lstEventToSendEmailNotif_Canceled.size() > 0){
            AP61_SendEmail_ESourcing.sendTo_ShortlistedOrInProgress_Participant(lstEventToSendEmailNotif_Canceled);
        } 

        if(lstEventToSendEmailNotif_Pending.size() > 0){
            AP61_SendEmail_ESourcing.sendWhen_PendingStatus(lstEventToSendEmailNotif_Pending);
        }

        // 04-FEB-2022  HSO - Send mail to awardee participant when sourcing event is completed
        if(lstEventToSendEmailNotif_Completed.size() > 0){
            AP61_SendEmail_ESourcing.sendWhen_EventCompleted(lstEventToSendEmailNotif_Completed);
        }
        
         // 04/02/2022  MRA - Send mail to participant 24hr before biddue date is reached.
        if(lstEventToSendEmailNotif_BidDueDate.size() > 0){
            AP61_SendEmail_ESourcing.NotifyBidDueDateReached(lstEventToSendEmailNotif_BidDueDate);
        }
        
        // 20/07/2022   ARA - Set Participant status to LOST when sourcing event is cancelled
        if(setCancelEventIds.size() > 0){
            AP06_Sing_BlockNewParticipant.eliminateParticipants(setCancelEventIds);
        }
    }
}