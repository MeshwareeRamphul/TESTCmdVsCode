Public without sharing class VFC54_EsignatoryRelatedList {
    public esignatory__c esign {get; set;}
    public Integer nbrValidator {get; set;} 
    public esignatory__c esignatory {get; set;} 
    public string idContract{get;set;}
    public List<eSignatory__c> lstEsignatories{get;set;}
    
    public List<eSignatory__c> getlstEsignatory(){
        nbrValidator = 0;
       
        esignatory = [SELECT Id, Name__c, Status__c, eSignature__c, eSignatureTransactionId__c, cTin_Role__c, RelaunchCount__c, Contact__c,Tech_Role__c,Contract_name__c,
                      cTin_signLink__c, NextReminder__c, cTin_EntityNameTxt__c,name,Contact__r.Tech_RecordType__c,eSignature__r.cTin_TECH_IsContractIn__c,
                      Contract__r.cTin_Owner__c, Contract__r.Global_Amount__c,cTin_Tech_OwnerEntity__c,Contract__r.TECH_AXALegalSignatoryName__c,
                      Contract__r.Service_Type__c, Contract__r.StartDate__c,contract__r.cTin_Reference__c,Contract__r.name,
                      Contract__r.EndDate__c, Contract__r.Account__r.Name,contract__r.cTin_TypeOfDocument__c,TECH_SignerRole__c,recordtype.name,
                      Contract__r.cTin_ShortDescription__c,contract__r.cTin_OwnerEntity__c,contract__r.cTin_OwnerEntityLocalCode__c,
                      Contract__r.cTin_AXAMainLegalSignatoryEntity__r.name,contract__r.Contract_Value_excl_VAT__c , Contract__r.cTin_AXAMainLegalSignatoryEntity__c,
                      Contract__r.cTin_SupplierAccount__r.name,Contract__r.Owner.LastName,Contract__r.Owner.firstName
                 FROM eSignatory__c WHERE Id = :esign.Id limit 1];
        idContract=esignatory.contract__c;         
        lstEsignatories = [SELECT Id, Name, Status__c, Order__c, eSignature__r.Id, eSignatureTransactionId__c, cTin_Role__c, RelaunchCount__c, Contact__c, Contract__r.TECH_IsContractIn__c,TECH_SignerRole__c
                FROM eSignatory__c WHERE eSignature__c = :esignatory.eSignature__c ORDER BY Order__c ASC];
        
        for(eSignatory__c esignatory : lstEsignatories){
            if(esignatory.cTin_Role__c == AP_Constant.esignRoleValidator){                nbrValidator += 1;
            }
        }
  
        return lstEsignatories;
    }
    
    public List<cTin_ContractTeam__c> getlstcTeam(){
       
        
        List<cTin_ContractTeam__c> lstcTeam = [SELECT Id, cTin_Role__c,cTin_TeamMember__c,cTin_ApprovalOrder__c,cTin_TeamMember__r.firstname, cTin_TeamMember__r.lastname,Tech_RoleDe__c,Tech_RoleFR__c,Tech_RoleEN__c,
        Tech_RoleSpanish__c  FROM cTin_ContractTeam__c WHERE cTin_Contract__c= :idContract and cTin_ApprovalOrder__c!='Not in Approval Process' ORDER BY cTin_ApprovalOrder__c ASC];return lstcTeam ;
    }
}