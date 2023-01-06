public without sharing class LC50_ManageEsignature {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC50_ManageEsignature
    -- - Author        : MRA
    -- - Description   : Controller for lwc LWC_EditEsignature & LWC_SubmitEsignature
    --                  
    --
    -- Maintenance History:
    --
    -- Date          Name   Version   Remarks
    -- -----------   ----   -------   ---------------------------------------
    -- 07-OCT-2020  ARA    1.0      Initial version 
                                    (implements submit esignature,Edit Esignature, Sign Approved contract)
    -- 15-DEC-2021  ARA    1.1      SP-03001    Populate Tech All Role email addresses field by contacts email
    -- 23-JUN-2022  ARA    1.1      SP-01893    Upgrade - Migrate Edit eSignature screen to LWC
    --------------------------------------------------------------------------- */

    //method calls AP22_XMLWrapper to submit esignature via xml request (button submit)
    @AuraEnabled
    public static map<string,object> submitEsignature(String esignId){
        String errorMsg = null;
        Map<string,object> result = new Map<String,object>();
        //result.put('esignatureId',esignId);
        eSignature__c eSignature = [SELECT Id, Language__c ,Error_Message__c, Name, Status__c, Contract__c, Contract__r.Customer_Operational_Contact__c, Contract__r.Customer_Operational_Contact__r.Email,
                                    TECH_AutomatedEsign__c,CreatedDate, Contract__r.Name, CreatedById, contract__r.status__c,FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c, TransactionID__c, RecordTypeId
                                    FROM eSignature__c
                                    WHERE id = :esignId];
                                        
        //display error if submit is not allowed
        if(eSignature.Status__c == 'Sent' || eSignature.TransactionID__c != null){
            result.put('error', system.label.EsignatureSubmitError);
        }
        else {
            //submit eSignature
            //1. get list of esignatories 
            List<esignatory__c> listEsignatory = [SELECT Id, cTin_Role_Universign__c,Contact__r.Name,Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, 
                        Code__c, Order__c,EntityName__c, Name__c, cTin_Role__c, SuccessURL__c, FailURL__c, CancelURL__c, EsignatoryType__c,cTin_signLink__c,signURL__c,OrderToSend__c, 
                        x__c, y__c,Tech_RecordTypeName__c,contact__r.mobilephone,esignature__r.cTin_TECH_IsContractIn__c, Tech_OriginalSignatory__c, contact__r.FirstName, contact__r.LastName
                        FROM eSignatory__c
                        WHERE eSignature__c= :esignature.id AND  Order__c != null
                        ORDER BY Order__c ASC];

            //2. get content distribution list (trigger to be implemented for inserting a cd when file is uploaded in LEX)
            List<ContentDistribution> lstCDist =    [SELECT id,name, contentDownloadurl, pdfdownloadurl,distributionpublicurl,contentversion.sign_able__c,contentversion.islatest
                                                    FROM ContentDistribution 
                                                    WHERE RelatedRecordId = :eSignature.Id /*and Contentversion.islatest = true */
                                                    ORDER BY createdDate ASC];
            if(lstCDist == null){
                result.put('error', 'No document to sign');
            }

            for(esignatory__c esignatory: listEsignatory){
                if(esignatory.Contact__c != null && esignatory.Code__c == 'sms' && (esignatory.MobileTxt__c == null || esignatory.MobileTxt__c == '')){
                    result.put('error', System.label.MessageMobileBlock);
                    break;
                }
            }

            if(result.get('error') == null){              
                try{
                    result = WS07_UniversignTransaction.createTransactionFull(esignature,listEsignatory,lstCDist);
                    System.debug('## LC50_ManageEsignature result: '+ result);
                    if(!result.containsKey('error')){
                        result.put('success', Label.EsignatureSubmitSuccess);
                    }
                }catch(Exception e){
                    result.put('error','An error occurred during the submission of the esignature : "'+eSignature.Error_Message__c+'"');
                }
            }
        }

        return result;
    }
    
    // method retrieves esignatories related to esignature (executed when cmp loads)
    @AuraEnabled
    public static map<string,object> getAllSignatories(string recordId){
        map<string,object>result = new map<string,object>();
        List<esignatory__c> lstEsignatory = new List<esignatory__c>();
        boolean blockSignApprove = false;
        string currentUserEmail = userinfo.getUserEmail();
        string currentUserprofileId = userinfo.getProfileId();        
    
        lstEsignatory = [SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c, EntityName__r.Name,EmailTxt__c,Code__c,
                        Order__c,TECH_defaultSignatory__c,Tech_OriginalSignatory__c,OrderCachet__c,orderToSend__c,MobileTxt__c,
                        Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c 
                        FROM esignatory__c 
                        WHERE eSignature__c=:recordId
                        ORDER BY  Order__c ASC];
        
        result.put('data', lstEsignatory);
        return result;
    }
    
    // method retrieves esignatories related to esignature (executed when cmp loads)
    @AuraEnabled
    public static map<string,object> buildSignatorylst(string esignId){
        map<string,object>result = new map<string,object>();
        List<esignatory__c> lstEsignatory = new List<esignatory__c>();
        //List<esignatory__c> currEsignatory = new List<esignatory__c>();
        boolean blockSignApprove = false;
        
        string currentUserEmail = userinfo.getUserEmail();
        string currentUserprofileId = userinfo.getProfileId();
        /*currEsignatory = [SELECT Id,Name, Contact__c, eSignature__c, FirstName__c, LastName__c, signURL__c, status__c,EmailTxt__c,TECH_defaultSignatory__c, Tech_OriginalSignatory__c
                            FROM eSignatory__c 
                            WHERE eSignature__c = :esignId
                            AND status__c = :AP_Constant.esignatoryStatusReady limit 1];
           
        if(currEsignatory.size()>0){
            if(currentUserEmail != currEsignatory[0].EmailTxt__c && currentUserprofileId != AP_Constant.getProfileIdAdmin()){
                blockSignApprove = true;
            }
        }*/
        
    
        lstEsignatory= [SELECT Id,Name,cTin_Role__c,cTin_Role_Universign__c,EntityName__c, EntityName__r.Name,EmailTxt__c,MobileTxt__c,Code__c,Order__c,TECH_defaultSignatory__c,
                        Tech_OriginalSignatory__c, OrderCachet__c,orderToSend__c, Contact__c,Contact__r.Name,Contact__r.AccountId,esignature__r.status__c FROM esignatory__c 
                        WHERE eSignature__c=:esignId
                        ORDER BY  Order__c asc];
        
        result.put('lstEsignatories', lstEsignatory);
        if(lstEsignatory[0].esignature__r.status__c == 'Cancelled' || lstEsignatory[0].esignature__r.status__c == 'Sent'
            || lstEsignatory[0].esignature__r.status__c == 'Completed'){
                result.put('disablebtn', true);
        }
        /*if(lstEsignatory[0].esignature__r.status__c == 'Cancelled' || lstEsignatory[0].esignature__r.status__c == 'Completed' ||
        lstEsignatory[0].esignature__r.status__c == 'Created'  || (blockSignApprove) ){
            result.put('disableSignbtn', true);
        }*/
        return result;
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
    
    //method implements logic to save changes (button edit esignature - Save action)
    @auraEnabled
    public static map<string, object> saveChanges(string eSignatureId, list<esignatory__c> lstEsignatories){
        system.debug('***saveChanges');
        List<eSignatory__c> listEsigToUpsert = new List<eSignatory__c>();
        List<eSignatory__c> listEsigToDelete = new List<eSignatory__c>();
        List<eSignatory__c> ListSigToUpdate = new List<eSignatory__c>();
        Set<Id> setContactId = new Set<Id>();
        map<string,object> result = new map<string,object>();
        map<Id,eSignatory__c> mapEsignatoryActual = new map<Id,eSignatory__c>();
        Integer position_x = 1;
        
        eSignature__c eSignature =  [SELECT Id, Language__c ,Error_Message__c, Name, Status__c,contract__c,contract__r.TECH_Apex_Context__c,
                                    CreatedDate, Contract__r.Name, CreatedById, contract__r.status__c,
                                    FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c, TransactionID__c 
                                    FROM eSignature__c
                                    WHERE id = :eSignatureId];

        for(esignatory__c esignatory: lstEsignatories){
            if(esignatory.Contact__c != null){
                system.debug('****email '+esignatory.EmailTxt__c);
                // Modification pour l'ordre des cachets sur une signature
                if(esignatory.cTin_Role__c == AP_Constant.esignRoleSigner){
                    Decimal x = (Decimal)position_x/2;
                    esignatory.x__c = math.mod(position_x,2) == 0 ? 390 : 100;
                    esignatory.y__c = x.round(System.RoundingMode.UP) * 55;
                    position_x++;
                }
                esignatory.OrderCachet__c  = esignatory.order__c ;
                setContactId.add(esignatory.Contact__c);

                // Esignatory to add
                if(esignatory.Id != null){
                    mapEsignatoryActual.put(esignatory.Id, esignatory);
                }else{
                    esignatory.Esignature__c = eSignature.Id;
                    esignatory.Contract__c = eSignature.Contract__c;
                    if(esignatory.cTin_Role__c == AP_Constant.esignRoleValidator){
                        esignatory.RecordTypeId = Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('Validator').getRecordTypeId();  
                    }else{
                        esignatory.RecordTypeId = Schema.SObjectType.eSignatory__c.getRecordTypeInfosByName().get('AXA Representative').getRecordTypeId();
                    }
                    listEsigToUpsert.add(esignatory);
                }
                //system.debug('***Role '+esignatory.cTin_role__c+' '+esignatory.x__c);
            }else{
                result.put('error', 'Please specify a Validator / Signatory in the new line(s)');
                break;
            }
        }

        if(!result.containsKey('error')){
            List<Contact> listContacts = new List<Contact>();
            Map<ID, List<eSignatory__c>> MapSignatoWchids = new Map<ID,List<eSignatory__c>>(); 
            String recordtypeIdToQuery = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();

            system.debug('***mapEsignatoryActual '+mapEsignatoryActual.keyset());
            for(esignatory__c esignatory:[SELECT Id, Name, Order__c, MobileTxt__c, EmailTxt__c, Code__c, x__c, y__c FROM eSignatory__c WHERE Esignature__c = :eSignatureId]){
                // Esignatory to delete
                system.debug('***containsKey '+mapEsignatoryActual.containsKey(esignatory.Id));
                if(!mapEsignatoryActual.containsKey(esignatory.Id)){
                    listEsigToDelete.add(esignatory);
                }else{
                    // Esignatory to update                 
                    eSignatory__c esign = mapEsignatoryActual.get(esignatory.Id);
                    if(esign.MobileTxt__c != esignatory.MobileTxt__c || esign.EmailTxt__c != esignatory.EmailTxt__c || esign.Code__c != esignatory.Code__c || esign.Order__c != esignatory.Order__c || esign.x__c != esignatory.x__c || esign.y__c != esignatory.y__c){
                        listEsigToUpsert.add(esign);
                    }
                }
            }

            system.debug('***listEsigToUpsert '+listEsigToUpsert.size());
            if(listEsigToUpsert.size() > 0){
                try{
                    upsert listEsigToUpsert;
                }Catch(Exception e){ 
                    result.put('error', e.getMessage());
                }
            }
            system.debug('***listEsigToDelete '+listEsigToDelete.size());
            if(listEsigToDelete.size() > 0){
                try{
                    delete listEsigToDelete;
                }Catch(Exception e){ 
                    result.put('error', e.getMessage());
                }
            }
        
            lstEsignatories = [SELECT Id,contract__r.Id, Name__c , Contact__c, FirstName__c, LastName__c,Name,                
                                Contract__c, MobileTxt__c, EmailTxt__c, Code__c, Order__c, EntityName__c, cTin_role__c,
                                SuccessURL__c, FailURL__c, CancelURL__c 
                                FROM eSignatory__c 
                                WHERE eSignature__c=:eSignatureId 
                                AND Order__c != null
                                ORDER BY Order__c asc];

            if(lstEsignatories.size()>0 || MapSignatoWchids.size()>0){
                integer NumberInList = 0 ; 
                //Integer order = 1;
                for(Integer i=0 ; i< lstEsignatories.size() ; i++){       
                    // Fils ou Pas
                    if(lstEsignatories.get(i).cTin_role__c == AP_Constant.esignRoleSigner){
                        if(MapSignatoWchids.get(lstEsignatories.get(i).ID) !=null){                   
                            for(eSignatory__c observerSign : MapSignatoWchids.get(lstEsignatories.get(i).ID) ){
                                observerSign.OrderToSend__c = NumberInList++   ; 
                                ListSigToUpdate.add(observerSign) ;              
                            }                    
                        }
                        if(NumberInList != null /*&& lstEsignatories.get(i).parenteSignatory__c == null*/) {
                            lstEsignatories.get(i).OrderToSend__c  =NumberInList ++ ;   
                            ListSigToUpdate.add(lstEsignatories.get(i)) ;                   
                        }
                        if(NumberInList == 0 /*&& lstEsignatories.get(i).parenteSignatory__c == null */){
                            lstEsignatories.get(i).OrderToSend__c  = i ;
                            ListSigToUpdate.add(lstEsignatories.get(i)) ;                     
                        }
                    }
                }

                if(ListSigToUpdate.size()>0 && !result.containsKey('error')){
                    try{
                        update ListSigToUpdate ; 
                        Contract__c ctr = new Contract__c(Id = esignature.Contract__c, TECH_Apex_Context__c = false);
                        update ctr;
                    }
                    Catch(Exception e){
                        result.put('error', e.getMessage()) ; 
                    }
                }
            }
        }
        if(!result.containsKey('error')){
            result.put('success', Label.EsignatureEditSuccess);
        }

        return result;
    }
    
    //method used to implement search/query contact for lookups used in cmp
    @AuraEnabled
    public static List<Contact> getSObjectList(String searchTerm) {        
        searchTerm = '%'+searchTerm+'%';
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
        return [SELECT Id, Name, Email, MobilePhone, AccountId, Account.Name FROM Contact 
                WHERE Name like :searchTerm 
                AND RecordTypeId = :recordTypeId
                AND Active__c = true
                ORDER BY Name LIMIT 20];
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
                for (sObject s : objs) {
                    auraObjs.add(new AuraObject(s));
                }
        } catch (Exception e) {
            auraObjs.add(new AuraObject('error',e.getMessage()+'; '+e.getStackTraceString()));
        }
        
        return auraObjs;
    }
    
    public class AuraObject {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;} 
        
        public AuraObject(sObject obj) {
            this.id = (String)obj.get('Id');
            this.name = (String)obj.get('Name');            
        }
        
        public AuraObject(String id,String name) {
            this.id = id;
            this.name = name;            
        }        
    }
}