global without sharing class AP57_BatchEnablePwdProtect implements Database.Batchable<sobject>,Database.Stateful,schedulable { 
/*  
----------------------------------------------------------------------
-- - Name          : AP57_BatchEnablePwdProtect 
-- - Author        : SC
-- - Description   : Enables password protection : Checks "PreferencesPasswordRequired" on signed content deliveries 
-- -                 
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 11-AUG-2020  MRA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
    //counters for number of success, failures , number of files to be generated 
    global integer numberOfsuccess;
    global integer numberOfLines;
    global integer numberOfError;
  

    
    //variables for sending mail with error.csv as attachment after exceution of batch
    global boolean isheaderSet;
    global AP00_CSVParser csv; 
    
    global AP57_BatchEnablePwdProtect (){
        system.debug('## AP56_BatchGenerateFile >> Constructor method Begins');
        csv = new AP00_CSVParser();
        numberOfsuccess=0;
        numberOfLines=0;
        numberOfError=0;
        
        system.debug('## AP00_BatchGenerateFile >> Constructor method Ends');
    }
    
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new AP57_BatchEnablePwdProtect (),10); //set smaller batch size to avoid heap limits / cpu limits
    }
    
    global Database.Querylocator start(Database.BatchableContext BC){    
        system.debug('## AP00_BatchGenerateFile >> Start method Begins');
          //query all signed content delivery
          return Database.getQueryLocator([select id,name,relatedrecordId,PreferencesPasswordRequired from contentdistribution
                                           where name like: '%sign%'and PreferencesPasswordRequired =false
                                           and relatedrecordId!=:null]);
        
    }
    
    global void execute (Database.Batchablecontext BC, List <sobject> scope){

        map<string,ContentDistribution> mapCtrIdCd=new map<string,ContentDistribution>();
        map<string,ContentDistribution> mapEsignIdCd=new map<string,ContentDistribution>();
        map<string,list<ContentDistribution>> mapObjIdCd=new map<string,list<ContentDistribution>>();
        set<id>cTinRelatedCdSet=new set<id>(); //contains all cd linked to cTin
        list<ContentDistribution> lstCd=new list<ContentDistribution>();
        
        string prefixContract=contract__c.sobjecttype.getDescribe().getKeyPrefix();
        string prefixsignature=eSignature__c.sobjecttype.getDescribe().getKeyPrefix();
        
        List<contentdistribution> lstContentDist= (List<contentdistribution>)scope;
         for(contentdistribution cd: lstContentDist){
            if (string.valueOf(cd.relatedrecordId).startswith(prefixContract)){
                mapCtrIdCd.put(cd.relatedrecordId, cd);   
            }
            
            if (string.valueOf(cd.relatedrecordId).startswith(prefixsignature)){
                mapEsignIdCd.put(cd.relatedrecordId, cd);   
            }
            
            if(mapObjIdCd.containsKey(cd.relatedrecordId)) {
                List<ContentDistribution> lstContent= mapObjIdCd.get(cd.relatedrecordId);
                lstContent.add(cd);
                mapObjIdCd.put(cd.relatedrecordId, lstContent);
            } else {
                mapObjIdCd.put(cd.relatedrecordId, new List<ContentDistribution> { cd });
            }
                       
        }
        
        
       for(Contract__c con: [select Id from Contract__c 
                              where tech_isContractIn__c= : true     
                              and id IN: mapCtrIdCd.keyset()]){
           cTinRelatedCdSet.add(con.Id);           
        }
        
        for(esignature__c esign: [select Id from esignature__c
                              where contract__r.tech_isContractIn__c= : true     
                              and id IN: mapEsignIdCd.keyset()]){
           cTinRelatedCdSet.add(esign.Id);           
        }
        
        if(cTinRelatedCdSet.size()>0){
            for(Id objId:cTinRelatedCdSet){
                    for(ContentDistribution cd: mapObjIdCd.get(objId)){
                        cd.PreferencesPasswordRequired=true;  
                        lstCd.add(cd);
                    }
                }       
         }
        
         if (lstCd.size()>0){       
            list<Database.SaveResult> results = Database.update(lstCd,false); 
            numberOfLines=lstCd.size();
            for (Integer i = 0; i < lstCd.size(); i++) {
                Database.SaveResult sr = results[i];    
                if(!sr.isSuccess()){  
                    numberOfError++;
                    //create a CSV from the errors to be sent via email                 
                    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Name','RelatedRecordId','Operation','Error'});
                    csv.addToLine(lstCd[i].Id);
                    csv.addToLine(lstCd[i].Name);
                    csv.addToLine(lstCd[i].RelatedRecordId);
                    csv.addToLine('Enabling password protection on content delivery');
                    csv.addToLine(sr.getErrors().get(0).getMessage());
                    csv.createLine();                   
                }
                else numberOfsuccess++;                                    
            }
        }
 
    }
    
    global void finish (Database.BatchableContext BC){
        // reset numberOfLines to get correct number  
        numberOfLines = numberOfsuccess + numberOfError;
        // no more contract to process, so send email for batch completion
        AP00_FormatEmailSend emailManager = new AP00_FormatEmailSend();
        emailManager.subject = 'Completion of batch : Enabling password protection on signed pdfs';
        emailManager.body = String.format(System.label.cTin_AP57batchEmailBody,
                                          new list<string>{
                                                  String.valueOf(numberOfLines),
                                                  String.valueOf(numberOfsuccess),
                                                  String.valueOf(numberOfError)                                      
                                                  });
        
        emailManager.setDestination(System.label.cTin_batchEmailAddress);
        
        if(numberOfError > 0) emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');
        // if(numberOfRecError > 0) emailManager.generateAttachment('UpdatingRecErrors.csv',csv.getBlobBody(),'text/csv');
        emailManager.sendFormattedEmail();
    }

}