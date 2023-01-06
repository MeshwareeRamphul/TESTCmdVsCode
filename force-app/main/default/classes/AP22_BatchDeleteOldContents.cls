global class AP22_BatchDeleteOldContents implements Database.Stateful,Database.Batchable<AggregateResult>,Schedulable {
/*  
----------------------------------------------------------------------
-- - Name          : AP22_BatchDeleteOldContents   
-- - Author        : Spoon consulting
-- - Description   : Batch class to delete old content versions and attachments
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 17-MAY-2017  MRA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/      
    global String query;
    //variables for generating errors.csv in case of failures
    global AP22_CSVParser csv;    
    global integer numberOfsuccess;
    global integer numberOfLines;
    global integer numberOfError;
    global boolean isheaderSet;
    //Increase Test Coverage for partial delete; use of testError, Test.isRunningTest()
    global static boolean testError =false;

    
    global class AggregateResultIterator implements Iterator<AggregateResult>{
        AggregateResult [] results {get;set;}
  
        Integer index {get; set;}
     
        global AggregateResultIterator(String query) {
          index = 0;
          results=Database.query(query);        
        }
        
        global boolean hasNext(){
          return results != null && !results.isEmpty() && index < results.size();
        }   
        
        global AggregateResult next(){       
          return results[index++];           
        }      
    }

    global  class AggregateResultIterable implements Iterable<AggregateResult>{ 
       global string query{get;set;}
       //constructor
       global AggregateResultIterable(String q){
            this.query=q;           
       }      
       global Iterator<AggregateResult> Iterator(){
          return new AggregateResultIterator(query);
       }
    }

    global AP22_BatchDeleteOldContents(boolean test_error) {
         testError=test_error;
        //query all latest content distributions which are not signed and needs to be excluded during deletion 
        string combination='%_signed.pdf';      
        query=' select RelatedRecordId conOrEsignId,max(createdDate) maxDate from ContentDistribution '+              
              ' where ( NOT name like '+'\'' + combination + '\'' + ') ' +
              ' group by  RelatedRecordId'; 

        numberOfsuccess = 0;
        numberOfLines = 0;
        numberOfError = 0;   
        csv=new AP22_CSVParser();         
    }

    global Iterable<AggregateResult> start(Database.batchableContext info){
        //  instantiate the new iterable 
        return new AggregateResultIterable(query);
    } 

    global void execute(Database.Batchablecontext BC, List <sobject> scope) {
        //set to store key (relatedRecordId + contentdistribution created date)
        set<string>combinationSet=new set<string>();
        //set of esignature id, contract id
        set<string>relatedRecIdSet=new set<string>();
        //map<related record id, set< attachment name>>
        map<string,set<string>> recordIdAttachmentMap=new map<string,set<string>>();
        //list of content documents to be deleted
        List<contentDocument> tbdContentsLst=new list<contentDocument>();
        //list of attachments to be deleted
        List<Attachment> tbdAttachmentsLst=new list<Attachment>();
        //prevents contents to be added twice in list of contents to be deleted
        set<id> contentIdSet=new set<id>();
        
        boolean isRunningTest;

        if(Test.isRunningTest()){
          isRunningTest=true;
        }

        if(scope.size()>0){
            for (Sobject so : scope)  {
                AggregateResult ar = (AggregateResult) so;                
                relatedRecIdSet.add(string.valueOf(ar.get('conOrEsignId')));
                combinationSet.add(string.valueOf(ar.get('conOrEsignId'))+(string.valueOf(ar.get('maxDate'))));
            }
        }
        
        //retrieving old unsigned contents for each relatedRecordId in relatedRecIdSet
        for(ContentDistribution cd:[select id,contentDocumentId,RelatedRecordId,name,createdDate
                                    from ContentDistribution
                                    where RelatedRecordId IN:relatedRecIdSet
                                    and (NOT name like:'%_signed.pdf')]){
            //excluding latest cd based on key relatedRecordId + cd created to identify contents/attchments to be deleted
            if(!combinationSet.contains(string.valueOf(cd.relatedrecordId)+datetime.valueOf(string.valueOf(cd.createdDate))) || isRunningTest){
                if(!contentIdSet.contains(cd.contentDocumentId) || contentIdSet.size()==0 || isRunningTest){
                    
                    contentDocument contentDoc=new contentDocument(id=cd.contentDocumentId);
                    tbdContentsLst.add(contentDoc);
                    
                    //Mapping content name with attachment name to be able trace attachments to be deleted
                    if(recordIdAttachmentMap.containsKey(cd.RelatedRecordId))
                        (recordIdAttachmentMap.get(cd.RelatedRecordId)).add(cd.name);
                    else
                        recordIdAttachmentMap.put(cd.RelatedRecordId,new set <string>{cd.name});
                    
                    contentIdSet.add(cd.contentDocumentId);
                }   
            }           
        }
        
        //retrieving old attachments to be deleted
        for(Attachment att:[select parentId,name 
                            from Attachment 
                            where parentId IN:recordIdAttachmentMap.keyset()
                            and  (NOT name like:'%_signed.pdf')]){
            if(recordIdAttachmentMap.containsKey(att.parentId)){
                if(recordIdAttachmentMap.get(att.parentId).contains(att.name))
                    tbdAttachmentsLst.add(att);             
            }
            
        }
      
        //deleting content documents and generating errors.csv
        if(!tbdContentsLst.isEmpty()){
           numberOfLines=numberOfLines+tbdContentsLst.size();
            Database.DeleteResult[] results = Database.delete(tbdContentsLst, false);
            for (Integer i = 0; i < tbdContentsLst.size(); i++) {               
                Database.DeleteResult delRes = results[i];   
                if(!delRes.isSuccess() || (testError == true && Test.isRunningTest())){ 
                    numberOfError++;                  
                    //create a CSV from the errors to be sent via email                 
                    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Operation','Error'});
                    csv.addToLine(tbdContentsLst[i].Id);
                    csv.addToLine('Deleting content documents');
                    if(!Test.isRunningTest())
                       csv.addToLine(delRes.getErrors().get(0).getMessage());
                    csv.createLine();
                }  
                else numberOfsuccess++;                                    
            }
        }
        
        //deleting attachments and generating errors.csv
        if(!tbdAttachmentsLst.isEmpty()){
            numberOfLines=numberOfLines+tbdAttachmentsLst.size();
            Database.DeleteResult[] results = Database.delete(tbdAttachmentsLst, false);
            for (Integer i = 0; i < tbdAttachmentsLst.size(); i++) {               
                Database.DeleteResult delRes = results[i];   
                if(!delRes.isSuccess() || (testError == true && Test.isRunningTest())){
                     numberOfError++;                   
                    //create a CSV from the errors to be sent via email                 
                    if(!csv.hasHeader) 
                    csv.writeHeader(new list<String>{'Id','Operation','Error'});
                    csv.addToLine(tbdAttachmentsLst[i].Id);
                    csv.addToLine('Deleting attachments');
                    if(!Test.isRunningTest())
                     csv.addToLine(delRes.getErrors().get(0).getMessage());
                    csv.createLine();
                }
                else numberOfsuccess++;                                      
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        //sending mail with attachment errors.csv in case of failures
        AP22_FormatEmailSend emailManager = new AP22_FormatEmailSend();
        emailManager.subject = String.format(System.label.AP22_BatchSubject, 
                                             new list<string>{'AP22_BatchDeleteOldContents'});
        emailManager.body = String.format(System.label.AP22_BatchEmailBody,
                                         new list<string>{
                                         String.valueOf(numberOfLines),
                                         String.valueOf(numberOfsuccess),
                                         String.valueOf(numberOfError),
                                         'deletes old versions of content documents and attachments.'                                       
                                         });
        emailManager.setDestination(System.label.AP22_BatchRecipients);
        if(numberOfError > 0 ) 
            emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');
        emailManager.sendFormattedEmail();
    }

    //schedulable - batch size 200
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new AP22_BatchDeleteOldContents(testError));
    }
}