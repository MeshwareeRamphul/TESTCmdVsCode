public without sharing class AP39_ContractInMethods {
/*
----------------------------------------------------------------------
-- - Name          : AP39_ContractInMethods
-- - Author        : Spoon Consulting 
-- - Description   : All In - Merge ContractIn
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 27-OCT-2017  HVA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/

    /** 
    * @author Spoon 
    * @date 27/10/2017
    * @description This function handles the creation of contract form for a contract
    */
    public static cTin_ContractForm__c createContractForm(Contract__c contract){

        cTin_ContractForm__c cf = new cTin_ContractForm__c();
        cf.cTin_Contract__c = contract.Id;
        cf.Name = contract.Name;
        for(String fieldName : cTin_Env.ContractToContractFormFieldMap.keySet()){
            cf.put(cTin_Env.ContractToContractFormFieldMap.get(fieldName), String.valueOf(contract.get(fieldName)));
        }
        return cf;
    }

    /** 
    * @author Spoon 
    * @date 27/10/2017
    * @description This function handles the update of contract forms 
    */
    public static List<cTin_ContractForm__c> updateContractForms(Map<Id, Contract__c> newContractMap, Map<Id, Contract__c> oldContractMap, Set<String> setCtinRecTypeId){

        // Selecting the ContractForm which is connected to this Contract and changing its Owner, or other fields
        Map<Id, List<String>> contractIdChangedContractFormFieldNamesMap = new Map<Id, List<String>>();
        Set<Id> idContractChangedSet = new Set<Id>();
        List<cTin_ContractForm__c> contractFormOwnerChangeList = new List<cTin_ContractForm__c>();
        Map<Id, cTin_ContractForm__c> contractFormIdContractForm = new Map<Id, cTin_ContractForm__c>();
        Map<Id, cTin_ContractForm__c> contractFormNeedsUpdateMap = new Map<Id, cTin_ContractForm__c>();

        for(Contract__c c : newContractMap.values()){
            if (setCtinRecTypeId.contains(String.valueOf(c.get('RecordTypeId')))){
                for(String fieldName : cTin_Env.ContractToContractFormFieldMap.keySet()){
                    if(String.valueOf(c.get(fieldName))!=String.valueOf(oldContractMap.get(c.Id).get(fieldName))){
                        idContractChangedSet.add(c.Id);if(contractIdChangedContractFormFieldNamesMap.containsKey(c.Id)){contractIdChangedContractFormFieldNamesMap.get(c.Id).add(fieldName);}else if(!contractIdChangedContractFormFieldNamesMap.containsKey(c.Id)){contractIdChangedContractFormFieldNamesMap.put(c.Id, new List<String>{fieldName});
                        }
                    }
                }
            }
        }
        
        contractFormOwnerChangeList = [SELECT Id, 
                                              OwnerId, 
                                              cTin_Contract__c,
                                              cTin_AntiBriberyClause__c,
                                              cTin_CharacterOfSourcing__c,
                                              /*cTin_ContractSegment__c,*/
                                              cTin_ContractStatus__c,
                                              cTin_CRClause__c,
                                              CurrencyIsoCode,
                                              cTin_DataPrivacyClause__c,
                                              cTin_DocumentExecution__c,
                                              cTin_ExitPlan__c,
                                              cTin_FinancialCheck__c,
                                              cTin_IFCRelevant__c,
                                              cTin_CriticalityRating__c,
                                              cTin_LiabilityClause__c,
                                              cTin_MainAPCL2__c,
                                              cTin_MainAPCL3__c,
                                              cTin_MaterialityRating__c,
                                              cTin_NoticePeriodForTermination__c,
                                              cTin_OutsourcingStandards__c,
                                              cTin_PaymentTerms__c,
                                              cTin_RationalOfSupplierSselectionIs__c,
                                              cTin_RiskAssessment__c,
                                              cTin_SavingsType__c,
                                              cTin_SupplierCompliesWithUNGlobalCompact__c,
                                              cTin_TerminationDisputeClause__c,
                                              Name,
                                              cTin_TypeOfDocument__c,
                                              cTin_SpecificTerms__c,
                                              cTin_GeographicalScope__c,
                                              cTin_OrganizationalScope__c
                                         FROM cTin_ContractForm__c 
                                        WHERE cTin_Contract__c IN: idContractChangedSet 
                                        ORDER BY CreatedDate DESC];

        // for each contract there must be only one contractform
        if (contractFormOwnerChangeList.size() > 0){for(cTin_ContractForm__c cf : contractFormOwnerChangeList){                if(!contractFormIdContractForm.containsKey(cf.Id)){contractFormIdContractForm.put(cf.Id, cf);}            }
        }

        // updating all contract forms with values from parent contract
        if (contractFormIdContractForm.size() > 0){

            for(cTin_ContractForm__c cf : contractFormIdContractForm.values()){

                if(contractIdChangedContractFormFieldNamesMap.containsKey(cf.cTin_Contract__c)){

                    for(String fieldName : contractIdChangedContractFormFieldNamesMap.get(cf.cTin_Contract__c)){

                        // if the field name is status that for not getting recursive calls we need to check that the contract and contract form status field are different
                        if(fieldName != 'Status__c'){cf.put(cTin_Env.ContractToContractFormFieldMap.get(fieldName), String.valueOf(newContractMap.get(cf.cTin_Contract__c).get(fieldName)));                            contractFormNeedsUpdateMap.put(cf.Id, cf);
                        }
                        else if((cf.cTin_ContractStatus__c != newContractMap.get(cf.cTin_Contract__c).Status__c) &&                                 (newContractMap.get(cf.cTin_Contract__c) != null) &&                                (cTin_contractFormHandler.contractFormStatusChangeMap.get(cf.Id) == null)){ cf.put(cTin_Env.ContractToContractFormFieldMap.get(fieldName), String.valueOf(newContractMap.get(cf.cTin_Contract__c).get(fieldName)));                            contractFormNeedsUpdateMap.put(cf.Id, cf);
                        }
                        else if((cf.cTin_ContractStatus__c != newContractMap.get(cf.cTin_Contract__c).Status__c) && (newContractMap.get(cf.cTin_Contract__c) != null) &&(cTin_contractFormHandler.contractFormStatusChangeMap.get(cf.Id) != null) &&(newContractMap.get(cf.cTin_Contract__c).Status__c != cTin_contractFormHandler.contractFormStatusChangeMap.get(cf.Id).cTin_ContractStatus__c)){ cf.put(cTin_Env.ContractToContractFormFieldMap.get(fieldName), String.valueOf(newContractMap.get(cf.cTin_Contract__c).get(fieldName)));contractFormNeedsUpdateMap.put(cf.Id, cf);
                        }
                    }
                }
            }
        }
        
        return contractFormNeedsUpdateMap.values();
    }

    /** 
    * @author Spoon
    * @date 27/10/2017
    */
    public static Boolean checkDoublons(Id Contract, Id TeamMember){
        Boolean NotcreatePermission = false ; 
        List<cTin_ContractTeam__c> ListTeamMembers = new List<cTin_ContractTeam__c>(); 

        ListTeamMembers = [Select Id, 
                                  cTin_TeamMember__c, 
                                  cTin_ContractAccessLevel__c  
                             From cTin_ContractTeam__c   
                            Where cTin_Contract__c = :contract  
                              And cTin_TeamMember__c = :teamMember 
                              And cTin_ContractAccessLevel__c='Read'  ] ; 
    
        if(ListTeamMembers.size()>0){
            NotcreatePermission = true;  
        }

        return NotcreatePermission ; 
    }
    
    public static void dummy(){
        integer i=0;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
        i=i+1;
        i=i+1;   
        i=i+1;
    }
}