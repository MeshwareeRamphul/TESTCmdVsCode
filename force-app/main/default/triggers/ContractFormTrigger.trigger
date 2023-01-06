trigger ContractFormTrigger on cTin_ContractForm__c (before update, after update) {

    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : ContractTeamTrigger
    -- - Author        : Spoon Consulting 
    -- - Description   : Trigger on Contract Team
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 17-OCT-2017  SBH    1.0     Initial version
    -- 25-APR-2019  MRA    1.1     Update approval status after final approval of contract form (evol bundle 1)
    -- 31-MAY-2021  MRA    1.2     cTin-Release 4 => SP-01548 : Block user from updating contract status to 'In approval' manually
    -- 22-DEC-2022  ARA    1.3     SP-00183 Alert to the Business owner when the document is approved and then signed if no business owner then do not send anything
    *************************************************************************************/

    //initialisation
    Map<String, String> contractFormStatusContractStatusMap = new Map<String, String>{'Waiting'=>'In Approval', 'Approved'=>'In Signature', 'Rejected'=>'In Progress'};
    //10/08/2016-MRA: Map for mapping contract status for AIM
    Map<String, String> contractFormStatusContractStatusAIMMap = new Map<String, String>{'Waiting'=>'In Approval', 'Approved'=>'Active', 'Rejected'=>'In Progress'};
    Map<Id, cTin_ContractForm__c> contractIdContractFormMap = new Map<Id, cTin_ContractForm__c>();
    Set<id> contractIdSet = new Set<id>();
    Set<id> setIdCtr = new Set<id>();
    list<cTin_ContractForm__c> lstContractFrm=new list<cTin_ContractForm__c>();

    //After triggers
    if(Trigger.isAfter && Trigger.isUpdate){
        ContractFormTriggerHandler.afterUpdateHandler(trigger.old, trigger.new);
    }
    
    //Before triggers
     if(Trigger.isBefore && Trigger.isUpdate){
        ContractFormTriggerHandler.beforeUpdateHandler(trigger.old, trigger.new, trigger.oldmap, trigger.newmap);
    }
}