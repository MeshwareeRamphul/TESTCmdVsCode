public with sharing class LC49_CreateSignature {
    /*
----------------------------------------------------------------------
-- - Name          : LC49_CreateSignature
-- - Author        : ARA
-- - Description   : Controller for lighning component LC49_CreateSignature
--                   @for creating eSignatures (applicable for OpCo only)
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 01-OCT-2020   ARA    1.0      Initial version 
-- 16-OCT-2021   ARA    1.1      Shield
--------------------------------------------------------------------------- */
    
    
    //methods checks if creation of eSignature should be blocked or allowed
    @AuraEnabled
    public static map<string,object> validateCreateSign(String contractId){
        Map<String,Object> mapOfResult = new Map<String,Object>();
        
        Contract__c contract = [SELECT Id, OwnerId, Name,FinalDocumentURL__c, AXA_GS_Signed_By__c, AXA_GO_Signed_By_2__c, CustomerSignedBy__c,Status__c,Language__c, C_Account__c,universign__c,TECH_Apex_Context__c,
                                CustomerSignedBy__r.Name, CustomerSignedBy__r.FirstName, CustomerSignedBy__r.LastName, CustomerSignedBy__r.MobilePhone, CustomerSignedBy__r.Email, CustomerSignedBy__r.Account.Name,
                                CustomerSignedBy2__r.Name, CustomerSignedBy2__r.FirstName, CustomerSignedBy2__r.LastName, CustomerSignedBy2__r.MobilePhone, CustomerSignedBy2__r.Email, CustomerSignedBy2__r.Account.Name,
                                AXA_GS_Signed_By__r.Name, AXA_GS_Signed_By__r.FirstName, AXA_GS_Signed_By__r.LastName, AXA_GS_Signed_By__r.MobilePhone, AXA_GS_Signed_By__r.Email,AXA_GS_Signed_By__r.AccountId, AXA_GS_Signed_By__r.Account.Name,
                                AXA_GO_Signed_By_2__r.Name, AXA_GO_Signed_By_2__r.FirstName, AXA_GO_Signed_By_2__r.LastName, AXA_GO_Signed_By_2__r.MobilePhone, AXA_GO_Signed_By_2__r.Email,AXA_GO_Signed_By_2__r.AccountId, AXA_GO_Signed_By_2__r.Account.Name
                                FROM Contract__c 
                                WHERE Id=:contractId];
        
        //Rule 1: block if contract status is not "Ready for Signature"
        if(contract.Status__c == AP_Constant.contractReadyStatus/* && contract.FinalDocumentURL__c != null*/) {
            set<id> ALLCDLIds = new set<id>();
            set<id> CDLIdToBeSigned = new set<id>();
            list<ContentDocumentLink> lstcdLink = new list<ContentDocumentLink>();
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId,LinkedEntityId
                                           FROM ContentDocumentLink
                                           WHERE LinkedEntityId =:contract.Id]){
                                               ALLCDLIds.add(cdl.ContentDocumentId);
                                           }
            
            for(ContentVersion  cv : [ SELECT ContentDocumentId, title FROM ContentVersion
                                      WHERE (ContentDocumentId  in :ALLCDLIds AND FileType ='pdf'/* AND Sign_able__c = true*/)]){
                                        if (cv.title.length() <= 89){
                                            CDLIdToBeSigned.add(cv.ContentDocumentId);
                                        }
                                        if(cv.title.containsAny('<>:"/\\|?*')){
                                            mapOfResult.put('error', system.label.ErrorMessageForDocsName) ;
                                            break;
                                        }
                                    }
            for(id signCdlID : CDLIdToBeSigned ){
                lstcdLink.add([SELECT ContentDocumentId,shareType,ContentDocument.title, ContentDocument.FileType,Id,LinkedEntityId 
                               FROM ContentDocumentLink
                               where ContentDocumentId = :signCdlID limit 1]);
            }
            
            //Rule 2: Block if no doc is uploaded on contract or all uploaded docs are not PDF                                     
            if(lstcdLink.size()>0){
                for(ContentDocumentLink cdlink: lstcdLink){
                    if(cdlink.ContentDocument.FileType != 'PDF'){
                        mapOfResult.put('error',system.label.LC16_ErrorDocumentType) ; 
                    }
                    if(cdlink.ContentDocument.title.length() >89 ) {
                        mapOfResult.put('error', system.label.LC16_ErrorDocumentLength);                       
                    }
                }
                // Create esignature
                if(!mapOfResult.containsKey('error')){
                    mapOfResult = createSign(contract, lstcdLink);
                    //mapOfResult.put('success', label.EsignatureCreatedSuccess);
                }
            }
            else{
                mapOfResult.put('error','You must generate a pdf file for the contract.');
            }
        }else{
            mapOfResult.put('error', label.MessageBlockCreation);
        }
        system.debug('******mapOfResult '+mapOfResult);
        return mapOfResult;
    }
    
    
    //method creates eSignature (for unilateral and bilateral scenario)
    @AuraEnabled
    public static map<string,object> createSign(Contract__c contract, List<ContentDocumentLink> lstcdLink){
        map<String,Object> mapOfResult = new map<String,Object>();
        string draftRtId=Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
        string signatoryAXART=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
        string signatorySupplierRT=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
        List<ContentDocumentLink> cdLinkSign = new list<ContentDocumentLink>();
        boolean Inserted = false;
        Integer order_number  = 1;
        Integer numeroOrdreDebut;
        Integer numeroOrdreFin;
        Integer nbDeleveryContent;

        Savepoint sp;
        list<esignatory__c> lstEsignatory = new list<esignatory__c>();
        list<String> lstEmail = new list<String>();
        
        eSignature__c eSignature = new eSignature__c(Name = contract.Name,
                                                     Contract__c = contract.Id,
                                                     Status__c = AP_Constant.eSignatureCreatedStatus,
                                                     language__c = contract.Language__c,                                     
                                                     RecordTypeId = AP_Constant.getRecordTypes('eSignature__c').get(AP_Constant.OpCo_Draft).Id);
        
        try{                        
            sp = Database.setSavepoint();
            if(Inserted == false){
                insert eSignature;
                mapOfResult.put('esignId',eSignature.Id);
                contract.universign__c        = true;
                contract.TECH_Apex_Context__c = false;
                update contract;             
                Inserted = true;  
            }  
        }
        catch(Exception e){
            //16-OCT-2021   ARA    1.1      Shield
            mapOfResult.put('error',e.getMessage().substring(e.getMessage().indexof(',')+1,e.getMessage().lastindexOf(':')).unescapeHtml4());
            //mapOfResult.put('error',label.ErrorMessageOneESign);
        }
        
        if (eSignature.Id != null){
            if(contract.AXA_GS_Signed_By__c != null){
                if(contract.AXA_GS_Signed_By__r.Email == null){
                    mapOfResult.put('error', 'Signatory ' + contract.AXA_GS_Signed_By__r.Name + ' '+ system.label.ErrorMessageNoActiveMail); 
                }else{
                    lstEsignatory.add(new esignatory__c(name                      = contract.AXA_GS_Signed_By__r.name,
                                                        eSignature__c             = eSignature.Id,
                                                        EntityName__c             = contract.AXA_GS_Signed_By__r.AccountId,
                                                        Contract__c               = contract.Id,
                                                        Contact__c                = contract.AXA_GS_Signed_By__r.Id,
                                                        FirstName__c              = contract.AXA_GS_Signed_By__r.FirstName,
                                                        LastName__c               = contract.AXA_GS_Signed_By__r.LastName,
                                                        MobileTxt__c              = contract.AXA_GS_Signed_By__r.MobilePhone,
                                                        EmailTxt__c               = contract.AXA_GS_Signed_By__r.Email,
                                                        EsignatoryType__c         = 'AXA',
                                                        cTin_role__c              = 'Signer',
                                                        OrderCreation__c          = order_number,
                                                        Order__c                  = order_number,
                                                        OrderToSend__c            = order_number-1,
                                                        code__c                   = (contract.AXA_GS_Signed_By__r.MobilePhone == null || contract.AXA_GS_Signed_By__r.MobilePhone == '') ? 'email' : 'sms',
                                                        Tech_OriginalSignatory__c = true
                                                        /*,EntityName__c = contract.C_Account__c*/));
                    lstEmail.add(contract.AXA_GS_Signed_By__r.Email);
                    order_number++;          
                }
            }
            if(!mapOfResult.containsKey('error') && contract.AXA_GO_Signed_By_2__c != null){
                if(contract.AXA_GO_Signed_By_2__r.Email == null){
                    mapOfResult.put('error', 'Signatory ' + contract.AXA_GO_Signed_By_2__r.Name + ' '+ system.label.ErrorMessageNoActiveMail); 
                }else{
                    lstEsignatory.add(new esignatory__c(name                      = contract.AXA_GO_Signed_By_2__r.name,
                                                        eSignature__c             = eSignature.Id,
                                                        EntityName__c             = contract.AXA_GO_Signed_By_2__r.AccountId,
                                                        Contract__c               = contract.Id,
                                                        Contact__c                = contract.AXA_GO_Signed_By_2__r.Id,
                                                        FirstName__c              = contract.AXA_GO_Signed_By_2__r.FirstName,
                                                        LastName__c               = contract.AXA_GO_Signed_By_2__r.LastName,
                                                        MobileTxt__c              = contract.AXA_GO_Signed_By_2__r.MobilePhone,
                                                        EmailTxt__c               = contract.AXA_GO_Signed_By_2__r.Email,
                                                        EsignatoryType__c         = 'AXA',
                                                        cTin_role__c              = 'Signer',
                                                        OrderCreation__c          = order_number,
                                                        Order__c                  = order_number,
                                                        OrderToSend__c            = order_number-1,
                                                        code__c                   = (contract.AXA_GO_Signed_By_2__r.MobilePhone == null || contract.AXA_GO_Signed_By_2__r.MobilePhone == '') ? 'email' : 'sms',
                                                        Tech_OriginalSignatory__c = true
                                                        /*,EntityName__c = contract.C_Account__c*/));
                    
                    if(lstEmail.contains(contract.AXA_GO_Signed_By_2__r.Email)){
                        mapOfResult.put('error', system.label.SameContactEmail);
                    }else{
                        lstEmail.add(contract.AXA_GO_Signed_By_2__r.Email);
                        order_number++;
                    }
                }
            }

            //if(!contract.unilateralAXA__c && !mapOfResult.containsKey('error')){
            if (!mapOfResult.containsKey('error') && contract.CustomerSignedBy__c != null){
                if(contract.CustomerSignedBy__r.Email == null) {
                    mapOfResult.put('error', 'Signatory ' + contract.CustomerSignedBy__r.Name + ' '+ system.label.ErrorMessageNoActiveMail);      
                }else{
                    lstEsignatory.add(new esignatory__c(name                      = contract.CustomerSignedBy__r.name,
                                                        eSignature__c             = eSignature.Id,
                                                        EntityName__c             = contract.CustomerSignedBy__r.AccountId,
                                                        Contract__c               = contract.Id,
                                                        Contact__c                = contract.CustomerSignedBy__r.Id,
                                                        FirstName__c              = contract.CustomerSignedBy__r.FirstName,
                                                        LastName__c               = contract.CustomerSignedBy__r.LastName,
                                                        MobileTxt__c              = contract.CustomerSignedBy__r.MobilePhone,
                                                        EmailTxt__c               = contract.CustomerSignedBy__r.Email,
                                                        EsignatoryType__c         = 'Customer',
                                                        cTin_role__c              = 'Signer',
                                                        OrderCreation__c          = order_number,
                                                        Order__c                  = order_number,
                                                        OrderToSend__c            = order_number-1,
                                                        code__c                   = (contract.CustomerSignedBy__r.MobilePhone == null || contract.CustomerSignedBy__r.MobilePhone == '') ? 'email' : 'sms',
                                                        Tech_OriginalSignatory__c = true
                                                        /*,EntityName__c=contract.C_Account__c*/));

                    if(lstEmail.contains(contract.CustomerSignedBy__r.Email)){
                        mapOfResult.put('error', system.label.SameContactEmail);
                    }else{
                        lstEmail.add(contract.CustomerSignedBy__r.Email);
                        order_number++;
                    }
                }
            }

            if (!mapOfResult.containsKey('error') && contract.CustomerSignedBy2__c != null){
                if(contract.CustomerSignedBy2__r.Email == null) {
                    mapOfResult.put('error', 'Signatory ' + contract.CustomerSignedBy2__r.Name + ' '+ system.label.ErrorMessageNoActiveMail);      
                }else{
                    lstEsignatory.add(new esignatory__c(name                      = contract.CustomerSignedBy2__r.name,
                                                        eSignature__c             = eSignature.Id,
                                                        EntityName__c             = contract.CustomerSignedBy2__r.AccountId,
                                                        Contract__c               = contract.Id,
                                                        Contact__c                = contract.CustomerSignedBy2__r.Id,
                                                        FirstName__c              = contract.CustomerSignedBy2__r.FirstName,
                                                        LastName__c               = contract.CustomerSignedBy2__r.LastName,
                                                        MobileTxt__c              = contract.CustomerSignedBy2__r.MobilePhone,
                                                        EmailTxt__c               = contract.CustomerSignedBy2__r.Email,
                                                        EsignatoryType__c         = 'Customer',
                                                        cTin_role__c              = 'Signer',
                                                        OrderCreation__c          = order_number,
                                                        Order__c                  = order_number,
                                                        OrderToSend__c            = order_number-1,
                                                        code__c                   = (contract.CustomerSignedBy2__r.MobilePhone == null || contract.CustomerSignedBy2__r.MobilePhone == '') ? 'email' : 'sms',
                                                        Tech_OriginalSignatory__c = true
                                                        /*,EntityName__c=contract.C_Account__c*/));

                    if(lstEmail.contains(contract.CustomerSignedBy2__r.Email)){
                        mapOfResult.put('error', system.label.SameContactEmail);
                    }else{
                        lstEmail.add(contract.CustomerSignedBy2__r.Email);
                    }
                }
            }
            
            if(!mapOfResult.containsKey('error')){
                if(lstEsignatory.size() > 0){
                    try{
                        //MRA - 20-Oct-20 : Added code to set x and y coordinates on creation of esignatory  
                        Integer position_x = 1;
                        for(esignatory__c esignatory: lstEsignatory){
                            // Modification pour l'ordre des cachets sur une signature
                            Decimal x = (Decimal)position_x/2;
                            esignatory.x__c = math.mod(position_x,2) == 0 ? 380 : 80;
                            esignatory.y__c = x.round(System.RoundingMode.UP) * 55;
                            esignatory.OrderCachet__c  = position_x;
                            esignatory.OrderToSend__c  = position_x-1;
                            position_x++;
                        }
                        insert lstEsignatory;   
                       
                        for(ContentDocumentLink cdLink: lstcdLink){
                            ContentDocumentLink cd = new ContentDocumentLink(LinkedEntityId = eSignature.Id,
                                                                             ContentDocumentId = cdLink.ContentDocumentId,
                                                                             ShareType = 'V',
                                                                             Visibility = 'AllUsers');
                            //shareType=cdLink.shareType);
                            cdLinkSign.add(cd);
                        }
                        try{
                            insert cdLinkSign;                   
                        }catch(Exception e){
                            mapOfResult.put('error', e.getMessage());
                        }

                        //USA 20180424 : sign multi documents
                        List<ContentDistribution> cdistList = new List<ContentDistribution>();
                        Integer counter = 1;
                        for (ContentDistribution cntDis : [
                                SELECT Name,ownerID, CreatedDate, RelatedRecordId,ContentDocumentId, DistributionPublicUrl,ContentVersionId, ContentVersion.TECH_GeneratedByUpdatePDF__c, ContentVersion.ContentDocument.FileType
                                FROM ContentDistribution
                                WHERE RelatedRecordId = :contract.Id
                                AND ContentVersion.ContentDocument.FileType = 'PDF'
                                ORDER BY ContentVersion.TECH_GeneratedByUpdatePDF__c desc, CreatedDate desc
                        ]) {
                            if (counter == 1) {
                                cdistList.add(cntDis);
                            } else {
                                if (!cntDis.ContentVersion.TECH_GeneratedByUpdatePDF__c) {
                                    cdistList.add(cntDis);
                                }
                            }
                            counter++;
                        }

                        if(cdistList.size() > 0 && eSignature.Id != null ){
                            //boolean notCorrespondingUrl = false ;                          
                            for(ContentDistribution cd :  cdistList ){                   
                                if(cd.ContentDocumentId!= null){                          
                                    if(cd.ContentVersionId != null ){
                                        ContentDistribution eSignCD = new ContentDistribution(RelatedRecordId        = eSignature.Id,
                                                                                            Name                     = cd.Name,
                                                                                            ContentVersionId         = cd.ContentVersionId,
                                                                                            PreferencesNotifyOnVisit = false);
                                        // Rajout de try catch for Rollback purpose
                                        try{ 
                                            insert eSignCD;
                                        }
                                        catch(Exception e){
                                            system.debug('## catch error 2'+ e.getMessage());
                                        }   
                                    }
                                    else { 
                                        mapOfResult.put('error', label.ErrorMessafeForDocs); 
                                    }                         
                                }
                            } 
                        } 
                        else { 
                            mapOfResult.put('error', label.ErrorMessageEsignNoDocs); 
                        } 
                    }catch(Exception e){
                        mapOfResult.put('error', e.getMessage());
                    }
                }
            }else{
                list<esignature__c> esignLst=[SELECT contract__c, id,cTin_TECH_IsContractIn__c FROM esignature__c WHERE contract__c=:contract.Id];
                if(esignLst.size() > 0){
                    delete esignLst;
                }
            }
        }
        if(!mapOfResult.containsKey('error')){
            mapOfResult.put('success', Label.EsignatureCreatedSuccess);
        }
        return mapOfResult;
    }
}