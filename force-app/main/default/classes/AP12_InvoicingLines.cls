/**
 * <b>Class AP12_InvoicingLines </b>: method to be called by the invoicing line trigger
 * @author Eric Wartelle, ....
 * @version 1.1
 * @history 1.1 : can pass from 03-READY FOR INVOICE to 04-INVOICING VALIDATION if the contract is 'Ended'
 *          1.0 : original version
 */
public with sharing class AP12_InvoicingLines {

    public AP12_InvoicingLines(){
        
    }
    ///**
    //* // Updates Invoicing Lines Status
    //*/
    //public static void updateStatus(Map<Id, Invoicing_Line__c> pOldInvoicingLineMap, Map<Id, Invoicing_Line__c> pInvoicingLineMap) {

    //    for (Invoicing_Line__c vInvoicingLine : pInvoicingLineMap.values()) {


    //        // Updates the value of SO_ITEM__c if SO__c or ITEM__c have been updated and are
    //        // different from null. If SO__c and ITEM__c are null, then sets SO_ITEM__c to empty string
    //        // Note that the field SO__c should only be set by an upload from an SAP export (file)
    //        if (vInvoicingLine.SO__c != null && vInvoicingLine.ITEM__c != null) {

    //            if (vInvoicingLine.SO__c != pOldInvoicingLineMap.get(vInvoicingLine.Id).SO__c ||
    //                vInvoicingLine.ITEM__c != pOldInvoicingLineMap.get(vInvoicingLine.Id).ITEM__c) {
    //                vInvoicingLine.SO_ITEM__c = vInvoicingLine.SO__c + '-' + vInvoicingLine.ITEM__c;
    //            }

    //        } else {
    //            vInvoicingLine.SO_ITEM__c = '';
    //        }

    //        if (vInvoicingLine.Contract_Status__c != AP_Constant.CONTRACT_STATUS_ENDED
    //            && vInvoicingLine.Contract_Status__c != AP_Constant.CONTRACT_STATUS_TERMINATED) {
    //            System.debug('##EWA## Contract status is not ended or terminated');

    //            // Checks if conditions are met to progressively update the status from Draft.
    //            // The conditions below  (that include prefilled fields from Contract, Legal Entity, and Invocing Lines) require
    //            // also the field Invoicing_WBS__c and Activity_Type__c to have a value differen from null, to set the status "Ready for SAP"
    //            // add invoice number as null to forced line status in Invoiced or Pai


    //            if (vInvoicingLine.AXA_GS_Legal_Entity__c != null && vInvoicingLine.SAP_Account_Number__c != null &&
    //                    vInvoicingLine.Customer_Operational_Contact__c != null && vInvoicingLine.Customer_Operational_Contact_Email__c != null &&
    //                    vInvoicingLine.Solution__c != null && vInvoicingLine.Service_Type__c != null && vInvoicingLine.Contract_Start_Date__c != null &&
    //                    vInvoicingLine.Contract_End_Date__c != null && vInvoicingLine.AXA_GS_Project_Manager__c != null &&
    //                    vInvoicingLine.SAP_ID__c != null && vInvoicingLine.Activity_Type__c != null &&
    //                    vInvoicingLine.Master_WBS_Structure__c != null && vInvoicingLine.Man_days__c != null && vInvoicingLine.Rate__c != null &&
    //                    vInvoicingLine.Amount__c != 0 && vInvoicingLine.Invoicing_Date__c != null &&
    //                    vInvoicingLine.N_Invoice__c == null || vInvoicingLine.N_Invoice__c == '') {


    //                // Set status to ready for SAP
    //                vInvoicingLine.Status__c = System.Label.InvLineStatus_ReadyForSAP;

    //                // If also SO__c, ITEM__c, and ADV_Comments__c have a value different from null, the status is set to "SO Created"
    //                if (vInvoicingLine.SO__c != null && vInvoicingLine.ITEM__c != null && vInvoicingLine.ADV_Comments__c != null) {

    //                    vInvoicingLine.Status__c = System.Label.InvLineStatus_SOCreated;

    //                    // If also the field PMO_Ready_for_Invoice__c == 'GO' and either there's a Purchase Order (Purchase_Order__c) with a number
    //                    // (N_Purchase_Order__c) or there isn't a Purchase Order (!Purchase_Order__c) and the Contract has status Signed
    //                    // then it sets the status to "Ready for Invoice"
    //                    if ((vInvoicingLine.Contract_Amount__c != null && vInvoicingLine.PMO_Ready_for_Invoice__c == 'GO') &&
    //                            ((vInvoicingLine.N_Purchase_Order__c != null && vInvoicingLine.Purchase_Order__c) ||
    //                             (((vInvoicingLine.Contract_Status__c == 'Signed') ||
    //                                (vInvoicingLine.Contract_Status__c == 'Ended')) && !vInvoicingLine.Purchase_Order__c))) {

    //                        // Set status to ready for invoice
    //                        vInvoicingLine.Status__c = System.Label.InvLineStatus_ReadyForInvoice;

    //                        // If also the field ADV_GoNoGo__c == 'GO' and either there's a Purchase Order (Purchase_Order__c) with a link
    //                        // (PO_Link__c) or there isn't a Purchase Order (!Purchase_Order__c)
    //                        // then it sets the status to "Invoicing Validation"
    //                        if (vInvoicingLine.ADV_GoNoGo__c == 'GO') {
    //                            vInvoicingLine.Status__c = System.Label.InvLineStatus_InvoicingValidation;
    //                        }
    //                    }
    //                }
    //            //}

    //                // If conditions to move to status "Ready for SAP" are not met, it checks if the SO__c field (that is filled only when the line is created on SAP)
    //                // is filled. If it is, it sets the status to "SO Created", it isn't, it sets the status to "Draft"
    //            } else {

    //                // If there is an invoice number then move to invoiced
    //                if (vInvoicingLine.N_Invoice__c != null && vInvoicingLine.N_Invoice__c != '') {
    //                    vInvoicingLine.Status__c = System.Label.InvLineStatus_Invoiced;
    //                    vInvoicingLine.RecordTypeId = Schema.SObjectType.Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine ReadOnly').getRecordTypeId();

    //                    // If also the field Paid_Not_Paid__c == 'X'
    //                    // then it sets the status to "Paid"
    //                    if (vInvoicingLine.Paid_Not_Paid__c == 'X') {
    //                        vInvoicingLine.Status__c = System.Label.InvLineStatus_Paid;
    //                    }
    //                } else if (vInvoicingLine.SO__c != null) {
    //                    vInvoicingLine.Status__c = System.Label.InvLineStatus_SOCreated;
    //                } else {
    //                    vInvoicingLine.Status__c = System.Label.InvLineStatus_Draft;
    //                }
    //            }

    //            // The status is set to "Cancelled" if the conditions below are met. Note that an invoiced invoicing line cannot be cancelled
    //            //(vInvoicingLine.CTRLFact__c == 'NOT INVOICED)

    //            if (vInvoicingLine.PMO_Ready_for_Invoice__c == 'CANCELLATION REQUESTED' && vInvoicingLine.ADV_GoNoGo__c == 'CANCELLED' &&
    //                    vInvoicingLine.CTRLFact__c == 'NOT INVOICED') {
    //                vInvoicingLine.Status__c = System.Label.InvLineStatus_Cancelled;
    //                vInvoicingLine.RecordTypeId = Schema.SObjectType.Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine ReadOnly').getRecordTypeId();
    //            }
    //        }
    //    }
    //}

    ///**
    // * Methode updateWBSInformations : will push the wbs informations to the invoicing line
    // * @param newInvoicingLines List<Invoicing_Line__c> : send by the trigger
    // */
    //public static void updateWBSInformations(List<Invoicing_Line__c> newInvoicingLines){
    //    // System.debug call for debug log purpose
    //    System.debug(LoggingLevel.INFO, '##AP12_InvoicingLines## updateWBSInformations Start');

    //    // For each Invoicing Line, if the contract is specified, we will update
    //    // the WBS information.
    //    for(Invoicing_Line__c newInvoicingLine : newInvoicingLines){
    //        if(newInvoicingLine.Contract2__c != null){
    //            if(newInvoicingLine.Master_WBS_Structure__c == null){
    //                if(newInvoicingLine.Contract2__r.Master_WBS_2__c != null){
    //                    newInvoicingLine.Master_WBS_Structure__c = newInvoicingLine.Contract2__r.Master_WBS_2__c;
    //                }
    //            }
    //        }
    //    }

    //    // System.debug call for debug log purpose
    //    System.debug(LoggingLevel.INFO, '##AP12_InvoicingLines## updateWBSInformations Start');
    //}
}