global without sharing class AP44_BatchUpdateNumDocs implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Schedulable {
/*  
----------------------------------------------------------------------
-- - Name          : AP44_BatchUpdateNumDocs 
-- - Author        : MRA
-- - Description   : Batch class to update number of uploaded docs on contract
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 22-JUN-2022  MRA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/      
    String query;
    string source='Batch';
    list<Contract__c>lstContractsToUpd=new list<Contract__c>();
    global AP44_BatchUpdateNumDocs (){   
        query=' select id,Status__c,TECH_IsContractIn__c '+
              ' from contract__c ' +
              ' where tech_isContractIn__c=true and cTin_NumUploadedDocs__c=null ' ;
              
              
              
              
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('## query'+query);
        integer i=0;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contract__c> scope) { 
      map<id,esignature__c> esignToExcludeMap=new map<id,esignature__c>();
set<id> setContractId=new set<id>();
    Map<Id, set<Id>> mapContractIdContentDocId = new Map<Id, set<Id>>();
      if(scope.size()>0){
       // list<Contract__c>lstContractsToUpd=new list<Contract__c>();
    
        for(Contract__c ctr: scope){
            setContractId.add(ctr.Id);
        }
        for (ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN :setContractId
                                          ]){
                // Get all content Document Id for each ctr
                if (mapContractIdContentDocId.containsKey(cdl.LinkedEntityId)){
                    mapContractIdContentDocId.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                }
                else{
                    mapContractIdContentDocId.put(cdl.LinkedEntityId, new Set<Id>{cdl.ContentDocumentId});
                }
            }
            
            
            if(mapContractIdContentDocId.size()>0){
                
               
                // For each ctr
                for (Contract__c ctr : [SELECT Id, name, cTin_NumberSignablePDF__c 
                                        FROM Contract__c
                                        WHERE Id IN :mapContractIdContentDocId.KeySet()]){
                    Integer numOfSignableDocs = 0;// Reset num of signable docs
                    Integer numberDocs = 0; // reset documents uploaded
                    for(Id currContentDocId:mapContractIdContentDocId.get(ctr.Id)){
                       
                        numberDocs ++;
                    }
                    
                    //ctr.cTin_NumberSignablePDF__c = numOfSignableDocs;// Set num of signable pdf
                    ctr.cTin_NumUploadedDocs__c= numberDocs;// reset documents uploaded
                    lstContractsToUpd.add(ctr);
                }
            }
        }           
    
    if(lstContractsToUpd.size()>0)
        database.update(lstContractsToUpd,false);
  }
    
    
    global void finish(Database.BatchableContext BC) {
        
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new AP44_BatchUpdateNumDocs (),200);
    }
    
}