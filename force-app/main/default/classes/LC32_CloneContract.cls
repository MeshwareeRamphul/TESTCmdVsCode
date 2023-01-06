public with sharing class LC32_CloneContract {
/*
----------------------------------------------------------------------
-- - Name          : LC32_CloneContract
-- - Author        : MRA
-- - Description   : Controller for lighning component LC32_CloneContract
--                   @reuse of VFC32_clonecontract
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 04-DEC-2019   MRA    1.0      Initial version 
--------------------------------------------------------------------------- */
    
    public static boolean allowClone=false;
   //methods checks if current user profile is allowed to clone and returns a map of result
   @AuraEnabled
    public static map<string,object> validateClone(String contractId){
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
            VFC32_CloneContract caller = new VFC32_CloneContract((Id)contractId);
            caller.init(); 
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