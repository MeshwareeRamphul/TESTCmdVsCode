public class ContentDocumentLinkTriggerHandler {

    public static void handleAfterInsert(List<ContentDocumentLink> lstcdl){
        map<Id,Id> mapcdLinkedEntity = new map<id,id>();
        //Map<Id, List<Id>> mapCD = new Map<Id, List<Id>>();
        Map<Id, Id> mapCD = new Map<Id, Id>();
          System.debug('***********AP31 '+PAD.canTrigger('AP31'));
        if ( PAD.canTrigger('AP31')) {
            AP31_ManageFiles.generatePublicURL(lstcdl);
        }
        
        if ( PAD.canTrigger('AP02_Sing')) { 
            String sObjectName = 'Bidder__c';
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName); 
            for(contentDocumentLink cdl :lstcdl){
                mapcdLinkedEntity.put(cdl.contentdocumentid,cdl.linkedEntityId);

                // LinkedEntityId => participant (Bidder)
                if(String.valueOf(cdl.LinkedEntityId).StartsWith(sObjType.getDescribe().getKeyPrefix())){
                    mapCD.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
        }
        
        if ( PAD.canTrigger('AP02_sing')) {
            /*if(mapcdLinkedEntity.size()>0){
                AP02_sing_countJustificationDoc.updtCountJustification(mapcdLinkedEntity);
            }*/
            if(mapCD.size() > 0){
                AP02_sing_countJustificationDoc.addToParticipantDocument(mapCD);
            }
        }
    }

    public static void handleAfterDelete(List<ContentDocumentLink> lstcdl){
        map<Id,Id>mapcdLinkedEntity=new map<id,id>();

        if ( PAD.canTrigger('AP31')) {
            AP31_ManageFiles.deleteContentDistribution(lstcdl);
        } 
    }
    
    public static void handleBeforeDelete(List<ContentDocumentLink> lstcdl){
        map<Id,Id>mapcdLinkedEntity=new map<id,id>();
          
        if ( PAD.canTrigger('AP02_Sing')) {   
            for(contentDocumentLink cdl :lstcdl){
                mapcdLinkedEntity.put(cdl.contentdocumentid,cdl.linkedEntityId); 
            }
        
        }
        
        /*if ( PAD.canTrigger('AP02_sing')) {
            if(mapcdLinkedEntity.size()>0)
                AP02_sing_countJustificationDoc.updtCountJustification(mapcdLinkedEntity);
        }*/
    }
}