@isTest
global class WS02_CallSAPWSMock implements WebServiceMock {
/*
//Mock Class for  WS01_UpdateContractsTest : 
----------------------------------------------------------------------
-- - Name          : WS02_CallSAPWSMock
-- - Author        : Spoon Consulting
-- - Description   : Mock class for WS02_CallSAPWS
--                   
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks  
-- -----------  ----  -------  ---------------------------------------
-- 28-FEB-2017  USA   1.0      Initial version  
----------------------------------------------------------------------

*/  
    public String type; 
    public Id IL_Id;
    public Id ctr_Id;

    global WS02_CallSAPWSMock(final String type){
        this.type = type; 
    }

    global WS02_CallSAPWSMock(final String type, final Id IL_Id, final Id ctr_Id){
        this.type = type; 
        this.IL_Id = IL_Id;
        this.ctr_Id = ctr_Id;
    }

    public void doInvoke(Object stub,
                         Object request,
                         Map<String, Object> response,
                         String endpoint,
                         String soapAction,
                         String requestName,
                         String responseNS,
                         String responseName,
                         String responseType) {

        WSDL_ContractCreation.salesforces_sales_order_flowResponse response1 = new WSDL_ContractCreation.salesforces_sales_order_flowResponse();
        WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERSResponse result = new WSDL_ContractCreation.ZSD_SALESFORCE_SALES_ORDERSResponse();
        result.ET_DOCS = new WSDL_ContractCreation.ET_DOCS();
        result.ET_DOCS.item = new list <WSDL_ContractCreation.item3>();
        result.ET_LOG = new WSDL_ContractCreation.ET_LOG();
        result.ET_LOG.item = new list <WSDL_ContractCreation.item4>(); 
        WSDL_ContractCreation.item4 var = new WSDL_ContractCreation.item4();
        WSDL_ContractCreation.item3 var_doc = new WSDL_ContractCreation.item3();
        

        if (type == 'S'){
            result.ET_DOCS.item = null;
            var.CONTRACT_ID = ctr_Id;
            var.INVOICING_LINE_ID = IL_Id;
            var.SEQ = 1;
            var.MSGTYPE = 'S';
            var.ERROR_MESSAGE = 'Success';
        } 
        else if (type == 'S_DOC'){
            var.CONTRACT_ID = ctr_Id;
            var.INVOICING_LINE_ID = IL_Id;
            var.SEQ = 1;
            var.MSGTYPE = 'S';
            var.ERROR_MESSAGE = 'Success';

            var_doc.CONTRACT_ID = ctr_Id;
            var_doc.INVOICING_LINE_ID = IL_Id;
            var_doc.SALES_ORDER_NUMBER = 'SO123';
            var_doc.SALES_ORDER_ITEM = '1';
            result.ET_DOCS.item.add(var_doc);
        }
        else if (type == 'E_ID'){
            result.ET_DOCS.item = null;
            var.CONTRACT_ID = ctr_Id;
            var.INVOICING_LINE_ID = null;
            var.SEQ = 1;
            var.MSGTYPE = 'E';
            var.ERROR_MESSAGE = 'Error';
        } 
        else if (type == 'E_IL'){
            result.ET_DOCS.item = null;
            var.CONTRACT_ID = ctr_Id;
            var.INVOICING_LINE_ID = IL_Id;
            var.SEQ = 1;
            var.MSGTYPE = 'E';
            var.ERROR_MESSAGE = 'Error';
        }
        else if (type == 'E_NO_IL'){
            result.ET_DOCS.item = null;
            var.CONTRACT_ID = ctr_Id;
            //var.INVOICING_LINE_ID = null;
            var.SEQ = 1;
            var.MSGTYPE = 'E';
            var.ERROR_MESSAGE = 'Error';
        }
        else if (type == 'EXP'){
            result.ET_DOCS.item = null;
            var.CONTRACT_ID = ctr_Id;
            var.INVOICING_LINE_ID = null;
            var.SEQ = 1;
            var.MSGTYPE = 'E';
            var.ERROR_MESSAGE = 'Error';

            result.ET_LOG.item.add(var);
            response.put('response_x', result); 
        }
        
        if (type != 'EXP'){
            result.ET_LOG.item.add(var);
            response1.ZSD_SALESFORCE_SALES_ORDERSResponse = result; 
            response.put('response_x', response1); 
        }
    }    
}