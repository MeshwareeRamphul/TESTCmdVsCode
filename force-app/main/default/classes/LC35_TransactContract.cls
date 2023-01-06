public with sharing class LC35_TransactContract {
/*
----------------------------------------------------------------------
-- - Name          : LC35_TransactContract
-- - Author        : MRA
-- - Description   : Controller for lighning component LC35_TransactContract
--                   @reuse of VFC35_TransactContract
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 04-DEC-2019   MRA    1.0      Initial version 
--------------------------------------------------------------------------- */
   public static boolean allowClone=false;
   //methods checks if current user profile is allowed to transact and returns a map of result
   @AuraEnabled
    public static map<string,object> validateTransact(String contractId){
        allowClone=true;
        map<String,Object> mapOfResult = new map<String,Object>();
        //Block user from duplicaing if current user is a stakeholder
        String profileName=[Select Id,Name 
                            from Profile 
                            where Id=:userinfo.getProfileId()].Name;

        if(profileName.contains('Stakeholder')){
            mapOfResult.put('error',system.label.cTin_btnDuplicateError);
        }  
        else {
            system.debug('## LEX calling VFC32');
            //call VFC32_CloneContract to clone contract
            VFC35_TransactContract caller = new VFC35_TransactContract((Id)contractId);
            //caller.init(); 
            caller.InsertContractAndRelatedLists();  
            string err=caller.cloneStatus(); //capture  error thrown
            string newConId=caller.newContractId(); //capture id of cloned contract 
            
            if(err!='')
                mapOfResult.put('error',err);
            else
                mapOfResult.put('newcontact',newConId);
        }
        
        return mapOfResult;
    } 

}