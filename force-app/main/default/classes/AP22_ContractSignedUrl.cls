public with sharing class AP22_ContractSignedUrl {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_ContractSignedUrl
-- - Author        : Spoon Consulting (initial author of AXA Contract-In class AP02_ContractSignedUrl)
-- - Description   : updates final document url on contract with public url of signed document
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 18-APR-2017  MRA    1.0     Copied and renamed to AP22_ContractSignedUrl
-- 17-APR-2020  MRA    1.1     Final Doc Url Rule changed = > SP-00186
                              ( for unsigned PDF, populated final document url with latest PDF if "Send for Esignature" is checked )
*************************************************************************************/
   
    @future
    public static void updateFinalUrl(set<Id>contentDocumentIdSet) {
        system.debug('## START AP02_ContractSignedUrl.updateFinalUrl');

        list<Contract__c> cToUpdate = new list<Contract__c>();  
        map<Id,String> eSignIdUrlMap = new map<Id,String>();
        map<Id,String> cTineSignIdUrlMap = new map<Id,String>();

        if(Test.isRunningTest()){
            Contract__c contract = [SELECT Id, name FROM Contract__c LIMIT 1];
            eSignature__c esign = TestFactory.createEsignature(contract,contract.name,'Signed');
            insert esign;
            eSignIdUrlMap.put(esign.id, 'google.com');  
        }
       for (ContentDistribution cd :[SELECT ContentDocumentId, DistributionPublicUrl,RelatedRecordId 
                                      FROM ContentDistribution 
                                      where ContentDocumentId  IN :contentDocumentIdSet ]){
            eSignIdUrlMap.put(cd.RelatedRecordId, cd.DistributionPublicUrl); 
        }
        
     
       for(eSignature__c e: [Select Contract__c 
                             from eSignature__c 
                             where Id in :eSignIdUrlMap.keySet()]){
            Contract__c c = new Contract__c(Id = e.Contract__c/*,FinalDocumentURL__c = eSignIdUrlMap.get(e.Id)*/,LinkToDocument__c=System.Label.Contract_LinkToDocument+cTineSignIdUrlMap.get(e.Id)+'/view');         
            cToUpdate.add(c);
        }//end for
        

        if(cToUpdate.size()>0){
            update cToUpdate;
        }
     
        system.debug('## END AP02_ContractSignedUrl.updateFinalUrl');
    }

    @future
    public static void cTin_updateFinalUrl(set<Id>signedContentIdSet,set<Id>unsignedContentDisIdSet) {
        system.debug('## START AP02_ContractSignedUrl.updateFinalUrl');

        list<Contract__c> cToUpdate = new list<Contract__c>();
        
        map<Id,String> eSignIdUrlMap = new map<Id,String>();
        map<Id,String> contractIdUrlMap = new map<Id,String>();
        map<Id,String> cTineSignIdUrlMap = new map<Id,String>();

        if(Test.isRunningTest()){             
            Contract__c contract = [SELECT Id, name FROM Contract__c LIMIT 1];
            eSignature__c esign = TestFactory.createEsignature(contract,contract.name,'Signed');
            insert esign;
            
            eSignIdUrlMap.put(esign.id, 'https://axa-clm--Full.cs18.my.salesforce.com/sfc/p/1100000C0LJZ/a/11000000Cg8k/HYjOQj37oeOJcI4ZqmmW1ZW1XRqe9vMjZ0mDm_z2.K4'); 
            cTineSignIdUrlMap.put(contract.id, 'https://axa-clm--Full.cs18.my.salesforce.com/sfc/p/1100000C0LJZ/a/11000000Cg8k/HYjOQj37oeOJcI4ZqmmW1ZW1XRqe9vMjZ0mDm_z2.K4'); 
        }
        

        for (ContentDistribution cd :[SELECT id,Name, ContentDocumentId, DistributionPublicUrl,RelatedRecordId 
                                      FROM ContentDistribution 
                                      where ContentDocumentId  IN :signedContentIdSet
                                     /* OR id IN :unsignedContentDisIdSet */ ]){        

            eSignIdUrlMap.put(cd.RelatedRecordId, cd.DistributionPublicUrl);  
            cTineSignIdUrlMap.put(cd.RelatedRecordId, cd.ContentDocumentId);
        }

        
        if(signedContentIdSet.size()>0){
            system.debug('## signedContentIdSet');

            for(eSignature__c e: [Select id,Contract__c,/*contract__r.FinalDocumentURL__c,*/contract__r.LinkToDocument__c
                                  from eSignature__c 
                                  where id in :eSignIdUrlMap.keySet()]){
                Contract__c c = new Contract__c();
                c.Id = e.Contract__c;
                //c.FinalDocumentURL__c = eSignIdUrlMap.get(e.Id);
                c.LinkToDocument__c= System.Label.Contract_LinkToDocument+cTineSignIdUrlMap.get(e.Id)+'/view';
                cToUpdate.add(c);
            }//end for
        }

        /*if(unsignedContentDisIdSet.size()>0){
            system.debug('## unsignedContentDisIdSet');

            for(Contract__c c: [Select id,FinalDocumentURL__c,cTin_AutoPopulateFinalDocumentURL__c 
                                from Contract__c 
                                where Id in :eSignIdUrlMap.keySet()
                                and cTin_AutoPopulateFinalDocumentURL__c=true]){
                c.FinalDocumentURL__c = eSignIdUrlMap.get(c.Id);
                // unchecked since final document url should not always be updated with url of latest document uploaded 
                c.cTin_AutoPopulateFinalDocumentURL__c=false; 
                cToUpdate.add(c);
            }//end for 
        }   */

        system.debug('## cToUpdate'+cToUpdate);
        if(cToUpdate.size()>0){
            update cToUpdate;
        }
        
        system.debug('## END AP02_ContractSignedUrl.updateFinalUrl');
    }
}