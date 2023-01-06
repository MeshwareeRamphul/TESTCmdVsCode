/*************************************************************************************
Trigger Name - DeployedComponentTrigger
Version - 1.0
Created Date - 24 AUG 2015
Function - Trigger to Manage Deployed Component Changes

Modification Log :
-----------------------------------------------------------------------------
* Owner            Date        Description
* ----------           ----------  -----------------------
* Urvashi Sadasing     09/01/2020  Original Version
*************************************************************************************/
trigger DeployedComponentTrigger on DeployedComponent__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    DeployedComponentTriggerHandler handler = new DeployedComponentTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    //Insert Handling
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
        //AccountTrigger//Handler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }
   
}//end trigger