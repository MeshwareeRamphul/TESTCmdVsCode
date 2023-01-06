public with sharing class LC14_ILClone {
    /**************************************************************************************
    -- - Author        : Spoon consulting
    -- - Description   : Class to clone an invoicing line
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    --              USA    1.0      Initial version
    -- 14-MAY-2020  ARA    1.1      SP-00252 
    -- 27-MAY-2022  ARA    1.2      SP-03382
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    @AuraEnabled   
    public static String cloneInvoicingLine(String iLId){
        if(Schema.sObjectType.Planned_Invoicing_Line__c.isCreateable()){
            //List<String> setStatus = AP_Constant.getPickListValuesIntoListIL();
            //System.debug('## LC14_ILClone setStatus ' + setStatus);
            
            System.debug('## LC14_ILClone.cloneInvoicingLine start.');
            List<Planned_Invoicing_Line__c> currentIL = [SELECT Name, Contract2__c, Type__c, AmountIL__c/*, Invoicing_Predefined_Date__c*/, Inv_Predefined_Date__c, 
                                                         CurrencyIsoCode, Description__c, Percent__c, Master_WBS_Structure__c,
                                                         Tech_AXA_GS_Legal_Entity__c, TestSap__c,Customer_Contact_name__c,
                                                         Status__c, SO__c, ITEM__c, PS_BillingDate__c, N_Invoice__c, PS_Message__c
                                                         , PS_ConnectionMessage__c, Paid_Not_Paid__c, Payment_Document_Number__c,
                                                         Activity_Type__c,Activity_Description__c,Status_Description__c,
                                                         PurchaseOrder__c,ADV_Comments__c,PMO_Comments__c, N_Purchase_Order__c, StartDate__c,EndDate__c,
                                                         Invoicing_Date__c, RecordTypeId
                                                         FROM Planned_Invoicing_Line__c WHERE Id =:iLId LIMIT 1];
            if ( currentIL.size() == 0 ){
                return System.Label.IL_Not_Found_To_Clone;
            }
            
            Planned_Invoicing_Line__c clonedIL = currentIL[0].clone(false, true, false, false); //Deep clone
            if(currentIL[0].Type__c == 'Invoicing Line'){
                clonedIL.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
                clonedIL.Planned_Invoicing_Line__c = null;
                clonedIL.Status__c = '01';
                clonedIL.SO__c = '';
                clonedIL.ITEM__c = '';
                clonedIL.PS_BillingDate__c = null;
                clonedIL.N_Invoice__c = null;
                clonedIL.PS_Message__c = '';
                clonedIL.PS_ConnectionMessage__c = '';
                clonedIL.Paid_Not_Paid__c = false;
                clonedIL.Payment_Document_Number__c = '';
                clonedIL.ILYear__c = null;
            }
            
            try {
                insert clonedIL;
            } 
            catch (Exception e) {
                return 'Technical error occured : ' + e.getMessage();
            }
            return clonedIL.Id;
        }else{
            return System.Label.IL_Clone_No_Right_Error;
        }
    } 
}