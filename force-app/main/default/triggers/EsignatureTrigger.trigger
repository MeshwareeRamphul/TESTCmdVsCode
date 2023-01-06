trigger EsignatureTrigger on eSignature__c (after update) {
/* 
--------------------------------------------------------------------------------------
-- - Name          : EsignatureTrigger
-- - Author        : Team Kerensen (Initial author of AXA Contract-In trigger EsignatureAfterUpdate)
-- - Description   : Trigger on Esignature object
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 19-APR-2017  MRA    1.0     Copied and renamed to EsignatureTrigger
-- 10-MAY-2017  MRA    1.1     Updated tto retrieve signed document on change of esignature status
-- 02-JUN-2021  MRA    1.2     Block retrieval of sign url when automate esignature is checked
-- 28-SEP-2021  MRA    1.3     Email notification to contract owner 60 days after esignature expires
*************************************************************************************/

    Set<Id> SetEsign = new Set<Id>() ;
   // Set<Id> SetUptEsign = new Set<Id>() ;
    Set<id>esignatureIdSet = new Set<id>();
    Set<id> setEsignIdCancel = new Set<id>();
    Set<id> setCtinExpiredEsign = new Set<id>();
    List<eSignatory__c> listSignato = new List<eSignatory__c>();
    Map<Id,eSignature__c> mapEsignature = new Map<Id,eSignature__c>();
    system.debug('## Esignature trigger');
    if (Trigger.isAfter && Trigger.isUpdate) {
        for(eSignature__c esign : Trigger.new){
            if(Pad.canTrigger('AP22')){
                if(esign.ExternalId__c != null && (Trigger.oldMap.get(esign.id).collecteDone__c==false  &&  Trigger.newMap.get(esign.id).collecteDone__c==true && Trigger.newMap.get(esign.id).TECH_AutomatedEsign__c==false)){                        SetEsign.add(esign.id) ;                 }
                
            	/* if(esign.ExternalId__c != null && Trigger.newMap.get(esign.id).TECH_AutomatedEsign__c && Trigger.newMap.get(esign.id).URL__c!=''){
                    SetUptEsign.add(esign.id);
                }*/
                
                if(Trigger.newMap.get(esign.id).status__c!=Trigger.oldMap.get(esign.id).status__c  && Trigger.newMap.get(esign.id).status__c==AP_Constant.eSignatureCompletedStatus){esignatureIdSet.add(esign.id);     }
            }

            if(PAD.CanTRigger('AP64')){
                List<String> lstStatus = new List<String>{AP_Constant.eSignatureCompletedStatus,AP_Constant.eSignatureExpiredStatus,AP_Constant.eSignatureRejectedStatus,AP_Constant.eSignatureCancelledStatus};
                // for Opco
                if(!esign.cTin_TECH_IsContractIn__c && Trigger.oldMap.get(esign.id).status__c != esign.status__c && lstStatus.contains(esign.status__c)){
                    //mapEsignature.put(esign.Contract__c, esign);
                    setEsignIdCancel.add(esign.Id);
                }
            }
            
            if(PAD.CanTRigger('AP65')){ 
                if(esign.cTin_TECH_IsContractIn__c && Trigger.oldMap.get(esign.id).status__c != esign.status__c && esign.status__c==AP_Constant.eSignatureExpiredStatus){                    setCtinExpiredEsign.add(esign.Id);
                }
            }
        }
        
        system.debug('## esignatureIdSet'+esignatureIdSet);

        if(Pad.canTrigger('AP22')){
            //if(SetEsign.size()>0)AP22_CallUniversign.getSignatories(SetEsign);
            
            /*if(SetUptEsign.size()>0){
               // AP41_AutomateEsignature.updateSupplierSignurl(SetUptEsign);
            }*/
                        
            //if(esignatureIdSet.size()>0 /*&& !AP22_RetrieveSignedDoc.hasExecuted && !AP22_XmlRpcWrapper.hasExecutedXmlRpc*/) AP22_RetrieveSignedDoc.getSignedDoc(esignatureIdSet);
        }

        // ARA 26-08-2021   SP-01823
        if(PAD.CanTRigger('AP64')){
            if (setEsignIdCancel.size() > 0){
                AP64_ContractFieldsUpdate.updateCtrValidators(setEsignIdCancel);
            }
            /*if (mapEsignature.size() > 0){
                AP64_ContractFieldsUpdate.updateCtrPendingSince(mapEsignature);
            }*/
        }
        
         if(PAD.CanTRigger('AP65')){ 
             if(setCtinExpiredEsign.size()>0){ AP65_NotifExpiredEsig.notifyCtrOwners(setCtinExpiredEsign);}
         }
    }
}