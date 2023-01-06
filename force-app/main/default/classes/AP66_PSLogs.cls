/*----------------------------------------------------------------------
-- - Name          : AP66_PSLogs
-- - Author        : ARA
-- - Description   : Methods to be used for the PSLogTrigger
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 19-NOV-2021  ARA   1.0      Initial version
-------------------------------------------------------------------------*/

public without sharing class AP66_PSLogs {
    
    /**
    * ----------------------------------------------------------------------------------------------
    * Uncheck LastPSLog__c field on previously created Logs
    * ----------------------------------------------------------------------------------------------
    * @param    mapLogContract Map<Id,Id>    : map of contract Id from Trigger.newMap
    * ----------------------------------------------------------------------------------------------
    */
    public static void uncheckRecentlyCreated(Map<Id, Id> mapLogContract){
        List<Log__c> lstPSLog = [SELECT Id, LastPSLog__c FROM Log__c WHERE Id NOT IN :mapLogContract.keySet() AND Contract__c IN :mapLogContract.values() AND LastPSLog__c = true];
        if(lstPSLog.size() > 0){
            for(Log__c log : lstPSLog){
                log.LastPSLog__c = false;
            }
            update lstPSLog;
        }
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * Update corresponding MassSend2PSLog__c
    * ----------------------------------------------------------------------------------------------
    * @param    mapLogId Map<Id, Id>    : map of log Id from Trigger.newMap
    * ----------------------------------------------------------------------------------------------
    */
    /*public static void updateMassSend2PSLog(Map<Id, Log__c> mapLog){
        List<MassSend2PSLog__c> lstMassSend2PSLog = new List<MassSend2PSLog__c>();
        List<String> lstCtrId = new List<String>();
        //lstContracts
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>([SELECT Id, Name, ContractNumber__c
                                            FROM Contract__c
                                            WHERE Id in :mapLog.keySet()]);

        for(MassSend2PSLog__c mslog : [SELECT Id, PendingContractsName__c, ProcessedContractsName__c, PendingNumber__c, ProcessedNumber__c, PendingContracts__c, ContractInSuccess__c, ContractInError__c, CreatedDate FROM MassSend2PSLog__c WHERE PendingNumber__c > 0 ORDER BY CreatedDate DESC]){
            for(Id ctrId : mapLog.keySet()){
                if(mslog.PendingContracts__c.contains(ctrId)){ 
                    String ctrIds = '';
                    String pendingCtrName = '';
                    String processedCtrName = mapContract.get(ctrId).ContractNumber__c + ' – ' + mapContract.get(ctrId).Name + '/n';
                    lstCtrId = mslog.PendingContracts__c.split(';');
                    for(String id : lstCtrId){
                        if(id != ctrId){
                            if(ctrIds == ''){
                                ctrIds = id;
                            }else{
                                ctrIds += ';'+id;
                            }
                            pendingCtrName += mapContract.get(id).ContractNumber__c + ' – ' + mapContract.get(id).Name + '/n';
                        }
                    }
                    mslog.PendingContractsName__c = pendingCtrName;
                    mslog.ProcessedContractsName__c = mslog.ProcessedContractsName__c + processedCtrName;
                    mslog.PendingContracts__c = ctrIds;
                    mslog.ProcessedContracts__c = mslog.ProcessedContracts__c == '' ? ctrId : ';'+ctrId;
                    mslog.ProcessedNumber__c = mslog.ProcessedNumber__c + 1;
                    mslog.PendingNumber__c = mslog.PendingNumber__c - 1;
                    if(mapLog.get(ctrId).Call_Status__c == 'S'){
                        mslog.ContractInSuccess__c = mslog.ContractInSuccess__c + 1;
                    }else{
                        mslog.ContractInError__c = mslog.ContractInError__c + 1;
                    }
                    if(mslog.PendingNumber__c == 0){
                        mslog.AllProcessed__c = true;
                    }
                    lstMassSend2PSLog.add(mslog);
                }
            }
        }
        if(lstMassSend2PSLog.size() > 0){
            update lstMassSend2PSLog;
        }
    }*/
}