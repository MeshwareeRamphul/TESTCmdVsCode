@isTest
public class WS07_UniversignTransaction_Test {
	static User                      testUser;
    static Esignature__c             esignature;
    static Contract__c               contract,contract2;
    static List<ContentDistribution> lstCDist;
    static Account                   supplier;
    static List<esignatory__c>       listEsignatory = new List<esignatory__c>();
    static list<Account>             supplierLst   = new list<Account>();
    static list<Contact>             contactLst    = new list<Contact>();
    static Map<String,Object> 		 mapOfResult = new Map<String,Object>();
    static ContentVersion            content;
    static ContentDistribution       cd;
    static Planned_Invoicing_Line__c pInvLine;
    static Id contractId;
    static ContentWorkspace workspace;
    
    static{
        
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Bypass_FieldFilter__c = true;
        testUser.PAD_BypassValidationRules__c = true;
        testUser.cTin_Universign__c = true;
        insert testUser;
        
        system.runAs(testUser){
            supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;
            
            Contact con1=TestFactory.createContact(supplier,'James','Brown');
            con1.Email='test1@email.com';
            Contact con2=TestFactory.createContact(supplier,'Jim','Brown');
            con2.Email='test2@email.com';
            Contact con3=TestFactory.createContact(supplier,'Jane','Brown');
            con3.Email='test3@email.com';
            Contact con4=TestFactory.createContact(supplier,'Tom','Brown');
            con3.Email='test4@email.com';
            Contact con5=TestFactory.createContact(supplier,'Jerry','Brown');
            con3.Email='test5@email.com';
            
            contactLst.add(con1);
            contactLst.add(con2); 
            contactLst.add(con3);
            contactLst.add(con4);
            contactLst.add(con5);
            insert contactLst;
            
            contract  = TestFactory.createContract(supplier.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
            contract2 = TestFactory.createContract(supplier.Id,'Contract2',AP_Constant.contractCustValidationStatus);   
            List<contract__c> lstctr = new List<contract__c>();         
            lstctr.add(contract);
            lstctr.add(contract2);
            insert lstctr;
            
            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;
            
            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
            insert cd;
            
            ContentDistribution cdistr = [SELECT id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId FROM ContentDistribution WHERE id=: cd.Id ];  
            contract.FinalDocumentURL__c = cdistr.DistributionPublicUrl;
            contract.status__c = AP_Constant.contractReadyStatus;
            contract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get(Label.RT_ContractReadOnlyLightning).getRecordTypeId();
            contract.CustomerSignedBy__c = contactLst[1].id;
            contract.AXA_GS_Signed_By__c = contactLst[2].id;
            contract.Customer_Operational_Contact__c = contactLst[3].id;
            update contract;
            
            List<ContentDocument> lstDocuments = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            contractId=[select id from Contract__c where id =: contract.id].id;
            List<contentDocumentLink> lstCDL = new List<contentDocumentLink>{
                new contentDocumentLink(LinkedEntityId=contractId, ContentDocumentId=lstDocuments[0].Id)
            };
            insert lstCDL;
            
            LC49_CreateSignature.validateCreateSign(contract.Id);
            
            eSignature = [SELECT Id, Language__c ,Error_Message__c, Name, Status__c, Contract__c, Contract__r.Customer_Operational_Contact__c, 
                        Contract__r.Customer_Operational_Contact__r.Email,TECH_AutomatedEsign__c,CreatedDate, Contract__r.Name, CreatedById, 
                        contract__r.status__c,FinalDocumentURL__c,HandWrittenSignatureMode__c,cTin_TECH_IsContractIn__c, TransactionID__c 
                        FROM eSignature__c
                        WHERE Contract__c = :contract.Id];
            
            Esignatory__c esignatory1 = TestFactory.createEsignatory(contract, eSignature,contactLst[0].Name,contactLst[0].id,AP_Constant.esignatoryStatusNotStarted);
            esignatory1.Order__c=1;
            esignatory1.OrderCachet__c=1;
            esignatory1.EmailTxt__c = contactLst[0].Email;
            esignatory1.Name=contactLst[0].lastname;
            esignatory1.Code__c = 'email';
            esignatory1.MobileTxt__c='45648461';
            esignatory1.ctin_Role__c = AP_Constant.esignRoleValidator;
            insert esignatory1;

            for(Esignatory__c esign : [SELECT Id, cTin_Role_Universign__c,Contact__r.Name,Contact__c, FirstName__c, LastName__c,Name, Contract__c, MobileTxt__c, EmailTxt__c, Code__c, 
                                    OrderToSend__c,Order__c,EntityName__c, Name__c, cTin_Role__c, SuccessURL__c, FailURL__c, CancelURL__c, EsignatoryType__c,cTin_signLink__c,signURL__c,
                                    x__c, y__c,contact__r.mobilephone,esignature__r.cTin_TECH_IsContractIn__c, Tech_OriginalSignatory__c, contact__r.FirstName, contact__r.LastName
                                    FROM eSignatory__c
                                    WHERE eSignature__c= :esignature.id AND Order__c != null
                                    ORDER BY OrderToSend__c asc]){
                for(Integer i=0;i<contactLst.size();i++){
                    if(contactLst[i].Email == esign.EmailTxt__c){
                        esign.Order__c=i+1;
                        esign.OrderCachet__c=i+1;
                        esign.OrderToSend__c=i+1;
                        esign.OrderCreation__c=i+1;
                    }
                }
                listEsignatory.add(esign);
            }
            update listEsignatory;

            lstCDist = [SELECT id,name, contentDownloadurl, pdfdownloadurl,distributionpublicurl,
                        contentversion.sign_able__c,contentversion.islatest
                        FROM ContentDistribution 
                        WHERE RelatedRecordId = :eSignature.Id
                        ORDER BY createdDate ASC];
            
            workspace = TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;
        }
    }
    
    @isTest
    static void createTransactionFull_test(){
        system.runAs(testUser){
            //Test.setMock(HttpCalloutMock.class, new WS07_UniversignTransactionMock());
            Test.startTest();
            Map<String, String> mapRes = WS07_UniversignTransaction.createTransactionFull(eSignature,listEsignatory,lstCDist);
            
            RestRequest req = new RestRequest();
            req.requestUri ='/services/apexrest/esignature/update/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_wQzJJ3G87k2P","created_at":"2022-11-16T11:12:59.033Z","type":"action.closed","payload":{"object":{"action_id":"act_QzlroBkKGrdwY","participant_email":"test1@email.com","transaction_id":"tx_aveG7QvK72qo"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_AW544w3kP2wz","created_at":"2022-11-16T11:12:59.029Z","type":"action.opened","payload":{"object":{"transaction_id":"tx_aveG7QvK72qo","action_id":"act_gmLgn5yE2xaeP","participant_email":"test2@email.com"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_wQzJJ3G87k2Q","created_at":"2022-11-16T11:12:59.033Z","type":"action.closed","payload":{"object":{"action_id":"act_QzlroBkKGrdwY","participant_email":"test2@email.com","transaction_id":"tx_aveG7QvK72qo"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_AW544w3kP3wz","created_at":"2022-11-16T11:12:59.029Z","type":"action.opened","payload":{"object":{"transaction_id":"tx_aveG7QvK72qo","action_id":"act_gmLgn5yE2xaeP","participant_email":"test3@email.com"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_wQzJJ3G87k2R","created_at":"2022-11-16T11:12:59.033Z","type":"action.closed","payload":{"object":{"action_id":"act_QzlroBkKGrdwY","participant_email":"test3@email.com","transaction_id":"tx_aveG7QvK72qo"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();

            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_YY2VV8VnlE0q","created_at":"2022-11-16T13:07:08.631Z","type":"transaction.lifecycle.completed","payload":{"object":{"object":"transaction","id":"tx_aveG7QvK72qo","folder_id":"fol_DJEwkmwZDBK3","created_at":"2022-11-16T13:01:42.411Z","started_at":"2022-11-16T13:01:42.847Z","closed_at":"2022-11-16T13:07:06.846Z","name":"NEWCONTRACT","stalled":false,"language":"en","creator":{"workspace_name":"AXA Procurement recette","api_key_name":"UniversignDevKey"},"state":"completed","participants":[{"email":"test3@email.com","name_constraint":"Jane Brown","fullname_prerequisite":"Jane Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"completed"},{"email":"test2@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"completed"}],"watchers":[],"sealers":[],"documents":[{"id":"doc_WEl8","name":"NEWCONTRACT_20221115_12-07_SOW.pdf","updatable":false,"deletable":false,"fields":[{"id":"fld_BwKk","name":"field0","position":{"page":1,"x":80,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":false,"deletable":false},{"id":"fld_2Za5","name":"field1","position":{"page":1,"x":380,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":false,"deletable":false}]}],"instructions":{"signatures":[{"signer":"test2@email.com","field":"fld_BwKk"},{"signer":"test3@email.com","field":"fld_2Za5"}],"reviews":[],"captures":[],"sequencing":[{"before":"test2@email.com","after":"test3@email.com"}],"editions":[]},"actions":[{"id":"act_oB7JqGl662zEo","actor":"test2@email.com","state":"closed","started_at":"2022-11-16T13:01:43.075Z","closed_at":"2022-11-16T13:04:13.611Z","url":"https://apps.universign.com/npds/act_oB7JqGl662zEo","tasks":[{"type":"signature","state":"done","field":"fld_BwKk"}],"stalled":false},{"id":"act_eEVkEJv1yEMaW","actor":"test3@email.com","state":"closed","started_at":"2022-11-16T13:04:14.291Z","closed_at":"2022-11-16T13:07:06.494Z","url":"https://apps.universign.com/npds/act_eEVkEJv1yEMaW","tasks":[{"type":"signature","state":"done","field":"fld_2Za5"}],"stalled":false}],"metadata":{},"progress_value":100,"ongoing_conversation":false,"has_unread_message":false,"origin":"API","carbon_copies":[],"uploads":[],"private":false}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();

            Test.stopTest();
        }
    }
    
    @isTest
    static void actionStalled_test(){
        system.runAs(testUser){
            //Test.setMock(HttpCalloutMock.class, new WS07_UniversignTransactionMock());
            Test.startTest();
            Map<String, String> mapRes = WS07_UniversignTransaction.createTransactionFull(eSignature,listEsignatory,lstCDist);
            
            RestRequest req = new RestRequest();
            req.requestUri ='/services/apexrest/esignature/update/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_wQzJJ3G87k2P","created_at":"2022-11-16T11:12:59.033Z","type":"action.closed","payload":{"object":{"action_id":"act_QzlroBkKGrdwY","participant_email":"test1@email.com","transaction_id":"tx_aveG7QvK72qo"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            
            req.requestBody = Blob.valueOf('{"object":"event","id":"evt_k1vw96DVZ6Ae","created_at":"2022-11-16T11:59:03.851Z","type":"action.stalled","payload":{"object":{"action_id":"act_gmLgn5yE2xaeP","participant_email":"test2@email.com","transaction_id":"tx_aveG7QvK72qo","stalled_reason":"signature_refusal"}}}');
            RestContext.request = req;
            WS07_UniversignTransaction.doPost();
            Test.stopTest();
        }
    }
    
    @isTest
    static void cancelTransaction_test(){
        system.runAs(testUser){
            Test.startTest();
            Map<String, String> mapRes = WS07_UniversignTransaction.cancelTransaction(eSignature);
            Test.stopTest();
        }
    }
}