@isTest
public class WS03_SAPLegalEntityMock implements WebServiceMock {
/*
//Mock Class for WS03_SAPLegalEntitTest : 
----------------------------------------------------------------------
-- - Name          : WS03_SAPLegalEntityMock
-- - Author        : Spoon Consulting
-- - Description   : Mock class for WS03_SAPLegalEntity
--                   
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks  
-- -----------  ----  -------  ---------------------------------------
-- 28-JUN-2017  MCU   1.0      Initial version

----------------------------------------------------------------------

*/  
public void doInvoke( Object stub,
                      Object request,
                      Map<String, Object> response,
                      String endpoint,
                      String soapAction,
                      String requestName,
                      String responseNS,
                      String responseName,
                      String responseType) 
    {


        WS03_SAPLegalEntity.wrapperResponse result;
        result.Vendor = null;
        result.Status = 'OK';
        result.Message = 'Legal entity created in Salesforce';
        result.SFDCID = 'a0C250000019xw3'; 

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