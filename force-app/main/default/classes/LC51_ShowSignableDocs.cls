public without sharing class LC51_ShowSignableDocs {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC51_ShowSignableDocs
    -- - Author        : MRA
    -- - Description   : Controller for lighning component LC51_ShowSignableDocs
    --                  
    --
    -- Maintenance History:
    --
    -- Date          Name   Version   Remarks
    -- -----------   ----   -------   ---------------------------------------
    -- 29-Sep-2021  MRA    1.0      Initial version                                  
    --------------------------------------------------------------------------- */

    
    @AuraEnabled
    public static map<string,object> getAttributes(String cfId){
        map<string,object> mapFieldValues=new map<string,object>();
        for(cTin_ContractForm__c  cf :[select id , CurrentUserIsApprover__c,Tech_hasSignableDoc__c,cTin_Confidential__c,cTin_ViewSignableDocuments__c
                                      from cTin_ContractForm__c  where id=:cfId]){
               if(cf.Tech_hasSignableDoc__c){
                   if(cf.cTin_Confidential__c){
                       if(!cf.CurrentUserIsApprover__c){
                            mapFieldValues.put('donotdisplay','true');
                       }
                       else{
                            mapFieldValues.put('displaydoc','true');
                        }      
                   }
                   else{
                        mapFieldValues.put('displaydoc','true');
                   }  
                  
                }
                else{
                      mapFieldValues.put('Nodocument','true');
                }
                                          
            
        }
        
         mapFieldValues.put('err','No document');
        return mapFieldValues;
        
    }
}