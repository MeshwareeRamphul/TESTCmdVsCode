public class AP71_AccValidateReqDoc {
/*
----------------------------------------------------------------------
-- - Name          : AP71_AccValidateReqDoc 
-- - Author        : Spoon Consulting 
-- - Description   : class for checking / unchecking TOBA Uploaded on Account
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 26-MAY-2022  MRA 1.0      Intitial version (SP-03904)
**************************************************************************/
    public static void checkTOBAUploaded(set<id>setAccId,set<id>contentDocSet,string operationType){
        //select conten
        map<string,string> mapAccIdDesc=new map<string,string>();
        string descFile='';
        list<Account>lstAcc=new list<Account>();
        for(ContentDocumentLink cdl :[SELECT id, LinkedEntityId, ContentDocumentId,contentdocument.description FROM ContentDocumentLink WHERE LinkedEntityId IN:setAccId ]){
             // TOBA_uploaded__c
             if(operationType=='insert'){
                  descFile=descFile+cdl.contentdocument.description;
                  mapAccIdDesc.put(cdl.LinkedEntityId,descFile);
                  system.debug('## AP71_AccValidatedReqDoc description'+ cdl.contentdocument.description);
             }
            else{
                if(!contentDocSet.contains(cdl.ContentDocumentId))
                  descFile=descFile+cdl.contentdocument.description;
                  mapAccIdDesc.put(cdl.LinkedEntityId,descFile);
            }
        }
        
        if(mapAccIdDesc.size()>0){
            for(string  AccId : mapAccIdDesc.keyset()){
                Account acc;
                if(!string.isblank(mapAccIdDesc.get(AccId)) && mapAccIdDesc.get(AccId).contains('TOBA'))
                     acc=new Account(id=AccId,TOBA_uploaded__c=true);
                
                else
                     acc=new Account(id=AccId,TOBA_uploaded__c=false);
                
                lstAcc.add(acc);
            }
            
            if(lstAcc.size()>0)
                update lstAcc;
        }
    }
}