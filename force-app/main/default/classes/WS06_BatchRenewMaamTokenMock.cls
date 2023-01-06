@isTest
global class WS06_BatchRenewMaamTokenMock implements HttpCalloutMock {
    
    public Integer status;
    
    global WS06_BatchRenewMaamTokenMock(final Integer status){
        this.status = status; 
    }
    
    global HTTPResponse respond(HTTPRequest req) {

        //create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(this.status == 200){
        	res.setBody('{ "status" : "200", "message" : "Success", "access_token" : "eyJhbGciOiJSUzI1NiIsImtpZCI6IkFUMjAxODA0MjMifQ.TestdWQiOiJzYWxlc2ZvcmNlX3Blb3BsZXNvZnQiLCJybG0iOiJjbGllbnQiLCJjZWkiOiIxMThhNjdlZSIsInNjb3BlIjoidXJuOmF4YTpmcmFuY2U6c2FsZXNmb3JjZSIsImlzcyI6Imh0dHBzOlwvXC9tYWFtLWRldi5heGEuY29tXC9tYWFtXC92MiIsImV4cCI6MTYzNTQxNzkxNSwiaWF0IjoxNjM1NDE0MzE1LCJqdGkiOiJmYzYzNjU3MC0xYTc5LTQwZjctODIyYy05YTk4YmFlNjAyNDIiLCJjbGllbnRfaWQiOiIxOWQ1MDY5ZiJ9.dS9KiS8oxGpWMjHYtHJVbtMhP4jdfrZJuIBrxMkAodOWBV7Mvlf2xR0l0ZZ_fzaAN8Q813BgzWwEQbib6r1TrVK60UfGqup_yIlA_Lp09agtUi7DRK344aVPW85ZSbTs6qqSFC0e2tB6et7L8xMsRiDfki75e-aZCt_bDFoHL8lB3TlCeE8kcYfJtJJmCsnKUcJK-pIDuphVRWRCqeHPFJcrCRzVZNaj7qsycXSM_O1sX_8jyKaxVmgcuvPuueWUU64zkWqZcUFTNjzk-D8Sbcghd6Jh1lIkWNgdKdzB_n6WiPvzNC7TWdn2t-Nbfav2GRcAclL3LPElLTP0YcpfbQ" }');     
        	res.setStatusCode(200);
        }else{
            res.setBody('{ "status" : "501", "message" : "Error"}'); 
        	res.setStatusCode(501);    
        }
        
				

        return res;
    }
}