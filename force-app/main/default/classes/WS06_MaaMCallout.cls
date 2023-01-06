/**
 * @description       : Added custom setting variables so that not to hard code values
 * @author            : Anthony
 * @group             : 
 * @last modified on  : 10-28-2021
 * @last modified by  : VMU
**/
public class WS06_MaaMCallout{
/*
    --------------------------------------------------------------------------------------
    -- - Name          : WS06_MaaMCallout
    -- - Author        : Spoon
    -- - Description   : Call the Class WS02_SAPInvoiceLine
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 14-OCT-2021  ARA 1.0     Initial version
    */
   /* public static HttpResponse makePostCallout(){
        CS_MAAMAuthentication__c cs = CS_MAAMAuthentication__c.getInstance(UserInfo.getUserId());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(cs.Host__c);
        request.setMethod(cs.POST__c);
        request.setHeader('Content-Type', cs.Content_type__c);
        request.setHeader('client_id','3MVG9d8..z.hDcPJZPIzGJ5UZDrL7bJthAQ_v0YCxzEeG1XXXXXXXXXXXXXXXXXXXXX');
        request.setHeader('client_secret','XXXXXXXXXXX');
        request.setHeader('username','XXXXXXXXXXXXX.com');
        request.setHeader('password','XXXXXXXXXXXXX');
        request.setHeader('grant_type','password');
        HttpResponse response = http.send(request);
        return response;
    }*/

    public String alg {get;set;}
    public String typ {get;set;}
    public String iss {get;set;}
    public String sub {get;set;}
    public String aud {get;set;}
    public String exp {get;set;}
    public String iat {get;set;}
    public String jti {get;set;}
    public String client_id {get;set;}
    public String scope {get;set;}
    public Map<String,String> claims {get;set;}
    public Integer validFor {get;set;}
    public String cert {get;set;}
    public String pkcs8 {get;set;}
    public String privateKey {get;set;}
    
    public static final String HS256 = 'HS256';
    public static final String RS256 = 'RS256';
    public static final String NONE = 'none';
    
    public WS06_MaaMCallout(String alg, String typ) {
        this.alg = alg;
        this.typ = typ;
        this.validFor = 3600;
    }
    
    public String assertion() {
        CS_MAAMAuthentication__c cs = CS_MAAMAuthentication__c.getInstance(UserInfo.getUserId());
        String jwt = '';
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', 'HS256');
        header.writeStringField('typ', 'JWT');
        header.writeEndObject();
        String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
        
        Long rightNow = (dateTime.now().getTime()/1000)+1;
        system.debug('*****rightNOW:  '+rightNow);
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeStringField('iss', cs.ISS__c);
        body.writeStringField('sub', cs.SUB__c);
        body.writeStringField('aud', cs.AUD__c);
        //body.writeNumberField('iat', rightNow);
        body.writeStringField('jti', generateRandomString(16));
        body.writeNumberField('exp', (rightNow + 6000));
        //body.writeStringField('client_id', '19d5069f');
        //body.writeStringField('scope', 'urn:axa:france:salesforce');
        if (claims != null) {
            for (String claim : claims.keySet()) {
                body.writeStringField(claim, claims.get(claim));
            }
        }
        body.writeEndObject();
        jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
       
        if ( this.alg == HS256 ) {
            //Blob key = EncodingUtil.base64Decode(privatekey);
            Blob key = blob.valueof(cs.client_secret__c);
            Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
            jwt += '.' + base64URLencode(signature);  
        } else if ( this.alg == RS256 ) {
            Blob signature = null;
            
            if (cert != null ) {
                signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
            } else {
                Blob privateKey = EncodingUtil.base64Decode(pkcs8);
                signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);
            }
            jwt += '.' + base64URLencode(signature);  
        } else if ( this.alg == NONE ) {
            jwt += '.';
        }
        return jwt;
    }
    
    //public static string getjwt(){
      //  WS06_MaaMCallout ws06=new WS06_MaaMCallout();
      //  string jwt=WS06.assertion();
     //   return jwt;
   // }
    
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    //method returns payload
    public string getAccessToken() {
        CS_MAAMAuthentication__c cs = CS_MAAMAuthentication__c.getInstance(UserInfo.getUserId());
        
        String privateKey = cs.client_secret__c;
        String iss = cs.ISS__c;
        String sub = cs.SUB__c;
        String aud = cs.AUD__c;
        string jti=generateRandomString(16);
        //String jti = '20000000-1000-4000-8000-100000';
        Long exp = DateTime.now().addMinutes(60).getTime();
        String client_id = cs.client_id__c;
        String jwtHeader = '{"typ":"JWT","alg":"HS256"}';
        String scope =  cs.Scope__c;
        //String jwtClaims = '{"iss":"' + iss + '","sub":"' + sub + '","aud":"' + aud + '","exp":' + exp + ',"jti":"' + jti + '","client_id":"' + client_id + '","scope":"' + scope +'"}';
        
        String jwtClaims = '{"iss":"' + iss + '","sub":"' + sub + '","aud":"' + aud + '","exp":' + exp + ',"jti":"' + jti + '"}';

        String jwtRequest = System.encodingUtil.base64Encode(Blob.valueOf(jwtHeader)).replace('+', '-').replace('/', '_') + '.' + System.encodingUtil.base64Encode(Blob.valueOf(jwtClaims)).replace('+', '-').replace('/', '_');
        system.debug('*****jwtRequest : '+ jwtRequest);
        while ( jwtRequest.endsWith('=')){
            jwtRequest = jwtRequest.subString(0,jwtRequest.length()-1);
        }
        //for uat/int
        Blob key = EncodingUtil.base64Decode(privateKey);
        
        //for prod - we encode in base 64 before decoding since for prod, the key received from maam is a plain string, not encoded in base 64
        /*String KeyString = EncodingUtil.base64Encode(Blob.valueOf(privateKey));
        Blob key = EncodingUtil.base64Decode(keyString);*/
        
        String signature = System.encodingUtil.base64Encode(Crypto.generateMac('hmacSHA256',Blob.valueof(jwtRequest),key)).replace('+', '-').replace('/', '_');
        while ( signature.endsWith('=')){
            signature = signature.subString(0,signature.length()-1);
        }
        //system.debug('*****signature : '+ signature);
        String signedJwtRequest = jwtRequest + '.' + signature;
        
        String newSignedJwt = assertion();
        //system.debug('*****newSignedJwt : '+ newSignedJwt);
        
        String payload = 'client_assertion_type=' + 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer';
        payload += '&scope=' + scope;
        payload += '&grant_type=' + 'client_credentials';
        payload += '&client_id=' + client_id;
        payload += '&client_assertion=' + newSignedJwt;
        
        system.debug('*****payload : '+ payload);
        
        return payload;
    }

// To execute in developer console
    /*WS06_MaaMCallout maam = new WS06_MaaMCallout('HS256', 'JWT');
    maam.iss = '19d5069f';
    maam.sub = '19d5069f';
    maam.aud = 'https://maam-dev.axa.com/maam/v2/token';
    maam.exp = '';
    maam.iat = '';
    maam.jti = '20000000-1000-4000-8000-100000';
    maam.client_id = '19d5069f';
    maam.scope = 'urn:axa:france:salesforce';
    maam.privatekey = 'PJjSwhMDolnS1pmNSo9C032Bfb7olCLP0qzCSoALWyMyrwTYvvq7Mg';

    system.debug('***token : ' + maam.assertion()); */
}