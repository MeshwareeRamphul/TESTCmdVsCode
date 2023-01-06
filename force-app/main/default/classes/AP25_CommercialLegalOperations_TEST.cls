@isTest
private class AP25_CommercialLegalOperations_TEST{
    
    static User testUser;
    static list<Account> accLst;
    static List<Account> accWithMDMEntityLst;

    
    static {
       
        testUser = TestFactory.createUser('testUsr',TestFactory.getProfileAdminId(), true);
        //testUser.PAD_BypassValidationRules__c = true;
        insert testUser;

        System.runAs(testUser){          
        //accLst = new list<Account>{new Account(Name= 'Acc1',MDM_Entity_Code__c = null)
        //                         , new Account(Name= 'Acc2', MDM_Entity_Code__c = '1234')
        //                         , new Account(Name= 'Acc3')
        //                     };

        }
    }


    
    static testMethod void ws04_legalUpdate(){
        System.debug('>>>TEST METHOD UpdateLegal<<<');
        System.runAs(testUser){
            Test.setMock(WebServiceMock.class, new WS04_DataservicesLegalMockUpdate());
            
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            PAD.PAD_BypassTrigger = 'AP25';
            accWithMDMEntityLst = TestFactory.createAccount(3, mapRT.get(AP_Constant.RT_DN_LEGAL_ENTITY).id);
            PAD.PAD_BypassTrigger = '';

            accWithMDMEntityLst[0].SAP_Account_Number__c  = 'abc1';
            accWithMDMEntityLst[1].SAP_Account_Number__c  = 'abc2';
            accWithMDMEntityLst[2].SAP_Account_Number__c  = 'abc3';

            accWithMDMEntityLst[0].MSA__c  = true;
            accWithMDMEntityLst[1].MSA__c  = false;
            accWithMDMEntityLst[2].MSA__c  = false;

            accWithMDMEntityLst[0].Active__c = false;
            accWithMDMEntityLst[1].Active__c = true;
            accWithMDMEntityLst[2].Active__c = false;

            accWithMDMEntityLst[0].MDMLegalEntityCode__c  = 'abc1';
            accWithMDMEntityLst[1].MDMLegalEntityCode__c  = 'abc2';
            accWithMDMEntityLst[2].MDMLegalEntityCode__c  = 'abc3';

            Test.startTest();
                update accWithMDMEntityLst;
            Test.stopTest();
        }
    }

    static testMethod void ws04_insertCommercialCrash(){
        System.debug('TEST METHOD LegalUpdateCrash');
        System.runAs(testUser){
            Test.setMock(WebServiceMock.class, new WS04_DataservicesLegalMockUpdate());
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            accWithMDMEntityLst = TestFactory.createAccount(3, mapRT.get(AP_Constant.RT_DN_ENTITY).id);

            accWithMDMEntityLst[0].MDM_Entity_Code__c  = 'abc1';
            accWithMDMEntityLst[1].MDM_Entity_Code__c  = 'abc2';
            accWithMDMEntityLst[2].MDM_Entity_Code__c  = 'abc3';
            Test.startTest();
                update accWithMDMEntityLst;
            Test.stopTest();
        }
    }

    static testMethod void ws04_updateCommercialCrash(){
        System.debug('TEST METHOD LegalUpdateCrash');
        System.runAs(testUser){
            //Test.setMock(WebServiceMock.class, new WS04_DataservicesMockUpdate());
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            accWithMDMEntityLst = TestFactory.createAccount(3, mapRT.get(AP_Constant.RT_DN_ENTITY).id);

            accWithMDMEntityLst[0].MDM_Entity_Code__c  = 'abc1';
            accWithMDMEntityLst[1].MDM_Entity_Code__c  = 'abc2';
            accWithMDMEntityLst[2].MDM_Entity_Code__c  = 'abc3';

            accWithMDMEntityLst[0].Name  = 'UpdateAcct1';
            accWithMDMEntityLst[1].Name  = 'UpdateAcct2';
            accWithMDMEntityLst[2].Name  = 'UpdateAcct3';

            accWithMDMEntityLst[0].Active__c  = false;
            accWithMDMEntityLst[1].Active__c  = true;
            accWithMDMEntityLst[2].Active__c  = false;

            Test.startTest();
                update accWithMDMEntityLst;
            Test.stopTest();
        }
    }

    static testMethod void ws04_UpdateLegalCrash(){
        System.debug('TEST METHOD LegalUpdateCrash');
        System.runAs(testUser){
            //Test.setMock(WebServiceMock.class, new WS04_DataservicesLegalMockUpdate());         
            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            PAD.PAD_BypassTrigger = 'AP25';
            accWithMDMEntityLst = TestFactory.createAccount(3, mapRT.get(AP_Constant.RT_DN_LEGAL_ENTITY).id);
            PAD.PAD_BypassTrigger = '';

            accWithMDMEntityLst[0].SAP_Account_Number__c  = 'abc1';
            accWithMDMEntityLst[1].SAP_Account_Number__c  = 'abc2';
            accWithMDMEntityLst[2].SAP_Account_Number__c  = 'abc3';

            accWithMDMEntityLst[0].MSA__c  = true;
            accWithMDMEntityLst[1].MSA__c  = false;
            accWithMDMEntityLst[2].MSA__c  = false;

            accWithMDMEntityLst[0].Active__c = false;
            accWithMDMEntityLst[1].Active__c = true;
            accWithMDMEntityLst[2].Active__c = false;

            accWithMDMEntityLst[0].MDMLegalEntityCode__c  = 'abc1';
            accWithMDMEntityLst[1].MDMLegalEntityCode__c  = 'abc2';
            accWithMDMEntityLst[2].MDMLegalEntityCode__c  = 'abc3';

            Test.startTest();
                update accWithMDMEntityLst;
            Test.stopTest();
        }
    }

    static testMethod void ws04_commercialUpdate(){
        system.debug('>>>Test METHOD commercialUpdate');
        system.runAs(testUser){
            Test.setMock(WebServiceMock.class, new WS04_DataservicesMockUpdate());

            Map<String, RecordType> mapRT = AP_Constant.getRecordTypes('Account');
            PAD.PAD_BypassTrigger = 'AP25';

            accWithMDMEntityLst = TestFactory.createAccount(3, mapRT.get(AP_Constant.RT_DN_ENTITY).id);
            PAD.PAD_BypassTrigger = '';
            accWithMDMEntityLst[0].MDM_Entity_Code__c = '123';
            accWithMDMEntityLst[1].MDM_Entity_Code__c = '124';
            accWithMDMEntityLst[2].MDM_Entity_Code__c = '125';

            accWithMDMEntityLst[0].Name = 'UpdatedAccountName1';
            accWithMDMEntityLst[1].Name = 'UpdatedAccountName2';
            accWithMDMEntityLst[2].Name = 'UpdatedAccountName3';

            accWithMDMEntityLst[0].Active__c = false;
            accWithMDMEntityLst[1].Active__c = true;
            accWithMDMEntityLst[2].Active__c = false;

            accWithMDMEntityLst[0].POS_Country__c = 'France';
            accWithMDMEntityLst[1].POS_Country__c = 'Germany';
            accWithMDMEntityLst[2].POS_Country__c = 'Italy';

            Test.startTest();

            update accWithMDMEntityLst;

            Test.stopTest();
        }
    }

    static testMethod void ws04_commercialCreation(){
        System.debug('>>>TEST METHOD commercialCreation<<<');
        System.runAs(testUser){
            Test.setMock(WebServiceMock.class, new WS04_DataservicesMockInsert());
            Test.startTest();

            insert AP05_TestDataFactory.createEntityAccountList(testUser, 'Acc',3);

            Test.stopTest();
        }
    }

    static testMethod void ws04_SAPEntitiesOperations10InstanceCreation() {
        system.debug('>>>TEST METHOD SAP Entities Operations 10 Instances<<<');        
        System.runAs(testUser){  

            Test.startTest();

            WS04_SAPEntitiesOperations10.insertM_LegalRequestType lR = new WS04_SAPEntitiesOperations10.insertM_LegalRequestType();
            WS04_SAPEntitiesOperations10.multiM_ResponseType rt = new WS04_SAPEntitiesOperations10.multiM_ResponseType();
            WS04_SAPEntitiesOperations10.inserted_element iE = new WS04_SAPEntitiesOperations10.inserted_element();
            WS04_SAPEntitiesOperations10.multiM_RequestType reqT = new WS04_SAPEntitiesOperations10.multiM_RequestType();
            WS04_SAPEntitiesOperations10.UsernameToken uT = new WS04_SAPEntitiesOperations10.UsernameToken();
            WS04_SAPEntitiesOperations10.insert_CommercialResponseType cRT = new WS04_SAPEntitiesOperations10.insert_CommercialResponseType();
            WS04_SAPEntitiesOperations10.Security sec = new WS04_SAPEntitiesOperations10.Security();
            WS04_SAPEntitiesOperations10.root_element rE = new WS04_SAPEntitiesOperations10.root_element();
            WS04_SAPEntitiesOperations10.rootLegal_element rLE = new WS04_SAPEntitiesOperations10.rootLegal_element();
            WS04_SAPEntitiesOperations10.StandardException_element sEE = new WS04_SAPEntitiesOperations10.StandardException_element();
            WS04_SAPEntitiesOperations10.UDA uDA = new WS04_SAPEntitiesOperations10.UDA();
            WS04_SAPEntitiesOperations10.insert_CommercialRequestType iCRT = new WS04_SAPEntitiesOperations10.insert_CommercialRequestType();
            WS04_SAPEntitiesOperations10.LegalType lTY = new WS04_SAPEntitiesOperations10.LegalType();
            WS04_SAPEntitiesOperations10.insert_LegalRequestType insLTY = new WS04_SAPEntitiesOperations10.insert_LegalRequestType();
            WS04_SAPEntitiesOperations10.value_element vElem = new WS04_SAPEntitiesOperations10.value_element();
            WS04_SAPEntitiesOperations10.insert_LegalResponseType iLegRT = new WS04_SAPEntitiesOperations10.insert_LegalResponseType();
            WS04_SAPEntitiesOperations10.multi_ResponseType mulRes = new WS04_SAPEntitiesOperations10.multi_ResponseType();
            WS04_SAPEntitiesOperations10.insertM_CommercialRequestType sMCom = new WS04_SAPEntitiesOperations10.insertM_CommercialRequestType();
            WS04_SAPEntitiesOperations10.update_CommercialRequestType upComm = new WS04_SAPEntitiesOperations10.update_CommercialRequestType();
            WS04_SAPEntitiesOperations10.session_element sessElem = new WS04_SAPEntitiesOperations10.session_element();
            WS04_SAPEntitiesOperations10.localizedDocumentations_element localDoc = new WS04_SAPEntitiesOperations10.localizedDocumentations_element();
            WS04_SAPEntitiesOperations10.update_LegalResponseType upLegResp = new WS04_SAPEntitiesOperations10.update_LegalResponseType();
            WS04_SAPEntitiesOperations10.multi_RequestType multiReq = new WS04_SAPEntitiesOperations10.multi_RequestType();
            WS04_SAPEntitiesOperations10.documentation_element docElem = new WS04_SAPEntitiesOperations10.documentation_element();
            WS04_SAPEntitiesOperations10.CommercialType commeType  = new WS04_SAPEntitiesOperations10.CommercialType();
            WS04_SAPEntitiesOperations10.UDACatalog uDACat = new WS04_SAPEntitiesOperations10.UDACatalog();
            WS04_SAPEntitiesOperations10.Legal_element legalElem = new WS04_SAPEntitiesOperations10.Legal_element();
            WS04_SAPEntitiesOperations10.update_LegalRequestType upLegalReqType = new WS04_SAPEntitiesOperations10.update_LegalRequestType();
            WS04_SAPEntitiesOperations10.updateM_LegalRequestType upMLegalRequType = new WS04_SAPEntitiesOperations10.updateM_LegalRequestType();
            WS04_SAPEntitiesOperations10.Commercial_element commElemt = new WS04_SAPEntitiesOperations10.Commercial_element();
            WS04_SAPEntitiesOperations10.update_CommercialResponseType upCommElemtResTy = new WS04_SAPEntitiesOperations10.update_CommercialResponseType();
            WS04_SAPEntitiesOperations10.updateM_CommercialRequestType upMCommElemetResTy = new WS04_SAPEntitiesOperations10.updateM_CommercialRequestType();


            Test.stopTest();
        }
    }

    static testMethod void ws04_schemasDs10() {
        system.debug('>>>TEST METHOD triggerInsertWsUpdate<<<');        
        System.runAs(testUser){  

            Test.startTest();



            /*
                WS04_SchemasDataservices10.History_element hE = new WS04_SchemasDataservices10.History_element();
               WS04_SchemasDataservices10.insertM_CommercialRequestType iCRT = new WS04_SchemasDataservices10.insertM_CommercialRequestType();     
                WS04_SchemasDataservices10.inserted_element iE = new WS04_SchemasDataservices10.inserted_element();     
                WS04_SchemasDataservices10.update_CommercialRequestType uCRT = new WS04_SchemasDataservices10.update_CommercialRequestType();
                WS04_SchemasDataservices10.UsernameToken UT = new WS04_SchemasDataservices10.UsernameToken();
                WS04_SchemasDataservices10.insert_CommercialResponseType iC = new WS04_SchemasDataservices10.insert_CommercialResponseType();
                WS04_SchemasDataservices10.session_element sE = new WS04_SchemasDataservices10.session_element();
                WS04_SchemasDataservices10.HistoryType hT = new WS04_SchemasDataservices10.HistoryType();
                WS04_SchemasDataservices10.Security s = new WS04_SchemasDataservices10.Security();
                WS04_SchemasDataservices10.StandardException_element sEE = new WS04_SchemasDataservices10.StandardException_element();  
                WS04_SchemasDataservices10.documentation_element dE = new WS04_SchemasDataservices10.documentation_element();
                WS04_SchemasDataservices10.CommercialType cT = new WS04_SchemasDataservices10.CommercialType();
                WS04_SchemasDataservices10.UDA uda = new WS04_SchemasDataservices10.UDA();
                WS04_SchemasDataservices10.UDACatalog udaC = new WS04_SchemasDataservices10.UDACatalog();
                WS04_SchemasDataservices10.insert_CommercialRequestType iCR = new WS04_SchemasDataservices10.insert_CommercialRequestType();
                WS04_SchemasDataservices10.LegalType lT = new WS04_SchemasDataservices10.LegalType();
                WS04_SchemasDataservices10.Commercial_element cE = new WS04_SchemasDataservices10.Commercial_element();
                WS04_SchemasDataservices10.value_element vE = new WS04_SchemasDataservices10.value_element();
                WS04_SchemasDataservices10.update_CommercialResponseType uCR = new WS04_SchemasDataservices10.update_CommercialResponseType();
                WS04_SchemasDataservices10.updateM_CommercialRequestType uC = new WS04_SchemasDataservices10.updateM_CommercialRequestType();
                WS04_SchemasDataservices10.Legal_element  lE = new WS04_SchemasDataservices10.Legal_element ();
                WS04_SchemasDataservices10.localizedDocumentations_element lDE = new WS04_SchemasDataservices10.localizedDocumentations_element();*/
            Test.stopTest();    
        }
    }


    static testMethod void ws05_schemasDs10() {
        system.debug('>>>TEST METHOD triggerInsertWsUpdate<<<');        
        System.runAs(testUser){  

            Test.startTest();  
            /*
                WS05_SchemasDataservices10.History_element hE = new WS05_SchemasDataservices10.History_element();
                WS05_SchemasDataservices10.insert_LegalResponseType iLRT = new WS05_SchemasDataservices10.insert_LegalResponseType();     
                WS05_SchemasDataservices10.insertM_LegalRequestType iE = new WS05_SchemasDataservices10.insertM_LegalRequestType();     
                WS05_SchemasDataservices10.inserted_element uCRT = new WS05_SchemasDataservices10.inserted_element();
                WS05_SchemasDataservices10.UsernameToken UT = new WS05_SchemasDataservices10.UsernameToken();
                WS05_SchemasDataservices10.localizedDocumentations_element iC = new WS05_SchemasDataservices10.localizedDocumentations_element();
                WS05_SchemasDataservices10.session_element sE = new WS05_SchemasDataservices10.session_element();
                WS05_SchemasDataservices10.HistoryType hT = new WS05_SchemasDataservices10.HistoryType();
                WS05_SchemasDataservices10.Security s = new WS05_SchemasDataservices10.Security();
                WS05_SchemasDataservices10.StandardException_element sEE = new WS05_SchemasDataservices10.StandardException_element();  
                WS05_SchemasDataservices10.documentation_element dE = new WS05_SchemasDataservices10.documentation_element();
                WS05_SchemasDataservices10.CommercialType cT = new WS05_SchemasDataservices10.CommercialType();
                WS05_SchemasDataservices10.UDA uda = new WS05_SchemasDataservices10.UDA();
                WS05_SchemasDataservices10.UDACatalog udaC = new WS05_SchemasDataservices10.UDACatalog();
                WS05_SchemasDataservices10.LegalType lT = new WS05_SchemasDataservices10.LegalType();
                WS05_SchemasDataservices10.Commercial_element cE = new WS05_SchemasDataservices10.Commercial_element();
                WS05_SchemasDataservices10.value_element vE = new WS05_SchemasDataservices10.value_element();
                WS05_SchemasDataservices10.Legal_element  lE = new WS05_SchemasDataservices10.Legal_element ();
                WS05_SchemasDataservices10.localizedDocumentations_element lDE = new WS05_SchemasDataservices10.localizedDocumentations_element();
                WS05_SchemasDataservices10.root_element  rE = new WS05_SchemasDataservices10.root_element ();
                WS05_SchemasDataservices10.update_LegalResponseType  uLRT = new WS05_SchemasDataservices10.update_LegalResponseType ();
                WS05_SchemasDataservices10.update_LegalRequestType   uLR = new WS05_SchemasDataservices10.update_LegalRequestType  ();
                WS05_SchemasDataservices10.updateM_LegalRequestType   uL = new WS05_SchemasDataservices10.updateM_LegalRequestType  ();
                WS05_SchemasDataservices10.insert_LegalRequestType    iL = new WS05_SchemasDataservices10.insert_LegalRequestType   ();*/
            Test.stopTest();    
        }
    }





/*
    static testMethod void triggerUpdateWsUpdate() {
        system.debug('>>>TEST METHOD triggerUpdateWsUpdate<<<');        
        System.runAs(testUser){  
            Test.setMock(WebServiceMock.class, new WS04_DataservicesMockInsert());
            insert accLst[2];
            
            Account acc = [SELECT id,MSA__c FROM account where id =: accLst[2].Id];
            acc.MSA__c = true;
            Test.setMock(WebServiceMock.class, new WS05_DataservicesMockUpdate());
            Test.startTest();  
                update acc;            
            Test.stopTest();    
        }
    }
*/


    @IsTest
    static void CallWebserviceLightning_test(){
        
        System.runAs(testUser){

            List<Account> accLst = new List<Account>{
                new Account(Name='Acc1'),
                new Account(Name='Acc2'),
                new Account(Name='Acc3')
            };

            insert accLst;
            
            Test.startTest();

            for (Account acc:accLst){
                AP25_CommercialLegalOperations.CallWebserviceLightning(acc.Id);

            }

            Test.stopTest();
            
        }
        
        
    }
    
}