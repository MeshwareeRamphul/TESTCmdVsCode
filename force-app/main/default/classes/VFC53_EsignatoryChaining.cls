public without sharing class VFC53_EsignatoryChaining {
    public esignatory__c esign {get; set;}
    public Integer nbrValidator {get; set;} 
    public esignatory__c esignatory {get; set;} 
    
    public List<eSignatory__c> getlstEsignatory(){
        nbrValidator = 0;
        esignatory = [SELECT Id, Name__c, Status__c, eSignature__c, eSignatureTransactionId__c, cTin_Role__c, RelaunchCount__c, Contact__c,
                      cTin_signLink__c, NextReminder__c, cTin_EntityNameTxt__c,
                      Contract__r.cTin_Owner__c, Contract__r.Global_Amount__c,
                      Contract__r.Service_Type__c, Contract__r.StartDate__c,
                      Contract__r.EndDate__c, Contract__r.Account__r.Name
                 FROM eSignatory__c WHERE Id = :esign.Id limit 1];
        List<eSignatory__c> lstEsignatories = [SELECT Id, Name, Status__c, Order__c, eSignature__r.Id, eSignatureTransactionId__c, cTin_Role__c, RelaunchCount__c, Contact__c, Contract__r.TECH_IsContractIn__c
                FROM eSignatory__c WHERE eSignature__c = :esignatory.eSignature__c ORDER BY Order__c ASC];
        for(eSignatory__c esignatory : lstEsignatories){
            if(esignatory.cTin_Role__c == AP_Constant.esignRoleValidator){
                nbrValidator += 1;
            }
        }
        return lstEsignatories;
    }
}