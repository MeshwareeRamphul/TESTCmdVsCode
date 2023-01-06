public with sharing class LC39_AbortContract {
/*
----------------------------------------------------------------------
-- - Name          : LC39_AbortContract
-- - Author        : SPOON
-- - Description   : Controller for lightning component LC39_AbortContract
-- - Maintenance History:
--
-- - Date          Name   Version   Remarks
-- - -----------   ----   -------   ---------------------------------------
--   26-FEB-2020   SGO    1.0      Initial version 
--------------------------------------------------------------------------- */

    @AuraEnabled
    public static string abort(String contractId){
        List<Contract__c> lstCtrs = new List<Contract__c>();
        String message = '';

        try{
            lstCtrs = [SELECT Id, Name, Status__c FROM Contract__c WHERE Id = :contractId];
            if (lstCtrs[0].Status__c == 'Draft' || lstCtrs[0].Status__c == 'In Progress'){
                lstCtrs[0].Status__c = 'Aborted';
                update lstCtrs;
                message = System.Label.LC39_CtrAbortSuccess;
            }
            else if (lstCtrs[0].Status__c == 'Aborted'){
                message = System.Label.LC39_AlreadyAbort;
            }
            else{
                message = System.Label.LC39_CtrAbortFailed;
            }
        }
        catch(Exception ex){
            System.debug('An exception occured : ' + ex.getMessage());
            message = ex.getMessage();
        }

        return message;
    }

}