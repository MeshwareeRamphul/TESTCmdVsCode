public without sharing class LC48_RecallContractForm {
/*
----------------------------------------------------------------------
-- - Name          : LC48_RecallContractForm
-- - Author        : MRA
-- - Description   : Controller for lighning component LC48_RecallContractForm
--                   @reuse of VFC48_RecallContractForm
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 08-MAY-2020   MRA    1.0      Initial version 
--------------------------------------------------------------------------- */
   
  
   @AuraEnabled
    public static map<string,object> callVFCMethod(String ctrId){
            string success='';
            string err='';
            map<String,Object> mapOfResult = new map<String,Object>();
        
            system.debug('## LEX calling VFC48');
            try{
                //call VFC48_RecallContractForm to clone contract
                VFC48_RecallContractForm caller = new VFC48_RecallContractForm((Id)ctrId);
                caller.processRecall();
                mapOfResult.put('ok','ok');
            }
            catch (exception e){
               mapOfResult.put('err',e.getMessage());
            }
            
        
        return mapOfResult;
    } 
}