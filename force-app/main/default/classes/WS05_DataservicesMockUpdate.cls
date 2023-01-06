@isTest
public class WS05_DataservicesMockUpdate implements WebServiceMock {
/*
----------------------------------------------------------------------
-- - Name          : WS05_DataservicesMockUpdate
-- - Author        : Spoon Consulting
-- - Description   : Mock class for WS05_Dataservices                
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

    WS04_SAPEntitiesOperations10.update_LegalResponseType response_x = new WS04_SAPEntitiesOperations10.update_LegalResponseType();
    //response_x.status = 'OK';
    response.put('response_x', response_x);

    }    
}