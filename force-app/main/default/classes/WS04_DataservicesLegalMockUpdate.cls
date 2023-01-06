@isTest
public class WS04_DataservicesLegalMockUpdate implements WebServiceMock {

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

    response_x.status = 'OK';
    response.put('response_x', response_x);

    }    
}