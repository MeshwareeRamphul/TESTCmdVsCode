public without sharing class LC51_SendToPSMass {
/*
--------------------------------------------------------------------------------------
-- - Name          : LC51_SendToPSMass
-- - Author        : ARA
-- - Description   : send contracts in bulk to PeopleSoft
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JAN-2020  ARA    1.0     Initial version
--------------------------------------------------------------------------------------
*/
    
    
    @AuraEnabled
    public static map<string,object> checkStatus(String contractIds){
        Map<string,object> result = new Map<String,object>();
        if (AP_Constant.hasRights(new Set<String>{AP_Constant.functionalAdmin, AP_Constant.billingTeam})){
            List<Contract__c> lstContract = new List<Contract__c>();
            Set<Id> setOfId = setContractIds(contractIds);
            
            if(setOfId.size() == 0){
                result.put('error', System.Label.LC51_SelectAtLeastONe);
            }else if(setOfId.size() > 20){
                result.put('error', System.Label.LC51_ValidateSelection);
            }else{
                lstContract = [SELECT Id, Name, Status__c, Peoplesoft_Sync__c, Tech_isSendingToPS__c, TECH_countILs__c FROM Contract__c WHERE Id in :setOfId 
                                AND Peoplesoft_Sync__c = false
                                AND (Status__c = :AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE OR Status__c = :AP_Constant.CONTRACT_STATUS_SIGNED OR Status__c = :AP_Constant.CONTRACT_STATUS_ENDED OR Status__c = :AP_Constant.CONTRACT_STATUS_RESILIATED OR Status__c = :AP_Constant.CONTRACT_STATUS_CANCELLED )];
                if(lstContract.size() != setOfId.size()){
                    result.put('error', System.Label.LC51_SelectRightListView);
                }else{
                    for(Contract__c ctr: lstContract){
                        if(ctr.Tech_isSendingToPS__c){
                            result.put('error', System.Label.LC51_ContractIsSending);
                            break;
                        }
                        if(ctr.TECH_countILs__c == 0){
                            result.put('error', System.Label.LC51_SelectRightListView);
                            break;
                        }
                    }
                }

                if(result.get('error') == null){
                
                    List<Id> lstContractIds = new List<Id>(new Map<Id, Contract__c>(lstContract).keySet());
                    List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id,Contract2__c
                                                                        FROM Planned_Invoicing_Line__c 
                                                                        WHERE Contract2__c IN :lstContractIds
                                                                        AND Contract2__r.Peoplesoft_Sync__c = false
                                                                        AND Type__c = 'Invoicing Line'
                                                                        AND AmountIL__c >= 0
                                                                        AND (isInPS__c = true OR Status__c !=: System.label.InvLineStatusCancelled)];

                    if(invoicingLineList.size() == 0){
                        result.put('error', System.Label.LC51_NoNewInformationToSend);
                    }
                    else{
                        Map<id, list<Planned_Invoicing_Line__c>> mapInvoiceLineInfo=new map<id, list<Planned_Invoicing_Line__c>>();
                        for(Planned_Invoicing_Line__c inv_Line: invoicingLineList){
                            if(mapInvoiceLineInfo.containsKey(inv_Line.Contract2__c)){
                                mapInvoiceLineInfo.get(inv_Line.Contract2__c).add(inv_Line);   
                            }
                            else{
                                mapInvoiceLineInfo.put(inv_Line.Contract2__c,new list<Planned_Invoicing_Line__c>{inv_Line});
                            }
                        }
                        for(Contract__c ctr : lstContract){
                            if(!mapInvoiceLineInfo.containsKey(ctr.Id)){
                                result.put('error', System.Label.LC51_SelectRightListView);
                                break;
                            }
                        }
                    }
                }
            }
        }else{
            result.put('error', System.Label.LC05_HaveNoSufficientRights);
        }
        return result;
    }

    @AuraEnabled
    public static map<string,object> sendToPS(String contractIds){
        Map<string,object> result = new Map<String,object>();
        Set<Id> setContractId = setContractIds(contractIds);
        List<Contract__c> lstContracts = new List<Contract__c>();
        Map<id, list<Planned_Invoicing_Line__c>> mapInvoiceLineInfo=new map<id, list<Planned_Invoicing_Line__c>>();
        
        for(Id ctrId : setContractId){
            lstContracts.add(new Contract__c(id = ctrId, Tech_isSendingToPS__c = true, PeopleSoftConnectionMessage__c = 'Preparation for sending to ps'));
        }
        update lstContracts;
        
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>(
            [SELECT Id, ContractNumber__c, Tech_isSendingToPS__c, Tech_countILsNotCancelled__c, Tech_countILsUpdatedByPS__c
            FROM Contract__c
            WHERE Id in :setContractId]
        );
        
        for(Id ctrId: mapContract.keySet()){
            Decimal nbrILs = mapContract.get(ctrId).Tech_countILsNotCancelled__c + mapContract.get(ctrId).Tech_countILsUpdatedByPS__c;
            if(nbrILs == 0){
                result.put('error', mapContract.get(ctrId).ContractNumber__c + System.Label.LC51_ErrorMessageNoInformation);
                break;
            }
            if(nbrILs > 20 && mapContract.size() > 1){
                result.put('error', mapContract.get(ctrId).ContractNumber__c + System.Label.LC51_ErrorMessageManyILs);
                break;
            }  
        }

        if(result.get('error') == null){
            try{
                // Send to PS
                AP54_MassSendToPeopleSoft.sendMassToPS(setContractId);
            }
            catch(exception e ){
                String errorMessage = '';
                if(e.getMessage().contains('Please choose an active Activity Code with an AXA GO Legal Entity corresponding to that on the contract.')){
                    Integer i = e.getMessage().indexOf(';');
                    Id pilId = e.getMessage().substring(i-18, i);
                    Planned_Invoicing_Line__c pil = [SELECT Id, Contract2__r.Name FROM Planned_Invoicing_Line__c WHERE Id = :pilId][0];
                    if(pil != null){errorMessage = System.Label.LC51_ChooseActivityCodeContract +' "'+pil.Contract2__r.Name+'".';}
                }else{errorMessage = e.getMessage();}
                result.put('error', errorMessage);
            }
        }

        if(result.get('error') != null || Test.isRunningTest()){
            try{
                lstContracts = new List<Contract__c>();
                for(Id ctrId : setContractId){
                    lstContracts.add(new Contract__c(id = ctrId, Tech_isSendingToPS__c = false));
                }
                update lstContracts;
            }catch(Exception e){
                String errorMessage = '';
                if(e.getMessage().contains('The following fields are mandatory to update the status from Draft:')){
                    Integer i = e.getMessage().indexOf(';');
                    Id ctrId = e.getMessage().substring(i-18, i);
                    Contract__c ctr = [SELECT Id, Name FROM Contract__c WHERE Id = :ctrId][0];
                    if(ctr != null){errorMessage = System.Label.LC51_FollowingFieldsMandatory+' "'+ctr.Name+'".';}
                }else{errorMessage = e.getMessage();}
                result.put('error', errorMessage);
            }
        }

        //result.put('listViewId', '00B1w000001XhZJEA0');
        return result;
    }
    
    private static Set<Id> setContractIds(String strIds){
        List<String> lstContractId = new List<String>();
        Set<Id> setOfId = new Set<Id>();
        strIds = strIds.replace('"','');
        if(strIds != ''){
            lstContractId = strIds.split(',');
            for(String idContract : lstContractId){
                setOfId.add(idContract);
            }
        }
        
        return setOfId;
    }
}