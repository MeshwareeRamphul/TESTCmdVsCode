global class WS01_UpdateContracts {
	/**
 * @description       : This class is called by PS for the flow3
 * @author            : 
 * @group             : 
 * @last modified on  : 09-03-2022
 * @last modified by  : ARA
 * 
 -- Maintenance History: 
 --
 -- Date         Name  Version  Remarks 
 -- -----------  ----  -------  ------------------------
 --                     1.0      Initial version
 -- 09-03-2022   ARA    2.0      SP-03415 Flow3 & Create log
 *-------------------------------------------------------
**/

	webservice String area; 
	webservice String region; 

	//object in apex that is exposed in apex web service
	global class parametresfromSAP {
		webservice list<wrapperParams> lstParamsSap;
	}	

    //return the greatest Invoice number
    public static PLanned_Invoicing_Line__c getBigestInvoiceNumber(PLanned_Invoicing_Line__c pil1, PLanned_Invoicing_Line__c pil2){
        String str1 = pil1.N_Invoice__c;
        String str2 = pil2.N_Invoice__c;
		PLanned_Invoicing_Line__c bigIL;
        
		if(str1 != null && str2 != null){
			List<Integer> lstAsc1 = str1.getChars();
			List<Integer> lstAsc2 = str2.getChars();
			if(str1.length() > str2.length()){
				bigIL = pil1;
			}else if(str1.length() < str2.length()){
				bigIL = pil2;
			}else{
				for(Integer i=0; i<lstAsc1.size(); i++){
					if(lstAsc1[i] > lstAsc2[i]){
						return pil1;
					}else if(lstAsc1[i] < lstAsc2[i]){
						return pil2;
					}
				}
			}
		}else if(str2 == null){
            bigIL = pil1;
		}else{
            bigIL = pil2;
		}

        return bigIL;
    }
	
	webservice static List<wrapperResponse> updateInvoiceLine(list<wrapperParams> lstparams) {
		System.debug('<< updateInvoiceLine start>>');

		set<string> setPurchaseOrder = new set<string>();
		List<PLanned_Invoicing_Line__c> lstInvoicingLines = new list<PLanned_Invoicing_Line__c>();
		map<string, PLanned_Invoicing_Line__c> mapInvoiLine = new map<string, PLanned_Invoicing_Line__c>();
		Map<Id, PLanned_Invoicing_Line__c> mapInvoicingLines = new Map<Id, PLanned_Invoicing_Line__c>();
		PLanned_Invoicing_Line__c invoicingLine;
		wrapperResponse response = new wrapperResponse();
		List<wrapperResponse> lstResponses = new List<wrapperResponse>();
		List<wrapperResponse> lstCtrResponses = new List<wrapperResponse>();
		Map<Id, List<wrapperResponse>> mapResponses = new Map<Id, List<wrapperResponse>>();
		String errorMessage,ContractId;
		map<string,string> mapContract = new map<string,string>();
		
		for (wrapperParams wp: lstparams){
			invoicingLine = new PLanned_Invoicing_Line__c(id=wp.Invoicing_Line_Id);
			invoicingLine.SO__c = wp.Sales_Order_Number;
			invoicingLine.SO_ITEM__c = wp.Sales_Order_Item;
			invoicingLine.N_Invoice__c = wp.Billing_Document_Number;
			invoicingLine.Billing_date_SAP__c = wp.Billing_Document_Date;
			invoicingLine.Payment_Document_Number__c = wp.Payment_Document;
			if(invoicingLine.Payment_Document_Number__c == 'CLEARED'){
				invoicingLine.Paid_Not_Paid__c = true;
			}else if(invoicingLine.Payment_Document_Number__c == 'INVOICED'){
				invoicingLine.Status__c = AP_Constant.INVLINE_STATUS_INVOICED;
			}
			invoicingLine.Payment_Document_Date__c = wp.Payment_Document_Date;
			mapContract.put(wp.Invoicing_Line_Id,wp.Contract_Id);

			// 23-08-2021	ARA		SP-02341 (The latest PS invoice is the one with the biggest invoice number)
			if(!mapInvoicingLines.containsKey(invoicingLine.Id)){
				mapInvoicingLines.put(invoicingLine.Id, invoicingLine);
			}else{
				mapInvoicingLines.put(invoicingLine.Id, getBigestInvoiceNumber(invoicingLine,mapInvoicingLines.get(invoicingLine.Id)));
			}
		}
		
		if(mapInvoicingLines.size() > 0){
			for(PLanned_Invoicing_Line__c pil: mapInvoicingLines.values()){
				lstInvoicingLines.add(pil);
			}
				
			Database.SaveResult[] lstInvoiUpdated = Database.update(lstInvoicingLines,false);
			Map<Id,Log__c> mapLog = new Map<Id,Log__c>();
			String jsonPart1 = JSON.serialize(lstparams);
			String jsonPart2 = '';
			Log__c log;
		
			if(jsonPart1.length() > 131072){
				jsonPart1 = jsonPart1.substring(0, 131072);
				jsonPart2 = jsonPart1.substring(131072, jsonPart1.length());
				if(jsonPart2.length() > 131072){
					jsonPart2 = jsonPart2.substring(0, 131072);
				}
			}

			for(integer j=0;j<lstInvoicingLines.size();j++){
				response = new wrapperResponse();
				response.Contract_Id = mapContract.get(lstInvoicingLines[j].id);
				response.Invoicing_Line_Id = lstInvoicingLines[j].id;
				response.Sales_Order_Number = lstInvoicingLines[j].SO__c;
				response.Sales_Order_Item = lstInvoicingLines[j].SO_ITEM__c;

				if(lstInvoiUpdated[j].isSuccess()){
					response.Notification_processing_Status = 'OK';
					System.debug('##sucess');
				}
				else{
					for(Database.Error err : lstInvoiUpdated[j].getErrors()) {
						errorMessage +=err.getMessage()+' ';
						System.debug('The following error has occurred.');                   
						System.debug(err.getStatusCode() + ': ' + err.getMessage());
						System.debug('Fields that affected this error: ' + err.getFields());
					}
					response.Notification_processing_Status = 'KO';
					response.Error_Log = errorMessage+'.';
				}
				System.debug('response: '+response);

				if(mapResponses.containsKey(response.Contract_Id)){
					lstCtrResponses = mapResponses.get(response.Contract_Id);
				}else{
					lstCtrResponses = new List<wrapperResponse>();
				}
				lstCtrResponses.add(response);
				mapResponses.put(response.Contract_Id, lstCtrResponses);
				lstResponses.add(response);
			}

			// Create log for flow 3
			for(wrapperResponse wr : lstResponses){
				if(mapLog.containsKey(wr.Contract_Id)){
					log = mapLog.get(wr.Contract_Id);
				}else{
					log = new Log__c();
				}

				log.Contract__c = wr.Contract_Id;
				log.Date_of_log__c = System.now();
				log.Source__c = AP_Constant.PS_FLOW_3;
				log.Request__c = jsonPart1;
				if(jsonPart2 != ''){
					log.Request_part_2__c = jsonPart2;
				}
				log.Response__c = JSON.serialize(mapResponses.get(wr.Contract_Id)).left(131072);

				if(wr.Notification_processing_Status == 'OK'){
					if(log.Call_Status__c != 'E'){
						log.Call_Status__c = 'S';
					}
				}else{
					log.Call_Status__c = 'E';
				}

				if(wr.Error_Log != null){
					log.Error_Message__c = (log.Error_Message__c == null) ? '[Error: ' + wr.Invoicing_Line_Id + ' ' + wr.Error_Log + ']' : '[Error: ' + wr.Invoicing_Line_Id + ' ' + wr.Error_Log + '], ' + log.Error_Message__c;
				}else{
					log.Error_Message__c = (log.Error_Message__c == null) ? '[OK: ' + wr.Invoicing_Line_Id + ']' : log.Error_Message__c + ', ' + '[OK : ' + wr.Invoicing_Line_Id + ']';
				}
				log.Error_Message__c = log.Error_Message__c.left(255);
				mapLog.put(wr.Contract_Id, log);
			}
			if(mapLog.size() > 0){
				insert mapLog.values();
			}
		}
		System.debug('lstResponses: '+JSON.serialize(lstResponses));
		return lstResponses;
	}

	global class wrapperParams{
		//webservice String SALESORGANIZATION;
		//webservice String SOLDTOPARTY;
		//webservice String SHIPTOPARTY;
		// webservice string PONUMBER {get;set;}  // commented on 14/03/17
		// webservice Integer TARGETQUANTITY; // commented on 14/03/17
		//webservice string DESCRIPTION;
		//webservice string CONTACTPERSON;
		//webservice string SOLUTION;
		//webservice string SERVICETYPE;
		//webservice date STARTDATE;
		//webservice date ENDDATE;
		// webservice string TEXTS;  // commented on 14/03/17
		// webservice integer EMPLOYERESPONS;  // commented on 14/03/17
		//webservice string DESCRIPTIONLONG;
		// webservice string CURENCY; // commented on 14/03/17
		//webservice string WBSELEMENT;  // commented on 14/03/17
		// webservice decimal AMOUNTMANUALPRICE; // commented on 14/03/17
		// webservice date BILLINGDATE; // commented on 14/03/17
		// webservice string ITEM;  // commented on 14/03/17
		// webservice integer INVOICENO;  // commented on 14/03/17
		// webservice date DATEDEFACTURE; // commented on 14/03/17
		// webservice string PAYMENTFLAG;  // commented on 14/03/17

		//ASO 25-10-2016
		webservice String Contract_Id;
		webservice String Invoicing_Line_Id;
		webservice String Sales_Order_Number;
		webservice String Sales_Order_Item;
		webservice String Billing_Document_Number;
		webservice Date Billing_Document_Date;
		webservice String Payment_Document;
		webservice Date Payment_Document_Date;
	}

	//ASO 25-10-2016
	global class wrapperResponse{
		webservice String Contract_Id;
		webservice String Invoicing_Line_Id;
		webservice String Sales_Order_Number;
		webservice String Sales_Order_Item;
		webservice String Notification_processing_Status;
		webservice String Error_Log;
	}
}