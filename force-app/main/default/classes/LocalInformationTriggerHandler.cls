public with sharing class LocalInformationTriggerHandler {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : LocalInformationTriggerHandler
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    --              KZE   1.0     Initial version  
    -- 26-AUG-2020  ARA   1.1     SP-00433       
    --------------------------------------------------------------------------------------
    **************************************************************************************/

    public static void handleAfterUpdate(Map<Id, Local_information__c> mapOldLI, Map<Id, Local_information__c> mapNewLI){
        System.debug('##starting method handleAfterUpdate');
        Set <Id> setLocalIdsAP30  = new Set <Id>();
        Set <Id> setLocalIdsAP56  = new Set <Id>();

        // MCU 
        for (Id localId : mapOldLI.keyset()){
            //AP30
            if (mapOldLI.get(localId).MSA__c != mapNewLI.get(localId).MSA__c ||
                mapOldLI.get(localId).MSA_ATS_Date__c != mapNewLI.get(localId).MSA_ATS_Date__c ||
                mapOldLI.get(localId).MSA_ATS_Reference__c != mapNewLI.get(localId).MSA_ATS_Reference__c
                ){
                setLocalIdsAP30.add(mapNewLI.get(localId).Id);    
            }
            //AP56
            if (mapOldLI.get(localId).Purchase_Order__c != mapNewLI.get(localId).Purchase_Order__c){
                setLocalIdsAP56.add(mapNewLI.get(localId).Id);    
            }
        }

        //AP30
        if (setLocalIdsAP30.size() > 0 && !system.isFuture()){
            System.debug('##KZE setLocalIdsAP30' + setLocalIdsAP30.size());
            AP30_ManagePDFStatus.updateContractPDFStatus(setLocalIdsAP30);
        }

        //AP56
        if (setLocalIdsAP56.size() > 0 && !system.isFuture()){
            AP56_ManageILStatusDescription.updateILStatusDescription(setLocalIdsAP56);
        }
    }
}