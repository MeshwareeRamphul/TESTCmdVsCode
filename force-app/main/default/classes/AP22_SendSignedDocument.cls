public without sharing class AP22_SendSignedDocument {
    
    /*public static void sendToSignatories(Set<Id> setCtrId){
        string signed = '%_SOW_signed.pdf%';
        List<id> ContentDocumentids = new List<id>();
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        set<eSignatory__c> setEsignatory = new Set<eSignatory__c>();
        Map<Id, List<Messaging.Emailfileattachment>> mapEFA = new Map<Id, List<Messaging.Emailfileattachment>>();
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:System.label.AP30_adminOpCo360_Email];
        
        for(eSignatory__c esignatory : [SELECT Id, eSignature__c, Contact__c, Contract__c, EmailTxt__c FROM eSignatory__c WHERE Status__c =:AP_Constant.esignatoryStatusSigned 
                                        AND cTin_Role__c =:AP_Constant.esignRoleSigner 
                                        AND Contract__c IN :setCtrId
                                        AND eSignature__r.Status__c =: AP_Constant.eSignatureCompletedStatus]){
            
            setEsignatory.add(esignatory);
        }
        
        for(ContentDistribution cd : [SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersion.title,ContentVersion.versiondata
                                      FROM ContentDistribution
                                      WHERE RelatedRecordId IN :setCtrId 
                                      AND ContentVersion.title LIKE :signed])
        {
            blob WOCFbody = cd.ContentVersion.versiondata;
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(cd.ContentVersion.title);
            efa.setBody(WOCFbody);
            
            if(!mapEFA.containsKey(cd.RelatedRecordId)){
                mapEFA.put(cd.RelatedRecordId, new List<Messaging.Emailfileattachment>{efa});
            }else{
                List<Messaging.Emailfileattachment> lstEFA = mapEFA.get(cd.RelatedRecordId);
                lstEFA.add(efa);
                mapEFA.put(cd.RelatedRecordId, lstEFA);
            }
            
        }
        system.debug('****mapEFA '+mapEFA.size());
        
        //for(Id esignId :mapEsignatory.keySet()){
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            for(eSignatory__c esignatory : setEsignatory){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new string[]{esignatory.EmailTxt__c});
                email.setTargetObjectId(esignatory.Contact__c);
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(esignatory.Id);
                email.setTemplateID(System.label.EmailTemplateId_Signed_Document);
                email.setSaveAsActivity(false);
                email.setUseSignature(false);
                email.setBccSender(false);
                
                if(mapEFA.containsKey(esignatory.Contract__c)){
                    email.setFileAttachments(mapEFA.get(esignatory.Contract__c));
                }
                
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                mails.add(email);

            }
            
            Messaging.sendEmail(mails);
        //}
    }

    public static void sendToSignatories(Set<eSignature__c> setEsignature){
        string signed = '%_SOW_signed.pdf%';
        List<id> ContentDocumentids = new List<id>();
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Map<Id, List<eSignatory__c>> mapEsignatory = new Map<Id, List<eSignatory__c>>();
        Map<Id, List<Messaging.Emailfileattachment>> mapEFA = new Map<Id, List<Messaging.Emailfileattachment>>();
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>();
        Set<Id> setContractId = new Set<Id>();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:System.label.AP30_adminOpCo360_Email];
        
        for(eSignatory__c esignatory : [SELECT Id, eSignature__c, Contact__c, EmailTxt__c FROM eSignatory__c WHERE cTin_Role__c =:AP_Constant.esignRoleSigner AND eSignature__c IN :setEsignature]){
            if(!mapEsignatory.containsKey(esignatory.eSignature__c)){
                mapEsignatory.put(esignatory.eSignature__c, new List<eSignatory__c>{esignatory});
            }else{
                List<eSignatory__c> lstEsignatory = mapEsignatory.get(esignatory.eSignature__c);
                lstEsignatory.add(esignatory);
                mapEsignatory.put(esignatory.eSignature__c, lstEsignatory);
            }
        }
        
        for(eSignature__c esign : setEsignature){
            setContractId.add(esign.contract__c);
        }
        
        for(ContentDistribution cd : [SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersion.title,ContentVersion.versiondata
                                      FROM ContentDistribution
                                      WHERE RelatedRecordId IN :setContractId 
                                      AND ContentVersion.title LIKE :signed])
        {
            blob WOCFbody = cd.ContentVersion.versiondata;
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(cd.ContentVersion.title);
            efa.setBody(WOCFbody);
            
            if(!mapEFA.containsKey(cd.RelatedRecordId)){
                mapEFA.put(cd.RelatedRecordId, new List<Messaging.Emailfileattachment>{efa});
            }else{
                List<Messaging.Emailfileattachment> lstEFA = mapEFA.get(cd.RelatedRecordId);
                lstEFA.add(efa);
                mapEFA.put(cd.RelatedRecordId, lstEFA);
            }
            
        }
        system.debug('****mapEFA '+mapEFA.size());
        
        for(Esignature__c esign :SetEsignature){
            for(eSignatory__c esignatory : mapEsignatory.get(esign.Id)){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new string[]{esignatory.EmailTxt__c});
                email.setTargetObjectId(esignatory.Contact__c);
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(esignatory.Id);
                email.setTemplateID(System.label.EmailTemplateId_Signed_Document);
                email.setSaveAsActivity(false);
                email.setUseSignature(false);
                email.setBccSender(false);
                
                if(mapEFA.containsKey(esign.Contract__c)){
                    email.setFileAttachments(mapEFA.get(esign.Contract__c));
                }
                
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }
        }
    }*/

    public static void sendToSignatories(List<ContentDistribution> lstCD){
        system.debug('## starting method sendToSignatories');
        string signed = '%_SOW_signed.pdf%';
        //AMA
        string signedCtin = '%_signed%';
        //List<id> ContentDocumentids = new List<id>();
        //List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Map<Id, List<eSignatory__c>> mapEsignatory = new Map<Id, List<eSignatory__c>>();
        //AMA
        Map<Id, List<Messaging.Emailfileattachment>> mapEFA = new Map<Id, List<Messaging.Emailfileattachment>>();
        List<Messaging.SingleEmailMessage> lstEmailMessage = new List<Messaging.SingleEmailMessage>();
        List<String> lstEmailOWEA = new List<String>{System.label.AP30_adminOpCo360_Email, System.label.cTin_OwdAddress};
        Map<String, Id> mapOWEA = new Map<String, Id>();
        Set<Id> setContractId = new Set<Id>();
        for(OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :lstEmailOWEA]){
            mapOWEA.put(owea.Address, owea.Id);
        }
        
        lstCD = [SELECT Id, DistributionPublicUrl, RelatedRecordId, ContentVersion.title, ContentVersion.versiondata
                 FROM ContentDistribution
                 WHERE Id IN :lstCD 
                 AND (ContentVersion.title LIKE :signed OR ContentVersion.title LIKE :signedCtin)];

        if(lstCD.size() > 0){
            for(ContentDistribution cd: lstCD){
                setContractId.add(cd.RelatedRecordId);
            }
            system.debug('## setContractId'+ setContractId);

            for(eSignatory__c esignatory : [SELECT Id,eSignature__c,Contract__c,Contact__c,EmailTxt__c,contract__r.TECH_IsContractIn__c,recordtype.developername,Contract__r.cTin_Reference__c,
                                            esignature__r.Language__c,cTin_Role__c,Contract__r.cTin_AXAMainLegalSignatoryEntity__r.name,contract__r.cTin_SupplierAccount__r.name 
                                            FROM eSignatory__c 
                                            WHERE contract__c IN :setContractId
                                            AND eSignature__r.Status__c =:AP_Constant.eSignatureCompletedStatus]){
                if((esignatory.contract__r.TECH_IsContractIn__c == false && esignatory.cTin_Role__c == AP_Constant.esignRoleSigner) || (esignatory.contract__r.TECH_IsContractIn__c == true && esignatory.recordtype.developername=='cTin_AXA_Representative')){
                    if(!mapEsignatory.containsKey(esignatory.contract__c)){
                        mapEsignatory.put(esignatory.contract__c, new List<eSignatory__c>{esignatory});
                    }else{
                        mapEsignatory.get(esignatory.contract__c).add(esignatory);
                    }
                }
            }
            
            system.debug('## mapEsignatory'+ mapEsignatory);
            if(mapEsignatory.size()>0){
                for(ContentDistribution cd : lstCD){
                    if(mapEsignatory.containsKey(cd.RelatedRecordId)){
                        blob WOCFbody = cd.ContentVersion.versiondata;
                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setFileName(cd.ContentVersion.title);
                        efa.setBody(WOCFbody);
                        
                        if(!mapEFA.containsKey(cd.RelatedRecordId)){
                            mapEFA.put(cd.RelatedRecordId, new List<Messaging.Emailfileattachment>{efa});
                        }else{
                            mapEFA.get(cd.RelatedRecordId).add(efa);
                        }
                    }
                }
            
                for(Id ctrId :mapEsignatory.keyset()){
                    for(eSignatory__c esignatory : mapEsignatory.get(ctrId)){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(new string[]{esignatory.EmailTxt__c});
                        email.setTargetObjectId(esignatory.Contact__c);
                        email.setTreatTargetObjectAsRecipient(false);
                        email.setWhatId(esignatory.Id);

                        if(esignatory.contract__r.TECH_IsContractIn__c){
                            // for cTin
                            if (esignatory.esignature__r.Language__c == 'French') {
                                email.setTemplateID(System.label.Ctin_EmailTemplateId_Signed_Document_FR); 
                            } else {
                                email.setTemplateID(System.label.Ctin_EmailTemplateId_Signed_Document); 
                            }
                            if (mapOWEA.containsKey(System.label.cTin_OwdAddress)){
                                email.setOrgWideEmailAddressId(mapOWEA.get(System.label.cTin_OwdAddress));
                            }
                        }else{
                            // for OpCo
                            email.setTemplateID(System.label.EmailTemplateId_Signed_Document);
                            if (mapOWEA.containsKey(System.label.AP30_adminOpCo360_Email)) {
                                email.setOrgWideEmailAddressId(mapOWEA.get(System.label.AP30_adminOpCo360_Email));
                            }
                        }
                        email.setSaveAsActivity(false);
                        email.setUseSignature(false);
                        email.setBccSender(false);
                        
                        if(mapEFA.containsKey(ctrId)){
                            email.setFileAttachments(mapEFA.get(ctrId));
                        }
                        
                        lstEmailMessage.add(email);
                    }
                }
            }
            
            system.debug('## lstEmailMessage'+ lstEmailMessage);
            if(lstEmailMessage.size() > 0 && !Test.isRunningTest()){
                Messaging.sendEmail(lstEmailMessage);
            }
        }
    }
}