/**
 * @description       : 
 * @author            : VMU
 * @group             : 
 * @last modified on  : 10-27-2021
 * @last modified by  : VMU
**/
public class LC05_SendToPeopleSoft {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : LC05_SendToPeopleSoft
-- - Author        : Spoon Consulting 
-- - Description   : Call the Class WS02_CallSAPWS
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 10-SEP-2019  MRA    1.0     Initial version
-- 08-JUL-2020  ARA    1.1    
-- 16-DEC-2020  MRA    1.2     SP-01102: Added update on checkbox byPassVREditStatus__c so that edit on IL status is not blocked by VR 
--------------------------------------------------------------------------------------
*/

    @AuraEnabled
    public static String setToSendingtoPS(id curCtr){
        String errorMsg = '';
        Contract__c ctr = [SELECT Id, Tech_isSendingToPS__c, Peoplesoft_Sync__c FROM Contract__c WHERE id = :curCtr];
        if(ctr.Tech_isSendingToPS__c){
            errorMsg = System.Label.ErrorMessage_SentToPS;
        }else if(ctr.Peoplesoft_Sync__c){
            errorMsg = System.Label.ErrorMessage_PeoplesoftSync;
        }else if(!AP_Constant.hasRights(new Set<String>{AP_Constant.functionalAdmin, AP_Constant.billingTeam})){
            errorMsg = System.Label.LC05_HaveNoSufficientRights;
        }else{
            try{
                update new Contract__c(id = curCtr, Tech_isSendingToPS__c = true, PeopleSoftConnectionMessage__c = 'Preparation for sending to ps');
            }catch(Exception e){ String msg = e.getMessage(); errorMsg = msg.substring(msg.lastIndexOf(',')+1, msg.lastIndexOf(':'));}
        }
        return errorMsg;
    }

    @AuraEnabled
    public static String sendCtrlightoPeopleSoft(id curCtr){
        String errorMsg = '';
        Contract__c ctr = [SELECT Id, Tech_isSendingToPS__c, byPassVREditStatus__c FROM Contract__c WHERE Id =: curCtr];
        
        List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id,Contract2__c,SAP_Synchronisation_Error__c,Connexion_Error__c,
                                                                SAP_Account_Number__c,N_Purchase_Order__c,PurchaseOrder__r.PO_Client__c,Customer_contact_name__c,Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Service_Type__c,
                                                                Contract_Start_Date__c,Contract_End_Date__c,Material_SAPEXP__c,Man_days__c,Activity_Type__c,
                                                                Activity_Description__c,ViewCurrency__c,Master_WBS_Structure__c,Master_WBS_Structure__r.Name,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,ADV_GoNoGo__c,
                                                                Status__c,isInPS__c,RecordTypeId,SO__c,ITEM__c,TECH_SynchroSAP__c,Header_Text__c,Header_Text_2_SAPEXP__c,
                                                                Header_Text_3_SAPEXP__c,Header_Text_4_SAPEXP__c, Contract2__r.TECH_PS_SalesOrganization__c, AmountIL__c, Tech_UpdatedByPS__c,
                                                                Inv_Predefined_Date__c, Contract2__r.Peoplesoft_Sync__c,
                                                                Contract2__r.name, Contract2__r.ContractNumber__c,Contract2__r.Status__c,Contract2__r.Tech_MSARef__c, Contract2__r.Tech_isSendingToPS__c, StartDate__c, EndDate__c
                                                                FROM Planned_Invoicing_Line__c 
                                                                WHERE Contract2__c =: curCtr 
                                                                AND Contract2__r.Peoplesoft_Sync__c = false
                                                                AND Type__c = 'Invoicing Line'
                                                                AND AmountIL__c >= 0
                                                                AND (isInPS__c = true OR Status__c !=: System.label.InvLineStatusCancelled)];
        //display error
        if(invoicingLineList.size() == 0){
            errorMsg = System.Label.LC51_NoNewInformationToSend;
        }else{
            try{
                Map<id, List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo = new Map<id, List<Planned_Invoicing_Line__c>>();
                List<Planned_Invoicing_Line__c> lstPILUpdate = new List<Planned_Invoicing_Line__c>();

                for(Planned_Invoicing_Line__c inv_Line: invoicingLineList){
                    if(mapInvoiceLineInfo.containsKey(inv_Line.Contract2__c)){
                        mapInvoiceLineInfo.get(inv_Line.Contract2__c).add(inv_Line);
                    }
                    else{
                        mapInvoiceLineInfo.put(inv_Line.Contract2__c,new list<Planned_Invoicing_Line__c>{inv_Line});
                    }
                }
                if(!Test.isRunningTest()){
                    WS02_CallRestESG callWS = new WS02_CallRestESG(mapInvoiceLineInfo);
                    errorMsg = callWS.getErroMessage();
                }
                //16-DEC-2020  MRA (SP-01102)
                /*if(ctr.byPassVREditStatus__c==true ) ctr.byPassVREditStatus__c=false;
                else ctr.byPassVREditStatus__c=true;*/
            }
            catch(exception e ){ errorMsg = e.getMessage(); }
        }
        
        return errorMsg;
    }
}