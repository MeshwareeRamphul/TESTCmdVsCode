public class AP56_ManageILStatusDescription {
    /**************************************************************************************
    -- - Author        : ARA
    -- - Description   : AP56_ManageILStatusDescription
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 26-AUG-2020  ARA   1.0      Initial version (SP-00433)
    -- 22-SEP-2020  ARA   1.1      Initial version (SP-00467)
    -- 11-MAY-2021  MRA   1.2      Commented send email when changing PO on Local Info (SP-01751)
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    static map<String, Schema.RecordTypeInfo>  mapRecTypeInfo = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName();
    public static Id idRecOpCoSingleEdit        = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoSingleReadOnly    = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoAmendEdit         = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoAmendReadOnly     = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).getRecordTypeId();
    public static Id idRecLightContract         = mapRecTypeInfo.get(AP_Constant.RT_LIGHTCONTRACT).getRecordTypeId();
    public static set<Id> setCtrRecTypesOpCo    = new set<Id>{idRecOpCoSingleEdit, idRecOpCoSingleReadOnly, idRecOpCoAmendEdit, idRecOpCoAmendReadOnly, idRecLightContract};

    public static void updateILStatusDescription(Set<Id> setLocalIds){
        String firstElement = null;
        for (ID setElement : setLocalIds) {
            firstElement = ''+ setElement;
            break;
        }
        List<Planned_Invoicing_Line__c> lstPilToUpdate = new List<Planned_Invoicing_Line__c>();

        if(!firstElement.startsWith('001')){
            List<Planned_Invoicing_Line__c> lstpil = [SELECT Id, Name, Contract2__c, ADV_GoNoGo__c, GoNoGo__c, Contract_Status__c, Status__c, Purchase_Order__c, PurchaseOrder__c, N_Purchase_Order__c, Status_Description__c 
                                                    FROM Planned_Invoicing_Line__c 
                                                    WHERE (Status__c = '01' OR Status__c = '02')
                                                    AND Inv_Predefined_Date__c != null 
                                                    AND Contract2__r.Local_information__c IN :setLocalIds
                                                    AND Contract2__r.RecordTypeId IN :setCtrRecTypesOpCo];
            
            if(lstpil.size() > 0){
                for(Planned_Invoicing_Line__c pil : lstpil){
                    String statusDescription = pil.Status_Description__c;
                    pil = AP12_PlannedInvoicingLines.setStatusDescription(pil);
                    if(statusDescription != pil.Status_Description__c){
                        lstPilToUpdate.add(pil);
                    }
                }
                
                //MRA 11/05/2021 - disabled email alert when PO on LI changes
                if(lstPilToUpdate.size() > 0){
                    try{
                        Database.Update(lstPilToUpdate, false);
                        /*Messaging.SendEmailResult[] res = sendMailNotification(firstElement, new List<String>{System.label.AP30_AdminOpCo360_Email});
                        if (res[0].success){
                            System.debug('***The email was sent successfully.');
                        } else {
                            System.debug('***The email failed to send: ' +  res[0].errors[0].message);
                        }*/
                    }
                    catch(Exception e){
                        Local_information__c localInfo = new Local_information__c (Id = firstElement);
                        localInfo.addError(e.getMessage());
                    }
                }
            }
        }
    }
    
    //MRA 11/05/2021 - disabled email alert when PO on LI changes
    /*public static Messaging.SendEmailResult[] sendMailNotification(Id localInfoId, List<String> lstAddresses){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(lstAddresses);
        email.setTargetObjectId(System.label.AP30_TargetObjectId);
        email.setTreatTargetObjectAsRecipient(false);
        email.setWhatId(localInfoId);
        email.setTemplateID(System.label.AP56_EmailTemplateId);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setBccSender(false);
        return Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email}); 
    }*/
}