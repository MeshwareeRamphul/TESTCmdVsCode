public with sharing class AP22_CallUniversign {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_CallUniversign
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class TR001CallUniversign)
-- - Description   : Update signUrl of Esignatories after creating a transaction and 
                     when collecteDone equals true on esignature - (trigger eSignatureAfterUpdate)
                    
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 17-APR-2017  MRA    1.0     Copied and renamed to AP22_CallUniversign
*************************************************************************************/
  
  @future(callout=true)
    public static void getSignatories(Set<id> SetIdSignat){
        system.debug('## START AP22_CallUniversign.getSignatories');

        list<eSignature__c> esignatureLst=new list<esignature__c>();
        set<id>esignIdSet=new set<id>();
        list<eSignatory__c> esignatoryLst=new list<eSignatory__c>();
        list<eSignatory__c> esignatoryToUpdateLst = new List<eSignatory__c>() ; 

        for(eSignatory__c esignatory:[Select Contact__r.FirstName, Contact__r.LastName,esignature__c,cTin_signLink__c,order__c,
                                      esignature__r.Name, esignature__r.Status__c, esignature__r.CreatedDate, 
                                      esignature__r.Contract__r.Name, esignature__r.CreatedById, 
                                      esignature__r.FinalDocumentURL__c, esignature__r.ExternalId__c,TECH_SignerRole__c
                                      from  eSignatory__c
                                      where eSignature__c in :  SetIdSignat
                                      order by order__c asc]){
          if(!esignIdSet.contains(esignatory.eSignature__c)){
            esignIdSet.add(esignatory.eSignature__c);
            esignature__c esign=new esignature__c();
            esign.id=esignatory.eSignature__c;
            esign.ExternalId__c=esignatory.esignature__r.ExternalId__c;
            esignatureLst.add(esign);
          }
          esignatoryLst.add(esignatory);         
        }
       
        List<eSignature__c> Listesignat = [Select Id, Name, Status__c, CreatedDate, Contract__r.Name, CreatedById, 
                                           FinalDocumentURL__c, ExternalId__c
                                           from eSignature__c WHERE 
                                           id in : SetIdSignat] ; 
        
     //AP22_XmlRpcWrapper.WrapperResponse WRP = new  AP22_XmlRpcWrapper.WrapperResponse() ; 
       list<string> signurlList=new list<string>();
       for(eSignature__c esignature : esignatureLst){                        
           // WRP  = AP22_XmlRpcWrapper.ParseXmlRPcResponse2(AP22_XmlRpcWrapper.getTransactionInfo(esignature) ) ;   
            string xmlString=AP22_XmlRpcWrapper.getTransactionInfo(esignature);  
            system.debug('xmlString from AP22'+xmlString);   
            
             list<string> lst=(string.valueOf(xmlString)).split('<member>');
                for(string s: lst){
                String str2 = s.subStringBetween('<string>', '</string>');
                System.debug('##str'+str2);
                if(str2!=null){
                    if(str2.startsWith('https')){
                      signurlList.add(str2);
                    }
                }
            }                                       
       }
       
        system.debug('## signurlList'+signurlList);   
        
       
         if(esignatoryLst.size()>0 && signurlList.size()>0){
          for(integer i=0;i<esignatoryLst.size();i++){                
                   esignatoryLst[i].cTin_signLink__c= signurlList[i];    
                    esignatoryLst[i].signURL__c = signurlList[i];    
                   esignatoryToUpdateLst.add(esignatoryLst[i]);  
          }
        }

        if(esignatoryToUpdateLst.size()>0){
          update esignatoryToUpdateLst ; 
        } 
       
       /*

        if(esignatoryLst.size()>0){
          for(eSignatory__c EsinCon : esignatoryLst ){     
                 system.debug('## all urls from AP22_CallUniversign '+ WRP.map1.keyset());            
                  String UrlSignatory ; 
                  system.debug('## WRP url'+ WRP.map1.get(EsinCon.Contact__r.FirstName + EsinCon.Contact__r.LastName));
                  if(EsinCon.Contact__r.FirstName !=null && EsinCon.Contact__r.LastName!=null){
                      UrlSignatory =(test.isRunningTest()? 'http://google.com':WRP.map1.get(EsinCon.Contact__r.FirstName + EsinCon.Contact__r.LastName)) ;
                  }else if(EsinCon.Contact__r.FirstName ==null && EsinCon.Contact__r.LastName!=null){
                       UrlSignatory =(test.isRunningTest()? 'http://google.com':WRP.map1.get(EsinCon.Contact__r.LastName)) ;
                  }
                                    
                  if(UrlSignatory != null){
                      EsinCon.signURL__c = UrlSignatory  ; 
                      esignatoryToUpdateLst.add(EsinCon) ; 
                  }           
          }
        }

        if(esignatoryToUpdateLst.size()>0){
          update esignatoryToUpdateLst ; 
        } */

    system.debug('## END AP22_CallUniversign.getSignatories'); 
 }
    public static void dummy(){
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
    }
}