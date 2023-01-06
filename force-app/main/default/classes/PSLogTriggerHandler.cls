/*----------------------------------------------------------------------
-- - Name          : PSLogTriggerHandler
-- - Author        : ARA
-- - Description   : trigger handler for Log__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 19-NOV-2021  ARA   1.0      Initial version
-------------------------------------------------------------------------*/

public without sharing class PSLogTriggerHandler {

    public static void afterInsertHandler(List<Log__c> lstNewPSLog){
        Map<Id, Log__c> mapLog = new Map<Id, Log__c>();
        Map<Id, Id> mapCtrId = new Map<Id, Id>();
        Set<Id> setCtrId = new Set< Id>();

        for(Log__c log : lstNewPSLog){
            if(log.LastPSLog__c && log.Contract__c != null){
                mapCtrId.put(log.Id, log.Contract__c);
                if(log.Source__c == AP_Constant.PS_FLOW_2){
                    mapLog.put(log.Contract__c, log);
                }
            }
        }

        if(mapCtrId.size() > 0){
            AP66_PSLogs.uncheckRecentlyCreated(mapCtrId);
        }
        /*if(mapLog.size() > 0){
            AP66_PSLogs.updateMassSend2PSLog(mapLog);
        }*/
    }
}