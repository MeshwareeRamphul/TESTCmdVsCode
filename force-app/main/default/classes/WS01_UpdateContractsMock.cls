@isTest
public class WS01_UpdateContractsMock implements WebServiceMock {
/*
//Mock Class for  WS01_UpdateContractsTest : 
----------------------------------------------------------------------
-- - Name          : WS01_UpdateContractsMock
-- - Author        : Spoon Consulting
-- - Description   : Mock class for WS01_UpdateContractsTest
--                   
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks  
-- -----------  ----  -------  ---------------------------------------
-- 27-Jan-2017  RLA   1.0      Initial version

----------------------------------------------------------------------

*/  
    public void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
      //sapComDocumentSapRfcFunctions.ZSD_SALESFORCE_SALES_ORDERSResponse result = new sapComDocumentSapRfcFunctions.ZSD_SALESFORCE_SALES_ORDERSResponse();
      //result = new sapComDocumentSapRfcFunctions.ZSD_SALESFORCE_SALES_ORDERSResponse();
      //result.ET_DOCS = new sapComDocumentSapRfcFunctions.ZSD_SF_SALES_ORDERS_DOCS_TAB();
      //result.ET_DOCS.item = new list <sapComDocumentSapRfcFunctions.ZSD_SF_SALES_ORDERS_DOCS> ();
      //sapComDocumentSapRfcFunctions.ZSD_SF_SALES_ORDERS_DOCS var = new sapComDocumentSapRfcFunctions.ZSD_SF_SALES_ORDERS_DOCS ();
      
      WSDL_SalesOrder.ZSD_SALESFORCE_SALES_ORDERSResponse result = new WSDL_SalesOrder.ZSD_SALESFORCE_SALES_ORDERSResponse();
      result.ET_DOCS = new WSDL_SalesOrder.ET_DOCS();
      result.ET_DOCS.item = new list <WSDL_SalesOrder.item3>();
      WSDL_SalesOrder.item3 var = new WSDL_SalesOrder.item3 ();
      
      var.CONTRACT_ID = '1235';
      var.INVOICING_LINE_ID = 'a0C250000019xw3';
      var.SALES_ORDER_NUMBER = '123';
      var.SALES_ORDER_ITEM = '12';
      result.ET_DOCS.item.add(var);

      System.debug('##response:'+response);
      System.debug('##endpoint:'+endpoint);
      System.debug('##soapAction:'+soapAction);
      System.debug('##requestName:'+requestName);
      System.debug('##responseNS:'+responseNS);
      System.debug('##responseName: '+responseName);
      System.debug('##responseType: '+responseType);
      response.put('response_x', result);

        

        
        
   }    

}