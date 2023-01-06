@isTest
public class WS04_DataservicesMockInsert implements WebServiceMock {

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

	 WS04_SAPEntitiesOperations10.insert_CommercialResponseType response_x = new WS04_SAPEntitiesOperations10.insert_CommercialResponseType();

    response_x.status = 'OK';

    WS04_SAPEntitiesOperations10.inserted_element insertedElem = new WS04_SAPEntitiesOperations10.inserted_element();
    insertedElem.predicate = new string[]{'X1X', 'X2X', 'X3X'};
    response_x.inserted = insertedElem;
    response.put('response_x', response_x);
    }    
}