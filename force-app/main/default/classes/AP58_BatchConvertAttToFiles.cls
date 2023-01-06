global without sharing class AP58_BatchConvertAttToFiles implements Database.Batchable<sobject>,Database.Stateful,schedulable { 
/*  
----------------------------------------------------------------------
-- - Name          : AP58_BatchConvertAttToFiles 
-- - Author        : SC
-- - Description   : Batch converts cTin attachment to Files
-- -                 
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 08-SEP-2020  MRA    1.0      Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
    //counters for number of success, failures , number of files to be generated 
    global integer numberOfsuccess;
    global integer numberOfLines;
    global integer numberOfError;
    global set<id> ctrIds;

    
    //variables for sending mail with error.csv as attachment after exceution of batch
    global boolean isheaderSet;
    global AP00_CSVParser csv; 
    
    global AP58_BatchConvertAttToFiles (){
        system.debug('## AP58_BatchConvertAttToFiles >> Constructor method Begins');
        csv = new AP00_CSVParser();
        numberOfsuccess=0;
        numberOfLines=0;
        numberOfError=0;
        //ctrIds=new set<id>();
        ctrIds = new set<id>{'a0D1p00000w0r6yEAA','a0D1p00000zjbhWEAQ','a0D1p000010ubGkEAI','a0D1p000010ubHKEAY','a0D1p000010ubHUEAY','a0D1p00000vOiKnEAK','a0D1p00000vOiCjEAK','a0D1p00000uixU3EAI','a0D1p00000uixaDEAQ','a0D1p00000uixkXEAQ','a0D1p00000w0qx8EAA','a0D1p00000w0rByEAI','a0D1p00000w0r78EAA','a0D1p00000y6NE1EAM','a0D1p00000y6OC7EAM','a0D1p00000y6OJkEAM','a0D1p00000y6OOVEA2','a0D1p000012lZheEAE','a0D1p000011RO5zEAG','a0D1p000011RO5UEAW','a0D1p000012ldmsEAA','a0D1p000012qmEYEAY','a0D1p00000uiy9fEAA','a0D1p00000uixcfEAA','a0D1p00000uiyW2EAI','a0D1p00000uixu5EAA','a0D1p00000uiyKhEAI','a0D1p000012KGq2EAG','a0D1p00000w0qlIEAQ','a0D1p00000x2CcjEAE','a0D1p00000xWojUEAS','a0D1p00000xWpG9EAK','a0D1p000011SFPBEA4','a0D1p00000x2CuvEAE','a0D1p00000x2BuMEAU','a0D1p00000x2BymEAE','a0D1p00000x2BzfEAE','a0D1p000012o8QsEAI','a0D1p00000x2BywEAE','a0D1p00000x2CZdEAM','a0D1p00000x2COpEAM','a0D1p00000x3LDVEA2','a0D1p000011Qvu1EAC','a0D1p00000vOhsFEAS','a0D1p00000vOiCtEAK','a0D1p00000vOiD8EAK','a0D1p00000vOi3JEAS','a0D1p00000vOiIYEA0','a0D1p000012ldlwEAA','a0D1p00000vOheDEAS','a0D1p00000vOiCkEAK','a0D1p00000vOiJLEA0','a0D1p000012LaI1EAK','a0D1p000010shwMEAQ','a0D1p000012ldlBEAQ','a0D1p000010vBbUEAU','a0D1p000010u4FNEAY','a0D1p000010sU1XEAU','a0D1p000010upcDEAQ','a0D1p000010tkNhEAI','a0D1p000010uSODEA2','a0D1p000012lZaeEAE','a0D1p000012lZYqEAM','a0D1p000012m6ybEAA','a0D1p000012m70CEAQ','a0D1p00000wYHkUEAW','a0D1p00000wYHZvEAO','a0D1p00000wYHogEAG','a0D1p00000wYHuZEAW','a0D1p00000wYHXuEAO','a0D1p00000wYHjDEAW','a0D1p00000wYHlYEAW','a0D1p00000wYHMrEAO','a0D1p00000wYHndEAG','a0D1p00000wYHobEAG','a0D1p000012o3rJEAQ'};
        
        system.debug('## AP58_BatchConvertAttToFiles >> Constructor method Ends');
    }
    
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new AP58_BatchConvertAttToFiles (),1); //set smaller batch size to avoid heap limits / cpu limits
    }
    
    global Database.Querylocator start(Database.BatchableContext BC){    
        system.debug('## AP58_BatchConvertAttToFiles >> Start method Begins');
          //query all ctin contracts for which migration is not yet triggered
          if(test.isRunningTest()){
              return Database.getQueryLocator([select id,tech_isContractIn__c,TECH_MigratedAttachments__c from contract__c where tech_isContractIn__c=:true and Tech_MigratedAttachments__c=:false]);      
          }
          else{
               return Database.getQueryLocator([select id,tech_isContractIn__c,TECH_MigratedAttachments__c from contract__c where tech_isContractIn__c=:true and Tech_MigratedAttachments__c=:false and id IN:ctrIds]);      

          }
    }
    
    global void execute (Database.Batchablecontext BC, List <sobject> scope){
       //to map Attachment Id with ContentVersion record
        Map<Id,ContentVersion> attachmentCVs = new Map<Id,ContentVersion>();
        //Map —> Attachement – Attachment Parent Id 
        Map<Id,Id> attachementParentIds = new Map<Id,Id>();
        Map<Id,Id> attOwnerIds = new Map<Id,Id>();
        Map<Id,Id> cvOwnerIds = new Map<Id,Id>();
        set<id> setCtinCon = new set<id>();
        map<Id,Id> cvToAttchmtParentIdMap = new map<Id,Id>();
        List<Id> cvIds = new List<Id>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        set<id>setParentIds=new set<id>();
        
        set<id> setctr=new set<id>();
        list<Contract__c> lstCtr=new list<Contract__c>();
        list<ContentDocument> lstCd=new list<ContentDocument>();
        
        list<contract__c> lstcon=(list<contract__c>)scope;
        
        //query attachments for each ctin contracts in scope and for each generate a content version
        for(Attachment attach: [SELECT Id, Name,Description, Body, ContentType, ParentId,ownerId,owner.IsActive From Attachment where parentId IN: lstcon] ){
           // if(setCtinCon.contains(attach.ParentId)){
                //Insert ContentVersion for each attachment
                ContentVersion cVersion = new ContentVersion();
                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce.
                cVersion.PathOnClient = attach.Name;//File name with extention
                cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.           
                cVersion.Title = attach.Name;//Name of the file
                cVersion.VersionData = attach.Body;//File content
                if(attach.Description==null || attach.Description=='' ) cVersion.Description ='Originally uploaded as attachment and converted into files'; else  cVersion.Description=attach.Description + ' : Originally uploaded as attachment and converted into files';
                attachmentCVs.put(attach.Id,cVersion);
                attachementParentIds.put(attach.Id,attach.ParentId);
                if(attach.owner.IsActive && attach.ownerId!='00524000006pyT6AAI') attOwnerIds.put(attach.Id,attach.OwnerId);  
           // }
        }
        
        if(attachmentCVs.values().size() > 0 ) {
            insert attachmentCVs.values();
        }
       
        for(Id key : attachmentCVs.keySet()){
            ContentVersion cv = attachmentCVs.get(key);
            Id attchmentParentId = attachementParentIds.get(key); 
            Id attOwnerId=attOwnerIds.get(key);
            cvOwnerIds.put(cv.Id,attOwnerId);
            cvToAttchmtParentIdMap.put(cv.Id,attchmentParentId);
            cvIds.add(cv.Id);   
        }
        
        //Fetching contentDocumentId using contentVersionId
        // List<ContentVersion> cvWithDocIds=new list<ContentVersion>();
        list<ContentDocument> cdlst=new list<Contentdocument>();
        map<id,id>cdOwnerId=new map<id,id>();
        
        //for each contentversion , generate a contentdocumentLink
        for(ContentVersion cv: [select Id,ContentDocumentId,ownerId from ContentVersion where Id IN :cvIds]){
            cdOwnerId.put(cv.ContentDocumentId,cvOwnerIds.get(cv.Id));
           // cvWithDocIds.add(cv);   
            Id attachmentParentId = cvToAttchmtParentIdMap.get(cv.Id);
            ContentDocumentLink cl = new ContentDocumentLink(LinkedEntityId = attachmentParentId, ContentDocumentId = cv.ContentDocumentId, ShareType = 'V',Visibility = 'AllUsers');
            ContentDocumentLinks.add(cl);   
        }




    if(contentDocumentLinks.size() > 0){
     
        list<Database.SaveResult> results = Database.insert(contentDocumentLinks,false); 
            numberOfLines=contentDocumentLinks.size();
            for (Integer i = 0; i < contentDocumentLinks.size(); i++) {
                Database.SaveResult sr = results[i];    
                if(!sr.isSuccess()){  
                    numberOfError++;
                    //create a CSV from the errors to be sent via email                 
                    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','LinkedEntityId','Operation','Error'});
                    csv.addToLine(contentDocumentLinks[i].Id);               
                    csv.addToLine(contentDocumentLinks[i].LinkedEntityId);
                    csv.addToLine('Converting notes & attachments to files');
                    csv.addToLine(sr.getErrors().get(0).getMessage());
                    csv.createLine();                   
                }
                else {
                    numberOfsuccess++; 
                    //update cdl owner
                    ContentDocument cd=new contentDocument();
                    cd.Id=contentDocumentLinks[i].contentDocumentId;
                    //skip if owner= guest user
                    cd.ownerId= cdOwnerId.get(contentDocumentLinks[i].ContentDocumentId);
                    //update cd;
                    lstcd.add(cd);
                    
                    //update flag on contract
                    Contract__c  con = new Contract__c(id=contentDocumentLinks[i].LinkedEntityId,TECH_MigratedAttachments__c=true);
                    
                    if(!setctr.contains(contentDocumentLinks[i].LinkedEntityId)){
                        lstCtr.add(con);
                    }
                    setctr.add(contentDocumentLinks[i].LinkedEntityId);
   
                }
         }
        
        if(lstcd.size()>0)  list<Database.SaveResult> resultscd = Database.update(lstcd,false); 
        if(setctr.size()>0)  { list<Database.SaveResult> resultsctr = Database.update(lstCtr,false); }
            
     }    
   }
    
    global void finish (Database.BatchableContext BC){
       // reset numberOfLines to get correct number  
        numberOfLines = numberOfsuccess + numberOfError;
        // no more contract to process, so send email for batch completion
        AP00_FormatEmailSend emailManager = new AP00_FormatEmailSend();
        emailManager.subject = 'Completion of batch : Migration of attachments to files';
        emailManager.body = 'Out of '  +  String.valueOf(numberOfLines) + ' attachments ,' + String.valueOf(numberOfsuccess)+ ' attachments are succesfully converted to files' + ' and ' + 
                             String.valueOf(numberOfError)    + ' attachments could not be converted to files. Please find attached the error.csv';
                                     
        
        emailManager.setDestination(System.label.cTin_batchEmailAddress);
        
        if(numberOfError > 0) emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');
        // if(numberOfRecError > 0) emailManager.generateAttachment('UpdatingRecErrors.csv',csv.getBlobBody(),'text/csv');
        emailManager.sendFormattedEmail();
    }

}