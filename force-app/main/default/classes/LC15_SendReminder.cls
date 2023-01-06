public with sharing class LC15_SendReminder {

    @AuraEnabled
    public static Map<String,String> sendReminder(String eSignatoryId){
        System.debug('## LC15_SendReminder.sendReminder - Start');
        Map<String,String> mapResult = new Map<String,String>();
        List<eSignatory__c> eSignatory = [SELECT Id, Name,cTin_Profile__c,TECH_SignerRole__c, EmailTxt__c, Status__c, eSignature__r.Id, eSignatureTransactionId__c, cTin_Role__c, RelaunchCount__c, Contact__c, 
                                            Contract__r.TECH_IsContractIn__c, Contract__r.cTin_OwnerEntityLocalCode__c, Contract__r.cTin_OwnerEntity__c
                                            FROM eSignatory__c WHERE Id = :eSignatoryId LIMIT 1];

        if (eSignatory.size() < 1) {
            mapResult.put('error', 'No eSignatory found.');
            throw new AuraHandledException('No eSignatory found.');
        }
        if (eSignatory[0].Status__c != 'Ready' || (eSignatory[0].Contract__r.TECH_IsContractIn__c && eSignatory[0].cTin_Role__c == 'Validator')){
            mapResult.put('error',System.label.CannotPerformRelaunch);
        }
        else {
            if (eSignatory[0].eSignatureTransactionId__c == '' || eSignatory[0].eSignatureTransactionId__c == null){
                mapResult.put('error',System.label.TransactionIdBlank);
            }else{
                mapResult.put('eSignatureId',eSignatory[0].eSignature__r.Id);
            }
        }

        // send email here if OpCo (not contractIn)
        if(!eSignatory[0].Contract__r.TECH_IsContractIn__c){
            mapResult.put('contractType','Opco');
            if( mapResult.get('error') == null){
                if(integer.valueOf(eSignatory[0].RelaunchCount__c) == null)
                eSignatory[0].RelaunchCount__c = 1;
                else
                eSignatory[0].RelaunchCount__c ++;
                eSignatory[0].LastRelaunchDate__c = datetime.Now();

                update eSignatory;
                Messaging.SendEmailResult[] res = sendMail('OpCo',eSignatory[0], new List<String>{eSignatory[0].EmailTxt__c}, mapResult);
                if(!test.isRunningTest()){
                    if (res[0].success){
                        if(eSignatory[0].cTin_Role__c == 'Signer')
                            mapResult.put('success','The reminder was successfully sent to the signatory.');
                        else
                            mapResult.put('success','The reminder was successfully sent to the validator.');
                    } else {
                        if(eSignatory[0].cTin_Role__c == 'Signer')
                            mapResult.put('error','The reminder was not sent to the signatory : ' +  res[0].errors[0].message);
                        else
                            mapResult.put('error','The reminder was not sent to the validator : ' +  res[0].errors[0].message);
                    }
                }else{
                    if(eSignatory[0].cTin_Role__c == 'Signer')
                        mapResult.put('success','The reminder was successfully sent to the signatory.');
                    else
                        mapResult.put('success','The reminder was successfully sent to the validator.');
                }
            }
        }else{
            mapResult.put('contractType','ContractIn');
            if( mapResult.get('error') == null){
                if(integer.valueOf(eSignatory[0].RelaunchCount__c) == null)
                eSignatory[0].RelaunchCount__c = 1;
                else
                eSignatory[0].RelaunchCount__c ++;
                eSignatory[0].LastRelaunchDate__c = datetime.Now();

                update eSignatory;
                Messaging.SendEmailResult[] res = sendMail('cTin',eSignatory[0], new List<String>{eSignatory[0].EmailTxt__c}, mapResult);
                if(!test.isRunningTest()){
                    if (res[0].success){
                        //if(eSignatory[0].cTin_Role__c == 'Signer')
                            mapResult.put('success','The reminder was successfully sent to the signatory.');
                        //else
                            //mapResult.put('success','The reminder was successfully sent to the validator.');
                    } else {
                        if(eSignatory[0].cTin_Role__c == 'Signer')
                            mapResult.put('error','The reminder was not sent to the signatory : ' +  res[0].errors[0].message);
                    // else
                        // mapResult.put('error','The reminder was not sent to the validator : ' +  res[0].errors[0].message);
                    }
                }else{
                    mapResult.put('success','The reminder was successfully sent to the signatory.');
                }
            }
        }
        return mapResult;
    }
    

    public static Messaging.SendEmailResult[] sendMail(string contractType, eSignatory__c eSignatory, List<String> lstAddresses, Map<String,String> mapResult){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String emailTemplateId = '';
        if (contractType=='OpCo') 
            emailTemplateId = System.label.EmailTemplateId_Reminder_Validate_Sign_Document;
        else {
            if (esignatory.cTin_Profile__c=='signersupplier')
                emailTemplateId = System.label.EmailTemplateId_cTin_Reminder_to_Signatory;
            else{
                if(esignatory.Contract__r.cTin_OwnerEntity__c == '1230 - AXA Spain'){
                    emailTemplateId = System.label.EmailTemplateId_cTin_Reminder_to_AXASignatory_Spain;
                }else if(esignatory.Contract__r.cTin_OwnerEntityLocalCode__c == 'AFR'){
                    emailTemplateId = System.label.EmailTemplateId_cTin_Reminder_to_AXASignatory_AFR;
                }else if(esignatory.Contract__r.cTin_OwnerEntityLocalCode__c == 'ADE' || esignatory.Contract__r.cTin_OwnerEntityLocalCode__c == 'ACH'){
                    emailTemplateId = System.label.EmailTemplateId_cTin_Reminder_to_AXASignatory_ADE_ACH;
                }else{
                    emailTemplateId = System.label.EmailTemplateId_cTin_Reminder_to_AXASignatory;
                }
            }     
        }
        email.setTemplateID(emailTemplateId);
        email.setToAddresses(lstAddresses);
        email.setTargetObjectId(eSignatory.Contact__c);
        email.setTreatTargetObjectAsRecipient(false);
        email.setWhatId(eSignatory.Id);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setBccSender(false);
        OrgWideEmailAddress[] owea;
        if (contractType=='OpCo'){
        owea = [select Id from OrgWideEmailAddress where Address =:System.label.AP30_adminOpCo360_Email];
        }
        else{
            owea = [select Id from OrgWideEmailAddress where Address =:'admin.contract-in@axa.com'];
        }
        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        return test.isRunningTest() ? null : Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }
}