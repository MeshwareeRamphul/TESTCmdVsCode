public class VFC37_CreateSignature{
    /* 
--------------------------------------------------------------------------------------
-- - Name          : VFC37_CreateSignature
-- - Author        : Spoon Consulting 
-- - Description   : Class that controls eSignture page
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 11-APR-2016  NJA    1.1     Case 2865: Bug on selection of Contact for Supplier Rep
-- 01-JUL-2016  MRA    1.2     Case 1176: Enable unilateral signatures
-- 04-JUL-2016  MRA    1.3     Corrected bug: Order number should start with 1 instead of 0
-- 07-JUL-2016  MRA    1.2     Corrected bug : query contact by id instead of name when adding a Signatory 
to cater for cases where contacts have same name
-- 27-FEB-2017  MRA    1.3     Corrected bug - Unable to add AXA Signatory (TMA 3551)
-- 30-OCT-2017  MRA    1.4     Evol Universign - Reworked and optimised class (taken from Contract In Prod)
-- 30-APR-2018  MRA    1.5     Evol (Case 00004143) - Enable multiple documents to be signed (previously available for ach only, now applicable for all entities)
-- 13-AUG-2018  MRA    1.6     Evol (Case 00004282) - Apply restriction of 89 characters to ensure that 
                               salesforce limit of 100 characters for content name is not exceeded
-- 05-JUN-2020  ARA    1.7     Case 0279: Default language on the signature
*************************************************************************************/
    public static boolean allowCreate=false;
    public List<eSignatory__c>eSignatoryList{get;set;}
    public eSignature__c eSignature{get;set;}
    public Contract__c contract{get;set;}
    public Account supplierAccount{get;set;}
    public cTin_ContractForm__c contractForm{get;set;}
    public Id contractId {get;set;}
    public Id eSignatureId {get;set;}
    public Integer ordredescente{get;set;}
    public Integer add_order{get;set;}
    public Integer delete_id{get;set;}
    public Integer numeroOrdreDebut{get;set;}
    public Integer numeroOrdreFin{get;set;}
   // public String UniversignResponse { get; set; }
   // public String UniversignResponseTransId { get; set; }
    // public User owner{get; set;}
    public String contractName {get; set;}
    public Integer nbDeleveryContent{get;set;}
    public boolean showpageblock{get ; set; }
    public static Id eSingId {get;set;}
   // public boolean onOff{get ; set; }
    public boolean Inserted = false;
    
    public String contact_Id {get;set;}
    public String esignatoryBis_Id {get;set;}
    public String MY_ERR_MSG {get;set;}
    public String MY_CON_ERR_MSG {get;set;}
    public String MY_EMAIL_ERR_MSG {get;set;}
    public Boolean Is_ERR {get;set;}
    
    public   Contact mySelectedcon{get;set;}
    public Boolean DoNotContinue  ; 
    public User currentUser{get ; set; }
    //06/03/2015
    public String MY_ERRROR_ALL{get ; set; }
    public boolean add{get ; set; }
    //public id entitySignatory{get;set;}
    //MRA 30 NOV 2015
    public Id eSignatoryId {get;set;}
    
    //NJA Case 1176 21/01/2016
    public integer order_number;
    public integer countClicks;
    /*Parametre  : object
     Valeur de retour :  boolean
     Objectif : Cette methode a pour objectif de controler si une variable est rempli ou pas
    */
    
    public static Boolean empty(Object o){
        return o==null || String.valueOf(o)=='';
    }
    
    public VFC37_CreateSignature(){
        allowCreate=true;
        contractId = ApexPages.currentPage().getParameters().get('contractId');
        eSignatureId = ApexPages.currentPage().getParameters().get('eSignatureId');
        eSingId = ApexPages.currentPage().getParameters().get('id');
        
        //MRA 30 NOV 2015 (Case 1130)
        try{
            eSignatoryId=ApexPages.currentPage().getParameters().get('signatoryId');
        }
        catch(Exception e){// do nothing
        }
        System.Debug('### le parametre' + eSingId ) ; 
        currentUser = [Select ID, cTin_UniversignProfile__c, cTin_Universign__c,cTin_EntityLocalCode__c 
                       from User 
                       where id =:UserInfo.getUserID() ] ; 
        //06/03/2015
        MY_ERRROR_ALL= System.label.MessageMobileBlock; 
        add = false;
        
        //NJA Case 1176 
        order_number = 1;
        countClicks=0; 
        
    }
    
    public PageReference back(){
       list<esignature__c> esignatureLst=[select id,status__c,contract__c,cTin_TECH_IsContractIn__c,contract__r.cTin_OwnerEntity__c
                                           from esignature__c 
                                           where status__c=:AP_Constant.eSignatureCreatedStatus
                                           and contract__c =: contractId
                                           order by createdDate desc limit 1] ;

        if(esignatureLst.size()>0) delete esignatureLst;

       return new PageReference('/'+contractId) ;
    }
    //method for button 'back to contract'
    public PageReference redirect(){
        string contract_id;
        list<esignature__c> esignatureLst=[select id,status__c,contract__c,cTin_TECH_IsContractIn__c,contract__r.cTin_OwnerEntity__c
                                           from esignature__c 
                                           where (status__c=:AP_Constant.eSignatureCreatedStatus
                                           and contract__c =: contractId)
                                           or id=: eSignatureId
                                           order by createdDate desc limit 1] ;
        if (esignatureLst.size()>0)
           contract_id=esignatureLst[0].contract__c;
        else
            contract_id=contractId;
        //if (esignatureLst.size()>0) 
          //  delete  esignatureLst;  

        return new PageReference('/'+contract_id) ; 
    }
    
    //method creates esignature  
    public PageReference createSignature(){
        DoNotContinue = false;
        Savepoint sp;
        pageReference pgRef;
        string language = 'English';
        //boolean to display error message
        showpageblock=true; 
        
        // create
        if(contractId!=null){
            
        /*MRA 29/06/2016: Case 1176:
            Updated functionality unilateral to consider 2 checkboxes:
            checkbox 1: unilateral supplier signatory - if checked, create only supplier signatory 
            checkbox 2: unilateral AXA Representative - if checked, create only AXA representative signatory 
        */
            contract = [Select Id, ownerID, Name,FinalDocumentURL__c, cTin_SupplierAccount__c,cTin_OwnerEntity__c,
                        cTin_OwnerEntityLocalCode__c,cTin_AXASignatoryRepresentative__c, 
                        cTin_SupplierSignatoryRepresentative__c,Status__c,cTin_UnilateralSupplier__c,
                        cTin_UnilateralAXARepresentative__c
                        FROM Contract__c 
                        WHERE Id=:contractId];
            
            if(contract.cTin_UnilateralSupplier__c && contract.cTin_SupplierAccount__c <> null && !contract.cTin_UnilateralAXARepresentative__c){  supplierAccount = [Select Id, Name from Account WHERE id=:contract.cTin_SupplierAccount__c]  ;}           
            
            if(contract.Status__c==AP_Constant.contractInSignatureStatus /*&& contract.FinalDocumentURL__c  != null*/) {
                
                User OwnerContract = [select cTin_UniversignProfile__c,cTin_EntityLocalCode__c 
                                      from User 
                                      where Id=: contract.ownerId ] ;                
                
                if(OwnerContract.cTin_EntityLocalCode__c  ==currentUser.cTin_EntityLocalCode__c 
                   && currentUser.cTin_Universign__c == true ) { 

                       //TODO add conditions to contractForm : latestContractForm et Created ContractForm__c.FinalApprovalStatus__c = "Approved"  / a rajouter en dessous FinalApprovalStatus__c='Approved'
                       // try catch exception in case the contract form related to contract is not in Approved Status
                       try{
                           //MRA 24/11/15: Case 00002427 : contract form should always be filled on esignature even if final approval status <> approved
                           contractForm = [Select Id, cTin_Contract__c 
                                           from cTin_ContractForm__c 
                                           WHERE cTin_Contract__c=:contractId 
                                           order by createdDate asc limit 1];
                       }
                       Catch(Exception e){} 
                       
                      /* RecordType draftRT = [SELECT Id, DeveloperName FROM RecordType Where DeveloperName='cTin_Draft' 
                                             AND SobjectType='eSignature__c'];*/

                       string draftRtId=Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
                       //owner = [Select Id, Name,LanguageLocaleKey FROM USER Where id=:UserInfo.getUserId()];
                       
                        /* ARA 05/06/20 : SP-00279 : Default language on the signature */
                       if(contract.cTin_OwnerEntity__c != null){
                           if(contract.cTin_OwnerEntity__c == '700 - AXA France' || contract.cTin_OwnerEntity__c == '710 - AXA France Assurances'){
                               language = 'French';
                           }else if(contract.cTin_OwnerEntity__c == '1230 - AXA Spain'){
                               language = 'Spanish';
                           }else if(contract.cTin_OwnerEntity__c == '1320 - AXA Switzerland'){
                               language = 'English';
                           }
                       }
                       
                       eSignature = new eSignature__c(Name = Contract.Name,
                                                      Contract__c = contract.Id,
                                                      Status__c = AP_Constant.eSignatureCreatedStatus,
                                                      language__c=language,
                                                     /*RecordTypeId= draftRT.Id*/
                                                     RecordTypeId=draftRtId);
                       
                       if(contractForm != null) eSignature.cTin_ContractForm__c=contractForm.Id;
                       try{ 
                           sp = Database.setSavepoint();
                           if(Inserted  == false){
                               insert eSignature;                
                               Inserted = true;
                           }
                       }catch(Exception e){ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,label.ErrorMessageOneESign) ) ;  showpageblock=false ; }
                       
                       contractName = contract.Name;
                       
                       if(eSignature.Id != null){
                           
                           eSignature = [Select Id,cTin_TECH_ContentIdToSign__c, Name, Status__c,cTin_ContractForm__c, CreatedDate, Contract__r.Name, CreatedById, 
                                         cTin_ShortDescription__c, FinalDocumentURL__c, cTin_KeyPoints__c, LastModifiedById,
                                         cTin_TotalSpendExcVAT2__c, cTin_StartDate__c, 
                                         cTin_AXAMainLegalSignatoryEntity__c, cTin_SupplierLegalSignatoryEntity__c, 
                                         cTin_AXAMainSignatoryRepresentative__c,cTin_TECH_IsContractIn__c, 
                                         cTin_SupplierSignatoryRepresentative__c,cTin_FinalApproval1__c,cTin_FinalApproval2__c,
                                         cTin_FinalApproval3__c,cTin_FinalApproval4__c,cTin_FinalApproval5__c,cTin_FinalApproval6__c, HandWrittenSignatureMode__c, 
                                         cTin_FinalApproval7__c,cTin_FinalApproval8__c,cTin_FinalApproval9__c,cTin_FinalApproval10__c,ExternalId__c,
                                         RecordTypeId,URL__c,Language__c,contract__r.cTin_OwnerEntity__c  
                                         from eSignature__c 
                                         WHERE Id=:eSignature.Id];
                           
                           Contact contactSupplier = new Contact()  ;
                           //create eSignatories
                           if (contract.cTin_SupplierSignatoryRepresentative__c !=null 
                               && !contract.cTin_UnilateralAXARepresentative__c) {
                                   contactSupplier = [Select Id,cTin_Active__c, Name, FirstName, LastName, MobilePhone, Email, 
                                                      Account.Name 
                                                      from Contact 
                                                      WHERE Id = :contract.cTin_SupplierSignatoryRepresentative__c limit 1]; 
                               }
                           // MRA: 30/06/2016: Case 1176 Added check contactSupplier!=null to prevent crash when unilateralAXARep is checked
                           if(contactSupplier!=null){          
                               if(contactSupplier.Email == null || contactSupplier.cTin_Active__c==false) {                 
                                   //29/06/2016 : MRA : (case 1176) - updated if conditions to cater for unilateral (line 189)                
                                   if (!(Contract.cTin_UnilateralSupplier__c) && !(Contract.cTin_UnilateralAXARepresentative__c)
                                       || ((Contract.cTin_UnilateralSupplier__c) && !(Contract.cTin_UnilateralAXARepresentative__c) )){
                                           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning ,contactSupplier.Name +  system.label.ErrorMessageNoActiveMail )  ) ;  showpageblock=false ;    
                                           //DoNotContinue = true ;
                                       } 
                                   /*else{
                                      if(contract.cTin_AXASignatoryRepresentative__c == null && contract.cTin_SupplierSignatoryRepresentative__c ==null){
                                      DoNotContinue = true ;
                                                      }
                                      }  */                                              
                               } 
                           } //end contactSupplier!=null  
                           
                           if(contactSupplier.Id != null && DoNotContinue==false ){
                               //MRA 01/07/2016 : case 1176
                               //eSignatory__c esignatorySupplier=new eSignatory__c();     
                               eSignatory__c esignatorySupplier = (eSignatory__c)eSignatory__c.sObjectType.newSObject(System.Label.cTin_RTSupplierSignatory, true) ; 
                               esignatorySupplier.eSignature__c = eSignature.Id; 
                               esignatorySupplier.cTin_OriginalRepresentative__c= true ;
                               esignatorySupplier.cTin_SupplierAccount__c=contract.cTin_SupplierAccount__c;
                               esignatorySupplier.entityName__c=contract.cTin_SupplierAccount__c;
                               esignatorySupplier.Contract__c = contract.Id;
                               esignatorySupplier.Contact__c = contactSupplier.Id;
                               esignatorySupplier.FirstName__c = contactSupplier.FirstName;
                               esignatorySupplier.LastName__c= contactSupplier.LastName;
                               esignatorySupplier.Name = contactSupplier.FirstName + contactSupplier.LastName;
                               esignatorySupplier.MobileTxt__c = contactSupplier.MobilePhone;
                               esignatorySupplier.EmailTxt__c = contactSupplier.Email;
                               esignatorySupplier.OrderCreation__c = order_number++; //NJA Case 1176
                               esignatorySupplier.Order__c = 1;
                               esignatorySupplier.Code__c = ( contactSupplier.MobilePhone==null ? 'email':'sms');

                              //esignatorySupplier.recordtypeId =system.label.cTin_RTSupplierSignatory;
                               esignatorySupplier.recordtypeId =Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
                               esignatorySupplier.cTin_role__c =system.label.cTin_RoleSupplierRep;                                              
                               try{
                                   insert esignatorySupplier;
                               } 
                               Catch(Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())) ;   showpageblock=false ;   
                               }
                           } 
                           
                           Contact contactAXA =  new Contact() ; 
                           //MRA 2016/01/07 -Case 1176
                           if (contract.cTin_AXASignatoryRepresentative__c !=null 
                               && !(contract.cTin_UnilateralSupplier__c)) {
                                   contactAXA = [Select Id,cTin_Active__c, Name, FirstName, LastName, MobilePhone, Email, 
                                                 AccountId, Account.Name 
                                                 from Contact 
                                                 WHERE Id = :contract.cTin_AXASignatoryRepresentative__c limit 1];
                               } 
                           
                           if(contactAXA.Email == null || contactAXA.cTin_Active__c==false /*&& !Contract.cTin_UnilateralAXARepresentative__c*/){
                               //29/06/2016 - MRA ( Case 1176) : updated if condition line 239 to cater for unilateral
                               if(!Contract.cTin_UnilateralAXARepresentative__c && !contract.cTin_UnilateralSupplier__c || (Contract.cTin_UnilateralAXARepresentative__c &&  !contract.cTin_UnilateralSupplier__c )){
                                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning ,contactAXA.Name +  system.label.ErrorMessageNoActiveMail )  ) ;  showpageblock=false ;
                                      //DoNotContinue = true ;
                                  }          
                           } 
                           
                           if( contactAXA.Email == contactSupplier.Email ){
                               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning , system.label.SameContactEmail)  ) ;  showpageblock=false ;
                               DoNotContinue = true ;
                               Database.rollback(sp);
                           }  
                           
                           
                           if(contactAXA.Id !=null  && DoNotContinue==false ){
                               
                               Id rtAXARep = [SELECT Id FROM RecordType 
                                              where DeveloperName = 'cTin_AXA_Representative' limit 1].id;
                               
                               eSignatory__c esignatoryAxa = new eSignatory__c();
                               
                               esignatoryAxa.cTin_OriginalRepresentative__c= true ; 
                               esignatoryAxa.eSignature__c = eSignature.Id;  
                               esignatoryAxa.Contract__c = contract.Id;
                               
                               /*29/06/2016-MRA(Case 1176) : Updated code to cater for unilateral*/
                               
                               if(contract.cTin_UnilateralAXARepresentative__c){
                                   esignatoryAxa.cTin_SupplierAccount__c = contactAXA.AccountId;
                                   esignatoryAxa.EntityName__c=contactAXA.AccountId;
                               }else{
                                   esignatoryAxa.cTin_SupplierAccount__c = system.label.cTin_AllLegalAXAEntityID;
                                   esignatoryAxa.EntityName__c=contactAXA.AccountId;
                               }
                               
                               esignatoryAxa.Contact__c = contactAXA.Id;
                               esignatoryAxa.Name = contactAXA.FirstName + contactAxa.LastName;
                               esignatoryAxa.FirstName__c = contactAXA.FirstName;
                               esignatoryAxa.LastName__c = contactAxa.LastName;
                               esignatoryAxa.MobileTxt__c = contactAxa.MobilePhone;
                               esignatoryAxa.EmailTxt__c = contactAxa.Email;
                               esignatoryAxa.OrderCreation__c = order_number++; //NJA Case 1176
                               esignatoryAxa.Order__c = 2;
                               esignatoryAxa.cTin_SupplierAccount__c= contactAxa.Account.Id;
                               esignatoryAxa.EntityName__c=contactAXA.AccountId;
                               //esignatoryAxa.recordtypeId =system.label.cTin_RTAxaSignatory ;
                               esignatoryAxa.recordtypeId=Schema.SObjectType.esignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
                               esignatoryAxa.cTin_role__c =system.label.cTin_RoleAxaRep;
                               esignatoryAxa.Code__c = ( contactAxa.MobilePhone==null ? 'email':'sms');
           
                               try{     
                                   insert esignatoryAxa;           
                                   
                               }Catch(DMLException e){ 
                                System.Debug('#### e.getMessage() : '+e.getMessage() )  ; 
                               } 
                           }
                           eSignatoryList = [Select Id, Contact__r.Name, /*RecordTypeId,*/cTin_OriginalRepresentative__c ,contract__r.Id,
                                             contract__r.cTin_SupplierAccount__c, Contact__r.cTin_RelatedUser__c, FirstName__c/*,cTin_UnilateralSupplier__c*/, 
                                             LastName__c, cTin_Role__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, /*unilateralAXA__c,*/
                                             Code__c, Order__c, Contact__c, cTin_ParenteSignatory__c, 
                                             SuccessURL__c, FailURL__c, CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,
                                             entityname__c 
                                             FROM eSignatory__c WHERE eSignature__c=:eSignature.Id order by Order__c ];
                         
                           if(eSignatoryList.size()>0)
                           {
                               numeroOrdreDebut=Integer.valueOf(eSignatoryList.get(0).Order__c);
                               Integer  tailleList = eSignatoryList.size()-1;
                               numeroOrdreFin =Integer.valueOf(eSignatoryList.get(tailleList).Order__c);
                           } 
                           
                           //get Delivery Content And  copie to Esignature
                           List<ContentDistribution> cdistList = [SELECT Name,ownerID, CreatedDate, RelatedRecordId, ContentDocumentId, DistributionPublicUrl,ContentVersionId,ContentVersion.ContentDocument.FileType FROM ContentDistribution WHERE RelatedRecordId=:contractId order by CreatedDate Desc];
                           list<ContentDistribution>esignCdLst=new list<ContentDistribution>();
                           
                           if( cdistList.size()>0 && eSignature.Id != null ){

                               boolean notCorrespondingUrl = false ; 
                               
                               for(ContentDistribution cd :  cdistList ){ 
                                 
                                  if (cd.ContentVersion.ContentDocument.FileType != 'PDF' || cd.Name.length() >89){
                                      if(cd.ContentVersion.ContentDocument.FileType != 'PDF'){
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'All Content Deliveries should be in PDF format.')) ; 
                                        showpageblock=false ;
                                        Database.rollback(sp);
                                      }
                                      // 13-AUG-2018 MRA : Case 00004282
                                      if(cd.Name.length() >89 ) {
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.label.AP10_ErrMsgLengthIncorrect)) ; 
                                        showpageblock=false ;
                                        Database.rollback(sp);
                                      } 
                                  }
                                  else{
                                     notCorrespondingUrl=true;
                                     if(cd.ContentDocumentId!= null){
                                         ContentVersion cVersion = new ContentVersion () ; 
                                         cVersion = [SELECT VersionData,OwnerID,ContentDocumentId, ContentDocument.PublishStatus 
                                                     FROM ContentVersion 
                                                     WHERE ContentDocumentID =:cd.ContentDocumentId limit 1];
                                         ContentDistribution eSignCD = new ContentDistribution(RelatedRecordId = eSignature.Id, Name = cd.Name, ContentVersionId = cVersion.Id,PreferencesNotifyOnVisit = false);
                                         esignCdLst.add(eSignCD);
                                     }
                                   }                                                             
                               }
                               
                               if(esignCdLst.size()>0 && showpageblock==true)
                                   insert esignCdLst;  
                           } 
                           else { 
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,label.ErrorMessageEsignNoDocs) ) ; showpageblock=false ; 
                             Database.rollback(sp);
                           }
                           
                           nbDeleveryContent = cdistList.size();
                           
                       }
                   }else {
                    //display error if current user does not belong to same entity as contract owner
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,label.MessageBlockCreation2) ) ; showpageblock=false ; 
                }
            }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,label.cTin_ErrorMessageBlckCreation) ) ; 
                showpageblock=false ;
            }    
            
            if(esignature!=null && showpageblock==true){
             save();
             pgRef=new pageReference('/'+esignature.id);
            }
            else{
              pgRef=null;
            }
            //edit
        } else if(eSignatureId!=null){
            List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
            eSignature = [Select Id, Name, Status__c, CreatedDate, Contract__r.Name, CreatedById, cTin_ShortDescription__c, FinalDocumentURL__c, 
            cTin_KeyPoints__c, cTin_TotalSpendExcVAT2__c, 
                          cTin_StartDate__c, cTin_AXAMainLegalSignatoryEntity__c,cTin_SupplierLegalSignatoryEntity__c, cTin_AXAMainSignatoryRepresentative__c, 
                          cTin_SupplierSignatoryRepresentative__c,cTin_FinalApproval1__c,cTin_FinalApproval2__c,
                          cTin_FinalApproval3__c,cTin_FinalApproval4__c,cTin_FinalApproval5__c,cTin_FinalApproval6__c,
                          cTin_FinalApproval7__c,cTin_FinalApproval8__c,cTin_FinalApproval9__c,cTin_FinalApproval10__c,
                          ExternalId__c,RecordTypeId,URL__c,LastModifiedById,Language__c ,cTin_TECH_IsContractIn__c,contract__r.cTin_OwnerEntity__c
                          from eSignature__c 
                          WHERE Id=:eSignatureId];
            
            
            //owner = [Select Id, Name from User WHere id=:eSignature.CreatedById];
            eSignatoryList = [Select Id, Contact__r.Name, recordTypeID, contract__r.Id,contract__r.cTin_SupplierAccount__c, 
                              contract__r.cTin_AXAMainLegalSignatoryEntity__c, cTin_OriginalRepresentative__c,Contact__r.cTin_RelatedUser__c 
                              ,FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
                              Code__c, Order__c, Contact__c, cTin_SupplierAccount__c,  cTin_ParenteSignatory__c, SuccessURL__c, entityname__c,
                              FailURL__c, CancelURL__c,contact__r.AccountId,
                              esignature__c,esignature__r.Name,esignature__r.Status__c,esignature__r.CreatedDate,esignature__r.Contract__r.Name, 
                              esignature__r.CreatedById,esignature__r.cTin_ShortDescription__c, esignature__r.FinalDocumentURL__c, 
                              esignature__r.cTin_KeyPoints__c, esignature__r.cTin_TotalSpendExcVAT2__c, 
                              esignature__r.cTin_StartDate__c, esignature__r.cTin_AXAMainLegalSignatoryEntity__c,esignature__r.cTin_SupplierLegalSignatoryEntity__c, 
                              esignature__r.cTin_AXAMainSignatoryRepresentative__c, 
                              esignature__r.cTin_SupplierSignatoryRepresentative__c,esignature__r.cTin_FinalApproval1__c,esignature__r.cTin_FinalApproval2__c,
                              esignature__r.cTin_FinalApproval3__c,esignature__r.cTin_FinalApproval4__c,esignature__r.cTin_FinalApproval5__c,
                              esignature__r.cTin_FinalApproval6__c,
                              esignature__r.cTin_FinalApproval7__c,esignature__r.cTin_FinalApproval8__c,esignature__r.cTin_FinalApproval9__c,
                              esignature__r.cTin_FinalApproval10__c,contract__r.name,
                              esignature__r.ExternalId__c,esignature__r.RecordTypeId,esignature__r.URL__c,esignature__r.LastModifiedById,esignature__r.Language__c 
                              FROM eSignatory__c 
                              WHERE eSignature__c=:eSignature.Id 
                              order by Order__c ];
            
            //show Delivery content number
            List<ContentDistribution> cdistList = [SELECT Name, RelatedRecordId, ContentDocumentId, 
                                                   DistributionPublicUrl 
                                                   FROM ContentDistribution 
                                                   WHERE RelatedRecordId=:eSignature.Id];
            nbDeleveryContent = cdistList.size();
            contractName = eSignatoryList[0].Contract__r.Name;
            
            if(!empty(eSignatoryList))
            {
                //create list without observers
                for(eSignatory__c eAll : eSignatoryList){
                    if(eAll.RecordTypeId!='0123E000000CnQeQAK'){
                        listWithoutObserver.add(eAll);
                    }
                }
                
                numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
                Integer  tailleList = listWithoutObserver.size()-1;
                numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
            } 

            pgRef=null;       
        } 
       /* if(DoNotContinue==false){
          pgRef=new PageReference('/'+esignature.id);

          }  else{
            pgRef=null;
          }    
        return pgRef;  */
        return pgRef;
    }
    
    public  PageReference descendre()
    {
        ordredescente=Integer.valueOf(ApexPages.currentPage().getParameters().get('ordre_descente'));
        Map<Decimal,List<esignatory__c>> mapEsignatory = new Map<Decimal,List<esignatory__c>>();
        Map <Id, eSignatory__c> mapTempEsign = new Map <Id,eSignatory__c>();
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        
        for(eSignatory__c e : eSignatoryList){
            mapTempEsign.put(e.Id, e);
        }
        //create a familly
        for(eSignatory__c familly : eSignatoryList){
           // if(familly.RecordTypeId ==system.label.cTin_RTAxaSignatory ||familly.RecordTypeId==system.label.cTin_RTSupplierSignatory){
           If(familly.RecordTypeId ==Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId() 
             || familly.RecordTypeId==Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId() ){
                //get parent
                System.debug('----------------- in if 1');
                //System.debug('----------------- familly'+ familly);
                eSignatory__c parent = familly;
                List <eSignatory__c> childrenList = new List<eSignatory__c>();
                
                
                //get children   
                for(eSignatory__c esM: mapTempEsign.values()){
                    if(esM.cTin_ParenteSignatory__c == parent.Id){
                        System.debug('----------------- in if 2');
                        childrenList.add(esM);
                    }
                }
                
                //System.debug('----------------- childrenList'+ childrenList);
                
                List<eSignatory__c> familyTempList = new List <eSignatory__c>();
                familyTempList.add(parent);
                familyTempList.addAll(childrenList);
                
                //put family in the map
                mapEsignatory.put(parent.Order__c, familyTempList);
                //System.debug('----------------- familyTempList'+ familyTempList);
                System.debug('----------------- mapEsignatory'+ mapEsignatory);
            }
        }
        
        //comparer la clé de la map au param pour récuper la liste
        
        if(mapEsignatory.containsKey(ordredescente)){
            System.debug('----------------- in if 3');
            List<eSignatory__c> listFromMap = mapEsignatory.get(ordredescente);
            List<eSignatory__c> listDown = new List<eSignatory__c>();
            List<eSignatory__c> listUp = new List<eSignatory__c>();
            Integer nextKey= listFromMap.size();
            Integer ordreSuivant = ordredescente+nextKey;
            System.debug('---------------nextKey' +nextKey);
            System.debug('---------------ordreSuivant' +ordreSuivant);
            
            listUp = mapEsignatory.get(ordreSuivant);
            listDown.addAll(listFromMap);
            
            System.debug('---------------listUp' +listUp);
            System.debug('---------------mapEsignatory1' +mapEsignatory);
            //réorganiser la map
            //list DOwn
            mapEsignatory.put(ordreSuivant, listDown);
            System.debug('---------------mapEsignatoryDown' +mapEsignatory);
            //list Up
            
            System.debug('---------------ordredescente' +ordredescente);
            mapEsignatory.put(ordredescente, listUp);
            System.debug('---------------mapEsignatoryUp' +mapEsignatory);
        }
        System.debug('---------------mapEsignatoryFinal' +mapEsignatory);
        Integer order = 0;
        //for(List <eSignatory__c> updateOrdreList :mapEsignatory.values()){
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
        
       // System.debug('---------------eSignatoryList' +eSignatoryList);
        //upsert eSignatoryList;
       
        if(!empty(eSignatoryList))
        {
            //create list without observers
            
            for(eSignatory__c eAll : eSignatoryList){
                /*if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                    listWithoutObserver.add(eAll);
                }*/
                if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                  listWithoutObserver.add(eAll);
                }
            }
            
            
            numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
            
        }       
        return null;
         
    }
    
    public PageReference monter()
    {
        ordredescente=Integer.valueOf(ApexPages.currentPage().getParameters().get('ordre_descente'));
        Map<Decimal,List<esignatory__c>> mapEsignatory = new Map<Decimal,List<esignatory__c>>();
        Map <Id, eSignatory__c> mapTempEsign = new Map <Id,eSignatory__c>();
        List <eSignatory__c> listPrevious= new List <eSignatory__c>();
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        
        for(eSignatory__c e : eSignatoryList){
            mapTempEsign.put(e.Id, e);
        }
        
        //create a familly
        for(eSignatory__c familly : eSignatoryList){
           // if(familly.RecordTypeId ==System.Label.cTin_RTAxaSignatory ||familly.RecordTypeId==System.Label.cTin_RTSupplierSignatory){
             if(familly.RecordTypeId ==Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId() 
              || familly.RecordTypeId==Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId()){
    
                //get parent
                System.debug('----------------- in if 1');
                System.debug('----------------- familly'+ familly);
                eSignatory__c parent = familly;
                List <eSignatory__c> childrenList = new List<eSignatory__c>();
                
                
                //get children   
                for(eSignatory__c esM: mapTempEsign.values()){
                    if(esM.cTin_ParenteSignatory__c == parent.Id){
                        System.debug('----------------- in if 2');
                        childrenList.add(esM);
                    }
                }
                
                //System.debug('----------------- childrenList'+ childrenList);
                
                List<eSignatory__c> familyTempList = new List <eSignatory__c>();
                familyTempList.add(parent);
                familyTempList.addAll(childrenList);
                
                //put family in the map
                mapEsignatory.put(parent.Order__c, familyTempList);
               // System.debug('----------------- familyTempList'+ familyTempList);
                //System.debug('----------------- mapEsignatory'+ mapEsignatory);
            }
        }
        
        for(esignatory__c tempElem: eSignatoryList){
            System.debug('#################### tempElem' + tempElem);
            System.debug('#################### ordredescente' + ordredescente);
            if(tempElem.Order__c == ordredescente-1 && tempElem.cTin_ParenteSignatory__c != null){
                id IdtempParent = tempElem.cTin_ParenteSignatory__c;
                eSignatory__c parent = mapTempEsign.get(IdtempParent);
                Decimal orderParent = parent.Order__c;
                listPrevious = mapEsignatory.get(orderParent);
            }else if(tempElem.Order__c == ordredescente-1 && tempElem.cTin_ParenteSignatory__c == null){
                listPrevious = mapEsignatory.get(tempElem.Order__c);
            }
        }
        
        
        System.debug('----------------- in if 3');
        List<eSignatory__c> listFromMap = mapEsignatory.get(ordredescente);
        List<eSignatory__c> listDown = new List<eSignatory__c>();
        List<eSignatory__c> listUp = new List<eSignatory__c>();
        Integer previousKey = listPrevious.size(); 
        Integer ordrePrecedent = ordredescente-previousKey;
        System.debug('---------------previousKey' +previousKey);
        System.debug('---------------ordrePrecedent' +ordrePrecedent);
        
        listUp.addAll(listFromMap);
        listDown = mapEsignatory.get(ordrePrecedent);
        
        System.debug('---------------mapEsignatory1' +mapEsignatory);
        //réorganiser la map
        //list DOwn
        mapEsignatory.put(ordrePrecedent, listUp);
        System.debug('---------------mapEsignatoryDown' +mapEsignatory);
        //list Up
        
        System.debug('---------------ordredescente' +ordredescente);
        mapEsignatory.put(ordredescente, listDown);
        System.debug('---------------mapEsignatoryUp' +mapEsignatory);
        
        Integer order = 0;
        
        List<Decimal> sortedKeys = new List<Decimal>(mapEsignatory.keySet());
        sortedKeys.sort();
        eSignatoryList.clear();
        for(Decimal key : sortedKeys) {
            List <eSignatory__c> updateOrdreList = mapEsignatory.get(key);
            for(eSignatory__c eSignElem : updateOrdreList){
                eSignElem.Order__c = order+1;
                update eSignElem;
                eSignatoryList.add(eSignElem);
                order++;
            }
            
        }
        
        //test begin
        if(!empty(eSignatoryList))
        {
            //create list without observers
            
            for(eSignatory__c eAll : eSignatoryList){
                /*if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                    listWithoutObserver.add(eAll);
                }*/

                if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                   listWithoutObserver.add(eAll);
                }
            }

            numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
            
        }       
        
        //test end
        
        return null; 
    }
    
    public PageReference add() {
        
        //get parameter
        add_order=Integer.valueOf(ApexPages.currentPage().getParameters().get('add_order'));
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        
        System.debug('##### add_order '+add_order);
        Id parentId = null;
        Integer index= null;
        
        for(Integer i=0; i<eSignatoryList.size(); i++){
            //find index of selected Reciepient =>get index
            if(eSignatoryList.get(i).Order__c==add_order){
                //increment all following indexs +1
                index= i+1;
                ParentId = eSignatoryList.get(i).Id;    
            }           
        }
                
        eSignatory__c cs =  new eSignatory__c();
        cs = (eSignatory__c)eSignatory__c.sObjectType.newSObject(System.Label.cTin_RTNegotiatorSignatory, true) ; 
        cs.eSignature__c = eSignature.Id;
        if(eSignatoryList.size() > 0) cs.Contract__c = eSignatoryList.get(0).contract__c;
        cs.OrderCreation__c =  add_order+1;
        cs.Order__c =  add_order+1;
        cs.cTin_ParenteSignatory__c=parentId; 
        //cs.recordTypeId=system.label.cTin_RTNegotiatorSignatory;   
        cs.recordTypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId();
        cs.cTin_role__c=system.label.cTin_RoleNegotiator;        

        insert cs;
        
        list<eSignatory__c> eSignatoryToUpsert = new list<eSignatory__c>();
        
        for(Integer j=0; j<eSignatoryList.size();j++){
            if(j>=index){ 
                //get element of the list 
                eSignatory__c e = eSignatoryList.get(j);
                // increment the order of all the following elements
                e.Order__c = e.Order__c+1;
                eSignatoryToUpsert.add(e);
            } 
        }
       // system.debug('## eSignatoryToUpsert: '+eSignatoryToUpsert);
        // try{
        if(eSignatoryToUpsert.size() >0 ){
            upsert eSignatoryToUpsert;
            
        }
        // }  Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
        
        
        
        if(index<eSignatoryList.size()){
            // add the element using the designated index of the list
            eSignatoryList.add(index, cs);  
        }
        else{ eSignatoryList.add(cs);}
        
        
        if(!empty(eSignatoryList))
        {
            //create list without observers
            
            for(eSignatory__c eAll : eSignatoryList){
                /*if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                    listWithoutObserver.add(eAll);
                }*/
                if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                 listWithoutObserver.add(eAll);
                }
            }

            numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            
            numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c); 
        }      

        //System.debug('### eSignatoryListAdd'+eSignatoryList);
        return null;
        
    }//end method add
    
    
    public PageReference save(){
        
        /**Declaration des variables**/
        integer PositionX = 0 ; 
        List<eSignatory__c> ListNegotiator = new List<eSignatory__c>() ;
        List<eSignatory__c> ListRepresentatif = new List<eSignatory__c>() ;   
        Map<ID, List<eSignatory__c>> MapSignatoWchids = new Map<ID,List<eSignatory__c>>() ; 
        List<eSignatory__c> ListSigToUpdate = new List<eSignatory__c>() ;
        List<Contact> ListContacts = new List<Contact>() ; 
        Map<Id,Contact> MapContact = new Map<ID,Contact>() ;  
        List<eSignatory__c> ListSignatoryToUpsert  = new List<eSignatory__c>() ;                
        
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        System.Debug('### eSignatoryList while Save :' + eSignatoryList );
        add = false;
        try{
            if(MY_ERR_MSG != null && MY_ERR_MSG != '')eSignatoryList.remove(eSignatoryList.size()-1);
            
            System.debug('#### signature : ' + eSignature ) ;  
            upsert eSignature ;    
            try{upsert eSignatoryList;}
            catch(Exception e){ system.debug('## validation error - upserting esignatory'+ e.getMessage());}
        }Catch(Exception e){return null;}
            
            /*// Case 2439 
            if(!e.getMessage().contains('The language you selected is not valid for your entity')){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Warning, label.ErrorMessageForSave)) ; 
                showpageblock =true; 
            }*/
            //return null; 
        
        eSignatoryList = [Select Id,cTin_OriginalRepresentative__c,contract__r.Id, contract__r.cTin_SupplierAccount__c, 
                          contract__r.cTin_AXAMainLegalSignatoryEntity__c, Name__c ,contact__r.recordtype.name, 
                          Contact__c, FirstName__c, LastName__c, cTin_Role__c,Name,entityname__c, 
                          Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c, contact__r.AccountId,
                          cTin_ParenteSignatory__c, SuccessURL__c, FailURL__c, CancelURL__c, cTin_SupplierAccount__c 
                          FROM eSignatory__c 
                          WHERE eSignature__c=:eSignature.Id and  Order__c != null
                          order by Order__c asc];
        
        /******************Replacement*****************/    
        
        ListContacts = [Select Id, FirstName, LastName, MobilePhone, recordtype.name,Email, Account.Name 
                        from contact ] ; 
        
        
        for( Contact con : ListContacts ) {
            MapContact.put(con.ID,con) ; 
        }
        
        
        for(eSignatory__c es :eSignatoryList){
        
            if(es.Code__c == 'sms' && (es.MobileTxt__c == null || es.MobileTxt__c == ''))  {
                            system.debug('######## no mobile to Save');
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,System.label.MessageMobileBlock);
                            ApexPages.addMessage(myMsg);
                            //showpageblock=false ; 
                            return null;
            }
                        
            Contact c = new Contact() ; 
            if(es.FirstName__c==null || es.Name != es.Name__c){
                //add try catch avec le message d'erreur que Fabien va créer 
                if(es.Contact__c != null) {
                    if( MapContact.get(es.Contact__c)  != null && MapContact.get(es.Contact__c) .ID!= null){ 
                        es.FirstName__c = MapContact.get(es.Contact__c).FirstName;
                        es.LastName__c = MapContact.get(es.Contact__c).LastName;
                        es.Name = es.FirstName__c + es.LastName__c ; 
                        es.MobileTxt__c = MapContact.get(es.Contact__c).MobilePhone;
                        es.EmailTxt__c = MapContact.get(es.Contact__c).Email;
                        //es.cTin_SupplierAccount__c= MapContact.get(es.Contact__c).Account.Name;
                        es.cTin_SupplierAccount__c = MapContact.get(es.Contact__c).Account.Id;
                        es.entityName__c = MapContact.get(es.Contact__c).Account.Id;
                        
                        if(MapContact.get(es.Contact__c).recordtype.name=='AXA' && es.cTin_ParenteSignatory__c==null){
                            es.cTin_role__c=system.label.cTin_RoleAxaRep;
                            //es.recordtypeId=system.label.cTin_RTAxaSignatory;
                            es.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
                        }
                        else if(MapContact.get(es.Contact__c).recordtype.name=='Supplier' && es.cTin_ParenteSignatory__c==null){
                            es.cTin_role__c=system.label.cTin_RoleSupplierRep;
                           //es.recordtypeId=system.label.cTin_RTSupplierSignatory;
                            es.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
                        }
                        else{
                            es.cTin_role__c=system.label.cTin_RoleNegotiator;
                            //es.recordtypeId=system.label.cTin_RTNegotiatorSignatory;
                            es.recordtypeId=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId();
                        }
                        
                        //Add By Mouad Pour empêcher le save si le mobile n'est pas renseigné(2)
                        if(es.Code__c == 'sms' && (es.MobileTxt__c == null || es.MobileTxt__c == ''))  {
                            system.debug('######## no mobile to Save');
                           //// ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,System.label.MessageMobileBlock);
                            //ApexPages.addMessage(myMsg);
                            return null;
                        }
                    }
                }                      
            }
        }
        
       
        
        /******************Replacement*****************/  
        
        /**** Modification pour l'ordre des cachets sur une signature ****/
        for(Integer i=0; i<eSignatoryList.size(); i++){
            
            if(eSignatoryList.get(i).cTin_Role__c !=system.label.cTin_RoleNegotiator){
                PositionX++ ;
                System.Debug('###  PositionX : ' + PositionX ) ; 
                eSignatoryList.get(i).OrderCachet__c  = PositionX ; 
                if(eSignatoryList.get(i).OrderCachet__c == 1) {
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c =55 ; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 2){ 
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c =55 ; 
                }else if (eSignatoryList.get(i).OrderCachet__c == 3){ 
                    eSignatoryList.get(i).x__c= 50; eSignatoryList.get(i).y__c = 110; 
                }else if(eSignatoryList.get(i).OrderCachet__c ==  4){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 110; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 5 ) {
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 165; 
                }else if(eSignatoryList.get(i).OrderCachet__c ==  6){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 165; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 7){ 
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 220; 
                } else if(eSignatoryList.get(i).OrderCachet__c ==  8){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 220; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 9 ){ 
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 275; 
                }else if (eSignatoryList.get(i).OrderCachet__c ==  10){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 275;
                }else if(eSignatoryList.get(i).OrderCachet__c == 11){
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 330; 
                }else if(eSignatoryList.get(i).OrderCachet__c ==  12){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 330; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 13){ 
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 385; 
                }else if(eSignatoryList.get(i).OrderCachet__c ==  14){
                    eSignatoryList.get(i).x__c= 400;eSignatoryList.get(i).y__c = 385; 
                }else if(eSignatoryList.get(i).OrderCachet__c == 15){
                    eSignatoryList.get(i).x__c= 50;eSignatoryList.get(i).y__c = 440 ;}
            }
        }    
        
        
        
        /***************** Observers By Signer *************/
        for(eSignatory__c esig : eSignatoryList){
            if(esig.cTin_ParenteSignatory__c !=null  &&  !MapSignatoWchids.containskey(esig.cTin_ParenteSignatory__c)){
                MapSignatoWchids.put(esig.cTin_ParenteSignatory__c , new List<eSignatory__c>()) ; 
            }
            if(esig.cTin_ParenteSignatory__c != null) MapSignatoWchids.get(esig.cTin_ParenteSignatory__c).Add(esig) ; 
        }
        /****************** Traitement *******************/
        //System.Debug('### begin process List Sig :' + eSignatoryList) ; 
        if(eSignatoryList.size()>0 || MapSignatoWchids.size()>0){
            integer NumberInList = 0 ; 
            for(Integer i=0 ; i< eSignatoryList.size() ; i++){       
                // Fils ou Pas
                if(MapSignatoWchids.get(eSignatoryList.get(i).ID) !=null){  
                    
                    for(eSignatory__c observerSign : MapSignatoWchids.get(eSignatoryList.get(i).ID) ){
                        observerSign.OrderToSend__c = NumberInList++   ; ListSigToUpdate.add(observerSign) ;               
                    } 
                    
                    
                }
                if(NumberInList != null && eSignatoryList.get(i).cTin_ParenteSignatory__c == null) {
                    eSignatoryList.get(i).OrderToSend__c  =NumberInList ++ ;   
                    ListSigToUpdate.add(eSignatoryList.get(i)) ;
                    System.Debug('### Cas 2  LastNumberOrder + 1 : ' +   eSignatoryList.get(i).OrderToSend__c ) ;      
                }
                if(NumberInList == 0 && eSignatoryList.get(i).cTin_ParenteSignatory__c == null ){
                    eSignatoryList.get(i).OrderToSend__c  = i ; ListSigToUpdate.add(eSignatoryList.get(i)) ; 
                    System.Debug('### Cas 3 LastNumerberOrde=null : ' + i ) ;      
                }      
                
            }    
        }
        /***********************************************************************************************/    
        
        //System.Debug('### ListSigToUpdate : ' + ListSigToUpdate ) ;
        if(ListSigToUpdate.size()>0){
            try{
                update ListSigToUpdate ;
            }  Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
            
        }
        
        
        //System.debug('### eSignatoryList'+eSignatoryList);
        
        return new PageReference('/'+eSignature.Id); 
        //return new PageReference('/'+eSignature.Contract__c);
    }
    
    
    
    public PageReference deleteEsignatory(){
        
        String passedParam = ApexPages.currentPage().getParameters().get('delete_id')  ;  
        if(passedParam !=''){ 
            delete_id=Integer.valueOf(passedParam );
        }    
        //System.debug('##### param delete_id '+delete_id);
        
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        
        List<eSignatory__c> listWithoutOrder = new List<eSignatory__c>() ; 
        Map <Decimal, eSignatory__c> eSignMap= new Map <Decimal, eSignatory__c>();
       // System.debug('##### eSignatoryList l 770 '+eSignatoryList);
        for(eSignatory__c eMap : eSignatoryList){
            if(eMap.Order__c == null ){
                listWithoutOrder.add(eMap) ; 
            }else if(delete_id !=null) {
                System.debug('##### emap.Order__c l 775 '+emap.Order__c);
                eSignMap.put(emap.Order__c, emap);
            }
        }
        
        if(listWithoutOrder.size()>0){listWithoutOrder.clear(); }
        
        //System.debug('### map for delete' +eSignMap);
        
        eSignatory__c eSignToDelete = new eSignatory__c();    
        
        if(delete_id !=null){
            eSignToDelete = eSignMap.get(delete_id);
        }
        
        //System.Debug('### eSignToDelete :' + eSignToDelete ) ; 
        
        list<Esignatory__c> esignatoryToUpdate=new list<Esignatory__c>();
        for(eSignatory__c esignToUpdate :eSignatoryList){
            if(esignToUpdate.Order__c>eSignToDelete.Order__c){
                esignToUpdate.Order__c=esignToUpdate.Order__c-1;
                //System.debug('##### esignToUpdate.Order__c '+esignToUpdate.Order__c);
                                
                //if(esignToUpdate.Contact__c != null) {
                  esignatoryToUpdate.add(esignToUpdate);
                //}
                  /* try{
                        update esignToUpdate;
                    } */ 
                    //Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
                  
            }
            
            if(esignatoryToUpdate.size()>0){
              try{
                update esignatoryToUpdate;
              }  
              Catch(Exception e){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; 
              } 
            }
            
        }


        //System.Debug('#### Signatory to delete test :'+ eSignToDelete.Contact__r.cTin_RelatedUser__c ) ; 
        
        eSignatory__c esigntoDeleteV2 = new eSignatory__c();
        try{
            esigntoDeleteV2 = [select Id , Contact__r.cTin_RelatedUser__c ,contract__c,RecordTypeID,
                               cTin_SupplierAccount__c,contact__r.AccountId,entityName__c
                               from eSignatory__c 
                               where id =: eSignToDelete.ID] ; 
        } Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
        
        if(esigntoDeleteV2 != null && esigntoDeleteV2.Id != null && 
          /*esigntoDeleteV2.RecordTypeId== System.Label.cTin_RTAxaSignatory*/
          esigntoDeleteV2.RecordTypeId==(Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId())
           && esigntoDeleteV2.Contact__r.cTin_RelatedUser__c !=null){
               //System.Debug('### esigntoDeleteV2.Contact__r.cTin_RelatedUser__c :' + esigntoDeleteV2.Contact__r.cTin_RelatedUser__c ) ; 
               List<cTin_ContractTeam__c> TeamMemberToDel = new List<cTin_ContractTeam__c>() ; 
               TeamMemberToDel  = [Select id,cTin_TeamMember__c 
                                   from cTin_ContractTeam__c 
                                   where cTin_TeamMember__c =: esigntoDeleteV2.Contact__r.cTin_RelatedUser__c
                                   and cTin_Contract__c=:esigntoDeleteV2.contract__c] ;
               if(TeamMemberToDel.size()>0){
                   try{
                       delete TeamMemberToDel ; 
                   }  Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())) ; } 
               }
           }
        
        //    
        if(esigntoDeleteV2 != null && esigntoDeleteV2.Id != null ){
            try{
                delete eSignToDelete;
            }Catch(Exception e){ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'The Signatory is deleted.')) ; } 
        }
        
        //upsert eSignatoryList;
        eSignatoryList = [Select Id, RecordTypeId, cTin_OriginalRepresentative__c ,contract__r.Id,eSignature__c, 
                          contract__r.cTin_SupplierAccount__c, Contact__c,Contact__r.cTin_RelatedUser__c, 
                          FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
                          Code__c, Order__c,cTin_ParenteSignatory__c, SuccessURL__c, FailURL__c, 
                          CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,entityName__c 
                          FROM eSignatory__c 
                          WHERE eSignature__c=:eSignatureId and  Order__c != null
                          order by Order__c asc];
        
        Set<ID> SetUserSignatory = new Set<ID>(); 
        
        //test begin
        if(!empty(eSignatoryList))
        {
            //create list without observers
            
            for(eSignatory__c eAll : eSignatoryList){
                /*if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                    listWithoutObserver.add(eAll);  
                }*/
                if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                  listWithoutObserver.add(eAll);  
                }
            }
            
            if(listWithoutObserver.size()>0){
                numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
                Integer  tailleList = listWithoutObserver.size()-1;                
                numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
            }
            
        }   
       // string esignId = ApexPages.currentPage().getParameters().get('eSignatureId');
        
        //PageReference pageRef = new PageReference('/apex/VFP37_ShowSignatory?contractId='+contractId+'&contractType=cTin');
        //pageRef.setRedirect(true);
        //return pageRef;
       // https://axags--dit--c.cs82.visual.force.com/apex/VFP37_showSignatory?contractId=a0D3E0000000pJV&contractType=cTin
        return null;
         //return new PageReference('/apex/VFP37_ShowSignatory?eSignatureId='+eSignatureId+'&contractType=cTin');
      // return new pageReference('/apex/VFP37_ShowSignatory?eSignatureId=a0S3E00000375bc&contractType=cTin');
        
    }
    
    
    // add a new supplierSignatory
    public PageReference addSignatory() {
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        add = true;
        eSignatory__c signatosup=  new eSignatory__c();
        
        signatosup=  (eSignatory__c )eSignatory__c.sObjectType.newSObject(System.Label.cTin_RTSupplierSignatory, true);
        try{
            signatosup.eSignature__c = eSignature.Id;
            signatosup.cTin_OriginalRepresentative__c = false ; 
           // signatosup.RecordTypeID = System.Label.cTin_RTSupplierSignatory ; 
            signatosup.RecordTypeID=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
            signatosup.cTin_role__c=system.label.cTin_RoleSupplierRep;
            //mra 01/07/2016: signatosup.order__c = eSignatoryList.size()+1;
            signatosup.order__c = eSignatoryList.size() +1;
            signatosup.Contract__c = eSignatoryList.get(0).contract__c;
            signatosup.cTin_SupplierAccount__c = eSignatoryList.get(0).contract__r.cTin_SupplierAccount__c;
            //mra 01/07/2016: signatosup.OrderCreation__c =  eSignatoryList.size()+1 ;
            signatosup.OrderCreation__c =  eSignatoryList.size() +1 ;
            
            insert signatosup;
            
        }catch(Exception e){ 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, label.ErrorMessageContNoSign) ) ; showpageblock=false ; 
        }   
        
        eSignatoryList.add ( signatosup);
        
        if(!empty(eSignatoryList))
        {
            numeroOrdreDebut=Integer.valueOf(eSignatoryList.get(0).Order__c);
            Integer  tailleList = eSignatoryList.size()-1;
            numeroOrdreFin =Integer.valueOf(eSignatoryList.get(tailleList).Order__c);
        } 

        return null;
    }
    
    // ADD Axa representative Signatory    
    public PageReference addAxaSignatory() {
        
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        add = true;
        eSignatory__c cs =  new eSignatory__c(); 
        cs = (eSignatory__c)eSignatory__c.sObjectType.newSObject(System.Label.cTin_RTAxaSignatory, true) ; 
        
        try{
            
            cs.eSignature__c = eSignature.Id;
            //cs.RecordTypeID = System.Label.cTin_RTAxaSignatory ; 
            cs.RecordTypeID=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
            cs.cTin_role__c=system.label.cTin_RoleAxaRep;
            cs.cTin_OriginalRepresentative__c =false ;             
            cs.order__c = eSignatoryList.size()+1;
            cs.Contract__c = eSignatoryList.get(0).contract__c;
            //hard coded id corresponds to the Account All Legal Entities
            //cs.cTin_SupplierAccount__c=system.label.cTin_AllLegalAXAEntityID; // to store in label
            //cs.cTin_SupplierAccount__c=eSignatoryList.get(0).contact__r.AccountId;
            
            Account acc = [SELECT ID FROM Account WHERE Name = :System.label.cTin_LabelAxaRep];

            //cs.cTin_SupplierAccount__c=eSignatoryList.get(0).contact__r.AccountId;
            cs.cTin_SupplierAccount__c = acc.Id;

            
            cs.OrderCreation__c =  eSignatoryList.size()+1;
            insert cs;
        }catch(Exception e){
            system.debug('###Error adding signatory AXA'+e.getMessage());
        }  
        
        eSignatoryList.add ( cs );
        
        if(!empty(eSignatoryList))
        {
            numeroOrdreDebut=Integer.valueOf(eSignatoryList.get(0).Order__c);
            Integer  tailleList = eSignatoryList.size()-1;
            numeroOrdreFin =Integer.valueOf(eSignatoryList.get(tailleList).Order__c);
        }

        return null;
    }
    
    /********************* Refresh the page from Lookup **********************************/   
    // reworked - MRA: 10/20/2017
    public PageReference refresh(){
        system.debug('Starting method refresh');
        
        //06/03/2015 un flag pour ne pas afficher le msg d'erreur lorsqu'on clique sur Add
        add = false;
        string recordtypeIdToQuery; // query supplier or axa contact in case contact name is not unique in system
        System.debug('### refresh');
        
        try{
            MY_ERR_MSG = null;
            MY_CON_ERR_MSG = null;
            MY_EMAIL_ERR_MSG = null;
            mySelectedcon = new Contact();
            // contact_Id = '';
            contact_Id = ApexPages.currentPage().getParameters().get('contact_Id')  ;
            esignatoryBis_Id = ApexPAges.currentPage().getParameters().get('esignatoryBis_Id');
            
            System.Debug('### esignatoryBis_Id : ' + esignatoryBis_Id ); 
            System.Debug('### passedParam_Contact ' + contact_Id) ; 
            
            // query esignatory to retrieve name and recortype
            list<Esignatory__c> currentsignatory=[select id,recordtype.name,contact__r.AccountId,entityName__c 
                                                  from esignatory__c 
                                                  where id =:esignatoryBis_Id];
            
            system.debug('## record type name of current signatory'+currentsignatory[0].recordType.name);
            
            //query contact AXA if esignatory.rt= AXA
            if(currentsignatory[0].recordtype.name.contains('AXA')){
                recordtypeIdToQuery=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            }
            //query contact supplier if esignatory.rt=Supplier
            else{
                recordtypeIdToQuery=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
            }
            
            if(recordtypeIdToQuery==null) recordtypeIdToQuery=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('AXA').getRecordTypeId();
            
            
            System.Debug('### recordtypeIdToQuery ' + recordtypeIdToQuery) ;
            
            if(contact_Id !=null){
                try{
                    //query selected contact
                    mySelectedcon = [Select Id, Name, RecordTypeId, FirstName, LastName, MobilePhone, 
                                     Email, Account.Name, AccountID 
                                     from Contact 
                                     where  Name=: contact_Id 
                                     AND cTin_LegalRepresentative__c = True 
                                     AND cTin_Active__c = True 
                                     AND RecordTypeId=:recordtypeIdToQuery Limit 1] ; 
                    System.debug('### mySelectedcon  989 : '+mySelectedcon);
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
                        MY_CON_ERR_MSG = system.label.ErrorDuplicateContactName;
                        Is_ERR = true;
                    }
                    if(es.EmailTxt__c == mySelectedcon.Email && esignatoryBis_Id != es.Id){
                        system.debug('same email text');
                        MY_EMAIL_ERR_MSG = 'Duplicate Email';
                        Is_ERR = true;
                    }   
                    
                    // modif 23/10/2015    Is_ERR from true to false
                    if(esignatoryBis_Id == es.Id && Is_ERR == false){
                        es.Contact__c = mySelectedcon.Id;
                        es.MobileTxt__c = mySelectedcon.MobilePhone;
                        es.EmailTxt__c = mySelectedcon.Email;
                        es.cTin_SupplierAccount__c = mySelectedcon.AccountId;
                        es.EntityName__c=mySelectedcon.AccountId;
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
                            es.EmailTxt__c = mySelectedcon.Email;
                            es.MobileTxt__c = '';
                            es.cTin_SupplierAccount__c = mySelectedcon.AccountId;
                            es.EntityName__c = mySelectedcon.AccountId;  
                            esignToUpsertList.add(es);
                        }
                        System.debug('### added signatory :' + es) ;
                       /* try{
                            upsert es ; 
                          }Catch(Exception e){}  */
                    }
                }
                
                if(esignToUpsertList.size()>0)
                    upsert esignToUpsertList;  
            }
            else{
                
                List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
                
                List<eSignatory__c> listofSignToRefresh = new  List<eSignatory__c>() ; 
                
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
                        es.cTin_SupplierAccount__c = mySelectedcon.AccountID;
                        es.EntityName__c=mySelectedcon.AccountId;
                        listofSignToRefresh.add(es);
                        
                        System.Debug('### le signataire : ' + es) ;  
                        
                    }
                    if(listofSignToRefresh.size()>0)
                        upsert listofSignToRefresh;
                } 
                
                eSignatoryList = [Select Id, RecordTypeId, cTin_OriginalRepresentative__c ,
                                  contract__r.Id, contract__r.cTin_SupplierAccount__c, Contact__r.cTin_RelatedUser__c, 
                                  Contact__c, Contact__r.Name, FirstName__c, LastName__c, cTin_Role__c,Name, Contract__c, 
                                  MobileTxt__c, EmailTxt__c, Code__c, Order__c ,cTin_ParenteSignatory__c, SuccessURL__c, 
                                  FailURL__c, CancelURL__c, cTin_SupplierAccount__c,contact__r.AccountId,entityName__c
                                  FROM eSignatory__c 
                                  WHERE eSignature__c=:eSignature.Id and  Order__c != null
                                  order by Order__c asc];
                
                System.Debug('#### eSignatoryList from sql:' + eSignatoryList.size()) ; 
                
                
                if(!empty(eSignatoryList)){
                    //create list without observers        
                    for(eSignatory__c eAll : eSignatoryList){
                       /* if(eAll.RecordTypeId!=System.Label.cTin_RTNegotiatorSignatory){
                            listWithoutObserver.add(eAll);
                        }*/

                        if(eAll.RecordTypeId!=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleNegotiator).getRecordTypeId()){
                           listWithoutObserver.add(eAll);
                        }
                    }        
                    if(listWithoutObserver.size()>0){
                        numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
                        Integer  tailleList = listWithoutObserver.size()-1;                 
                        numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
                    }              
                }  
                return null;  
            }
            return null;
        }
        catch(Exception e){
            return null;
        }              
    }
    //Méthode pour rafraichir le phone aprs changement de la valeur du code
    public PageReference ref(){
        MY_ERR_MSG=null;
        List<eSignatory__c> ListToRefresh = new List<eSignatory__c>() ; 
        
        if(eSignatoryList.size() >0){   
            for(eSignatory__c signat : eSignatoryList ){
                if(signat.code__c != 'sms' ||  (signat.code__c =='sms' 
                   && (signat.MobileTxt__c!='' || signat.MobileTxt__c!= null )) ){
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
    }
    
    //reworked : mra 29-OCT-2017
    public PageReference refreshPhone(){
        add = false;
        List<eSignatory__c> listofSignToRefresh = new  List<eSignatory__c>() ; 
        List<eSignatory__c> eSignatoryListSql = new  List<eSignatory__c>() ; 
        List<eSignatory__c> listWithoutObserver = new List<eSignatory__c>();
        list<Contact>contactLst=new list<Contact>();
        
        contact_Id = ApexPages.currentPage().getParameters().get('contact_Id');
        
        if(contact_Id !=null){
            try{
                
                list<esignatory__c>esignatory=[select contact__c,contact__r.AccountId,entityName__c 
                                               from esignatory__c 
                                               where contact__c=:contact_Id];
                
                mySelectedcon = [Select Id, RecordTypeId, FirstName, LastName, MobilePhone, Email, 
                                 Account.Name, AccountID 
                                 from Contact 
                                 where  id=: contact_Id] ; 
            }catch(Exception e){ } 
        }
        //End
        for(eSignatory__c es : eSignatoryList){
            if(mySelectedcon != null) { 
                
                if(es.contact__c != null && mySelectedcon.ID != null){
                    if (mySelectedcon.ID == es.contact__c){                        
                        if(es.MobileTxt__c !=null){
                            Contact c = new Contact(); 
                            c = [Select Id, FirstName, LastName,AccountId, MobilePhone, Email, Account.Name, Name 
                                 from contact 
                                 Where Id=:es.Contact__c];
                            
                            if(c.FirstName != null) es.FirstName__c = c.FirstName;
                            if(c.LastName != null)es.LastName__c = c.LastName;
                            if(c.FirstName==null && c.LastName !=null){
                                es.Name =c.LastName ; 
                            }else if(c.LastName==null && c.FirstName!=null){
                                es.Name = c.FirstName; 
                            }else if (c.FirstName!=null & c.LastName !=null){
                                es.Name = c.FirstName + ' ' + c.LastName ; 
                            }
                            //append + to mobile number when upserting contact else VR will trigger
                            c.MobilePhone=(es.MobileTxt__c.startsWith('+')? es.MobileTxt__c: '+' + es.MobileTxt__c);           
                            es.MobileTxt__c = es.MobileTxt__c ; 
                            es.EmailTxt__c = c.Email;
                            es.cTin_SupplierAccount__c = c.AccountId;
                            es.EntityName__c=c.AccountId;
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
            try{
                upsert contactLst;
            }
            catch(Exception e){
                //to be implemented
            }
            
        }
        
        if(!empty(eSignatoryList)){
            for(eSignatory__c eAll : eSignatoryList){         
                listWithoutObserver.add(eAll);         
            }
            numeroOrdreDebut=Integer.valueOf(listWithoutObserver.get(0).Order__c);
            Integer  tailleList = listWithoutObserver.size()-1;
            numeroOrdreFin =Integer.valueOf(listWithoutObserver.get(tailleList).Order__c);
            
        }  
        try{ 
            eSignatoryList=  [Select Id, cTin_OriginalRepresentative__c ,contract__r.cTin_SupplierAccount__c, 
                              Contact__r.cTin_RelatedUser__c, Contact__c, FirstName__c, LastName__c,contact__r.AccountId, 
                              cTin_Role__c,Name,Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c,entityName__c, 
                              cTin_ParenteSignatory__c,SuccessURL__c, FailURL__c, CancelURL__c,cTin_SupplierAccount__c
                              FROM eSignatory__c 
                              WHERE eSignature__c=:eSignatureId and  Order__c != null
                              order by Order__c asc]; 
        } 
        catch(Exception e){}   
        
        return null ;
    }

    public pageReference reset(){
        string ssesignId = ApexPages.currentPage().getParameters().get('eSignatureId');
        contractId = ApexPages.currentPage().getParameters().get('contractId');
        if(contractId != null) return new pageReference('/'+ contractId ) ; 
        if(ssesignId != null) return new pageReference('/'+ ssesignId ) ; 
        return null ; 
    }
    
    public PageReference submit(){
       countClicks=countClicks+1;
        system.debug('###Count number of clicks'+ countClicks);

        List<eSignatory__c> listSignataire = new List<eSignatory__c>() ;
       
    
        eSignatoryList = [Select Id, cTin_OriginalRepresentative__c , Contact__r.Name, contact__r.mobilePhone,
                          Contact__r.cTin_RelatedUser__c, Contact__c, FirstName__c, LastName__c, 
                          cTin_Role__c,cTin_Role_Universign__c,Name, Contract__c, MobileTxt__c, 
                          EmailTxt__c, Code__c, Order__c,contact__r.AccountId,
                          cTin_ParenteSignatory__c, SuccessURL__c, FailURL__c, TECH_ContractEntityCode__c,
                          CancelURL__c, OrderToSend__c, cTin_Profile__c, x__c, y__c,entityName__c,esignature__r.cTin_TECH_IsContractIn__c,
                          cTin_SupplierAccount__c FROM eSignatory__c 
                          WHERE eSignature__c=:eSignatureId and  Order__c != null
                          order by OrderToSend__c asc];    
        
        /*list<esignature__C> esignature=[select id,cTin_finalDocumentURLToSign__c  
                                        from esignature__c
                                        where id=:eSignatureId ];*/
        
        
        List<ContentDistribution> cdistList = [SELECT Name, RelatedRecordId, ContentDocumentId, DistributionPublicUrl, ContentVersionId 
                                               FROM ContentDistribution 
                                               WHERE RelatedRecordId=:eSignatureId order by createdDate ASC];
        
        System.debug('##### submit eSignatoryList'+eSignatoryList);
        
        eSignature__c eSignatureForCollecte = [Select Id,cTin_TECH_ContentIdToSign__c, Language__c ,cTin_TECH_IsContractIn__c,
                                               Error_Message__c, Name, Status__c, CreatedDate, Contract__r.Name, 
                                               CreatedById, cTin_ShortDescription__c, FinalDocumentURL__c, cTin_KeyPoints__c, 
                                               cTin_TotalSpendExcVAT2__c, cTin_StartDate__c,cTin_finalDocumentURLToSign__c,
                                               cTin_AXAMainLegalSignatoryEntity__c, cTin_SupplierLegalSignatoryEntity__c, 
                                               cTin_AXAMainSignatoryRepresentative__c, cTin_SupplierSignatoryRepresentative__c, 
                                               HandWrittenSignatureMode__c,contract__r.cTin_OwnerEntity__c
                                               from eSignature__c WHERE id=:eSignatureId];
        
        try{
            AP22_XmlRpcWrapper.CreateXmlRpc(eSignatureForCollecte, eSignatoryList, cdistList);
        }Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
        }   
        Map<ID,List<eSignatory__c>> MapSignatoWchids = new Map<ID,List<eSignatory__c>>() ; 
        List<eSignatory__c> ListSigner = new List<eSignatory__c>() ;
        Integer combiendeSigner = 0 ;
        List<eSignatory__c> ListObserverToUpdate = new List<eSignatory__c>() ; 
        
        if(eSignatureForCollecte.Error_Message__c =='' && eSignatureForCollecte.id !=null ){
            for(eSignatory__c esig: eSignatoryList){
                if(esig.cTin_ParenteSignatory__c !=null  &&  !MapSignatoWchids.containskey(esig.cTin_ParenteSignatory__c)){
                    MapSignatoWchids.put(esig.cTin_ParenteSignatory__c , new List<eSignatory__c>()) ; 
                }
                if(esig.cTin_ParenteSignatory__c != null) MapSignatoWchids.get(esig.cTin_ParenteSignatory__c).Add(esig) ; 
                
                if( esig.cTin_Role_Universign__c == AP_Constant.esignRoleUniversignSigner && combiendeSigner<2){
                    ListSigner.add(esig) ;  combiendeSigner = combiendeSigner ++ ; 
                    
                }   
            }
        } 
        
        for(integer i=0 ; i<ListSigner.size(); i++){
            if(i==0) {
                if(MapSignatoWchids.get(ListSigner.get(i).ID) != null) {
                    for(eSignatory__c esig : MapSignatoWchids.get(ListSigner.get(i).ID) ) {
                        esig.status__c = AP_Constant.esignatoryStatusReady; 
                        ListObserverToUpdate.add(esig) ; 
                    }    
                }    
                ListSigner.get(i).status__c = AP_Constant.esignatoryStatusReady ; 
                
            } else if(  i==1) {
                if(MapSignatoWchids.get(ListSigner.get(i).ID) != null) {
                    for(eSignatory__c esig : MapSignatoWchids.get(ListSigner.get(i).ID) ){
                        esig.status__c = AP_Constant.esignatoryStatusAwaiting;
                        ListObserverToUpdate.add(esig) ;  
                    }    
                }    
                ListSigner.get(i).status__c = AP_Constant.esignatoryStatusAwaiting; 
            }
        }
        
        
        update ListSigner ; 
        update ListObserverToUpdate ;   
        
        eSignatureForCollecte.Status__c=AP_Constant.eSignatureSentStatus;
        eSignatureForCollecte.collecteDone__c=true;
        /*RecordType inSignatureRT = [SELECT Id, DeveloperName 
                                    FROM RecordType 
                                    Where DeveloperName='cTin_IneSignature' AND SobjectType='eSignature__c'];
        eSignatureForCollecte.RecordTypeId = inSignatureRT.Id;*/
        eSignatureForCollecte.RecordTypeId=Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_InEsignature').getRecordTypeId(); 
        
        if(listSignataire.size()>0){
            update listSignataire ; 
        }
        
        update eSignatureForCollecte;
    
       
        return new PageReference('/'+eSignatureId); 
        
    }
    
    // MRA 24-NOV-2015
    //Case 1130 (Enhancement) -> add relauch 
    public pagereference relaunch(){
        system.debug('## Starting method relauch');
        
        //get the signatory id
        system.debug('##eSignatureId'+eSingId);
        system.debug('##eSignatoryId'+eSignatoryId);
        
        //query the esignature to retrieve the transaction id         
       // list<esignature__c> esignatureList=[select transactionId__c,Contract__c,Language__c, id,CreatedById,HandWrittenSignatureMode__c,contract__r.cTin_OwnerEntity__c from esignature__c where id=:eSingId];
        
        list<eSignatory__c> esignatoryList = [Select Id, Contact__r.Name, RecordTypeId,cTin_OriginalRepresentative__c ,contract__r.Id, contract__r.cTin_SupplierAccount__c, 
                                              Contact__r.cTin_RelatedUser__c, FirstName__c, LastName__c, cTin_Role__c,Name, 
                                              Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c,OrderToSend__c,
                                              Contact__c, cTin_ParenteSignatory__c, SuccessURL__c,x__c,y__c,contact__r.AccountId,
                                              FailURL__c, CancelURL__c, cTin_SupplierAccount__c,cTin_Profile__c,cTin_Role_Universign__c,
                                              LastRelaunchDate__c,RelaunchCount__c,RelaunchErrorMessage__c,entityName__c,
                                              esignature__r.transactionId__c,esignature__r.Contract__c,esignature__r.Language__c, 
                                              esignature__c,esignature__r.CreatedById,esignature__r.HandWrittenSignatureMode__c
                                              FROM eSignatory__c 
                                              WHERE id=:eSignatoryId];
        
        
        if(esignatoryList.size()>0){
            string transactionId=esignatoryList[0].esignature__r.transactionId__c;           
            integer relaunchCount;
            
            if(integer.valueOf(esignatoryList[0].RelaunchCount__c)==null)
                relaunchCount=0;
            else
                relaunchCount=integer.valueOf(esignatoryList[0].RelaunchCount__c);
            
            eSignature__c eSignatureForCollecte=new esignature__c();
            eSignatureForCollecte.id=esignatoryList[0].esignature__c;
            
            system.debug('##transactionId'+transactionId); 
            system.debug('##contractnId'+contractid); 
            
            if(transactionId!=null || transactionId!='' ) {        
                //call webservice to relaunch transaction -> requester.relaunchTransaction(transactionId); 
                try{
                    AP22_XmlRpcWrapper.CreateXmlRpcForRelaunch(eSignatureForCollecte,transactionId, eSignatoryList,relaunchCount);
                }
                Catch(Exception e){
                    system.debug('##catch');
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
                }   
                
            }
            
            return new PageReference('/'+eSingId); 
        }
        
        system.debug('## Ending method relauch');
        return null;
    }
    
    //MRA 03 DEC 2015 (Case 1211 -Enhancement)
    public pagereference cancel(){
        system.debug('## Starting method eSignature cancel');
        
        //get the signatory id
        system.debug('##eSignatureId'+eSingId);
        
        //query the esignature to retrieve the transaction id         
        /*list<esignature__c> esignatureList=[select transactionId__c,Contract__c,Language__c, id,
                                            CreatedById,HandWrittenSignatureMode__c 
                                            from esignature__c where id=:eSingId];*/
        
        list<eSignatory__c> eSignLst = [Select Id, status__c,cTin_SupplierAccount__c,
                                        contact__r.AccountId,entityName__c,
                                        esignature__r.transactionId__c,esignature__r.Contract__c,
                                        esignature__r.Language__c, esignature__c,
                                        esignature__r.CreatedById,esignature__r.HandWrittenSignatureMode__c 
                                        from eSignatory__c             
                                        where eSignature__c =: eSingId];
        
        if(eSignLst.size()>0){
            string transactionId=eSignLst[0].esignature__r.transactionId__c;
            
            eSignature__c eSignatureForCollecte=new esignature__c();
            eSignatureForCollecte.id=eSingId;
            
           
            if(transactionId!=null || transactionId!='' ) {        
                //call webservice to relaunch transaction -> requester.relaunchTransaction(transactionId); 
                try{
                    AP22_XmlRpcWrapper.CreateXmlRpcForCancel(eSignatureForCollecte,transactionId,eSignLst);
                }
                Catch(Exception e){
                    system.debug('##catch: '+e.getMessage());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) ) ; 
                }   
                
            }
            
            return new PageReference('/'+eSingId); 
        }
        
        system.debug('## Ending method eSignature cancel');
        return null;        
    }
}