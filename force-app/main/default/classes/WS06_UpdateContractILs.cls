global class WS06_UpdateContractILs {

	// return the greatest Invoice number
	public static PLanned_Invoicing_Line__c getBigestInvoiceNumber(PLanned_Invoicing_Line__c pil1, PLanned_Invoicing_Line__c pil2){
		String str1 = pil1.N_Invoice__c;
		String str2 = pil2.N_Invoice__c;
		
		if(str1.length() > str2.length())
			return pil1;
		if(str1.length() < str2.length())
			return pil2;

		List<Integer> lstAsc1 = str1.getChars();
		List<Integer> lstAsc2 = str2.getChars();
		
		for(Integer i=0; i<lstAsc1.size(); i++){
			if(lstAsc1[i] > lstAsc2[i]){
				return pil1;
			}else if(lstAsc1[i] < lstAsc2[i]){
				return pil2;
			}
		}
		return pil1;
	}

	webservice static List<WrapperResponse> updateContractILs(wrapperResult result) {
		List<WrapperResponse> lstResponses = new List<WrapperResponse>();
		Map<Id, PLanned_Invoicing_Line__c> mapInvoicingLines = new Map<Id, PLanned_Invoicing_Line__c>();
		map<Id,Contract__c> mapContract = new map<Id,Contract__c>();
		map<string, Log__c> mapLogs = new map<string, Log__c>();
		map<string, String> mapERROR_MESSAGE = new map<string, String>();
		map<string, String> mapET_DOCS = new map<string, String>();
		map<string, String> mapET_LOG = new map<string, String>();
		map<string, Item3> mapItem3 = new map<string, Item3>();
		map<string, String> mapMSGTYPE = new map<string, String>();
		Set<string> setInvoicingLineId = new Set<string>();
		PLanned_Invoicing_Line__c pil;

		if(result != null){
			ET_LOG ET_LOG = result.ET_LOG;
			ET_DOCS ET_DOCS = result.ET_DOCS;

			if(ET_LOG != null && ET_LOG.item != null){
				for(Item3 item: ET_DOCS.item){
					if(item.INVOICING_LINE_ID != null && item.INVOICING_LINE_ID != ''){
						mapItem3.put(item.INVOICING_LINE_ID, item);
					}
				}
				for(Item4 item4: result.ET_LOG.item){
					Item3 item3 = mapItem3.get(item4.INVOICING_LINE_ID);
					if(item4.MSGTYPE == 'S'){
						// Create a success log for each contract
						if(!mapLogs.containsKey(item4.CONTRACT_ID)){
							mapLogs.put(item4.CONTRACT_ID, new log__c(
								Call_Status__c 		= item4.MSGTYPE, 
								Date_of_log__c		= System.now(), 
								Error_Message__c	= '', 
								Contract__c 		= item4.CONTRACT_ID, 
								Response_ET_DOC__c 	= String.valueOf(ET_DOCS), 
								Response_ET_LOG__c 	= String.valueOf(ET_LOG)
							));
						}

						// Update ILs in success
						if(item3 != null){
							pil = new PLanned_Invoicing_Line__c(id = item3.INVOICING_LINE_ID);
							pil.isInPS__c = true;
							pil.SO__c = item3.SALES_ORDER_NUMBER;
							pil.SO_ITEM__c = '' + Integer.valueOf(item3.SALES_ORDER_ITEM);
							pil.TECH_SynchroSAP__c = true;
							/*pil.N_Invoice__c = item3.BILLING_DOCUMENT_NUMBER;
							pil.Billing_date_SAP__c = item3.BILLING_DOCUMENT_DATE;			
							pil.Payment_Document_Number__c = item3.PAYMENT_DOCUMENT;
							pil.Payment_Document_Date__c = item3.PAYMENT_DOCUMENT_DATE;
							if(pil.Payment_Document_Number__c == 'CLEARED'){
								pil.Paid_Not_Paid__c = true;
							}*/
							
							if(!mapInvoicingLines.containsKey(pil.Id)){
								mapInvoicingLines.put(pil.Id, pil);
							}else if(pil.N_Invoice__c != null){
								if(mapInvoicingLines.get(pil.Id).N_Invoice__c == null){
									mapInvoicingLines.put(pil.Id, pil);
								}else{
									mapInvoicingLines.put(pil.Id, getBigestInvoiceNumber(pil,mapInvoicingLines.get(pil.Id)));
								}
							}
							setInvoicingLineId.add(item3.INVOICING_LINE_ID);
						}
						
						// Update Contract success
						mapContract.put(item4.CONTRACT_ID, new Contract__c(Id = item4.CONTRACT_ID, Peoplesoft_Sync__c = true, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
					}else if(item4.MSGTYPE == 'E'){
						if(string.isnotblank(item4.INVOICING_LINE_ID)){
							// create an error log for the contract
							mapLogs.put(item4.CONTRACT_ID, new log__c(
								Call_Status__c 		= item4.MSGTYPE, 
								Date_of_log__c		= System.now(), 
								Error_Message__c	= item4.ERROR_MESSAGE, 
								Contract__c 		= item4.CONTRACT_ID, 
								Response_ET_DOC__c 	= String.valueOf(ET_DOCS), 
								Response_ET_LOG__c 	= String.valueOf(ET_LOG)
							));
							
							// Update ILs in error
							if(item3 != null){
								if(!mapInvoicingLines.containsKey(item3.INVOICING_LINE_ID)){
									mapInvoicingLines.put(item3.INVOICING_LINE_ID, new Planned_Invoicing_Line__c(
										id 								= item3.INVOICING_LINE_ID,
										Connexion_Error__c 				= 'Connection to PeopleSoft OK',
										SAP_Synchronisation_Error__c 	= item4.ERROR_MESSAGE
									));
								}
							}
						}else{
							// PS didn't send us an invoicing line ID
							mapERROR_MESSAGE.put(item4.CONTRACT_ID, item4.ERROR_MESSAGE);
							mapET_DOCS.put(item4.CONTRACT_ID, String.valueOf(ET_DOCS));
							mapET_LOG.put(item4.CONTRACT_ID, String.valueOf(ET_LOG));
						}

						// Update Contract error
						mapContract.put(item4.CONTRACT_ID, new Contract__c(Id = item4.CONTRACT_ID, Peoplesoft_Sync__c = false, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
					}
				}

				// Set log and update IL for blank IL Id from PS
				if(mapERROR_MESSAGE != null && !mapERROR_MESSAGE.isEmpty()){
					List<Planned_Invoicing_Line__c> invalidILs = [	SELECT id, Contract2__c, ADV_GoNoGo__c, Connexion_Error__c, SAP_Synchronisation_Error__c
																	FROM Planned_Invoicing_Line__c
																	WHERE Contract2__c IN :mapERROR_MESSAGE.keyset()
																	AND Status__c = '01'
																	AND TECH_SynchroSAP__c = false ];

					for(Planned_Invoicing_Line__c invalidIL : invalidILs){
						string contractId = invalidIL.Contract2__c;
						if(mapInvoicingLines != null && !mapInvoicingLines.isEmpty() && !mapInvoicingLines.containsKey(invalidIL.id)){
							mapInvoicingLines.put(invalidIL.id, new Planned_Invoicing_Line__c(
								id 								= invalidIL.id,
								Connexion_Error__c 				= 'Connection to PeopleSoft OK',
								SAP_Synchronisation_Error__c 	= mapERROR_MESSAGE.get(contractId)
							));

							// Create an error log for the contract
							if(!mapLogs.containsKey(contractId)){
								mapLogs.put(contractId, new log__c(
									Call_Status__c 		= mapMSGTYPE.get(contractId), 
									Date_of_log__c		= System.now(), 
									Error_Message__c	= mapERROR_MESSAGE.get(contractId), 
									Contract__c 		= contractId, 
									Response_ET_DOC__c 	= mapET_DOCS.get(contractId), 
									Response_ET_LOG__c 	= mapET_LOG.get(contractId)
								));
							}
							
							// Update Contract error
							mapContract.put(contractId, new Contract__c(Id = contractId, Peoplesoft_Sync__c = false, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
						}
					}
				}
			}
			
			// Update Invoicing lines
			if (mapInvoicingLines.size() > 0){
				String errorMessage = '';
				List<PLanned_Invoicing_Line__c> lstInvoicingLines = new list<PLanned_Invoicing_Line__c>();
				Map<Id, PLanned_Invoicing_Line__c> mapPIL = new Map<Id, PLanned_Invoicing_Line__c>();
				if(setInvoicingLineId.size() > 0){
					mapPIL = new Map<Id, PLanned_Invoicing_Line__c>([SELECT Id, Status__c, Tech_UpdatedByPS__c FROM Planned_Invoicing_Line__c WHERE Id IN:setInvoicingLineId]);
				}

				// Set IL status
				for(PLanned_Invoicing_Line__c invoicingLine: mapInvoicingLines.values()){
					if(mapPIL != null && mapPIL.containsKey(invoicingLine.Id)){
						if(mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_DRAFT){
							invoicingLine.Status__c = AP_Constant.INVLINE_STATUS_INVOICING_VALIDATION;
						}
						if(mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_INVOICED || mapPIL.get(invoicingLine.Id).Status__c == AP_Constant.INVLINE_STATUS_PAID){
							invoicingLine.Tech_UpdatedByPS__c = (mapPIL.get(invoicingLine.Id).Tech_UpdatedByPS__c ? false : true);
						}
					}
					lstInvoicingLines.add(invoicingLine);
				}
				
				Database.SaveResult[] lstInvoiUpdated = Database.update(lstInvoicingLines, false);

				for(integer j=0;j<lstInvoicingLines.size();j++){
					WrapperResponse response = new WrapperResponse();
					response.CONTRACT_ID = lstInvoicingLines[j].Contract2__c;
					response.INVOICING_LINE_ID = lstInvoicingLines[j].id;
					response.SALES_ORDER_NUMBER = lstInvoicingLines[j].SO__c;
					response.SALES_ORDER_ITEM = lstInvoicingLines[j].SO_ITEM__c;

					if(lstInvoiUpdated[j].isSuccess()){
						response.NOTIFICATION_PROCESSING_STATUS = 'OK';
						System.debug('##sucess');
					}
					else{
						for(Database.Error err : lstInvoiUpdated[j].getErrors()) {
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
			
			// Insert lstLog;
			if((mapLogs.size() > 0) && (!Test.isRunningTest())){
				insert mapLogs.values();
			}
			
			// Update contract
            if (mapContract.size() > 0) {
                update mapContract.values();
            }
			System.debug('lstResponses: '+lstResponses);
		}
		return lstResponses;
	}
	
	global class WrapperResponse{
		webservice String CONTRACT_ID;
		webservice String INVOICING_LINE_ID;
		webservice String SALES_ORDER_NUMBER;
		webservice String SALES_ORDER_ITEM;
		webservice String NOTIFICATION_PROCESSING_STATUS;
		webservice String ERROR_LOG;
	}

    global class wrapperResult {
        public ET_DOCS ET_DOCS;
        public ET_LOG ET_LOG;
    }
	
    public class ET_LOG {
        public item4[] item;
    }
	
    public class ET_DOCS {
        public item3[] item;
    }

    public class Item3 {
        public String CONTRACT_ID;
        public String INVOICING_LINE_ID;
        public String SALES_ORDER_NUMBER;
        public String SALES_ORDER_ITEM;
		/*public String BILLING_DOCUMENT_NUMBER;
		public String PAYMENT_DOCUMENT;
		public Date BILLING_DOCUMENT_DATE;
		public Date PAYMENT_DOCUMENT_DATE;*/
    }

    public class Item4 {
        public String CONTRACT_ID;
        public String INVOICING_LINE_ID;
        public Integer SEQ;
        public String MSGTYPE;
        public String ERROR_MESSAGE;
		/*public String ET_REQUEST;*/
    }
}