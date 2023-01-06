global without sharing class AP22_BatchRetrieveSignedDoc implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Schedulable {
/*  
----------------------------------------------------------------------
-- - Name          : AP22_BatchRetrieveSignedDoc   
-- - Author        : MRA
-- - Description   : Batch class to redo WS Call operation in bulk to retrieve signed documents from Universign for all previously failed records 
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 11-MAY-2017  MRA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/      
    String query;
    string source='Batch';
    global AP22_BatchRetrieveSignedDoc(){   
        query=' select id,Status__c,Contract__c,isSuccess__c,ExternalId__c,cTin_TECH_IsContractIn__c '+
              ' from eSignature__c ' +
              ' where Status__c = '+'\'' + AP_Constant.eSignatureCompletedStatus + '\'' +' and isSuccess__c = false '+ ' and cTin_SignatureDate__c=THIS_YEAR ' +' and contract__r.tech_isContractIn__c=true ' ;
              
              
              
              
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('## query'+query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Esignature__c> scope) { 
      map<id,esignature__c> esignToExcludeMap=new map<id,esignature__c>();

      if(scope.size()>0){
        for(contentDistribution cd:[select name,RelatedRecordId from contentDistribution where relatedRecordId In:scope]){
            if(cd.name.endsWith('_signed.pdf')){Esignature__c esignature=new Esignature__c(id=cd.relatedRecordId);esignToExcludeMap.put(cd.relatedRecordId,esignature);
            }
        }

        for(Esignature__c esign:scope){ 
          if(esignToExcludeMap.size()>0)    {
            if(!esignToExcludeMap.containsKey(esign.id))  {contract__c contract=new Contract__c(id=esignToExcludeMap.get(esign.id).Contract__c);AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esign,contract,source); 
            }
          }else{
            contract__c contract=new Contract__c(id=esign.Contract__c);         
              AP22_XmlRpcWrapper.CreateXmlRpcForSignedDocument(esign,contract,source); 
          }            
        }
      }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new AP22_BatchRetrieveSignedDoc(),10);
    }
    
}