public class LWC3_eSignatureFollowUp {
    /*
--------------------------------------------------------------------------------------
-- - Name          : LWC3_eSignatureFollowUp
-- - Author        : ARA
-- - Description   : Controller for lwc LWC_EsignatureFollowUp
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 09-SEP-2021  ARA    1.0     Initial version SP-01773
--------------------------------------------------------------------------------------
*/
    @AuraEnabled
    public static ResultWrapper getEsignatory(String recordId){
        ResultWrapper result = new ResultWrapper();
        Map<String, List<sObject>> mapResult = new Map<String, List<sObject>>();
        List<Esignatory__c> lstEsignatory = new List<Esignatory__c>();

        Esignature__c esignature = [SELECT Id FROM Esignature__c WHERE Contract__c = :recordId AND (Status__c = :AP_Constant.eSignatureSentStatus OR Status__c = :AP_Constant.eSignatureCompletedStatus)];
        Contract__c contract = [SELECT Id, AXA_GS_Signed_By__r.Name, AXA_GO_Signed_By_2__r.Name, CustomerSignedBy__r.Name, CustomerSignedBy2__r.Name, PendingSince__c, NextEsignatory__c, NextAction__c, Tech_NextEsignatory__c, Validator1__c, Validator2__c, Validator3__c, Validator4__c FROM Contract__c WHERE Id = :recordId];
        
        if(contract != null){
            result.contract = contract;
        }
        if(esignature != null){
            result.esignature = esignature;
            result.esignatory = [SELECT Id, Name, Order__c, Tech_Role__c, ctin_Role__c, SignedDate__c, Status__c, EmailTxt__c, MobileTxt__c, Contact__r.Email, SignURL__c FROM Esignatory__c WHERE Esignature__c = :esignature.Id ORDER BY Order__c ASC];
        }
        return result;
    }
    
    // wrapper class
    public class ResultWrapper{
        @AuraEnabled public Contract__c contract {get; set;}
        @AuraEnabled public eSignature__c esignature {get; set;}
        @AuraEnabled public List<eSignatory__c> esignatory {get; set;}
    }
}