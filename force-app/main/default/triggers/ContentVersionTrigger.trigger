trigger ContentVersionTrigger on ContentVersion (before insert, after insert, after update, after delete,before update) {
        
    list<contentversion> lstCv=new list<contentversion>();
    list<contentversion> lstCvSignable=new list<contentversion>();
    
    system.debug('Starting trigger ContentVersion');
    if (Trigger.isBefore && Trigger.isInsert) {
        for(integer i=0;i<Trigger.new.size();i++){
            system.debug('##before insert cv.ContentSize>600000' + Trigger.new[i].ContentSize);
        }
    
        /* for(integer i=0;i<Trigger.new.size();i++){
            if(Trigger.new[i].ContentSize>600000){
            Trigger.new[i].addError('Files exceeding 6 MB are not allowed');
            }
        }*/
        
        ContentVersionTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        ContentVersionTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
        
    //SP-01537:MRA 05-JUN-2021 : Block upload of files if size exceeds 50MB or file extension is not allowed (applicable for OpCo and CtIn and non-admin users)
    if (Trigger.isAfter && Trigger.isInsert) {
        list<string> allowedtypes=new list<string>();
        allowedtypes=(system.label.GLO_FileType.toLowercase()).split(';');
        /*for(integer i=0;i<Trigger.new.size();i++){
            if( userinfo.getProfileId()!=system.label.GLO_SystemAdminId){
                if(Trigger.new[i].ContentSize>50000000)Trigger.new[i].addError('Files exceeding 50 MB are not allowed');
                if((allowedtypes.contains(Trigger.new[i].fileType.toLowercase())==false)) Trigger.new[i].addError('Files type is not allowed');
            }
        }*/
       //MRA 4/5 2022 - added check on file extension to allow mpp and daeb files, fileextension is null if not queried and check on file type is not valid for these 2 as it is always unknown 
        for(Contentversion cv: [select id,ContentSize,fileType,fileExtension from Contentversion where id IN:Trigger.new]){
            system.debug('## cv' + cv);
            system.debug('## fileExtension' + cv.fileExtension);
          if( userinfo.getProfileId()!=system.label.GLO_SystemAdminId && cv.fileExtension!='snote'){
            if(cv.ContentSize>50000000)cv.addError('Files exceeding 50 MB are not allowed');
            if((allowedtypes.contains(cv.fileType.toLowercase())==false) && (allowedtypes.contains(cv.fileExtension.toLowercase())==false)) cv.addError('Files type is not allowed');
          }
        }

        ContentVersionTriggerHandler.handleAfterInsert(Trigger.new);
    }
        
    //03-Jun-2020 : MRA Bundle 3.4 => SP-00257 (block Send for eSignature to be checked / unchecked when status is beyond "In Progress")
    if (Trigger.isBefore && Trigger.isUpdate) {
        for(integer i=0;i<Trigger.new.size();i++){
            /* //SP-01537:MRA 05-JUN-2021 : Block upload of files if size exceeds 50MB (applicable for OpCo and CtIn)
            if(Trigger.new[i].ContentSize>6000){
            Trigger.new[i].addError('Files exceeding 50 MB are not allowed');
            }*/
                
            //SP-03003  ARA 15-DEC-2021 : Block upload of files if size exceeds 10MB (applicable for CtIn)
            if(Trigger.new[i].Sign_able__c && Trigger.new[i].ContentSize > 10240000){                   Trigger.new[i].addError('Files exceeding 10 MB are not allowed to sent for signature');
            }
    
            if(Trigger.old[i].Sign_able__c!=Trigger.new[i].Sign_able__c && PAD.canTrigger('AP48')){
                system.debug ('## Changing signable');
                lstCv.add(Trigger.new[i]);               
            }
            
            if(Trigger.old[i].Sign_able__c!=Trigger.new[i].Sign_able__c && Trigger.new[i].Sign_able__c){
                if(Trigger.new[i].title.length() > 89)  Trigger.new[i].addError(system.label.LC16_ErrorDocumentLength);
                if(Trigger.new[i].FileType!='pdf')  Trigger.new[i].addError(system.label.LC16_ErrorDocumentType);
            }
            
            ContentVersionTriggerHandler.handleBeforeUpdate(Trigger.old, Trigger.new);
        }
            
        if(lstCv.size()>0 && PAD.canTrigger('AP48')){AP48_blockFileUpdate.blockUpdtFile(lstCv);
        }
    }
}