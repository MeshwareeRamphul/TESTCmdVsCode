public without sharing class ContractFormTriggerHandler {
    public static Map<String, String> contractFormStatusContractStatusMap = new Map<String, String>{'Waiting'=>'In Approval', 'Approved'=>'In Signature', 'Rejected'=>'In Progress'};
    public static Map<String, String> contractFormStatusContractStatusAIMMap = new Map<String, String>{'Waiting'=>'In Approval', 'Approved'=>'Active', 'Rejected'=>'In Progress'};
    public static Map<Id, cTin_ContractForm__c> contractIdContractFormMap = new Map<Id, cTin_ContractForm__c>();
    public static Set<id> contractIdSet = new Set<id>();
    public static Set<id> setIdCtr = new Set<id>();
    public static List<cTin_ContractForm__c> lstContractFrm=new List<cTin_ContractForm__c>();
	public static Boolean hasExecutedafterUpdate = false;
    
    public static void beforeUpdateHandler(List<cTin_ContractForm__c> lstOld, List<cTin_ContractForm__c> lstNew, Map<Id,cTin_ContractForm__c> mapOld, Map<Id,cTin_ContractForm__c> mapNew){
        Id profileId= userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        //Before update
        System.debug('## >>> BEFORE UPDATE TRIGGER START <<<');
        for(cTin_ContractForm__c cf : lstNew){
            //MRA: 31-MAY-2021 : SP-01548 (block user from changing  contract status to In approval manually' )
            if(cf.cTin_Contract__c != null && (cf.cTin_ApprovalStartDate__c == mapOld.get(cf.Id).cTin_ApprovalStartDate__c )
               && cf.cTin_ContractStatus__c !=  mapOld.get(cf.Id).cTin_ContractStatus__c &&  cf.cTin_ContractStatus__c=='In Approval'
               && !profileName.contains('Administrator') && !profileName.contains('Administrateur')) {
                   cf.addError(system.label.cTin_ErrorMessageInApprovalStatus  );                    
               }
            
            if(cf.cTin_Contract__c != null && (cf.cTin_FinalApprovalStatus__c != mapOld.get(cf.Id).cTin_FinalApprovalStatus__c)){
                contractIdContractFormMap.put(cf.cTin_Contract__c, cf);
                if(cf.cTin_FinalApprovalStatus__c == null || cf.cTin_FinalApprovalStatus__c.trim() == ''){
                    cf.cTin_ContractStatus__c = contractFormStatusContractStatusMap.get('Rejected');cTin_contractFormHandler.contractFormStatusChangeMap.put(cf.Id, cf);
                }else{            
                    //MRA 10/08/2016 - Case 00003089 (Added check on contract owner local entity)
                    if(/*cf.ContractOwnerEntityLocalCode__c <> 'AIM' &&*/ cf.cTin_ContractOwnerEntityLocalCode__c <> 'ASIA'){                   
                        cf.cTin_ContractStatus__c = contractFormStatusContractStatusMap.get(cf.cTin_FinalApprovalStatus__c);
                        cTin_contractFormHandler.contractFormStatusChangeMap.put(cf.Id, cf);
                    }
                    else{                   
                        cf.cTin_ContractStatus__c = contractFormStatusContractStatusAIMMap .get(cf.cTin_FinalApprovalStatus__c);cTin_contractFormHandler.contractFormStatusChangeMap.put(cf.Id, cf);
                    }
                }
            }  
            
            //25-APR-2019  MRA : Evol Bundle 1
            if(cf.cTin_FinalApprovalStatus__c==system.label.cTin_ApprovedStatus){
                if(cf.cTin_ApproverName1__c!=null)
                    cf.cTin_ApprovalStatus1__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus1__c='';
                
                if(cf.cTin_ApproverName2__c!=null)
                    cf.cTin_ApprovalStatus2__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus2__c='';
                
                if(cf.cTin_ApproverName3__c!=null)
                    cf.cTin_ApprovalStatus3__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus3__c='';
                
                if(cf.cTin_ApproverName4__c!=null)
                    cf.cTin_ApprovalStatus4__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus4__c='';
                
                if(cf.cTin_ApproverName5__c!=null)
                    cf.cTin_ApprovalStatus5__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus5__c='';
                
                if(cf.cTin_ApproverName6__c!=null)
                    cf.cTin_ApprovalStatus6__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus6__c='';
                
                if(cf.cTin_ApproverName7__c!=null)
                    cf.cTin_ApprovalStatus7__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus7__c='';
                
                if(cf.cTin_ApproverName8__c!=null)
                    cf.cTin_ApprovalStatus8__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus8__c='';
                
                
                if(cf.cTin_ApproverName9__c!=null) cf.cTin_ApprovalStatus9__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus9__c='';
                
                
                if(cf.cTin_ApproverName10__c!=null)
                    cf.cTin_ApprovalStatus10__c=system.label.cTin_ApprovedStatus;
                else
                    cf.cTin_ApprovalStatus10__c='';
            }
            
            
            
        }
        
        
        List<Contract__c> contractToUpdateList = [SELECT Id, Status__c, cTin_OwnerEntityLocalCode__c
                                                  FROM Contract__c
                                                  WHERE Id in :contractIdContractFormMap.keySet()];
        
        map<Id,Contract__c> contractWithDifferentStatusToUpdate = new map<Id,Contract__c>();
        
        if(contractToUpdateList.size()>0){
            for(Contract__c contract : contractToUpdateList){
                if(contractIdContractFormMap.get(contract.Id).cTin_FinalApprovalStatus__c == null || contractIdContractFormMap.get(contract.Id).cTin_FinalApprovalStatus__c == ''){
                    if(contract.Status__c != contractFormStatusContractStatusMap.get('Rejected')){
                        contract.Status__c = contractFormStatusContractStatusMap.get('Rejected');contractWithDifferentStatusToUpdate.put(contract.Id,contract);
                    }
                }
                else if(contract.Status__c != contractFormStatusContractStatusMap.get(contractIdContractFormMap.get(contract.Id).cTin_FinalApprovalStatus__c)){
                    //MRA 10/08/2016 - Case 00003089 (Added check on contract owner local entity)
                    if(/*contract.OwnerEntityLocalCode__c <> 'AIM' && */ contract.cTin_OwnerEntityLocalCode__c <> 'ASIA'){
                        contract.Status__c = contractFormStatusContractStatusMap.get(contractIdContractFormMap.get(contract.Id).cTin_FinalApprovalStatus__c);
                        contractWithDifferentStatusToUpdate.put(contract.Id,contract);
                    }
                    else{
                        contract.Status__c=contractFormStatusContractStatusAIMMap.get(contractIdContractFormMap.get(contract.Id).cTin_FinalApprovalStatus__c);
                        contractWithDifferentStatusToUpdate.put(contract.Id,contract);
                    }
                }
                
            }
            if(contractWithDifferentStatusToUpdate.size()>0){
                //try{
                //update contractWithDifferentStatusToUpdate.values();
                List<Database.SaveResult> results = Database.update(contractWithDifferentStatusToUpdate.values(), false);
                for (Database.SaveResult result : results) {
                    system.debug('## result: '+result); 
                    if (!result.isSuccess()){
                        for (Database.Error err : result.getErrors()){ 
                            system.debug('## Error: '+err);
                            System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                            if(lstNew.size() == 1){lstNew[0].addError(err.getMessage());
                                                  }
                        }
                    }
                }  
                //}catch(Exception e){}
            }
            
        }
        
        System.debug('## >>> BEFORE UPDATE TRIGGER END <<<');
    }
    
    public static void afterUpdateHandler(List<cTin_ContractForm__c> lstOldContractForm, List<cTin_ContractForm__c> lstNewContractForm){
        System.debug('## >>> AFTER UPDATE TRIGGER START <<<');
        if(!hasExecutedafterUpdate){
            for(integer i=0; i<lstNewContractForm.size(); i++){        
                if(lstNewContractForm[i].cTin_eSignature_automate__c==true &&      
                    /*(lstNewContractForm[i].cTin_FinalApprovalStatus__c==system.label.cTin_ApprovedStatus) 
                    &&*/ ((lstOldContractForm[i].cTin_ContractStatus__c!=lstNewContractForm[i].cTin_ContractStatus__c)
                    && lstNewContractForm[i].cTin_ContractStatus__c==system.label.cTin_Status_Signature)){
                        contractIdSet.add(lstNewContractForm[i].cTin_Contract__c);              
                }  
                if(lstOldContractForm[i].cTin_FinalApprovalStatus__c != lstNewContractForm[i].cTin_FinalApprovalStatus__c && lstNewContractForm[i].cTin_FinalApprovalStatus__c == 'Approved'){
                    setIdCtr.add(lstNewContractForm[i].cTin_Contract__c);
                }
            }
                
            if(contractIdSet.size()>0 && AP41_AutomateEsignature.alreadyFired!=true){
                AP41_AutomateEsignature.createEsignature(contractIdSet);
            }
    
            // 22-12-2022 ARA SP-00183
            if(setIdCtr.size()>0){
                AP75_ManageNotificationSE_ctin.sendNotifDocumentApprouved(setIdCtr);
            }
            hasExecutedafterUpdate = true;
        }
        System.debug('## >>> AFTER UPDATE TRIGGER END <<<');
    }
}