@isTest
private class AP22_XmlRpcWrapper_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_XmlRpcWrapper
-- - Author        : SC
-- - Description   : Test Class AP22_XmlRpcWrapper
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 06-JUN-2017  DMU    1.0     Test Class AP22_XmlRpcWrapper
*************************************************************************************/

    static User testUser;
    static list<Esignature__c> esignatureLst=new list<Esignature__c>();
    static list<Contract__c> contractLst=new list<Contract__c>();
    static list<Account>supplierLst=new list<Account>();
    static list<Esignatory__c> esignatoryLst=new list<Esignatory__c>();
    static list<Contact> contactLst=new list<Contact>();
    static List <UniversignAuthentification__c> currentAuth;
    static ContentWorkspace workspace;
    
    static {
       
        testUser = TestFactory.createUser('testUsr',TestFactory.getProfileAdminId(), true);
        testUser.PAD_BypassValidationRules__c = true;
        testUser.Bypass_FieldFilter__c = true;
        testUser.cTin_Universign__c = true;
        insert testUser;

        System.runAs(testUser){  
        
            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;
          
            Account supplier1 = TestFactory.createSupplier('supplier 1','Paris','France');
            Account supplier2 = TestFactory.createSupplier('supplier 2','Paris','France');
            supplierLst.add(supplier1);
            supplierLst.add(supplier2);
            insert supplierLst;

            Contact con1=TestFactory.createContact(supplier1,'James','Brown');
            Contact con2=TestFactory.createContact(supplier1,'Jim','Brown');
            Contact con3=TestFactory.createContact(supplier1,'Kate','Brown');
            Contact con4=TestFactory.createContact(supplier1,'Kim','Brown');
            contactLst.add(con1);
            contactLst.add(con2);
            contactLst.add(con3);
            contactLst.add(con4);
            insert contactLst;

            contract__c contract1 = TestFactory.createContract(supplier1.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
            contract__c contract2 = TestFactory.createContract(supplier2.Id,'Contract2',AP_Constant.contractCustValidationStatus);
            contract__c contract3 = new Contract__c(RecordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(), name='ctr1');
            contractLst.add(contract1);  
            contractLst.add(contract2);
            contractLst.add(contract3);
            insert contractLst;

            Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
            Esignature__c esignature3=TestFactory.createEsignature(contractLst[2],'esign3', AP_Constant.eSignatureCreatedStatus);
            esignatureLst.add(esignature1);
            esignatureLst.add(esignature2);
            esignatureLst.add(esignature3);
            insert esignatureLst;

            Esignatory__c esignatory1= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'James',contactLst[0].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory2= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'Jim',contactLst[1].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory3= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kate',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory4= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kim',contactLst[3].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory5= TestFactory.createEsignatory(contractLst[2], esignatureLst[2],'Kate',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory6= TestFactory.createEsignatory(contractLst[2], esignatureLst[2],'Kim',contactLst[3].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory1.mobileTxt__c='515655656';
            esignatory2.mobileTxt__c='515655746';
            esignatory3.mobileTxt__c='515655446';
            esignatory4.mobileTxt__c='515655146';
            esignatory5.mobileTxt__c='515655446';
            esignatory6.mobileTxt__c='515655146';
            esignatoryLst.add(esignatory1);
            esignatoryLst.add(esignatory2);
            esignatoryLst.add(esignatory3);
            esignatoryLst.add(esignatory4);
            esignatoryLst.add(esignatory5);
            esignatoryLst.add(esignatory6);
            insert esignatoryLst;      
        
        }
    }
    
    static testMethod void testAPICalloutSuccess_requesterRequestTransaction() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_requesterRequestTransaction<<<');
        
        System.runAs(testUser){
            currentAuth = TestFactory.loadCSWSDetails();
            insert currentAuth;

            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_requesterRequestTransaction().respond(new HTTPRequest()); 
            Test.startTest(); 
            List<ContentDistribution> contDistList = new list <ContentDistribution> ();
               /* contentversion cv = TestFactory.createContentVersion('titleCV', 'pathCV.pdf', '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u78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNC4yLjEtYzA0MyA1Mi4zNzI3MjgsIDIwMDkvMDEvMTgtMTU6MDg6MDQgICAgICAgICI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyI+CiAgICAgICAgIDxkYzpmb3JtYXQ+YXBwbGljYXRpb24vcGRmPC9kYzpmb3JtYXQ+CiAgICAgICAgIDxkYzpjcmVhdG9yPgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaT5jZGFpbHk8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6U2VxPgogICAgICAgICA8L2RjOmNyZWF0b3I+CiAgICAgICAgIDxkYzp0aXRsZT4KICAgICAgICAgICAgPHJkZjpBbHQ+CiAgICAgICAgICAgICAgIDxyZGY6bGkgeG1sOmxhbmc9IngtZGVmYXVsdCI+VGhpcyBpcyBhIHRlc3QgUERGIGZpbGU8L3JkZjpsaT4KICAgICAgICAgICAgPC9yZGY6QWx0PgogICAgICAgICA8L2RjOnRpdGxlPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHhtcDpDcmVhdGVEYXRlPjIwMDAtMDYtMjlUMTA6MjE6MDgrMTE6MDA8L3htcDpDcmVhdGVEYXRlPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPk1pY3Jvc29mdCBXb3JkIDguMDwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8eG1wOk1vZGlmeURhdGU+MjAxMy0xMC0yOFQxNToyNDoxMy0wNDowMDwveG1wOk1vZGlmeURhdGU+CiAgICAgICAgIDx4bXA6TWV0YWRhdGFEYXRlPjIwMTMtMTAtMjhUMTU6MjQ6MTMtMDQ6MDA8L3htcDpNZXRhZGF0YURhdGU+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpwZGY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGRmLzEuMy8iPgogICAgICAgICA8cGRmOlByb2R1Y2VyPkFjcm9iYXQgRGlzdGlsbGVyIDQuMCBmb3IgV2luZG93czwvcGRmOlByb2R1Y2VyPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iPgogICAgICAgICA8eG1wTU06RG9jdW1lbnRJRD51dWlkOjA4MDVlMjIxLTgwYTgtNDU5ZS1hNTIyLTYzNWVkNWMxZTJlNjwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1NOkluc3RhbmNlSUQ+dXVpZDo2MmQ2YWU2ZC00M2M0LTQ3MmQtOWIyOC03YzRhZGQ4ZjllNDY8L3htcE1NOkluc3RhbmNlSUQ+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgCjw/eHBhY2tldCBlbmQ9InciPz4NCmVuZHN0cmVhbQ1lbmRvYmoNMiAwIG9iag08PC9GaWx0ZXIvRmxhdGVEZWNvZGUvRmlyc3QgNC9MZW5ndGggNDgvTiAxL1R5cGUvT2JqU3RtPj5zdHJlYW0NCmjeMlUwULCx0XfOL80rUTDU985MKY62BIoFxeqHVBak6gckpqcW29kBBBgA1ncLgA0KZW5kc3RyZWFtDWVuZG9iag0zIDAgb2JqDTw8L0ZpbHRlci9GbGF0ZURlY29kZS9GaXJzdCA0L0xlbmd0aCAxNjcvTiAxL1R5cGUvT2JqU3RtPj5zdHJlYW0NCmjePMvBCsIwEEXRX5mdDaKdxCpVSqFY3AkuBNexSelA6EAyRfx7A4qPu3znAAhNU3aLTByLwVkKb1Weo7dCPPdWfNGfDOYdzFGj0VivtV4hrn6vrK40RE48Cjw4Oqi3qMoruz/WuwxrvTeV3m2w+uJbZLcMPhZdxk8r0FMSCsFHqLYII0d40Oz4lVR5Jwm+uE+UIGdBfBK49RcYKXjVth8BBgBnZztkDQplbmRzdHJlYW0NZW5kb2JqDTQgMCBvYmoNPDwvRGVjb2RlUGFybXM8PC9Db2x1bW5zIDMvUHJlZGljdG9yIDEyPj4vRmlsdGVyL0ZsYXRlRGVjb2RlL0lEWzw0REM5MUExODc1QTZENzA3QUVDMjAzQkIwMjFDOTNBMD48RjZDOTJCMzY4QThBMTM0MDg0NTdBMUQzOTVBMzdFQjk+XS9JbmZvIDYgMCBSL0xlbmd0aCAzNy9Sb290IDggMCBSL1NpemUgNy9UeXBlL1hSZWYvV1sxIDIgMF0+PnN0cmVhbQ0KaN5iYmBgYGLkPcLEwD+ViYGhh4mBkYWJ8bEkkM0IEGAAKlkDFA0KZW5kc3RyZWFtDWVuZG9iag1zdGFydHhyZWYNCjExNg0KJSVFT0YNCg==', true);
                insert cv;

                List<ContentDistribution> contDistList = new list <ContentDistribution> ();
                ContentDistribution cd = TestFactory.createContentDistribution(cv.Id, 'xxxTEST.pdf', contractLst[0].id );                
                contDistList.add(cd);
                insert contDistList;*/
            // insert doc in pdf
            ContentVersion cv = new ContentVersion(
                Title = 'ACH',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('ACH'),
                IsMajorVersion = true,
                sign_able__c=true
            );
            insert cv;
            ContentDistribution cd = new ContentDistribution(
                Name = cv.Title,
                ContentVersionId = cv.Id,
                RelatedRecordId= contractLst[0].Id,
                PreferencesAllowViewInBrowser= true,
                PreferencesLinkLatestVersion=true,
                PreferencesNotifyOnVisit=false,
                PreferencesPasswordRequired=false,
                PreferencesAllowOriginalDownload= true
            );
            //List<ContentDistribution> contDistList = new list <ContentDistribution> ();
            contDistList.add(cd);
            insert contDistList;
            
           
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            // System.debug('@@@ lstDocuments' + lstDocuments);

            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=contractLst[0].Id, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;
                
                esignatoryLst[0].FirstName__c = 'ESFirstname';
                esignatoryLst[0].LastName__c = 'ESLsname';
                esignatoryLst[0].Code__c = 'sms';
                esignatoryLst[0].EmailTxt__c = 'emlTEXT@gmail.com';
                esignatoryLst[0].MobileTxt__c = 'mbTEST@gmail.com';
                esignatoryLst[0].Order__c = 1;
                esignatoryLst[0].cTin_role__c='Supplier Representative';
                esignatoryLst[0].OrderCreation__c=1;
                esignatoryLst[0].OrderCachet__c=1;
                esignatoryLst[0].OrderToSend__c=0;
                update esignatoryLst;

                esignatureLst[0].language__c = 'French';
                update esignatureLst;

                AP22_XmlRpcWrapper.CreateXmlRpc(esignatureLst[0], esignatoryLst, contDistList);   
                
                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICalloutSuccess_requesterRelaunchTransaction() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_requesterRelaunchTransaction<<<');  
        set<id> esignatureIdSet=new set<id>();
        
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_requesterRelaunchTransaction().respond(new HTTPRequest()); 
            Test.startTest();  

                AP22_XmlRpcWrapper.CreateXmlRpcForRelaunch(esignatureLst[0], '2' ,esignatoryLst, 1);                               

                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                esignatureIdSet.add(esignatureLst[0].id);
                AP22_RetrieveSignedDoc.getSignedDoc(esignatureIdSet);
            Test.stopTest();    
        }
    }

    static testMethod void testAPICalloutSuccess_ParseXmlRelaunchResponse() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_ParseXmlRelaunchResponse<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRelaunchResponse(esignatureLst[0],'<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>url</name><value><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member></struct></value></param></params></methodResponse>','<methodCall><methodName>requester.cancelTransaction</methodName><params><param><value><string>null</string></value></param></params></methodCall>',esignatoryLst,1);                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c != null];  
                system.assertEquals(true, elogLst.size() > 0); 
                
            Test.stopTest();    
        }
    }

    //test to increase coverage for catch block
    static testMethod void testAPICalloutError_ParseXmlRelaunchResponse() {
        system.debug('>>>TEST METHOD testAPICalloutError_ParseXmlRelaunchResponse<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRelaunchResponse(esignatureLst[0],'<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>url</name><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member></struct></value></param></params></methodResponse>','<methodCall><methodName>requester.cancelTransaction</methodName><params><param><value><string>null</string></value></param></params></methodCall>',esignatoryLst,1);                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c != null];  
                system.assertEquals(true, elogLst.size() > 0); 
                
            Test.stopTest();    
        }
    }
    static testMethod void testAPICalloutSuccess_requesterCancelTransaction() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_requesterCancelTransaction<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_requesterCancelTransaction().respond(new HTTPRequest()); 
            Test.startTest();  

                AP22_XmlRpcWrapper.CreateXmlRpcForCancel(esignatureLst[0], '2', esignatoryLst);                             

                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }
    static testMethod void testAPICalloutError_requesterCancelTransaction() {
        system.debug('>>>TEST METHOD testAPICalloutError_requesterCancelTransaction<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Error_requesterCancelTransaction().respond(new HTTPRequest()); 
            Test.startTest();  

                AP22_XmlRpcWrapper.CreateXmlRpcForCancel(esignatureLst[0], '2', esignatoryLst);                             

                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICalloutSuccess_ParseXmlCancelResponse() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_ParseXmlCancelResponse<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) ');             
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlCancelResponse(esignatureLst[0], '<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>url</name><value><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member></struct></value></param></params></methodResponse>', '<methodCall><methodName>requester.cancelTransaction</methodName><params><param><value><string>null</string></value></param></params></methodCall>', esignatoryLst);                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c = 'Cancel Esignature'];  
                system.assertEquals(1, elogLst.size());
                                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICalloutSuccess_ParseXmlRPcResponse() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_ParseXmlRPcResponse<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRPcResponse(esignatureLst[0], '<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>url</name><value><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member></struct></value></param></params></methodResponse>', '<methodCall><methodName>requester.cancelTransaction</methodName><params><param><value><string>null</string></value></param></params></methodCall>');                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c = 'Submit Esignature'];  
                system.assertEquals(1, elogLst.size());
                                
            Test.stopTest();    
        }
    }

     static testMethod void testAPICalloutError_ParseXmlRPcResponse() {
        system.debug('>>>TEST METHOD testAPICalloutError_ParseXmlRPcResponse<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRPcResponse(esignatureLst[0], '<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</member><member><name>url</name><value><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member></struct></value></param></params></methodResponse>', '<methodCall><methodName>requester.cancelTransaction</methodName><params><param><value><string>null</string></value></param></params></methodCall>');                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c = 'Submit Esignature'];  
                system.assertEquals(0, elogLst.size());
                                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICallout_ParseXmlRPcResponse2_Success() {
        system.debug('>>>TEST METHOD testAPICallout_ParseXmlRPcResponse2_Success<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRPcResponse2('<?xml version="1.0"?><methodCall><methodName>requester.requestTransaction</methodName><params><param><value><struct><member><name>profile</name><value><string>default</string></value></member><member><name>documents</name><value><array><data><value><struct><member><name>profile</name><value><string>default</string></value></member><member><name>url</name><value><string>https://axags--dev04.cs88.content.force.com/sfc/dist/version/downloadNoFlash?oid=00D9E000000D8et&amp;ids=0689E000000DsruQAC&amp;d=/a/9E0000004Gu3/OjR_mD0yYxD1rgp3yld.dcPHaaA34rp07CNQvtVEAC8&amp;operationContext=DELIVERY</string></value></member><member><name>name</name><value><string>TEST_FLOW_01062017_2017-06-01-08:02:26.pdf.pdf</string></value></member><member><name>signatureFields</name><value><array><data><value><struct><member><name>signerIndex</name><value><int>0</int></value></member><member><name>page</name><value><int>1</int></value></member><member><name>x</name><value><int>50</int></value></member><member><name>y</name><value><int>55</int></value></member></struct></value><value><struct><member><name>signerIndex</name><value><int>1</int></value></member><member><name>page</name><value><int>1</int></value></member><member><name>x</name><value><int>400</int></value></member><member><name>y</name><value><int>55</int></value></member></struct></value></data></array></value></member></struct></value></data></array></value></member><member><name>mustContactFirstSigner</name><value><boolean>1</boolean></value></member><member><name>language</name><value><string>fr</string></value></member><member><name>signers</name><value><array><data><value><struct><member><name>firstname</name><value><string>Jane</string></value></member><member><name>lastname</name><value><string>Blue</string></value></member><member><name>identificationType</name><value><string>email</string></value></member><member><name>emailAddress</name><value><string>meshwaree.ramphul@sc-mauritius.com</string></value></member><member><name>phoneNum</name><value><string>2222222</string></value></member><member><name>successURL</name><value><string>https://www.axa.com</string></value></member><member><name>cancelURL</name><value><string>https://custom.cryptolog.com/axagroupprocurement/gie/canceled.html</string></value></member><member><name>failURL</name><value><string>https://www.axa.com</string></value></member></struct></value><value><struct><member><name>firstname</name><value><string>Jim</string></value></member><member><name>lastname</name><value><string>Black</string></value></member><member><name>identificationType</name><value><string>email</string></value></member><member><name>emailAddress</name><value><string>meshwaree.ramphul@spoonconsulting.com</string></value></member><member><name>phoneNum</name><value><string>23057248291</string></value></member><member><name>successURL</name><value><string>https://www.axa.com</string></value></member><member><name>cancelURL</name><value><string>https://custom.cryptolog.com/axagroupprocurement/gie/canceled.html</string></value></member><member><name>failURL</name><value><string>https://www.axa.com</string></value></member></struct></value></data></array></value></member><member><name>customId</name><value><string>Id=a0R9E000000MnvQUAS&amp;Contract=a0D9E000000RzqLUAS&amp;CreatedById=0059E000000YrKwQAK</string></value></member><member><name>finalDocSent</name><value><boolean>1</boolean></value></member><member><name>handwrittenSignatureMode</name><value><int>2</int></value></member><member><name>description</name><value><string>a0R9E000000MnvQUAS</string></value></member></struct></value></param></params></methodCall>');

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c != null];  
                system.assertEquals(0, elogLst.size()); //In methos ParseXmlRPcResponse2, record eSignatureLog__c is not created
                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICallout_ParseXmlRPcResponse2_Error() {
        system.debug('>>>TEST METHOD testAPICallout_ParseXmlRPcResponse2_Error<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            Test.startTest();  

                AP22_XmlRpcWrapper.ParseXmlRPcResponse2('<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member>86eaa8d0-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>url</name><value><string>https://sign.test.universign.eu/fr/signature/?id=87070a70-4690-31e7-8b7a-0ae1403d207f</string></value></member><member><name>faultCode</name><value><string>true</string></value></member><member><name>faultString</name><value><string>true</string></value></member><member><name>firstName</name><value><string>fisrtnameTest</string></value></member><member><name>lastName</name><value><string>lastnameTest</string></value></member></struct></value></param></params></methodResponse>');                          

                list <eSignatureLog__c> elogLst = [select Request__c from eSignatureLog__c where StepName__c != null];  
                system.assertEquals(1, elogLst.size()); //In methos ParseXmlRPcResponse2, record eSignatureLog__c is not created
                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICalloutSuccess_getTransactionInfo() {
        system.debug('>>>TEST METHOD testAPICalloutSuccess_getTransactionInfo<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_getTransactionInfo().respond(new HTTPRequest()); 
            Test.startTest();  

                AP22_XmlRpcWrapper.getTransactionInfo(esignatureLst[0]);                             

                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }

    static testMethod void testAPICallout_CreateXmlRpcForSignedDocument_Success() {
        system.debug('>>>TEST METHOD testAPICallout_CreateXmlRpcForSignedDocument_Success<<<');
        System.runAs(testUser){  
            //esignatureLst[0].ExternalId__c='9aef0930-45ea-31e7-bd7f-005ca37beeef';
            //update esignatureLst[0];
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_CreateXmlRpcForSignedDocument().respond(new HTTPRequest()); 
            Test.startTest();  

                AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esignatureLst[0],contractLst[0], 'sourceTestClass');                            

                system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }

   static testMethod void testAPICallout_CreateXmlRpcForSignedDocument_Error() {
        system.debug('>>>TEST METHOD testAPICallout_CreateXmlRpcForSignedDocument_Error<<<');
        System.runAs(testUser){  
            system.debug('>>>System.runAs(testUser) '); 
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Error_CreateXmlRpcForSignedDocument().respond(new HTTPRequest());
            AP22_XmlRpcWrapper.testError=true; 
            Test.startTest();  

                AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esignatureLst[0],contractLst[0], 'sourceTestClass');                            

                system.assertEquals(500, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());  
                
            Test.stopTest();    
        }
    }
    //coverage for catch block
    static testMethod void testAPICallout_CreateXmlRpcForSignedDocument_CatchExc() {
        system.debug('>>>TEST METHOD testAPICallout_CreateXmlRpcForSignedDocument_CatchExc<<<');
        System.runAs(testUser){  
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Error_CreateXmlRpcForSignedDocument().respond(new HTTPRequest()); 
            Test.startTest();  
                AP22_XmlRpcWrapper.testError=true;
                AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esignatureLst[0],contractLst[0], 'sourceTestClass');                            
            Test.stopTest();  
             list<eSignatureLog__c> logList=[select Response__c from eSignatureLog__c where eSignatureId__c=:esignatureLst[0].id];
             system.assertEquals(1,logList.size()); 
        }
    }

    static testMethod void testAPICallout_CreateXmlRpcForSignedDocumentLEX_Success() {
        system.debug('>>>TEST METHOD testAPICallout_CreateXmlRpcForSignedDocument_Success<<<');
        System.runAs(testUser){
            //esignatureLst[0].ExternalId__c='9aef0930-45ea-31e7-bd7f-005ca37beeef';
            //update esignatureLst[0];
            system.debug('>>>System.runAs(testUser) ');
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_CreateXmlRpcForSignedDocument().respond(new HTTPRequest());
            Test.startTest();

            AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esignatureLst[2],contractLst[2], 'sourceTestClass');

            system.assertEquals(200, AP22_XmlRpcWrapper.dummyResponse.getStatusCode());

            Test.stopTest();
        }
    }

    static testMethod void testGetRfusalComment() {
        System.runAs(testUser){
            
            esignatureLst[0].ExternalId__c = '85e49c20-446f-31e7-bd7f-005ca37beeef';
            update esignatureLst;
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_CreateXmlRpcForSignedDocument().respond(new HTTPRequest());
            Test.startTest();

            AP22_XmlRpcWrapper.GetRefusalComment('85e49c20-446f-31e7-bd7f-005ca37beeef');

            Test.stopTest();
        }
    }

    static testMethod void testCreateXmlRpcForRefusalComment() {
        System.runAs(testUser){
            
            esignatureLst[0].ExternalId__c = '85e49c20-446f-31e7-bd7f-005ca37beeef';
            update esignatureLst;
            AP22_XmlRpcWrapper.dummyResponse = new TestFactory.WSResponse_Success_CreateXmlRpcForSignedDocument().respond(new HTTPRequest());
            Test.startTest();

            AP22_XmlRpcWrapper.CreateXmlRpcForRefusalComment('85e49c20-446f-31e7-bd7f-005ca37beeef',esignatureLst[0].Id, esignatoryLst[0]);

            Test.stopTest();
        }
    }

}