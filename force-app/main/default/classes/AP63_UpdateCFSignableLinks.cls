public without sharing class AP63_UpdateCFSignableLinks{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP63_UpdateCFSignableLinks
-- - Author        : Spoon Consulting 
-- - Description   : populate cTin_ViewSignableDocuments__c on CF whenever link to document is updated
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
--20-AUG-2021  MRA    1.0     Initial version - SP-01720
************************************************************************************/
  public static boolean hasAlreadyFired = false;
  public static void UpdateLinks(set<id>contractIdSet){
       hasAlreadyFired=true;
       map<string,list<string>> mapCtrContentDoc=new map<string,list<string>>(); // map of contract id => content document link
  
       for(ContentDistribution cd: [SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId,ContentVersion.Sign_able__c 
                                            FROM ContentDistribution
                                            WHERE RelatedRecordId IN: contractIdSet
                                            and  ContentVersion.Sign_able__c=:true                                             
                                            order by LastmodifiedDate Desc]){
                    
              if(mapCtrContentDoc.containsKey(cd.RelatedRecordId)) {
                list<string> lsturls= mapCtrContentDoc.get(cd.RelatedRecordId);
                lsturls.add(System.Label.Contract_LinkToDocument + cd.contentDocumentId+'/view');
                mapCtrContentDoc.put(cd.RelatedRecordId, lsturls);
               } 
              else {
                 mapCtrContentDoc.put(cd.RelatedRecordId, new list<string> { System.Label.Contract_LinkToDocument + cd.contentDocumentId+'/view'});
              }                        
                                            
      }
      
      system.debug('### AP63'+contractIdSet);
      
      
      if(contractIdSet.size()>0){
       
         
         
         list <cTin_ContractForm__c> lstCf=new list<cTin_ContractForm__c  >();
         
         for  (cTin_ContractForm__c  cf: [select id,cTin_Contract__c , cTin_Contract__r.cTin_NumberSignablePDF__c,cTin_ViewSignableDocuments__c from cTin_ContractForm__c where cTin_Contract__c IN:contractIdSet]){
             
             system.debug('### AP63 cTin_Contract__r.cTin_NumberSignablePDF__c'+cf.cTin_Contract__r.cTin_NumberSignablePDF__c);
              
             if(cf.cTin_Contract__r.cTin_NumberSignablePDF__c!=0  ){
                if(mapCtrContentDoc.containsKey(cf.cTin_Contract__c )){
                     string link='';
                     for( string links: mapCtrContentDoc.get(cf.cTin_Contract__c )){
                         system.debug('### AP63 link 1 ' +link);
                         system.debug('### AP63 links' +links);
                         link=link+ links   + '<br>';
                         system.debug('### AP63 link 2' +link);
                     }
                     system.debug('### AP63 link 3' +link);
                     cf.cTin_ViewSignableDocuments__c =link;
                 }
                else {
                cf.cTin_ViewSignableDocuments__c ='';
                }
             } 
             else{
                 system.debug('### AP63 else'); 
                 cf.cTin_ViewSignableDocuments__c ='';
             }

             lstCf.add(cf);
         }
        
         
          if(lstCf.size()>0)
          update lstCf;
      
      }
      
                                         
  
  
  }
 
 }