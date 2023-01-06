global class AP25_CommercialLegalOperations {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : AP25_CommercialLegalOperations
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 13-JULY-2017 MCU   1.0     Initial version  
    -- 07-MAY-2019  USA   1.1     Migration Lightning              
    --------------------------------------------------------------------------------------
    **************************************************************************************/
   
    @auraEnabled
    public static void CallWebserviceLightning(Id accId){
        List<Id> setCommercialInsUpt = new List<Id>();
        setCommercialInsUpt.add(accId);   
        try{
            CallWebserviceUpdateLegalOperation(setCommercialInsUpt);  

            if(test.isRunningTest()){
                throw new AuraHandledException('Error thrown');
            }
            
        }
        catch(exception e){
            System.debug('## error : ' + e.getMessage());
        }        
    }

    @future(callout=true)
    public static void insertCommercialOperation(Set<Id> setCommercialIns){
        System.debug('### START - AP25_CommercialLegalOperations.insertCommercialOperation');
        List<Id> listCommercialIns = new list<Id>(setCommercialIns);
        CallWebserviceInsert(listCommercialIns); 
       
    }

    webservice static void CallWebserviceInsert(List<Id> setCommercialIns){

        System.debug('### START - AP25_CommercialLegalOperations.CallWebserviceInsert');
        PAD.cantrigger('AP25a');
        List<WS04_SAPEntitiesOperations10.Commercial_Element> commercialElementsLst = new List<WS04_SAPEntitiesOperations10.Commercial_Element>();
        List<Account> accLst = new List <Account>();
        
        List <Account> accInsertLst = [SELECT id,Name,Active__c,AXA_Region__c,MDM_Entity_Code__c,Group_Governance__c,
                                      Account_Manager__c,Account_Manager__r.name,Show_In_POS__c,POS_Country__c,billingcountry,
                                      Status__c,Message__c,Last_Synchronisation__c FROM Account WHERE ID IN :setCommercialIns]; 

        if (accInsertLst.size() > 0){

            for (Account acc : accInsertLst){ 
                WS04_SAPEntitiesOperations10.Commercial_Element Ce = new WS04_SAPEntitiesOperations10.Commercial_Element();
                //Ce.CommercialEntityID = acc.MDM_Entity_Code__c; 
                Ce.SFDCID = acc.Id; 
                Ce.CommercialName = acc.Name;
                Ce.Active = (acc.Active__c) ? 'true' : 'false';
                Ce.AxaRegion = blankValue(acc.AXA_Region__c);
                Ce.Country = blankValue(acc.billingcountry);
                Ce.AccountManager = blankValue(acc.Account_Manager__r.name);
                Ce.POS = (acc.Show_In_POS__c) ? 'true' : 'false';
                Ce.Governance =blankValue(acc.Group_Governance__c);
              
                commercialElementsLst.add(Ce); 
            }

            WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp ebx = new WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp();

            // instantiate Response.
            WS04_SAPEntitiesOperations10.insert_CommercialResponseType sche = new WS04_SAPEntitiesOperations10.insert_CommercialResponseType();
            
            // instantiate DataList
            WS04_SAPEntitiesOperations10.CommercialType wscom = new WS04_SAPEntitiesOperations10.CommercialType ();
            WS04_SAPEntitiesOperations10.root_element wsRE = new WS04_SAPEntitiesOperations10.root_element ();
            wsRe.Commercial = commercialElementsLst;
            wscom.root = wsRE;

            System.debug('### MCU Insert : ' + commercialElementsLst); 
        
            try{
                ebx.inputHttpHeaders_x  = new Map<String, String>(); 
                ebx.timeout_x  = 120000;
                Blob headerValue = Blob.valueOf(system.label.WS_EIPLogin + ':' + system.label.WS_EIPPassword);

                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

                ebx.inputHttpHeaders_x.put('Authorization',authorizationHeader);
                system.debug(LoggingLevel.INFO,'## Authorization:'+authorizationHeader);
                sche = ebx.insert_CommercialOperation('clientData','client','false','false','false',wscom);
                integer i=0;
                system.debug('sche: '+sche);
                for (Account account : accInsertLst){   
                     account.Status__c = (sche.status=='00')?'OK':((sche.status=='01')?'OK':sche.status);
                     account.Message__c = 'No MDM Entity code found in response';
                     if(sche.inserted.predicate.size() > 0 && string.isNotBlank(sche.inserted.predicate[i])){
                        account.MDM_Entity_Code__c = sche.inserted.predicate[i].replaceall('&#39;','');
                        system.debug(account.MDM_Entity_Code__c);
                        //account.MDM_Entity_Code__c = sche.inserted.predicate[i].replaceall('\'','');
                        //account.MDM_Entity_Code__c = sche.inserted.predicate[i].replaceall(''','');
                        account.MDM_Entity_Code__c = account.MDM_Entity_Code__c.replaceall('./CommercialEntityID=','');
                        account.MDM_Entity_Code__c = account.MDM_Entity_Code__c.replaceall('\'','');
                        system.debug(account.MDM_Entity_Code__c);
                        account.Message__c = account.status__c;
                     } 
                     account.Last_Synchronisation__c = System.now();
                     i++;
                }
            }catch(exception e) {
                for (Account account : accInsertLst){   
                     account.Status__c = 'KO';
                     account.Message__c = 'Error calling webservice : ' + e.getMessage();//32000
                     account.Message__c.left(32000);
                     account.Last_Synchronisation__c = System.now();
                     
                }
            }

            
            if (accInsertLst.size() > 0){
                update accInsertLst;
            }
            
        }

        System.debug('### END - AP25_CommercialLegalOperations.CallWebserviceInsert');
    }

    @future(callout=true)
    public static void updateCommercialOperation(Set<Id> setCommercialUpt){
        System.debug('### START - updateCommercialOperation');
        List<Id> lstCommercialUpt = new list<Id>(setCommercialUpt);
        CallWebserviceupdateCommercialOperation(lstCommercialUpt);   
    }

    webservice static void CallWebserviceUpdateCommercialOperation(list<Id> setCommercialUpt){
        System.debug('### START - CallWebserviceUpdateCommercialOperation');

        List<WS04_SAPEntitiesOperations10.Commercial_Element> commercialElementsLst = new List<WS04_SAPEntitiesOperations10.Commercial_Element>();
        List<Account> accLst = new List <Account>();
        
        List <Account> accUpdateLst = [SELECT id,Name,Active__c,AXA_Region__c,MDM_Entity_Code__c,Account_Manager__r.name,
                                              Account_Manager__c,Show_In_POS__c,POS_Country__c,billingcountry,
                                              Status__c,Message__c,Last_Synchronisation__c,Group_Governance__c 
                                        FROM Account 
                                        WHERE ID IN :setCommercialUpt];

        
        if (accUpdateLst.size() > 0){

            for (Account acc : accUpdateLst){
                WS04_SAPEntitiesOperations10.Commercial_Element Ce = new WS04_SAPEntitiesOperations10.Commercial_Element();
                Ce.CommercialEntityID = acc.MDM_Entity_Code__c; 
                Ce.SFDCID = acc.Id; 
                Ce.CommercialName = acc.Name;
                Ce.Active = (acc.Active__c) ? 'true' : 'false';
                Ce.AxaRegion = blankValue(acc.AXA_Region__c);
                Ce.Country = blankValue(acc.billingcountry);
                Ce.AccountManager = blankValue(acc.Account_Manager__r.name);
                Ce.POS = (acc.Show_In_POS__c) ? 'true' : 'false';
                Ce.Governance =blankValue(acc.Group_Governance__c);
              
                commercialElementsLst.add(Ce); 
            }

            WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp ebx = new WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp();

            // instantiate Response.
            String Response = '';
            
            // instantiate DataList
            WS04_SAPEntitiesOperations10.CommercialType wscom = new WS04_SAPEntitiesOperations10.CommercialType ();
            WS04_SAPEntitiesOperations10.root_element wsRE = new WS04_SAPEntitiesOperations10.root_element ();
            wsRe.Commercial = commercialElementsLst;
            wscom.root = wsRE;

            System.debug('### MCU Update : ' + commercialElementsLst);

            try{
                ebx.inputHttpHeaders_x  = new Map<String, String>();
                ebx.timeout_x  = 120000;
                Blob headerValue = Blob.valueOf(system.label.WS_EIPLogin + ':' + system.label.WS_EIPPassword);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                ebx.inputHttpHeaders_x.put('Authorization',authorizationHeader);
                
                Response = ebx.update_CommercialOperation('clientData','client','false','false','false',wscom);
                system.debug(Response);
                for (Account account : accUpdateLst){   
                     Response = (Response=='00')?'OK':((Response=='01')?'OK':Response);
                     account.Status__c = Response;
                     account.Message__c = Response;
                     account.Last_Synchronisation__c = System.now();
                }
            }catch(exception e) {
                for (Account account : accUpdateLst){   
                     account.Status__c = 'KO';
                     account.Message__c = 'Error calling webservice : ' + e.getMessage();//32000
                     account.Message__c.left(32000);
                     account.Last_Synchronisation__c = System.now();
                }
            }


            if (accUpdateLst.size() > 0){
                update accUpdateLst;
            }

        }

    }



    @future(callout=true)
    public static void updateLegalOperation(Set<Id> setLegalUpt){
        System.debug('### START - updateLegalOperation');
        List<Id> lstLegalUpt = new list<Id>(setLegalUpt);
        CallWebserviceUpdateLegalOperation(lstLegalUpt);
    }


    webservice static void CallWebserviceUpdateLegalOperation(List<Id> setLegalUpt){
         System.debug('### START - CallWebserviceUpdateLegalOperation');

        List<WS04_SAPEntitiesOperations10.Legal_element> legalElementsLst = new List<WS04_SAPEntitiesOperations10.Legal_element>();
        List<Account> accLst = new List <Account>();
        
        List <Account> accUpdateLst = [SELECT id,Parentid,SAP_Account_Number__c,MSA__c,MSA_Reference__c,MSA_Date__c,
                                              Active__c,Company_Registration_Number__c,Tax_Document__c,MDMLegalEntityCode__c,
                                              Status__c,Message__c,Last_Synchronisation__c,name,parent.MDM_Entity_Code__c,
                                              billingStreet,billingCity,billingPostalCode,billingcountry,Email__c,Language__c,VAT__c,GIE_AXA_GS_Member__c
                                        FROM Account 
                                        WHERE ID IN :setLegalUpt];

        
        if (accUpdateLst.size() > 0){

            for (Account acc : accUpdateLst){
                WS04_SAPEntitiesOperations10.Legal_element Le = new WS04_SAPEntitiesOperations10.Legal_element();
                Le.MSA = (acc.MSA__c) ? 'true' : 'false';
                Le.MSAReference = blankValue(acc.MSA_Reference__c);
                Le.MSADate = (acc.MSA_Date__c==null)?null:string.valueof(acc.MSA_Date__c);
                Le.Active = (acc.Active__c) ? 'true' : 'false';
                Le.CompagnyRegistrationNumber = blankValue(acc.Company_Registration_Number__c);
                Le.TaxDocument = (acc.Tax_Document__c=='Yes')? 'true' : 'false';
                //Le.Vendor = acc.SAP_Account_Number__c;
                Le.legalentityid =  acc.MDMLegalEntityCode__c;
                Le.CommercialEntity = blankValue(acc.parent.MDM_Entity_Code__c);

                /*
                //Le.Legalname = acc.name;
                Le.Street = acc.billingStreet;
                Le.City = acc.billingCity;
                Le.PostalCode = acc.billingPostalCode;
                Le.Country = acc.billingCountry;
                //Le.Email = acc.Email__c;
                Le.Language = acc.Language__c;
                Le.VAT = acc.VAT__c;
                Le.GIE = (acc.GIE_AXA_GS_Member__c=='Yes')?'true':'false';
                Le.Trading = 'Legal Entity';
            */
                legalElementsLst.add(Le); 
                

            }

            WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp ebx = new WS04_SAPEntitiesOperations.ags_it_entities_operations_vssoaphttp();

            // instantiate Response.
            String Response;
            
            // instantiate DataList
            WS04_SAPEntitiesOperations10.LegalType wscom = new WS04_SAPEntitiesOperations10.LegalType ();
            WS04_SAPEntitiesOperations10.rootLegal_element wsRE = new WS04_SAPEntitiesOperations10.rootLegal_element ();
            wsRe.Legal = legalElementsLst;
            wscom.root = wsRE;
            
            try{
                ebx.inputHttpHeaders_x  = new Map<String, String>();
                ebx.timeout_x  = 120000;
                Blob headerValue = Blob.valueOf(system.label.WS_EIPLogin + ':' + system.label.WS_EIPPassword);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                ebx.inputHttpHeaders_x.put('Authorization',authorizationHeader);
                Response = ebx.update_LegalOperation('clientData','client','false','true','false',wscom);
                system.debug(Response);
                for (Account account : accUpdateLst){   
                     account.Status__c = Response;
                     account.Message__c = Response;
                     account.Last_Synchronisation__c = System.now();
                }
            }catch(exception e) {
                for (Account account : accUpdateLst){   
                     account.Status__c = 'KO';
                     account.Message__c = 'Error calling webservice : ' + e.getMessage();//32000
                     account.Message__c.left(32000);
                     account.Last_Synchronisation__c = System.now();
                }

            }

            if (accUpdateLst.size() > 0){
                update accUpdateLst;
            }

        }

    }
    
    public static string blankValue(string val){
        return ((string.isnotblank(val))?val:'');
    }

}