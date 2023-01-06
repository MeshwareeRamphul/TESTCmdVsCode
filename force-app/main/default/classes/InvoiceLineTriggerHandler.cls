public class InvoiceLineTriggerHandler {
/*
--------------------------------------------------------------------------------------
-- - Name          : InvoiceLineTriggerHandler
-- - Author        : ASO
-- - Description   : trigger Handler for InvoicingLineTrigger
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-OCT-2016  ASO    1.0     Initial version
-- 11-APR-2017  EWA    1.1     Gestion d'un problème d'enregistrement de duplicats dans la map mapInvoiceLineInfo
-- 18-AUG-2017  USA    1.2     ALLINFIN-509 : restrict record type credit memo
-- 18-MAR-2020  USA    1.3     SP-00198 : update profile in CheckRights method
-- 17-SEP-2021  ARA    1.4     SP-02508 : Credit Note RecordType is deleted
--------------------------------------------------------------------------------------
*/
    //Static Id idRecIL = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Credit Note').getRecordTypeId();

    @future(callout=true)
    public static void handleBeforeUpdate(Set<Id> setInvoicingLines){

        WS02_CallSAPWS callWS;
        map<id,List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo = new map<id,List<Planned_Invoicing_Line__c>>();
        //List<Planned_Invoicing_Line__c> lstInvoiceLineInfo = [Select Id,AXA_GS_Legal_Entity__c,Tech_AXA_GS_Legal_Entity__c,SAP_Account_Number__c,N_Purchase_Order__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Contract2__c,
        //                                                      Material_SAPEXP__c,Man_days__c,Activity_Type__c,Header_Text__c,SAP_ID__c,RecordTypeId,
        //                                                      TECH_SynchroSAP__c, Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,Service_Type__c,Contract_Start_Date__c,
        //                                              Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c
        //                                          From Planned_Invoicing_Line__c
        //                                          Where Id IN :setInvoicingLines
        //                                          ];

        for(Planned_Invoicing_Line__c invLine:[Select Id,AXA_GS_Legal_Entity__c,Tech_AXA_GS_Legal_Entity__c,SAP_Account_Number__c,N_Purchase_Order__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Contract2__c,
                                                Material_SAPEXP__c,Man_days__c,Activity_Type__c,Header_Text__c,SAP_ID__c,RecordTypeId, Customer_contact_name__c,Status__c,Tech_UpdatedByPS__c,
                                                TECH_SynchroSAP__c, Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,Service_Type__c,Contract_Start_Date__c,
                                                Contract_End_Date__c, Header_Text_2_SAPEXP__c, Header_Text_3_SAPEXP__c, Header_Text_4_SAPEXP__c, PurchaseOrder__r.PO_Client__c, AmountIL__c, Inv_Predefined_Date__c/*, Invoicing_Predefined_Date__r.Invoicing_Date__c*/
                                                From Planned_Invoicing_Line__c
                                                Where Id IN :setInvoicingLines
                                                ]){

            if(mapInvoiceLineInfo.containsKey(invLine.Contract2__c)){
                List<Planned_Invoicing_Line__c> listTemp = mapInvoiceLineInfo.get(invLine.Contract2__c);
                //J'ai fait quelque changement à ce niveau car il semblerait que SFDC envoie plusieurs fois le même Invoicing Line pour un même contrat
                //Tout ce que je fait c'est qu'à chaque fois que j'essaie d'ajouter une IL, je vérifie qu'il n'existe pas déjà une IL dans la liste
                Boolean flag = true;
                for(Planned_Invoicing_Line__c il : listTemp){
                    if(il.Id == invLine.Id){
                        flag = false;
                    }
                }
                if(flag){
                    mapInvoiceLineInfo.get(invLine.Contract2__c).add(invLine);
                }
            }
            else{
                mapInvoiceLineInfo.put(invLine.Contract2__c,new List<Planned_Invoicing_Line__c>{invLine});
            }
        }
        if(mapInvoiceLineInfo.size() > 0){
            System.debug('sending lst to callSAPWS');
            callWS = new WS02_CallSAPWS(mapInvoiceLineInfo);
        }
    }

    
    // 17/09/2021   ARA     SP-02508
    /*public static void checkRights(List<Planned_Invoicing_Line__c> lstNewPIL){
        Boolean hasRights = AP_Constant.hasRights(AP_Constant.functionalAdmin);
        for (Planned_Invoicing_Line__c pil :lstNewPIL){
            if (il.RecordTypeId == idRecIL && !hasRights){
                pil.addError(AP_Constant.strCRCannotUpdate);
            }
        }
    }*/
}