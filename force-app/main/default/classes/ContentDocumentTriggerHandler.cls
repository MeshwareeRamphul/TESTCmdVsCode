public class ContentDocumentTriggerHandler {
/* 
--------------------------------------------------------------------------------------
-- - Name          : ContentDocumentTriggerHandler
-- - Author        : Spoon Consulting 
-- - Description   : 
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 01-APR-2020  SGO    1.0     Initial version
-- 11-JAN-2020  ARA    2.0     SP-01136
--------------------------------------------------------------------------------------*/
    public static void handleAfterInsert(List<ContentDocument> lstNewCD) {
        system.debug('Starting trigger ContentDocumentAfterInsert');
        String profile_Universign_name = 'Universign Profile';
        String suffix_signed = '_signed';
        set<id> contentDocumentIdSet=new set<id>();
        List<Profile>currentUserProfile=[select name,id
                                         from Profile 
                                         where id=:userinfo.getProfileId() limit 1];
        
        for (ContentDocument cd : lstNewCD) {
          
            //Check that running user is Universign Profile and document name ends with _signed
            if (PAD.canTrigger('AP22')) {
                if(currentUserProfile[0].name.equalsIgnoreCase(profile_Universign_name) 
                    && cd.Title.substring(cd.Title.length()-7,cd.Title.length()).equalsignorecase(suffix_signed)){
                    contentDocumentIdSet.add(cd.id);
                }
            }
        }
        if (PAD.canTrigger('AP22')) {
            if(contentDocumentIdSet.size()>0)   AP22_ContractSignedUrl.updateFinalUrl(contentDocumentIdSet);
            
        }
    }
    
    public static void handleBeforeInsert(List<ContentDocument> lstNewCD) {
        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];

        if (/*!currentUser.profile.name.StartsWith('cTin') &&*/ PAD.canTrigger('ByPassSpecialCharacter')){
            for (ContentDocument cd : lstNewCD) {
                if(cd.title.containsAny('<>:"/\\|?*')){
                    cd.addError('Title', Label.ErrorMessageForDocsName);break;
                }
            }
        }
    }

    public static void handleAfterUpdate(List<ContentDocument> lstOldCD, List<ContentDocument> lstNewCD) {
        set<id>contentDocSet=new set<id>(); 
        set<id>setAccId=new set<id>();
        Set<id> cdIdSet=new Set<id>();
        Set<id> setSEId=new Set<id>();
        String sObjectName = 'Sourcing_Event__c';
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName); 

        for (ContentDocument cd : lstNewCD) {
        system.debug ('##cd.description after update' + cd.description);
            //Check that running user is Universign Profile and document name ends with _signed
            if (PAD.canTrigger('AP22')) {
                if(cd.Description == 'RFX Results'){
                    cdIdSet.add(cd.Id);
                }
            }
            
            if (PAD.canTrigger('AP71')) { 
                contentDocSet.add(cd.Id);
            }
        }

        if(cdIdSet.size()>0){
            for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN:cdIdSet]){
                if((String.valueOf(cdl.LinkedEntityId)).StartsWith(sObjType.getDescribe().getKeyPrefix())){                    setSEId.add(cdl.LinkedEntityId);
                }
            }
            if(setSEId.size() > 0) AP02_sing_countJustificationDoc.updtCountJustification(setSEId, true);
        }
        
        //MRA 26/05/2022- count number of TOBA doc on Account
        if(contentDocSet.size()>0){
            for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId 
                                          FROM ContentDocumentLink 
                                          WHERE ContentDocumentId IN:contentDocSet]){
                if((String.valueOf(cdl.LinkedEntityId)).StartsWith( Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix())){
                    setAccId.add(cdl.LinkedEntityId);
                }
            }
            if(setAccId.size()>0)
            	AP71_AccValidateReqDoc.checkTOBAUploaded(setAccId,contentDocSet,'insert');
        }
    }

    public static void handleBeforeUpdate(List<ContentDocument> lstOldCD, List<ContentDocument> lstNewCD) {
        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];

        if (/*!currentUser.profile.name.StartsWith('cTin')*/ PAD.canTrigger('ByPassSpecialCharacter')){
            for (ContentDocument cd : lstNewCD) {
                if(cd.title.containsAny('<>:"/\\|?*')){
                    cd.addError('Title', Label.ErrorMessageForDocsName);
                    break;
                }
            }
        }

        // Block update for vendor profile
        if (currentUser.profile.name == AP_Constant.esourcingVendorProfile){
            List<Id> lstCDId = new List<Id>();
            for (Integer i=0; i<lstNewCD.size(); i++){
                if(lstOldCD[i].Title != lstNewCD[i].Title || lstOldCD[i].Description != lstNewCD[i].Description){
                    lstCDId.add(lstOldCD[i].Id);
                }
            }
            if(lstCDId.size() > 0){
                List<ContentVersion> lstCV = [SELECT Id, ContentDocumentId, Negotiation_Round__c, 
                                              Sharing_Logic__c, Participant__c, 
                                              Participant__r.Bidder_Status__c FROM ContentVersion WHERE ContentDocumentId IN :lstCDId];
                if(lstCV.size() > 0){
                    boolean isDeclined = false;
                    for(ContentVersion cv: lstCV){
                        if(cv.Participant__r.Bidder_Status__c == 'Declined'){
                            isDeclined = true; break;
                        }
                    }
                    if(isDeclined || AP02_sing_countJustificationDoc.blockUpdateCompletedRound(lstCV)){
                        lstNewCD[0].addError(System.Label.Sing_ErrorMessageUpdateDoc);
                    }
                }
            }
        }
    }
    
    public static void handleBeforeDelete(List<ContentDocument> lstOldCD) {
        System.debug('@@ ContentDocumentTriggerHandler handleBeforeDelete starts ');
         
        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];
        List<ContentDocument> lstCDs = new List<ContentDocument>();
        List<Id> lstCDId = new List<Id>();
        List<Id> lstOldCDId = new List<Id>();
        set<id> conDocIdSet=new set<id>();
        Set<id> setSEId=new Set<id>();
		set<id>contentDocSet=new set<id>();
        set<id>setAccId=new set<id>();
        String sObjectName = 'Sourcing_Event__c';
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName); 
        
        for (Integer i=0;i<lstOldCD.size();i++){
            system.debug ('##cd.description' + lstOldCD[i].description);
            // commented by MRA 29/09/2021 -> blocks file component when replacing a file
            if (lstOldCD[i].fileType== 'PDF'){
                lstCDs.add(lstOldCD[i]);
                conDocIdSet.add(lstOldCD[i].id);
            }

            if (PAD.canTrigger('AP02_Sing')) {
                lstCDId.add(lstOldCD[i].Id);
            }
            
            if (PAD.canTrigger('AP71')) { 
                contentDocSet.add(lstOldCD[i].Id);
            }
        }
        
        if (PAD.canTrigger('AP02_Sing')) {   
            for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId, ContentDocument.Description FROM ContentDocumentLink WHERE ContentDocumentId IN:lstCDId]){
                if((String.valueOf(cdl.LinkedEntityId)).StartsWith(sObjType.getDescribe().getKeyPrefix()) && cdl.ContentDocument.Description == 'RFX Results'){
                    setSEId.add(cdl.LinkedEntityId);
                }
            }
            
            if(setSEId.size() > 0)
            AP02_sing_countJustificationDoc.updtCountJustification(setSEId, false);
        }
        
        if(contentDocSet.size()>0){
            for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId 
                                          FROM ContentDocumentLink 
                                          WHERE ContentDocumentId IN:contentDocSet]){
                if((String.valueOf(cdl.LinkedEntityId)).StartsWith( Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix())){
                    setAccId.add(cdl.LinkedEntityId);
                }
            }
            if(setAccId.size()>0)
            	AP71_AccValidateReqDoc.checkTOBAUploaded(setAccId,contentDocSet,'delete');
        }
        
        if(lstCDId.size() > 0){
            if(AP02_sing_countJustificationDoc.blockDocumentDeletion(lstCDId)){
                lstOldCD[0].addError(System.Label.ErrorMessage_CannotDeleteRFXRequirementsDoc);
            }else{
                List<ContentVersion> lstCV = [SELECT Id, ContentDocumentId, 
                                              Negotiation_Round__c, Sharing_Logic__c, 
                                              Participant__c, Participant__r.Bidder_Status__c FROM ContentVersion WHERE ContentDocumentId IN :lstCDId];
                if(lstCV.size() > 0){
                    boolean isDeclined = false;
                    for(ContentVersion cv: lstCV){
                        if(cv.Participant__r.Bidder_Status__c == 'Declined'){
                            isDeclined = true; break;
                        }
                    }
                    // Block update for 'esourcing Vendor' profile or a declined participant
                    if(isDeclined || AP02_sing_countJustificationDoc.blockUpdateCompletedRound(lstCV)) lstOldCD[0].addError(System.Label.Sing_ErrorMessageDeleteDoc);
                    
                }
            }
        }

        if (lstCDs.size() > 0)  AP44_BlockNewContractTeam.determineNumOfSignablePDF(lstCDs);

         if (conDocIdSet.size() > 0) AP47_UpdateFinalDocUrl.UpdateFinaldocUrlToBlank(conDocIdSet);
        
        
        //AP44_BlockNewContractTeam.determineNumOfSignablePDF(lstOldCD);
        System.debug('@@ ContentDocumentTriggerHandler handleBeforeDelete ends ');
    }
}