/**
 * @description       : 
 * @author            : VMU
 * @group             : 
 * @last modified on  : 10-28-2021
 * @last modified by  : VMU
**/
global class WS06_BatchRenewMaamToken implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful, Schedulable{
/*  
----------------------------------------------------------------------
-- - Name          : WS06_BatchRenewMaamToken 
-- - Author        : Spoon
-- - Description   : Batch executes every 50 min to request a new Maam Token 
                     (stored in custom metadata MaamAuth)
-- -                 
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 14-OCT-2021  Spoon 1.0      Intitial version
-- 25-OCT-2021  VMU   1.1      store the access token in the access token field of the maam token record
----------------------------------------------------------------------
**********************************************************************
*/
    global String alg='HS256';
    global String typ='JWT';
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        system.debug('## starting batch WS06_BatchRenewMaamToken');

        String soqlQuery ='SELECT ClientID__c,Endpoint__c,LastRenewDate__c,Token__c,Access_token__c,NextRenewalTime__c,TokenRenewalMessage__c FROM MaaMAuthToken__c limit 1';
        return Database.getQueryLocator(soqlQuery);
    }
     
    global void execute(Database.BatchableContext bc, List<sObject>scope){ 
        system.debug('## Executing batch WS06_BatchRenewMaamToken');       
        List<MaaMAuthToken__c> MaamAuthToken = (List<MaaMAuthToken__c>)scope;
        List<MaaMAuthToken__c> refreshMaamAuthToken  = new List<MaaMAuthToken__c>(); 
         
        if(MaamAuthToken.size()>0){
            WS06_MaaMCallout ws = new WS06_MaaMCallout(alg, typ);
            string payload=ws.getAccessToken();
            string errorMsg='';
            
            if(!(string.isblank(payload))){
                //do a callout to obtain the access token
                Http httpObj = new Http();
                HttpRequest req = new HttpRequest();
                HttpResponse res;
        
                req.setEndpoint(MaamAuthToken[0].Endpoint__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');               
                req.setBody(payload);
                system.debug('## payload : ' + payload);
                system.debug('## request : ' + req);
               
                try{
                    res = httpObj.send(req);
                    system.debug('## result : ' + res );
                }
                catch(Exception e){
                    errorMsg = e.getMessage();
                    system.debug('## Exception errorMsg : ' + errorMsg);
                }
                
                if(res.getStatusCode() == 200){                  
                   
                    MaamAuthToken[0].Token__c=payload;                    
                    MaamAuthToken[0].TokenRenewalMessage__c ='Token retrieved successfully';
                    MaamAuthToken[0].LastRenewDate__c=system.now(); 
                    MaamAuthToken[0].NextRenewalTime__c=(system.now()).addHours(1);
                    //VMU 25/10/21 - extract the access token from the json response
                    map<string,Object> mapJsonResponse = (map<string,Object>)JSON.deserializeUntyped(res.getBody());
                    if(mapJsonResponse.containsKey('access_token')){
                        MaamAuthToken[0].Access_token__c = (String)mapJsonResponse.get('access_token');
                    }
                    refreshMaamAuthToken.add(MaamAuthToken[0]);           
                }
                else{
                    //System.debug('Error-' + e.getMessage());  
                    MaamAuthToken[0].TokenRenewalMessage__c ='Failed to renew token ' + errorMsg;
                    refreshMaamAuthToken.add(MaamAuthToken[0]);  
                }  
                 
            }
            else{
                //System.debug('Error-' + e.getMessage());  
                MaamAuthToken[0].TokenRenewalMessage__c ='Metadata is empty';
                refreshMaamAuthToken.add(MaamAuthToken[0]);  
            } 
            
            //refresh Metadata
            if(refreshMaamAuthToken.size()>0)  {
              try{
                update refreshMaamAuthToken;
              }
              catch(exception e){
                system.debug('## error : '+e.getmessage());
              }
            }                
        }
    }
     
    global void finish(Database.BatchableContext bc){
        system.debug('## Finishing batch WS06_BatchRenewMaamToken');   
         //if(reFreshMaamMetaData.size()>0)  
            // upsert reFreshMaamMetaData[0];
    }
    global void execute(SchedulableContext sc) {
        WS06_BatchRenewMaamToken b = new WS06_BatchRenewMaamToken (); 
        database.executebatch(b);
     }
}