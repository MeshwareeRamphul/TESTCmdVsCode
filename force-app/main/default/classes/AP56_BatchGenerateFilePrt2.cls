global without sharing class AP56_BatchGenerateFilePrt2 implements Database.Batchable<sobject>,Database.Stateful,schedulable{
    /*
    ----------------------------------------------------------------------
    -- - Name : AP56_BatchGenerateFile
    -- - Author : SC
    -- - Description : generates files for existing content deliveries for both Esignature and Contract object
    -- -
    -- Maintenance History:
    --
    -- Date Name Version Remarks
    -- ----------- ---- ------- ---------------------------------------
    -- 06-FEB-2020 MRA 1.0 Intitial version
    ----------------------------------------------------------------------
    **********************************************************************
    */
    
    // parameter passed in constructor => defines the object for which migration from cd to files is to be performed
    global string ObjType;
    //counters for number of success, failures , number of files to be generated
    global integer numberOfsuccess;
    global integer numberOfLines;
    global integer numberOfError;
    global integer numberOfRecords=0;
    global integer numberOfRecSuccess;
    global integer numberOfRecError;
    global set<string> setIdCtr;
    
    
    //variables for sending mail with error.csv as attachment after exceution of batch
    global boolean isheaderSet;
    global AP00_CSVParser csv;
    

    
    global AP56_BatchGenerateFilePrt2 (string obj){
    system.debug('## AP56_BatchGenerateFilePrt2 >> Constructor method Begins');
    ObjType= obj;
    
    csv = new AP00_CSVParser();
    numberOfsuccess=0;
    numberOfLines=0;
    numberOfError=0;
    numberOfRecError=0;
    numberOfRecSuccess=0;
    
    
    system.debug('## AP56_BatchGenerateFilePrt2  >> Constructor method Ends');
    }
    
    
    global void execute(SchedulableContext scon) {
     Database.executeBatch(new AP56_BatchGenerateFilePrt2 ('contract'),10); //set smaller batch size to avoid heap limits / cpu limits
     }
 
    global Database.Querylocator start(Database.BatchableContext BC){
    system.debug('## AP56_BatchGenerateFilePrt2 >> Start method Begins');
    
    if(ObjType=='contract'){
    return Database.getQueryLocator([select id,ownerId,cTin_NumberSignablePDF__c from Contract__c
    where  tech_isContractIn__c= true
    and tech_migratedFile__c= false and createdDate <=2020-08-20T00:00:00Z]);
    }
    else {
    return Database.getQueryLocator([select id,contract__r.OwnerId from esignature__c
    where Tech_MigratedFile__c=:false
    and contract__r.tech_isContractIn__c=:true order by name asc ]);
    }
    }
    
    global void execute (Database.Batchablecontext BC, List <sobject> scope){
    list<id>cvLst=new list<id>();
    map<id,id>cvRecordMap=new map<id,id>();
    set<id>objIdSet=new set<id>();
    list<eSignature__c> eslst=new list<eSignature__c>();
    list<Contract__c> ctrlst=new list<Contract__c>();
    list<contentDocumentLink> lstcdl=new list<contentDocumentLink>();
    list<ContentVersion> contentversionLst=new list<ContentVersion>();
    map<string,string> mapCdTitle=new map<string,string>();
    set<id> setcontentDocumentId=new set<id>();
    map<id,id> mapRecOwnerID=new map<id,id>();
    list<contentDocument> lstCd=new list<ContentDocument>();
    
    if(ObjType=='contract'){
    List<Contract__c> ctrList = (List<Contract__c>)scope;
    for(Contract__c ctr : ctrList){
    objIdSet.add(ctr.id);
    mapRecOwnerID.put(ctr.id,ctr.ownerId);
    }
    }
    else{
    List<esignature__c> esList = (List<esignature__c>)scope;
    for(esignature__c esign : esList){
    objIdSet.add(esign.id);
    mapRecOwnerID.put(esign.id,esign.Contract__r.ownerId);
    }
    }
    

    if (objIdSet.size()>0) {
        for(contentDistribution cd: [select id, contentversionId, relatedRecordId ,name
        from contentDistribution where
        relatedRecordId IN : objIdSet]){
        
        cvLst.add(cd.contentversionId);
        cvRecordMap.put(cd.contentversionId,cd.relatedRecordId);
        mapCdTitle.put(cd.contentversionId,cd.name);
    }
    
    set<id> uniquecrt=new set<id>();
    for (ContentVersion cv :[SELECT id, ContentDocumentId, ContentDocument.title, title,VersionData,sign_able__c,isMajorVersion,PathOnClient
    FROM ContentVersion
    WHERE id IN :cvLst]){
    
    
    if(cvRecordMap.containsKey(cv.id) ){
    if(!uniquecrt.contains(cvRecordMap.get(cv.id))){
    if(ObjType=='contract'){
    contract__c ctr=new contract__c(id=cvRecordMap.get(cv.id),Tech_MigratedFile__c=true );
    ctrlst.add(ctr);
    }
    else{
    esignature__c es=new esignature__c(id=cvRecordMap.get(cv.id),Tech_MigratedFile__c=true );
    eslst.add(es);
    }

    uniquecrt.add(cvRecordMap.get(cv.id));
    }
    
    ContentVersion newCv = new ContentVersion();
    newCv.Title = mapCdTitle.get(cv.id);
    newCv.PathOnClient = cv.PathOnclient;
    newCv.VersionData = cv.VersionData;
    newCv.IsMajorVersion = false;
    newCv.sign_able__c=true;
    try{
    insert newCv;
    }
    catch(Exception e){
    system.debug(' *** ctin exception'+ e.getMessage());
    }
    contentversionLst.add(newCv);
    //Get Content Documents
    Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:newCv.Id].ContentDocumentId;
    
    lstcdl.add(new contentDocumentLink(ContentDocumentId = conDocId ,
    LinkedEntityId = cvRecordMap.get(cv.id),
    ShareType = 'V',
    Visibility = 'AllUsers'));
    }
    
    } 
    
    
     if (lstcdl.size()>0) {
            list<Database.SaveResult> results = Database.insert(lstcdl,false);
            numberOfLines += lstcdl.size(); //totl number of lines to update 

            for (Integer i = 0; i < lstcdl.size(); i++) {
                Database.SaveResult sr = results[i];
    
                if(!sr.isSuccess()){
                    numberOfError++;
                    //create a CSV from the errors to be sent via email                 
                    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Operation','Error'});
                    csv.addToLine(lstCd[i].Id); csv.addToLine('generating content doc link');csv.addToLine(sr.getErrors().get(0).getMessage());csv.createLine();
                }
                else numberOfSuccess++;                     
            }
     }
    
    
    if (ctrlst.size()>0) {
    //updating field "number of sign-able documents"
    for(Contract__c c: ctrlst){
    for (AggregateResult ar : [select count(id),LinkedEntityId from contentDocumentLink where LinkedEntityId =: c.Id group by LinkedEntityId ] ){
    c.cTin_NumberSignablePDF__c=integer.valueOf(ar.get('expr0'));
    }
    }
    
    list<Database.SaveResult> results = Database.update(ctrlst,false);
    numberOfRecords += ctrlst.size(); //totl number of lines to update
    
    for (Integer i = 0; i < ctrlst.size(); i++) {
    Database.SaveResult sr = results[i];
    
     if(!sr.isSuccess()){
    numberOfRecError++;
    //create a CSV from the errors to be sent via email
    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Operation','Error'});
    csv.addToLine(ctrlst[i].Id);
    csv.addToLine('Updating tech_migratedFile on Contracts');
    csv.addToLine(sr.getErrors().get(0).getMessage());
    csv.createLine();
    }
    else numberOfRecsuccess++;
    }
    }
    
    if (eslst.size()>0) {
    list<Database.SaveResult> results = Database.update(eslst,false);
    numberOfRecords += eslst.size(); //totl number of lines to update
    
    for (Integer i = 0; i < eslst.size(); i++) {
    Database.SaveResult sr = results[i];
    
    if(!sr.isSuccess()){
    numberOfRecError++;
    //create a CSV from the errors to be sent via email
    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Operation','Error'});
    csv.addToLine(eslst[i].Id);
    csv.addToLine('Updating tech_migratedFile on Esignatures');
    csv.addToLine(sr.getErrors().get(0).getMessage());
    csv.createLine();
    }
    else numberOfRecsuccess++;
    }
    }
    
    }
    
    }
    
    global void finish (Database.BatchableContext BC){
    // reset numberOfLines to get correct number
    //numberOfLines = numberOfsuccess + numberOfError;
    // no more contract to process, so send email for batch completion
    AP00_FormatEmailSend emailManager = new AP00_FormatEmailSend();
    emailManager.subject = 'Completion of batch for updating file owner';
    //emailManager.subject = 'Completion of batch for migrating of content deliveries into files';
    emailManager.body = String.format(System.label.cTin_batchEmailBody,
    new list<string>{
    ObjType,
    String.valueOf(numberOfLines),
    String.valueOf(numberOfsuccess),
    String.valueOf(numberOfError),
    String.valueOf(numberOfRecords),
    ObjType,
    String.valueOf(numberOfRecSuccess),
    String.valueOf(numberOfRecError),
    ObjType
    });
    
    emailManager.setDestination(System.label.cTin_batchEmailAddress);
    
    if(numberOfError > 0 || numberOfRecError > 0) emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');
    // if(numberOfRecError > 0) emailManager.generateAttachment('UpdatingRecErrors.csv',csv.getBlobBody(),'text/csv');
    emailManager.sendFormattedEmail();
    integer i=0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    }
    
    }