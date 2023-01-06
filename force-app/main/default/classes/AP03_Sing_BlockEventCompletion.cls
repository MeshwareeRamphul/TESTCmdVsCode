public class AP03_Sing_BlockEventCompletion{

    /**
    * ----------------------------------------------------------------------------------------------
    * Check if no doc is uploaded on event when Documents_Uploaded__c updated to Yes
    * ----------------------------------------------------------------------------------------------
    * @param    mapNewEvent Map<Id,Sourcing_Event__c>    : map of Sourcing_Event from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void checkDocumentBeforePublish(Map<Id, Sourcing_Event__c> mapNewEvent){
        Map<Id, Set<String>> existingDocTypeByEventIdMap = getAllDocumentType(mapNewEvent.keySet());
        Set<String> setExistingDocument = new set<string>();
            
        for (Sourcing_Event__c event : mapNewEvent.values()) {
            if(existingDocTypeByEventIdMap.size() > 0)
                setExistingDocument = existingDocTypeByEventIdMap.get(event.Id);
            
            if (setExistingDocument.size() == 0 || (!setExistingDocument.contains('RFX Results') && !setExistingDocument.contains('RFX Requirements'))) {
                mapNewEvent.get(event.Id).addError(System.Label.AP03_Sing_ErrorRequiredDocOnPublish);
            }
        }
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * Check if no doc is uploaded on event when Documents_Uploaded__c updated to Yes
    * ----------------------------------------------------------------------------------------------
    * @param    mapNewEvent Map<Id,Sourcing_Event__c>    : map of Sourcing_Event from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void checkDocumentBeforeComplete(Map<Id, Sourcing_Event__c> mapNewEvent){
        Map<Id, Set<String>> existingDocTypeByEventIdMap = getAllDocumentType(mapNewEvent.keySet());
        Set<String> setExistingDocument = new set<string>();
            
        for (Sourcing_Event__c event : mapNewEvent.values()) {
            if(existingDocTypeByEventIdMap.size()>0)
                setExistingDocument = existingDocTypeByEventIdMap.get(event.Id);
            System.debug('************setExistingDocument '+setExistingDocument);
            if (!setExistingDocument.contains('RFX Results') || !setExistingDocument.contains('RFX Requirements') || (Schema.getGlobalDescribe().get('Sourcing_Event__c').getDescribe().getRecordTypeInfosById().get(event.recordTypeId).getName() == 'RFP' && event.CountAwardees__c == 0)) {
                mapNewEvent.get(event.Id).addError(System.Label.AP03_Sing_ErrorRequiredDocOnComplete);
            }
        }
    }
    
    /**
    * ----------------------------------------------------------------------------------------------
    * Check if no doc is uploaded on event when Documents_Uploaded__c updated to Yes
    * ----------------------------------------------------------------------------------------------
    * @param    mapUploadedDocCheck Map<Id,Sourcing_Event__c>    : map of Sourcing_Event from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void checkUploadedDocuments(Map<Id, Sourcing_Event__c> mapUploadedDocCheck) {   //16-NOV-2021 ARA
        Map<Id, Boolean> mapUploadeDoc = new Map<Id, Boolean>();
        for(ContentDocumentLink cdl : [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:mapUploadedDocCheck.keySet()]){
            mapUploadeDoc.put(cdl.LinkedEntityId, true);
        }

        for(Id IdSE : mapUploadedDocCheck.keySet()){
            if(!mapUploadeDoc.containsKey(IdSE)){
                mapUploadedDocCheck.get(IdSE).addError(Label.AP03_Sing_ErrorNoDocumentUploaded);
            }
        }
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * check if all participant have a NDA Signed / Confirmed status before moving to Publish status
    * ----------------------------------------------------------------------------------------------
    * @param    mapNewEvent Map<Id,Sourcing_Event__c>    : map of Sourcing_Event from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void checkNDA(Map<Id, Sourcing_Event__c> mapNewEvent) {   //16-NOV-2021 ARA
        List<Bidder__c> lstParticipant = [SELECT Id, Sourcing_Event__c, Bidder_Status__c FROM Bidder__c WHERE Sourcing_Event__c IN :mapNewEvent.keySet()];
        Map<Id, Boolean> mapNDASigned = new Map<Id, Boolean>();
        Map<Id, Boolean> mapConfirmed = new Map<Id, Boolean>();

        //23-DEC-2021 ARA
        if(lstParticipant.size() > 0){
            for(Bidder__c participant : lstParticipant){
                if(participant.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_NDASIGNED){
                    mapNDASigned.put(participant.Sourcing_Event__c, true);
                }
                if(participant.Bidder_Status__c == AP_Constant.PARTICIPANT_STATUS_CONFIRMED){
                    mapConfirmed.put(participant.Sourcing_Event__c, true);
                }
            }
        }

        for(Id eventId : mapNewEvent.keySet()){
            if(mapNewEvent.get(eventId).NDA_Mandatory__c && !mapNDASigned.containsKey(eventId)){
                mapNewEvent.get(lstParticipant[0].Sourcing_Event__c).addError(Label.AP03_Sing_ErrorParticipantSignedNDA);
            }
            /*if(!mapNewEvent.get(participant.Sourcing_Event__c).NDA_Mandatory__c && !mapConfirmed.containsKey(eventId)){
                mapNewEvent.get(lstParticipant[0].Sourcing_Event__c).addError(Label.AP03_Sing_ErrorParticipantConfirmed);
            }*/
        }
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * check if all document types are uploaded in the old status before moving to Completed status
    * ----------------------------------------------------------------------------------------------
    * @param    mapNewEvent Map<Id,Sourcing_Event__c>    : map of Sourcing_Event from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    // public static void checkRFXResult(Map<Id, Sourcing_Event__c> mapNewEvent) {

    //     // check if each SourcingEvent have justification documents
    //     Map<Id, Set<String>> existingDocTypeByEventIdMap = getAllDocumentType(mapNewEvent.keySet());
    //     Set<String> setExistingDocument =new set<string>();
    //    // List<DocumentPerObject__mdt> requiredDocList   = getRequiredDocumentsList(AP_Constant.SOURCING_EVENT_STATUS_COMPLETED);
    //    /* set<id> setEventsWithAwardee=new set<id>();
    //     for(bidder__c bidder:[ select id,Sourcing_Event__c from bidder__c 
    //                           where Sourcing_Event__c IN:mapNewEvent.keyset() 
    //                           and bidder_status__c='Awardee']){
    //         setEventsWithAwardee.add(bidder.Sourcing_Event__c);
    //     }*/
            
    //     for (Sourcing_Event__c event : mapNewEvent.values()) {
    //         if(existingDocTypeByEventIdMap.size()>0)
    //          setExistingDocument = existingDocTypeByEventIdMap.get(event.Id);
            
    //         if (/*isDocumentMissing(requiredDocList, setExistingDocument, event.Sourcing_Status__c)*/ 
    //            setExistingDocument.size()==0 || !setExistingDocument.contains('RFX Results') /*|| setEventsWithAwardee.size()==0
    //            || (setEventsWithAwardee.size()>0 && !setEventsWithAwardee.contains(event.Id))*/) {
    //             mapNewEvent.get(event.Id).addError(Label.AP03_Sing_ErrorRFXResultMissing);
    //         }
    //     }
        
        
    // }
    
    // public static void checkRFXReq(Map<Id, Sourcing_Event__c> mapNewEvent) {

    //     // check if each SourcingEvent have justification documents
    //     Map<Id, Set<String>> existingDocTypeByEventIdMap = getAllDocumentType(mapNewEvent.keySet());
    //     Set<String> setExistingDocument =new set<string>();
    //    // List<DocumentPerObject__mdt> requiredDocList   = getRequiredDocumentsList(AP_Constant.SOURCING_EVENT_STATUS_COMPLETED);
    //    /* set<id> setEventsWithAwardee=new set<id>();
    //     for(bidder__c bidder:[ select id,Sourcing_Event__c from bidder__c 
    //                           where Sourcing_Event__c IN:mapNewEvent.keyset() 
    //                           and bidder_status__c='Awardee']){
    //         setEventsWithAwardee.add(bidder.Sourcing_Event__c);
    //     }*/
            
    //     for (Sourcing_Event__c event : mapNewEvent.values()) {
    //         if(existingDocTypeByEventIdMap.size()>0)
    //          setExistingDocument = existingDocTypeByEventIdMap.get(event.Id);
            
    //         if (/*isDocumentMissing(requiredDocList, setExistingDocument, event.Sourcing_Status__c)*/ 
    //            setExistingDocument.size()==0 || !setExistingDocument.contains('RFX Requirements') /*|| setEventsWithAwardee.size()==0
    //            || (setEventsWithAwardee.size()>0 && !setEventsWithAwardee.contains(event.Id))*/) {
    //             mapNewEvent.get(event.Id).addError(Label.AP03_Sing_ErrorRFXReqMissing);
    //         }
    //     }
        
        
    // }

    /**
    * ----------------------------------------------------------------------------------------------
    * get all document type by stage
    * ----------------------------------------------------------------------------------------------
    * @param    statusSet Set<String>   : set of Sourcing_Event status
    * ----------------------------------------------------------------------------------------------
    */
    // public static List<DocumentPerObject__mdt> getRequiredDocumentsList(String status) {
    //     return [SELECT RequiredDocuments__c, StageName__c
    //             FROM DocumentPerObject__mdt
    //             WHERE Object_Name__c = 'Sourcing_Event__c'
    //             AND StageName__c = :status];
    // }

    /**
    * ----------------------------------------------------------------------------------------------
    * check if all required documents are uploaded in the current stage
    * ----------------------------------------------------------------------------------------------
    * @param    enventIdSet Set<Id>    : set of Sourcing_Event IDs
    * ----------------------------------------------------------------------------------------------
    */
    public static Map<Id, Set<String>> getAllDocumentType(Set<Id> enventIdSet) {
        // get existing all attachment type for the Event
        Map<Id, Set<String>> existingDocTypeByEventIdMap = new Map<Id, Set<String>>();
        if (enventIdSet != null) {
            for (ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId, ContentDocument.description
                                           FROM ContentDocumentLink
                                           WHERE LinkedEntityId IN :enventIdSet
                                           AND ContentDocument.description <> null]){
                if (existingDocTypeByEventIdMap.get(cdl.LinkedEntityId) == null) {
                    existingDocTypeByEventIdMap.put(cdl.LinkedEntityId, new Set<String>());
                }
                existingDocTypeByEventIdMap.get(cdl.LinkedEntityId).add(cdl.ContentDocument.description);
            }
        }
        return existingDocTypeByEventIdMap;
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * check if any document is missing on the Sourcing_Event
    * ----------------------------------------------------------------------------------------------
    * @param    lstRequiredDocuments List<RequiredDocuments__mdt> : list of required documents
    * @param    setExistingDocument    Set<String>   : set of existing documents
    * @param    stageName              String        : Sourcing_Event stage name
    * ----------------------------------------------------------------------------------------------
    */
    // public static Boolean isDocumentMissing(List<DocumentPerObject__mdt> lstRequiredDocuments, Set<String> setExistingDocument, String stageName) {
    //     Boolean isMissing                   = false;
    //     Set<String> requiredDocumentTypeSet = new Set<String>();

    //     for (DocumentPerObject__mdt rd : lstRequiredDocuments){
    //         if (rd.StageName__c.equals(stageName) && String.isNotBlank(rd.RequiredDocuments__c)) {
    //             for (string docName : rd.RequiredDocuments__c.split(';')){
    //                 requiredDocumentTypeSet.add(docName);
    //             }
    //             break;
    //         }
    //     }
    //     for (String requiredDoc : requiredDocumentTypeSet){
    //         if (setExistingDocument == null || !setExistingDocument.contains(requiredDoc)) {
    //             isMissing = true;
    //         }
    //     }
    //     return isMissing;
    // }
}