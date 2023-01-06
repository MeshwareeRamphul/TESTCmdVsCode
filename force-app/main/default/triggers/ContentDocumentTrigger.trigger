trigger ContentDocumentTrigger on ContentDocument (before insert, after insert, before update, before delete, after update) {
/* 
--------------------------------------------------------------------------------------
-- - Name          : ContentDocumentAfterInsert
-- - Author        : Spoon Consulting 
-- - Description   : Trigger on Content Document to update final document url with url of signed document
                     (Copied from AXA Contract- In)
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 19-APR-2017  MRA    1.0     Initial version
-- 11-JAN-2021  ARA    1.2     SP-01136
*************************************************************************************/

    if (Trigger.isBefore && Trigger.isInsert) {
        ContentDocumentTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentTriggerHandler.handleAfterInsert(Trigger.new);
    }
    system.debug('Ending trigger ContentDocumentAfterInsert');
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        ContentDocumentTriggerHandler.handleBeforeUpdate(Trigger.old, Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        set<id> assigneToIds=new set<id>();for(PermissionSetAssignment ps: [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId,PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSet.Name =: 'PS_ByPassAP44']){assigneToIds.add(ps.AssigneeId);}if((assigneToIds.size()>0 && !assigneToIds.contains(userinfo.getUserId())) || assigneToIds.size()==0){
           ContentDocumentTriggerHandler.handleBeforeDelete(Trigger.old); 
        }
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        ContentDocumentTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}