trigger SourcingRequestTrigger on Sourcing_Request__c (before insert,after insert,before update, after update) {
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
-- 29-APR-2022  MRA    1.0      Intitial version
-- 30-JUN-2022  ARA    1.1      Added code for AP73
**************************************************************************/
if (Trigger.isAfter && Trigger.isInsert) {
    AP73_ManageSrcReqSharing.AfterInsertSharing(Trigger.newMap);
}

if (Trigger.isAfter && Trigger.isUpdate) {

        SourcingRequestTriggerHandler.AfterUpdateHandler(Trigger.oldMap, Trigger.newMap);
        set<id> setSrcReqId=new set<id>();
        Map<ID,Sourcing_Request__c> mapSrcReq = new Map<ID,Sourcing_Request__c>();
        Map<ID,string> mapSrcReqOldSharing = new Map<ID,string>();
        set<id>setOldSharing=new set<id>();
    
        for (Sourcing_Request__c srcReq : Trigger.new) {
            if ((srcReq.TECH_userIdWithReadAccess__c != Trigger.oldMap.get(srcReq.id).TECH_userIdWithReadAccess__c || srcReq.TECH_usrIdWithEditAccess__c != Trigger.oldMap.get(srcReq.id).TECH_usrIdWithEditAccess__c)) {
                mapSrcReq.put(srcReq.id, srcReq);
                mapSrcReqOldSharing.put(srcReq.id, Trigger.oldMap.get(srcReq.id).TECH_userIdWithReadAccess__c+';'+Trigger.oldMap.get(srcReq.id).TECH_usrIdWithEditAccess__c);
            }
            
            /*if((srcReq.TECH_HasRFICreatedFromBtn__c!=Trigger.oldMap.get(srcReq.id).TECH_HasRFICreatedFromBtn__c && srcReq.TECH_HasRFICreatedFromBtn__c==true)
               || (srcReq.TECH_HasRFPCreatedFromBtn__c!=Trigger.oldMap.get(srcReq.id).TECH_HasRFPCreatedFromBtn__c && srcReq.TECH_HasRFPCreatedFromBtn__c==true)){
                setSrcReqId.add(srcReq.Id);
            }*/
         }
    
         if(mapSrcReqOldSharing.size()>0)
            AP73_ManageSrcReqSharing.deleteContractSharing(mapSrcReqOldSharing);
        
         if(mapSrcReq.size()>0)
            AP73_ManageSrcReqSharing.AfterUpdateSharing(mapSrcReq);
            
        // if(setSrcReqId.size()>0)
          //  AP73_ManageSrcReqSharing.calculateSharingEventCreation(setSrcReqId);
    }
}