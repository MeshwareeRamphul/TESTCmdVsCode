public without sharing class LC16_CreateSignature {
/*
----------------------------------------------------------------------
-- - Name          : LC16_CreateSignature
-- - Author        : MRA
-- - Description   : Controller for lighning component LC16_CreateSignature
--                   @for creating eSignatures (applicable for cTin only)
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 11-DEC-2019   MRA   1.0      Initial version 
-- 05-JUN-2020   ARA   1.1      Case 0279: Default language on the signature
-- 06-APR-2022   AMA   1.2      SP-03122: set esignature's currency
-- 31-AUG-2022   MRA   1.3      Set language parameter to FR for AVANSSUR
-- 07-OCT-2022   ARA   1.4      Universign v2 - Add coordinate and EsignatoryType

--------------------------------------------------------------------------- */

  //methods checks if creation of eSignature should be blocked or allowed
  @AuraEnabled
  public static map<string,object> validateCreateSign(String contractId){
    map<String,Object> mapOfResult = new map<String,Object>();
    list<User> currentUser = [SELECT ID, cTin_UniversignProfile__c, cTin_Universign__c,cTin_EntityLocalCode__c 
                              FROM User 
                              WHERE id =:UserInfo.getUserID()] ; 
    list<Contract__c> contract = [SELECT Id, ownerID, Name,FinalDocumentURL__c, cTin_SupplierAccount__c,
                                  cTin_OwnerEntityLocalCode__c,cTin_AXASignatoryRepresentative__c, cTin_OwnerEntity__c ,
                                  cTin_SupplierSignatoryRepresentative__c,Status__c,cTin_UnilateralSupplier__c,
                                  cTin_UnilateralAXARepresentative__c,CurrencyIsoCode
                                  FROM Contract__c 
                                  WHERE Id=:contractId];
      
      //Rule 1: block if contract status is not "In signature"
      if(contract[0].Status__c==AP_Constant.contractInSignatureStatus){
          system.debug('##if status==in signature');
          
          set<id> ALLCDLIds = new set<id>();
          set<id> CDLIdToBeSigned = new set<id>();
          for(ContentDocumentLink cdl : [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:contractId]){
              ALLCDLIds.add(cdl.ContentDocumentId);
          }
          
          for(ContentVersion  cv : [SELECT ContentDocumentId, title FROM ContentVersion WHERE (ContentDocumentId in :ALLCDLIds AND FileType ='PDF' AND Sign_able__c = true)]){
              if (cv.title.length() <=89){
                  CDLIdToBeSigned.add(cv.ContentDocumentId);
              }
          }
          
          list<ContentDocumentLink> lstcdLink = new list<ContentDocumentLink>();
          
          for(id signCdlID : CDLIdToBeSigned ){
            lstcdLink.add([SELECT ContentDocumentId,shareType,ContentDocument.title, ContentDocument.FileType,Id,LinkedEntityId 
                           FROM ContentDocumentLink
                           WHERE ContentDocumentId = :signCdlID limit 1]);
          }
          
          //Rule 2: Block if no doc is uploaded on contract or all uploaded docs are not PDF                                     
          if(lstcdLink.size()>0){
            for(ContentDocumentLink cdlink: lstcdLink){                   
              if (cdlink.ContentDocument.FileType != 'PDF' || cdlink.ContentDocument.title.length() >89){
                if(cdlink.ContentDocument.FileType != 'PDF'){
                  mapOfResult.put('error',system.label.LC16_ErrorDocumentType) ; 
                }
                if(cdlink.ContentDocument.title.length() >89 ) {
                  mapOfResult.put('error', system.label.LC16_ErrorDocumentLength);                       
                }
              }
            }
            system.debug('##if has document');
          }
          else{
              mapOfResult.put('error',system.label.ErrorMessageEsignNoDocs);
              system.debug('##else no document');
          }
          //Rule 3 : Block  if entity of current user!= entity of ctr owner + cTin_UniversignProfile__c is false 
          
          if(!mapOfResult.containsKey('error')){
              system.debug('## no error so far, 2nd if');
            if(contract[0].cTin_OwnerEntityLocalCode__c  ==currentUser[0].cTin_EntityLocalCode__c 
                && currentUser[0].cTin_Universign__c == true ) {
                    system.debug('##if check on entity'+contract[0].cTin_OwnerEntityLocalCode__c + ' == '+ currentUser[0].cTin_EntityLocalCode__c + ' is universign checked ' + currentUser[0].cTin_Universign__c);
                  //Rule 4: block if bilateral but either supplier rep or AXA rep is not specified
                if(!contract[0].cTin_UnilateralSupplier__c &&  !contract[0].cTin_UnilateralAXARepresentative__c
                    && (contract[0].cTin_SupplierSignatoryRepresentative__c==null || contract[0].cTin_AXASignatoryRepresentative__c==null)){
                    mapOfResult.put('error',system.label.LC16_ErrorBilateralSignatories);                    
                }
                else{
                    //Allow creation                   
                  mapOfResult=createSign(contract[0],lstcdLink);
                }
            }
            else{
                  system.debug('##else check on entity failed');
                  system.debug('##if check on entity'+contract[0].cTin_OwnerEntityLocalCode__c + ' == '+ currentUser[0].cTin_EntityLocalCode__c + ' is universign checked ' + currentUser[0].cTin_Universign__c);
  
                  mapOfResult.put('error',system.label.LC16_ErrorCurrentUser);
              } 
          }
      }
      else{
          system.debug('##last else');
          mapOfResult.put('error',system.label.cTin_ErrorMessageBlckCreation);
      }
      
      return mapOfResult;
    }

  //method creates eSignature (for unilateral and bilateral scenario)
  @AuraEnabled
  public static map<string,object> createSign(Contract__c ctr,list<ContentDocumentLink>lstcdLink){
      map<String,Object> mapOfResult = new map<String,Object>();
      string draftRtId=Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
      string signatoryAXART=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleAxaRep).getRecordTypeId();
      string signatorySupplierRT=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(system.label.cTin_RoleSupplierRep).getRecordTypeId();
      boolean doNotContinue=false;
      list<contact> contactSupplier=new list<contact>();
      list<contact> contactAXA=new list<contact>();
      string emailAXA,emailsupplier;
      list<esignatory__c> lstesignatory=new list<esignatory__c>();
      esignatory__c esignatorySupplier,esignatoryAXA;
      list<ContentDocumentLink> cdLinkSign=new list<ContentDocumentLink>();
      string language='English';
      
      for(contact con: [Select Id,cTin_Active__c, Name, FirstName, LastName, MobilePhone, Email, Account.Name, recordtype.name
                        from Contact 
                        WHERE Id = :ctr.cTin_SupplierSignatoryRepresentative__c 
                        or Id=:ctr.cTin_AXASignatoryRepresentative__c]){
          if(con.recordtype.name=='AXA'){
              contactAXA.add(con);
          }
          if(con.recordtype.name=='Supplier'){
            contactSupplier.add(con);
          }
      }

      if(contactAXA.size()>0 && contactAXA[0].email!=null)
        emailAXA=contactAXA[0].email;

      if(contactSupplier.size()>0 && contactSupplier[0].email!=null)
        emailSupplier=contactSupplier[0].email;

      //bilateral - creating axa and supplier signatories 
      if(!ctr.cTin_UnilateralAXARepresentative__c  && !ctr.cTin_UnilateralSupplier__c && (emailAXA == emailSupplier)){
          system.debug('##emailAXA'+emailAXA );
            system.debug('##emailSupplier'+emailSupplier );
          mapOfResult.put('error', system.label.LC16_ErrorSameContactEmail);
          doNotContinue=true;
      }
      
      if(!doNotContinue){
          //query contractForm
          Id contractFormId = [Select Id, cTin_Contract__c 
                              from cTin_ContractForm__c 
                              WHERE cTin_Contract__c=:ctr.id 
                              order by createdDate asc limit 1].id;
          
            if(ctr.cTin_OwnerEntity__c != null){
              if(ctr.cTin_OwnerEntity__c == '700 - AXA France' || ctr.cTin_OwnerEntity__c == '710 - AXA France Assurances' || ctr.cTin_OwnerEntity__c == '750 - Avanssur'){
                  language = 'French';
              }else if(ctr.cTin_OwnerEntity__c == '1230 - AXA Spain'){
                  language = 'Spanish';
              }else if(ctr.cTin_OwnerEntity__c == '1320 - AXA Switzerland'){
                  language = 'English';
              }
          }
          
          eSignature__c eSignature = new eSignature__c(Name = ctr.Name,
                                        Contract__c = ctr.Id,
                                        CurrencyIsoCode = ctr.CurrencyIsoCode,
                                        Status__c = AP_Constant.eSignatureCreatedStatus,
                                        language__c=language,                                     
                                        RecordTypeId=draftRtId,
                                        cTin_ContractForm__c=contractFormId);

          //creating supplier signatory
          if(contactSupplier.size()>0){
              esignatorySupplier = new esignatory__c(
                            cTin_OriginalRepresentative__c= true ,
                            cTin_SupplierAccount__c=ctr.cTin_SupplierAccount__c,
                            entityName__c=ctr.cTin_SupplierAccount__c,
                            Contract__c = ctr.Id,
                            Contact__c = contactSupplier[0].Id,
                            FirstName__c = contactSupplier[0].FirstName,
                            LastName__c= contactSupplier[0].LastName,
                            Name = contactSupplier[0].FirstName + contactSupplier[0].LastName,
                            MobileTxt__c = contactSupplier[0].MobilePhone,
                            EmailTxt__c = contactSupplier[0].Email,
                            OrderCreation__c = 1,
                            Order__c = 1,
                            OrderCachet__c=1,
                            OrderToSend__c=0,
                            cTin_OrderToSetCoordinates__c=0,
                            x__c = 100,
                            y__c = 55,
                            TECH_defaultSignatory__c=true, // helps identify if signatories were created automatically or manually
                            Code__c = ( contactSupplier[0].MobilePhone==null ? 'email':'sms'),
                            recordtypeId =signatorySupplierRT,
                            cTin_role__c =system.label.cTin_RoleSupplierRep,
                            EsignatoryType__c = 'Customer');    
          }
          
          //creating AXA signatory
          if(contactAXA.size()>0){
            esignatoryAXA = new esignatory__c(eSignature__c = eSignature.Id,
                            cTin_OriginalRepresentative__c= true ,
                            cTin_SupplierAccount__c=contactAxa[0].AccountId,
                            entityName__c=contactAxa[0].AccountId,
                            Contract__c = ctr.Id,
                            Contact__c = contactAxa[0].Id,
                            FirstName__c = contactAxa[0].FirstName,
                            LastName__c= contactAxa[0].LastName,
                            Name = contactAxa[0].FirstName + contactAxa[0].LastName,
                            MobileTxt__c = contactAxa[0].MobilePhone,
                            EmailTxt__c = contactAxa[0].Email,                             
                            Code__c = ( contactAxa[0].MobilePhone==null ? 'email':'sms'),
                            TECH_defaultSignatory__c=true, // helps identify if signatories were created automatically or manually
                            recordtypeId =signatoryAXART,
                            cTin_role__c =system.label.cTin_RoleAxaRep,
                            EsignatoryType__c = 'AXA'
                            /*,OrderCreation__c = 2,
                            Order__c = 2,
                            OrderCachet__c=2,
                            OrderToSend__c=1*/);                                              
          }
    
          try{
            insert eSignature;
            mapOfResult.put('esignId',eSignature.Id);
              //bilateral - creating axa and supplier signatories 
            if(!ctr.cTin_UnilateralAXARepresentative__c  && !ctr.cTin_UnilateralSupplier__c){
                esignatorySupplier.eSignature__c = eSignature.Id;                  
                esignatoryAXA.eSignature__c = eSignature.Id;                 
                esignatoryAXA.OrderCreation__c = 2;
                esignatoryAXA.Order__c = 2;
                esignatoryAXA.OrderCachet__c = 2;
                esignatoryAXA.OrderToSend__c = 1;
                esignatoryAXA.cTin_OrderToSetCoordinates__c = 1;
                esignatoryAXA.x__c = 390;
                esignatoryAXA.y__c = 55 ;
                lstesignatory.add(esignatoryAXA); 
                lstesignatory.add(esignatorySupplier);
            }
            if(ctr.cTin_UnilateralAXARepresentative__c){
                esignatoryAXA.OrderCreation__c = 1;
                esignatoryAXA.Order__c = 1;
                esignatoryAXA.OrderCachet__c = 1;
                esignatoryAXA.OrderToSend__c = 0;
                esignatoryAXA.cTin_OrderToSetCoordinates__c = 0;
                esignatoryAXA.eSignature__c = eSignature.Id;
                esignatoryAXA.x__c = 100;
                esignatoryAXA.y__c = 55 ;
                lstesignatory.add(esignatoryAXA);
            }
            if(ctr.cTin_UnilateralSupplier__c){
                esignatorySupplier.OrderCreation__c = 1;
                esignatorySupplier.Order__c = 1;
                esignatorySupplier.OrderCachet__c = 1;
                esignatorySupplier.OrderToSend__c = 0;
                esignatorySupplier.cTin_OrderToSetCoordinates__c = 0;
                esignatorySupplier.eSignature__c = eSignature.Id;
                esignatorySupplier.x__c = 100;
                esignatorySupplier.y__c = 55 ;
                lstesignatory.add(esignatorySupplier);
            }
      
            if(lstesignatory.size()>0){
              try{
                
                system.debug('## lstesignatory before insert:'+lstesignatory);
                insert lstesignatory;
                for(ContentDocumentLink cdLink: lstcdLink){
                  ContentDocumentLink cd=new ContentDocumentLink(LinkedEntityId=eSignature.Id,
                  ContentDocumentId= cdLink.ContentDocumentId,
                  shareType='V',
                  Visibility = 'AllUsers');
                  //shareType=cdLink.shareType);
                  
                  cdLinkSign.add(cd);

                }
                try{
                  insert cdLinkSign;                   
                  }
                catch(Exception e){mapOfResult.put('error', e.getMessage());}
              }
              catch(Exception e){
                mapOfResult.put('error', e.getMessage());
              }
            }
          }
          catch(Exception e){
            mapOfResult.put('error', e.getMessage());
          }
      }
      return mapOfResult;
  }   
}