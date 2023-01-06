public class VFC36_ContractsToSign {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : VFC36_ContractsToSign
-- - Author        : Spoon Consulting 
-- - Description   : Class that displays Contracts To Sign Component on Home page
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 07-SEP-2016  KZE    1.0     Case 4295: Added check to query only Contract-In records: LINE 36
*************************************************************************************/
    User currentUser {get; set;}
    public List<eSignature__c> lstEsignaturesTemp{get;set;}
    public String supplierStatus {get;set;}
    public string sortField  {get;set;}

    public PageReference showSignature(){
        
        Set<Id> eSignatureIds = new Set<Id>();
        String emailCurrentUser = UserInfo.getUserEmail();
        List<Contract__c> listContract = new List<Contract__c>();
        
        List <eSignatory__c> lstSignatory = new List <eSignatory__c>([SELECT ID,
                                                                              RecordTypeId,
                                                                              EmailTxt__c,
                                                                              Contract__c,
                                                                              eSignature__c,
                                                                              cTin_Role__c,
                                                                              Status__c
                                                                         FROM eSignatory__c
                                                                        WHERE EmailTxt__c = :emailCurrentUser
                                                                          AND Contract__r.TECH_IsContractIn__c = true
                                                                          AND Status__c = 'Ready']);
        System.debug('????lstSignatory: '+ lstSignatory );

        Map<String, RecordType> mapEsignatoryRecTypes = AP_Constant.getRecordTypes('eSignatory__c');

        for(eSignatory__c eS : lstSignatory){
            if(String.valueOf(eS.RecordTypeId) != mapEsignatoryRecTypes.get('ctin_Negotiator').Id){
                 eSignatureIds.add(eS.eSignature__c);
            }
        }

        lstEsignaturesTemp = [SELECT Id,
                                     cTin_TechStatusField__c,
                                     cTin_LastApprovedByName__c,
                                     Name,
                                     Status__c,
                                     cTin_SupplierLegalSignatoryEntity__c,
                                     cTin_StartDate__c,
                                     cTin_LastApprovedDate__c,
                                     cTin_LastSignatureDate__c
                                FROM eSignature__c
                                WHERE id IN :eSignatureIds
                                  AND (Status__c = 'Sent'
                                  OR Status__c = 'Ready')];
        
        return null;
    }    

}