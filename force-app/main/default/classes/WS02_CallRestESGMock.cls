@isTest
global class WS02_CallRestESGMock implements HttpCalloutMock {

    public Integer status;

    global WS02_CallRestESGMock(final Integer status){
        this.status = status;
    }

    global HTTPResponse respond(HTTPRequest req) {

        //create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "status" : "'+status+'", "message" : "Success" }'); 
				

        res.setStatusCode(status);
        return res;
    }
}