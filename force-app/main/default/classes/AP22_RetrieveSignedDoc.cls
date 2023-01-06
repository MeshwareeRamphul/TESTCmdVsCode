public without sharing class AP22_RetrieveSignedDoc {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_RetrieveSignedDoc 
-- - Author        : Spoon Consulting
-- - Description   : Retrieve signed document from Universign when esignature status changes to completed                   
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 10-MAY-2017  MRA    1.0     Initial
-- 10-OCT-2017  MRA    1.1     Evol Universign Contract-In : Updated to query cTin_TECH_IsContractIn__c
*************************************************************************************/
    
    // method retrieves signed content and updates content delivery of contract and esignature. 
    // Also updates the final document url of the contract with the public url of the signed content
    public static boolean hasExecuted=false;
    @future(callout=true)
    public static void getSignedDoc(set<id> esignatureIdSet){
        system.debug('## Starting method getSignedDoc');
        hasExecuted=true;
        string source='Trigger';
        for(esignature__c esignature:[Select Id, contract__c, ExternalId__c,isSuccess__c,cTin_TECH_IsContractIn__c
                                     from eSignature__c 
                                     where id in : esignatureIdSet limit 1] ){
            Contract__c contract=new Contract__c(id= esignature.contract__c);             
            AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esignature,contract,source);             
        }
                             
        system.debug('## Ending method getSignedDoc');
    }
}