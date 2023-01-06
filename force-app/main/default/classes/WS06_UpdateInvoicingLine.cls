@RestResource(urlMapping='/invoicingLine/update')
global with sharing class WS06_UpdateInvoicingLine {
/**
 * @description       : This class will generate a json body from contract and invoices then will send 
 *                      the information to ESG. ESG will then acknowledge, if all format and authentication is ok
 *                      NOTE : WE used map instead of wrapper class for the object to json method because the CURRENCY 
 *                       attribute is unfortunately reserved keyword.
 * @author            : VMU
 * @group             : SC
 * @last modified on  : 09-03-2022
 * @last modified by  : ARA
 * 
 -- Maintenance History: 
 --
 -- Date         Name  Version  Remarks 
 -- -----------  ----  -------  ------------------------
 -- 10-20-2021    VMU    1.0      Initial version
 -- 12-09-2021    ARA    2.0      SP-02998 limit PS Log Error_Message__c to 255 characters
 -- 09-03-2022    ARA    3.0      SP-03415 Add field Source__c in log
 *-------------------------------------------------------
**/
    @HttpPost
    global static List<WrapperResponse> doPost(RequestWrapper SALES_ORDERSResponse) {
        System.debug('*** jsonrequest:' + SALES_ORDERSResponse);

        List<WrapperResponse> lstResponses = new List<WrapperResponse>();
        map<string, Item3> mapORDER_ITEM3 = new map<string, Item3>();
        map<Id, Contract__c> mapContract = new map<Id, Contract__c>();
        Map<Id, PLanned_Invoicing_Line__c> mapInvoicingLines = new Map<Id, PLanned_Invoicing_Line__c>();
        Set<string> setInvoicingLineId = new Set<string>();
        map<string, Log__c> mapLogs = new map<string, Log__c>();
        map<string, string> mapET_DOCS = new map<string, string>();
        map<string, string> mapET_LOG = new map<string, string>();
        map<string, string> mapORDER_ITEM = new map<string, string>();
        map<string, string> mapORDER_NUMBER = new map<string, string>();
        map<string, string> mapERROR_MESSAGE = new map<string, string>();
        map<string, string> mapMSG_TYPE = new map<string, string>();
        PLanned_Invoicing_Line__c pil;
    

        if(SALES_ORDERSResponse != null){

            ET_LOG ET_LOG = SALES_ORDERSResponse.ET_LOG;
            ET_DOCS ET_DOCS = SALES_ORDERSResponse.ET_DOCS;

            System.debug('** ET_LOG object:' + ET_LOG);
            System.debug('** ET_DOCS object:' + ET_DOCS);

            if(ET_LOG != null && ET_LOG.item != null){
                for(Item3 item: ET_DOCS.item){
                    if(item.INVOICING_LINE_ID != null && item.INVOICING_LINE_ID != ''){
                        mapORDER_ITEM3.put(item.INVOICING_LINE_ID, item);
                    }
                }

                for(Item4 item4: SALES_ORDERSResponse.ET_LOG.item){
                    Item3 item3 = mapORDER_ITEM3.get(item4.INVOICING_LINE_ID);
                    if(item4.MSGTYPE  == 'S'){
                        //Create success log for each contract
                        if(!mapLogs.containsKey(item4.CONTRACT_ID)){
                            mapLogs.put(item4.CONTRACT_ID, new log__c(
                                Call_Status__c      = item4.MSGTYPE, 
                                Date_of_log__c      = System.now(), 
                                // 09-12-2021 ARA
                                Source__c = AP_Constant.PS_FLOW_2,
                                Error_Message__c = AP_Constant.PS_SUCCESS,
                                Contract__c = item4.CONTRACT_ID,
                                Response_ET_DOC__c  = String.valueOf(ET_DOCS), 
                                Response_ET_LOG__c  = String.valueOf(ET_LOG),
                                LastPSLog__c = true
                            ));

                            System.debug('*** Log with success:' + mapLogs);
                        }
                        System.debug('*** item3:' + item3);
                        //Get invoice lines in success
                        if(item3 != null){
                            System.debug('*** item3:' + item3);
                            mapORDER_ITEM.put(item3.INVOICING_LINE_ID, item3.SALES_ORDER_ITEM);
                            mapORDER_NUMBER.put(item3.INVOICING_LINE_ID, item3.SALES_ORDER_NUMBER);
                            pil = new PLanned_Invoicing_Line__c(
                                id = item3.INVOICING_LINE_ID, 
                                isInPS__c = true, 
                                SO__c = item3.SALES_ORDER_NUMBER, 
                                ITEM__c = item3.SALES_ORDER_ITEM, 
                                TECH_SynchroSAP__c = true, 
                                Tech_UpdatedByPS__c = true,
                                Contract2__c = item4.CONTRACT_ID
                            );

                            mapInvoicingLines.put(pil.Id, pil);
                            setInvoicingLineId.add(item3.INVOICING_LINE_ID);
                        }

                        //Get contract in success
                        mapContract.put(item4.CONTRACT_ID, new Contract__c(Id = item4.CONTRACT_ID, Peoplesoft_Sync__c = true, Tech_isSendingToPS__c = false, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                    
                    }else if(item4.MSGTYPE  == 'E'){
                        if(string.isnotblank(item4.INVOICING_LINE_ID)){
                            //Create error log for each contract
                            if(!mapLogs.containsKey(item4.CONTRACT_ID)){
                                mapLogs.put(item4.CONTRACT_ID, new log__c(
                                    Call_Status__c      = item4.MSGTYPE, 
                                    Date_of_log__c      = System.now(), 
                                    // 09-12-2021 ARA
                                    Source__c = AP_Constant.PS_FLOW_2,
                                    Error_Message__c    = ('Error: ' + item4.ERROR_MESSAGE).left(255), 
                                    Contract__c = item4.CONTRACT_ID,
                                    Response_ET_DOC__c  = String.valueOf(ET_DOCS), 
                                    Response_ET_LOG__c  = String.valueOf(ET_LOG),
                                    LastPSLog__c = true
                                ));

                                System.debug('*** Log with error:' + mapLogs);
                            }
                            //Get invoice lines in error
                            if(item3 != null){
                                if(!mapInvoicingLines.containsKey(item3.INVOICING_LINE_ID)){
                                    mapORDER_ITEM.put(item3.INVOICING_LINE_ID, item3.SALES_ORDER_ITEM);
                                    mapORDER_NUMBER.put(item3.INVOICING_LINE_ID, item3.SALES_ORDER_NUMBER);
                                    mapInvoicingLines.put(item3.INVOICING_LINE_ID, new Planned_Invoicing_Line__c(
                                        id                              = item3.INVOICING_LINE_ID,
                                        Contract2__c                    = item3.CONTRACT_ID,
                                        Connexion_Error__c              = 'Connection to PeopleSoft OK',
                                        SAP_Synchronisation_Error__c    = item4.ERROR_MESSAGE
                                    ));
                                }
                            }
                        }else{
                            //No response from PS
                            mapMSG_TYPE.put(item4.CONTRACT_ID, item4.MSGTYPE);
                            mapERROR_MESSAGE.put(item4.CONTRACT_ID, item4.ERROR_MESSAGE);
                            mapET_DOCS.put(item4.CONTRACT_ID, String.valueOf(ET_DOCS));
                            mapET_LOG.put(item4.CONTRACT_ID, String.valueOf(ET_LOG));
                        }

                        //Get contract in error
                        mapContract.put(item4.CONTRACT_ID, new Contract__c(Id = item4.CONTRACT_ID, Peoplesoft_Sync__c = false, Tech_isSendingToPS__c = false, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                    }    
                    System.debug('*** mapERROR_MESSAGE1:' + mapERROR_MESSAGE); 
                }

                //Set log and update IL for blank IL Id from PS
                if(mapERROR_MESSAGE != null && !mapERROR_MESSAGE.isEmpty()){
                    List<Planned_Invoicing_Line__c> invalidILs = [  SELECT id, Contract2__c, ADV_GoNoGo__c, Connexion_Error__c, SAP_Synchronisation_Error__c
                                                                    FROM Planned_Invoicing_Line__c
                                                                    WHERE Contract2__c IN :mapERROR_MESSAGE.keyset()
                                                                    AND Status__c = '01'
                                                                    AND TECH_SynchroSAP__c = false ];

                    for(Planned_Invoicing_Line__c invalidIL : invalidILs){
                        string contractId = invalidIL.Contract2__c;
                        contractId = contractId.substring(0,15);
                        System.debug('*** mapERROR_contractId:' + contractId);

                        if(!mapInvoicingLines.containsKey(invalidIL.id)){
                            mapInvoicingLines.put(invalidIL.id, new Planned_Invoicing_Line__c(
                                id                              = invalidIL.id,
                                Contract2__c                    = contractId,
                                Connexion_Error__c              = 'Connection to PeopleSoft OK',
                                SAP_Synchronisation_Error__c    = mapERROR_MESSAGE.get(contractId)
                            ));
                        }
                        System.debug('*** mapERROR_MESSAGE:' + mapERROR_MESSAGE.get(contractId));

                        if(!mapLogs.containsKey(contractId)){
                            mapLogs.put(contractId, new log__c(
                                Call_Status__c      = mapMSG_TYPE.get(contractId), 
                                Date_of_log__c      = System.now(), 
                                // 09-12-2021 ARA
                                Source__c = AP_Constant.PS_FLOW_2,
                                Error_Message__c    = ('Error: ' + mapERROR_MESSAGE.get(contractId)).left(255), 
                                Contract__c         = contractId, 
                                Response_ET_DOC__c  = mapET_DOCS.get(contractId), 
                                Response_ET_LOG__c  = mapET_LOG.get(contractId),
                                LastPSLog__c = true
                            ));

                            System.debug('*** Log for Invalid IL:' + mapLogs);
                        }
                        
                        mapContract.put(contractId, new Contract__c(Id = contractId, Peoplesoft_Sync__c = false, Tech_isSendingToPS__c = false, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                    }
                }
            }
            
            System.debug('##mapInvoicingLines'+mapInvoicingLines);
            
            //Update Invoicing lines
            if (mapInvoicingLines.size() > 0){
             System.debug('#1');
                String errorMessage = '';
                List<PLanned_Invoicing_Line__c> lstInvoicingLines = new list<PLanned_Invoicing_Line__c>();
                Map<Id, PLanned_Invoicing_Line__c> mapPIL = new Map<Id, PLanned_Invoicing_Line__c>();
                System.debug('##setInvoicingLineId'+setInvoicingLineId);
                if(setInvoicingLineId.size() > 0){
                    mapPIL = new Map<Id, PLanned_Invoicing_Line__c>([SELECT Id, Status__c, Tech_UpdatedByPS__c, Contract2__c FROM Planned_Invoicing_Line__c WHERE Id IN:setInvoicingLineId]);
                }

                //Set IL status
                for(PLanned_Invoicing_Line__c invoicingLine:mapInvoicingLines.values() /*[SELECT Id, Contract2__c, SO_ITEM__c, SO__c, Status__c, 
                Tech_UpdatedByPS__c FROM Planned_Invoicing_Line__c WHERE Id IN:mapInvoicingLines.keyset()]*/){
                    if(mapPIL != null && mapPIL.containsKey(invoicingLine.Id)){
                        if(mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_DRAFT){
                            invoicingLine.Status__c = AP_Constant.INVLINE_STATUS_INVOICING_VALIDATION;
                        }
                        /*if(mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_INVOICED || mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_PAID){
                            invoicingLine.Tech_UpdatedByPS__c = (mapPIL.get(invoicingLine.Id).Tech_UpdatedByPS__c ? false : true);
                        }*/
                    }
                    lstInvoicingLines.add(invoicingLine);
                }
                
                Database.SaveResult[] lstInvoiceUpdated = Database.update(lstInvoicingLines, false);
                System.debug('*** lstInvoiceUpdated:' + lstInvoiceUpdated);

                for(integer j=0;j<lstInvoicingLines.size();j++){
                    System.debug('lstInvoicingLines[j].Contract2__c'+lstInvoicingLines[j].Contract2__c);
                    System.debug('lstInvoicingLines[j].id'+lstInvoicingLines[j].id);
                    System.debug('lstInvoicingLines[j].SO__c'+lstInvoicingLines[j].SO__c);
                    System.debug('lstInvoicingLines[j].ITEM__c'+lstInvoicingLines[j].ITEM__c);
                    
                    WrapperResponse response = new WrapperResponse();
                    response.CONTRACT_ID = lstInvoicingLines[j].Contract2__c;
                    response.INVOICING_LINE_ID = lstInvoicingLines[j].id;
                    response.SALES_ORDER_NUMBER = mapORDER_NUMBER.get(lstInvoicingLines[j].Id);
                    response.SALES_ORDER_ITEM = mapORDER_ITEM.get(lstInvoicingLines[j].Id);
                    //response.SALES_ORDER_NUMBER = lstInvoicingLines[j].SO__c;
                    //response.SALES_ORDER_ITEM = lstInvoicingLines[j].ITEM__c;

                    if(lstInvoiceUpdated[j].isSuccess()){
                        response.NOTIFICATION_PROCESSING_STATUS = 'OK';
                        System.debug('##sucess');
                    }
                    else{
                        for(Database.Error err : lstInvoiceUpdated[j].getErrors()) {
                            errorMessage += err.getMessage()+' ';
                            System.debug('The following error has occurred.');                   
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                        response.NOTIFICATION_PROCESSING_STATUS = 'KO';
                        response.ERROR_LOG = errorMessage+'.';
                    }
                    System.debug('response: '+response);
                    lstResponses.add(response);
                }
            }
            
            //Insert lstLog;
            if(mapLogs.size() > 0 && (!Test.isRunningTest())){
                System.debug('*** inserting logs'); 
                //insert mapLogs.values();
                ////VMU 09/11/21 - Do not allow others errors (from triggers) preventing the log to be created
                System.debug('*** log values' + mapLogs.values());
                Database.SaveResult[] lstNewLogs = Database.insert(mapLogs.values(), false); 
                System.debug('*** After inserting logs');               
                for (Database.SaveResult sr : lstNewLogs) {                    
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {  
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                    }                    
                }
            }
            
            //Update contract
            if (mapContract.size() > 0) {
                System.debug('## updating contracts'); 
                //update mapContract.values();
                //VMU 09/11/21 - Do not allow others errors (from triggers) preventing the log to be created
                Database.SaveResult[] lstUpdContract = Database.update(mapContract.values(), false);
                integer i = 0;
                for (Database.SaveResult sr : lstUpdContract) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            //create a response only if error so that peoplesoft may be aware
                            WrapperResponse response = new WrapperResponse();
                    		response.CONTRACT_ID = (mapContract.values())[i].Id;
                            response.NOTIFICATION_PROCESSING_STATUS = 'KO';
                        	response.ERROR_LOG = err.getMessage();
                            lstResponses.add(response);
                            
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                    }
                    else{
                        WrapperResponse response = new WrapperResponse();
                        response.CONTRACT_ID = (mapContract.values())[i].Id;
                        response.NOTIFICATION_PROCESSING_STATUS = 'OK'; 
                        lstResponses.add(response);
                    }
                    i++;
                }
                            }
            System.debug('lstResponses: '+lstResponses);        
        }
       
        return lstResponses;
    }

    global class WrapperResponse{
        public String CONTRACT_ID;
        public String INVOICING_LINE_ID;
        public String SALES_ORDER_NUMBER;
        public String SALES_ORDER_ITEM;
        public String NOTIFICATION_PROCESSING_STATUS;
        public String ERROR_LOG;
    }

    global class RequestWrapper {
        public ET_DOCS ET_DOCS;
        public ET_LOG ET_LOG;
    }

    global class ET_LOG {
        public item4[] item;
    }
    
    global class ET_DOCS {
        public item3[] item;
    }

    global class Item3 {
        public String CONTRACT_ID;
        public String INVOICING_LINE_ID;
        public String SALES_ORDER_NUMBER;
        public String SALES_ORDER_ITEM;
    }

    global class Item4 {
        public String CONTRACT_ID;
        public String INVOICING_LINE_ID;
        public String SEQ;
        public String MSGTYPE;
        public String ERROR_MESSAGE;
    }   
}