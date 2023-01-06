public without sharing class LWC03_DocumentToUpload_Acc {
        /*
--------------------------------------------------------------------------------------
-- - Name          : LWC03_DocumentToUpload_cTin
-- - Author        : ARA
-- - Description   : Controller for lwc LWC_DocumentToUpload_cTin & LWC_UploadedDocument_cTin
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 28-APR-2022  ARA    1.0     Initial version (SP-03475)
--------------------------------------------------------------------------------------
*/

@AuraEnabled
public static Map<String, Object> getDocumentType(String recordId){
    Map<String, Object> result = new Map<String, Object>();
    List <Map<String, String>> lstDocumentType = new List <Map<String, String>>();
    List <Map<String, String>> lstDocumentSubTypeAccDoc = new List <Map<String, String>>();
    List <Map<String, String>> lstDocumentSubTypeAddDoc = new List <Map<String, String>>();
    String prefixId = '';
    String currentObject = '';
    Contract__c contract = new Contract__c();

    if(recordId != null){
        prefixId = recordId.substring(0, 3);
        List<DocumentPerObject__mdt> lstDocPerObject = [SELECT StageName__c, RequiredDocuments__c, OptionalDocuments__c, RecordTypes__c,Subtype__c FROM DocumentPerObject__mdt WHERE ObjectIdPrefix__c = :prefixId];
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        for(DocumentPerObject__mdt rd: lstDocPerObject){
            // required doc
            if(string.isNotBlank(rd.RequiredDocuments__c)){
                for(string docType: rd.RequiredDocuments__c.split(';')){
                    system.debug('****** '+Label.LWC03_DocumentTypeExternal+'***'+docType);
                    Map <String, String> values = new Map <String, String> {
                        'label' => docType,
                        'value' => docType
                    };
                    lstDocumentType.add(values);
                }
            }

            if(string.isNotBlank(rd.Subtype__c)){
                for(string docSubType: rd.Subtype__c.split(';')){
                    system.debug('****** '+Label.LWC03_DocumentTypeExternal+'***'+docSubType);
                    if (docSubType.startsWith('AccDoc_')) {
                        Map <String, String> values = new Map <String, String> {
                            'label' => docSubType.replace('AccDoc_', ''),
                            'value' => docSubType.replace('AccDoc_', '')
                        };
                        lstDocumentSubTypeAccDoc.add(values);
                    }
                    else if (docSubType.startsWith('AddDoc_')) {
                        Map <String, String> values = new Map <String, String> {
                            'label' => docSubType.replace('AddDoc_', ''),
                            'value' => docSubType.replace('AddDoc_', '')
                        };
                        lstDocumentSubTypeAddDoc.add(values);
                    }
                }
            }
        }
    }

    User user = [SELECT Id, name FROM User WHERE Id = :UserInfo.getUserId()];
    result.put('currentObject', currentObject);
    result.put('user', user);
    result.put('document', lstDocumentType);
    result.put('subtypeAccDoc', lstDocumentSubTypeAccDoc);
    result.put('subtypeAddDoc', lstDocumentSubTypeAddDoc);

    return result;
}

@AuraEnabled
public static Map<String, Object> getAllDocuments(String recordId){
    Map<String, Object> result = new Map<String, Object>();
    map<string, Document__mdt> mapDoc = new Map<string, Document__mdt>();
    map<Id,ContentVersion> mapCV = new map<Id,ContentVersion>();
    map<string, DocumentWrapper> mapDocumentWrapper = new Map<string, DocumentWrapper>();
    map<string, DocumentWrapper> mapDocumentWrapperSorted = new Map<string, DocumentWrapper>();
    map<string,List<ContentDocument>> mapAttachment = new map<string,List<ContentDocument>>();
    List<DocumentWrapper> listDW = new List<DocumentWrapper>();
    List<ContentDocument> lstCD = new List<ContentDocument>();
    Set<Id> setOwnerId = new Set<Id>();
    Map<Id, User> mapUser;
    String fields = '';
    String ObjectAPIName = '';
    String condition = '';
    String prefixId = '';

    if(recordId != null){
        prefixId = recordId.substring(0, 3);
        Set<Id> documentIds = new Set<Id>();
        List<ContentDocumentLink> lstCDL = [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        
        for(ContentDocumentLink cdLink : lstCDL){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        
        List<ContentVersion> lstCV = [SELECT Id, ContentDocumentId, Sign_able__c, CreatedDate,TECH_CreatedDateTimestamp__c 
                                      FROM ContentVersion 
                                      WHERE contentDocumentId IN :documentIds 
                                      order by TECH_CreatedDateTimestamp__c desc];
        
        for(ContentVersion cv: lstCV){
            mapCV.put(cv.contentDocumentId, cv);
        }

        for(ContentDocument att:[SELECT Id,Title,FileType,ContentSize,FileExtension,Description,createdDate,OwnerId FROM ContentDocument WHERE id IN: documentIds ORDER BY createdDate DESC]){
            setOwnerId.add(att.OwnerId);
            List<ContentDocument> lstDoc;
            if(!mapAttachment.containsKey(att.description)){
                lstDoc = new List<ContentDocument>{att};
            }else{
                lstDoc = mapAttachment.get(att.description);
                lstDoc.add(att);
            }
            mapAttachment.put(att.description,lstDoc);
            lstCD.add(att);
        }

        system.debug('*****lstCD1 '+lstCD);
        if(setOwnerId.size() > 0){
            mapUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :setOwnerId]);
        }

        // required doc
        for(ContentDocument cd: lstCD){
            DocumentWrapper dw = new DocumentWrapper();
            system.debug('******Description '+ cd.Description);
            if(cd.Description != null){
                dw.type = cd.Description.split(';')[0];
                dw.subtype = cd.Description.split(';')[1];
            }
            dw.description = cd.Description;
            dw.fileName = cd.Title + '.' + cd.FileExtension;
            dw.size = cd.ContentSize;
            dw.documentId = cd.Id;
            dw.createdDate = cd.createdDate;
            dw.docURL =  '/lightning/r/' + cd.Id +'/view';
            if(mapUser.containsKey(cd.OwnerId)){
                dw.owner = mapUser.get(cd.OwnerId);
            }
            dw.createdDate = cd.createdDate;
            listDW.add(dw);
        }
        
        //system.debug('*****listDW '+listDW);
    }
    User user = [SELECT Id, name, cTin_Profile__c FROM User WHERE Id = :UserInfo.getUserId()];
    result.put('user', user);

    //Sort the List by createdDate
    List<String> orderingList = new List<String>();
    if(listDW.size()>0){
        Integer order = 0;
        for(DocumentWrapper docWrapper: listDW){
            mapDocumentWrapper.put(docWrapper.createdDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'), docWrapper);
        }
        orderingList.addAll(mapDocumentWrapper.keyset());
        orderingList.sort();
        for (Integer i=orderingList.size()-1; i>=0; i--){
            DocumentWrapper dw = mapDocumentWrapper.get(orderingList[i]);
            dw.Id = order;
            //system.debug('*****id '+order+' ***createdDate '+dw.createdDate);
            mapDocumentWrapperSorted.put(orderingList[i],dw);
            order++;
        }
        result.put('data', mapDocumentWrapperSorted.values());
    }else{
        result.put('data', null);
    }

    return result;
}

@AuraEnabled
public static Map<String, Object> addDocuments(List<DocumentWrapper> lstUploadedDoc, String recordId){
    Map<String, Object> result = new Map<String, Object>();
    map<Id,ContentVersion> mapCV = new map<Id,ContentVersion>();
    map<Id,DocumentWrapper> mapDocWrap = new map<Id,DocumentWrapper>();
    List<ContentDocument> lstCD = new List<ContentDocument>();
    List<Id> lstDocId = new List<Id>();
    List<ContentVersion> lstCV = new List<ContentVersion>();

    for(DocumentWrapper doc: lstUploadedDoc){
        mapDocWrap.put(doc.documentId, doc);
    }

    Account Acc = [SELECT id,name FROM Account WHERE id = :recordId limit 1];
    lstCD = [SELECT Id, contentSize, FileExtension, Title FROM ContentDocument WHERE Id IN :mapDocWrap.keySet()];
    if(lstCD.size() > 0){
        for(ContentDocument cd: lstCD){
            String type = mapDocWrap.get(cd.Id).type;
            /*if(cd.Title.toLowercase().contains('_sow')){
                result.put('error', System.Label.LWC2_ContainsSOW);
            }else if(type == System.Label.LWC03_DocumentTypeExternal && (cd.contentSize > 10485760 || cd.FileExtension != 'pdf')){
                result.put('error', System.Label.LWC03_ExternalFileSize);
            }else if(type == System.Label.LWC03_DocumentTypeInternal && cd.contentSize > 52428800){
                result.put('error', System.Label.LWC03_InternalFileSize);
            }else{*/
                cd.Title = mapDocWrap.get(cd.Id).subtype + '-' + Acc.name;
                cd.description = type + ';' + mapDocWrap.get(cd.Id).subtype;// Changing file description with user entered description
            //}
            Decimal contentSize = cd.contentSize<1048576 ? Decimal.ValueOf(cd.contentSize)/1024 : Decimal.ValueOf(cd.contentSize)/1048576;
            contentSize = contentSize.setScale(2, RoundingMode.HALF_UP);
            DocumentWrapper dw = mapDocWrap.get(cd.Id);
            dw.description = cd.Title + '.'+ cd.FileExtension + ' ' + (cd.contentSize<1048576 ? '('+ contentSize + 'Kb)' : '('+contentSize + 'Mb)');
            mapDocWrap.put(cd.Id, dw);
        }
        if(result.containsKey('error')){
            result.put('data',mapDocWrap.values());
            try{
                delete lstCD;
            }
            catch(Exception ex){
            }
        }else{
            // add document
            lstCV = [SELECT Id, contentDocumentId FROM ContentVersion WHERE contentDocumentId IN :mapDocWrap.keySet()];
            for(ContentVersion cv: lstCV){
                mapCV.put(cv.contentDocumentId, cv);
            }
    
            lstCV = new List<ContentVersion>();
            for(DocumentWrapper doc: lstUploadedDoc){
                ContentVersion cv = mapCV.get(doc.documentId);
                cv.Account__c = recordId;
                lstCV.add(cv);
            }
    
            system.debug('## lstCD '+lstCD);
            system.debug('## lstCV '+lstCV);
            if(lstCD.size() > 0){
                try{
                    update lstCV;
                    update lstCD;
                    map<String,Object> mapResult= getAllDocuments(recordId);
                    List<DocumentWrapper> lstDocument = (List<DocumentWrapper>)mapResult.get('data');
                    result.put('data', lstDocument);
                    result.put('success', System.label.LWC03_UploadedSuccess);
                }  
                catch(DMLException e){
                    result.put('error', e.getMessage());  
                }
            }
        }
    }
    system.debug('******result '+ result);
    return result;
}

@AuraEnabled
public static map<String, Object> replaceDocument(DocumentWrapper newDoc, String originDocId, String recordId){
    map<String,Object> result = new map<String,Object>();
    List<Id> lstDocId = new List<Id>();
    Map<Id, DocumentWrapper> mapDocWrap = new Map<Id, DocumentWrapper>();
    List<ContentDocument> lstCD = new List<ContentDocument>();
    List<ContentVersion> lstCv = new List<ContentVersion>();
    String type = newDoc.type;
    
    lstCD = [SELECT Id, contentSize, FileExtension, Title, createdDate,description FROM ContentDocument WHERE Id = :newDoc.documentId];
    Account Acc = [SELECT id,name FROM Account WHERE id = :recordId limit 1];
    for(ContentDocument cd : lstCD){
        /*if(cd.Title.toLowercase().contains('_sow')){
            result.put('error', System.Label.LWC2_ContainsSOW);
        }else if(type == System.Label.LWC03_DocumentTypeExternal && (cd.contentSize > 10485760 || cd.FileExtension != 'pdf')){
            result.put('error', System.Label.LWC03_ExternalFileSize);
        }else if(type == System.Label.LWC03_DocumentTypeInternal && cd.contentSize > 52428800){
            result.put('error', System.Label.LWC03_InternalFileSize);
        }else{*/
            cd.Title = newDoc.subtype + '-' + Acc.name;
            cd.description = newDoc.type +';'+newDoc.subtype;// Changing file description with user entered description
        //}
        Decimal contentSize = cd.contentSize<1048576 ? Decimal.ValueOf(cd.contentSize)/1024 : Decimal.ValueOf(cd.contentSize)/1048576;
        contentSize = contentSize.setScale(2, RoundingMode.HALF_UP);
        newDoc.description = cd.Title + '.'+ cd.FileExtension + ' ' + (cd.contentSize<1048576 ? '('+ contentSize + 'Kb)' : '('+contentSize + 'Mb)');
        


        newDoc.description = cd.Description;
        newDoc.fileName = cd.Title + '.' + cd.FileExtension;
        newDoc.size = cd.ContentSize;
        newDoc.createdDate = cd.createdDate;


        mapDocWrap.put(cd.Id, newDoc);
    }

    if(result.containsKey('error')){
        result.put('data',mapDocWrap.values());
        try{
            delete lstCD;
        }
        catch(Exception ex){
        }
    }else{
        lstCV = [SELECT Id, contentDocumentId, sign_able__c FROM ContentVersion WHERE contentDocumentId = :newDoc.documentId];
        for(ContentVersion cv : lstCV){
            cv.Account__c = recordId;
        }

        try{
            update lstCD;
            if(lstCV.size() > 0){
                update lstCV;
            }
            // Delete old document
            ContentDocument oldDoc = new ContentDocument(Id = originDocId);
            delete oldDoc;

            result.put('data', newDoc);  
        }  
        catch(DMLException e){
            if(e.getMessage().contains(System.Label.Sing_ErrorMessageUpdateDoc)){
                result.put('error', System.Label.Sing_ErrorMessageUpdateDoc);
            }else{
                result.put('error', e.getMessage());  
            }
        }
    }
    return result;
}

@AuraEnabled
public static string deleteDocument(List<String> documentId){
    try{
        delete [SELECT Id FROM ContentDocument WHERE Id=:documentId];
        return 'success';
    }
    catch(Exception ex){
        if(ex.getMessage().contains(System.Label.AP03_Sing_ErrorDocumentUploadedDeletion)){
            return 'Sourcing Documents Completed Error';
        }
        return  ex.getMessage();
    }
}

// wrapper class
public class DocumentWrapper{
    @AuraEnabled public Integer Id {get; set;}
    @AuraEnabled public Document__mdt doc {get; set;}
    @AuraEnabled public boolean inserted {get; set;}
    @AuraEnabled public boolean required {get; set;}
    @AuraEnabled public String description {get; set;}
    @AuraEnabled public string documentId  {get; set;}
    @AuraEnabled public String stage {get; set;}
    @AuraEnabled public String fileName {get; set;}
    @AuraEnabled public String type {get; set;}
    @AuraEnabled public String subtype {get; set;}
    @AuraEnabled public String docURL {get; set;}
    @AuraEnabled public Integer size {get; set;}
    @AuraEnabled public Datetime createdDate {get; set;}
    @AuraEnabled public User owner {get; set;}
}
}