public class AP02_sing_countJustificationDoc{
    /*----------------------------------------------------------------------
    -- - Name          : AP02_sing_countJustificationDoc
    -- - Author        : Spoon
    -- - Description   : updates CountJustificationDocument__c on sourcing event when doc is uploaded / deleted
    -- - History:
    
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 06-OCT-2021  MRA  1.0      Initial version 
    -- 16-JAN-2022  ARA  2.0      SP-03219  Send welcome email when NDA is added to the participant
    -- 27-JAN-2022  ARA  3.0      SP-03219  Share previously added documents to the new Participant
    -- 07-FEB-2022  ARA  4.0      SP-03378  add check in apex class so that same record is not updated twice.
    -- 07-MAR-2022  ARA  5.0      SP-03276  automatically associate the docs to the current round when event published
    -- 07-DEC-2022  MRA  6.0      R9 (SP-04774)- commented check on Documents_Uploaded__c = Yes since Rule is no longer valid
    -------------------------------------------------------------------------*/
        
        
    public static void updtCountJustification(Set<Id> setLinkedEntityId, boolean increment){
        system.debug('## starting updtCountJustification');
        List<Sourcing_Event__c> lstSE = new List<Sourcing_Event__c>();
        Map<Id, Integer> mapCountRFXResultsDoc  = new Map<Id, Integer>();

        if(increment){
            for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:setLinkedEntityId AND ContentDocument.Description = 'RFX Results']){
                if(mapCountRFXResultsDoc.containsKey(cdl.LinkedEntityId)){
                    Integer countRFX = mapCountRFXResultsDoc.get(cdl.LinkedEntityId) + 1;
                    mapCountRFXResultsDoc.put(cdl.LinkedEntityId, countRFX);
                }else{
                    mapCountRFXResultsDoc.put(cdl.LinkedEntityId, 1);
                }
            }
            for(Id seId: setLinkedEntityId){
                if(mapCountRFXResultsDoc.containsKey(seId)){
                    lstSE.add(new Sourcing_Event__c(Id = seId, CountJustificationDocument__c = mapCountRFXResultsDoc.get(seId)));
                }else{
                    lstSE.add(new Sourcing_Event__c(Id = seId, CountJustificationDocument__c = 0));
                }
            }
        }else{
            lstSE = [SELECT id, CountJustificationDocument__c FROM Sourcing_Event__c WHERE Id IN:setLinkedEntityId AND CountJustificationDocument__c > 0];
            for(Sourcing_Event__c se : lstSE){
                if(se.CountJustificationDocument__c > 0){
                    se.CountJustificationDocument__c = se.CountJustificationDocument__c - 1;
                }
            }
        }
        
        update lstSE;
    }

    public static boolean blockDocumentDeletion(List<Id> lstCD){
        Map<Id, Id> mapSE = new Map<Id, Id>();
        Set<id> SEWithRfxDeletion = new Set<Id>();
        Map<Id, Integer> mapCD = new Map<Id, Integer>();
        Map<Id, ContentVersion> mapCV = new Map<Id, ContentVersion>();
        //Map<Id, Sourcing_Event__c> mapSourcingEvent;
        String sObjectSE = 'Sourcing_Event__c';
        Schema.SObjectType sObjTypeSE = Schema.getGlobalDescribe().get(sObjectSE);
        for(ContentVersion cv: [SELECT Id, contentDocumentId, Title, ContentDocument.description, Sourcing_Event__r.Sourcing_Status__c, OwnerId
                                FROM ContentVersion 
                                WHERE contentDocumentId IN :lstCD]){
            mapCV.put(cv.contentDocumentId, cv);
        }

        for(ContentDocumentLink cdl : [SELECT Id,ContentDocument.description, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :lstCD]){
            if(String.valueOf(cdl.LinkedEntityId).StartsWith(sObjTypeSE.getDescribe().getKeyPrefix())){
                if(cdl.ContentDocument.description =='RFX Requirements'){
                    SEWithRfxDeletion.add(cdl.LinkedEntityId);
                }
                mapSE.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
        }
        if(mapSE.size()>0){
            //mapSourcingEvent = new Map<Id, Sourcing_Event__c>([SELECT Id , Documents_Uploaded__c FROM Sourcing_Event__c WHERE Id IN :mapSE.values()]);
            
            for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :mapSE.values()]){
                if(!mapCD.containsKey(cdl.LinkedEntityId)){
                    mapCD.put(cdl.LinkedEntityId, 1);
                }else{
                    Integer countDoc = mapCD.get(cdl.LinkedEntityId) + 1;
                    mapCD.put(cdl.LinkedEntityId, countDoc);
                }
            }
            for(Id docId : lstCD){
                //07-DEC-2022 MRA commented check on Documents_Uploaded__c - obsolete rule 
                system.debug('## number of doc for SE'+ mapCD.get(mapSE.get(docId))); 
                 system.debug('## is doc being deleted of type RFX Reqirement'+ SEWithRfxDeletion +' : ' + SEWithRfxDeletion.contains(mapSE.get(docId)));
                //if(mapSourcingEvent.get(mapSE.get(docId)).Documents_Uploaded__c == 'Yes' && mapCD.get(mapSE.get(docId)) <= 1){ mapSourcingEvent.get(docId).addError('Document cannot be deleted');}
                if(SEWithRfxDeletion.contains(mapSE.get(docId)) && mapCV.get(docId).Sourcing_Event__r.Sourcing_Status__c != AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS && mapCV.get(docId).Sourcing_Event__r.Sourcing_Status__c != AP_Constant.SOURCING_EVENT_STATUS_CANCELLED){
                    return true;
                }
            }
        }

        return false;
    }

    public static boolean blockUpdateCompletedRound(List<ContentVersion> lstCV){
        Set<Id> setRoundId = new Set<Id>();
        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];

        if (currentUser.profile.name == AP_Constant.esourcingVendorProfile){
            for(integer i=0; i<lstCV.size(); i++){
                if(lstCV[i].Negotiation_Round__c != null){
                    setRoundId.add(lstCV[i].Negotiation_Round__c);
                }
            }

            if(setRoundId.size() > 0){
                Datetime currentDate =  datetime.now();
                List<Negotiation_Round__c> lstRound = [SELECT Id, Sing_Round_Bid_Due_Date__c FROM Negotiation_Round__c WHERE Id IN :setRoundId AND Sing_Round_Bid_Due_Date__c <= :currentDate/* AND Round_Status__c = 'Completed'*/];
                
                if(lstRound.size() > 0){
                    return true;
                }
            }
        }
        return false;
    }

    public static void addToParticipantDocument(Map<Id, Id> mapCDId){
        List<ContentDocument> lstCD = new List<ContentDocument>();
        List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
        Map<Id, Id> mapSourcingEventId = new Map<Id, Id>();
        Map<Id, Id> mapParticipantId = new Map<Id, Id>();
        Map<Id, ContentDocument> mapCD = new Map<Id, ContentDocument>();
        Map<Id, Bidder__c> mapBidder= new Map<Id, Bidder__c>();
        String sObjectParticpant = 'Bidder__c';
        String sObjectSE = 'Sourcing_Event__c';
        Schema.SObjectType sObjTypeParticipant = Schema.getGlobalDescribe().get(sObjectParticpant);
        Schema.SObjectType sObjTypeSE = Schema.getGlobalDescribe().get(sObjectSE);

        for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :mapCDId.keySet()]){
            if(String.valueOf(cdl.LinkedEntityId).StartsWith(sObjTypeSE.getDescribe().getKeyPrefix())){
                // LinkedEntityId = SourcingEvent
                mapSourcingEventId.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }else if(String.valueOf(cdl.LinkedEntityId).StartsWith(sObjTypeParticipant.getDescribe().getKeyPrefix())){
                // LinkedEntityId = Participant (Bidder)
                mapParticipantId.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
        }

        for(Bidder__c bidder: [SELECT Id, Sourcing_Event__c, Negotiation_Round__c FROM Bidder__c WHERE Id IN :mapCDId.values()]){
            mapBidder.put(bidder.Id, bidder);
        }

        for(Id cdId : mapCDId.keySet()){
            if(!mapSourcingEventId.containsKey(cdId)){
                lstCD.add(new ContentDocument(Id = cdId, description = 'Participant Document'));

                lstCDL.add(new ContentDocumentLink(
                    LinkedEntityId = mapBidder.get(mapParticipantId.get(cdId)).Sourcing_Event__c,
                    ContentDocumentId = cdId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }

        if(lstCD.size() > 0){
            update lstCD;
            if(lstCDL.size() > 0){
                insert lstCDL;
            }

            mapCD = new Map<Id, ContentDocument>([SELECT Id,Title,FileType,ContentSize,Description,createdDate,OwnerId FROM ContentDocument WHERE id IN: lstCD]);
            
            // Update ContentVersion
            List<ContentVersion> lstCV = new List<ContentVersion>();
            for(ContentVersion cv : [SELECT Id, contentDocumentId, Negotiation_Round__c, Participant__c FROM ContentVersion WHERE contentDocumentId IN :lstCD]){
                lstCV.add(new ContentVersion(
                    Id = cv.Id, 
                    Sing_DocumentName__c = mapCD.get(cv.contentDocumentId).Title, 
                    Participant__c = mapParticipantId.get(cv.contentDocumentId),
                    Sourcing_Event__c = mapBidder.get(mapParticipantId.get(cv.contentDocumentId)).Sourcing_Event__c,
                    Negotiation_Round__c = mapBidder.get(mapParticipantId.get(cv.contentDocumentId)).Negotiation_Round__c,
                    Sharing_Logic__c = 'Specific Vendor'));
            }
            if(lstCV.size() > 0){
                update lstCV;
            }
        }
    }

    public static void updateParticipantStatus(List<Id> lstIdCV){
        List<Id> lstParticipantId = new List<Id>();
        List<Id> lstSEId = new List<Id>();
        List<Id> lstPartNDASignedId = new List<Id>();
        List<Bidder__c> lstParticipant = new List<Bidder__c>();
        Map<Id, Id> mapRound = new Map<Id, Id>();
        Map<Id, Id> mapSE = new Map<Id, Id>();

        if(lstIdCV.size() > 0){
            for(ContentVersion cv : [SELECT Id, contentDocumentId, Sourcing_Event__c, Negotiation_Round__c, Participant__c FROM ContentVersion WHERE Id IN :lstIdCV AND contentDocument.description = :AP_Constant.DOCUMENT_TYPE_NDA_SIGNED]){
                lstParticipantId.add(cv.Participant__c);
                lstSEId.add(cv.Sourcing_Event__c);
                mapSE.put(cv.Participant__c, cv.Sourcing_Event__c);
            }
            if(lstSEId.size() > 0){
                for(Negotiation_Round__c round : [SELECT Id, Sourcing_Event__c FROM Negotiation_Round__c WHERE Sourcing_Event__c IN :lstSEId AND Round_Status__c != :AP_Constant.ROUND_STATUS_COMPLETED AND Round_Status__c != :AP_Constant.ROUND_STATUS_CANCELLED]){
                    mapRound.put(round.Sourcing_Event__c, round.Id);
                }
            }

            if(lstParticipantId.size() > 0){
                for(Bidder__c participant : [SELECT Id, Bidder_Status__c, Sourcing_Event__c, Sourcing_Event__r.Sourcing_Status__c FROM Bidder__c 
                                            WHERE Id IN :lstParticipantId 
                                            AND (Sourcing_Event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS OR Sourcing_Event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED)]){
                    if(participant.Sourcing_Event__r.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS){
                        lstParticipant.add(new Bidder__c(Id = participant.Id, Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_NDASIGNED));
                    }else if(participant.Sourcing_Event__r.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED){
                        lstPartNDASignedId.add(participant.Id);
                        Bidder__c bid = new Bidder__c(Id = participant.Id, Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS);
                        if(mapSE.containsKey(participant.Id) && mapRound.containsKey(mapSE.get(participant.Id))){
                            bid.Negotiation_Round__c = mapRound.get(mapSE.get(participant.Id));
                        }
                        lstParticipant.add(bid);
                    }
                }

                // 16-01-2022   ARA     Send welcome email
                if(lstPartNDASignedId.size() > 0){
                    LC_Sing_ManagePortalAccess.openAccessToBidder(lstPartNDASignedId);
                }
                if(lstParticipant.size() > 0){
                    for(Bidder__c bid : lstParticipant){
                        System.debug('*************Bidder_Status__c '+ bid.Bidder_Status__c);
                    }
                    update lstParticipant;
                }
            }
        }
    }

    // 07-03-2022   ARA SP-03276
    public static void addDocumentsToRound(Map<Id, Id> mapRound0){
        List<ContentVersion> lstCV = new List<ContentVersion>();
        Map<Id, Id> mapSEId = new Map<Id, Id>();
        Set<Id> setIdCD = new Set<Id>();
        List<String> lstRFXDocType = new List<String>{AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS, AP_Constant.DOCUMENT_TYPE_RFX_RESULTS};

        for(ContentDocumentLink cdl : [SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :mapRound0.keySet() AND ContentDocument.Description NOT IN:lstRFXDocType]){
            setIdCD.add(cdl.ContentDocumentId);
        }
        for(ContentVersion cv : [SELECT Id, Sourcing_Event__c FROM ContentVersion WHERE Negotiation_Round__c = null AND contentDocumentId IN :setIdCD]){
            cv.Negotiation_Round__c = mapRound0.get(cv.Sourcing_Event__c);
            lstCV.add(cv);
        }

        if(lstCV.size() > 0){
            update lstCV;
        }
    }

    public static void addParticipantToRound(List<Bidder__c> lstBidder){
        List<Id> lstSEId = new List<Id>();
        Map<Id, Id> mapRound = new Map<Id, Id>();
        
        for(Bidder__c bid : lstBidder){
            lstSEId.add(bid.Sourcing_Event__c);
        }
        
        if(lstSEId.size() > 0){
            for(Negotiation_Round__c round : [SELECT Id, Sourcing_Event__c, Sourcing_Event__r.NDA_Mandatory__c, Sourcing_Event__r.Sourcing_Status__c FROM Negotiation_Round__c WHERE Round_Status__c != :AP_Constant.ROUND_STATUS_COMPLETED AND Round_Status__c != :AP_Constant.ROUND_STATUS_CANCELLED AND Sourcing_Event__c IN :lstSEId AND Sourcing_Event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED AND Sourcing_Event__r.NDA_Mandatory__c = false]){
                mapRound.put(round.Sourcing_Event__c, round.Id);
            }
            for(Bidder__c bid : lstBidder){
                if(mapRound.containsKey(bid.Sourcing_Event__c)){
                    bid.Negotiation_Round__c = mapRound.get(bid.Sourcing_Event__c);
                    if(!bid.Sourcing_Event__r.NDA_Mandatory__c){
                        bid.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS;
                    }
                }
            }
        }
    }
    
    // 27-JAN-2022  ARA SP-03219
    public static void shareDocumentsWithParticipant(List<Bidder__c> lstBidder){
        Map<Id, Id> mapSE = new Map<Id, Id>();
        Map<Id, Id> mapDoc = new Map<Id, Id>();
        Map<Id, Set<Id>> mapDocEntityId = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> mapExistingCDL = new Map<Id, Set<Id>>();
        Set<Id> setDocs;
        List<contentDocumentLink> lstCDLs = new List<contentDocumentLink>();

        for(bidder__c bid: lstBidder){
            mapSE.put(bid.Id, bid.Sourcing_Event__c);
        }
        system.debug('## mapSE '+mapSE);
        if(mapSE.size() > 0){
            for(ContentVersion cv : [SELECT Id, Sourcing_Event__c, ContentDocumentId, Sharing_Logic__c FROM ContentVersion WHERE Sharing_Logic__c = 'All Vendors' AND Sourcing_Event__c IN :mapSE.values() AND Participant__c NOT IN :mapSE.keySet()]){
                mapDoc.put(cv.ContentDocumentId, cv.Sourcing_Event__c);
            }
            system.debug('## mapDoc '+mapDoc);
            if(mapDoc.size() > 0){
                for(ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :mapDoc.keySet() AND LinkedEntityId IN :lstBidder]){
                    setDocs = mapExistingCDL.get(cdl.LinkedEntityId);
                    if(setDocs == null){
                        setDocs = new Set<Id>();
                    }
                    setDocs.add(cdl.ContentDocumentId);

                    mapExistingCDL.put(cdl.LinkedEntityId, setDocs);
                }

                system.debug('## mapExistingCDL '+mapExistingCDL);
                for(bidder__c bid: lstBidder){
                    for(Id docId: mapDoc.keySet()){
                        if(bid.Sourcing_Event__c == mapDoc.get(docId) && (!mapExistingCDL.containsKey(docId) || !(mapExistingCDL.get(docId)).contains(bid.Id))){
                            setDocs = mapDocEntityId.get(bid.Id);
                            // 07-FEB-2022  ARA  SP-03378
                            if(setDocs == null || !setDocs.contains(docId)){
                                lstCDLs.add(new contentDocumentLink(LinkedEntityId = bid.Id ,ContentDocumentId = docId, Visibility = 'AllUsers'));
                                if(setDocs == null){
                                    setDocs = new Set<Id>();
                                }
                            }

                            setDocs.add(docId);
                            mapDocEntityId.put(bid.Id, setDocs);
                        }
                    }
                }
                system.debug('## lstCDLs '+lstCDLs);
                if(lstCDLs.size() > 0){
                    insert lstCDLs;
                }
            }
        }
    }

    //  28-JAN-2022  ARA    SP-03043
    public static void blockInsertionEventCompleted(List<ContentVersion> lstCV){
        Set<Id> setBidId = new Set<Id>();
        Set<Id> setCDId = new Set<Id>();
        List<Id> lstBidId;
        List<Id> lstCDId;
        
        for(ContentVersion cv :lstcv){
            if(cv.Participant__c != null){
                setBidId.add(cv.Participant__c);
                setCDId.add(cv.ContentDocumentId);
            }
        }
        if(setBidId.size() > 0){
            lstBidId = new List<Id>(new Map<Id, Bidder__c>([SELECT Id FROM Bidder__c WHERE Id IN :setBidId AND Sourcing_Event__r.Sourcing_Status__c = :AP_Constant.SOURCING_EVENT_STATUS_COMPLETED]).keySet());
            lstCDId = new List<Id>(new Map<Id, ContentDocument>([SELECT Id, Description FROM ContentDocument WHERE id IN :setCDId AND description != :AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL]).keySet());

            for(ContentVersion cv : lstCV){
                if(lstBidId.contains(cv.Participant__c) && lstCDId.contains(cv.ContentDocumentId)){
                    cv.addError(System.Label.Sing_ErrorMessageAddDoc);
                }
            }
        }
    }
}