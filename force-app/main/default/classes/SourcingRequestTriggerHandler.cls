public without sharing class SourcingRequestTriggerHandler {
/*----------------------------------------------------------------------
-- - Name          : SourcingRequestTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Sourcing_Request__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 29-APR-2022  MRA    1.0      Initial version (SP-03786 - make sourcing request read-only)
-- 05-MAY-2022  AMA    1.1      SP-03786
-------------------------------------------------------------------------*/
    public static void AfterUpdateHandler(map<Id,Sourcing_Request__c> mapOldSrcReq, map<Id,Sourcing_Request__c> mapNewSrcReq){
        
        System.debug('AfterUpdateHandler');
        map<Id,Contract__c> idSrcReqCtrMap = new map<Id,Contract__c>();
        map<Id,Id> idSrcReqIdCtrPrtMap = new map<Id,Id>();

        for (Contract__c ctr : [select id,cTin_RALinkedMSAParent__c,cTin_CoupaRiskAssessID__c,cTin_ParentContract__c,Sourcing_Request__c from Contract__c WHERE Sourcing_Request__c in: mapNewSrcReq.keyset()]) {
            System.debug('for');
            idSrcReqCtrMap.put(ctr.Sourcing_Request__c,ctr);
            if (ctr.cTin_ParentContract__c != null) {
                System.debug('if');
                idSrcReqIdCtrPrtMap.put(ctr.Sourcing_Request__c,ctr.cTin_ParentContract__c);
            }
        }

        System.debug('idSrcReqCtrMap '+idSrcReqCtrMap);
        System.debug('idSrcReqIdCtrPrtMap '+idSrcReqIdCtrPrtMap);
        List<Id> lstIdCtrPrt = new List<Id>();
        if (idSrcReqIdCtrPrtMap.size()>0) {
            System.debug('if2');
            for (Id idSrcReq : idSrcReqIdCtrPrtMap.keyset()) {
                System.debug('for2');
                lstIdCtrPrt.add(idSrcReqIdCtrPrtMap.get(idSrcReq));
            }
        }
        System.debug('lstIdCtrPrt '+lstIdCtrPrt);
        map<Id,Contract__c> idCtrCtrMap = new map<Id,Contract__c>();
        if (lstIdCtrPrt.size()>0) {
            System.debug('if3');
            for (Contract__c Ctr : [select id,cTin_CoupaRiskAssessID__c from Contract__c WHERE id in: lstIdCtrPrt]) {
                System.debug('for3');
                idCtrCtrMap.put(Ctr.id,Ctr);
            }
        }
        
        if(mapNewSrcReq.size()>0 && AP70_UpdateSrcReqStatus.hasExecutedAP70 == false){
            System.debug('if4');
            AP70_UpdateSrcReqStatus.MapSrcReqFields(mapNewSrcReq, idSrcReqCtrMap, idSrcReqIdCtrPrtMap, idCtrCtrMap);
        }   
        
    }

}