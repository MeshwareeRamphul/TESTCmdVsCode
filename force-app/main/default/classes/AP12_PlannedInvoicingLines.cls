public without sharing class AP12_PlannedInvoicingLines {
    /*
    ----------------------------------------------------------------------
    -- - Name          : AP12_PlannedInvoicingLines
    -- - Author        : Spoon Consulting 
    -- - Description   : class used by PlannedInvoicingLinesHandler
    --                                       
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    --                     1.0      Initial version
    -- 27-MAY-2022  ARA    1.1      SP-03382
    -- 07-JUN-2022  ARA    1.3      SP-02668 (Ensure IL currency same as contract)
    ----------------------------------------------------------------------
    **********************************************************************
    */

    /**
    * Calculates and updates the CurrentValue__c of the PDFContractAttached object when a relevant Planned Invoicing Line field is updated
    */

    //public static void updatePlannedInvoicingLinesCurrentValuePDF(Map<Id, Planned_Invoicing_Line__c> pOldPlannedInvoicingLineMap, Map<Id, Planned_Invoicing_Line__c> pPlannedInvoicingLineMap) {

    //    System.Debug('## AP12_PlannedInvoicingLines.updatePlannedInvoicingLinesCurrentValuePDF start');
    //    List<ID> vPlannedInvoicingLineToUpdate = new List<ID>();
    //    List<ID> vContractsToUpdate = new List<ID>();

    //    // Selects Planned Invoicing Line records where at least one of the fields on the PDF has changed
    //    for (Planned_Invoicing_Line__c vPlannedInvoicingLine : pPlannedInvoicingLineMap.values()) {
    //        if (vPlannedInvoicingLine.Description__c != pOldPlannedInvoicingLineMap.get(vPlannedInvoicingLine.Id).Description__c ||
    //            vPlannedInvoicingLine.Invoicing_Date__c != pOldPlannedInvoicingLineMap.get(vPlannedInvoicingLine.Id).Invoicing_Date__c ||
    //            vPlannedInvoicingLine.Percent__c != pOldPlannedInvoicingLineMap.get(vPlannedInvoicingLine.Id).Percent__c ||
    //            vPlannedInvoicingLine.Amount__c != pOldPlannedInvoicingLineMap.get(vPlannedInvoicingLine.Id).Amount__c) {
    //                //if(vPlannedInvoicingLine.RecordTypeId == Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Planned Invoicing Line').getRecordTypeId()){
    //                if(vPlannedInvoicingLine.Type__c == 'Planned Invoicing Line'){
    //                    vPlannedInvoicingLineToUpdate.add(vPlannedInvoicingLine.Contract2__c);
    //                }
    //                System.Debug('selected invoicing line');
    //        }
    //    }

    //    // Selects related Contract records with a PDF Attachment record and with editable status
    //    for (Contract__c vContract : [SELECT Id FROM Contract__c WHERE Id IN :vPlannedInvoicingLineToUpdate AND Status__c !='Signed' AND Status__c !='Ended' AND Status__c !='Terminated']){
    //        vContractsToUpdate.add(vContract.Id);
    //        System.Debug('selected relevant contract');
    //    }

    //    AP12_PDFContractsAttached.updatePDFContractsAttachedCurrentValue (vContractsToUpdate);
    //    System.Debug('## AP12_PlannedInvoicingLines.updatePlannedInvoicingLinesCurrentValuePDF end');
    //}
    
    public static set<String> setCtrStatus = new set<String>{System.Label.ContractStatus_Draft, System.Label.ContractStatus_InternalValidation, System.Label.ContractStatus_CustomerValidation, System.Label.ContractStatus_ReadyForSignature, System.Label.ContractStatus_SentForSignature};
    //07-JUN-2022  ARA  SP-02668 (Ensure IL currency same as contract)
    //27-MAY-2022 ARA SP-03382
    public static void initializeFields(List<Planned_Invoicing_Line__c> newPlannedInvoicingLines, Set<Id> concernContractsID){
        Map<Id, Contract__c> mapCtr = new Map<Id, Contract__c>([SELECT Id, Customer_Operational_Contact__r.TECH_Name__c, CurrencyIsoCode FROM Contract__c WHERE Id =: concernContractsID]);
        for(Planned_Invoicing_Line__c pil : newPlannedInvoicingLines){
            if(pil.Customer_Contact_name__c == null){
                if(mapCtr.get(pil.Contract2__c).Customer_Operational_Contact__c != null){
                    pil.Customer_contact_name__c = (mapCtr.get(pil.Contract2__c).Customer_Operational_Contact__r.TECH_Name__c).replace('-',' ');
                }  																			 
            }else{
                pil.Customer_contact_name__c = pil.Customer_contact_name__c.replace('-',' ');
            }
            pil.CurrencyIsoCode = mapCtr.get(pil.Contract2__c).CurrencyIsoCode;
        }
    }

    public static void updatePDFContractsAttached(List<Planned_Invoicing_Line__c> newPlannedInvoicingLines, Set<Id> concernContractsID){
        System.debug(LoggingLevel.INFO, '## AP12_PlannedInvoicingLines.updatePDFContractsAttached Start');

        List<Id> concernPDFContractAttachsID = new List<Id>();
        List<Contract__c> concernContracts = new List<Contract__c>();
        List<PDFContractAttached__c> concernPDFContractAttachs = new List<PDFContractAttached__c>();

        for(Contract__c concernContract :[SELECT Id, PDFContrAtt__c FROM Contract__c WHERE Id =: concernContractsID]){
            concernPDFContractAttachsID.add(concernContract.PDFContrAtt__c);
            System.debug('## AP12_PlannedInvoicingLines GOT PDFContrAtt__c: '+ concernContract.PDFContrAtt__c);
        }
        if (concernPDFContractAttachsID.size() > 0){
            for(PDFContractAttached__c pdfContractAttached : [SELECT Id, PDFStatus__c FROM PDFContractAttached__c WHERE Id =: concernPDFContractAttachsID]){
                pdfContractAttached.PDFStatus__c = 'Not Updated!';
                System.debug('## AP12_PlannedInvoicingLines Updating one ');
                concernPDFContractAttachs.add(pdfContractAttached);
            }
        }
        if (concernPDFContractAttachs.size() > 0){
            update concernPDFContractAttachs;
        }

        System.debug(LoggingLevel.INFO, '## AP12_PlannedInvoicingLines.updatePDFContractsAttached End');
    }
    

    /**
     * Method updateWBSInformations : will push the new WBS informations to the planned invoicing line
     * @param newPlannedInvoicingLines List<Planned_Invoicing_Line__c> : send by the trigger.
     */
    public static void updateWBSInformations(List<Planned_Invoicing_Line__c> newPlannedInvoicingLines){
        // System debug call for debug log purpose
        System.debug(LoggingLevel.DEBUG, '##AP12_PlannedInvoicingLines## updateWBSInformations start');

        List<Id> contractId = new List<Id>();
        for(Planned_Invoicing_Line__c newPlannedInvoicingLine : newPlannedInvoicingLines){
            contractId.add(newPlannedInvoicingLine.Contract2__c);
        }
        Map<Id,Contract__c> contracts = new Map<Id, Contract__c>([SELECT Id, Master_WBS_2__c FROM Contract__c WHERE Id in :contractId]);

        // For each planned invoicing line, if the contract is specified and the WBS is null at PIL level, we will update the
        // WBS
        for(Planned_Invoicing_Line__c newPlannedInvoicingLine : newPlannedInvoicingLines){
            system.debug('## wbs newPlannedInvoicingLine.Master_WBS_Structure__c : ' + newPlannedInvoicingLine.Master_WBS_Structure__c);
            if(newPlannedInvoicingLine.Contract2__c != null){
                if(newPlannedInvoicingLine.Master_WBS_Structure__c == null){
                    if(contracts.get(newPlannedInvoicingLine.Contract2__c).Master_WBS_2__c != null){
                        newPlannedInvoicingLine.Master_WBS_Structure__c = contracts.get(newPlannedInvoicingLine.Contract2__c).Master_WBS_2__c;
                    }

                }
            }
        }
        // System debug call for debug log purpose
        System.debug(LoggingLevel.DEBUG, '##AP12_PlannedInvoicingLines## updateWBSInformations end');
    }

    /**
     * <b>Method updateILsStatusDescription </b>: update the status description for all IL
     * @param plannedInvoicingLines (List<Planned_Invoicing_Line__c>) : all the planned invoicing line send by the trigger.
     */
    public static void updateILsStatusDescription(List<Planned_Invoicing_Line__c> plannedInvoicingLines){

        //For each plannedInvoicignLine, we are applying the updateILStatusDescription method.
        for(Planned_Invoicing_Line__c plannedInvoicingLine : plannedInvoicingLines){
            plannedInvoicingLine = setStatusDescription(plannedInvoicingLine);
        }
    }

    /*
     * <b>Method updateILStatusDescription </b>: this method will update the field Contract Status
     * @param plannedInvoicingLine (Planned_Invoicing_Line__c) : a planned invoicing line for which we want to update the field Status_Description__c
     */
    /*private static void updateILStatusDescription(Planned_Invoicing_Line__c plannedInvoicingLine){
        // System debug call for debug log purpose
        //System.debug(LoggingLevel.INFO, '##AP12_PlannedInvoicingLines## updateILStatusDescription start');

        // Emptying the field Status_Description__c
        plannedInvoicingLine.Status_Description__c = null;

        if(plannedInvoicingLine.Status__c != '03' &&
           plannedInvoicingLine.Status__c != '04' &&
            plannedInvoicingLine.Status__c != '99' ){
            // Testing if purchased order field is checked
            if(plannedInvoicingLine.Purchase_Order__c){
                if(((plannedInvoicingLine.N_Purchase_Order__c == '') ||
                                    (plannedInvoicingLine.N_Purchase_Order__c == null)) && 
                    (plannedInvoicingLine.PurchaseOrder__c == null) ){
                        plannedInvoicingLine.Status_Description__c = System.Label.InvoicingLine_StatusDescription_PoMissing;
                }
            }
            else{
                if((plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_Draft) ||
                    (plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_InternalValidation) ||
                    (plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_Validated) ||
                    (plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_CustomerValidation) ||
                    (plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_ReadyForSignature) ||
                    (plannedInvoicingLine.Contract_Status__c == System.Label.ContractStatus_SentForSignature)){
                        plannedInvoicingLine.Status_Description__c = System.Label.InvoicingLine_StatusDescription_SignatureMissing;
                }
            }
        }

        // System debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '##AP12_PlannedInvoicingLines## updateILStatusDescription end');
    }*/
    
    /**
    * // Updates Invoicing Lines Status
    */
    public static void updateStatus(Map<Id, Planned_Invoicing_Line__c> pOldInvoicingLineMap, Map<Id, Planned_Invoicing_Line__c> pInvoicingLineMap) {
        System.debug('## AP12_PlannedInvoicingLines.updateStatus start');
        //Were going to create a list with
        Map<Id, Planned_Invoicing_Line__c> tempMap = new Map<Id, Planned_Invoicing_Line__c>();
        for(Planned_Invoicing_Line__c vInvoicingLine : pInvoicingLineMap.values()){
            if(vInvoicingLine.Type__c == 'Invoicing Line'){tempMap.put(vInvoicingLine.Id, vInvoicingLine);}
        }

        //For each planned_invoicing_line with the record type Invoicing_Line
        for (Planned_Invoicing_Line__c vInvoicingLine : tempMap.values()) {

            // Updates the value of SO_ITEM__c if SO__c or ITEM__c have been updated and are
            // different from null. If SO__c and ITEM__c are null, then sets SO_ITEM__c to empty string
            // Note that the field SO__c should only be set by an upload from an SAP export (file)
            if (vInvoicingLine.SO__c != null && vInvoicingLine.ITEM__c != null) {
                if (vInvoicingLine.SO__c != pOldInvoicingLineMap.get(vInvoicingLine.Id).SO__c || vInvoicingLine.ITEM__c != pOldInvoicingLineMap.get(vInvoicingLine.Id).ITEM__c) {                    vInvoicingLine.SO_ITEM__c = vInvoicingLine.SO__c + '-' + vInvoicingLine.ITEM__c;
                }
            } else {vInvoicingLine.SO_ITEM__c = '';
            }

            // If there is an invoice number then move to invoiced
            //if (vInvoicingLine.N_Invoice__c != null && vInvoicingLine.N_Invoice__c != '') {vInvoicingLine.Status__c = System.Label.InvLineStatus_Invoiced;
                //vInvoicingLine.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine ReadOnly').getRecordTypeId();/

                // If also the field Paid_Not_Paid__c == 'X'
                // then it sets the status to "Paid"
                //  if (vInvoicingLine.Payment_Document_Number__c == 'CLEARED') {
                if (vInvoicingLine.Paid_Not_Paid__c) {vInvoicingLine.Status__c = System.Label.InvLineStatus_Paid;}
            //} 
        }
        System.debug('## AP12_PlannedInvoicingLines.updateStatus end ');
    }


    /**
     * <b>Methods updateTechGIESASField </b>: update the tech field at the creation of the Invoicing Line
     * @param newPlannedInvoicingLines List<Planned_Invoicing_Line__c> : list of invoicing line newly created
     */
    public static void updateTechGIESASField(List<Planned_Invoicing_Line__c> newPlannedInvoicingLines, Set<Id> concernContractsIds) {
        // System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## AP12_PlannedInvoicingLines.updateTechGIESASField start');

        // Variables declarations
        Map<Id, Contract__c> concernContracts;

        // Getting all the contract concern by the invoicing line
        concernContracts = new Map<Id, Contract__c>([SELECT Id, AXA_GO_Legal_Entity__c, Customer_Operational_Contact__c, Master_WBS_2__c FROM Contract__c WHERE Id IN: concernContractsIds]);

        // For each Invoicing Line
        for(Planned_Invoicing_Line__c newPlannedInvoicingLine : newPlannedInvoicingLines){
            if(concernContracts.get(newPlannedInvoicingLine.Contract2__c).Master_WBS_2__c != null)
                newPlannedInvoicingLine.TECH_GIE_SAS__c = concernContracts.get(newPlannedInvoicingLine.Contract2__c).AXA_GO_Legal_Entity__c;
            else{
                newPlannedInvoicingLine.TECH_GIE_SAS__c = null;
            }
            // Only for new IL
            /*if(newPlannedInvoicingLine.Id == null){
                newPlannedInvoicingLine.Customer_Contact__c = concernContracts.get(newPlannedInvoicingLine.Contract2__c).Customer_Operational_Contact__c;
            }*/
        }

        // System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## AP12_PlannedInvoicingLines.updateTechGIESASField end');
    }


    //public static void updateWBSatIlUpdate(Set<Id> ILwithNewWBSet, map<Id, Planned_Invoicing_Line__c> newPlannedInvoicingLines){
    //    //Variables declarations
    //    System.debug('## AP12_PlannedInvoicingLines ## updateWBSatIlUpdate Start');

    //    // ASE : 2017/06/21 : correction following bug on invoicing.
    //    Set<Id> tempSet = new set<Id>();
    //    Set<Id> pilIdSet = new Set<Id>();
    //    Map<Id, Planned_Invoicing_Line__c> PILToUpdateMap = new Map<Id, Planned_Invoicing_Line__c>();

    //    for(Id plannedInvoicingLineId : ILwithNewWBSet){
    //        Planned_Invoicing_Line__c pil = newPlannedInvoicingLines.get(plannedInvoicingLineId);
    //        if(pil.RecordTypeId == Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Invoicing Line').getRecordTypeId()){
    //            System.debug(LoggingLevel.ERROR, pil.Planned_Invoicing_Line__c);
    //            pilIdSet.add(pil.Planned_Invoicing_Line__c);
    //            tempSet.add(pil.Id);
    //        }
    //    }
    //    // select info from PIL
    //    map<Id, Planned_Invoicing_Line__c> selectedPILMap = new map<Id, Planned_Invoicing_Line__c>([  SELECT Id, Contract_Status__c, Master_WBS_Structure__c, RecordTypeId, Planned_Invoicing_Line__c
    //                                                                                                  FROM Planned_Invoicing_Line__c
    //                                                                                                  WHERE Id IN: pilIdSet]);
    //    for(Id selectedPILId : selectedPILMap.keySet()){
    //        Planned_Invoicing_Line__c selectedPIL = selectedPILMap.get(selectedPILId);
    //        if(pilIdSet.contains(selectedPIL.Id)){
    //            system.debug('## NON PIL');
    //            for(Id plannedInvoicingLineId : tempSet){
    //                Planned_Invoicing_Line__c newPIL = newPlannedInvoicingLines.get(plannedInvoicingLineId);
    //                if(newPIL != null && newPIL.Planned_Invoicing_Line__c != null){
    //                    Planned_Invoicing_Line__c updatedPIL = selectedPILMap.get(newPIL.Planned_Invoicing_Line__c);
    //                    if(!PILToUpdateMap.containsKey(updatedPIL.Id)){
    //                        PILToUpdateMap.put(updatedPIL.Id, new Planned_Invoicing_Line__c( Id = updatedPIL.Id
    //                                                                                        ,Master_WBS_Structure__c = newPIL.Master_WBS_Structure__c));
    //                    }
    //                }
    //            }
    //        }
    //    }

    //    system.debug('## PILToUpdateMap:'+PILToUpdateMap);
    //    if(PILToUpdateMap.size() > 0){
    //        update PILToUpdateMap.values();
    //    }

    //    System.debug('## AP12_PlannedInvoicingLines ## updateWBSatIlUpdate End');
    //}

    //USA 20170604 : ALLINFIN-490
    //public static void updateInvoicingdate(map<Id,Planned_Invoicing_Line__c> pOldPlannedInvoicingLineMap, map<Id,Planned_Invoicing_Line__c> pNewPlannedInvoicingLineMap){
        //System.debug('## AP12_PlannedInvoicingLines ## updateInvoicingdate Begin');
        //List<Invoicing_parameter__c> lstInvParam = [SELECT invoicing_date__c
        //                                            FROM invoicing_parameter__c
        //                                            WHERE parameter_type__c = 'Invoicing Date'
        //                                            AND invoicing_date__c >= TODAY
        //                                            ORDER BY invoicing_date__c
        //                                            LIMIT 1];

        //for (Id idInv : pNewPlannedInvoicingLineMap.keySet()){
        //    //USA 20171010 : ALLINFIN-517
        //    //if ((pNewPlannedInvoicingLineMap.get(idInv).RecordTypeId == Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()) && (pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c == NULL) && (lstInvParam.size() > 0 )){
        //    //    pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c = lstInvParam[0].Invoicing_Date__c;
        //    //}

        //    //USA 20171107 : ALLINFIN-517
        //    //if ((pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c > Date.today()) && (lstInvParam.size() > 0 )){
        //    //    pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c = lstInvParam[0].Invoicing_Date__c;
        //    //}

        //    //USA 20170604 : ALLINFIN-490
        //    if ((pNewPlannedInvoicingLineMap.get(idInv).ADV_GoNoGo__c != pOldPlannedInvoicingLineMap.get(idInv).ADV_GoNoGo__c) &&
        //        (pNewPlannedInvoicingLineMap.get(idInv).ADV_GoNoGo__c == 'GO') &&
        //        (pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c != NULL) &&
        //        (pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c < Date.today()) &&
        //        (lstInvParam.size() > 0) ){
        //        pNewPlannedInvoicingLineMap.get(idInv).Invoicing_Date__c = lstInvParam[0].Invoicing_Date__c;
        //    }
        //}
        //System.debug('## AP12_PlannedInvoicingLines ## updateInvoicingdate End');
    //}
    
    /*
     * <b>Method setStatusDescription </b>: this method will update the field Status description
     * @param plannedInvoicingLine (Planned_Invoicing_Line__c) : a planned invoicing line for which we want to update the field Status_Description__c
     */
    public static Planned_Invoicing_Line__c setStatusDescription(Planned_Invoicing_Line__c pil){
        if(pil.Status__c == '03' || pil.Status__c == '04' || pil.Status__c == '99'){
            if(pil.Status_Description__c != ''){
                pil.Status_Description__c = '';
            }
        }else{
            system.debug('*****pil.Purchase_Order__c '+pil.Purchase_Order__c);
            Boolean isFillOut = true;
            if(pil.Purchase_Order__c){
                if(pil.PurchaseOrder__c == null && pil.N_Purchase_Order__c == null){
                    if(pil.Status_Description__c != System.Label.InvoicingLine_StatusDescription_PoMissing){
                        pil.Status_Description__c = System.Label.InvoicingLine_StatusDescription_PoMissing;
                    }
                }else{
                    isFillOut = false;
                }
            }else if(setCtrStatus.contains(pil.Contract_Status__c)){
                if(pil.Status_Description__c != System.Label.InvoicingLine_StatusDescription_SignatureMissing){
                    pil.Status_Description__c = System.Label.InvoicingLine_StatusDescription_SignatureMissing;
                }
            }else {
                isFillOut = false;
            }
            system.debug('*****isFillOut '+isFillOut);
            if(!isFillOut){
                if(pil.GoNoGo__c != 'GO'){
                    if(pil.Status_Description__c != System.Label.InvoicingLine_StatusDescription_PendingBillingRequesterGO){
                        pil.Status_Description__c = System.Label.InvoicingLine_StatusDescription_PendingBillingRequesterGO;
                    }
                }else if(pil.ADV_GoNoGo__c != 'GO'){
                    if(pil.Status_Description__c != System.Label.InvoicingLine_StatusDescription_PendingBillingTeamGO){pil.Status_Description__c = System.Label.InvoicingLine_StatusDescription_PendingBillingTeamGO;
                    }
                }else if(pil.Status_Description__c != System.Label.InvoicingLine_StatusDescription_ToBeInvoiced){pil.Status_Description__c = System.Label.InvoicingLine_StatusDescription_ToBeInvoiced;
                }
            } 
        }
            //system.debug('*****pil.Status_Description__c '+pil.Status_Description__c);

        return pil;
    }

    public static void checkDeleteRight(Map<Id, Planned_Invoicing_Line__c> mapNewPIL){
        List<String> lstProfiles = new List<String>{AP_Constant.functionalAdmin, AP_Constant.billingTeam, AP_Constant.accountManager,AP_Constant.accountManager};
        User currentUser = [SELECT id, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];

        if (lstProfiles.contains(currentUser.profile.name)){
            for(Planned_Invoicing_Line__c pil : mapNewPIL.values()){
                if(pil.Status__c != '01' && !pil.IsRunningSendToPs__c){
                    pil.addError(System.Label.InvoicingLine_CannotDelete);
                    break;
                }
            }
        }
    }
}