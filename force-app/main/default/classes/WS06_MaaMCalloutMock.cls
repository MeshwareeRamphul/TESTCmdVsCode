@isTest
global class WS06_MaaMCalloutMock implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"example":"test","access_token": "theaccesstoken","expires_in": 3600,"id_token": "theidtoken"}');
        response.setStatusCode(200);
        return response;
    }
}