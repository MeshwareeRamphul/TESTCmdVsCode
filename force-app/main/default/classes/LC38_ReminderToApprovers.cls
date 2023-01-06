public with sharing class LC38_ReminderToApprovers {
/*
----------------------------------------------------------------------
-- - Name          : LC38_ReminderToApprovers
-- - Author        : SPOON
-- - Description   : Controller for lighning component LC38_ReminderToApprovers
--                   @reuse of VFC38_ReminderToAprovers
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 29-JAN-2020   SGO    1.0      Initial version 
--------------------------------------------------------------------------- */

    @AuraEnabled
    public static map<string,object> remind(String contractFormId){

        map<String,Object> mapOfResult = new map<String,Object>();
        try{
            // LEX call VFC38_ReminderToAprovers
            VFC38_ReminderToAprovers caller = new VFC38_ReminderToAprovers(contractFormId);
            caller.sendReminder();
            mapOfResult.put('success', contractFormId);

        }
        catch(Exception e){
            // System.debug('@@ error : ' + e.getMessage());
            mapOfResult.put('error', e.getMessage());
        }
        
        System.debug('@@ mapOfResult : ' + mapOfResult);
        return mapOfResult;
    }

}