public without sharing class AP53_UncheckExpirePreference {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP53_UncheckExpirePreference
-- - Author        : Spoon Consulting (initial author of AXA Contract-In class AP53_UncheckExpirePreference)
-- - Description   : unchecks ExpirePreferences on content deliveries
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 30-APR-2019  MRA    1.0     Update content deliveries to uncheck ExpirePreferences and set expiry date to null
-- 02-SEP-2020  MRA   1.4     Copy password generated for signde copy on contract field "Password to access Final Document URL"
*****************************************************************************************/
    

    //method unchecks the option "Remove access to content" after uploading content delivery 
    public static void uncheckExpirePref(list<ContentDistribution>lstCd){

        string prefixContract=contract__c.sobjecttype.getDescribe().getKeyPrefix();

        string prefixsignature=eSignature__c.sobjecttype.getDescribe().getKeyPrefix();

        map<id,list<ContentDistribution>> mapConIdLstCd=new map<id,list<ContentDistribution>>();
        map<id,list<ContentDistribution>> mapEsignIdLstCd=new map<id,list<ContentDistribution>>();
        list<ContentDistribution> lstcdToUpt=new list<ContentDistribution>();

        for(ContentDistribution cd:lstCd){
           // if(cd.PREFERENCESEXPIRES ==true){
                if (string.valueOf(cd.relatedrecordId).startswith(prefixContract)){
                    if(!mapConIdLstCd.containsKey(cd.relatedrecordId)){
                        mapConIdLstCd.put(cd.relatedrecordId, new list<ContentDistribution>{cd});
                    }else{mapConIdLstCd.get(cd.relatedrecordId).add(cd);}
                }

                if (string.valueOf(cd.relatedrecordId).startswith(prefixsignature)){
                    if(!mapEsignIdLstCd.containsKey(cd.relatedrecordId)){
                        mapEsignIdLstCd.put(cd.relatedrecordId, new list<ContentDistribution>{cd});
                    }else{mapEsignIdLstCd.get(cd.relatedrecordId).add(cd);}
                }   
            //}
        }

        if(mapConIdLstCd.size()>0){
            for (contract__c con:[select id,TECH_IsContractIn__c 
                                  from contract__c 
                                  where id IN:mapConIdLstCd.keyset()
                                  and TECH_IsContractIn__c=true]){
                lstcdToUpt.addAll(mapConIdLstCd.get(con.id));
            }
        }

        if(mapEsignIdLstCd.size()>0){
            for (eSignature__c esign:[select id,cTin_TECH_IsContractIn__c 
                                  from eSignature__c 
                                  where id IN:mapEsignIdLstCd.keyset()
                                  and cTin_TECH_IsContractIn__c=true]){
                lstcdToUpt.addAll(mapEsignIdLstCd.get(esign.id));
            }
        }

        if(lstcdToUpt.size()>0){
            for(ContentDistribution cd: lstcdToUpt){
                system.debug('####3cd.name'+ cd);
                if(cd.PREFERENCESEXPIRES){
                cd.PREFERENCESEXPIRES=false;
                cd.expirydate=null;
                }
               
                system.debug('cd.name'+ cd.name);
                if(cd.name.contains('_signed')){
                 system.debug('##cd.name'+ cd.name);
                 cd.PreferencesPasswordRequired=true;
               
               }
            }
          
        }       
    }
    
     public static void RetrievePwd(list<ContentDistribution>lstcdWithPwd){
         system.debug('****cTin Starting method RetrievePwd');
         //map<string,string> mapRecIdFinalDocUrl=new map<string,string>();
         map<string,string> mapRecIdDocLinkUrl=new map<string,string>();
         map<string,string> mapUrlPwd=new map<string,string>();
         list<Contract__c> lstCtr=new list<Contract__c>();
         
         for(ContentDistribution cd: [select id,DistributionPublicUrl,password,relatedRecordId,PreferencesPasswordRequired,contentdocumentId from ContentDistribution where 
                                     id in:lstcdWithPwd]){
              system.debug('***cTin relatedRecordId'+cd.relatedRecordId);  
              system.debug('***cTin password'+cd.password);  
              if(cd.password!=null){                         
              //mapRecIdFinalDocUrl.put(cd.relatedRecordId,cd.DistributionPublicUrl); 
              mapRecIdDocLinkUrl.put(cd.relatedRecordId,cd.contentdocumentId);
              mapUrlPwd.put(cd.DistributionPublicUrl,cd.password); 
              }
         }

        for(Contract__c ctr : [select id,cTin_pwd__c,LinkToDocument__c from Contract__c where id in:mapRecIdDocLinkUrl.keyset()]){
                //ctr.FinalDocumentURL__c=mapRecIdFinalDocUrl.get(ctr.id);
                //ctr.cTin_pwd__c=mapUrlPwd.get(mapRecIdFinalDocUrl.get(ctr.id));
                ctr.LinkToDocument__c=System.Label.Contract_LinkToDocument+mapRecIdDocLinkUrl.get(ctr.id)+'/view';
                lstCtr.add(ctr);       
        }
        
        if(lstCtr.size()>0)
             update lstCtr;   
     }
        
 }