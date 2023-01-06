trigger UserTrigger on User (after insert, after Update) {
/* 
--------------------------------------------------------------------------------------
-- - Name          : UserTrigger 
-- - Author        : Spoon
-- - Description   : User triggers after insert,after update
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 07-APR-2020  MRA    1.0     Bundle 3.1 Ticket : SP-00188
                               User is deleted from chatter group "USER GUIDE SHARING GROUP" when deactivated or deleted => standard functionality
                               Add users to the chatter group when users are activated or created
-- 19-JAN-2020  ARA    1.1     SP-03219 Share Sourcing Event with new/activated users
---------------------------------------------------------*/
    set<Id> usrIdSet=new set<Id>();
    
    if (Trigger.isAfter && Trigger.isInsert) {
        if (PAD.canTrigger('AP45')) {
            for(Integer i=0; i<trigger.new.size();i++){
                if(Trigger.new[i].isActive && Trigger.new[i].cTin_Universign__c)
                     usrIdSet.add(Trigger.new[i].Id);                   
            }
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        if (PAD.canTrigger('AP45')) {
            for(Integer i=0; i<trigger.new.size();i++){
                if(Trigger.new[i].isActive && Trigger.new[i].cTin_Universign__c)
                    usrIdSet.add(Trigger.new[i].Id);                    
            }
        }

        // 19-JAN-2020  ARA   SP-03219
        UserTriggerHandler.afterUpdateHandler(Trigger.oldMap, Trigger.newMap);
    }
    
    //if(usrIdSet.size()>0 && AP45_ManageGroupMembers.bypassSpecial==false)
        // AP45_ManageGroupMembers.addMembers(usrIdSet);
}