public without sharing class AP41_AutomateEsignature {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : AP41_AutomateEsignature
-- - Author        : Spoon Consulting 
-- - Description   : Class automates creation of esignature and esignatories 
                     when automate_esignature is checked on contract and contractform is approved.
                     Also notifies contract owner when esignature fails.
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 18-MAY-2016  MRA    1.0     Initial version
-- 24-MAY-2016  MRA    1.1     Notify contract owner when automation of esignature fails
-- 27-JUL-2016  MRA    1.2     Added check to prevent createEsignature FROM being fired more than once.
-- 05-AUG-2016  MRA    1.3     Updated method createEsignature to cater for unilateral 
-- 13-AUG-2018  MRA    1.6     Evol (Case 00004282) - Apply restriction of 89 characters to ensure that 
                               salesforce limit of 100 characters for content name is not exceeded
-- 04-MAR-2020  SGO    1.7     Generate content document link 
-- 11-MAR-2020  SGO    1.8     Implement bashar's solution - sign able
-- 04-DEC-2020  MRA    1.9     Corrected bug - SP-001071
-- 25-FEB-2021  MRA    2.0     SP-01371 => Corrected bug in query retrieving the sign-able cv
-- 28-MAY-2021  MRA    2.1     SP-00239 => When automate option is SELECTed, create + submit esignature automatically
-- 07-OCT-2022  ARA    3.0     Universign v2
************************************************************************************
*/
    
    public static boolean alreadyFired = false;
    
    //method creates esignature with esignatories, also caters for unilateral 
    public static void createEsignature(set<id>ContractId){
         system.debug('## Starting method AP41_AutomateEsignature.createEsignature');
         alreadyFired = true;
         Contract__c contract;
         Boolean notifyContractOwner = false;
         cTin_ContractForm__c contractForm;
         eSignature__c esignature= new eSignature__c(); 
         Integer numeroOrdreDebut;
         Integer numeroOrdreFin;
         Integer nbDeleveryContent;
         String contractName;
         String errorMessage = '';
         String errorMsg = '';
         User owner;
         List<Esignatory__c> eSignatoryList = new List<Esignatory__c>();
         Savepoint sp;
         Id axaRepRT = Schema.SObjectType.esignatory__c.getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();

         if(contractId.size()!=0){
            contract = [SELECT Id, ownerID, Name,LinkToDocument__c, cTin_SupplierAccount__c,TECH_IsContractIn__c,cTin_ErrorMessage__c, cTin_OwnerEntityLocalCode__c, 
                        cTin_AXASignatoryRepresentative__c, cTin_SupplierSignatoryRepresentative__c,cTin_UnilateralSupplier__c,cTin_UnilateralAXARepresentative__c,Status__c,cTin_Owner__c,
                        cTin_SupplierSignatoryRepresentative__r.cTin_Active__c, cTin_SupplierSignatoryRepresentative__r.Name, cTin_SupplierSignatoryRepresentative__r.FirstName, 
                        cTin_SupplierSignatoryRepresentative__r.LastName, cTin_SupplierSignatoryRepresentative__r.MobilePhone, cTin_SupplierSignatoryRepresentative__r.Email, cTin_SupplierSignatoryRepresentative__r.Account.Name,
                        cTin_AXASignatoryRepresentative__r.cTin_Active__c, cTin_AXASignatoryRepresentative__r.Name, cTin_AXASignatoryRepresentative__r.FirstName, cTin_AXASignatoryRepresentative__r.LastName, 
                        cTin_OwnerEntity__c,cTin_AXASignatoryRepresentative__r.MobilePhone, cTin_AXASignatoryRepresentative__r.Email,cTin_AXASignatoryRepresentative__r.Account.Name
                        FROM Contract__c
                        WHERE Id IN: contractId];
        
            system.debug('##AP07 contract.Status__c'+contract.Status__c);
            //system.debug('##AP07 contract.FinalDocumentURL__c'+contract.FinalDocumentURL__c);
            
            if((contract.LinkToDocument__c != '' && contract.LinkToDocument__c != null)){
            string language='';
                User OwnerContract = [SELECT cTin_UniversignProfile__c,cTin_Universign__c FROM User WHERE Id=: contract.ownerId ] ; 
                if(OwnerContract.cTin_Universign__c){
                    contractForm = [SELECT Id, cTin_Contract__c FROM cTin_ContractForm__c WHERE cTin_Contract__c IN:contractId ORDER BY createdDate asc limit 1];
                    RecordType draftRT = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName='cTin_Draft' AND SobjectType='eSignature__c'];
                    owner = [SELECT Id, Name,LanguageLocaleKey FROM USER WHERE id=:UserInfo.getUserId()];
                   
                    contractName = contract.Name;
                    //create esignature 
                     if(Contract.cTin_OwnerEntity__c == '700 - AXA France' || Contract.cTin_OwnerEntity__c == '710 - AXA France Assurances' || Contract.cTin_OwnerEntity__c == '750 - Avanssur'){
                          language = 'French';
                      }else if(Contract.cTin_OwnerEntity__c == '1230 - AXA Spain'){
                          language = 'Spanish';
                      }else if(Contract.cTin_OwnerEntity__c == '1320 - AXA Switzerland'){
                          language = 'English';
                      }

                    eSignature__c esign = new eSignature__c(Name = Contract.Name,Contract__c = contract.Id,Status__c = 'Created',Language__c=language ,RecordTypeId= draftRT.Id,cTin_ContractForm__c=contractForm!= null ? contractForm.Id : null);
                    try{ 
                        System.Debug('### la signature avant :'+  esign ) ;  
                        sp = Database.setSavepoint();
                        insert esign;
                    }catch(Exception e){
                        //message You can not have more than one "In Progress" eSignature related to this Contract.                                                               
                        system.debug('##1 You can not have more than one "In Progress" eSignature related to this Contract.');
                        errorMessage+=system.label.ErrorMessageOneESign; notifyContractOwner=true;                                                                        
                        System.debug('####  End of the exception ') ; 
                    }
                    if(esign.Id != null){
                        eSignature = [SELECT Id, Name, Status__c,cTin_ContractForm__c, CreatedDate, Contract__r.Name, CreatedById,cTin_TECH_IsContractIn__c, 
                                    cTin_ShortDescription__c, FinalDocumentURL__c, cTin_KeyPoints__c, LastModifiedById,
                                    cTin_TotalSpendExcVAT2__c, cTin_StartDate__c, cTin_AXAMainLegalSignatoryEntity__c,
                                    cTin_SupplierLegalSignatoryEntity__c, cTin_AXAMainSignatoryRepresentative__c, 
                                    cTin_SupplierSignatoryRepresentative__c,cTin_FinalApproval1__c,cTin_FinalApproval2__c,
                                    cTin_FinalApproval3__c,cTin_FinalApproval4__c,cTin_FinalApproval5__c,cTin_FinalApproval6__c, 
                                    HandWrittenSignatureMode__c,cTin_FinalApproval7__c,cTin_FinalApproval8__c,TECH_AutomatedEsign__c,
                                    cTin_FinalApproval9__c,cTin_FinalApproval10__c,ExternalId__c,Contract__r.cTin_OwnerEntity__c,
                                    RecordTypeId,URL__c,Language__c  
                                    FROM eSignature__c 
                                    WHERE Id=:esign.Id];
                                
                        System.debug('###contract '+ contractId);
                        System.debug('###signature '+  eSignature.Id);
                        
                        //modif AMine 22/01/2015
                        //create eSignatories
                        if(contract.cTin_SupplierSignatoryRepresentative__c != null){
                            System.Debug(' #### contract.cTin_SupplierSignatoryRepresentative__r.Email: ' + contract.cTin_SupplierSignatoryRepresentative__r.Email) ; 
                            if(contract.cTin_SupplierSignatoryRepresentative__r.Email == null || !contract.cTin_SupplierSignatoryRepresentative__r.cTin_Active__c){
                                //message displayed :   Contact is not Active or does not have an Email.
                                system.debug('##2Contact is not Active or does not have an Email.');
                                errorMessage+= contract.cTin_SupplierSignatoryRepresentative__r.Name + system.label.ErrorMessageNoActiveMail;notifyContractOwner=true;
                            }else{
                                //MRA 050816: cater for unilateral 
                                if(contract.cTin_UnilateralSupplier__c || !contract.cTin_UnilateralAXARepresentative__c){                          
                                    eSignatory__c esignatorySupplier = (eSignatory__c)eSignatory__c.sObjectType.newSObject(Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId(), true) ; 
                                    esignatorySupplier.eSignature__c = eSignature.Id; 
                                    esignatorySupplier.cTin_OriginalRepresentative__c = true ;
                                    //esignatorySupplier.SupplierAccount__c=contract.cTin_SupplierAccount__c;
                                    esignatorySupplier.Contract__c = contract.Id;
                                    esignatorySupplier.Contact__c = contract.cTin_SupplierSignatoryRepresentative__r.Id;
                                    esignatorySupplier.FirstName__c = contract.cTin_SupplierSignatoryRepresentative__r.FirstName;
                                    esignatorySupplier.LastName__c = contract.cTin_SupplierSignatoryRepresentative__r.LastName;
                                    esignatorySupplier.MobileTxt__c = contract.cTin_SupplierSignatoryRepresentative__r.MobilePhone;
                                    esignatorySupplier.EmailTxt__c = contract.cTin_SupplierSignatoryRepresentative__r.Email;
                                    if(contract.cTin_SupplierSignatoryRepresentative__r.MobilePhone==null) esignatorySupplier.Code__c = 'email';
                                    esignatorySupplier.cTin_SupplierAccount__c = contract.cTin_SupplierSignatoryRepresentative__r.Account.id;
                                    esignatorySupplier.EsignatoryType__c = 'Customer';
                                    esignatorySupplier.entityName__c = contract.cTin_SupplierAccount__c;
                                    esignatorySupplier.OrderCreation__c = 1;
                                    esignatorySupplier.OrderCachet__c = 1;
                                    esignatorySupplier.OrderToSend__c = 0;
                                    esignatorySupplier.cTin_OrderToSetCoordinates__c = 0;
                                    esignatorySupplier.Order__c = 1;
                                    esignatorySupplier.x__c = 100;
                                    esignatorySupplier.y__c = 55;
                                    eSignatoryList.add(esignatorySupplier);
                                }
                            }
                        }
                                        
                        if (contract.cTin_AXASignatoryRepresentative__c != null && errorMessage == ''){
                            System.Debug(' #### contract.cTin_AXASignatoryRepresentative__r.Email: ' + contract.cTin_AXASignatoryRepresentative__r.Email) ;
                            if(contract.cTin_AXASignatoryRepresentative__r.Email == null || !contract.cTin_AXASignatoryRepresentative__r.cTin_Active__c){
                                //message displayed: Contact is not Active or does not have an Email.
                                system.debug('##4 Contact is not Active or does not have an Email' );
                                errorMessage += contract.cTin_AXASignatoryRepresentative__r.Name + system.label.ErrorMessageNoActiveMail;
                                notifyContractOwner = true;
                            }else if(contract.cTin_AXASignatoryRepresentative__r.Email == contract.cTin_SupplierSignatoryRepresentative__r.Email ){
                                //message displayed: contacts have same email
                                system.debug('##5 Contacts have same email');
                                errorMessage+=system.label.SameContactEmail;                        
                                Database.rollback(sp);
                                notifyContractOwner=true;   
                            }else{
                                //MRA 050816: cater for unilateral 
                                eSignatory__c esignatoryAxa = new eSignatory__c();         
                                esignatoryAxa.cTin_OriginalRepresentative__c= true ; 
                                esignatoryAxa.eSignature__c = eSignature.Id;  
                                esignatoryAxa.Contract__c = contract.Id;
                                esignatoryAxa.cTin_SupplierAccount__c = contract.cTin_AXASignatoryRepresentative__r.AccountId;
                                esignatoryAxa.Contact__c = contract.cTin_AXASignatoryRepresentative__r.Id;
                                esignatoryAxa.FirstName__c = contract.cTin_AXASignatoryRepresentative__r.FirstName;
                                esignatoryAxa.LastName__c = contract.cTin_AXASignatoryRepresentative__r.LastName;
                                esignatoryAxa.MobileTxt__c = contract.cTin_AXASignatoryRepresentative__r.MobilePhone;
                                esignatoryAxa.EmailTxt__c = contract.cTin_AXASignatoryRepresentative__r.Email;
                                if(contract.cTin_AXASignatoryRepresentative__r.MobilePhone==null) esignatoryAxa.Code__c='email';
                                esignatoryAxa.EsignatoryType__c = 'AXA';
                                esignatoryAxa.entityName__c = contract.cTin_AXASignatoryRepresentative__r.AccountId;
                                esignatoryAxa.recordtypeId = axaRepRT;

                                if(contract.cTin_UnilateralAXARepresentative__c){
                                    esignatoryAxa.Order__c = 1;
                                    esignatoryAxa.OrderCreation__c = 1;
                                    esignatoryAxa.OrderCachet__c = 1;
                                    esignatoryAxa.OrderToSend__c = 0;
                                    esignatoryAxa.cTin_OrderToSetCoordinates__c = 0;
                                    esignatoryAxa.x__c = 100;
                                    esignatoryAxa.y__c = 55;
                                }else if(!contract.cTin_UnilateralSupplier__c){
                                    esignatoryAxa.Order__c = 2;
                                    esignatoryAxa.OrderCreation__c = 2;
                                    esignatoryAxa.OrderCachet__c = 2;
                                    esignatoryAxa.OrderToSend__c = 1;
                                    esignatoryAxa.cTin_OrderToSetCoordinates__c = 1;
                                    esignatoryAxa.x__c = 390;
                                    esignatoryAxa.y__c = 55;
                                }
                                eSignatoryList.add(esignatoryAxa);
                            }
                        }
                        system.debug('## eSignatoryList : ' + eSignatoryList);
                        if(eSignatoryList.size() > 0){
                            try{     
                                insert eSignatoryList;
                            }
                            Catch(DMLException e){ system.debug('## error creating esignatory' + e.getMessage());notifyContractOwner=true;}

                            List<ContentDocumentLink> cdLink = [SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: contractId];
                            system.debug(' : ' +cdLink.size());
                            if(cdLink.size() > 0){
                                List<ContentDocumentLink > conClone = new List<ContentDocumentLink >();
                                for(ContentDocumentLink file: cdLink){
                                    List<contentversion> cv = [SELECT id,ContentDocumentId FROM contentversion WHERE ContentDocumentId =:file.ContentDocumentId  and Sign_able__c=:true];
                                    system.debug('##cv'+cv.size());
                                    if(cv.size() != 0){
                                        ContentDocumentLink newclnk = file.clone();
                                        newclnk.LinkedEntityId = eSignature.Id;
                                        newclnk.ShareType = 'V';
                                        conClone.add(newclnk);
                                    }
                                }                       
                                insert conClone;                    
                            }else{ 
                                System.Debug('#### AP07 no esign doc :') ;
                                errorMessage+=system.label.ErrorMessageEsignNoDocs;                             
                                Database.rollback(sp);
                                notifyContractOwner=true;
                            }               
                            
                            if(errorMessage != '') {  
                                try{
                                    delete esignature;
                                }
                                catch(Exception e)  {
                                    system.debug(' AP07 unable to delete esignature');
                                }   
                            }                            
                        }
                    }                    
                }else{
                    //message displayed when contract.owner!=universign profile
                    system.debug('## AP07 contract.owner!=universign profile');
                    errorMessage+=system.label.MessageBlockCreation2; 
                    notifyContractOwner=true;                           
                }
            }else{
                //error displayed when contract status != in signature or final document is not filled
                system.debug('## AP07 contract status != in signature or final document is not filled');
                errorMessage+=system.label.MessageBlockCreation;notifyContractOwner=true;                                   
            }
                
            //update field ErrorMessage on contract in case errors are encountered
            system.debug('AP07 errorMessage'+errorMessage);
            
            if(errorMessage!=''){
                contract.cTin_ErrorMessage__c = errorMessage;                  
            }else{
                contract.cTin_ErrorMessage__c = '';
            }
                
            update contract; 
            
            system.debug('## AP07 contract id'+contract.id);
            system.debug('## AP07 contract ownerId'+contract.OwnerId);
            system.debug('## AP07 notifyContractOwner'+notifyContractOwner);
            system.debug('## AP07 eSignature.id'+eSignature.id);
            //notify contract owner if creation of esignature fails
            if(notifyContractOwner){
                system.debug('## AP07 sending mail');
                List<Messaging.SingleEmailMessage> allMailsList = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();      
                mail.setTargetObjectId(contract.OwnerId);
                if(contract.cTin_OwnerEntityLocalCode__c == 'ACH') {
                    mail.setSubject(system.label.cTin_AP41EmailSubject);
                }else if(contract.cTin_OwnerEntityLocalCode__c == 'ADE') {
                    mail.setSubject(string.format(system.label.cTin_AP41EmailSubject_ADE, new string[]{contract.name}));
                }
                //mail.setOrgWideEmailAddressId(owea.get(0).Id);  
                mail.setSaveAsActivity(false);
            
                string linkToContract= URL.getSalesforceBaseUrl().toExternalForm() + '/'+ contract.id;
                string body='';
                //AMA Template german 26/07/2022 12:00
                if(contract.cTin_OwnerEntityLocalCode__c == 'ACH') {
                    body = string.format(system.label.cTin_AP41EmailBody, new string[]{contract.name,linkToContract});  
                } else if (contract.cTin_OwnerEntityLocalCode__c == 'ADE') {
                    body = string.format(system.label.cTin_AP41EmailBody_ADE, new string[]{contract.name,linkToContract,contract.cTin_Owner__c});
                }   
                mail.setHTMLBody(body);
                allMailsList.add(mail);
            
                //send email
                if(allMailsList.size()>0)
                Messaging.sendEmail(allMailsList);  
            }
            //MRA 28/05
            else{submitEsignature(eSignature.Id);}                             
            System.Debug('### la signature apres :'+  eSignature ) ;
        }//end if
        system.debug('## Ending method AP07_AutomateEsignature.createEsignature');
    }//end method
    
    @future (callout=true)
    public static void submitEsignature(id eSignId){
        Map<string,object> result = new Map<string,object>();
        List<ContentDistribution> cdistList = [ SELECT id,name, contentDownloadurl, pdfdownloadurl,distributionpublicurl,
                                                contentversion.sign_able__c,contentversion.islatest
                                                FROM ContentDistribution 
                                                WHERE RelatedRecordId=:eSignId ORDER BY createdDate ASC];
        List<esignatory__c> eSignatoryList = [SELECT Id, cTin_Role_Universign__c,Contact__r.Name,Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, 
                                            EmailTxt__c, Code__c, Order__c,EntityName__c, Name__c, cTin_Role__c, SuccessURL__c, FailURL__c, CancelURL__c, EsignatoryType__c,cTin_signLink__c,signURL__c,
                                            OrderToSend__c, x__c, y__c,contact__r.mobilephone,esignature__r.cTin_TECH_IsContractIn__c, Tech_OriginalSignatory__c, contact__r.FirstName, contact__r.LastName
                                            FROM eSignatory__c 
                                            WHERE eSignature__c=:eSignId ];  
        
        eSignature__c esignature = [SELECT Id, Language__c ,Error_Message__c, Name, Status__c, Contract__c, Contract__r.Customer_Operational_Contact__c, Contract__r.Customer_Operational_Contact__r.Email,TECH_AutomatedEsign__c,
                                    CreatedDate, Contract__r.Name, CreatedById, contract__r.status__c,
                                    FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c, TransactionID__c 
                                    FROM eSignature__c 
                                    WHERE Id=:eSignId];
        try{
            result = WS07_UniversignTransaction.createTransactionFull(esignature, eSignatoryList, cdistList);
            System.debug('## AP41_AutomateEsignature result: '+ result);
        }catch(Exception e){
            system.debug('An error occurred during the submission of the esignature : "'+esignature.Error_Message__c+'"');
        }
    }
}