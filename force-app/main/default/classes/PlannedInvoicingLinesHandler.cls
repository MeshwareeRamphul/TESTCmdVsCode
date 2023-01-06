/* 
--------------------------------------------------------------------------------------
-- - Name          : PlannedInvoicingLinesHandler
-- - Author        : Spoon Consulting 
-- - Description   : PlannedInvoicingLines handler
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 23-MAY-2018  USA    1.0     Initial version
-- 29-OCT-2018  USA    1.1     Integration PeopleSoft
-- 27-MAY-2022  ARA    1.2     SP-03382
-- 07-JUN-2022  ARA    1.3     SP-02668 (Ensure IL currency same as contract)
************************************************************************************/
public without sharing class PlannedInvoicingLinesHandler {

	public static void handleAfterInsert(List<Planned_Invoicing_Line__c> lstPIL_New){

	}

	public static void handleBeforeInsert(List<Planned_Invoicing_Line__c> lstPIL_New){
        Set<Id> concernContractsIds = new Set<Id>();

		for (Planned_Invoicing_Line__c pil : lstPIL_New) {
			concernContractsIds.add(pil.Contract2__c);
        }

        if(PAD.canTrigger('AP12')){
            AP12_PlannedInvoicingLines.updateWBSInformations(lstPIL_New);
        }
		if (PAD.canTrigger('AP112')) {
			AP12_PlannedInvoicingLines.updateILsStatusDescription(lstPIL_New);
		}
        if (concernContractsIds.size() > 0){
        	AP12_PlannedInvoicingLines.updateTechGIESASField(lstPIL_New, concernContractsIds);
        	AP12_PlannedInvoicingLines.updatePDFContractsAttached(lstPIL_New, concernContractsIds);
			//07-JUN-2022  ARA  SP-02668 (Ensure IL currency same as contract)
			//27-MAY-2022  ARA  SP-03382
			if(PAD.canTrigger('AP123')){
				AP12_PlannedInvoicingLines.initializeFields(lstPIL_New, concernContractsIds);
			}
        }
	}

	public static void handleAfterUpdate(Map<Id, Planned_Invoicing_Line__c> pOldPlannedInvoicingLineMap, Map<Id, Planned_Invoicing_Line__c> pPlannedInvoicingLineMap){
		
		List<ID> vPlannedInvoicingLineToUpdateAP112 = new List<ID>();

        for (Planned_Invoicing_Line__c pil : pPlannedInvoicingLineMap.values()) {
        	if (PAD.canTrigger('AP112')) {
				//if (pil.Invoicing_Predefined_Date__c != pOldPlannedInvoicingLineMap.get(pil.Id).Invoicing_Predefined_Date__c ||
				if (pil.Inv_Predefined_Date__c != pOldPlannedInvoicingLineMap.get(pil.Id).Inv_Predefined_Date__c ||
	            	//pil.Invoicing_Date__c != pOldPlannedInvoicingLineMap.get(pil.Id).Invoicing_Date__c || 
	                //pil.Percent__c != pOldPlannedInvoicingLineMap.get(pil.Id).Percent__c ||
	                pil.AmountIL__c != pOldPlannedInvoicingLineMap.get(pil.Id).AmountIL__c) {
	                    if(pil.Type__c == 'Invoicing Line'){
	                        vPlannedInvoicingLineToUpdateAP112.add(pil.Contract2__c);
	                    }
	            }
	        }
        }

        if (vPlannedInvoicingLineToUpdateAP112.size() > 0){
        	AP12_PDFContractsAttached.updatePDFContractsAttachedCurrentValue (vPlannedInvoicingLineToUpdateAP112);
        }
	}

	public static void handleBeforeUpdate(Map<Id, Planned_Invoicing_Line__c> pOldPlannedInvoicingLineMap, Map<Id, Planned_Invoicing_Line__c> pPlannedInvoicingLineMap){
        Set<Id> concernContractsIds = new Set<Id>();

		for (Planned_Invoicing_Line__c pil : pPlannedInvoicingLineMap.values()) {
			// 27-MAY-2022  ARA  SP-03382
			if(pil.Customer_contact_name__c != null && pil.Customer_contact_name__c.contains('-')){
				pil.Customer_contact_name__c = pil.Customer_contact_name__c.replace('-', ' ');
			}
        	if (PAD.canTrigger('AP112')) {
        		concernContractsIds.add(pil.Contract2__c);
        	}
        }

        if (concernContractsIds.size() > 0){
        	AP12_PlannedInvoicingLines.updateTechGIESASField(pPlannedInvoicingLineMap.values(), concernContractsIds);
        }
        if(PAD.canTrigger('AP12')){
            AP12_PlannedInvoicingLines.updateWBSInformations(pPlannedInvoicingLineMap.values());
        }
        if (PAD.canTrigger('AP112')) {
            AP12_PlannedInvoicingLines.updateStatus(pOldPlannedInvoicingLineMap, pPlannedInvoicingLineMap);
            AP12_PlannedInvoicingLines.updateILsStatusDescription(pPlannedInvoicingLineMap.values());
        }
    }

	public static void handleBeforeDelete(Map<Id, Planned_Invoicing_Line__c> mapOldPIL){
        if (PAD.canTrigger('AP112')) {
            AP12_PlannedInvoicingLines.checkDeleteRight(mapOldPIL);
        }
	}
}