public class AP48_blockFileUpdate{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP48_blockFileUpdate
-- - Author        : Spoon
-- - Description   : blocks users from checking/unchecking "send for esignature" if contract is sent for approval
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 03-Jun-2020  MRA    1.0     BAU Bundle 3.4 Ticket : SP-00257
-- 19-Apr-2022  AMA    2.0     BAU Bundle 3.4 Ticket : SP-03413
*************************************************************************************/
    
    //method displays an error message and blocks users from checking/unchecking "send for esignature" if contract is sent for approval
    public static void blockUpdtFile(list<ContentVersion>lstCv){         
         system.debug('## starting blockUpdtFile');
        system.debug ('## lstCv'+lstCv);
         //Contentversion cv;
         list<contract__c> lstcon=new list<contract__c>();
         set<id>relatedContractSet=new set<id>();
         map<id,id> mapContractCv=new map<id,id>();
         set<id>setcontentdocId=new set<id>();
        map<id,id> mapcdcv=new map<id,id>();
         for( contentversion cv :lstCv ){
             if(cv.islatest)
            	setcontentdocId.add(cv.contentDocumentId);
         }
        //Select id, ContentDocumentId, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where LinkedEntityId IN (some list of obj Ids) 
         //query content distriution linked to content version
         for (ContentDistribution cd :[SELECT id,RelatedRecordId,ContentVersionId,contentDocumentId
                                        FROM ContentDistribution
                                        WHERE (ContentVersionId IN: lstCv
                                       or contentDocumentId in :setcontentdocId)
                                      ]){
              if(string.valueOf(cd.RelatedRecordId).startsWith('a0D'))    {
                      mapContractCv.put(cd.RelatedRecordId,cd.ContentVersionId);
               
                              
              }                                    
           }  
          system.debug ('## mapContractCv' + mapContractCv);
          //query contracts linked to content version being edited
          list<contract__c> lstCtr = [select id,status__c 
                                      from contract__c 
                                      where id IN: mapContractCv.keyset() 
                                      and status__c!=:'In Progress'
                                      and status__c!=:'Draft'];
        
          Profile profile = [select id, name from profile where id=:userinfo.getProfileid()];
        
          if(lstCtr.size()>0) {
              for(Contract__c con:lstCtr){
                  //display error message if contentversion is linked to a contract beyond 'In Progress' status
                 for(Contentversion cv:lstCv){
                    if(mapContractCv.get(con.id)==cv.id  || mapContractCv.containsKey(con.id) && profile.name != AP_Constant.systemAdmin)
                        cv.addError(system.label.cTin_BlockUpdateFile);
                  }  
                 
              }            
          }
          
  }
      
}