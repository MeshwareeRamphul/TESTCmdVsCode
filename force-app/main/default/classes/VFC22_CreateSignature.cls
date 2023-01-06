public with sharing class VFC22_CreateSignature {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_CreateSignature
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class Ctrl_CreateSignatureV3)
-- - Description   : This class contains methods to create Esignature/esignatories and to specify sign order of esignatories
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 17-APR-2017  MRA    1.0     Copied and renamed to VFC22_CreateSignature
-- 27-APR-2017  MRA    1.1     Updated w.r.t All In requirements 
-- 11-AUG-2017  MRA    1.2     Check TECH_Apex_Context__c when creating esignature to prevent VR(FieldRequired_UpdatebySysAdmAndPMO)
                               from blocking status update on contract
-- 06-APR-2018  MRA    1.3     Updated method Submit - Do not generation Invoice lines for  ATS on submit of esignature 
-- 22-JUN-2018  USA    1.4     Multi signatories 
-- 09-JUL-2018  USA    1.5     Rework some methods (optimisation)
-- 26-JUL-      MRA    1.6     Unilateral AXA ( ALLINFIN-591 )
-- 11-AUG-2020  USA    1.7     SP-00375
-- 11-AUG-2020  USA    1.8     SP-00382
*************************************************************************************/

    public eSignature__c           eSignature        {get;set;}
    public boolean                 showpageblock     {get;set;}
    public Id                      contractId        {get;set;}
    public Id                      eSignatureId      {get;set;}
    public String                  esignatoryBis_Id  {get;set;}
    public Contract__c             contract          {get;set;}
    public List<eSignatory__c>     eSignatoryList    {get;set;}
    public Integer                 numeroOrdreDebut  {get;set;}
    public Integer                 numeroOrdreFin    {get;set;}
    public Integer                 nbDeleveryContent {get;set;}
    public static Id               eSingId           {get;set;}
    //public Integer                 delete_id         {get;set;}
    public Integer                 add_order         {get;set;}    
    public String                  contact_Id        {get;set;}
    public Contact                 mySelectedcon     {get;set;}   
    //public Integer                 ordredescente     {get;set;} 
    public boolean                 add               {get;set;}
    public Id                      eSignatoryId      {get;set;}
    //public Boolean                 Is_ERR            {get;set;}
    public String                  MY_EMAIL_ERR_MSG  {get;set;}
    public String                  MY_ERR_MSG        {get;set;}
    public String                  MY_ERRROR_ALL     {get;set;}
    public String                  MY_CON_ERR_MSG    {get;set;}

    public boolean hasContact;

    public Boolean                 DoNotContinue;
    public boolean                 Inserted            = false;
    public Integer                 order_number;
    public Map<String, RecordType> esignRtNameMap      = AP_Constant.getRecordTypes('eSignature__c');
    public String                  recordtypeIdToQuery = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
  
    //check if a parameter is filled or not
    /*public static Boolean empty(Object o){
        return o==null || String.valueOf(o)=='';
    }*/
 
    public VFC22_CreateSignature(){
        contractId     = ApexPages.currentPage().getParameters().get('contractId'); //create esignature from contract
        eSignatureId   = ApexPages.currentPage().getParameters().get('eSignatureId'); //submit esignature from esignature
        eSingId        = ApexPages.currentPage().getParameters().get('id');//esit esignature 

        hasContact     = true;

        try{
            eSignatoryId = ApexPages.currentPage().getParameters().get('signatoryId');
        }
        catch(Exception e){
            // do nothing
        }

        MY_ERRROR_ALL = System.label.MessageMobileBlock; 
        add           = false;
        order_number  = 1; 
    }
  
    /*public PageReference redirect(){                
        return new PageReference('/'+contractId) ; 
    }*/

  //USA 2018/07/09 : rework method backToContract
    public PageReference backToContract(){
        if (contractId != null){
            List<eSignature__c> lstSig = [SELECT id, name FROM eSignature__c WHERE Status__c = :AP_Constant.eSignatureCreatedStatus AND Contract__c = :contractId];
            /*if (lstSig.size()>0){
                delete lstSig;
            }*/

            return new PageReference('/'+contractId) ; 
        }
        /*else if (eSignatureId != null){
            return new PageReference('/'+eSignatureId) ; 
        }*/  
        return null;
    }
  

    //USA 2018/07/09 : rework method createSignature
    public PageReference createSignature(){
        list<eSignatory__c> esignatoryLst = new list<eSignatory__c>(); 
        DoNotContinue                     = false;
        Savepoint sp;   
        showpageblock                     = true;
        Set<String> setClassicThemes = new Set<String>{'Theme2','Theme3'};
        Set<String> setLightningThemes = new Set<String>{'Theme4d'};

        system.debug('##createSignature## contractId : ' + contractId);
        system.debug('##createSignature## eSignatureId : ' + eSignatureId);

        if(contractId!=null){ //create eSignature
            contract = [SELECT Id, OwnerId, Name,FinalDocumentURL__c, AXA_GS_Signed_By__c, CustomerSignedBy__c,Status__c,Language__c, C_Account__c,universign__c,TECH_Apex_Context__c,
                               CustomerSignedBy__r.Name, CustomerSignedBy__r.FirstName, CustomerSignedBy__r.LastName, CustomerSignedBy__r.MobilePhone, CustomerSignedBy__r.Email, CustomerSignedBy__r.Account.Name,
                               AXA_GS_Signed_By__r.Name, AXA_GS_Signed_By__r.FirstName, AXA_GS_Signed_By__r.LastName, AXA_GS_Signed_By__r.MobilePhone, AXA_GS_Signed_By__r.Email,AXA_GS_Signed_By__r.AccountId, AXA_GS_Signed_By__r.Account.Name
                          FROM Contract__c 
                         WHERE Id=:contractId];

            if(contract.Status__c==AP_Constant.contractReadyStatus  && contract.FinalDocumentURL__c  != null) {
                RecordType draftRT = esignRtNameMap.get(AP_Constant.recordTypeDraft);        
                eSignature         = new eSignature__c(Name         = Contract.Name,
                                                       Contract__c  = contract.Id,
                                                       Status__c    = AP_Constant.eSignatureCreatedStatus,
                                                       RecordTypeId = draftRT.Id,
                                                       Language__c  = contract.Language__c);                     
                try{                        
                    sp = Database.setSavepoint();
                    if(Inserted == false){
                        insert eSignature;
                        contract.universign__c        = true;
                        contract.TECH_Apex_Context__c = true;
                        update contract;                
                        Inserted = true;  
                    }  
                }
                catch(Exception e){
                    /*system.Debug('##VFC22_CreateSignature.createSignature## begin of the exception : '+ e.getMessage()) ; 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,label.ErrorMessageOneESign) ) ; 
                    showpageblock=false ;   */                         
                }
                system.debug('##createSignature## eSignature : ' + eSignature);

                if (eSignature.Id != null){
                    //if(!contract.unilateralAXA__c){
                        if (contract.CustomerSignedBy__c !=null && contract.CustomerSignedBy__r.Email == null) {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error ,'Signatory ' + contract.CustomerSignedBy__r.Name + ' '+ system.label.ErrorMessageNoActiveMail ));  
                            showpageblock=false ;    
                            DoNotContinue = true ;
                        }   

                        if(contract.CustomerSignedBy__c != null && DoNotContinue==false ){
                            esignatoryLst.add(new esignatory__c(name                      = contract.CustomerSignedBy__r.name,
                                                                eSignature__c             = eSignature.Id,
                                                                /*EntityName__c=contract.C_Account__c,*/
                                                                EntityName__c             = contract.CustomerSignedBy__r.AccountId,
                                                                Contract__c               = contract.Id,
                                                                Contact__c                = contract.CustomerSignedBy__r.Id,
                                                                FirstName__c              = contract.CustomerSignedBy__r.FirstName,
                                                                LastName__c               = contract.CustomerSignedBy__r.LastName,
                                                                MobileTxt__c              = contract.CustomerSignedBy__r.MobilePhone,
                                                                EmailTxt__c               = contract.CustomerSignedBy__r.Email,
                                                                OrderCreation__c          = order_number + 1,
                                                                Order__c                  = order_number + 1,
                                                                code__c                   = 'sms',
                                                                Tech_OriginalSignatory__c = true));
                        }

                        system.debug('##createSignature## esignatoryLst : ' + esignatoryLst);
                   //}

                    if(contract.AXA_GS_Signed_By__c != null && contract.AXA_GS_Signed_By__r.Email == null){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error , 'Signatory ' + contract.AXA_GS_Signed_By__r.Name + ' '+ system.label.ErrorMessageNoActiveMail ));  
                        showpageblock=false ;
                        DoNotContinue = true ;
                    }    

                    if( contract.CustomerSignedBy__r.Email == contract.AXA_GS_Signed_By__r.Email/* && !contract.unilateralAXA__c*/){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error , system.label.SameContactEmail)) ;  
                        showpageblock=false ;
                        DoNotContinue = true ;
                        Database.rollback(sp);
                    }

                    if(contract.AXA_GS_Signed_By__C !=null  && DoNotContinue==false ){
                        esignatoryLst.add(new esignatory__c(name                      = contract.AXA_GS_Signed_By__r.name,
                                                            eSignature__c             = eSignature.Id,
                                                            EntityName__c             = contract.AXA_GS_Signed_By__r.AccountId,
                                                            Contract__c               = contract.Id,
                                                            Contact__c                = contract.AXA_GS_Signed_By__r.Id,
                                                            FirstName__c              = contract.AXA_GS_Signed_By__r.FirstName,
                                                            LastName__c               = contract.AXA_GS_Signed_By__r.LastName,
                                                            MobileTxt__c              = contract.AXA_GS_Signed_By__r.MobilePhone,
                                                            EmailTxt__c               = contract.AXA_GS_Signed_By__r.Email,
                                                            OrderCreation__c          = order_number,
                                                            Order__c                  = order_number,
                                                            code__c                   = 'sms',
                                                            Tech_OriginalSignatory__c = true
                                                            /*,EntityName__c = contract.C_Account__c*/));              
                    }

                    if(esignatoryLst.size()>0){
                        try{
                            insert esignatoryLst;
                        }
                        catch(DMLException e){
                            /*ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));  
                            showpageblock=false ; */  
                        }
                    } 

                    system.debug('##createSignature## esignatoryLst 2 : ' + esignatoryLst);

                    if(DoNotContinue){
                        list<esignature__c> esignLst=[SELECT contract__c, id,cTin_TECH_IsContractIn__c FROM esignature__c WHERE contract__c=:contractId];
                        if(esignLst.size()>0){
                            delete esignLst;
                        }
                    }    

                    eSignatoryList = [ SELECT Id, Contact__r.Name,contract__r.Id,name__c, contract__r.AXA_Gs_Signed_By__c,FirstName__c, 
                                              LastName__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c, Contact__c,
                                              SuccessURL__c, FailURL__c, CancelURL__c, EntityName__c, Tech_OriginalSignatory__c
                                         FROM eSignatory__c 
                                        WHERE eSignature__c=:eSignature.Id                            
                                     order by Order__c ];

                    system.debug('##createSignature## >> eSignatoryList: ' + eSignatoryList);

                    if(eSignatoryList.size()>0){
                        numeroOrdreDebut    = Integer.valueOf(eSignatoryList.get(0).Order__c);
                        Integer  tailleList = eSignatoryList.size()-1;
                        numeroOrdreFin      = Integer.valueOf(eSignatoryList.get(tailleList).Order__c);
                    }

                    //USA 20180424 : sign multi documents
                    List<ContentDistribution> cdistList = new List<ContentDistribution>();
                    Integer counter = 1;

                    //classic version
                    if (setClassicThemes.contains(UserInfo.getUiThemeDisplayed())) {
                        for (ContentDistribution cntDis : [
                                SELECT Name,ownerID, CreatedDate, RelatedRecordId,ContentDocumentId, DistributionPublicUrl,ContentVersionId, ContentVersion.TECH_GeneratedByUpdatePDF__c, ContentVersion.ContentDocument.FileType
                                FROM ContentDistribution
                                WHERE RelatedRecordId = :contractId
                                ORDER BY ContentVersion.TECH_GeneratedByUpdatePDF__c desc, CreatedDate desc
                        ]) {
                            system.debug('##createSignature## cntDis : ' + cntDis);
                            system.debug('##createSignature## cntDis FileType : ' + cntDis.ContentVersion.ContentDocument.FileType);
                            /*if (cntDis.ContentVersion.ContentDocument.FileType != 'PDF') {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'All Content Deliveries should be in PDF format.')) ;
                                showpageblock = false ;
                                Database.rollback(sp);
                            }*/

                            if (counter == 1) {
                                cdistList.add(cntDis);
                            } else {
                                if (!cntDis.ContentVersion.TECH_GeneratedByUpdatePDF__c) {
                                    cdistList.add(cntDis);
                                }
                            }
                            counter++;
                        }
                    }
                    /*else if (setLightningThemes.contains(UserInfo.getUiThemeDisplayed())){
                        for (ContentDistribution cntDis : [
                                SELECT Name,ownerID, CreatedDate, RelatedRecordId,ContentDocumentId, DistributionPublicUrl,ContentVersionId, ContentVersion.TECH_GeneratedByUpdatePDF__c, ContentVersion.ContentDocument.FileType
                                FROM ContentDistribution
                                WHERE RelatedRecordId = :contractId
                                AND ContentVersion.ContentDocument.FileType = 'PDF'
                                ORDER BY ContentVersion.TECH_GeneratedByUpdatePDF__c desc, CreatedDate desc
                        ]) {
                            system.debug('##createSignature## cntDis lEX : ' + cntDis);
                            system.debug('##createSignature## cntDis FileType LEX : ' + cntDis.ContentVersion.ContentDocument.FileType);
                            if (counter == 1) {
                                cdistList.add(cntDis);
                            } else {
                                if (!cntDis.ContentVersion.TECH_GeneratedByUpdatePDF__c) {
                                    cdistList.add(cntDis);
                                }
                            }
                            counter++;
                        }
                    }*/

                    if(cdistList.size()>0 && eSignature.Id != null ){
                        //boolean notCorrespondingUrl = false ;                          
                        for(ContentDistribution cd :  cdistList ){                   
                            //if(cd.DistributionPublicUrl == contract.FinalDocumentURL__c ){
                                //notCorrespondingUrl = true ; 
                                //ContentVersion cVersion = new ContentVersion () ; 
                            if(cd.ContentDocumentId!= null){ 
                                /* Cette Section est specifique pour vérifier que le document est partagé.
                                Si une distribution de document est crée cela veut dire qu'un document et une version existe.
                                Si la variable cVersion est vide, cela veut dire que le document n'est pas partagé avec l'utilisateur connecté.
                                d'où l'erreur, 'Le document doit etre partagé' */
                                //try{                        
                                //  cVersion = [SELECT VersionData,OwnerID,ContentDocumentId, ContentDocument.PublishStatus 
                                //  FROM ContentVersion 
                                //  WHERE ContentDocumentID =:cd.ContentDocumentId limit 1];              
                                //} catch(Exception e){                              
                                //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,label.ErrorMessafeForDocs) ) ; showpageblock=false ;
                                //}                              
                                if(cd.ContentVersionId != null ){
                                    ContentDistribution eSignCD = new ContentDistribution(RelatedRecordId          = eSignature.Id,
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
                                /*else { 
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.ErrorMessafeForDocs) ) ; 
                                    showpageblock=false ;  
                                }      */                   
                            }
                        }
                        // Gestion du message d'erreur si aucune des Urls des documents ne correspond pas au Final Url du contract                 
                        //if(notCorrespondingUrl == false){
                        //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.ErrorMessageUrlBlock) ) ; showpageblock=false ; 
                        //}     
                    } 
                    /*else { 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,label.ErrorMessageEsignNoDocs)) ; 
                        showpageblock=false ; 
                        Database.rollback(sp);
                    } */
                    nbDeleveryContent = cdistList.size();
                }
            }
            /*else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,label.MessageBlockCreation) ) ; 
                showpageblock=false ;
            }*/
        }
        /*if(eSignatureId != null){ //edit eSignature
            //if(eSignature.Id != null){ 
            eSignature     = [Select Id, Name, Status__c, CreatedDate, Contract__r.Name, CreatedById, 
                                     FinalDocumentURL__c,LastModifiedById,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c,
                                     ExternalId__c,RecordTypeId,URL__c,Language__c  
                                FROM eSignature__c 
                               WHERE id= :eSignatureId //:eSignature.Id
                               LIMIT 1];

            eSignatoryList = [ SELECT Id, Contact__r.Name, contract__r.Id, contract__r.C_Account__c,Name__c, 
                                      contract__r.AXA_GS_Signed_By__c, contract__r.CustomerSignedBy__c
                                      ,FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
                                      Code__c, Order__c, Contact__c, EntityName__c, SuccessURL__c, 
                                      FailURL__c, CancelURL__c,eSignature__c,eSignature__r.name,eSignature__r.contract__c,
                                      eSignature__r.Status__c,eSignature__r.CreatedDate,eSignature__r.contract__r.name,
                                      eSignature__r.CreatedById,eSignature__r.FinalDocumentURL__c,eSignature__r.ExternalId__c,
                                      eSignature__r.URL__c,eSignature__r.LastModifiedById,eSignature__r.Language__c, Tech_OriginalSignatory__c
                                 FROM eSignatory__c 
                                WHERE eSignature__c=:eSignatureId                         
                             ORDER BY Order__c ];

            Integer i = 0;
            while (hasContact && i<eSignatoryList.size()){
                if (eSignatoryList[i].contact__c == null){
                    hasContact = false;
                }
                i++;
            }

            //show Delivery content number
            List<ContentDistribution> cdistList = [SELECT Name, RelatedRecordId, ContentDocumentId, DistributionPublicUrl 
                                                     FROM ContentDistribution 
                                                    WHERE RelatedRecordId=:eSignatureId 
                                                    limit 1];
            nbDeleveryContent = cdistList.size();
              
            if(eSignatoryList.size() > 0){                   
                numeroOrdreDebut    = Integer.valueOf(eSignatoryList.get(0).Order__c);
                Integer  tailleList = eSignatoryList.size()-1;
                numeroOrdreFin      = Integer.valueOf(eSignatoryList.get(tailleList).Order__c);   
            } 
        }*/
        return null;
    }
     
    // method decrements signatory order
    /*public  PageReference descendre(){
        ordredescente=Integer.valueOf(ApexPages.currentPage().getParameters().get('ordre_descente'));
        Map<Decimal,List<esignatory__c>> mapEsignatory       = new Map<Decimal,List<esignatory__c>>();
        Map<Id, eSignatory__c>           mapTempEsign        = new Map <Id,eSignatory__c>();
        List<eSignatory__c>              listWithoutObserver = new List<eSignatory__c>();
 
        for(eSignatory__c e : eSignatoryList){
            mapTempEsign.put(e.Id, e);
        }

        //create a familly
        for(eSignatory__c familly : eSignatoryList){  
            eSignatory__c parent               = familly;
            List <eSignatory__c> childrenList  = new List<eSignatory__c>();  
            List<eSignatory__c> familyTempList = new List <eSignatory__c>();
            familyTempList.add(parent);
            familyTempList.addAll(childrenList); 
            mapEsignatory.put(parent.Order__c, familyTempList);       
        }

        if(mapEsignatory.containsKey(ordredescente)){
           
            List<eSignatory__c> listFromMap    = mapEsignatory.get(ordredescente);
            List<eSignatory__c> listDown       = new List<eSignatory__c>();
            List<eSignatory__c> listUp         = new List<eSignatory__c>();
            Integer             nextKey        = listFromMap.size();
            Integer             ordreSuivant   = ordredescente+nextKey;
           
            listUp = mapEsignatory.get(ordreSuivant);
            listDown.addAll(listFromMap);    
            //list DOwn
            mapEsignatory.put(ordreSuivant, listDown);        
            //list Up      
            mapEsignatory.put(ordredescente, listUp);                
        }
            
        Integer order = 0;
           
        List<Decimal> sortedKeys = new List<Decimal>(mapEsignatory.keySet());
        sortedKeys.sort();
        eSignatoryList.clear();

        for(Decimal key : sortedKeys) {
            List <eSignatory__c> updateOrdreList = new  List <eSignatory__c>();
            if(mapEsignatory.get(key)!= null) updateOrdreList = mapEsignatory.get(key);
            if(updateOrdreList.size()>0){
                for(eSignatory__c eSignElem : updateOrdreList){
                    eSignElem.Order__c = order+1;
                    update eSignElem;
                    eSignatoryList.add(eSignElem);
                    order++;
                }
            } 
        }
              
        if(!empty(eSignatoryList)){               
            for(eSignatory__c eAll : eSignatoryList){                
                listWithoutObserver.add(eAll);                 
            }

            numeroOrdreDebut    = Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin      = Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
 
        }       
        return null;
    }*/

    //method increments signatory order
    /*public PageReference monter(){

        ordredescente=Integer.valueOf(ApexPages.currentPage().getParameters().get('ordre_descente'));
        Map<Decimal,List<esignatory__c>> mapEsignatory       = new Map<Decimal,List<esignatory__c>>();
        Map<Id,eSignatory__c>            mapTempEsign        = new Map <Id,eSignatory__c>();
        List<eSignatory__c>              listPrevious        = new List <eSignatory__c>();
        List<eSignatory__c>              listWithoutObserver = new List<eSignatory__c>();

        for(eSignatory__c e : eSignatoryList){
            mapTempEsign.put(e.Id, e);
        }
 
         //create a familly
        for(eSignatory__c familly : eSignatoryList){             
            eSignatory__c       parent         = familly;
            List<eSignatory__c> childrenList   = new List<eSignatory__c>();  
            List<eSignatory__c> familyTempList = new List <eSignatory__c>();
            familyTempList.add(parent);           
            //put family in the map
            mapEsignatory.put(parent.Order__c, familyTempList);       
        }
 
        for(esignatory__c tempElem: eSignatoryList){
           
            if(tempElem.Order__c == ordredescente-1){           
                id IdtempParent      = tempElem.Id;
                eSignatory__c parent = mapTempEsign.get(IdtempParent);
                Decimal orderParent  = parent.Order__c;
                listPrevious         = mapEsignatory.get(orderParent);
            }
            else if(tempElem.Order__c == ordredescente-1){
                listPrevious = mapEsignatory.get(tempElem.Order__c);
            }
        }
            
        List<eSignatory__c> listFromMap    = mapEsignatory.get(ordredescente);
        List<eSignatory__c> listDown       = new List<eSignatory__c>();
        List<eSignatory__c> listUp         = new List<eSignatory__c>();
        Integer             previousKey    = listPrevious.size(); 
        Integer             ordrePrecedent = ordredescente-previousKey;

        listUp.addAll(listFromMap);
        listDown = mapEsignatory.get(ordrePrecedent);
                
        //list Down
        mapEsignatory.put(ordrePrecedent, listUp);
      
        //list up                         
        mapEsignatory.put(ordredescente, listDown);

        Integer order = 0;          
        List<Decimal> sortedKeys = new List<Decimal>(mapEsignatory.keySet());
        sortedKeys.sort();
        eSignatoryList.clear();

        for(Decimal key : sortedKeys) {
            List <eSignatory__c> updateOrdreList = mapEsignatory.get(key);
            for(eSignatory__c eSignElem : updateOrdreList){
                eSignElem.Order__c = order+1;
                try{update eSignElem;}
                catch(Exception e){}
                eSignatoryList.add(eSignElem);
                order++;
            }
        }

        if(!empty(eSignatoryList)){     
            for(eSignatory__c eAll : eSignatoryList){         
                listWithoutObserver.add(eAll);        
            }

            numeroOrdreDebut    = Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin      = Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
        }       
        return null; 
    }*/
 
    public PageReference save(){      
        /**Declaration des variables**/
        integer PositionX = 0 ; 
        List<eSignatory__c>          ListNegotiator        = new List<eSignatory__c>();
        List<eSignatory__c>          ListRepresentatif     = new List<eSignatory__c>();   
        Map<ID, List<eSignatory__c>> MapSignatoWchids      = new Map<ID,List<eSignatory__c>>(); 
        List<eSignatory__c>          ListSigToUpdate       = new List<eSignatory__c>();
        List<Contact>                ListContacts          = new List<Contact>(); 
        Map<Id,Contact>              MapContact            = new Map<ID,Contact>();  
        List<eSignatory__c>          ListSignatoryToUpsert = new List<eSignatory__c>(); 

         List<eSignatory__c>         ListSignatoryToUpsertNew = new List<eSignatory__c>();      
        List<eSignatory__c>          ListSignatoryToDelete    = new List<eSignatory__c>();           

        add = false;
        try{
            if(MY_ERR_MSG != null && MY_ERR_MSG != ''){
               eSignatoryList.remove(eSignatoryList.size()-1);
            }         
            upsert eSignature ;  
            for (Integer i=0; i<eSignatoryList.size();i++){
                if (eSignatoryList[i].contact__c != null){
                    ListSignatoryToUpsertNew.add(eSignatoryList[i]);
                }
                else{
                    ListSignatoryToDelete.add(eSignatoryList[i]);
                }
            }  
            upsert ListSignatoryToUpsertNew; //eSignatoryList;
            if (ListSignatoryToDelete.size() > 0){
                delete ListSignatoryToDelete;
            }

            system.debug('##save## eSignature : ' + eSignature);
            system.debug('##save## eSignatoryList : ' + eSignatoryList);
        }Catch(Exception e){ 
            system.debug('##save## e.getMessage()2 : ' + e.getMessage());        
            return null; 
        }
      
        eSignatoryList = [SELECT Id,contract__r.Id, Name__c , Contact__c, FirstName__c, LastName__c,Name,                
                                 Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c, EntityName__c,
                                 SuccessURL__c, FailURL__c, CancelURL__c 
                            FROM eSignatory__c 
                           WHERE eSignature__c=:eSignature.Id 
                             AND Order__c != null
                        order by Order__c asc];

        system.debug('##save## eSignature : ' + eSignature);
 
       /******************Replacement*****************/    
            
        ListContacts = [SELECT Id, FirstName, LastName, MobilePhone, Email, Account.Name 
                          FROM contact
                         WHERE recordTypeId = :recordtypeIdToQuery] ; 
        
        for( Contact con : ListContacts ) {
            MapContact.put(con.ID,con) ; 
        }
                        
        for(eSignatory__c es :eSignatoryList){
            Contact c = new Contact() ; 
            if(es.FirstName__c==null || es.Name != es.Name__c){
                //add try catch avec le message d'erreur que Fabien va créer 
                if(es.Contact__c != null) {
                    if( MapContact.get(es.Contact__c)  != null && MapContact.get(es.Contact__c) .ID!= null){ 
                        es.FirstName__c = MapContact.get(es.Contact__c).FirstName;
                        es.LastName__c = MapContact.get(es.Contact__c).LastName;
                        es.Name = es.FirstName__c + ' ' +es.LastName__c ; 
                        es.MobileTxt__c = MapContact.get(es.Contact__c).MobilePhone;
                        es.EmailTxt__c = MapContact.get(es.Contact__c).Email;
                        if(es.Code__c == 'sms' && (es.MobileTxt__c == null || es.MobileTxt__c == ''))  {                    
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,System.label.MessageMobileBlock);
                            ApexPages.addMessage(myMsg);
                            return null;
                        }
                    }
                }                    
            }
        }
 
        /**** Modification pour l'ordre des cachets sur une signature ****/
        for(Integer i=0; i<eSignatoryList.size(); i++){  
            PositionX++ ;           
            eSignatoryList.get(i).OrderCachet__c  = PositionX ; 
            if(eSignatoryList.get(i).OrderCachet__c == 1 ) {
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c =55 ; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 2){ 
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c =55 ; 
            }/*else if (eSignatoryList.get(i).OrderCachet__c == 3){ 
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 110; 
            }else if(eSignatoryList.get(i).OrderCachet__c ==  4){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 110; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 5 ) {
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 165; 
            }else if(eSignatoryList.get(i).OrderCachet__c ==  6){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 165; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 7){ 
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 220; 
            } else if(eSignatoryList.get(i).OrderCachet__c ==  8){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 220; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 9 ){ 
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 275; 
            }else if (eSignatoryList.get(i).OrderCachet__c ==  10){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 275;
            }else if(eSignatoryList.get(i).OrderCachet__c == 11){
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 330; 
            }else if(eSignatoryList.get(i).OrderCachet__c ==  12){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 330; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 13 ){ 
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 385; 
            }else if(eSignatoryList.get(i).OrderCachet__c ==  14){
                eSignatoryList.get(i).x__c= 400;
                eSignatoryList.get(i).y__c = 385; 
            }else if(eSignatoryList.get(i).OrderCachet__c == 15){
                eSignatoryList.get(i).x__c= 50;
                eSignatoryList.get(i).y__c = 440 ; 
            }*/
        }    

        if(eSignatoryList.size()>0 || MapSignatoWchids.size()>0){
            integer NumberInList = 0 ; 
            for(Integer i=0 ; i< eSignatoryList.size() ; i++){       
                // Fils ou Pas
                if(MapSignatoWchids.get(eSignatoryList.get(i).ID) !=null){                   
                    /*for(eSignatory__c observerSign : MapSignatoWchids.get(eSignatoryList.get(i).ID) ){
                        observerSign.OrderToSend__c = NumberInList++   ; 
                        ListSigToUpdate.add(observerSign) ;              
                    } */                   
                }
                if(NumberInList != null /*&& eSignatoryList.get(i).parenteSignatory__c == null*/) {
                    eSignatoryList.get(i).OrderToSend__c  =NumberInList ++ ;   
                    ListSigToUpdate.add(eSignatoryList.get(i)) ;                   
                }
                if(NumberInList == 0 /*&& eSignatoryList.get(i).parenteSignatory__c == null */){
                    /*eSignatoryList.get(i).OrderToSend__c  = i ;
                    ListSigToUpdate.add(eSignatoryList.get(i)) ;   */                  
                }                                        
            }    
        } 

        system.debug('##save## ListSigToUpdate : ' + ListSigToUpdate);
     
        if(ListSigToUpdate.size()>0){
            try{
                update ListSigToUpdate ;
            }  
            Catch(Exception e){
                /*system.debug('##save## e.getMessage()1 : ' + e.getMessage());
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; */
            }        
        }

        return new PageReference('/'+eSignature.Id); 
    }

    //Méthode pour rafraichir le phone aprs changement de la valeur du code
    /*public PageReference ref(){
   
       List<eSignatory__c> ListToRefresh = new List<eSignatory__c>() ; 
      
        if(eSignatoryList.size() >0){   
            for(eSignatory__c signat : eSignatoryList ){
                if(signat.code__c != 'sms' ||  (signat.code__c =='sms' && (signat.MobileTxt__c!='' || signat.MobileTxt__c!= null )) ){
                    if(signat.contact__c!=null ){
                        ListToRefresh.add(signat) ;
                    }       
                }
            }
        }
        if(ListToRefresh.size()>0){
            try{
                upsert eSignatoryList ;
            }Catch(Exception e){}     
        }    
        return null;
    }*/
    //End Mouad

    /********************* Refresh the page from Mobile field **********************************/   
  
    /*public PageReference refreshPhone(){
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        add = false;
        List<eSignatory__c> listofSignToRefresh = new  List<eSignatory__c>() ; 
        List<eSignatory__c> eSignatoryListSql = new  List<eSignatory__c>() ; 
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        list<Contact>contactLst=new list<Contact>();

        contact_Id = ApexPages.currentPage().getParameters().get('contact_Id');

        if(contact_Id !=null){
            try{
       
                list<esignatory__c>esignatory=[SELECT contact__c FROM esignatory__c WHERE contact__c=:contact_Id];

                mySelectedcon = [SELECT Id, RecordTypeId, FirstName, LastName, MobilePhone, Email, Account.Name, AccountID 
                                  FROM  Contact 
                                 WHERE  Id=: contact_Id] ; 
            }catch(Exception e){ } 
        }
        //End
        for(eSignatory__c es : eSignatoryList){
            if(mySelectedcon != null) { 
                if(es.contact__c != null && mySelectedcon.ID != null){
                    if (mySelectedcon.ID == es.contact__c){                        
                        if(es.MobileTxt__c !=null){
                            Contact c = new Contact(); 
                            c = [SELECT Id, FirstName, LastName,AccountId, MobilePhone, Email, Account.Name, Name 
                                   FROM contact 
                                  WHERE Id=:es.Contact__c];
                            if(c.FirstName != null) es.FirstName__c = c.FirstName;
                            if(c.LastName != null)es.LastName__c = c.LastName;
                            if(c.FirstName==null && c.LastName !=null){
                                es.Name =c.LastName ; 
                            }else if(c.LastName==null && c.FirstName!=null){
                                es.Name = c.FirstName; 
                            }else if (c.FirstName!=null & c.LastName !=null){
                                es.Name = c.FirstName + ' ' + c.LastName ; 
                            }
                            es.MobileTxt__c = es.MobileTxt__c ; 
                            es.EmailTxt__c = c.Email;
                            c.MobilePhone=es.MobileTxt__c;
                            contactLst.add(c);                              
                            listofSignToRefresh.add(es) ; 
                        }
                        else{                      
                            es.MobileTxt__c = es.MobileTxt__c ; 
                            system.debug(MY_ERR_MSG );
                            listofSignToRefresh.add(es) ;
                            return null; 
                        }
                    } 
                } 
            } 
        }   
       
        if(listofSignToRefresh.size()>0){         
            upsert listofSignToRefresh ; 
        }  
        if(contactLst.size()>0){
            upsert contactLst ;
        }
    
        if(!empty(eSignatoryList)){
            for(eSignatory__c eAll : eSignatoryList){         
                listWithoutObserver.add(eAll);         
            }
            numeroOrdreDebut    = Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin      = Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
 
        }  
        try{eSignatoryList=  [SELECT Id, Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c,
                                     SuccessURL__c, FailURL__c, CancelURL__c,Name__c,EntityName__c, Tech_OriginalSignatory__c
                                FROM eSignatory__c               
                               WHERE eSignature__c=:eSignature.Id 
                                 AND Order__c != null
                            ORDER BY Order__c asc]; } catch(Exception e){}   
        return null ;
    }
 
 
    public pageReference reset(){
        string ssesignId = ApexPages.currentPage().getParameters().get('eSignatureId');
        contractId       = ApexPages.currentPage().getParameters().get('contractId');
       
        if(contractId != null) return new pageReference('/'+ contractId ) ; 
        if(ssesignId != null) return new pageReference('/'+ ssesignId ) ; 
        return null ; 
    }*/
 
    /*public PageReference submit(){
        string errorMsg=null;
        List<eSignatory__c> listSignataire = new List<eSignatory__c>() ; 
     
        eSignatoryList = [  Select Id, Contact__r.Name,Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, 
                                   EmailTxt__c, Code__c, Order__c,EntityName__c, Name__c, 
                                   SuccessURL__c, FailURL__c, CancelURL__c, OrderToSend__c, x__c, y__c,esignature__r.cTin_TECH_IsContractIn__c, Tech_OriginalSignatory__c
                              FROM eSignatory__c
                             WHERE eSignature__c=:eSignatureId and  Order__c != null
                          ORDER BY OrderToSend__c asc]; 

        //get public URL of documents
        List<ContentDistribution> cdistList = [SELECT Name, RelatedRecordId, ContentDocumentId, 
                                                      DistributionPublicUrl, ContentVersionId 
                                                 FROM ContentDistribution 
                                                WHERE RelatedRecordId=:eSignatureId order by createdDate ASC];

        eSignature__c eSignatureForCollecte = [SELECT Id, Language__c ,Error_Message__c, Name, Status__c,contract__c,
                                                      CreatedDate, Contract__r.Name, CreatedById, contract__r.status__c,
                                                      FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c
                                                 FROM eSignature__c 
                                                WHERE id=:eSignatureId];

        try{
            AP22_XmlRpcWrapper.CreateXmlRpc(eSignatureForCollecte, eSignatoryList, cdistList);
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
        }   

        Map<ID,List<eSignatory__c>> MapSignatoWchids = new Map<ID,List<eSignatory__c>>() ; 
        List<eSignatory__c> ListSigner = new List<eSignatory__c>() ;
        Integer combiendeSigner = 0 ;
        List<eSignatory__c> ListObserverToUpdate = new List<eSignatory__c>() ; 
         
        if(eSignatureForCollecte.Error_Message__c =='' && eSignatureForCollecte.id !=null || test.isRunningTest()){
            for(eSignatory__c esign: eSignatoryList){               
                if(esign.order__c==1){
                    esign.status__c=AP_Constant.esignatoryStatusReady;
                }
                else if(esign.order__c==2){
                  esign.status__c=AP_Constant.esignatoryStatusAwaiting;
                }
                ListObserverToUpdate.add(esign) ; 
            }  
        
            list<Contract__c> contractToUpdt=[SELECT status__c,AXA_GO_Legal_Entity__c,id,recordtype.developername
                                                FROM contract__c 
                                               WHERE id=:eSignatureForCollecte.contract__c];

            contractToUpdt[0].status__c=AP_Constant.contractSentStatus;
        
            try{
                update contractToUpdt;
            }
            catch(Exception e){
                errorMsg=e.getMessage();
            }

            if(contractToUpdt[0].recordtype.developername !=AP_Constant.RT_AXAATS && contractToUpdt[0].recordtype.developername !=AP_Constant.RT_AXAATSReadOnly){
                //MRA 14/05/2017 - Updated to generate invoicing lines when contract status changes to Sent for esignature
                List<Planned_Invoicing_Line__c> ilines = new List<Planned_Invoicing_Line__c>();
        
                Id pilID = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Planned Invoicing Line').getRecordTypeId();
                List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id 
                                                                       FROM Planned_Invoicing_Line__c 
                                                                      WHERE Contract2__c =: contractToUpdt[0].Id 
                                                                        AND Type__c = 'Invoicing Line'];
                if (invoicingLineList.IsEmpty() && errorMsg == null) {           
                    ilines = new List<Planned_Invoicing_Line__c>();
            
                    for(Planned_Invoicing_Line__c piline :[SELECT AXA_GS_Legal_Entity__c, Description__c, Id, Amount__c, 
                                                                  Percent__c, Master_WBS_Structure__c, Invoicing_Date__c, 
                                                                  CurrencyIsoCode, WBS__c, Contract2__r.Owner.FirstName, 
                                                                  Contract2__r.Owner.LastName  
                                                             FROM Planned_Invoicing_Line__c 
                                                            WHERE Contract2__c =: contractToUpdt[0].Id 
                                                              AND RecordTypeId =: pilID]){
                        Planned_Invoicing_Line__c iline   = new Planned_Invoicing_Line__c();
                        iline.Contract2__c                = contractToUpdt[0].Id;
                        iline.Type__c                     = 'Invoicing Line';
                        iline.Percent__c                  = piline.Percent__c; 
                        iline.Rate__c                     = piline.Amount__c; 
                        iline.Invoicing_Date__c           = piline.Invoicing_Date__c;
                        iline.Man_days__c                 = 1;
                        iline.TECH_GIE_SAS__c             = contractToUpdt[0].AXA_GO_Legal_Entity__c;
                        if (String.isNotBlank(piline.Master_WBS_Structure__c)) {
                            iline.Master_WBS_Structure__c = piline.Master_WBS_Structure__c;                 
                        }
                        iline.Planned_Invoicing_Line__c   = piline.Id;
                        iline.CurrencyIsoCode             = piline.CurrencyIsoCode;
                        iline.Status__c                   = System.Label.InvLineStatus_Draft;
                        iline.AGS_Project_Manager__c      = piline.Contract2__r.Owner.FirstName + ' ' + piline.Contract2__r.Owner.LastName;
                        iline.RecordTypeId                = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
                        iline.Activity_Type__c            = piline.Description__c;
                        ilines.add(iline);
                    }           
                    if(ilines.size()>0)
                        insert ilines;
                }
            }
        }
        update ListObserverToUpdate ;   
            
        eSignatureForCollecte.Status__c       = AP_Constant.eSignatureSentStatus;
        eSignatureForCollecte.collecteDone__c = true;      
        RecordType inSignatureRT              = esignRtNameMap.get(AP_Constant.recordTypeInSignature);
        eSignatureForCollecte.RecordTypeId    = inSignatureRT.Id;
        update eSignatureForCollecte;
        return new PageReference('/'+eSignatureForCollecte.contract__c); 
    }*/
     
    /*public pagereference relaunch(){
        system.debug('## Starting method relauch');

        list<eSignatory__c> esignatoryList = [SELECT Id, Contact__r.Name, contract__r.Id, 
                                                     FirstName__c, LastName__c, Contract__c, MobileTxt__c, EmailTxt__c, Code__c, 
                                                     Order__c,OrderToSend__c,Contact__c, SuccessURL__c,x__c,y__c,
                                                     FailURL__c, CancelURL__c, RelaunchCount__c, RelaunchErrorMessage__c,
                                                     LastRelaunchDate__c,esignature__r.transactionId__c,esignature__r.Contract__c,esignature__r.Language__c, esignature__c,esignature__r.CreatedById,
                                                     esignature__r.HandWrittenSignatureMode__c ,EntityName__c                                         
                                                FROM eSignatory__c 
                                               WHERE id=:eSignatoryId];
          
        if(esignatoryList.size()>0){
            string transactionId=esignatoryList[0].esignature__r.transactionId__c;           
            integer relaunchCount;
            
            if(integer.valueOf(esignatoryList[0].RelaunchCount__c)==null)
                relaunchCount=0;
            else
                relaunchCount=integer.valueOf(esignatoryList[0].RelaunchCount__c);
           
            eSignature__c eSignatureForCollecte=new eSignature__c();
            eSignatureForCollecte.id=esignatoryList[0].esignature__c;

            if(transactionId!=null || transactionId!='' ) {        
                //call webservice to relaunch transaction -> requester.relaunchTransaction(transactionId); 
                try{               
                    AP22_XmlRpcWrapper.CreateXmlRpcForRelaunch(eSignatureForCollecte,transactionId, eSignatoryList,relaunchCount);
                }
                catch(Exception e){                   
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
                }   
            }
            return new PageReference('/'+eSingId); 
        }         
        system.debug('## Ending method relauch');
        return null;
    }*/
     
    /*//MRA 24-NOV-2015
    //Case 1130 (Enhancement) -> add relauch 
    public pagereference relaunch(){
        system.debug('## Starting method relauch');

        //query the esignature to retrieve the transaction id         
        list<esignature__c> esignatureList=[select transactionId__c,Contract__c,Language__c, id,CreatedById,
                                            HandWrittenSignatureMode__c 
                                            from esignature__c
                                            where id=:eSingId];

        list<eSignatory__c> esignatoryList = [Select Id, Contact__r.Name, contract__r.Id, 
                                             FirstName__c, LastName__c, Contract__c, MobileTxt__c, EmailTxt__c, Code__c, 
                                             Order__c,OrderToSend__c,Contact__c, SuccessURL__c,x__c,y__c,
                                             FailURL__c, CancelURL__c, RelaunchCount__c, RelaunchErrorMessage__c, 
                                             LastRelaunchDate__c 
                                             FROM eSignatory__c 
                                             WHERE id=:eSignatoryId];
          
        if(esignatureList.size()>0){
            string transactionId=esignatureList[0].transactionId__c;           
            integer relaunchCount;
            
            if(integer.valueOf(esignatoryList[0].RelaunchCount__c)==null)
                relaunchCount=0;
            else
                relaunchCount=integer.valueOf(esignatoryList[0].RelaunchCount__c);
           
            eSignature__c eSignatureForCollecte=esignatureList[0];

            if(transactionId!=null || transactionId!='' ) {        
             //call webservice to relaunch transaction -> requester.relaunchTransaction(transactionId); 
              try{               
                    AP22_XmlRpcWrapper.CreateXmlRpcForRelaunch(eSignatureForCollecte,transactionId, eSignatoryList,relaunchCount);
              }
              catch(Exception e){                   
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
              }   
 
            }
            
            return new PageReference('/'+eSingId); 
        }
         
        system.debug('## Ending method relauch');
        return null;
    }*/

    /*public pagereference cancel(){
        system.debug('## Starting method eSignature cancel');
 
        list<eSignatory__c> eSignLst = [SELECT Id, status__c,esignature__r.status__c, esignature__r.transactionId__c,
                                               esignature__r.Contract__c,esignature__r.Language__c, esignature__c,
                                               esignature__r.CreatedById,esignature__r.HandWrittenSignatureMode__c 
                                          FROM eSignatory__c 
                                         WHERE eSignature__c =: eSingId];
      

        if(eSignLst.size()>0){
            string transactionId=string.valueOf(eSignLst[0].esignature__r.transactionId__c);          
            eSignature__c eSignatureForCollecte=new esignature__c();
            eSignatureForCollecte.id=eSignLst[0].esignature__c;
            
            if(transactionId!=null || transactionId!='') {        
                //call webservice to relaunch transaction -> requester.relaunchTransaction(transactionId); 
                try{
                    AP22_XmlRpcWrapper.CreateXmlRpcForCancel(eSignatureForCollecte,transactionId,eSignLst);
                }
                Catch(Exception e){               
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
                }   
            } 
            else{
                eSignatureForCollecte.status__c='Cancelled'; //AP_Constant.eSignatureCreatedStatus;
                update eSignatureForCollecte;
            } 
            return new PageReference('/'+eSignLst[0].esignature__r.contract__c); 
        }         
        system.debug('## Ending method eSignature cancel');
        return null;        
    }*/

    public PageReference refresh(){
        system.debug('Starting method refresh');
        
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        add = false;
                
        try{
            MY_ERR_MSG       = null;
            MY_CON_ERR_MSG   = null;
            MY_EMAIL_ERR_MSG = null;
            mySelectedcon    = new Contact();
            // contact_Id = '';
            contact_Id       = ApexPages.currentPage().getParameters().get('contact_Id')  ;
            esignatoryBis_Id = ApexPAges.currentPage().getParameters().get('esignatoryBis_Id');
            
            System.Debug('### esignatoryBis_Id : ' + esignatoryBis_Id ); 
            System.Debug('### passedParam_Contact ' + contact_Id) ; 
            
            // query esignatory to retrieve name and recortype
            list<Esignatory__c> currentsignatory=[SELECT id,recordtype.name,contact__r.AccountId,entityName__c, name, name__c
                                                    FROM esignatory__c 
                                                   WHERE id =:esignatoryBis_Id];
            
            system.debug('## record type name of current signatory'+currentsignatory[0].recordType.name);
            
            ////query contact AXA if esignatory.rt= AXA
            //if(currentsignatory[0].recordtype.name.contains('Entity contact')){
            //    recordtypeIdToQuery=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
            //}
            
            //if(recordtypeIdToQuery==null) recordtypeIdToQuery=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
            
            
            System.Debug('### recordtypeIdToQuery ' + recordtypeIdToQuery) ;
            
            /*if(contact_Id !=null){
                try{
                    //query selected contact
                    mySelectedcon = [SELECT Id, Name, RecordTypeId, FirstName, LastName, MobilePhone, Email, Account.Name, AccountID 
                                       FROM Contact 
                                      WHERE Id=: contact_Id 
                                        AND RecordTypeId=:recordtypeIdToQuery Limit 1] ; 
                    System.debug('### mySelectedcon  989 : '+mySelectedcon);
                    hasContact = true;
                }
                catch(Exception e){ 
                    System.debug('## error: '+e.getMessage());
                }  
            }
            
            System.debug('### eSignatoryList :'+ eSignatoryList.size()) ;    
            
            if(eSignatoryList.size()>0){
                Is_ERR = false;
                for(eSignatory__c es : eSignatoryList){
                    system.debug('**mySelectedcon.Name'+mySelectedcon.Name);
                    system.debug('**esignatoryBis_Id'+esignatoryBis_Id);
                    system.debug('*es.name'+es.name);
                    system.debug('*es.id'+es.id);
                    
                    if(es.Name == mySelectedcon.Name && esignatoryBis_Id != es.Id){
                        system.debug('same contact name');
                        MY_CON_ERR_MSG   = system.label.ErrorDuplicateContactName;
                        Is_ERR           = true;
                    }
                    if(es.EmailTxt__c == mySelectedcon.Email && esignatoryBis_Id != es.Id){
                        system.debug('same email text');
                        MY_EMAIL_ERR_MSG = 'Duplicate Email';
                        Is_ERR           = true;
                    }   
                    
                    // modif 23/10/2015    Is_ERR from true to false
                    if(esignatoryBis_Id == es.Id && Is_ERR == false){
                        es.Contact__c              = mySelectedcon.Id;
                        es.MobileTxt__c            = mySelectedcon.MobilePhone;
                        es.EmailTxt__c             = mySelectedcon.Email;
                        //es.cTin_SupplierAccount__c = mySelectedcon.AccountId;
                        es.EntityName__c           = mySelectedcon.AccountId;
                    }   
                    
                }
                if(Is_ERR == true) 
                    return null;
                
            }
            list<esignatory__c> esignToUpsertList=new list<esignatory__c>();   
            if( mySelectedcon.MobilePhone == '' ||  mySelectedcon.MobilePhone == Null ){
                System.debug('### mySelectedcon : '+mySelectedcon);
                MY_ERR_MSG = System.label.MessageMobileBlock;
                
                for(eSignatory__c es : eSignatoryList){
                    if(esignatoryBis_Id == es.Id ){
                        es.Contact__c = mySelectedcon.Id;                        
                        if(es.contact__c !=null ){
                            es.EmailTxt__c             = mySelectedcon.Email;
                            es.MobileTxt__c            = '';
                            //es.cTin_SupplierAccount__c = mySelectedcon.AccountId;
                            es.EntityName__c           = mySelectedcon.AccountId;  
                            esignToUpsertList.add(es);
                        }
                        System.debug('### added signatory :' + es) ;*/
                       /* try{
                            upsert es ; 
                          }Catch(Exception e){}  */
                    /*}
                }                
                if(esignToUpsertList.size()>0)
                    upsert esignToUpsertList;  
            }
            else{
                //List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();                
                List<eSignatory__c> listofSignToRefresh = new  List<eSignatory__c>();                 
                // On the refresh of the lookup upsert the Signatories                
                System.debug('### esignatoryBis_Id : '+esignatoryBis_Id);
                for(eSignatory__c es : eSignatoryList){
                    
                    if(esignatoryBis_Id == es.Id ){
                        es.Contact__c = mySelectedcon.Id;
                        System.Debug('### es.Contact__c 1035 : ' + es.Contact__c) ; 
                    }
                    System.Debug('### es 1037 : ' + es) ; 
                    
                    if(es.contact__c !=null && esignatoryBis_Id == es.Id){
                        if(mySelectedcon.FirstName != null) es.FirstName__c = mySelectedcon.FirstName;
                        if(mySelectedcon.LastName != null)es.LastName__c = mySelectedcon.LastName;                        
                        if(mySelectedcon.FirstName==null && mySelectedcon.LastName !=null){
                            es.Name =mySelectedcon.LastName ; 
                        }
                        else if(mySelectedcon.LastName==null && mySelectedcon.FirstName!=null){
                            es.Name = mySelectedcon.FirstName; 
                        }
                        else if (mySelectedcon.FirstName!=null & mySelectedcon.LastName !=null){
                            es.Name = mySelectedcon.FirstName + ' ' + mySelectedcon.LastName ; 
                        }
                        System.Debug('### mySelectedcon.MobilePhone : ' + mySelectedcon.MobilePhone) ; 
                        es.MobileTxt__c = mySelectedcon.MobilePhone;
                        es.EmailTxt__c = mySelectedcon.Email;
                        //es.AccountName__c = mySelectedcon.Account.Name;
                        //es.cTin_SupplierAccount__c = mySelectedcon.AccountID;
                        es.EntityName__c=mySelectedcon.AccountId;
                        listofSignToRefresh.add(es);
                        
                        System.Debug('### le signataire : ' + es) ;    
                    }
                    if(listofSignToRefresh.size()>0)
                        upsert listofSignToRefresh;
                } 
                
                //eSignatoryList = [Select Id, RecordTypeId, cTin_OriginalRepresentative__c ,
                //                  contract__r.Id, contract__r.cTin_SupplierAccount__c, Contact__r.cTin_RelatedUser__c, 
                //                  Contact__c, Contact__r.Name, FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, 
                //                  MobileTxt__c, EmailTxt__c, Code__c, Order__c ,cTin_ParenteSignatory__c, SuccessURL__c, 
                //                  FailURL__c, CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,entityName__c
                //                  FROM eSignatory__c 
                //                  WHERE eSignature__c=:eSignature.Id and  Order__c != null
                //                  order by Order__c asc];
                
                //System.Debug('#### eSignatoryList from sql:' + eSignatoryList.size()) ; 
                
                
                //if(!empty(eSignatoryList)){
                //    //create list without observers        
                //    for(eSignatory__c eAll : eSignatoryList){
                //       /* if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                //            listWithoutObserver.add(eAll);
                //        }*/

                //        //if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                //        //   listWithoutObserver.add(eAll);
                //        //}
                //    }        
                //    //if(listWithoutObserver.size()>0){
                //    //    numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
                //    //    Integer  tailleList = listWithoutObserver.size()-1;                 
                //    //    numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
                //    //}              
                //}  
                /*return null;  
            }
            return null;*/
        }
        catch(Exception e){
            //return null;
        }
        return null;          
    } 

    //public PageReference deleteEsignatory(){
        
    //    String passedParam = ApexPages.currentPage().getParameters().get('delete_id')  ;  
    //    if(passedParam !=''){ 
    //        delete_id=Integer.valueOf(passedParam );
    //    }    
    //    System.debug('##### param delete_id '+delete_id);
        
    //    List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        
    //    List<eSignatory__c> listWithoutOrder    = new List<eSignatory__c>() ; 
    //    Map <Decimal, eSignatory__c> eSignMap   = new Map <Decimal, eSignatory__c>();
    //   // System.debug('##### eSignatoif(eSignatoryList.size()>0){
    //    for(eSignatory__c eMap : eSignatoryList){
    //        if(eMap.Order__c == null ){
    //            listWithoutOrder.add(eMap) ; 
    //        }else if(delete_id !=null) {
    //            System.debug('##### emap.Order__c l 775 '+emap.Order__c);
    //            eSignMap.put(emap.Order__c, emap);
    //        }
    //    }
        
        
    //    if(listWithoutOrder.size()>0){listWithoutOrder.clear(); }
        
    //    eSignatory__c eSignToDelete = new eSignatory__c();    
        
    //    if(delete_id !=null){
    //        eSignToDelete = eSignMap.get(delete_id);
    //    }
        
    //    System.Debug('### eSignToDelete :' + eSignToDelete ) ; 
        
    //    list<Esignatory__c> esignatoryToUpdate=new list<Esignatory__c>();
    //    for(eSignatory__c esignToUpdate :eSignatoryList){
    //        if(esignToUpdate.Order__c>eSignToDelete.Order__c){
    //            esignToUpdate.Order__c=esignToUpdate.Order__c-1;
    //            //System.debug('##### esignToUpdate.Order__c '+esignToUpdate.Order__c);
                                
    //            //if(esignToUpdate.Contact__c != null) {
    //            esignatoryToUpdate.add(esignToUpdate);
    //            //}
    //              /* try{
    //                    update esignToUpdate;
    //                } */ 
    //                //Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
    //        }
            
    //        if(esignatoryToUpdate.size()>0){
    //            try{
    //                update esignatoryToUpdate;
    //            }  
    //            Catch(Exception e){
    //                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; 
    //            } 
    //        }
    //    }
        
    //    eSignatory__c esigntoDeleteV2 = new eSignatory__c();
    //    try{
    //        esigntoDeleteV2 = [SELECT Id , Contact__r.cTin_RelatedUser__c ,contract__c,RecordTypeID,
    //                                  cTin_SupplierAccount__c,contact__r.AccountId,entityName__c, Tech_OriginalSignatory__c 
    //                             FROM eSignatory__c 
    //                            WHERE id =: eSignToDelete.ID] ; 
    //    } Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
          
    //    if(esigntoDeleteV2 != null && esigntoDeleteV2.Id != null ){
    //        try{
    //            delete eSignToDelete;
    //        }Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'The Signatory is deleted.')) ; } 
    //    }

    //    //upsert eSignatoryList;
    //    Id eSigId = eSignatureId == null? eSignature.Id : eSignatureId;

    //    eSignatoryList = [SELECT Id, RecordTypeId, cTin_OriginalRepresentative__c ,contract__r.Id,eSignature__c, 
    //                             contract__r.cTin_SupplierAccount__c, Contact__c,Contact__r.cTin_RelatedUser__c, 
    //                             FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
    //                             Code__c, Order__c,cTin_ParenteSignatory__c, SuccessURL__c, FailURL__c, 
    //                             CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,entityName__c , Tech_OriginalSignatory__c 
    //                        FROM eSignatory__c 
    //                       WHERE eSignature__c=:eSigId 
    //                        AND Order__c != null
    //                    ORDER BY Order__c asc];

    //    //for (eSignatory__c eSig : eSignatoryList){
    //    //    if (eSig.contact__c == null){
    //    //        hasContact = false;
    //    //        break;
    //    //    }
    //    //    else{
    //    //        hasContact = true;
    //    //    }
    //    //}

    //    return null;        
    //}

    public PageReference add() {
        //get parameter
        if (hasContact){
            add_order = Integer.valueOf(ApexPages.currentPage().getParameters().get('add_order'));
            List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();

            System.debug('##add## add_order '+ add_order);

            Id parentId   = null;
            Integer index = null;

            for(Integer i=0; i<eSignatoryList.size(); i++){
                //find index of selected Reciepient =>get index
                if(eSignatoryList.get(i).Order__c==add_order){
                    //increment all following indexs +1
                    index= i+1;
                    ParentId = eSignatoryList.get(i).Id;    
                }           
            }

            eSignatory__c cs    =  new eSignatory__c();
            cs                  = (eSignatory__c)eSignatory__c.sObjectType.newSObject(System.Label.cTin_RTNegotiatorSignatory, true) ; 
            cs.eSignature__c    = eSignatureId == null? eSignature.Id : eSignatureId;


            if (cs.contact__c == null)
                cs.name = 'Please select a Contact';
            
            System.debug('##add## cs '+ cs);

            if(eSignatoryList.size() > 0){
                cs.Contract__c      = eSignatoryList.get(0).contract__c;
            }

            System.debug('##add## cs.contract '+ cs.Contract__c);

            cs.OrderCreation__c =  add_order+1;
            cs.Order__c         =  add_order+1;
            //cs.Tech_OriginalSignatory__c = false;
            //cs.recordTypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('cTin_AXA_Representative').getRecordTypeId();     

            System.debug('##add## before insert cs '+ cs);
            
            insert cs;

            if (cs.Contact__c == null){
                hasContact = false;
            }
            else{
                hasContact = true;
            }

            list<eSignatory__c> eSignatoryToUpsert = new list<eSignatory__c>();
            list<eSignatory__c> eSignatoryToDelete = new list<eSignatory__c>();
            
            /*for(Integer j=0; j<eSignatoryList.size();j++){
                if(j>=index){ 
                    //get element of the list 
                    eSignatory__c e = eSignatoryList.get(j);
                    // increment the order of all the following elements
                    e.Order__c = e.Order__c+1;
                    if (e.contact__c != null){
                        eSignatoryToUpsert.add(e);
                    }
                    else{
                        eSignatoryToDelete.add(e);
                    }
                } 
            }*/

            System.debug('##add## eSignatoryToUpsert '+ eSignatoryToUpsert);
            System.debug('##add## eSignatoryToDelete '+ eSignatoryToDelete);

            /*if(eSignatoryToUpsert.size() >0 ){
                upsert eSignatoryToUpsert;
            }
            if(eSignatoryToDelete.size() >0 ){
                delete eSignatoryToDelete;
            }

            if(index<eSignatoryList.size()){
                // add the element using the designated index of the list
                eSignatoryList.add(index, cs);  
            }
            else{ eSignatoryList.add(cs);}

            if(eSignatoryList.size() > 0){
                //create list without observers            
                //for(eSignatory__c eAll : eSignatoryList){
                //    if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('cTin_AXA_Representative').getRecordTypeId()){
                //        listWithoutObserver.add(eAll);
                //    }
                //}
                numeroOrdreDebut=Integer.valueOf(eSignatoryList.get(0).Order__c);
                Integer tailleList = eSignatoryList.size()-1;            
                numeroOrdreFin     = Integer.valueOf(eSignatoryList.get(tailleList).Order__c); 
            }      */
        }
        return null;
    }

    /*public PageReference deleteEsignatory(){
        
        String passedParam = ApexPages.currentPage().getParameters().get('delete_id')  ;  
        if(passedParam !=''){ 
            delete_id=Integer.valueOf(passedParam );
        }    
        System.debug('##### param delete_id '+delete_id);
                
        List<eSignatory__c> listToDelete    = new List<eSignatory__c>() ; 
        eSignatoryList                      = new List<eSignatory__c>() ; 

        Id eSigId = eSignatureId == null? eSignature.Id : eSignatureId;
        Integer orderUpdate = 1;
        for(eSignatory__c eSigExist : [SELECT Id, RecordTypeId, cTin_OriginalRepresentative__c ,contract__r.Id,eSignature__c, 
                                             contract__r.cTin_SupplierAccount__c, Contact__c,Contact__r.cTin_RelatedUser__c, 
                                             FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
                                             Code__c, Order__c,cTin_ParenteSignatory__c, SuccessURL__c, FailURL__c, 
                                             CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,entityName__c , Tech_OriginalSignatory__c 
                                        FROM eSignatory__c 
                                       WHERE eSignature__c=:eSigId 
                                    ORDER BY Order__c asc]){
            if (eSigExist.Contact__c == null || eSigExist.order__c == delete_id){
                listToDelete.add(eSigExist);
            }
            else{
                eSigExist.order__c = orderUpdate;
                eSignatoryList.add(eSigExist);
                orderUpdate++;
            }
        }

        if (listToDelete.size() > 0){
            delete listToDelete;
        }

        if (eSignatoryList.size() > 0){
            update eSignatoryList;
        }
        hasContact = true;

        return null;        
    }*/
}