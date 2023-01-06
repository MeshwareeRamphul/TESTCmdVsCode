public class AP29_ContractStatusControls{
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP29_ContractStatusControls
    -- - Author        : Spoon Consulting 
    -- - Description   : 
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 23-JUL-2019  USA   1.0      Initial version
    -- 19-AUG-2019  SGO   1.1      Error message displayed through custom labels
    -- 22-APR-2020  USA   1.2      SP-00258,SP-00278
    -- 11-MAY-2020  USA   1.3      SP-00260
    -- 17-JUN-2020  USA   1.4      SP-00320 (Code Optimisation)
	-- 28-JUN-2022  ARA   1.5      SP-03203 (Intraco contract | Enable contracts with no IL)
    --------------------------------------------------------------------------------------*/ 
        
    public static void controls_toInternalValition(map<Id,Contract__c> mapCtr){
        Boolean validated = true;
        String errorMsg = '';

        map<Id,Contract__c> mapCtrCorresponding = new map<Id,Contract__c>([SELECT Account__r.BillingCity, Account__r.BillingCountry, Account__r.BillingPostalCode, Account__r.BillingStreet, Account__r.Name,
                                                                            Account__r.MSA__c, Amendment_to__c, AXA_GS_Signed_By__r.Name, AXA_GS_Signed_By__r.Title, AXA_GO_Legal_Entity__c, CurrencyIsoCode,
                                                                            CustomerSignedBy__r.Name, CustomerSignedBy__r.Title, EndDate__c, Global_Amount__c, Invoicing_Condition__c, InvoicingMethod__c, Language__c,
                                                                            Name, PDFContrAtt__c, RecordType.developerName, Service_Started__c, ServiceType__c, SOW_Operational__c, StartDate__c,
                                                                            Planned_Invoicing_Lines_Amount__c, Account__r.MSA_ATS_Reference__c, SOW_Type__c, OpCo_IsILNotRequired__c,
                                                                            (SELECT Id, AmountIL__c, Description__c, Invoicing_Date__c, Percent__c, CurrencyIsoCode, Contract2__c, Status__c
                                                                            FROM Planned_Invoicing_Lines2__r
                                                                            WHERE Type__c = 'Invoicing Line')
                                                                            FROM Contract__c 
                                                                            WHERE id in:mapCtr.keySet()]);
        for (Contract__c ctr : mapCtrCorresponding.values()){
            errorMsg = ''; 
            if (ctr.Account__c == null){ 
                validated = false; 
                errorMsg += Label.AP29_ErrMsgLegalEntityMandatory + '\r\n '; 
            }
            if (ctr.StartDate__c == null){
            validated = false;
            errorMsg +=  Label.AP29_ErrMsgStartDateMandatory  + '\r\n ';
            }
            if (ctr.EndDate__c == null){
                validated = false;
                errorMsg += Label.AP29_ErrMsgEndDateMandatory + '\r\n ';
            }
            if (ctr.InvoicingMethod__c == null){
                validated = false; 
                errorMsg += Label.AP29_ErrMsgInvoicingMethodMandatory + '\r\n '; 
            }
            if (ctr.Invoicing_Condition__c == null){
                validated = false;
                errorMsg += Label.AP29_ErrMsgInvoicingConditionMandatory + '\r\n ';
            }
            if (ctr.Planned_Invoicing_Lines2__r.size() > 0){
                Decimal vPlannedInvSum = 0.0;
                for (Planned_Invoicing_Line__c vPlannedInvLine : ctr.Planned_Invoicing_Lines2__r) {
                    if (vPlannedInvLine.Status__c != '99'){
                        vPlannedInvSum += vPlannedInvLine.AmountIL__c.setScale(2, RoundingMode.HALF_UP);
                    }
                }
                if (ctr.Global_Amount__c != vPlannedInvSum){
                    validated = false;
                    errorMsg += Label.AP29_ErrMsgGlobalAmountDifferent + '\r\n ';
                }
            }
            if (ctr.AXA_GS_Signed_By__c == null){
                validated = false;
                errorMsg += Label.AP29_ErrMsgAxaGoSignedByMandatory + '\r\n ';
            }
            if (ctr.AXA_GS_Signed_By__r.Title == null){
                validated = false;
                errorMsg += Label.AP29_ErrMsgAxaGoSignedByTitleMandatory + '\r\n ';
            }
            if (ctr.Invoicing_Condition__c !=null && !ctr.Invoicing_Condition__c.contains('Per deliverable') && (ctr.Planned_Invoicing_Lines2__r.size() <= 0) && !ctr.OpCo_IsILNotRequired__c && (ctr.Global_Amount__c != 0)){
                validated = false; 
                errorMsg += Label.AP29_ErrMsgInvoicingLineMandatory + '\r\n '; 
            }
            if (ctr.SOW_Type__c == null){
                validated = false;
                errorMsg += Label.AP29_ErrMsgSOWTypeMandatory + '\r\n ';
            }
            system.debug('##AP29## errorMsg : ' + errorMsg);
            if (errorMsg != ''){
                mapCtr.get(ctr.Id).addError(errorMsg); 
            }
        }
    }
}