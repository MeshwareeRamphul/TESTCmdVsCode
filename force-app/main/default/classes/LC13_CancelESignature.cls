public with sharing class LC13_CancelESignature {
/*
----------------------------------------------------------------------
-- - Name          : LC13_CancelESignature
-- - Author        : MRA
-- - Description   : Controller for lighning component LC13_CancelESignature
--                  
--
-- Maintenance History:
--
-- Date          Name      Version   Remarks
-- -----------   ----     -------   ---------------------------------------
-- 12-DEC-2019   USA/MRA    1.0      Initial version (Applicable for cTin + opCo360)
-- 07-AVR-2020   USA        1.1      SP-00171 (allow profiles cancel esignature)
-- 19-may-2020   usa        1.2      SP-00303 (cancel eSignatories) 
-- 28-AUG-2020	 ARA		1.3		 SP-00267 (Expired: no need to cancel it)
--------------------------------------------------------------------------- */

    public static Boolean isAuthorised(){
        Id IdCurProfile = UserInfo.getProfileId();
        List<String> lstProfiles = new List<String>{AP_Constant.functionalAdmin, AP_Constant.billingTeam, AP_Constant.contractManager, 
                                                    AP_Constant.accountManager, AP_Constant.productOwner, AP_Constant.userAdmin,
                                                    AP_Constant.systemAdmin, AP_Constant.cTinAdmin};

        Set<Id> setIdProfile = new set<Id>();
        for (Profile prof :[SELECT id FROM profile WHERE Name IN :lstProfiles]){
            setIdProfile.add(prof.Id);
        }

        if (setIdProfile.contains(IdCurProfile)){
            return true;
        } else{
            return false;
        }
    }

    @AuraEnabled
    public static Map<String, String> cancelESignature(String ctrId){
        System.debug('## LC13_CancelESignature.cancelESignature - Start' + ctrId);
        Map<String, String> result = new Map<String, String>();
        String message = '';
        List<eSignature__c> lstcurrentESign = new List<eSignature__c>();

        try{
            list<Contract__c> lstCtr=[select Tech_IsContractIn__c from contract__c where id=:ctrId];
            if(!lstCtr[0].Tech_IsContractIn__c){
                lstcurrentESign = [ SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c, LastModifiedDate, Contract__c, RecordTypeId
                                    FROM eSignature__c
                                    WHERE Contract__c = :ctrId 
                                    AND (Status__c = :Ap_Constant.eSignatureSentStatus 
                                    OR Status__c = :Ap_Constant.eSignatureCreatedStatus 
                                    OR Status__c = :Ap_Constant.eSignatureFailedStatus)
                                    ORDER BY LastModifiedDate Desc
                                    LIMIT 1];     
            }else{
                lstcurrentESign = [ SELECT Id, Status__c,TransactionID__c,TECH_ContractOwner__c, cTin_TECH_IsContractIn__c, Error_Message__c, LastModifiedDate,Contract__c, RecordTypeId
                                    FROM eSignature__c
                                    WHERE Contract__c = :ctrId 
                                    AND (Status__c = :Ap_Constant.eSignatureSentStatus
                                    OR Status__c = :Ap_Constant.eSignatureCreatedStatus )
                                    ORDER BY LastModifiedDate Desc
                                    LIMIT 1];     
            }
            System.debug('@@@ currentESign ' + lstcurrentESign);
            if (lstcurrentESign.size() < 1){
                result.put('error', 'The eSignature cannot be cancelled.');
            }else if(isAuthorised() || lstcurrentESign[0].TECH_ContractOwner__c.substring(0,14) == UserInfo.getUserId().substring(0,14)){
                System.debug('## TransactionID__c + msg ' + lstcurrentESign[0].TransactionID__c + '/' + lstcurrentESign[0].Error_Message__c);
                if(lstcurrentESign[0].Status__c == Ap_Constant.eSignatureSentStatus){
                    if(lstcurrentESign[0].TransactionID__c != null){
                        result = WS07_UniversignTransaction.cancelTransaction(lstcurrentESign[0]);
                    }else{
                        result.put('error', 'No created transaction for this signature');
                    }
                }else{
                    list<eSignatory__c> lstEsignToUpdat = new list<eSignatory__c>();
                    for (eSignatory__c eSign : [SELECT Id, status__c,esignature__r.status__c, esignature__r.transactionId__c,
                                                esignature__r.Contract__c,esignature__r.Language__c, esignature__c,
                                                esignature__r.CreatedById,esignature__r.HandWrittenSignatureMode__c
                                                FROM eSignatory__c
                                                WHERE eSignature__c =: lstcurrentESign[0].Id]){
                        lstEsignToUpdat.add(new eSignatory__c(Id = eSign.Id, Status__c = Ap_Constant.esignatoryStatusCancelled));
                    }
                    update lstEsignToUpdat;
                    
                    lstcurrentESign[0].Status__c = Ap_Constant.eSignatureCancelledStatus;
                    update lstcurrentESign;
                }
                if(!result.containsKey('error')){
                    result.put('success', 'Your eSignature has been cancelled.');
                }
            }else{
                result.put('error', Label.NotAuthorisedToCancel);
            }
        }catch(AuraHandledException ex){
            result.put('error', ex.getMessage());
        }

        return result;
    }
}