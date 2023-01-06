public with sharing class LC12_ILCancel {
    /**************************************************************************************
    -- - Author        : Spoon consulting
    -- - Description   : Class to cancel an invoicing line
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    --              USA    1.0      Initial version
    -- 14-MAY-2020  ARA    1.1      SP-00252 
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    @AuraEnabled   
    public static void cancelIL(String ilId){
        System.debug('## LC12_ILCancel.cancelIL - Start');
        if(Schema.sObjectType.Planned_Invoicing_Line__c.isUpdateable()){
            Boolean isCancelable = false;
            Planned_Invoicing_Line__c currentIL = new Planned_Invoicing_Line__c();
            try{
                currentIL = [SELECT Id, Status__c 
                             FROM Planned_Invoicing_Line__c
                             WHERE ID = :ilId
                             LIMIT 1];     
            }catch(Exception ex){
                throw new AuraHandledException(ex.getMessage()); 
            }
            
            if(currentIL.Status__c == System.Label.InvLineStatus_Draft || currentIL.Status__c == System.Label.InvLineStatus_InvoicingValidation){
                String profileName = [Select Name from Profile where Id = :UserInfo.getProfileId() LIMIT 1][0].Name;
                List<String> lstProfiles = new List<String>{AP_Constant.functionalAdmin, AP_Constant.billingTeam, AP_Constant.accountManager, AP_Constant.contractManager, AP_Constant.productOwner, AP_Constant.dpLegal, AP_Constant.systemAdmin};
                if(lstProfiles.contains(profileName)){
                    isCancelable = true;
                }
            }
            
            if(isCancelable){
                try{
                    currentIL.Status__c = System.Label.InvLineStatusCancelled;
                    update currentIL;
                }catch (Exception e) {
                    throw new AuraHandledException(e.getMessage()); 
                }
            }
            else{
                throw new AuraHandledException( System.Label.Btn_CancelInvLine_Error); 
            }
        }
        else{
            AuraHandledException e = new AuraHandledException(System.Label.IL_Cancel_No_Right_Error);
            e.setMessage(System.Label.IL_Cancel_No_Right_Error);
            throw e;
        }
    }
}