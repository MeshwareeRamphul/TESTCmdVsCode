public with sharing class AP30_ManagePDFStatus {
    /**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : AP30_ManagePDFStatus
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
--              KZE   1.0     Initial version      
-- 2019/09/05   SGO   1.1     Contract Lightning RT Updated
-- 2020/08/06	ARA	  1.2     Update warning MSA
-- 2020/09/22   ARA   1.3     Initial version (SP-00467)
--------------------------------------------------------------------------------------
**************************************************************************************/
    public static void updateContractEntity(Map<Id, Account> mapAccount) {
        List<Contract__c> lstContract = new List<Contract__c>();
        system.debug('*****mapAccount '+mapAccount.values()[0].Active__c);
        for(Contract__c ctr : [SELECT Id, Account__c, Tech_ByPassVR__c FROM Contract__c WHERE TECH_IsContractIn__c = false AND Account__c IN :mapAccount.values()]){
            ctr.C_Account__c = mapAccount.get(ctr.Account__c).parentid;
            ctr.Tech_ByPassVR__c = (ctr.Tech_ByPassVR__c ? false : true);
            lstContract.add(ctr);
        }
        if(lstContract.size() > 0){
            update lstContract;
        }
    }

    public static void updateContractPDFStatus(set<ID> objIds) {
        String firstElement = null;
        String queryString='';
        List<Contract__c> lstCtrUpdFail;
        for (ID setElement : objIds) {
            firstElement = ''+ setElement + '';
            break;
        }

        if(firstElement.startsWith('001')){
            queryString ='SELECT Status__c, RecordType.DeveloperName, Account__r.Id, PDFStatus_lgt__c'
                    +' FROM Contract__c WHERE Account__r.Id IN :objIds'
                    +' AND Status__c !=\'Signed\' AND Status__c !=\'Ended\' AND Status__c !=\'Terminated\' '
                    +' AND ( RecordType.DeveloperName = \'Single_Contract_process_OpCo360\''
                    +' OR RecordType.DeveloperName = \'Amendment_Edit_OpCo360\''
                    +' OR RecordType.DeveloperName = \'Light_Contract\' )';
        }
        else{
            queryString ='SELECT Id, Name, ContractNumber__c, Status__c, Account__r.Name, AXA_GO_Legal_Entity__c, Local_information__r.Id, Local_information__r.Name, Local_information__r.MSA__c, PDFStatus_lgt__c, Tech_MSARef__c, Warning_MSA__c, RecordType.DeveloperName, CreatedBy.Email, Owner.Name, Owner.Email'
                    +' FROM Contract__c WHERE Local_information__r.Id IN :objIds'
                    +' AND Status__c !=\'Signed\' AND Status__c !=\'Ended\' AND Status__c !=\'Terminated\' '
                    +' AND ( RecordType.DeveloperName = \'Single_Contract_process_OpCo360\''
                    +' OR RecordType.DeveloperName = \'Amendment_Edit_OpCo360\''
                    +' OR RecordType.DeveloperName = \'Light_Contract\' )';
        }

        List<Contract__c> lstContractToCheck = Database.query(queryString);
        List<Contract__c> lstContractToUpdate = new List<Contract__c>();
        map<Id,String> mapCtrErrorMsg = new map<Id,String>();

        if(lstContractToCheck.size() > 0){
            for (Contract__c c: lstContractToCheck){
                c.PDFStatus_lgt__c ='Not updated!';
                if(!firstElement.startsWith('001')){
                    if(c.Local_information__r.MSA__c && (c.Warning_MSA__c == null || c.Warning_MSA__c == '')){
                        c.Warning_MSA__c = System.Label.Contract_Warning_MSA_Lt;
                        lstContractToUpdate.add(c);
                    }else if(!c.Local_information__r.MSA__c && (c.Warning_MSA__c != null && c.Warning_MSA__c != '')){
                        c.Warning_MSA__c = '';
                        lstContractToUpdate.add(c);
                    }
                }
            }
            try{
                List<Database.SaveResult> results = Database.Update(lstContractToUpdate, false);
                //update lstContractToUpdate;
                lstCtrUpdFail = new List<Contract__c>();
                for(Integer i=0;i<results.size();i++){
                    if (!results.get(i).isSuccess()){
                        lstCtrUpdFail.add(lstContractToUpdate.get(i));
                        for (Database.Error err :results.get(i).getErrors()){
                            mapCtrErrorMsg.put(lstContractToUpdate.get(i).Id, err.getMessage());
                        }
                    }
                }
                //Send email notification
                if(lstCtrUpdFail.size()>0){
                    String finalstr = 'Contract Owner, Contract Id, Contract Number, Contract Name, Status, Customer Legal Entity Name, AXA GO Legal Entity, Error Message \n';
                    Set<String> setAddress = new Set<String>();
                    Contract__c temp;
                    //Sort contracts by Owner
                    if(lstCtrUpdFail.size() > 1){
                        for (Integer i = 0; i < lstCtrUpdFail.size(); i++) {
                            for (Integer j = 1; j < (lstCtrUpdFail.size()-i); j++) {
                                if (lstCtrUpdFail[j-1].Owner.Name > lstCtrUpdFail[j].Owner.Name) {
                                    temp = lstCtrUpdFail[j-1];
                                    lstCtrUpdFail[j-1] = lstCtrUpdFail[j];
                                    lstCtrUpdFail[j] = temp;
                                }
                            }
                        }
                    }
                    //Set recipient and attached file content
                    setAddress.add(System.label.AP30_AdminOpCo360_Email);
                    for (Contract__c ctr :lstCtrUpdFail){
                        if(ctr.Owner != null){
                            setAddress.add(ctr.Owner.Email);
                        }else if(ctr.CreatedBy!=null){
                            setAddress.add(ctr.CreatedBy.Email);
                        }

                        finalstr += ctr.Owner.Name+','+ctr.Id+','+ctr.ContractNumber__c+',"'+ctr.Name+'",'+ctr.Status__c+',"'+ctr.Account__r.Name+'","'+ctr.AXA_GO_Legal_Entity__c+'","'+mapCtrErrorMsg.get(ctr.Id)+'"\n';
                    }
                    sendMailNotification(firstElement, finalstr, new List<String>(setAddress));
                }
                if(Test.isRunningTest()){
                    throw new DMLException();
                }
            }
            catch(Exception e){
                system.debug('error: ' + e.getMessage());
                if(!firstElement.startsWith('001')){
                    Local_information__c localInfo = new Local_information__c (Id = firstElement);
                    localInfo.addError(e.getMessage());
                }
            }
        }
    }

    public static void updateContractPDFStatus(List<Contract__c> lstContr, String strStatus) {
        for(Contract__c c : lstContr){
            c.PDFStatus_lgt__c = strStatus;
        }
    }

    public static void sendMailNotification(Id localInfoId, String finalstr, List<String> lstAddresses){
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob xlsxBlob = Blob.valueOf(finalstr);
        string xlsxname = 'List of contracts in error.csv';
        csvAttc.setFileName(xlsxname);
        csvAttc.setBody(xlsxBlob);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        //email.setToAddresses(new String[] {'urvashi.sadasing@spoonconsulting.com'});
        email.setToAddresses(lstAddresses);
        email.setTargetObjectId(System.label.AP30_TargetObjectId);
        email.setTreatTargetObjectAsRecipient(false);
        email.setWhatId(localInfoId);
        email.setTemplateID(System.label.AP30_EmailTemplateId);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setBccSender(false);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult[] res = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});

        if (res[0].success){
            System.debug('***The email was sent successfully.');
        } else {
            System.debug('***The email failed to send: ' +  res[0].errors[0].message);
        }
    }

}