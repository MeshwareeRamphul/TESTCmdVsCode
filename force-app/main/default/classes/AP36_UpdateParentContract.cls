public without sharing class AP36_UpdateParentContract {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP36_UpdateParentContract
-- - Author        : Spoon Consulting 
-- - Description   : Impact on Parent contract (status and endDate)
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JAN-2016  RLA    1.0     Initial version
-- 29-NOV-2021  MRA    1.1     Release 9 -SP-02008 : do not update parent contract end date with Amendment end date
*************************************************************************************/

    public static void updateParentContract(set<Id> setContractsId){ 

        List<Contract__c> childList = new List<Contract__c> ();
        List<Contract__c> parentList = new List<Contract__c>();
        Contract__c parent = new Contract__c();
        map<Id,Id> childParentMap = new map<Id, Id>();

        for(Contract__c c :[SELECT Id, cTin_ParentContract__c,cTin_DoNotCopyAmendmentEndDate__c,cTin_ParentContract__r.EndDate__c , EndDate__c from Contract__c where Id in :setContractsId]){
            childList.add(c);
        }
        
        //Build map of child and parent 
        for(Contract__c c :childList){
            childParentMap.put(c.Id,c.cTin_ParentContract__c);
        }
        //get parent of child and update
        for (Contract__c c: childList){         
            parent.Id = childParentMap.get(c.Id);
            parent.status__c = label.cTin_StatusAmended; 
            if(!c.cTin_DoNotCopyAmendmentEndDate__c && parent.EndDate__c < c.EndDate__c)
                parent.EndDate__c = c.EndDate__c;
            parentList.add(parent);
        }


        if(parentList.size()>0){
            Update parentList;  
        }
    }
}