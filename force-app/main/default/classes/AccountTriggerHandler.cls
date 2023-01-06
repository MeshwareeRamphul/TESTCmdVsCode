public with sharing class AccountTriggerHandler {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : AccountTriggerHandler
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    --              USA   1.0     Initial version
    --13-JULY-2017  MCU   1.1     Call webService   
    --02-AUGU-2019  KZE   1.1     Add method to update field on Contract AP30           
    --------------------------------------------------------------------------------------
    **************************************************************************************/

    public static void handleAfterUpdate(Map<Id, account> mapOldAcc, Map<Id, account> mapNewAcc){
        //map of account manager changes => Key: new owner; value: old owner
        Map<Id, Id> mapAccManagerhanges = new Map<Id, Id>();
        Set<Id> setCommercialUpt  = new Set<Id>();
        Set<Id> setCommercialIns  = new Set<Id>();
        Set<Id> setLegalUpt  = new Set<Id>();
        Set<Id> setAccIdsAP30  = new Set<Id>();
        Map<Id, Account> mapAccount  = new Map<Id, Account>();
        
        Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
        
        // USA
        for (Id accId : mapOldAcc.keyset()){
            if (mapOldAcc.get(accId).Account_Manager__c != mapNewAcc.get(accId).Account_Manager__c){
                mapAccManagerhanges.put(mapNewAcc.get(accId).Account_Manager__c, mapOldAcc.get(accId).Account_Manager__c);
            }
        }
        
        // MCU 
        for (Id accId : mapOldAcc.keyset()){
            if(mapRT.containsKey(AP_Constant.RT_DN_ENTITY) && 
               mapRT.get(AP_Constant.RT_DN_ENTITY).id == mapNewAcc.get(accId).recordtypeid){ 
                
            
                //Call Webservice WS04
                if (string.isblank(mapNewAcc.get(accId).MDM_Entity_Code__c)){
                    setCommercialIns.add(accid);
                    system.debug('mgr setCommercialUpt ' + setCommercialIns);
                    
                }
                else if (mapOldAcc.get(accId).Name != mapNewAcc.get(accId).Name ||
                    mapOldAcc.get(accId).Active__c != mapNewAcc.get(accId).Active__c ||
                    mapOldAcc.get(accId).Account_Manager__c != mapNewAcc.get(accId).Account_Manager__c ||
                    mapOldAcc.get(accId).AXA_Region__c != mapNewAcc.get(accId).AXA_Region__c ||
                    mapOldAcc.get(accId).Show_In_POS__c != mapNewAcc.get(accId).Show_In_POS__c ||
                    mapOldAcc.get(accId).Group_Governance__c != mapNewAcc.get(accId).Group_Governance__c ||
                    mapOldAcc.get(accId).billingcountry != mapNewAcc.get(accId).billingcountry){
                    setCommercialUpt.add(accid);

                    system.debug('mgr setCommercialUpt ' + setCommercialUpt);

                }
            }
            
            //Call Webservice WS05
            if (mapNewAcc.get(accId).MDMLegalEntityCode__c != null &&
                mapRT.containsKey(AP_Constant.RT_DN_LEGAL_ENTITY) && 
                mapRT.get(AP_Constant.RT_DN_LEGAL_ENTITY).id == mapNewAcc.get(accId).recordtypeid &&
                (mapOldAcc.get(accId).MSA__c != mapNewAcc.get(accId).MSA__c ||
                 mapOldAcc.get(accId).MSA_Reference__c != mapNewAcc.get(accId).MSA_Reference__c ||
                 mapOldAcc.get(accId).MSA_Date__c != mapNewAcc.get(accId).MSA_Date__c ||
                 mapOldAcc.get(accId).Active__c != mapNewAcc.get(accId).Active__c ||
                 mapOldAcc.get(accId).Company_Registration_Number__c != mapNewAcc.get(accId).Company_Registration_Number__c ||
                 mapOldAcc.get(accId).parentid != mapNewAcc.get(accId).parentid || 
                 mapOldAcc.get(accId).Tax_Document__c != mapNewAcc.get(accId).Tax_Document__c)
                ){
                
                setLegalUpt.add(mapNewAcc.get(accId).Id);    
            }
            //AP30
            if (mapOldAcc.get(accId).BillingCity != mapNewAcc.get(accId).BillingCity ||
                mapOldAcc.get(accId).BillingCountry != mapNewAcc.get(accId).BillingCountry ||
                mapOldAcc.get(accId).BillingPostalCode != mapNewAcc.get(accId).BillingPostalCode ||
                mapOldAcc.get(accId).BillingStreet != mapNewAcc.get(accId).BillingStreet ||
                mapOldAcc.get(accId).Name != mapNewAcc.get(accId).Name 
                ){
                setAccIdsAP30.add(mapNewAcc.get(accId).Id);    
            }
            // 30-07-2021   ARA SP-02169
            if(mapOldAcc.get(accId).parentid != mapNewAcc.get(accId).parentid){
                mapAccount.put(accId, mapNewAcc.get(accId));
            }
        }

        //KZE: Added bypass for class AP24   
        if (PAD.canTrigger('AP24')) {
            AP24_AccManagerOppChatter.updateEntitySubscritptions(mapAccManagerhanges, mapNewAcc);
        }

        System.debug('### setCommercialUpt ' + setCommercialUpt );
        if (setCommercialUpt.size() > 0 && !system.isFuture()){
            AP25_CommercialLegalOperations.updateCommercialOperation(setCommercialUpt);
        }
        
        if (setCommercialIns.size() > 0 && !system.isFuture() && PAD.cantrigger('AP25a')){
            AP25_CommercialLegalOperations.insertCommercialOperation(setCommercialIns);
        }

        if (setLegalUpt.size() > 0 && !system.isFuture()){
            AP25_CommercialLegalOperations.updateLegalOperation(setLegalUpt);
        }

        //AP30
        if (setAccIdsAP30.size() > 0 && !system.isFuture()){
            System.debug('##AP30## setAccIdsAP30: ' + setAccIdsAP30.size());
            AP30_ManagePDFStatus.updateContractPDFStatus(setAccIdsAP30);
        }
        
        if (mapAccount.size() > 0 && !system.isFuture()){
            System.debug('##AP30## mapAccount: ' + mapAccount.size());
            AP30_ManagePDFStatus.updateContractEntity(mapAccount);
        }

    }


    public static void handleAfterInsert(Map<Id, account> mapOldAcc, Map<Id, account> mapNewAcc){

        Set <Id> setCommercialIns = new Set <Id>();
        Set <Id> setCommercialUpt = new Set <Id>();
        Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
        for (Account acc : mapNewAcc.values()) {   
            System.debug('### acc.Name ' + acc.Name );
            System.debug('### acc.MDM_Entity_Code__c ' + acc.MDM_Entity_Code__c );
            
            if(mapRT.containsKey(AP_Constant.RT_DN_ENTITY) && 
               mapRT.get(AP_Constant.RT_DN_ENTITY).id == mapNewAcc.get(acc.Id).recordtypeid){
                if (acc.MDM_Entity_Code__c == null)
                    setCommercialIns.add(acc.Id);
                else 
                   setCommercialUpt.add(acc.Id); 
            }
        }

        System.debug('### setCommercialIns ' + setCommercialIns );
        if (setCommercialIns.size()>0 ){
            AP25_CommercialLegalOperations.insertCommercialOperation(setCommercialIns);
        }

        System.debug('### setCommercialUpt ' + setCommercialUpt ); 
        if (setCommercialUpt.size() > 0){
            System.debug('### INNNNNNNNNNNNNNN' );
            AP25_CommercialLegalOperations.updateCommercialOperation(setCommercialUpt);
        }

    }
    
    
    public static void handleBeforeInsert(list<Account> listAcc){
    	Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
    	for (Account acc : listAcc){
    		if(mapRT.containsKey(AP_Constant.RT_DN_LEGAL_ENTITY) && 
                mapRT.get(AP_Constant.RT_DN_LEGAL_ENTITY).id == acc.recordtypeid &&
				string.isBlank(acc.Signature_Type__c))
			{
    			acc.Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC;
    		}
    	}
    }

}