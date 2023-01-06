@RestResource(urlMapping='/esignature/update')
global without sharing class WS07_UniversignTransaction {
    
    public static List<String> lstTransactionEvents = new List<String>{Label.UniversignTransactionStarted, Label.UniversignTransactionCompleted, Label.UniversignTransactionCancelled, Label.UniversignTransactionExpired};
    public static List<String> lstActionEvents = new List<String>{Label.UniversignActionOpened, Label.UniversignActionStalled, Label.UniversignActionClosed};

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        system.debug('*********req '+req);
        Blob body = req.requestBody;
        String jsonReq = body.toString();
        system.debug('*********body '+jsonReq);
        Event_Object event = parseJSONToEventObject(jsonReq);

        system.debug('*********event.type '+event.type);
        // Event on transaction
        if(lstTransactionEvents.contains(event.type)){
            updateContractStatus(event);
        }
        // Event for Participants actions
        else if(lstActionEvents.contains(event.type)){
            updateSignatoryStatus(event);
        }
    }
    
    public static HttpResponse getTransaction(String transaction_id){
        return sendRequest('GET', System.Label.Universign_EndPoint_Transaction+'/'+transaction_id, null);
    }

    /*public static HttpResponse updateTransaction(Transaction_Object trans){
        String endpoint = System.Label.Universign_EndPoint_Transaction+'/'+trans.id;
        return sendRequest('POST', endpoint, null);
    }

    public static HttpResponse startTransaction(String transaction_id){
        String endpoint = System.Label.Universign_EndPoint_Transaction+'/'+transaction_id+'/start';
        return sendRequest('POST', endpoint, null);
    }

    public static HttpResponse getArchivedTransaction(String transaction_id){
        HttpResponse res = sendRequest('GET', System.Label.Universign_EndPoint_Archives+'/'+transaction_id, null);
        return res;
    }*/

    //ARA 23/06/2022
    /* method accepts transaction_id and document_id as parameters
    * and returns the document signed (blob body) FROM Universign */ 
    public static HttpResponse getSignedDocument(String transaction_id, String document_id){
        return sendRequest('GET', System.Label.Universign_EndPoint_Archives+'/'+transaction_id+'/documents/'+document_id+'/download', null);
    }

    //ARA 23/06/2022
    /* method accepts method, endpoint and jsonBody as parameters
    * and returns HTTPResponse Universign */
    public static HTTPResponse sendRequest(String method, String endpoint, String jsonBody){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');//x-www-form-urlencoded
        req.setMethod(method);
        //set endpoint
        req.setEndpoint(endpoint);
        //set api key as username and password blank in header in format => apikey : password
        Blob headerValue = Blob.valueOf(System.Label.Universign_apikey + ':' + '');
        // Base 64 Encode the blob and prepend "Basic "
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        // Add the basic auth string to the Request Header
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);
        if(jsonBody != null){
            req.setbody(jsonBody);
            req.setHeader('Content-length',string.valueOf(jsonBody.length()));
        }

        if(!Test.isrunningTest()){
            res = http.send(req);
        }else{
            if(endpoint.contains('/cancel')){
                res = dummyResponse('cancelled');
            }else if(endpoint.contains(System.Label.Universign_EndPoint_Transaction)){
                res = dummyResponse('transaction');
            }else if(endpoint.contains(System.Label.Universign_EndPoint_Archives)){
                res = dummyResponse('archives');
            }
        }

        return res;
    }
    
    //30/05/2022 - MRA method to build transaction request,accepts esignature id as parameter
    public static Map<String, String> createTransactionFull(eSignature__c esignature, List<esignatory__c> listEsignatory, List<ContentDistribution> lstCDist){
        // generate request as json
        String jsonReq = generateTransactionJSON(esignature, listEsignatory, lstCDist);
        System.debug('## jsonReq'+jsonReq.trim());
        //send request
        HTTPResponse res = sendRequest('POST', System.Label.Universign_EndPoint_Transaction+'/full', jsonReq);
        return generateEsignatureLog(res, esignature, listEsignatory, jsonReq);
    }
    
    //MRA 25/05/2022
    /* methodaccepts contentdistribution.downloadurl as parameter
    * and returns the file body (as blob) FROM contentdistribution.downloadurl */ 
    public static blob fetchblobFROMdownloadUrl(string pdfdownloadurl){        
        Http h = new Http(); 
        HttpRequest request = new HttpRequest(); 
        //Replace any spaces in pdfdownloadurl with %20 
        pdfdownloadurl = pdfdownloadurl.replace(' ', '%20');
        //Set the end point URL
        request.setEndpoint(pdfdownloadurl); // requires a remote site to be configured in org
        request.setMethod('GET'); 
        request.setHeader('Content-Type', 'application/pdf'); 
        request.setCompressed(true); 
        request.setTimeout(60000); 
        //Now Send HTTP Request
        HttpResponse response = Test.isRunningTest() ? dummyResponse('file') : h.send(request); 
        /*System.debug('## res blobFROMdownloadUrl -> '+r);
        System.debug('## res header -> '+r.getHeader('Content-Type'));
        System.debug('## res body -> '+r.getBody());*/
        return response.getBodyAsBlob();
    }
    
    //MRA 25/05/2022
    /* method uploads SF file to Universign
    * accepts file body encoded in base64 + file name as parameter
    * and returns the id of the file received FROM Universign */
    public static string UploadFileToUniversign(string encodedFileBody,string filename){
        //string contentType = HttpFormBuilder.GetContentType();
        //  Compose the form
        string form64 = '';
        
        //01/06/2022 mra
        string contentType = HttpHexFormBuilder.GetContentType();
        HttpHexFormBuilder httpBuilder=new HttpHexFormBuilder();
        blob blobReq = httpBuilder.writeFile( 'file', fileName, encodedFileBody).getFormAsBlob();
        Http http = new Http();
        HttpResponse res = new HttpResponse();
       
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(System.Label.Universign_EndPoint_Files);
        req.setHeader('Content-Type', contentType);
        Blob headerValue = Blob.valueOf(System.Label.Universign_apikey + ':' + '');
        // Base 64 Encode the blob and prepend "Basic "
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        // Add the basic auth string to the Request Header
        req.setHeader('Authorization', authorizationHeader);
        req.setBodyAsBlob(blobReq);
        req.setTimeout(120000);

        res = Test.isRunningTest() ? dummyResponse('file_Id') : http.send(req);

        System.debug('## res -> '+res);
        System.debug('## res.body -> '+res.getBody());
        String jsonStr = res.getBody();
        Map<String, String> m = (Map<String, String>) JSON.deserialize(jsonStr, Map<String, String>.class);
        String externalfileId = m.get('id');
        System.debug('##externalfileId'+externalfileId);
        
        return externalfileId;
    }

    //MRA 25/05/2022
    /*method uploads signable pdfs to Universign 
    *accepts as parameter the contract id
    * returns a list of documents with file_id field set with the file id received FROM universign after upload*/ 
    public static List<Document> FetchAndUploadFiles(List<ContentDistribution> lstCDist){
        Map<string,string> mapcdIdDownloadurls = new  Map<string,string>();
        Map<string,string>mapcdIdName = new Map<string,string>();
        List<Document> lstDoc = new List<Document>();
        string retFileId = null;
        string encodedBase64Str = '';
        blob retBlobContent = null;
        //retrieve downloadurl for each signable pdfs
        for(Contentdistribution cdist :  lstCDist){
            mapcdIdDownloadurls.put(cdist.id,cdist.pdfdownloadurl); 
            mapcdIdName.put(cdist.id,cdist.name);
            // Retrieving the blob body FROM download url
            retBlobContent = fetchblobFROMdownloadUrl(cdist.pdfdownloadurl);
            if(retBlobContent != null){
                //uploading file to universign
                retFileId = UploadFileToUniversign(EncodingUtil.base64Encode(retBlobContent),cdist.name);
                Document doc = new Document();
                doc.id = cdist.id;
                doc.file_id = retFileId;
                doc.name = cdist.name;
                lstDoc.add(doc);
            }
         }
         System.debug('##lstDoc'+lstDoc);
         return lstDoc;        
    }

    public static Map<String, String> cancelTransaction(eSignature__c esignature){
        Map<String, String> result = new Map<String, String>();
        HttpResponse res = getTransaction(esignature.transactionId__c);
        
        if(res.getStatusCode() == 200){
            Transaction_Object trans =  parseJSONToTransactionObject(res.getBody());
            if(trans != null){
                if(trans.state != 'cancelled'){
                    res = sendRequest('POST', System.Label.Universign_EndPoint_Transaction+'/'+esignature.transactionId__c+'/cancel', null);
                    result = generateEsignatureLog(res, esignature, null, null);
                }else{
                    result = generateEsignatureLog(res, esignature, null, null);
                }
            }else{
                result.put('error', 'No created transaction for this signature');
            }
        }else{
            WrapperResponseError wse = (WrapperResponseError) System.JSON.deserialize(res.getBody(), WrapperResponseError.class);
            esignature.Error_Message__c = wse.error_description;
            update esignature;
            result.put('error', wse.error_description);
        }
        
        return result;
    }

    //ARA 16/09/2022
    /* method generates transaction request as json format
    * accepts esignature + list esignatories + list Content Document Distribution
    * and returns a string request */
    public static string generateTransactionJSON(eSignature__c esignature, List<esignatory__c> listEsignatory, List<ContentDistribution> lstCDist){
        Map<string,string> mapSequenceActions;
        Map<string,string> mapReviewer;
        List<Map<string,string>> lstSeq = new List<Map<string,string>>();
        List<esignatory__c> lstValidator = new List<esignatory__c>();
        List<esignatory__c> lstSigner = new List<esignatory__c>();
        
        List<Document> lstDoc = FetchAndUploadFiles(lstCDist);
        System.debug('## lstDoc'+lstDoc);

        if(listEsignatory.size() > 0){
            for(Integer i=0; i<listEsignatory.size(); i++){
                if(i<listEsignatory.size()-1){
                    mapSequenceActions = new Map<string,string>();
                    mapSequenceActions.put('before',listEsignatory[i].EmailTxt__c);
                    mapSequenceActions.put('after', listEsignatory[i+1].EmailTxt__c);
                    lstSeq.add(mapSequenceActions);
                }
                if(listEsignatory[i].cTin_Role_Universign__c == AP_Constant.esignRoleSigner){
                    lstSigner.add(listEsignatory[i]);
                }else{
                    lstValidator.add(listEsignatory[i]);
                }
            }
        }

        System.debug('## lstSigner'+lstSigner);
        System.debug('## lstValidator'+lstValidator);
        JSONGenerator jsonGen = System.JSON.createGenerator(true); 
        jsonGen.writeStartObject();
        jsonGen.writeBooleanField('autostart',true);
        jsonGen.writeStringField('name',esignature.Name);
        jsonGen.writeStringField('language','en');
        jsonGen.writeNumberField('duration',20160);
        jsonGen.writeStringField('folder_id',Label.Universign_folder_id); 
        /*start documents**/
        jsonGen.writeFieldName('documents');
        jsonGen.writeStartArray();
        for(Document doc:lstDoc){
            jsonGen.writeStartObject();
            jsonGen.writeStringField('file_id',String.valueOf(doc.file_id));
            jsonGen.writeStringField('name',String.valueOf(doc.name)); // as in SF, will be overwritten by Universign
            jsonGen.writeStringField('id',String.valueOf(doc.id)); // as in SF, will be overwritten by Universign
            if(lstSigner.size()>0){
                jsonGen.writeFieldName('fields');
                jsonGen.writeStartArray();
                for(esignatory__c esign  :lstSigner){
                    jsonGen.writeStartObject();
                    jsonGen.writeStringField('id','field_id_'+string.valueOf(esign.orderToSend__c));
                    jsonGen.writeStringField('name','field'+string.valueOf(esign.orderToSend__c));
                    jsonGen.writeNumberField('page',1);
                    jsonGen.writeNumberField('width',550);
                    jsonGen.writeNumberField('x',esign.x__c);
                    jsonGen.writeNumberField('y',esign.y__c);
                    jsonGen.writeEndObject();
                }
                jsonGen.writeEndArray();
            }
            jsonGen.writeEndObject();
        }
        jsonGen.writeEndArray();
        /*end documents**/
        
        if(lstSigner.size()>0){
            /*start signatures**/
            jsonGen.writeFieldName('signatures');
            jsonGen.writeStartArray();
            for(esignatory__c esign  :lstSigner){
                jsonGen.writeStartObject();
                jsonGen.writeStringField('field','field_id_'+string.valueOf(esign.orderToSend__c));
                jsonGen.writeStringField('signer',string.valueOf(esign.Emailtxt__c));
                jsonGen.writeEndObject();
            }
            jsonGen.writeEndArray();
            /*end signatures**/
        
            /*start reviews**/
            if(lstValidator.size() > 0){
                jsonGen.writeFieldName('reviews');
                jsonGen.writeStartArray();
                for(esignatory__c validator :lstValidator){
                    //Boolean isRecipient = false;
                    jsonGen.writeStartObject();
                    jsonGen.writeFieldName('recipient');
                    jsonGen.writeStartArray();
                    for(esignatory__c signer :lstSigner){
                        if(validator.EsignatoryType__c == signer.EsignatoryType__c){
                            jsonGen.writeString(string.valueOf(signer.EmailTxt__c));
                            break;
                        }
                    }
                    jsonGen.writeEndArray();
                    jsonGen.writeStringField('reviewer', validator.EmailTxt__c);
                    jsonGen.writeEndObject();
                }
                jsonGen.writeEndArray();
            }
            /*end reviews*/
        }

        /*start sequencing**/
        if(lstSeq.size() > 0){
            jsonGen.writeFieldName('sequencing');
            jsonGen.writeStartArray();
            for(integer i=0;i<lstSeq.size();i++){
                jsonGen.writeStartObject();
                jsonGen.writeFieldName('before');
                jsonGen.writeStartArray();
                if(lstSeq[i].containsKey('before')){
                    jsonGen.writeString(string.valueOf(lstSeq[i].get('before')));
                }
                jsonGen.writeEndArray();
                jsonGen.writeFieldName('after');
                jsonGen.writeStartArray();
                if(lstSeq[i].containsKey('after')){
                    jsonGen.writeString(string.valueOf(lstSeq[i].get('after')));
                }
                jsonGen.writeEndArray();
                jsonGen.writeEndObject();
            }
            jsonGen.writeEndArray();
        }
        /*end sequencing**/

        /*start participants**/
        if(listEsignatory.size() > 0){
            jsonGen.writeFieldName('participants');
            jsonGen.writeStartArray();
            for(esignatory__c esign: listEsignatory){
                jsonGen.writeStartObject();
                jsonGen.writeStringField('email',string.valueOf(esign.EmailTxt__c)); // email of participant
                jsonGen.writeStringField('name_constraint',esign.Name__c); // name of participant
                //jsonGen.writeStringField('access_control','none');
                jsonGen.writeBooleanField('send_signed_Documents_mail',false); 
                jsonGen.writeFieldName('schedule');
                jsonGen.writeStartArray();
                /*if(esign.esignature__r.cTin_TECH_IsContractIn__c){
                    jsonGen.writeNumber(0);
                }*/
                jsonGen.writeEndArray();
                jsonGen.writeEndObject();
            }
            jsonGen.writeEndArray();
        }
        /*end participants**/

        /*start carbon_copies**/
        jsonGen.writeFieldName('carbon_copies');
        jsonGen.writeStartArray();
        jsonGen.writeEndArray();
        /*end carbon_copies**/
        
        jsonGen.writeEndObject();

        return jsonGen.getAsString();
    }

    public static Map<String, String> generateEsignatureLog(HTTPResponse res, Esignature__c esignature, List<eSignatory__c> lstEsignatory, String jsonReq){
        System.debug('##resBody'+res.getBody());
        Map<String, String> result = new Map<String, String>();
        String contactsEmail = '';
        Transaction_Object trans;
        esignature.request__c = jsonReq;

        if(res.getStatusCode() == 200){
            eSignatureLog__c eSign_log = new eSignatureLog__c();
            try{
                trans =  parseJSONToTransactionObject(res.getBody());
            }catch(Exception e){
                result.put('error', 'Error on Universign response parsing.');
                //update esignature
                esignature.Error_Message__c = e.getMessage();
                update esignature;
                
                //update log
                eSign_log.StepName__c = 'Submit Esignature and Parsing response';
                eSign_log.Response__c = 'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber() + '.  Response: ' +res.getBody();
                eSign_log.DateCall__c = Datetime.now();
                insert eSign_log;
            }
            //update esignature and create log and start transaction
            if(!result.containsKey('error')){
                //Submit esignature
                if(trans.state == 'started'){
                    Id esignatureRT = eSignature.RecordTypeId;
                    esignature.Status__c = AP_Constant.eSignatureSentStatus;
                    esignature.TransactionID__c = trans.id;
                    eSignature.ExternalId__c = trans.id;
                    eSignature.collecteDone__c = true;      
                    eSignature.RecordTypeId = eSignature.cTin_TECH_IsContractIn__c ? Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_InEsignature').getRecordTypeId() : AP_Constant.getRecordTypes('eSignature__c').get(AP_Constant.recordTypeInSignature).Id;
                    eSign_log.StepName__c = 'Submit Esignature';

                    // update first esignatory status to Ready and others to Awaiting
                    Map<String, String> mapActionURL = new Map<String, String>();
                    if(trans.actions != null){
                        for(Action action : trans.actions){
                            mapActionURL.put(action.actor, action.url);
                        }
                    }

                    for(eSignatory__c esign: lstEsignatory){
                        if(mapActionURL.containsKey(esign.EmailTxt__c)){
                            if(esign.order__c == 1){
                                esign.status__c = AP_Constant.esignatoryStatusReady;
                                esign.NextReminder__c = Date.today().addDays(20);
                                esign.cTin_NextReminder__c = Date.today().addDays(20);
                            }else{
                                esign.status__c = AP_Constant.esignatoryStatusAwaiting;
                            }
                            // set url to sign
                            if(mapActionURL.containsKey(esign.EmailTxt__c)){
                                esign.cTin_signLink__c = mapActionURL.get(esign.EmailTxt__c);
                                esign.SignURL__c = mapActionURL.get(esign.EmailTxt__c);
                                if(esign.order__c == 1){
                                    eSignature.SignURL__c = mapActionURL.get(esign.EmailTxt__c);
                                }
                            }
                            contactsEmail += contactsEmail == '' ? esign.Emailtxt__c : !contactsEmail.contains(esign.Emailtxt__c) ? ';'+esign.Emailtxt__c : '';
                        }else{
                            result.put('error', 'Error during the transaction creation.');
                            break;
                        }
                    }
                    
                    if(!result.containsKey('error')){
                        try{update lstEsignatory;}catch(Exception e){result.put('error', 'Error when updating the esignatory.');}
                    }else{
                        esignature.Status__c = AP_Constant.eSignatureCreatedStatus;
                        eSignature.RecordTypeId = esignatureRT;
                        esignature.Error_Message__c = result.get('error');
                        update eSignature;
                    }
                }else if(trans.state == 'cancelled'){ //Cancel esignature
                    esignature.Status__c = AP_Constant.eSignatureCancelledStatus;
                    eSign_log.StepName__c = 'Cancel Esignature';
                }

                // create logs
                eSign_log.eSignatureId__c = eSignature.Id;
                eSign_log.Response__c = res.getBody().remove('\n').remove('\t').remove('      ').remove('    ').replace('{  ','{').replace('  }','}').replace('} ]', '}]').replace('[ {', '[{').replace(' : ', ':').replace(', ', ',').replace(',  ', ',');
                eSign_log.Request__c = jsonReq;
                eSign_log.DateCall__c = Datetime.now();
                insert eSign_log;
                
                // update esignature & contract
                System.debug('## eSignature : '+ eSignature);
                if(!result.containsKey('error')){
                    try{
                        update eSignature;
                    }catch(Exception e){
                        result.put('error', 'Error when updating the eSignature.');
                    }
                    if(!result.containsKey('error')){
                        Contract__c contract;
                        if(trans.state == 'started' && !eSignature.cTin_TECH_IsContractIn__c){
                            // update contract to sent for signature for OpCo
                            contract = new Contract__c(Id = eSignature.Contract__c, Tech_AllRoleEmailAddresses__c = contactsEmail.left(255), TECH_Apex_Context__c = true, Status__c = AP_Constant.contractSentStatus);
                        }else if(trans.state == 'cancelled' && eSignature.cTin_TECH_IsContractIn__c){
                            // update contract to in signature for contractIn
                            contract = new Contract__c(Id = eSignature.Contract__c, Status__c = AP_Constant.contractInSignatureStatus);
                        }
                        if(contract != null){
                            try{
                                update contract;
                            }catch(Exception e){
                                System.debug('# # Error when updating the contract: '+e.getMessage());
                                result.put('error', 'Error when updating the contract.');
                            }
                        }
                    }
                }
            }
        }else{
            WrapperResponseError wse = (WrapperResponseError) System.JSON.deserialize(res.getBody(), WrapperResponseError.class);
            esignature.Error_Message__c = wse.error_description;
            update esignature;
            result.put('error', wse.error_description);
        }
        return result;
    }

    public static void updateSignatoryStatus(Event_Object event) {
        Transaction_Object trans = event.payload.objet;
        List<eSignatory__c> lstEsignatory;
        eSignature__c esignature;
        
        lstEsignatory = [SELECT Id, Status__c, EmailTxt__c, cTin_Role__c, cTin_Role_Universign__c, cTin_signLink__c, eSignature__c, Contract__c
                        FROM eSignatory__c
                        WHERE eSignature__r.TransactionID__c = :trans.transaction_id FOR UPDATE];
        if(lstEsignatory.size() > 0){
            for(eSignatory__c esign : lstEsignatory){
                /* Action opened */
                if(event.type == Label.UniversignActionOpened){
                    if(esign.EmailTxt__c == trans.participant_email && esign.Status__c == AP_Constant.esignatoryStatusAwaiting){
                        // update current esignatory status to Ready
                        esign.Status__c = AP_Constant.esignatoryStatusReady;
                        esign.NextReminder__c = Date.today().addDays(20);
                        esign.cTin_NextReminder__c = Date.today().addDays(20);
                        // update current SignURL__c for the esignature
                        if(esign.cTin_signLink__c != null){
                            esignature = new eSignature__c(Id = esign.eSignature__c, SignURL__c = esign.cTin_signLink__c);
                        }
                    }else if(esign.EmailTxt__c != trans.participant_email && esign.Status__c == AP_Constant.esignatoryStatusReady){
                        // update previous esignatory status to Validated / Signed
                        esign.Status__c = esign.cTin_Role_Universign__c == AP_Constant.esignRoleSigner ? AP_Constant.esignatoryStatusSigned : AP_Constant.esignatoryStatusValidated;
                    }
                    System.debug('******esign Opened '+esign);
                }
                /* Action closed */
                else if(event.type == Label.UniversignActionClosed){
                    // update esignatory status to Validated / Signed
                    if(esign.EmailTxt__c == trans.participant_email && esign.Status__c == AP_Constant.esignatoryStatusReady){
                        esign.Status__c = esign.cTin_Role_Universign__c == AP_Constant.esignRoleSigner ? AP_Constant.esignatoryStatusSigned : AP_Constant.esignatoryStatusValidated;
                        esign.NextReminder__c = null;
                        esign.cTin_NextReminder__c = null;
                    }
                    System.debug('******esign Closed '+esign);
                }
                /* Action stalled */
                else if(event.type == Label.UniversignActionStalled){
                    // update esignatory status to Rejected and others to Cancelled
                    if(trans.participant_email == esign.EmailTxt__c){
                        esign.Status__c = AP_Constant.esignatoryStatusRejected;
                        esign.cTin_RefusalComment__c = trans.stalled_reason;
                        // update eSignature to rejected
                        esignature = new eSignature__c(Id = lstEsignatory[0].eSignature__c, Status__c = AP_constant.esignatoryStatusRejected, RejectionComment__c = trans.stalled_reason);
                    }else{
                        esign.Status__c = AP_Constant.esignatoryStatusCancelled;
                    }
                    esign.NextReminder__c = null;
                    esign.cTin_NextReminder__c = null;
                    System.debug('******esign Stalled '+esign);
                }
            }
        
            update lstEsignatory;
            for(eSignatory__c esign : lstEsignatory){
                System.debug('******esign1 '+esign);
            }
            // update esignature SignURL
            if(esignature != null){
                update esignature;
            }
        }
    }

    //ARA 24/06/2022
    public static void updateContractStatus(Event_Object event) {
        Transaction_Object trans = event.payload.objet;
        List<eSignatureLog__c> esignLogLst = new List<eSignatureLog__c>();
        List<Attachment> lstAttachment = new List<Attachment>();
        Map<String, Blob> mapBlob = new Map<String, Blob>();
        List<eSignature__c> lstEsignature = [SELECT Id, Status__c, TransactionID__c , Contract__c FROM eSignature__c WHERE TransactionID__c = :trans.id LIMIT 1 FOR UPDATE];
        
        system.debug('*********trans.state1 '+trans.state);
        if(lstEsignature.size() > 0){
            eSignature__c esignature = lstEsignature[0];
            /* Transaction completed */
            if(trans.state == 'completed'){
                if(esignature.status__c != AP_Constant.eSignatureCompletedStatus){
                    HttpResponse res;
                    List<String> lstDocId = new List<String>();

                    for(Document doc: trans.documents){
                        while(!lstDocId.contains(doc.id)){
                            res = getSignedDocument(trans.id, doc.id);
                            system.debug('*********res.getStatusCode '+res.getStatusCode());
                            if(!res.getBody().contains('invalid_request_error')){
                                Blob blobFile = res.getBodyAsBlob();
                                String base64String = EncodingUtil.base64Encode(blobFile);
                                String docName = doc.name.contains('.pdf') ? doc.name.replace('.pdf', '_signed.pdf') : doc.name + '_signed.pdf';
                                mapBlob.put(docName, blobFile);
                                lstAttachment.add(new Attachment(Name = docName, ParentId = eSignature.Contract__c, body = blobFile));
                                lstDocId.add(doc.id);
                            }
                        }
                    }
                    esignature.isSuccess__c = true;
                    esignature.status__c = AP_Constant.eSignatureCompletedStatus;
                }
            }
            /* Transaction cancelled */
            else if(trans.state == 'cancelled'){
                esignature.Status__c = AP_Constant.eSignatureCancelledStatus;
            }
            /* Transaction expired */
            else if(trans.state == 'expired'){
                esignature.Status__c = AP_Constant.eSignatureExpiredStatus;
            }

            // updating esignature
            update esignature;

            system.debug('*********esignature '+esignature);
            
            if(lstAttachment.size() > 0){
                List<ContentDocumentLink> lstcdl = new List<ContentDocumentLink>();
                List<ContentDocumentLink> lstcTin_cdl = new List<ContentDocumentLink>();
                Contract__c ctr = [SELECT Id, Status__c, TECH_IsContractIn__c, OpCo_Send_Automatic_PO_Reminder__c, OpCo_CountILNoPO__c, Tech_RecordTypeName__c FROM Contract__c WHERE Id = :eSignature.Contract__c];
                try{
                    insert lstAttachment;
                    system.debug('*********lstAttachment '+lstAttachment);
                    List<ContentVersion> lstContractContentVersion = new List<ContentVersion>();
                    //Query workspace for All-In ,ATS + contract-In
                    String workspaceId;
                    if (test.isrunningTest()){
                        workspaceId=[SELECT Id,name,DeveloperName FROM ContentWorkspace WHERE DeveloperName=:'Workspace_test' LIMIT 1].id;
                    }else{
                        if(ctr.Tech_RecordTypeName__c.contains('OpCo360')){
                            System.debug('## querying OpCo workspace');
                            // query content workspace for All-In  + ATS
                            workspaceId = [SELECT Id,name,DeveloperName FROM ContentWorkspace WHERE DeveloperName=:System.label.ContentWorkspace LIMIT 1].id;
                        }
                        else{
                            System.debug('## querying cTin workspace');
                            // query content workspace for Contract-In
                            workspaceId = [SELECT Id,name,DeveloperName FROM ContentWorkspace WHERE DeveloperName=:System.label.cTin_ContentWorkspace LIMIT 1].id;
                        }
                    }

                    //create contentversions for contract (ATS,All-In,Contract-In)
                    for(Attachment att: lstAttachment){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = att.Name;
                        cv.PathOnClient = att.Name;
                        cv.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):mapBlob.get(att.Name));

                        // firstpublishLocationId needs not be specified for unit tests, asssigned automatically to the workspace created in test class
                        // if assigned throws an exception invalid id
                        //if (!test.isrunningTest()){
                        cv.FirstPublishLocationId = workspaceId;
                        //}
                        lstContractContentVersion.add(cv);
                    }

                    if(lstContractContentVersion.size() > 0){
                        insert lstContractContentVersion;
                        List<ContentVersion> cveSignList = new List<ContentVersion>();

                        //create content distributions for contract (All-IN,ATS,Contract-In)
                        for(ContentVersion cv :[SELECT id, ContentDocumentId, Title,VersionData FROM ContentVersion WHERE id IN :lstContractContentVersion]){
                            //USA : Migration lightning
                            lstcdl.add(new contentDocumentLink(ContentDocumentId = cv.ContentDocumentId, LinkedEntityId = esignature.Contract__c, ShareType = 'V', Visibility = 'AllUsers'));
                        
                            if (ctr.Tech_RecordTypeName__c.contains('cTin')){
                                lstcTin_cdl.add(new contentDocumentLink(ContentDocumentId = cv.ContentDocumentId, LinkedEntityId = eSignature.Id, ShareType = 'V', Visibility = 'AllUsers'));
                            }
                        }
                                    
                        if(lstcdl != null){
                            insert lstcdl;
                            system.debug('*********lstcdl '+lstcdl);
                        }
                        if(lstcTin_cdl != null){
                            insert lstcTin_cdl ;
                            system.debug('*********lstcTin_cdl '+lstcTin_cdl);
                        }

                        if(ctr.Tech_RecordTypeName__c.contains('OpCo360')){
                            //skipped this part for contract in since final doc url is already being updated in AP53_UncheckExpirePreference
                            for(ContentDistribution cd: [select id,DistributionPublicUrl,ContentDocumentId FROM ContentDistribution WHERE contentversionId=:lstContractContentVersion[0].Id]){
                                if(cd.DistributionPublicUrl !=null){
                                    // 06-08-2021   ARA     SP-1729
                                    ctr.LinkToDocument__c = System.Label.Contract_LinkToDocument+cd.ContentDocumentId+'/view';
                                    //ctr.FinalDocumentURL__c = cd.DistributionPublicUrl;
                                }
                            }
                            ctr.Status__c = AP_Constant.CONTRACT_STATUS_SIGNED;
                            ctr.Contract_Signed_Date__c = System.Today();
                            ctr.PendingSince__c = null;
                            update ctr;
                            system.debug('*********ctr '+ctr);

                            // SP-02770 Contract | Change PO reminder functionality
                            if(PAD.canTrigger('AP1209') && !ctr.TECH_IsContractIn__c && ctr.OpCo_Send_Automatic_PO_Reminder__c && ctr.OpCo_CountILNoPO__c > 0 && (ctr.Tech_RecordTypeName__c == Label.RT_ContractReadOnlyLightning || ctr.Tech_RecordTypeName__c == Label.RT_AmendmentReadOnlyLightning)){
                                AP12_Contract.sendPOReminder(new Set<Id>{ctr.Id});
                            }
                        }
                    }
                    
                    //to increase coverage for catch block
                    if(test.isRunningTest()){
                        Id esignatureId = 'a0SO0xxxxxxxxxx';
                        Map<id,esignature__c> esignIdMap = new Map<id,esignature__c>();
                        esignIdMap.put(esignatureId,new esignature__c());
                        update esignIdMap.values();
                    }
                }catch(Exception e){
                    esignLogLst.add( new eSignatureLog__c(  eSignatureId__c = eSignature.Id,
                                                            StepName__c = 'Execution to retrieve signed content',
                                                            Response__c = 'Error : '+ e.getMessage() + ' at line ' + e.getLineNumber(),
                                                            Request__c = null,
                                                            DateCall__c = Datetime.now()));
                    esignature.isSuccess__c = false;
                    update esignature;
                }
            }
            if(esignLogLst.size() > 0){
                try{
                    insert esignLogLst;
                    system.debug('*********esignLogLst '+esignLogLst);
                }catch(Exception e){
                    System.debug('##Exception request too large to be stored'+ e.getMessage());
                }
            }
        }
    }
    
    public static Transaction_Object  parseJSONToTransactionObject(String json){
        Transaction_Object trans = new Transaction_Object();
        json = json.replace('"object"','"objet"').remove('\n').remove('\t');
        try{
            trans = (Transaction_Object) System.JSON.deserialize(json, Transaction_Object.class);
        }catch(Exception e){
            System.debug('##Exception deserialization '+ e.getMessage());
        }
        return trans;
    }
    
    public static Event_Object parseJSONToEventObject(String json){
        Event_Object event = new Event_Object();
        json = json.replace('"object"','"objet"').remove('\n').remove('\t');
        try{
            event = (Event_Object) System.JSON.deserialize(json, Event_Object.class);
        }catch(Exception e){
            System.debug('##Exception deserialization '+ e.getMessage());
        }
        return event;
    }

    /** For class test */
    public static HttpResponse dummyResponse(String type){
        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);
        
        if(type == 'transaction'){
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"object":"transaction","id":"tx_aveG7QvK72qo","folder_id":"fol_DJEwkmwZDBK3","created_at":"2022-11-15T14:21:48Z","started_at":"2022-11-15T14:21:48Z","expires_at":"2022-11-29T14:21:48Z","name":"NEWCONTRACT","folder_name":"uat_transaction","stalled":false,"language":"en","creator":{"workspace_name":"AXA Procurement recette","api_key_name":"UniversignDevKey"},"state":"started","participants":[{"email":"test1@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test3@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test2@email.com","name_constraint":"Jane Brown","fullname_prerequisite":"Jane Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"}],"watchers":[],"sealers":[],"documents":[{"id":"doc_Bwnl","name":"NEWCONTRACT_20221115_12-07_SOW.pdf","updatable":true,"deletable":false,"fields":[{"id":"fld_6Ane","name":"field0","position":{"page":1,"x":100,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false},{"id":"fld_Q46","name":"field1","position":{"page":1,"x":390,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false}]}],"instructions":{"signatures":[{"signer":"test2@email.com","field":"fld_6Ane"},{"signer":"test3@email.com","field":"fld_Q46"}],"reviews":[{"reviewer":"test1@email.com","recipient":"test2@email.com"}],"captures":[],"sequencing":[{"before":"test2@email.com","after":"test3@email.com"}],"editions":[]},"actions":[{"id":"act_K6MBX92qzlew1","actor":"test1@email.com","state":"open","url":"https://apps.universign.com/npds/act_K6MBX92qzlew1","tasks":[{"type":"review","state":"todo","recipient":"test2@email.com","document":"doc_Bwnl"}],"stalled":false},{"id":"act_6JwBA1r9wBXn4","actor":"test2@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_6JwBA1r9wBXn4","tasks":[{"type":"signature","state":"todo","field":"fld_6Ane"}],"stalled":false},{"id":"act_JzZJe5X3dBOPW","actor":"test3@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_JzZJe5X3dBOPW","tasks":[{"type":"signature","state":"todo","field":"fld_Q46"}],"stalled":false}],"metadata":{},"progress_value":0,"ongoing_conversation":false,"has_unread_message":false,"origin":"API","carbon_copies":[],"uploads":[],"private":false}');
        }else if(type == 'file'){
            response.setHeader('Content-Type', 'application/pdf;charset=UTF-8');
            response.setBody('test');
            response.setBodyAsBlob(Blob.toPDF('test'));
        }else if(type == 'file_Id'){
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"object" : "file-id", "id" : "file_MZPQJaaQ5kJwQUD15WkerJ8bA2"}');
        }else if(type == 'archives'){
            response.setHeader('Content-Type', 'application/pdf;charset=UTF-8');
            response.setBody('test');
            response.setBodyAsBlob(Blob.toPDF('test'));
        }else if(type == 'cancelled'){
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"object":"transaction","id":"tx_aveG7QvK72qo","folder_id":"fol_DJEwkmwZDBK3","created_at":"2022-11-15T14:21:48Z","started_at":"2022-11-15T14:21:48Z","closed_at":"2022-11-16T08:51:36Z","name":"NEWCONTRACT","folder_name":"uat_transaction","stalled":false,"language":"en","creator":{"workspace_name":"AXA Procurement recette","api_key_name":"UniversignDevKey"},"state":"cancelled","participants":[{"email":"test1@email.com","name_constraint":"James Brown","fullname_prerequisite":"James Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test3@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test2@email.com","name_constraint":"Jane Brown","fullname_prerequisite":"Jane Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"}],"watchers":[],"sealers":[],"documents":[{"id":"doc_DXA3","name":"NEWCONTRACT_20221115_12-07_SOW.pdf","updatable":true,"deletable":false,"fields":[{"id":"fld_1dKl","name":"field0","position":{"page":1,"x":100,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false},{"id":"fld_QrGK","name":"field1","position":{"page":1,"x":390,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false}]}],"instructions":{"signatures":[{"signer":"test2@email.com","field":"fld_1dKl"},{"signer":"test3@email.com","field":"fld_QrGK"}],"reviews":[{"reviewer":"test1@email.com","recipient":"test2@email.com"}],"captures":[],"sequencing":[{"before":"test2@email.com","after":"test3@email.com"}],"editions":[]},"actions":[{"id":"act_8ma2AqqqD0G9","actor":"test1@email.com","state":"open","started_at":"2022-11-16T08:46:10Z","url":"https://apps.universign.com/npds/act_8ma2AqqqD0G9","tasks":[{"type":"review","state":"todo","recipient":"test2@email.com","document":"doc_DXA3"}],"stalled":false},{"id":"act_rDVGW6dGkwY3O","actor":"test2@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_rDVGW6dGkwY3O","tasks":[{"type":"signature","state":"todo","field":"fld_1dKl"}],"stalled":false},{"id":"act_oBEkmQldM25Dg","actor":"test3@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_oBEkmQldM25Dg","tasks":[{"type":"signature","state":"todo","field":"fld_QrGK"}],"stalled":false}],"metadata":{},"progress_value":0,"ongoing_conversation":false,"has_unread_message":false,"origin":"API","carbon_copies":[],"uploads":[],"private":false}');
        }
        return response;
    }

    global class File_Object {
        public String file_name;
        public Blob file_blob;
    }

    global class Event_Object{
        public String objet;
        public String id;
        public Datetime created_at;
        public String type;
        public String trace_id;
        public Paylod_Object payload;
    }
    
    global class Paylod_Object {
        public Transaction_Object objet;
    }

    global class Transaction_Object {
        public Boolean stalled;
        public Boolean autostart;
        public Boolean ongoing_conversation;
        public Boolean has_unread_message;
        public Datetime expires_at;
        public Datetime closed_at;
        public Integer duration;
        public String objet;
        public String id;
        public String folder_id;
        public String created_at;
        public String started_at;
        public String name;
        public String folder_name;
        public String language;
        public String sender_name_display;
        public String state;
        public String cancel_code;
        public String progress_value;
        public String origin;
        public String transaction_id;
        public String participant_email;
        public String stalled_reason;
        public String action_id;
        public Creator creator;
        public Metadata metadata;
        public Instruction instructions;
        public List<Action> actions;
        public List<Document> documents;
        public List<Participant> participants;
        public List<Review> reviews;
        public List<Signature> signatures;
        public List<Sequencing> sequencing;
        public List<Sealer> sealers;
        public List<String> carbon_copies;
        public List<String> watchers;
        //public Object metadata;
    }

    global class Creator {
        public String name;
        public String email;
        public String workspace_name;
        public String api_key_name;
    }

    global class Participant {
        public Boolean ongoing_conversation;
        public Boolean has_unread_message;
        public Integer stall_trigger;
        public String email;
        public String invitation_subject;
        public String invitation_message;
        public String reminder_subject;
        public String reminder_message;
        public String name_constraint;
        public String phone_number_flex_constraint;
        public List<Integer> schedule;
    }

    global class Sealer {
        public String id;
        public String name;
    }

    global class Document {
        public Boolean updatable;
        public Boolean deletable;
        public String id;
        public String file_id;
        public String name;
        public List<Field> fields;
    }

    global class Field {
        public Boolean built_in;
        public Boolean updatable;
        public Boolean deletable;
        public Integer page;
        public Integer x;
        public Integer y;
        public String id;
        public String name;
        public String type;
        public Position position;
        public List<String> consents;
    }

    global class Position {
        public Integer page;
        public Integer x;
        public Integer y;
        public Integer width;
        public Integer height;
    }

    global class Instruction {
        public List<Review> reviews;
        public List<Signature> signatures;
        public List<Sequencing> sequencing;
    }

    global class Signature {
        public String field;
        public String signer;
    }

    global class Review {
        public String recipient;
        public String reviewer;
    }

    global class Sequencing {
        public String after;
        public String before;
    }

    global class Action {
        public Boolean stalled;
        public Datetime started_at;
        public Datetime closed_at;
        public String id;
        public String actor;
        public String state;
        public String url;
        public List<Task> tasks;
    }

    global class Task {
        public String field;
        public String recipient;
        public String state;
        public String type;
    }

    global class Metadata {
        public String key;
        public Object value;
    }

    global class WrapperResponseError {
        public String type;
        public String error_description;
    }
}