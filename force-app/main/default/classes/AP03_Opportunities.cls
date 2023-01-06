public with sharing class AP03_Opportunities {
    /*----------------------------------------------------------------------
        -- - Name          : AP03_Opportunities
        -- - Author        : Eric Wartelle
        -- - Description   :
        --
        -- - History:
        -- Date         Name  Version  Remarks
        -- -----------  ----  -------  ---------------------------------------
        --              Eric   1.0      Initial version
        -- 10-09-2020   USA    1.1      SP-00321
    -------------------------------------------------------------------------*/
    // Available stages of the opportunities
    public static List<OpportunityStage> mOptyStagesList { get; set; }

    static { 
        mOptyStagesList = new List<OpportunityStage>([SELECT Id, IsActive, IsClosed, MasterLabel, SortOrder, IsWon, DefaultProbability
                                                      FROM OpportunityStage
                                                      WHERE IsActive=true
                                                      ORDER BY SortOrder ASC]);
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * Change opty user to be notified and last open stage
    * ----------------------------------------------------------------------------------------------
    * @param    pOptiesRetrieved Map<Id,Opportunity>    : map of opportunities from Trigger.Newmap
    * @param    pOldOpties       Map<Id,Opportunity>    : map of opportunities from Trigger.Oldmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void changeLastStage(Map<Id, Opportunity> pOptiesRetrieved, Map<Id, Opportunity> pOldOpties) {
        // Assign the OO as owner and the account manager as user to notify
        for (Opportunity vOpty : pOptiesRetrieved.values()) {
            vOpty.Lost_In_Stage__c = pOldOpties.get(vOpty.Id).StageName;
            if (pOptiesRetrieved.get(vOpty.Id).StageName != AP_CONSTANT.STAGE_LOST && pOptiesRetrieved.get(vOpty.Id).StageName != AP_CONSTANT.STAGE_CANCEL) {
                vOpty.Last_Open_Stage__c = pOptiesRetrieved.get(vOpty.Id).StageName;
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Util : get OpportunityStage object by his name
    * ----------------------------------------------------------------------------------------------
    * @param    pStageName String    : name of opportunity stage
    * ----------------------------------------------------------------------------------------------
    */
    private static OpportunityStage getStageByName(String pStageName) {
        if (pStageName != null && mOptyStagesList != null) {
            for (OpportunityStage vOptyStage : mOptyStagesList) {
                if (pStageName.equals(vOptyStage.MasterLabel)) {
                    return vOptyStage;
                }
            }
        }
        return null;
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * check if all document types are uploaded in the old status before moving to the next stage
    * ----------------------------------------------------------------------------------------------
    * @param    pOpportunityMapOld Map<Id,Opportunity>    : map of opportunities from Trigger.Oldmap
    * @param    pOpportunityMapNew Map<Id,Opportunity>    : map of opportunities from Trigger.Newmap
    * ----------------------------------------------------------------------------------------------
    */
    public static void checkAllDocumentRequired(Map<Id, Opportunity> pOpportunityMapOld, Map<Id, Opportunity> pOpportunityMapNew) {
        //String rtOpptyLgtContractId = OpportunityHandler.idRecOppSingleEdit;

        // get oppty with status changed
        Map<Id, Opportunity> oppChangedMap = new Map<Id, Opportunity>();
        Set<String> statusChangedSet       = new Set<String>();
        for (Opportunity opp : pOpportunityMapNew.values()) {
            // If status changes, check required documents for old stage
            OpportunityStage vNewStage = getStageByName(opp.StageName);// + '');
            OpportunityStage vOldStage = getStageByName(pOpportunityMapOld.get(opp.Id).StageName + '');
            Integer vNewStageOrder     = Integer.valueOf(vNewStage.SortOrder);
            Integer vOldStageOrder     = Integer.valueOf(vOldStage.SortOrder);

            if (opp.StageName != pOpportunityMapOld.get(opp.Id).StageName && vNewStageOrder > vOldStageOrder) {
                statusChangedSet.add(opp.StageName);
                oppChangedMap.put(opp.Id, opp);
            }
        }
        System.debug('oppChangedMap.size()=' + oppChangedMap.size());
        // check if each changing oppty have all required documents
        if (!oppChangedMap.isEmpty()) {
            Map<Id, Set<String>> existingDocTypeByOppIdMap = getAllDocumentType(oppChangedMap.keySet());
            List<RequiredDocuments__mdt> requiredDocList   = getRequiredDocumentsList(statusChangedSet);
            for (Opportunity opp : oppChangedMap.values()) {
                Set<String> existingDocumentSet = existingDocTypeByOppIdMap.get(opp.Id);
                
                if (isDocumentMissing(requiredDocList, existingDocumentSet, opp.stageName, opp.AXA_GO_Entity__c)) {
                    pOpportunityMapNew.get(opp.Id).addError(Label.Attachment_MissingDocumentTrigger);
                }
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * check if all required documents are uploaded in the current stage
    * ----------------------------------------------------------------------------------------------
    * @param    oppIdSet Set<Id>    : set of opportunity IDs
    * ----------------------------------------------------------------------------------------------
    */
    public static Map<Id, Set<String>> getAllDocumentType(Set<Id> oppIdSet) {
        // get existing all attachment type for the opp
        Map<Id, Set<String>> existingDocTypeByOppIdMap = new Map<Id, Set<String>>();
        if (oppIdSet != null) {
            for (ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId, ContentDocument.description
                                           FROM ContentDocumentLink
                                           WHERE LinkedEntityId IN :oppIdSet
                                           AND ContentDocument.description <> null]){
                if (existingDocTypeByOppIdMap.get(cdl.LinkedEntityId) == null) {
                    existingDocTypeByOppIdMap.put(cdl.LinkedEntityId, new Set<String>());
                }
                existingDocTypeByOppIdMap.get(cdl.LinkedEntityId).add(cdl.ContentDocument.description);
            }
        }
        return existingDocTypeByOppIdMap;
    }
    

    /**
    * ----------------------------------------------------------------------------------------------
    * get all document type by stage
    * ----------------------------------------------------------------------------------------------
    * @param    statusSet Set<String>   : set of opportunity status
    * ----------------------------------------------------------------------------------------------
    */
    public static List<RequiredDocuments__mdt> getRequiredDocumentsList(Set<String> statusSet) {
        return [SELECT RequiredDocuments__c, Stage__c, AXA_GS_Entity__c
                FROM RequiredDocuments__mdt
                WHERE ObjectName__c = 'Opportunity'
                AND Stage__c IN :statusSet];
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * check if any document is missing on the opportunity
    * ----------------------------------------------------------------------------------------------
    * @param    mdtList List<RequiredDocuments__mdt> : list of required documents
    * @param    existingDocumentSet    Set<String>   : set of existing documents
    * @param    stageName              String        : opportunity stage name
    * @param    entityName             String        : opportunity entity name
    * ----------------------------------------------------------------------------------------------
    */
    public static Boolean isDocumentMissing(List<RequiredDocuments__mdt> mdtList, Set<String> existingDocumentSet, String stageName, String entityName) {
        Boolean isMissing                   = false;
        Set<String> requiredDocumentTypeSet = new Set<String>();

        for (RequiredDocuments__mdt rd : mdtList){
            if (rd.Stage__c.equals(stageName) && rd.AXA_GS_Entity__c.equals(entityName) && String.isNotBlank(rd.RequiredDocuments__c)) {
                for (string docName : rd.RequiredDocuments__c.split(';')){
                    requiredDocumentTypeSet.add(docName);
                }
                break;
            }
        }
        for (String requiredDoc : requiredDocumentTypeSet){
            if (existingDocumentSet == null || !existingDocumentSet.contains(requiredDoc)) {
                isMissing = true;
            }
        }
        return isMissing;
    }
}