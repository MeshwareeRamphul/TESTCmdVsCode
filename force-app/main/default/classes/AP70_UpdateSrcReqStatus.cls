/*
----------------------------------------------------------------------
-- - Name          : SourcingRequestTrigger
-- - Author        : Spoon Consulting 
-- - Description   : sourcing event trigger
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 22-APR-2022  AMA    1.0      Intitial version
-- 05-MAY-2022  AMA    1.1      SP-03786
**************************************************************************/
public without sharing class AP70_UpdateSrcReqStatus {
    public static Boolean hasExecutedAP70 =false;
    
    public static void UpdateSourcingReqest(Map<ID,String> IdSrcReqStatusMap, Map<ID,Contract__c> IdSrcReqCtrMap){
        system.debug(' IdSrcReqCtrMap' +IdSrcReqCtrMap);
        List<Sourcing_Request__c> lstSrcReqUpd = new List<Sourcing_Request__c>();
        for (ID idSrcReq :IdSrcReqStatusMap.KeySet()) {
            if (IdSrcReqCtrMap.containsKey(idSrcReq) && IdSrcReqCtrMap.get(idSrcReq).status__c=='Active') {
                lstSrcReqUpd.add(new Sourcing_Request__c(id=idSrcReq, Status__c = IdSrcReqStatusMap.get(idSrcReq), Signature_target_date__c = IdSrcReqCtrMap.get(idSrcReq).cTin_SignatureDate__c,Estimated_spend__c=IdSrcReqCtrMap.get(idSrcReq).Contract_Value_excl_VAT__c, Commitment_at_stake_in_K__c=IdSrcReqCtrMap.get(idSrcReq).cTin_CommittedPartExclVAT__c,TECH_IsChangedByTrigger__c=generateRandomString(5)));
            }
            else {
                if (IdSrcReqCtrMap.size()>0 && IdSrcReqCtrMap.containsKey(idSrcReq)) {
                    lstSrcReqUpd.add(new Sourcing_Request__c(id=idSrcReq, Status__c = IdSrcReqStatusMap.get(idSrcReq),Estimated_spend__c=IdSrcReqCtrMap.get(idSrcReq).Contract_Value_excl_VAT__c, Commitment_at_stake_in_K__c=IdSrcReqCtrMap.get(idSrcReq).cTin_CommittedPartExclVAT__c,TECH_IsChangedByTrigger__c=generateRandomString(5)));
                }else {
                    lstSrcReqUpd.add(new Sourcing_Request__c(id=idSrcReq, Status__c = IdSrcReqStatusMap.get(idSrcReq),TECH_IsChangedByTrigger__c=generateRandomString(5)));
                }
            }
        }

        if(lstSrcReqUpd.size()>0){
            update lstSrcReqUpd;
        }
    }

    public static void MapSrcReqFields(map<Id,Sourcing_Request__c> mapNewSrcReq,map<Id,Contract__c> idSrcReqCtrMap,map<Id,Id> idSrcReqIdCtrPrtMap,map<Id,Contract__c> idCtrCtrMap){
        hasExecutedAP70 = true;
        List<Sourcing_Request__c> lstSrcReqUpd = new list<Sourcing_Request__c>();
        for(id srcReqId: mapNewSrcReq.keyset())   {
            System.debug('for');
            if (mapNewSrcReq.get(srcReqId).Status__c == 'Closed/Signed') {
                System.debug('if1');
                System.debug('Risk_assessment_requirements__c'+mapNewSrcReq.get(srcReqId).Risk_assessment_requirements__c);
                System.debug('CRAQ_number__c'+mapNewSrcReq.get(srcReqId).CRAQ_number__c);
                if (idSrcReqCtrMap.containsKey(srcReqId) && idSrcReqCtrMap.get(srcReqId).cTin_RALinkedMSAParent__c == true) {
                    System.debug('if2');
                    lstSrcReqUpd.add(new Sourcing_Request__c(id=srcReqId,CRAQ_number__c=idCtrCtrMap.get(idSrcReqIdCtrPrtMap.get(srcReqId)).cTin_CoupaRiskAssessID__c,TECH_IsChangedByTrigger__c=generateRandomString(5)));
                }
                else if (mapNewSrcReq.containsKey(srcReqId) && mapNewSrcReq.get(srcReqId).Risk_assessment_requirements__c == 'Applicable' &&  String.isBlank(mapNewSrcReq.get(srcReqId).CRAQ_number__c)) {
                    System.debug('if3');
                    lstSrcReqUpd.add(new Sourcing_Request__c(id=srcReqId,CRAQ_number__c=idSrcReqCtrMap.get(srcReqId).cTin_CoupaRiskAssessID__c,TECH_IsChangedByTrigger__c=generateRandomString(5)));
                }
            }
        } 

        if (lstSrcReqUpd.size()>0) {
            update lstSrcReqUpd;
        }
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}