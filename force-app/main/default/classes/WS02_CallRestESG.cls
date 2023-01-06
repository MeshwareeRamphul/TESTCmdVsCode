/**
 * @description       : This class will generate a json body from contract and invoices then will send 
 *                      the information to ESG. ESG will then acknowledge, if all format and authentication is ok
 *                      NOTE : WE used map instead of wrapper class for the object to json method because the CURRENCY 
 *                       attribute is unfortunately reserved keyword.
 * @author            : VMU
 * @group             : SC
 * @last modified on  : 09-03-2022
 * @last modified by  : ARA
  
 -- Maintenance History: 
 --
 -- Date         Name  Version  Remarks 
 -- -----------  ----  -------  ------------------------
 -- 20-10-2021    VMU    1.0      Initial version
 -- 18-11-2021    VMU    2.0      Rework the system to generate distinct body per contract and send them seperately
 -- 09-12-2021    ARA    3.0      SP-02998 limit PS Log Error_Message__c to 255 characters
 -- 09-03-2022    ARA    4.0      SP-03415 Add field Source__c in log
 *-------------------------------------------------------
**/
public  without sharing class WS02_CallRestESG {
    
    //call status values
    private String errorMsg;
    private boolean isErrorLog = false;
    private static boolean isSentToPS = false;
    private map<id,string> mapContractIdJsonBody;
    public map<id,List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo;

    public String getErroMessage(){
        return errorMsg;
    }
    public Boolean getErrorLog(){
        return isErrorLog;
    }
    public WS02_CallRestESG(map<id,List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo){
        System.debug(LoggingLevel.INFO, '## Start of WS02_CallRestESG ');
        errorMsg = '';
        this.mapInvoiceLineInfo = mapInvoiceLineInfo;
        //now generate the payload
        mapContractIdJsonBody = generatePayload();
        //send the request
        sendRequest();
    }
    /**
     * This method will generate the required payload in JSON format
     */
    public map<id,string> generatePayload(){
        System.debug(LoggingLevel.INFO, '## Start generation of JSON payload');

        map<id,string> lstContractJson = new map<id,string>();
        Pattern forbiddenChar = Pattern.compile(system.label.forbiddenCharSAP);
        
        try{
            
        
            for(id contractId:mapInvoiceLineInfo.keyset()){
				//for each contract generate an object starting with the ZSD_SALESFORCE_SALES_ORDERS node
				Map<Id, Planned_Invoicing_Line__c> mapInvoiceLines = new Map<Id, Planned_Invoicing_Line__c>();
				map<string,Object> ZSD_SALESFORCE_SALES_ORDERS = new map<string,Object>();
				map<string,Object> item = new map<string,Object>();
				map<string,Object> MSGHEADER1 = new map<string,Object>();
				list<Object> MSGHEADERS = new list<Object>();
                List<Planned_Invoicing_Line__c> lstInvoiceLines = mapInvoiceLineInfo.get(contractId);
                list<Object> MSGITEMS = new list<Object>();
                map<string,Object> MSGITEM;
                //create a contract node
                map<string,Object> MSGHEADER = new map<string,Object>();
    
                for(Integer i=0;i<lstInvoiceLines.size();i++){
                    system.debug('## processing invoice line id :' +lstInvoiceLines[i].Id );
                    
                    mapInvoiceLines.put(lstInvoiceLines[i].Id, lstInvoiceLines[i]);
                    MSGITEM = new map<string,Object>(); //reset the invoice line tag for each invoice
    
                    if(i==0){
                       //MSGHEADER.put('SALES_ORGANIZATION','ATSFR'); 
                       if(lstInvoiceLines[i].SAP_Account_Number__c==null){
                           MSGHEADER.put('SOLD_TO_PARTY','');
                           MSGHEADER.put('SHIP_TO_PARTY','');
                       }
                       else{
                            MSGHEADER.put('SHIP_TO_PARTY',lstInvoiceLines[i].SAP_Account_Number__c);
                            MSGHEADER.put('SOLD_TO_PARTY',lstInvoiceLines[i].SAP_Account_Number__c);
                       }
                        
                        MSGHEADER.put('SALES_ORGANIZATION',lstInvoiceLines[i].Contract2__r.TECH_PS_SalesOrganization__c);
                        MSGHEADER.put('PO_NUMBER',(lstInvoiceLines[i].Contract2__r.Tech_MSARef__c != null ? lstInvoiceLines[i].Contract2__r.Tech_MSARef__c : '-'));
                        //cannot be null else exception occurs
                        //MSGHEADER.put('CONTACT_PERSON',(lstInvoiceLines[i].Customer_Operational_Contact__c != null ? lstInvoiceLines[i].Customer_Operational_Contact__c : ''));                   
    
                        if (lstInvoiceLines[i].Solution__c != null){
                            String solution = parseString(lstInvoiceLines[i].Solution__c, forbiddenChar);
                            solution = solution.startsWith('Product - Out of Catalog(') ? solution.replace('Product - Out of Catalog(','').removeEnd(')') :solution;
                            MSGHEADER.put('SOLUTION', (solution.length() > 40) ? solution.substring(0, 40) : solution);
                        }
                        else{
                            MSGHEADER.put('SOLUTION', 'GENAMT');
                        }
                        MSGHEADER.put('START_DATE', lstInvoiceLines[i].Contract_Start_Date__c != null ? buildDateFormat(lstInvoiceLines[i].Contract_Start_Date__c) : '');
                        MSGHEADER.put('END_DATE',lstInvoiceLines[i].Contract_End_Date__c != null ? buildDateFormat(lstInvoiceLines[i].Contract_End_Date__c) : '');
                        MSGHEADER.put('CONTRACT_ID',lstInvoiceLines[i].Contract2__c);
    
                        if(string.valueOf(lstInvoiceLines[i].Contract2__c).length() > 15){
                            MSGHEADER.put('CONTRACT_ID',string.valueOf(lstInvoiceLines[i].Contract2__c).substring(0, 15));
                        }
                        
                        MSGHEADER.put('TEXT1',parseString(lstInvoiceLines[i].Contract2__r.ContractNumber__c, forbiddenChar));
                       
                        if(lstInvoiceLines[i].Contract2__r.Status__c == 'Cancelled' || lstInvoiceLines[i].Contract2__r.Status__c == 'Resiliated'){
                            MSGHEADER.put('TEXT2','CLOSED');
                        }
                        else{
                            MSGHEADER.put('TEXT2','');
                        }
                        MSGHEADER.put('TEXT3',parseString(lstInvoiceLines[i].Contract2__r.name, forbiddenChar));
                        MSGHEADER.put('TEXT4','');
                    }
    
                    if(lstInvoiceLines[i].N_Purchase_Order__c != '' && lstInvoiceLines[i].N_Purchase_Order__c != null){
                        MSGITEM.put('PO_NUMBER_ITEM',lstInvoiceLines[i].N_Purchase_Order__c);
                    } else if (lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c != '' && lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c != null) {
                        MSGITEM.put('PO_NUMBER_ITEM',lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c);
                    } else{
                        MSGITEM.put('PO_NUMBER_ITEM','-');
                    }
                    MSGITEM.put('TARGET_QUANTITY','1');
                    MSGITEM.put('UNIT_OF_MEASURE','AMT');
    
                    if (lstInvoiceLines[i].Activity_Type__c == null){
                        MSGITEM.put('DESCRIPTION','');
                    }
                    else{
                        MSGITEM.put('DESCRIPTION',parseString(lstInvoiceLines[i].Activity_Type__c, forbiddenChar));
                    }
                    MSGITEM.put('CURRENCY',lstInvoiceLines[i].ViewCurrency__c);
                    MSGITEM.put('WBS_ELEMENT',(lstInvoiceLines[i].Master_WBS_Structure__c != null? lstInvoiceLines[i].Master_WBS_Structure__r.Name : ''));
                    MSGITEM.put('AMOUNT_MANUAL_PRICE',String.valueOf(lstInvoiceLines[i].AmountIL__c));
                    MSGITEM.put('BILLING_DATE',(lstInvoiceLines[i].Inv_Predefined_Date__c !=null) ? buildDateFormat(lstInvoiceLines[i].Inv_Predefined_Date__c) :  '');
                    MSGITEM.put('INVOICING_LINE_ID',lstInvoiceLines[i].id);
                    MSGITEM.put('INVOICE_STATUS',String.valueOf(lstInvoiceLines[i].Status__c));
                    //To be mapped on the correct fields of invoice
                    MSGITEM.put('START_DATE',lstInvoiceLines[i].StartDate__c != null ? buildDateFormat(lstInvoiceLines[i].StartDate__c) : '');
                    MSGITEM.put('END_DATE',lstInvoiceLines[i].EndDate__c != null ? buildDateFormat(lstInvoiceLines[i].EndDate__c) : '');
                    //system.debug('## invoice contact person  :' + lstInvoiceLines[i].Customer_contact__c);
                    //MSGITEM.put('CONTACT_PERSON',(lstInvoiceLines[i].Customer_contact__c!= null) ? lstInvoiceLines[i].Customer_contact__r.Name : '');
                    system.debug('******* '+lstInvoiceLines[i].Customer_contact_name__c);
                    MSGITEM.put('CONTACT_PERSON',(lstInvoiceLines[i].Customer_contact_name__c!= null) ? String.valueOf(lstInvoiceLines[i].Customer_contact_name__c) : '');
                    //add to list of invoices
                    MSGITEMS.add(MSGITEM);
                }
                MSGHEADER.put('MSGITEM',MSGITEMS);
                MSGHEADERS.add(MSGHEADER);
				MSGHEADER1.put('MSGHEADER',MSGHEADERS);
				item.put('item',MSGHEADER1);
				ZSD_SALESFORCE_SALES_ORDERS.put('ZSD_SALESFORCE_SALES_ORDERS',item);
				//adding the big ZSD_SALESFORCE_SALES_ORDERS as a serialize json string per contract id
			    lstContractJson.put(contractId,JSON.serialize(ZSD_SALESFORCE_SALES_ORDERS));
            }
        }
        catch(exception e){
            system.debug('## error is :' + e.getMessage());
            system.debug('## error cause :' + e.getCause());
            system.debug('## error line :' + e.getLineNumber());
        }
        return lstContractJson;
    }   
    /**
     * This method will execute the request
     */
    public void sendRequest(){
        system.debug('## Sending request');
        //call method send request here        
        list<REST_WS_Setting__mdt> setting = [SELECT Endpoint__c,Certificate__c FROM REST_WS_Setting__mdt WHERE Active__c = true limit 1];
        //get the Maam token
        list<MaaMAuthToken__c> tokenManager = [select Access_token__c from MaaMAuthToken__c limit 1];

        List<Contract__c> lstContract = new List<Contract__c>();
		List<Log__c> lstLog = new List<Log__c>();
        Http httpCls = new Http();        
        httpResponse response;
        Map<String, Object> result;
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type','application/json'); 
        request.setHeader('Authorization','Bearer '+ tokenManager[0].Access_token__c);
        if(String.isNotEmpty(setting[0].Certificate__c)) request.setClientCertificateName(setting[0].Certificate__c); 
        request.setEndpoint(setting[0].Endpoint__c);
        request.setMethod('POST');
        request.setTimeout(2 * 60 * 1000);
        
        //now do the callout
        try{
			for(Id cid : mapContractIdJsonBody.keySet()){
				system.debug('## sending request for contract ' + cid);
				string body = mapContractIdJsonBody.get(cid);
				request.setBody(body);
				//sending the json to the request body
				response = httpCls.send(request);
				result = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
				//Check if web service run successfully
				if(response.getStatusCode() == 200){
					system.debug('## status 200');
					//mark contract as acknowledged
					lstContract.add(new Contract__c(Id = cid, PeopleSoftConnectionMessage__c = 'Received and ready to be handled by PeopleSoft'));					
					
					//errorMsg = 'Success: ' + response.getStatusCode() + ' ' + response.getStatus();
					lstLog.addAll(createLog(cid, AP_Constant.PS_FLOW_1, response.getStatusCode() + ' ' + response.getStatus(), 'S'));
					System.debug('*** body response:' + body);
				}
				else{
					system.debug('## Status is :' + response.getStatusCode());
                    // Sending error and Contract not sent to PS
                    lstContract.add(new Contract__c(Id = cid, Tech_isSendingToPS__c = false));
					errorMsg = 'Status ' + response.getStatusCode() + ' ' + response.getStatus();
					if(result.containsKey('Exception')) errorMsg += ' Details : ' + string.valueOf(result.get('Exception'));
					else if(result.containsKey('STATUS_MESSAGE')) errorMsg = (String)result.get('STATUS_MESSAGE');
					lstLog.addAll(createLog(cid, AP_Constant.PS_FLOW_1, errorMsg, 'E'));
				}
			}
			//updating contracts
			update lstContract;
			//now insert logs
			insert lstLog;
        }
        catch(exception e){
            System.debug('## error :' + e.getMessage());
            isErrorLog = true;
            errorMsg = e.getMessage();
            lstContract = new List<Contract__c>();
            for(Id ctrId : mapInvoiceLineInfo.keySet()){
                lstLog.addAll(createLog(ctrId, AP_Constant.PS_FLOW_1, e.getMessage(), 'E'));
                lstContract.add(new Contract__c(Id = ctrId, Tech_isSendingToPS__c = false, PeopleSoftConnectionMessage__c = 'Connection to Peoplesoft OK'));
            }
            update lstContract;
			insert lstLog;
        }
    }

    /**
     * This method will create logs upon error
     */
    public List<Log__c> createLog(String ctrId, String source, String error, string callStatus){
        system.debug('## creating logs');
        List<Log__c> lstLog = new List<Log__c>();
        String request2 = '';
        String request1 = mapContractIdJsonBody.get(ctrId);

        if(request1.length() > 131072){
            request1 = request1.substring(0, 131072);
            request2 = request1.substring(131072, request1.length());
            if(request2.length() > 131072){
                request2 = request2.substring(0, 131072);
            }
        }
        
        lstLog.add(new log__c(
                                Call_Status__c = callStatus
                                , Date_of_log__c = System.now()
                                // 09-12-2021 ARA
                                , Source__c = source
                                , Error_Message__c = error.left(255)
                                , Contract__c = ctrId
                                , Request__c = request1
                                , Request_part_2__c = request2
                                , LastPSLog__c = true
                            ));

        return lstLog;
    }

    /**
     * This method will format the given date as needed
     */
    public static String buildDateFormat(Date ilDate){
        system.debug('## buildDateFormat Start');

        String year = String.valueOf(ilDate.year());
        String billingDateDay = (ilDate.day() < 10) ? '0' + String.valueOf(ilDate.day()) : String.valueOf(ilDate.day());
        String billingDateMonth = (ilDate.month() < 10) ? '0' + String.valueOf(ilDate.month()) : String.valueOf(ilDate.month());

        system.debug('## buildDateFormat End');
        return (year + billingDateMonth + billingDateDay);
    }
    /**
     * This method will parse forbidden char
     */
    public static String parseString(String textValue, Pattern forbiddenChar){
        system.debug('## parseString start');

        if(textValue != null){
            Matcher matcher = forbiddenChar.matcher(textValue);
            textValue = (matcher.replaceAll('#'));
        }
        system.debug('## parseString end: '+textValue);
        return textValue;
    }
}