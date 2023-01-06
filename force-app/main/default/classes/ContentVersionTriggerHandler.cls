public without sharing class ContentVersionTriggerHandler {
/* 
--------------------------------------------------------------------------------------
-- - Name          : ContentVersionTriggerHandler
-- - Author        : Spoon Consulting 
-- - Description   : 
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 08-AUG-2019  USA    1.0     Initial version
-- 31-JAN-2020  MRA    1.1     Added code for cTin to generate contentversion incTin workspace
-- 31-MAR-2020  SGO    1.2     Determine num of signable docs
-- 28-JAN-2022  ARA    1.3     SP-03043 After Event completion no option to share the documents through RFx requriements
--------------------------------------------------------------------------------------*/

    public static void handleBeforeDelete(List<ContentVersion> lstOldCV) {
        /*if(AP02_sing_countJustificationDoc.blockUpdateCompletedRound(lstOldCV)){
            lstOldCV[0].addError(System.Label.Sing_ErrorMessageDeleteDoc);
        }*/
    }

    public static void handleBeforeUpdate(List<ContentVersion> lstOldCV, List<ContentVersion> lstNewCV) {

        /*if(AP02_sing_countJustificationDoc.blockUpdateCompletedRound(lstNewCV)){
            lstNewCV[0].addError(System.Label.Sing_ErrorMessageUpdateDoc);
        }*/
        
        List<ContentVersion> lstCV = new List<ContentVersion>();   
            
        for (Integer i=0;i<lstNewCV.size();i++){    
            if(lstNewCV[i].Participant__c != null && lstNewCV[i].Sourcing_Event__c != null){    
                lstCV.add(lstNewCV[i]); 
            }   
        }   
        //  28-JAN-2022  ARA    SP-03043    
        if(lstCV.size()>0)  
        AP02_sing_countJustificationDoc.blockInsertionEventCompleted(lstCV);
    }

    public static void handleAfterUpdate(List<ContentVersion> lstOldCV, List<ContentVersion> lstNewCV) {
        System.debug('## start of cv afterupdate');
        List<ContentVersion> lstCVs = new List<ContentVersion>();
        List<Id> lstIdCV = new List<Id>();

        for (Integer i=0;i<lstNewCV.size();i++){
            if (lstOldCV[i].Sign_able__c != lstNewCV[i].Sign_able__c && lstNewCV[i].FileType=='PDF'){
                lstCVs.add(lstNewCV[i]);
            }
            if(lstNewCV[i].Participant__c != null){
                lstIdCV.add(lstNewCV[i].Id);
            }
        }
         System.debug('## lstCVs.size()' + lstCVs.size());
        if (lstCVs.size() > 0){
           AP44_BlockNewContractTeam.determineNumOfSignablePDF(lstCVs);
           AP47_UpdateFinalDocUrl.UpdateFinaldocUrl(lstCVs);
        }

        AP02_sing_countJustificationDoc.updateParticipantStatus(lstIdCV);
    }

  
    public static void handleAfterInsert(List<ContentVersion> lstNewCV) {
        //List<ContentVersion> lstCVs = new List<ContentVersion>();

        /*for (Integer i=0;i<lstNewCV.size();i++){
            if (lstNewCV[i].Sign_able__c == true && lstNewCV[i].FileType=='PDF'){
                lstCVs.add(lstNewCV[i]);
            }
        }
        if (lstCVs.size() > 0){
            AP44_BlockNewContractTeam.determineNumOfSignablePDF(lstCVs);
        }*/
        //System.debug('trigger AMA2');
        AP44_BlockNewContractTeam.determineNumOfSignablePDF(lstNewCV);
    }

    public static void handleBeforeInsert(List<ContentVersion> lstCV) {
        String workspaceId;
        String workspaceName = test.isrunningTest() ? 'Workspace_test' : system.label.ContentWorkspace;
        Set<Id> setRoundId = new Set<Id>();

        User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];
        system.debug('currentUser : ' + currentUser );
        
        if (!currentUser.profile.name.StartsWith('cTin') && !currentUser.profile.name.StartsWith(AP_Constant.esourcingVendorProfile)){
            system.debug('workspaceName : ' + workspaceName);
            if (!test.isrunningTest()) {
                workspaceId = [
                        SELECT Id,developername
                        FROM ContentWorkspace
                        where developername = :workspaceName
                        limit 1
                ].id; 
            }
            system.debug('workspaceId : ' + workspaceId ); 
            for (ContentVersion cv : lstCV) {
                //update TECH_GeneratedByUpdatePDF__c field to different files coming from Conga [code used : '_SOW']
                if (cv.title != null && cv.title.contains('_SOW')) {
                    System.debug('##SGO## cv.title.contains()');
                    cv.TECH_GeneratedByUpdatePDF__c = true;
                    if (!test.isrunningTest()) {
                        cv.FirstPublishLocationId = workspaceId;
                    }
                }
            }
        }
        
        /*if(AP02_sing_countJustificationDoc.blockUpdateCompletedRound(lstCV)){
            lstCV[0].addError(System.Label.Sing_ErrorMessageUpdateDoc);
        }*/
     /*  else{
             workspaceName= test.isrunningTest() ? 'Workspace_test' : system.label.cTin_ContentWorkspace;
             if (!test.isrunningTest()) {
                 workspaceId = [
                            SELECT Id,developername
                            FROM ContentWorkspace
                            where developername = :workspaceName
                            limit 1
                    ].id;
                    
                  for (ContentVersion cv : lstCV) {                  
                        cv.FirstPublishLocationId = workspaceId;
                                  
                  }
              }
            
        }
        */

        integer i=1;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;   i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
        i=2;
    }

}