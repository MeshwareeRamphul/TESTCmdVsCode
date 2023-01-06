public without sharing class LC36_ManageEsignature {
/*
----------------------------------------------------------------------
-- - Name          : LC36_ManageEsignature
-- - Author        : MRA
-- - Description   : Controller for lighning component LC36_ManageEsignature
--                  
--
-- Maintenance History:
--
-- Date          Name   Version   Remarks
-- -----------   ----   -------   ---------------------------------------
-- 07-JAN-2020  MRA    1.0      Initial version 
                                (implements submit esignature,Edit Esignature, Sign Approved contract)

-- 30-JUN-2022  ARA    1.1      SP-01893    Upgrade - Migrate Edit eSignature screen to LWC
--------------------------------------------------------------------------- */
     
    //method calls AP22_XMLWrapper to submit esignature via xml request (button submit)
    @AuraEnabled
    public static map<string,object> submitEsignature(string esignId){
        system.debug('### starting submitEsignature');
        map<string,object> result=new map<string,object>();
        result.put('esignatureId',esignId);
        eSignature__c eSignature = [SELECT Id,cTin_TECH_ContentIdToSign__c, Language__c ,cTin_TECH_IsContractIn__c,Error_Message__c, Name, Status__c, CreatedDate,
                                    Contract__c, Contract__r.Name, Contract__r.Customer_Operational_Contact__c, Contract__r.Customer_Operational_Contact__r.Email,
                                    CreatedById, cTin_ShortDescription__c, FinalDocumentURL__c, cTin_KeyPoints__c, cTin_TotalSpendExcVAT2__c, cTin_StartDate__c,
                                    cTin_finalDocumentURLToSign__c, cTin_AXAMainLegalSignatoryEntity__c, cTin_SupplierLegalSignatoryEntity__c, cTin_AXAMainSignatoryRepresentative__c, 
                                    cTin_SupplierSignatoryRepresentative__c, HandWrittenSignatureMode__c,contract__r.cTin_OwnerEntity__c, TransactionID__c,TECH_AutomatedEsign__c, RecordTypeId 
                                    FROM eSignature__c
                                    WHERE Id =:esignId];
        //display error if submit is not allowed
        if(eSignature.Status__c=='Sent' && eSignature.TransactionID__c!=null){
            result.put('error',system.label.EsignatureSubmitError);
        }
        //submit eSignature
        else {  
            //1. get list of esignatories 
             list<esignatory__c> listEsignatory = [SELECT Id, cTin_Profile__c,cTin_Role_Universign__c, Contact__r.Name,Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, 
                                                    EmailTxt__c, Code__c, Order__c,EntityName__c, Name__c, cTin_Role__c,contact__r.FirstName,contact__r.lastName,cTin_signLink__c,signURL__c,
                                                    EsignatoryType__c,SuccessURL__c, FailURL__c, CancelURL__c, OrderToSend__c, x__c, y__c,contact__r.mobilephone,contact__r.Tech_recordtype__c,
                                                    esignature__r.cTin_TECH_IsContractIn__c, Tech_OriginalSignatory__c,TECH_ContractEntityCode__c,TECH_defaultSignatory__c,TECH_SignerRole__c 
                                                    FROM eSignatory__c
                                                    WHERE eSignature__c=:eSignature.Id AND Order__c != null
                                                    ORDER BY Order__c ASC]; 

            //2. get content distribution list (trigger to be implemented for inserting a cd when file is uploaded in LEX)
            List<ContentDistribution> lstCDist = [SELECT Name, RelatedRecordId, ContentDocumentId, DistributionPublicUrl, ContentVersionId, PdfDownloadUrl 
                                                FROM ContentDistribution 
                                                WHERE RelatedRecordId= :eSignature.Id order by createdDate ASC];
            try{
                result = WS07_UniversignTransaction.createTransactionFull(esignature,listEsignatory,lstCDist);
                System.debug('## LC50_ManageEsignature result: '+ result);
                if(!result.containsKey('error')){
                    result.put('contractId', eSignature.Contract__c);
                    result.put('success', Label.EsignatureSubmitSuccess);
                }
            }catch(Exception e){
                result.put('error','An error occurred during the submission of the esignature : "'+eSignature.Error_Message__c+'"');
            }
        }
        return result;
    }
    
    // method retrieves esignatories related to esignature (executed when cmp loads)
    @AuraEnabled
    public static map<string,object> buildSignatorylst(string esignId){
        map<string,object>result=new map<string,object>();
        List<esignatory__c> lstEsignatory = new List<esignatory__c>();
        
        List<esignatory__c> currEsignatory = new List<esignatory__c>();
        currEsignatory = [SELECT Id,Name, contact__r.tech_recordtype__c,eSignature__c, cTin_Role_Universign__c,FirstName__c, LastName__c, signURL__c, status__c,EmailTxt__c
                         FROM eSignatory__c 
                         WHERE eSignature__c = :esignId
                         AND status__c = :AP_Constant.esignatoryStatusReady LIMIT 1];
        
        string currentUserEmail=userinfo.getUserEmail();
        string currentUserprofileId=userinfo.getProfileId();
        
        boolean blockSignApprove=false;
        
        if(currEsignatory.size()>0){
            if(currentUserEmail!=currEsignatory[0].EmailTxt__c 
               /*&& currentUserprofileId!=AP_Constant.getProfileIdAdmin()*/){
                blockSignApprove=true;
            }
        }
       
        lstEsignatory= [SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,
                        OrderCachet__c,orderToSend__c,Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c,contact__r.tech_recordtype__c 
                        FROM esignatory__c 
                        WHERE eSignature__c = :esignId
                        ORDER BY Order__c ASC];
        result.put('lst',lstEsignatory);
        if(lstEsignatory[0].esignature__r.status__c=='Cancelled' || lstEsignatory[0].esignature__r.status__c=='Sent' || lstEsignatory[0].esignature__r.status__c=='Completed'){
            result.put('disablebtn',true);
        }
        if(lstEsignatory[0].esignature__r.status__c=='Cancelled' || lstEsignatory[0].esignature__r.status__c=='Completed' || lstEsignatory[0].esignature__r.status__c=='Created'  || (blockSignApprove) ){
            result.put('disableSignbtn',true);
        }

        return result;
    }
    
    //method implements logic to delete esignatory (button Edit eSignature - delete Icon)
    @AuraEnabled
    public static list<esignatory__c> deleteSignatory(string signatoryId,string esignId,integer ordertbd){
        List<esignatory__c> lstEsignatory = new List<esignatory__c>();
        if(signatoryId != '' && signatoryId != null){
            esignatory__c delEsign = new esignatory__c(id = signatoryId);
            delete delEsign;
        }
        
        //get order of deleted signatory (if ==3; get all signatroies where order > 3 => new order == (3-1))
        for(esignatory__c es: [ SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c,contact__r.tech_recordtype__c, EntityName__r.Name,
                                EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c,OrderCachet__c,OrderCreation__c
                                FROM esignatory__c 
                                WHERE eSignature__c = :esignId 
                                AND Order__c > :integer.valueOf(ordertbd)]){                                
            es.Order__c=es.Order__c-1;es.OrderCreation__c=es.OrderCreation__c-1;es.OrderCachet__c=es.OrderCachet__c-1;es.orderToSend__c=es.orderToSend__c-1;                                       
            lstEsignatory.add(es);                       
        }
        
        if(lstEsignatory.size()>0) update lstEsignatory;
        
        list<esignatory__c>lstresfreshed = [SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c,contact__r.tech_recordtype__c, 
                                            EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,orderToSend__c 
                                            FROM esignatory__c 
                                            WHERE eSignature__c= :esignId
                                            ORDER BY Order__c ASC];
        
        return lstresfreshed;
    }
    
    //method retrieves esignatory codes for populating picklist in cmp
    @AuraEnabled 
    public static Map<String, String> getCodes(){
        Map<String, String> options = new Map<String, String>(); 
        Schema.DescribeFieldResult fieldResult = eSignatory__c.code__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {        
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    
    //methods refreshes esignatory list and displays error message if invalid changes w.r.t contact and entity are made
    @auraEnabled
    public static list<esignatory__c >refreshSignatoryLst(string eSignatureId,boolean contactType, string esignatoryId, string recordId,string recordName,string objectType,
                                                         string code, string mobilephone, integer esignOrder){             
         eSignatory__c newEsign;                        
         string rtAXA=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();
         string rtSupplier=Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();
         list<Contact> con=[select accountId,Id,account.name,email,MobilePhone from contact where id =:recordId];
         
         id contract=[select contract__c from eSignature__c where id=:eSignatureId].contract__c;
                                                  
         list<esignatory__c> currentSignatory=[SELECT Id,Name,Order__c,cTin_Role_Universign__c,contact__r.tech_recordtype__c,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,
                                            Code__c,TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCachet__c,OrderCreation__c,orderToSend__c
                                            FROM esignatory__c 
                                            WHERE eSignature__c= :eSignatureId  
                                            AND id= :esignatoryId
                                            ORDER BY  Order__c ASC];
        
        //updating esignatory contact and entity  
       
        if(contactType){
            system.debug('###if');
            if(currentSignatory.size()>0){
                if(currentSignatory[0].cTin_PreviousContact__c!='') currentSignatory[0].cTin_PreviousContact__c= currentSignatory[0].Contact__c;
                currentSignatory[0].Contact__c=recordId;
                currentSignatory[0].Name=recordName;
                currentSignatory[0].EmailTxt__c=con[0].email; 
                currentSignatory[0].MobileTxt__c=con[0].MobilePhone;
                if(con[0].MobilePhone==null)
                   currentSignatory[0].Code__c='email';
                else
                    currentSignatory[0].Code__c=code;
                currentSignatory[0].OrderCreation__c=esignOrder;
                currentSignatory[0].OrderCachet__c=esignOrder;
                currentSignatory[0].OrderToSend__c=esignOrder-1;
                
            }
            else{
                system.debug('###else');                                
                newEsign=new eSignatory__c(Name=recordName,Contact__c=recordId,EntityName__c=con[0].AccountId,
                                        recordtypeId=rtAXA, cTin_Role__c='AXA Representative',eSignature__c=eSignatureId,Contract__c=contract,
                                        code__c=code, EmailTxt__c=con[0].email ,MobileTxt__c=con[0].MobilePhone,
                                        OrderCreation__c=esignOrder,OrderCachet__c=esignOrder,cTin_PreviousContact__c='tbd',OrderToSend__c=esignOrder-1); 
                
                try{insert newEsign;} catch(Exception e){system.debug('####### e'+e.getMessage());}
            }
        }
        else{
            if(currentSignatory.size()>0){
                if(currentSignatory[0].cTin_PreviousContact__c!='') currentSignatory[0].cTin_PreviousContact__c= currentSignatory[0].Contact__c;
                currentSignatory[0].Contact__c=recordId;currentSignatory[0].Name=recordName;currentSignatory[0].EmailTxt__c=con[0].email; currentSignatory[0].MobileTxt__c=con[0].MobilePhone;
                if(con[0].MobilePhone==null)currentSignatory[0].Code__c='email';
                else currentSignatory[0].Code__c=code;
                //update entity as well if contacttype=supplier
                //list<Contact> con= [select accountId,Id,account.name from contact where id=:recordId];
                currentSignatory[0].EntityName__r.name=con[0].account.name;
                currentSignatory[0].EntityName__c=con[0].accountId;currentSignatory[0].OrderCreation__c=esignOrder;currentSignatory[0].OrderCachet__c=esignOrder;currentSignatory[0].OrderToSend__c=esignOrder-1;
            }
            else{
                system.debug('###else');
                newEsign = new eSignatory__c(Name=recordName,Contact__c=recordId,EntityName__c=con[0].AccountId,
                                        recordtypeId=rtSupplier, cTin_Role__c='Supplier Representative',eSignature__c=eSignatureId,Contract__c=contract,
                                        code__c=code, EmailTxt__c=con[0].email ,MobileTxt__c=con[0].MobilePhone,
                                        OrderCreation__c=esignOrder,OrderCachet__c=esignOrder,cTin_PreviousContact__c='tbd',OrderToSend__c=esignOrder-1);               
                try{insert newEsign;} catch(Exception e){system.debug('####### e'+e.getMessage());}
            }
        }
        
        if(currentSignatory.size()>0) update currentSignatory;
       
        list<esignatory__c> lstEsignatory = [SELECT Id,Name,Order__c,cTin_Role__c,cTin_Role_Universign__c,EntityName__c,EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,
                                            TECH_defaultSignatory__c,Contact__c,Contact__r.Name,contact__r.tech_recordtype__c,Contact__r.AccountId,cTin_PreviousContact__c,
                                            OrderCachet__c,OrderCreation__c,OrderToSend__c
                                            FROM esignatory__c
                                            WHERE eSignature__c=:eSignatureId
                                            ORDER BY  Order__c ASC];

         return  lstEsignatory;
    }
    
    //method implements logic to cancel any changes (button edit esignature - Cancel action)
    @auraEnabled
    public static list<esignatory__c> cancelChanges(string eSignatureId){
         system.debug('## cancelChanges');
         list<esignatory__c> esignlst=new list<esignatory__c>();
         list<esignatory__c> refreshedlst=new list<esignatory__c>();
         list<esignatory__c> tbdlst=new list<esignatory__c>();
         set<string>contactIdSet=new set<string>();
         map<string,Contact> mapCon=new map<string,Contact>();
         list<esignatory__c>esignRefList= new list<esignatory__c>();

         for(esignatory__c esign: [ SELECT Id,Name,cTin_Role__c,contact__r.tech_recordtype__c,cTin_Role_Universign__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,
                                    Order__c,TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCachet__c,OrderCreation__c,OrderToSend__c
                                    FROM esignatory__c 
                                    WHERE eSignature__c=:eSignatureId 
                                    AND cTin_PreviousContact__c!='' ]){
                contactIdSet.add(esign.cTin_PreviousContact__c);
                esignlst.add(esign);
          }
        
          for(Contact c:[select accountId,Id,account.name,mobilephone,email from contact where id IN:contactIdSet]){mapCon.put(c.Id,c);}
        
          for(esignatory__c esign:esignlst ){        
              if(esign.cTin_PreviousContact__c!=''){
                  if( esign.cTin_PreviousContact__c!='tbd'){
                      if(!esign.cTin_Role__c.contains('AXA')){esign.EntityName__r.name=mapCon.get(esign.cTin_PreviousContact__c).account.name;esign.EntityName__c=mapCon.get(esign.cTin_PreviousContact__c).accountId;}
 
                       if(mapCon.get(esign.cTin_PreviousContact__c).mobilePhone==null) esign.Code__c='sms';
                       else esign.Code__c='email';
                       esign.EmailTxt__c=mapCon.get(esign.cTin_PreviousContact__c).email;
                       esign.Contact__c=esign.cTin_PreviousContact__c;
                       esign.cTin_PreviousContact__c='';
                       refreshedlst.add(esign);
                  }  
                  else{
                  //delete if created via add button and cancelled afterwards
                  tbdlst.add(esign);
                  }
              }
          }
        
          if(refreshedlst.size()>0) update refreshedlst;
          if(tbdlst.size()>0) {
              delete tbdlst;

              list<esignatory__c> tempEsignatory = [SELECT Id,Name,cTin_Role__c,contact__r.tech_recordtype__c,EntityName__c,EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,
                                                    TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCreation__c,OrderToSend__c
                                                    FROM esignatory__c 
                                                    WHERE eSignature__c=:eSignatureId     
                                                    ORDER BY  Order__c ASC];
              for(integer i=0;i<tempEsignatory.size();i++){
                 tempEsignatory[i].order__c=i+1;
                 tempEsignatory[i].OrderCreation__c=i+1;
                 tempEsignatory[i].OrderCachet__c=i+1;
                 tempEsignatory[i].OrderToSend__c= tempEsignatory[i].order__c - 1;       
              }
              
              update tempEsignatory;
         }

          list<esignatory__c> lstEsignatory=[SELECT Id,Name,cTin_Role__c,EntityName__c, contact__r.tech_recordtype__c, cTin_Role_Universign__c,EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,
                                            Order__c,TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCreation__c,OrderToSend__c
                                            FROM esignatory__c 
                                            WHERE eSignature__c=:eSignatureId     
                                            ORDER BY Order__c ASC];
        
          return  lstEsignatory;
    }
    
    
    //method implements logic to save changes (button edit esignature - Save action)
    @auraEnabled
    public static map<string, object> saveChanges(string eSignatureId, list<esignatory__c> lstEsignatories){
        List<eSignatory__c> listEsigToUpsert = new List<eSignatory__c>();
        List<eSignatory__c> listEsigToDelete = new List<eSignatory__c>();
        Set<Id> setContactId = new Set<Id>();
        map<string,object> result = new map<string,object>();
        map<Id,eSignatory__c> mapEsignatoryActual = new map<Id,eSignatory__c>();
        Integer order= 1;
        Integer position_x = 1;
        //integer signerOrder=1;
        integer validatorpositionX = 0 ;
        result.put('success', '');
        
        eSignature__c eSignature =  [SELECT Id, Language__c ,Error_Message__c, Name, Status__c,contract__c,CreatedDate, Contract__r.Name, CreatedById, 
                                    contract__r.status__c,FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c, TransactionID__c 
                                    FROM eSignature__c
                                    WHERE id = :eSignatureId];

        Contract__c ctr =   [SELECT Id,TECH_Apex_Context__c
                            FROM Contract__c 
                            WHERE Id=:eSignature.Contract__c];                              
        
        integer lastindex=lstEsignatories.size()-1;
        if(lstEsignatories[lastindex].cTin_Role__c==AP_Constant.esignRoleValidator){result.put('error', 'Please review the order of the validator at order '+ string.valueOf(lastindex+1) +'. A validator cannot be specified after a signer');}
         
        for(esignatory__c esignatory: lstEsignatories){
            if(esignatory.Contact__c != null){
                if(esignatory.Code__c == 'sms' && (esignatory.MobileTxt__c == null || esignatory.MobileTxt__c == '')){
                    result.put('error', System.label.MessageMobileBlock);
                    break;
                }else{
                    // Esignatory to add
                    if(esignatory.Id != null){
                        mapEsignatoryActual.put(esignatory.Id, esignatory);
                    }else{
                        esignatory.Esignature__c = eSignature.Id;
                        esignatory.Contract__c = ctr.Id;
                        if(esignatory.cTin_Role__c == AP_Constant.esignRoleValidator){
                            esignatory.EsignatoryType__c = 'Customer';
                            esignatory.RecordTypeId = Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get(AP_Constant.esignRoleValidator).getRecordTypeId(); 
                        }else if(esignatory.cTin_Role__c.contains('AXA')){
                            esignatory.EsignatoryType__c = 'AXA';
                            esignatory.RecordTypeId = Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();
                        }else if(esignatory.cTin_Role__c.contains('Supplier')){
                            esignatory.EsignatoryType__c = 'Customer';
                            esignatory.RecordTypeId = Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('Supplier Representative').getRecordTypeId();
                        }
                    }
                    esignatory.order__c = order;
                    order++;
                    //set cTin_OrderToSetCoordinates__c for signers only => used to set x,y coordinates in workflow field update
                  // if(esignatory.cTin_role__c!=AP_Constant.esignRoleValidator){
                       //esignatory.cTin_OrderToSetCoordinates__c = signerOrder;
                       // signerOrder++;
                    //}
                    listEsigToUpsert.add(esignatory);
                }
            }else{result.put('error', 'Please specify a Validator / Signatory in the new line(s)');break;}
        }

        if(!result.containsKey('error')){
            Map<ID, List<eSignatory__c>> MapSignatoWchids = new Map<ID,List<eSignatory__c>>();
            for(esignatory__c esignatory:[SELECT Id, Name, Order__c, MobileTxt__c,cTin_OrderToSetCoordinates__c,Code__c,contact__r.tech_recordtype__c 
                                          FROM esignatory__c 
                                          WHERE Contract__c = :ctr.Id]){                 
                eSignatory__c esign = mapEsignatoryActual.get(esignatory.Id);
                // Esignatory to delete
                if(esign == null){listEsigToDelete.add(esignatory);}
            }
            if(listEsigToDelete.size() > 0){
                try{ delete listEsigToDelete;}Catch(Exception e){ result.put('error', e.getMessage());}
            }
            if(listEsigToUpsert.size() > 0){
                for(Integer i=0; i<listEsigToUpsert.size(); i++){
                    listEsigToUpsert[i].Order__c = i+1;
                    listEsigToUpsert[i].OrderCachet__c = i+1;
                    listEsigToUpsert[i].OrderCreation__c = i+1;
                    if(listEsigToUpsert[i].cTin_Role__c == AP_Constant.esignRoleSigner){
                        Decimal x = (Decimal)position_x/2;
                        listEsigToUpsert[i].x__c = math.mod(position_x,2) == 0 ? 390 : 100;
                        listEsigToUpsert[i].y__c = x.round(System.RoundingMode.UP) * 55;
                        position_x++;
                    } 
                    //listEsigToUpsert[i].cTin_OrderToSetCoordinates__c = i+1;
                    system.debug('*****Name '+listEsigToUpsert[i].Name +' *** '+listEsigToUpsert[i].x__c);
                    system.debug('*****'+listEsigToUpsert[i].Name +' *** '+listEsigToUpsert[i].Order__c);
                }
                try{
                    upsert listEsigToUpsert;
                    ctr.TECH_Apex_Context__c = false;
                    update ctr;
                    result.put('success','Your changes have been saved');
                }Catch(Exception e){ result.put('error', e.getMessage());}
            }
        }
        calculateCoordinates(eSignatureId);
        return result;
    }
    
    public static  void calculateCoordinates(string eSignatureId){
        Integer order=0;
        list<esignatory__c> lstEsign=new list<esignatory__c>();
        for(esignatory__c esign:[SELECT id,cTin_OrderToSetCoordinates__c FROM esignatory__c where esignature__c =:eSignatureId AND cTin_role__c != : AP_Constant.esignRoleValidator ORDER BY order__c asc]){
            esign.cTin_OrderToSetCoordinates__c=order;
            order++;                        
            lstEsign.add(esign);
        }
        if(lstEsign.size()>0)
            update lstEsign;
    }
    
    //method implements logic to save changes (button edit esignature - Save action)
   /* @auraEnabled
    public static map<string,object> saveChanges(string eSignatureId,list<esignatory__c>esignlst){
        system.debug('## saveChanges');
        map<string,object> result=new map<string,object>();
        map<id,string> mapCode=new map<id,string>();
        map<id,string> mapPhone=new map<id,string>();
        boolean isError=false;
            
        result.put('success','');    
        for(esignatory__c tempesign:esignlst){
            mapCode.put(tempesign.Id,tempesign.Code__c);
            mapPhone.put(tempesign.Id,tempesign.MobileTxt__c);
        }
        
        list<esignatory__c> lstEsignatory=new list<esignatory__c>();
        
        for(eSignatory__c esign:[SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,
                                 Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCachet__c,OrderCreation__c,OrderToSend__c
                                 FROM esignatory__c 
                                 where eSignature__c=:eSignatureId  
                                 and Id IN: esignlst
                                 order by  Order__c asc]){
                  
                   esignatory__c es = new esignatory__c();           
                   if(esign.cTin_PreviousContact__c != '')     esign.cTin_PreviousContact__c = '';
                   
                   if(mapCode.containsKey(esign.Id)){
                        esign.Code__c = (mapCode.get(esign.Id));
                        if((mapPhone.get(esign.Id)) != null && (mapPhone.get(esign.Id)) != ''  && !(mapPhone.get(esign.Id)).startswith('+'))
                            esign.MobileTxt__c = '+' + (mapPhone.get(esign.Id));  
                        else 
                            esign.MobileTxt__c = (mapPhone.get(esign.Id));  
                   }
                   lstEsignatory.add(esign);                                        
        }
       
        try{  
            if (lstEsignatory.size() > 0){
                update lstEsignatory;              
            }
        }
        catch(Exception e){
            if(e.getMessage().contains('Mobile'))
                result.put('error','Phone is mandatory if sms OTP code is selected');
            else
               result.put('error',e.getMessage());
        }
        
        if(!result.containsKey('error'))
            result.put('success',lstEsignatory);
       
        return  result;
    }*/
    
    //method implements logic to change order of esignatories (button edit esignature - Arrow up/down action)
    @auraEnabled
    public static list<esignatory__c> changeOrder(string eSignatureId,string esignatoryId, string sortType, decimal currentOrder,esignatory__c currEsign){     
        System.debug('@@ eSignatureId '  + eSignatureId + ' esignatoryId ' + esignatoryId + ' sortType ' + sortType + ' currentOrder ' + currentOrder + ' currEsign ' + currEsign);

        decimal newOrder=0;
        list<esignatory__c> lstEsignatory=new list<esignatory__c>();
        list<esignatory__c> refreshedlst=new list<esignatory__c>();

        try{
            
       
            for(eSignatory__c esign:[SELECT Id,Name,cTin_Role__c,EntityName__c,contact__r.tech_recordtype__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,
                                    TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCachet__c,OrderCreation__c,OrderToSend__c
                                    FROM esignatory__c 
                                    WHERE eSignature__c=:eSignatureId
                                    AND order__c=:currentOrder]){
                   
                if(sortType=='up') {                    
                        esign.Order__c=currentOrder+1;
                        esign.OrderCachet__c=currentOrder+1;
                        esign.OrderCreation__c=currentOrder+1;     
                    lstEsignatory.add(esign) ;     
                }
                
                if(sortType=='down') {                    
                        esign.Order__c=currentOrder-1;
                        esign.OrderCachet__c=currentOrder-1;
                        esign.OrderCreation__c=currentOrder-1;
                        lstEsignatory.add(esign) ;     
                }
                        
            }
            esignatory__c esign=new esignatory__c(id=esignatoryId,Order__c=currentOrder,OrderCachet__c=currentOrder,OrderCreation__c=currentOrder,OrderToSend__c=currentOrder-1);
            lstEsignatory.add(esign);
           
           if (lstEsignatory.size() > 0){
                update lstEsignatory;
            }
            
            list<esignatory__c> esignatorylst=new list<esignatory__c>();
            for(esignatory__c es: lstEsignatory){          
                es.OrderToSend__c=es.Order__c-1;
                if(es.Id==currEsign.Id){
                    es.MobileTxt__c=currEsign.MobileTxt__c;
                    es.Code__c=currEsign.Code__c;
                }
                esignatorylst.add(es);
            }

            if (esignatorylst.size() > 0){
                update esignatorylst;
            }

            refreshedlst = [SELECT Id,Name,cTin_Role__c,EntityName__c, EntityName__r.Name,EmailTxt__c,contact__r.tech_recordtype__c,MobileTxt__c,Code__c,Order__c,
                            TECH_defaultSignatory__c,Contact__c,Contact__r.Name,Contact__r.AccountId,cTin_PreviousContact__c,OrderCachet__c,OrderCreation__c,OrderToSend__c
                            FROM esignatory__c 
                            WHERE eSignature__c=:eSignatureId     
                            ORDER BY Order__c asc ];
            for(integer i=1;i<refreshedlst.size();i++){
                refreshedlst[i].Order__c=i+1;
                refreshedlst[i].OrderCachet__c=i+1;
                refreshedlst[i].OrderCreation__c=i+1;
            }
            update refreshedlst;
        }
        catch(Exception e){
            System.debug('@@ Exception ' + e.getMessage());
        }
        
        return  refreshedlst;
    }
    
   //method implements logic for the action "Sign Approve contract" 
   @AuraEnabled
    public static map<string,object> assignSignatoryURL(string eSignatureId){
        map<string,object> result=new map<string,object>();
        result.put('esignatureId',eSignatureId);
        
        String signUrl = '';
        List<eSignatory__c> lstESignatory = new List<eSignatory__c>();

        try{
            lstESignatory = [SELECT Id,Name, eSignature__c, FirstName__c, LastName__c, signURL__c, status__c,contact__r.tech_recordtype__c
                            FROM eSignatory__c 
                            WHERE eSignature__c = :eSignatureId
                            AND status__c = :AP_Constant.esignatoryStatusReady];
            
            // will execute only once since only one eSignatory ready at a time
            for(eSignatory__c eSignatory : lstESignatory){ signUrl = eSignatory.signURL__c.replace('#/?id=','sign/');}
            
            //display error if no signUrl is found
            if(signUrl != null && signUrl != ''){result.put('success',signUrl);
            }
            else{
                result.put('error',System.label.eSignatoryErrNotSignatory);
            }
        }
        catch(Exception e){result.put('error',e.getMessage()); }   
       
        System.debug('$$$$ Result: ' +  result);
        return result;
    }
    
   //method used to implement search/query contact for lookups used in cmp
    @AuraEnabled
    public static List<Contact> getSObjectList(String sObjectType,String searchTerm, String contactType, String esignatoriesId) {
        //List<String> contactIdlst = new List<String>();
        List<Contact> lstContact;
        String recordTypeId = '';
        Type idArrType = Type.forName('List<string>');
        List<string> lstContactId = esignatoriesId.split(',');

        if(contactType == 'AXA Representative'){
            recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('AXA').getRecordTypeId();
        }else{ //if(contactType == 'Supplier Representative'){
            recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
        }
        searchTerm = '%'+searchTerm+'%';
        /*if(recordTypeId == ''){
            recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
            lstContact = [SELECT Id, Name, Email, MobilePhone, AccountId, Account.Name, Tech_RecordType__c 
                        FROM Contact 
                        WHERE Name like :searchTerm
                        AND RecordTypeId != :recordTypeId
                        AND Active__c = true
                        AND Id NOT IN :lstContactId
                        ORDER BY Name LIMIT 20];
        }else{*/
            lstContact = [SELECT Id, Name, Email, MobilePhone, AccountId, Account.Name, Tech_RecordType__c FROM Contact WHERE Name like :searchTerm 
                        AND RecordTypeId = :recordTypeId
                        AND ctin_Active__c = true
                        AND Id NOT IN :lstContactId
                        ORDER BY Name LIMIT 20];
        //}
        return lstContact;
    }
    
    //method used to implement search/query contact for lookups used in cmp
    @AuraEnabled
    public static List<AuraObject> getSObject(String sObjectType,String searchId) {
        return querySObjects('Select Id,Name From '+String.escapeSingleQuotes(sObjectType)+
                    ' Where Id = \'' + String.escapeSingleQuotes(searchId) + '\''+
                    ' Limit 1');
    }    

    private static List<AuraObject> querySObjects(String qry) {
        List<AuraObject> auraObjs = new List<AuraObject>();
        try {
            List<sObject> objs = Database.query(qry);
                for (sObject s : objs) { auraObjs.add(new AuraObject(s));}
        } catch (Exception e) {auraObjs.add(new AuraObject('error',e.getMessage()+'; '+e.getStackTraceString()));}       
        return auraObjs;
    }
    
    public class AuraObject {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;} 
        
        public AuraObject(sObject obj) {this.Id = (String)obj.get('Id');this.name = (String)obj.get('Name');            }
        
        public AuraObject(String id,String name) {this.Id = id;this.name = name;            }        
    }
}