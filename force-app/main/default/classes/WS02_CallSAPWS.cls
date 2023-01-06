public class WS02_CallSAPWS {
    /*
    --------------------------------------------------------------------------------------
    -- - Name          : WS02_CallSAPWS
    -- - Author        : ASO
    -- - Description   : Call the Class WS02_SAPInvoiceLine
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 24-OCT-2016  ASO    1.0     Initial version
    -- 11-AVR-2017  EWA    1.1     Utilisaiton des classes sapComDocumentSapRfcFunctions & dvssneipags11PpmailPpservicesAxaTech suite au changement de WSDL
    --                             Changement de la valeur envoyer en PO_NUMBER dans le HEADER
    --                             Gestion de l'affichage des messages d'erreurs pour les end user
    --                             Utilisation de la nouvelle structure de données.
    -- 27-JUN-2017  ASE    1.2     ALLINFIN-488 Interface SAP-SFDC : Ajout de 7 nouveaux champs + utilisation du nouveau WSDL_ContractCreation
    -- 31-JUL-2017  ASE    1.3     ALLINFIN-488 Interface SAP-SFDC : username/ passwprd no more sent in WSDL. But in the header using authorizationHeader
    -- 12-SEP-2017  ASE    1.4     replace '&'(forbidden character on SAP) by '#'. Trim length till 40
    -- 20-NOV-2017  USA    1.5     ALLINFIN-546 Issues/Evolutions on SAP response
    -- 21-NOV-2017  USA    1.6     ALLINFIN-548 SAP Webservice Logs
    -- 30-OCT-2018  MRA    1.7     Callout Interface Peoplesoft
    -- 17-NOV-2020  USA    1.8     SP-00526 
    -- 25-MAR-2021  ARA    1.9     SP-01488 Allow contract update after send to PS even if Customer Operational contact is inactive
    --------------------------------------------------------------------------------------
    */


    ///ASE: 27/06/2017
    // creating instance ZSD_SALESFORCE_SALES_ORDERS from class WSDL_ContractCreation
    WSDL_ContractCreation.IT_INPUT salesOrdersInputTab = new WSDL_ContractCreation.IT_INPUT();
    WSDL_ContractCreation.item[] salesOrdersInput = new List<WSDL_ContractCreation.item>();
    WSDL_ContractCreation.MSGITEM msgItemTab = new WSDL_ContractCreation.MSGITEM();
    WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERS orders = new WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERS();
    WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERSResponse result = new WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERSResponse();
    List<Log__c> lstLog = new List<Log__c>();

    //call status values
    String str_Error = 'E';
    String str_Success = 'S';
    String str_Exception = 'Exception';

    // 25-MAR-2021  ARA     SP-01488 (used in ContractTrigerHandler)
    public static boolean isSentToPS = false;
    String errorMsg = '';

    public String getErroMessage(){
        return errorMsg;
    }

    public WS02_CallSAPWS(map<id,List<Planned_Invoicing_Line__c>> mapInvoiceLineInfo){
        System.debug(LoggingLevel.INFO, '<<Start of WS02_CallSAPWS>>');
        system.debug('## mapInvoiceLineInfo'+mapInvoiceLineInfo);
        Map<Id, Planned_Invoicing_Line__c> mapInvoiceLines = new Map<Id, Planned_Invoicing_Line__c>();
        List<Contract__c> lstCtr = new List<Contract__c>();
        isSentToPS = true;

        for(id contractId:mapInvoiceLineInfo.keyset()){
            //ASE: 27/06/2017
            WSDL_ContractCreation.MSGHEADER headersData;
            WSDL_ContractCreation.item2[] itemData = new List<WSDL_ContractCreation.item2>();
            WSDL_ContractCreation.item input = new WSDL_ContractCreation.item();

            Pattern forbiddenChar = Pattern.compile(system.label.forbiddenCharSAP);

            List<Planned_Invoicing_Line__c> lstInvoiceLines = mapInvoiceLineInfo.get(contractId);
            for(Integer i=0;i<lstInvoiceLines.size();i++){
                mapInvoiceLines.put(lstInvoiceLines[i].Id, lstInvoiceLines[i]);

                if(i==0){
                    lstInvoiceLines[i].SAP_Synchronisation_Error__c = '';
                    lstInvoiceLines[i].Connexion_Error__c = '';

                    headersData = new WSDL_ContractCreation.MSGHEADER();
                    headersData.ORDER_TYPE = 'YORD';
                    headersData.SALES_ORGANIZATION = lstInvoiceLines[i].Contract2__r.TECH_PS_SalesOrganization__c;
                    headersData.DISTRIBUTION_CHANNEL = '01';
                    headersData.DIVISION_DIVISION = '01';
                    headersData.SOLD_TO_PARTY = lstInvoiceLines[i].SAP_Account_Number__c;
                    headersData.SHIP_TO_PARTY = lstInvoiceLines[i].SAP_Account_Number__c;
                    headersData.PO_NUMBER = lstInvoiceLines[i].Contract2__r.Tech_MSARef__c;
                    headersData.BILL_FORM = lstInvoiceLines[i].Bill_form_SAPEXP__c;
                    headersData.CONTACT_PERSON = lstInvoiceLines[i].Customer_Operational_Contact__c;

                    if (lstInvoiceLines[i].Solution__c != null){
                        String solution = parseString(lstInvoiceLines[i].Solution__c, forbiddenChar);
                        solution = solution.startsWith('Product - Out of Catalog(') ? solution.replace('Product - Out of Catalog(','').removeEnd(')') :solution;
                        headersData.SOLUTION = (solution.length() > 40) ? solution.substring(0, 40) : solution;
                    }
                    else{
                        headersData.SOLUTION = 'GENAMT';
                    }

                    headersData.SERVICE_TYPE = lstInvoiceLines[i].Service_Type__c;
                    headersData.START_DATE = lstInvoiceLines[i].Contract_Start_Date__c != null ? buildDateFormat(lstInvoiceLines[i].Contract_Start_Date__c) : null;
                    headersData.END_DATE = lstInvoiceLines[i].Contract_End_Date__c != null ? buildDateFormat(lstInvoiceLines[i].Contract_End_Date__c) : null;

                    headersData.CONTRACT_ID = lstInvoiceLines[i].Contract2__c;
                    if(headersData.CONTRACT_ID.length() > 15){              //In case we got a 18 char ID
                        headersData.CONTRACT_ID = headersData.CONTRACT_ID.substring(0, 15);
                    }
                    headersData.EMPLOYEE_RESPONSIBLE_PARTNER = '18982'; //String.valueOf(lstInvoiceLines[i].SAP_ID__c);
                    headersData.TEXT1 = parseString(lstInvoiceLines[i].Contract2__r.ContractNumber__c, forbiddenChar); //parseString(lstInvoiceLines[i].Header_Text__c, forbiddenChar);
                    if(lstInvoiceLines[i].Contract2__r.Status__c == 'Cancelled' || lstInvoiceLines[i].Contract2__r.Status__c == 'Resiliated'){
                        headersData.TEXT2 = 'CLOSED';
                    }else{
                        headersData.TEXT2 = '';
                    }
                    headersData.TEXT3 = parseString(lstInvoiceLines[i].Contract2__r.name, forbiddenChar);
                    headersData.TEXT4 = '';
                }
                WSDL_ContractCreation.item2 itemDataInfo = new WSDL_ContractCreation.item2();

                System.debug('##USA## headersData: '+headersData);
                System.debug('##USA## itemData: '+itemData);
                if(lstInvoiceLines[i].N_Purchase_Order__c != ''  && lstInvoiceLines[i].N_Purchase_Order__c != null){
                    itemDataInfo.PO_NUMBER_ITEM = lstInvoiceLines[i].N_Purchase_Order__c;
                } else if (lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c != '' && lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c != null) {
                    itemDataInfo.PO_NUMBER_ITEM  = lstInvoiceLines[i].PurchaseOrder__r.PO_Client__c;
                } else{
                    itemDataInfo.PO_NUMBER_ITEM = '-';
                }
                itemDataInfo.MATERIAL = lstInvoiceLines[i].Material_SAPEXP__c;
                itemDataInfo.TARGET_QUANTITY = '1'; //String.valueOf(lstInvoiceLines[i].Man_days__c);
                itemDataInfo.UNIT_OF_MEASURE = 'AMT';
                if (lstInvoiceLines[i].Activity_Type__c == null){
                    itemDataInfo.DESCRIPTION = '';
                }
                else{
                    itemDataInfo.DESCRIPTION = parseString(lstInvoiceLines[i].Activity_Type__c, forbiddenChar);
                }
                itemDataInfo.DESCRIPTION_LONG = lstInvoiceLines[i].Customer_contact_name__c;
                itemDataInfo.CURRENCY_x = lstInvoiceLines[i].ViewCurrency__c;
                itemDataInfo.WBS_ELEMENT = lstInvoiceLines[i].WBS_Element_SAPEXP__c;
                itemDataInfo.AMOUNT_MANUAL_PRICE = String.valueOf(lstInvoiceLines[i].AmountIL__c);
                //itemDataInfo.BILLING_DATE = (lstInvoiceLines[i].Invoicing_Predefined_Date__r.Invoicing_Date__c !=null) ? buildDateFormat(lstInvoiceLines[i].Invoicing_Predefined_Date__r.Invoicing_Date__c) :  null;
                itemDataInfo.BILLING_DATE = (lstInvoiceLines[i].Inv_Predefined_Date__c !=null) ? buildDateFormat(lstInvoiceLines[i].Inv_Predefined_Date__c) :  null;
                itemDataInfo.INVOICING_LINE_ID = lstInvoiceLines[i].id;
                itemDataInfo.INVOICE_STATUS = String.valueOf(lstInvoiceLines[i].Status__c);
                system.debug('##USA## itemDataInfo:'+itemDataInfo);
                itemData.add(itemDataInfo);
            }

            msgItemTab.item = itemData;

            input.MSGHEADER = headersData;
            input.MSGITEM = msgItemTab;

            salesOrdersInput.add(input);
        }
        salesOrdersInputTab.item = salesOrdersInput;
        orders.IT_INPUT = salesOrdersInputTab;

        WSDL_ContractCreation.ags_it_services_salesorders_vssoaphttp soapRequest = new WSDL_ContractCreation.ags_it_services_salesorders_vssoaphttp();
        soapRequest.Timeout_x = 60000;
        //ASE : 31/07/2017 : username no more in WSDL
        //Blob headerValue = Blob.valueOf('SFDC_MDM' + ':' + 'G0TcgGER8fNczquKk2dj');
        Blob headerValue = Blob.valueOf(system.label.WS_EIPLogin + ':' + system.label.WS_EIPPassword);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        soapRequest.inputHttpHeaders_x  = new Map<String, String>();
        soapRequest.inputHttpHeaders_x.put('Authorization',authorizationHeader);

        system.debug('##USA## orders:'+orders);

        map<Id, Contract__c> mapIdCtr = new map<Id, Contract__c>();

        try{

            //result = soapRequest.salesforces_sales_order_flow(orders,'EIPWEB','sjb=AdR3');
            //ASE : 31/07/2017 : username no more in WSDL
            //result = soapRequest.salesforces_sales_order_flow(orders,'ZZTESTWEB','k7Cca)iF');

            Contract__c ctrCurrent;
            result = soapRequest.salesforces_sales_order_flow(orders);

            system.debug(LoggingLevel.INFO, '##USA## result: '+result);
            List<Planned_Invoicing_Line__c> lstInvoiceLinesUpdate = new List<Planned_Invoicing_Line__c>();

            set<WSDL_ContractCreation.item4> setError = new Set<WSDL_ContractCreation.item4>();

            if(result != null){
                system.debug('## USA## result.ET_DOCS: '+result.ET_DOCS);
                system.debug('## USA## result.ET_LOG: '+result.ET_LOG);

                //USA 20171116 : ALLINFIN-546
                if(result.ET_LOG != null && result.ET_LOG.item != null){
                    // if msgtype = 'S' => Success : ET_DOC should not be null
                    Integer intCountE = 0;
                    for(WSDL_ContractCreation.item4 itm4 : result.ET_LOG.item){
                        ctrCurrent = new Contract__c (Id = itm4.CONTRACT_ID);
                        if (itm4.MSGTYPE == 'S'){
                            system.debug('S'); // && result.ET_LOG.item.MSGTYPE == 'S'
                        }
                        else if (itm4.MSGTYPE == 'E'){
                            setError.add(itm4);
                            intCountE = intCountE + 1;

                            if(string.isnotblank(itm4.INVOICING_LINE_ID)){
                                boolean flag = true;
                                for(Planned_Invoicing_Line__c pil : lstInvoiceLinesUpdate){
                                    if(pil.id == itm4.INVOICING_LINE_ID){
                                        flag = false;
                                    }
                                }
                                system.debug('## USA## flag: '+flag);
                                if(flag){
                                    lstInvoiceLinesUpdate.add(new Planned_Invoicing_Line__c(id = itm4.INVOICING_LINE_ID
                                            //,ADV_GoNoGo__c = 'NO GO'
                                            //,RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                            //,Status__c=AP_Constant.INVLINE_STATUS_DRAFT
                                            ,Connexion_Error__c = 'Connection to PeopleSoft OK'
                                            ,SAP_Synchronisation_Error__c = itm4.ERROR_MESSAGE));
                                    if (!mapIdCtr.containsKey(itm4.CONTRACT_ID)){
                                        mapIdCtr.put(itm4.CONTRACT_ID, new Contract__c(Id = itm4.CONTRACT_ID, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                                        // Error to display on lwc
                                        errorMsg = itm4.ERROR_MESSAGE;
                                        lstLog.add(new log__c(
                                                Call_Status__c = str_Error
                                                , Date_of_log__c = System.now()
                                                , Error_Message__c = itm4.ERROR_MESSAGE
                                                //, Invoicing_Line__c = itm4.INVOICING_LINE_ID
                                                , Contract__c = itm4.CONTRACT_ID
                                                , Request__c = String.valueOf(orders)
                                                , Response_ET_DOC__c = String.valueOf(result.ET_DOCS)
                                                , Response_ET_LOG__c = String.valueOf(result.ET_LOG)
                                        ));
                                    }
                                }
                            }
                            else{
                                System.debug('## USA## SAP didn\'t send us an invoicing line ID');
                                List<Planned_Invoicing_Line__c> invalidILs = [SELECT id, ADV_GoNoGo__c, Connexion_Error__c, SAP_Synchronisation_Error__c
                                FROM Planned_Invoicing_Line__c
                                WHERE Contract2__c =: itm4.CONTRACT_ID
                                AND Status__c = '01'
                                AND TECH_SynchroSAP__c = false ];
                                for(Planned_Invoicing_Line__c invalidIL : invalidILs){
                                    boolean flag = true;
                                    for(Planned_Invoicing_Line__c pil : lstInvoiceLinesUpdate){
                                        if(pil.id == invalidIL.id){
                                            flag = false;
                                        }
                                    }
                                    if(flag){
                                        lstInvoiceLinesUpdate.add(new Planned_Invoicing_Line__c(id = invalidIL.id
                                                //,ADV_GoNoGo__c = 'NO GO'
                                                //,RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                                //,Status__c=AP_Constant.INVLINE_STATUS_DRAFT
                                                ,Connexion_Error__c = 'Connection to PeopleSoft OK'
                                                ,SAP_Synchronisation_Error__c = itm4.ERROR_MESSAGE));
                                        if (!mapIdCtr.containsKey(itm4.CONTRACT_ID)){
                                            mapIdCtr.put(itm4.CONTRACT_ID, new Contract__c(Id = itm4.CONTRACT_ID,PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                                            // Error to display on lwc
                                            errorMsg = itm4.ERROR_MESSAGE;
                                            lstLog.add(new log__c(
                                                    Call_Status__c = str_Error
                                                    , Date_of_log__c = System.now()
                                                    , Error_Message__c = itm4.ERROR_MESSAGE
                                                    //, Invoicing_Line__c = invalidIL.id
                                                    , Contract__c = itm4.CONTRACT_ID
                                                    , Request__c = String.valueOf(orders)
                                                    , Response_ET_DOC__c = String.valueOf(result.ET_DOCS)
                                                    , Response_ET_LOG__c = String.valueOf(result.ET_LOG)
                                            ));
                                        }
                                    }
                                }
                            }
                        }
                    }

                    System.debug('## USA## intCountE : ' + intCountE);
                    // if no error, intCountE should be 0 => get updated SO and item from ET_DOC
                    if (intCountE == 0){
                        if (result.ET_DOCS != null && result.ET_DOCS.item != null){
                            String manageSyncILs = '';
                            for (WSDL_ContractCreation.item3 itm3 : result.ET_DOCS.item){
                                if(string.isnotblank(itm3.INVOICING_LINE_ID) && mapInvoiceLines.containsKey(itm3.INVOICING_LINE_ID)){
                                    System.debug('## USA## We\'re updating an Invoicing Line with new data');
                                    boolean flag = true;
                                    for(Planned_Invoicing_Line__c pil : lstInvoiceLinesUpdate){
                                        if(pil.id == itm3.INVOICING_LINE_ID){
                                            flag = false;
                                        }
                                    }
                                    System.debug('***flag '+flag);
                                    if(flag){
                                        System.debug('***mapInvoiceLines '+mapInvoiceLines.size());
                                        System.debug('***INVOICING_LINE_ID '+itm3.INVOICING_LINE_ID);
                                        System.debug('***itm3 '+mapInvoiceLines.get(itm3.INVOICING_LINE_ID));
                                        String new_Status = mapInvoiceLines.get(itm3.INVOICING_LINE_ID).Status__c;
                                        System.debug('***new_Status '+new_Status);
                                        if(new_Status == AP_Constant.INVLINE_STATUS_DRAFT){
                                            new_Status = AP_Constant.INVLINE_STATUS_INVOICING_VALIDATION;
                                        }
                                        Boolean tech_UpdatedByPS = mapInvoiceLines.get(itm3.INVOICING_LINE_ID).Tech_UpdatedByPS__c;
                                        System.debug('***tech_UpdatedByPS00 '+tech_UpdatedByPS);
                                        if(new_Status == AP_Constant.INVLINE_STATUS_INVOICED || new_Status == AP_Constant.INVLINE_STATUS_PAID){
                                            tech_UpdatedByPS = (tech_UpdatedByPS ? false : true);
                                        }
                                
                                        System.debug('***tech_UpdatedByPS11 '+tech_UpdatedByPS);
                                        lstInvoiceLinesUpdate.add(new Planned_Invoicing_Line__c(id = itm3.INVOICING_LINE_ID
                                                ,SO__c = itm3.SALES_ORDER_NUMBER
                                                ,ITEM__c = '' + Integer.valueOf(itm3.SALES_ORDER_ITEM)
                                                //,RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()
                                                ,Status__c = new_Status
                                                ,isInPS__c = true
                                                ,TECH_SynchroSAP__c = true
                                                ,Tech_UpdatedByPS__c = tech_UpdatedByPS
                                                ,Connexion_Error__c = 'Connection to PeopleSoft OK'
                                                ,SAP_Synchronisation_Error__c = 'Synchronisation with SAP Done'));
                                                
                                        if (!mapIdCtr.containsKey(ctrCurrent.id)){
                                            mapIdCtr.put(ctrCurrent.id, new Contract__c(Id = ctrCurrent.id,
                                                    PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));

                                            lstLog.add(new log__c(
                                                    Call_Status__c = str_Success
                                                    , Date_of_log__c = System.now()
                                                    , Error_Message__c = ''
                                                    //, Invoicing_Line__c = itm3.INVOICING_LINE_ID
                                                    , Contract__c = ctrCurrent.id
                                                    , Request__c = String.valueOf(orders)
                                                    , Response_ET_DOC__c = String.valueOf(result.ET_DOCS)
                                                    , Response_ET_LOG__c = String.valueOf(result.ET_LOG)
                                            ));
                                        }
                                    }
                                }
                            }
                            ctrCurrent.Peoplesoft_Sync__c = true;
                        }
                    }
                }
            }
            system.debug('## USA## lstInvoiceLinesUpdate: '+lstInvoiceLinesUpdate);
            if(lstInvoiceLinesUpdate.size()>0){
                update lstInvoiceLinesUpdate;
                //Database.update(lstInvoiceLinesUpdate,false);
            }
            system.debug('## USA## il updated');

            if (mapIdCtr.size() > 0) {
                update mapIdCtr.values();
            }
            system.debug('## USA## ctr updated');

            if (ctrCurrent.Peoplesoft_Sync__c)
                update ctrCurrent;

            System.debug(LoggingLevel.INFO, '<<End of WS02_CallSAPWS>>');
        }
        catch(Exception e){
            system.debug('## Exception Start:' +e.getMessage());
            List<Planned_Invoicing_Line__c> updatedIlList = new List<Planned_Invoicing_Line__c>();

            for(Id contractId : mapInvoiceLineInfo.keySet()){
                List<Planned_Invoicing_Line__c> listIls = mapInvoiceLineInfo.get(contractId);
                for(Planned_Invoicing_Line__c il : listIls){
                    Boolean tech_UpdatedByPS = il.Tech_UpdatedByPS__c;
                    if(il.Status__c == AP_Constant.INVLINE_STATUS_INVOICED || il.Status__c == AP_Constant.INVLINE_STATUS_PAID){
                        tech_UpdatedByPS = (tech_UpdatedByPS ? false : true);
                    }
                    updatedIlList.add(new Planned_Invoicing_Line__c(Id = il.Id
                            ,Connexion_Error__c = e.getMessage().left(255)
                            ,SAP_Synchronisation_Error__c = 'Can\'t connect to PS'
                            ,Tech_UpdatedByPS__c = tech_UpdatedByPS));
                    //,ADV_GoNoGo__c='NO GO'
                    //,Status__c=AP_Constant.INVLINE_STATUS_DRAFT
                    //,RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId()));

                    if (!mapIdCtr.containsKey(contractId)){
                        mapIdCtr.put(contractId, new Contract__c(Id = contractId, PeopleSoftConnectionMessage__c = 'Connection to PeopleSoft OK'));
                        // Error to display on lwc
                        errorMsg = e.getMessage();
                        lstLog.add(new log__c(
                                Call_Status__c = str_Exception
                                , Date_of_log__c = System.now()
                                , Error_Message__c = e.getMessage()
                                //, Invoicing_Line__c = il.Id
                                , Contract__c = contractId
                                , Request__c = String.valueOf(orders)
                                , Response_ET_DOC__c = String.valueOf(result.ET_DOCS)
                                , Response_ET_LOG__c = String.valueOf(result.ET_LOG)
                        ));
                    }
                }
            }

            //update listIls;
            system.debug('## USA## updatedIlList: '+updatedIlList);
            if((updatedIlList.size() > 0) && (!Test.isRunningTest())){
                update updatedIlList;
            }
            if (mapIdCtr.size() > 0) {
                system.debug('## USA## mapIdCtr.size : '+mapIdCtr.size());
                system.debug('## USA## mapIdCtr: '+mapIdCtr);
                update mapIdCtr.values();
            }
            system.debug('## Exception End:' +e.getMessage());
        }

        //insert lstLog;
        if((lstLog.size() > 0) && (!Test.isRunningTest())){
            insert lstLog;
        }
    }

    public static String buildDateFormat(Date ilDate){
        system.debug('## buildDateFormat Start');

        String year = String.valueOf(ilDate.year());
        String billingDateDay = (ilDate.day() < 10) ? '0' + String.valueOf(ilDate.day()) : String.valueOf(ilDate.day());
        String billingDateMonth = (ilDate.month() < 10) ? '0' + String.valueOf(ilDate.month()) : String.valueOf(ilDate.month());

        system.debug('## buildDateFormat End');
        return (year + billingDateMonth + billingDateDay);
    }

    // ASE : 12-SEP-2017
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