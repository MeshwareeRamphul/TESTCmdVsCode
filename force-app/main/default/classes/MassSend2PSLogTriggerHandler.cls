public class MassSend2PSLogTriggerHandler {
/*----------------------------------------------------------------------
-- - Name          : MassSend2PSLogTriggerHandler
-- - Author        : ARA
-- - Description   : trigger handler for MassSend2PSLog__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 03-JAN-2022  ARA    1.0      Initial version
-------------------------------------------------------------------------*/

    public static void AfterUpdateHandler(map<Id,MassSend2PSLog__c> mapOldMassSend2PSLog, map<Id,MassSend2PSLog__c> mapNewMassSend2PSLog){
        List<Id> lstContractId = new List<Id>();
        Set<Id> setUserId = new Set<Id>();
        Map<Id, User> mapUser;
        Map<Id, Log__c> mapLog = new Map<Id, Log__c>();
        Map<Id, List<Id>> mapContractId = new Map<Id, List<Id>>();
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>();
        List<Log__c> lstLog = new List<Log__c>();
        List<MassSend2PSLog__c> lstMSLog = new List<MassSend2PSLog__c>();
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        String fileHeader = 'Contract Number, Contract Name, PS LOG, Status, Error message \n';

        for(MassSend2PSLog__c newMSLog : mapNewMassSend2PSLog.values()){
            MassSend2PSLog__c oldMSLog = mapOldMassSend2PSLog.get(newMSLog.Id);
            if(oldMSLog.AllProcessed__c != newMSLog.AllProcessed__c && newMSLog.AllProcessed__c){
                List<String> lstCtrId = newMSLog.ProcessedContracts__c.split(';');
                mapContractId.put(newMSLog.Id, lstCtrId);
                lstMSLog.add(newMSLog);
                setUserId.add(newMSLog.User__c);
                for(String id : lstCtrId){
                    lstContractId.add(id);
                }
            }
        }

        //Send email process completed
        if(lstContractId.size() > 0){
            if(setUserId.size() > 0){
                mapUser = new Map<Id, User>([SELECT Id, ContactId, Email FROM User WHERE Id IN :setUserId]);
            }

            for(Log__c log : [SELECT Id, Contract__c, Contract__r.Name, Contract__r.ContractNumber__c, Error_Message__c, Call_Status__c, Date_of_log__c FROM Log__c WHERE Contract__c IN :lstContractId AND LastPSLog__c = true AND Error_Message__c LIKE '%Flow2%']){
                mapLog.put(log.Contract__c, log);
            }
            
            for(MassSend2PSLog__c newMSLog : lstMSLog){
                String finalstr = '';
                Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                email.setTemplateID(System.label.EmailTemplateId_MassSendToPSResults);
                email.setTargetObjectId(mapUser.get(newMSLog.User__c).ContactId);
                email.setWhatId(newMSLog.Id);
                email.setTreatTargetObjectAsRecipient(false);
                email.setToAddresses(new List<String>{mapUser.get(newMSLog.User__c).Email});

                if(finalstr == '') finalstr = fileHeader;
                //finalstr += '"'+mapLog.get(lstInvoiceLinesUpdate[i].Id).Contract2__r.ContractNumber__c+'","'+mapPIL.get(lstInvoiceLinesUpdate[i].Id).Contract2__r.name+'","N/A", "Error","'+sr.getErrors().get(0).getMessage()+'"\n';

                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                blob xlsxBlob = Blob.valueOf(finalstr);
                string xlsxname = 'Send To PS Status.csv';
                csvAttc.setContentType('text/csv');
                csvAttc.setFileName(xlsxname);
                csvAttc.setBody(xlsxBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});

                lstEmails.add(email);
            }
            if(!test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmails);
            }
        }
    }
}