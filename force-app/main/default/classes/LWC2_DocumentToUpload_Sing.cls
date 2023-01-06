public without sharing class LWC2_DocumentToUpload_Sing {
    /*
--------------------------------------------------------------------------------------
-- - Name          : LWC2_DocumentToUpload
-- - Author        : ARA
-- - Description   : Controller for lwc LWC_DocumentToUpload & LWC_UploadedDocument
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 02-SEP-2021  ARA    1.0     Initial version 
-- 29-OCT-2021  UBE    1.1     Order by created date (and time also)
-- 24-NOV-2021  MRA    1.2     Added functionality to create + share files with all participants(SF app + portal) if sharing logic equals 'All vendors'
-- 10-MAR-2022  ARA    1.3     SP-03276 Do not associate RFX documents to a round
-- 18-AUG-2022  ARA    1.4     SP-03701 Notify the sourcing team when a vendor uploads a document on the portal
--------------------------------------------------------------------------------------
*/

    @AuraEnabled
    public static Map<String, Object> getDocumentType(String recordId){
        Map<String, Object> result = new Map<String, Object>();
        List <Map<String, String>> lstDocumentType = new List <Map<String, String>>();
        Map<String, List<Map<String, String>>> mapSharingLogic = new Map<String, List<Map<String, String>>>();
        String prefixId = '';
        String currentObject = '';
        Sourcing_Event__c sourcingEvent = new Sourcing_Event__c();
        List<String> lstStatus = new List<String>{AP_Constant.ROUND_STATUS_IN_PROGRESS, AP_Constant.ROUND_STATUS_PREPARATION};

        if(recordId != null){
            prefixId = recordId.substring(0, 3);
            List<DocumentPerObject__mdt> lstDocPerObject = [SELECT StageName__c, RequiredDocuments__c, OptionalDocuments__c, SharingLogic__c, RecordTypes__c FROM DocumentPerObject__mdt WHERE ObjectIdPrefix__c = :prefixId];
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            for(Schema.SObjectType objectInstance : gd.values()){
                if(objectInstance.getDescribe().getKeyPrefix() == prefixId){
                    currentObject = objectInstance.getDescribe().getName();
                }
            }
            if(currentObject == 'Sourcing_Event__c'){
                sourcingEvent = [SELECT Id, Sourcing_Status__c FROM Sourcing_Event__c WHERE Id = :recordId];
            }
            List<Negotiation_Round__c> currentRound = [ SELECT Id, Name, Sourcing_Event__r.Bid_Due_Date__c, Round_Status__c, Sing_Round_Bid_Due_Date__c,Round_Start_Date__c
                                                        FROM Negotiation_Round__c
                                                        WHERE Sourcing_Event__c = :recordId AND Round_Status__c IN :lstStatus LIMIT 1];
            if(currentRound.size() > 0){
                result.put('currentRound', currentRound[0]);
            }
            
            for(DocumentPerObject__mdt rd: lstDocPerObject){
                // required doc
                if(string.isNotBlank(rd.RequiredDocuments__c)){
                    if(sourcingEvent != null && sourcingEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED){
                        if(rd.RequiredDocuments__c.contains(AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL)){
                            lstDocumentType.add(new Map <String, String> {
                                'label' => AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL,
                                'value' => AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL
                            });
                        }
                    }else{
                        for(string docType: rd.RequiredDocuments__c.split(';')){
                            Map <String, String> values = new Map <String, String> {
                                'label' => docType,
                                'value' => docType
                            };
                            lstDocumentType.add(values);
                        }
                    }
                }
                // optional doc
                if(string.isNotBlank(rd.OptionalDocuments__c)){
                    if(sourcingEvent != null && sourcingEvent.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_COMPLETED){
                        if(rd.OptionalDocuments__c.contains(AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL)){
                            lstDocumentType.add(new Map <String, String> {
                                'label' => AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL,
                                'value' => AP_Constant.DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL
                            });
                        }
                    }else{
                        for(string docType: rd.OptionalDocuments__c.split(';')){
                            Map <String, String> values = new Map <String, String> {
                                'label' => docType,
                                'value' => docType
                            };
                            lstDocumentType.add(values);
                        }
                    }
                }
            }
        }

        User user = [SELECT Id, name FROM User WHERE Id = :UserInfo.getUserId()];
        result.put('currentObject', currentObject);
        result.put('user', user);
        result.put('document', lstDocumentType);

        return result;
    }

    @AuraEnabled
    public static Map<String, Object> getAllDocuments(String recordId){
        Map<String, Object> result = new Map<String, Object>();
        map<string, Document__mdt> mapDoc = new Map<string, Document__mdt>();
        map<Id,ContentVersion> mapCV = new map<Id,ContentVersion>();
        list<DocumentWrapper> listDW = new list<DocumentWrapper>();
        map<string, DocumentWrapper> mapDocumentWrapper = new Map<string, DocumentWrapper>();
        map<string, DocumentWrapper> mapDocumentWrapperSorted = new Map<string, DocumentWrapper>();
        map<string,List<ContentDocument>> mapAttachment = new map<string,List<ContentDocument>>();
        Set<Id> setOwnerId = new Set<Id>();
        Map<Id, User> mapUser;
        String fields = '';
        String ObjectAPIName = '';
        String condition = '';
        String prefixId = '';

        if(recordId != null){
            prefixId = recordId.substring(0, 3);
            Set<Id> documentIds = new Set<Id>();
            List<ContentDocumentLink> lstCDL = [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
            
            for(ContentDocumentLink cdLink : lstCDL){  
                documentIds.add(cdLink.ContentDocumentId);  
            }
            

            //START 29-OCT-2021  UBE    1.1
            List<ContentVersion> lstCV = [SELECT Id, contentDocumentId, Sing_DocumentName__c, Negotiation_Round__c, Participant__c, 
                                                 Sharing_Logic__c,createddate,TECH_CreatedDateTimestamp__c 
                                          FROM ContentVersion 
                                          WHERE contentDocumentId IN :documentIds 
                                          order by TECH_CreatedDateTimestamp__c desc];
 
            //List<ContentVersion> lstCV = [SELECT Id, contentDocumentId, Sing_DocumentName__c, Negotiation_Round__c, Participant__c, Sharing_Logic__c,createddate FROM ContentVersion WHERE contentDocumentId IN :documentIds order by createddate desc];
            //END 29-OCT-2021  UBE    1.1
            
            for(ContentVersion cv: lstCV){
                mapCV.put(cv.contentDocumentId, cv);
            }
            //system.debug('********mapCV '+mapCV);
    
            for(ContentDocument att:[SELECT Id,Title,FileType,ContentSize,Description,createdDate,OwnerId,LatestPublishedVersionId FROM ContentDocument WHERE id IN: documentIds AND description != null
            order by createdDate desc]){
                setOwnerId.add(att.OwnerId);
                List<ContentDocument> lstDoc;
                if(!mapAttachment.containsKey(att.description)){
                    lstDoc = new List<ContentDocument>{att};
                }else{
                    lstDoc = mapAttachment.get(att.description);
                    lstDoc.add(att);
                }
                mapAttachment.put(att.description,lstDoc);
            }
            

            if(setOwnerId.size() > 0){
                mapUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :setOwnerId]);
            }

            Map<Id, Negotiation_Round__c> mapNegotiationRound = new Map<Id, Negotiation_Round__c>([SELECT Id, Name FROM Negotiation_Round__c WHERE Sourcing_Event__c = :recordId]);
            Map<Id, Bidder__c> mapParticipant = new Map<Id, Bidder__c>([SELECT Id, Name, TECH_ParticipantName__c, Sing_Account__c, TECH_AccountName__c FROM Bidder__c WHERE Sourcing_Event__c = :recordId]);

            List<DocumentPerObject__mdt> lstDocPerObject = [SELECT StageName__c, RequiredDocuments__c, OptionalDocuments__c, RecordTypes__c FROM DocumentPerObject__mdt WHERE ObjectIdPrefix__c = :prefixId];
            Id round;
            Id participant;

            for(DocumentPerObject__mdt rd: lstDocPerObject){
                // required doc
                if(string.isNotBlank(rd.RequiredDocuments__c)){
                    for(string docType: rd.RequiredDocuments__c.split(';')){
                        if(mapAttachment.containsKey(docType)){
                            for(ContentDocument cd: mapAttachment.get(docType)){
                                DocumentWrapper dw = new DocumentWrapper();
                                dw.Id = cd.Id;
                                dw.stage = rd.StageName__c;
                                dw.type = docType;
                                dw.name = mapCV.get(cd.Id).Sing_DocumentName__c;
                                dw.fileName = cd.Title;
                                dw.size = cd.ContentSize;
                                dw.documentId = cd.Id;
                                dw.LatestPublishedVersionId  = cd.LatestPublishedVersionId;

                                round = mapCV.get(cd.Id).Negotiation_Round__c;
                                if(round != null){
                                    dw.round = mapNegotiationRound.get(round);
                                }
                                
                                participant = mapCV.get(cd.Id).Participant__c;
                                if(participant != null){
                                    dw.participant = mapParticipant.get(participant);
                                }
                                
                                dw.sharingLogic = mapCV.get(cd.Id).Sharing_Logic__c;
                                dw.createdDate = cd.createdDate;
                                dw.docURL =  '/lightning/r/' + cd.Id +'/view';
                                if(mapUser.containsKey(cd.OwnerId)){
                                    dw.owner = mapUser.get(cd.OwnerId);
                                }
                                dw.createdDate = cd.createdDate;
                                listDW.add(dw);
                                //order ++;
                            }
                        }
                    }
                }
                    
                // optional doc
                List<String> lstOptionalDocuments = new List<String>{'Participant Document'};
                if(string.isNotBlank(rd.OptionalDocuments__c)){
                    for(string docType: rd.OptionalDocuments__c.split(';')){
                        lstOptionalDocuments.add(docType);
                    }
                }
                for(string docType: lstOptionalDocuments){
                    if(mapAttachment.containsKey(docType) || mapAttachment.containsKey('')){
                        for(ContentDocument cd: mapAttachment.get(docType)){
                            DocumentWrapper dw = new DocumentWrapper();
                            dw.Id = cd.Id;
                            dw.stage = rd.StageName__c;
                            dw.type = docType;
                            dw.name = mapCV.get(cd.Id).Sing_DocumentName__c;
                            dw.fileName = cd.Title;
                            dw.size = cd.ContentSize;
                            dw.documentId = cd.Id;
                            dw.LatestPublishedVersionId  = cd.LatestPublishedVersionId;
                            
                            round = mapCV.get(cd.Id).Negotiation_Round__c;
                            if(round != null){
                                dw.round = mapNegotiationRound.get(round);
                            }
                            
                            participant = mapCV.get(cd.Id).Participant__c;
                            if(participant != null){
                                dw.participant = mapParticipant.get(participant);
                            }

                            dw.sharingLogic = mapCV.get(cd.Id).Sharing_Logic__c;
                            dw.docURL =  '/lightning/r/' + cd.Id +'/view';
                            if(mapUser.containsKey(cd.OwnerId)){
                                dw.owner = mapUser.get(cd.OwnerId);
                            }
                            dw.createdDate = cd.createdDate;
                            listDW.add(dw);
                            //order ++;
                        }
                    }
                }
            }
        }
        User user = [SELECT Id, name, cTin_Profile__c FROM User WHERE Id = :UserInfo.getUserId()];
        result.put('user', user);


        //Sort the List by createdDate
        List<String> orderingList = new List<String>();
        if(listDW.size()>0){
            for(DocumentWrapper docWrapper: listDW){
                mapDocumentWrapper.put(docWrapper.createdDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'), docWrapper);
            }
            orderingList.addAll(mapDocumentWrapper.keyset());
            orderingList.sort();
            Integer order = 0;
            for ( Integer i= orderingList.size()-1 ;i >= 0; i--){
                //mapDocumentWrapper.get(orderingList[i]).Id = order;
                mapDocumentWrapperSorted.put(orderingList[i],mapDocumentWrapper.get(orderingList[i]));
                order ++;
            }
            result.put('data', mapDocumentWrapperSorted.values());
        }else{
            result.put('data', null);
        }

        return result;
    }

    @AuraEnabled
    public static Map<String, Object> getParticipantDocuments(String recordId){
        Map<String, Object> result = new Map<String, Object>();
        map<string, Document__mdt> mapDoc = new Map<string, Document__mdt>();
        map<Id,ContentVersion> mapCV = new map<Id,ContentVersion>();
        list<DocumentWrapper> listDW = new list<DocumentWrapper>();
        map<string, DocumentWrapper> mapDocumentWrapper = new Map<string, DocumentWrapper>();
        map<string, DocumentWrapper> mapDocumentWrapperSorted = new Map<string, DocumentWrapper>();
        map<string,List<ContentDocument>> mapAttachment = new map<string,List<ContentDocument>>();
        Set<Id> setOwnerId = new Set<Id>();
        Map<Id, User> mapUser;
        String fields = '';
        String ObjectAPIName = '';
        String condition = '';
        String prefixId = '';

        //system.debug('********recordId '+recordId);
        if(recordId != null){
            Set<Id> documentIds = new Set<Id>();
            Bidder__c participant = [SELECT Id, Sourcing_Event__c, Negotiation_round__c FROM Bidder__c WHERE Id = :recordId];
            prefixId = ((String)participant.Sourcing_Event__c).substring(0, 3);
            //system.debug('********participant '+participant);
            for(ContentDocumentLink cdLink : [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:participant.Sourcing_Event__c OR LinkedEntityId = :recordId]){
                documentIds.add(cdLink.ContentDocumentId);
            }
            //system.debug('********documentIds '+documentIds);
            if(documentIds.size() > 0){
                List<ContentVersion> lstCV = [SELECT Id, contentDocumentId, Sing_DocumentName__c, Sourcing_Event__c, Negotiation_Round__c, Participant__c, Sharing_Logic__c,createddate,TECH_CreatedDateTimestamp__c 
                                            FROM ContentVersion
                                            WHERE contentDocumentId IN :documentIds
                                            ORDER BY TECH_CreatedDateTimestamp__c DESC];
                
                for(ContentVersion cv: lstCV){
                    //system.debug('********cv '+cv);
                    if(cv.Sharing_Logic__c == 'All Vendors' || cv.Participant__c == participant.Id && cv.Negotiation_Round__c == participant.Negotiation_Round__c){
                        mapCV.put(cv.contentDocumentId, cv);
                    }
                }
        
                if(mapCV.size() > 0){
                    //system.debug('********mapCV '+mapCV.size());
                    for(ContentDocument att:[SELECT Id,Title,FileType,ContentSize,Description,createdDate,OwnerId,LatestPublishedVersionId FROM ContentDocument WHERE id IN: mapCV.keyset() AND description != null
                    ORDER BY createdDate DESC]){
                        //system.debug('********att '+att);
                        setOwnerId.add(att.OwnerId);
                        List<ContentDocument> lstDoc;
                        if(!mapAttachment.containsKey(att.description)){
                            lstDoc = new List<ContentDocument>{att};
                        }else{
                            lstDoc = mapAttachment.get(att.description);
                            lstDoc.add(att);
                        }
                        mapAttachment.put(att.description,lstDoc);
                    }
                    //system.debug('********mapAttachment '+mapAttachment.size());
                    

                    if(setOwnerId.size() > 0){
                        mapUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :setOwnerId]);
                    }
                    
                    //system.debug('********mapUser '+mapUser);
                    List<DocumentPerObject__mdt> lstDocPerObject = [SELECT StageName__c, RequiredDocuments__c, OptionalDocuments__c, RecordTypes__c FROM DocumentPerObject__mdt WHERE ObjectIdPrefix__c = :prefixId];
                    Integer order = 0;

                    //system.debug('********lstDocPerObject '+lstDocPerObject.size());
                    for(DocumentPerObject__mdt rd: lstDocPerObject){
                        // required doc
                        if(string.isNotBlank(rd.RequiredDocuments__c)){
                            for(string docType: rd.RequiredDocuments__c.split(';')){
                                if(mapAttachment.containsKey(docType)){
                                    for(ContentDocument cd: mapAttachment.get(docType)){
                                        DocumentWrapper dw = new DocumentWrapper();
                                        dw.Id = cd.Id;
                                        dw.cvId = mapCV.get(cd.Id).Id;
                                        dw.stage = rd.StageName__c;
                                        dw.type = docType;
                                        dw.name = cd.Title;
                                        dw.fileName = cd.Title;
                                        dw.fileType = cd.FileType;
                                        dw.size = cd.ContentSize;
                                        dw.documentId = cd.Id;
                                        dw.LatestPublishedVersionId  = cd.LatestPublishedVersionId;

                                        dw.createdDate = cd.createdDate;
                                        dw.docURL = '/supplier/s/detail/'+cd.Id;
                                        if(mapUser.containsKey(cd.OwnerId)){
                                            dw.owner = mapUser.get(cd.OwnerId);
                                        }
                                        dw.createdDate = cd.createdDate;
                                        listDW.add(dw);
                                        system.debug('********DW '+dw);
                                        order ++;
                                    }
                                }
                            }
                        }
                            
                        // optional doc
                        List<String> lstOptionalDocuments = new List<String>{'Participant Document'};
                        if(string.isNotBlank(rd.OptionalDocuments__c)){
                            for(string docType: rd.OptionalDocuments__c.split(';')){
                                lstOptionalDocuments.add(docType);
                            }
                        }
                        for(string docType: lstOptionalDocuments){
                            if(mapAttachment.containsKey(docType) || mapAttachment.containsKey('')){
                                for(ContentDocument cd: mapAttachment.get(docType)){
                                    DocumentWrapper dw = new DocumentWrapper();
                                    dw.Id = cd.Id;
                                    dw.cvId = mapCV.get(cd.Id).Id;
                                    dw.stage = rd.StageName__c;
                                    dw.type = docType;
                                    dw.name = cd.Title;
                                    dw.fileName = cd.Title;
                                    dw.fileType = cd.FileType;
                                    dw.size = cd.ContentSize;
                                    dw.documentId = cd.Id;
                                    dw.LatestPublishedVersionId  = cd.LatestPublishedVersionId;
                                    
                                    dw.docURL =  '/supplier/s/detail/'+cd.Id;
                                    if(mapUser.containsKey(cd.OwnerId)){
                                        dw.owner = mapUser.get(cd.OwnerId);
                                    }
                                    dw.createdDate = cd.createdDate;
                                    listDW.add(dw);
                                    order ++;
                                }
                            }
                        }
                    }
                    User user = [SELECT Id, name, cTin_Profile__c FROM User WHERE Id = :UserInfo.getUserId()];
                    result.put('user', user);
                }
            }
        }


        //Sort the List by createdDate
        List<String> orderingList = new List<String>();
        //system.debug('********listDW '+listDW.size());
        if(listDW.size()>0){
            for(DocumentWrapper docWrapper: listDW){
                mapDocumentWrapper.put(docWrapper.createdDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'), docWrapper);
            }
            orderingList.addAll(mapDocumentWrapper.keyset());
            orderingList.sort();
            for ( Integer i= orderingList.size()-1 ;i >= 0; i--){
                mapDocumentWrapperSorted.put(orderingList[i],mapDocumentWrapper.get(orderingList[i]));
            }
            result.put('data', mapDocumentWrapperSorted.values());
        }else{
            result.put('data', null);
        }
            
        //system.debug('********data '+result.containsKey('data'));

        return result;
    }

    @AuraEnabled
    public static map<String,Object> addDocuments(List<DocumentWrapper> lstUploadedDoc, String recordId){
        map<String,Object> mapOfResult = new map<String,Object>();
        map<Id,ContentVersion> mapCD = new map<Id,ContentVersion>();
        map<Id,DocumentWrapper> mapDocWrap = new map<Id,DocumentWrapper>();
        List<ContentDocument> lstCD = new List<ContentDocument>();
        List<ContentVersion> lstCV = new List<ContentVersion>();
        List<contentDocumentLink> lstCDLs = new List<contentDocumentLink>();
        List<String> lstRFXDocType = new List<String>{AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS, AP_Constant.DOCUMENT_TYPE_RFX_RESULTS};
		list<Bidder__c> lstBidder;
        //mra 24/11/2021 : copy file on all particpant with visibility = all Users if shring logic=All vendors

        for(DocumentWrapper doc: lstUploadedDoc){
            mapDocWrap.put(doc.documentId, doc);
        }
        if(lstUploadedDoc.size() > 0 && lstUploadedDoc[0].roundId != null){
            lstBidder = [SELECT id, Sourcing_Event__r.Bid_Due_Date__c,Sourcing_Event__c                                              
                        FROM Bidder__c
                        WHERE Sourcing_Event__c =:recordId AND Negotiation_Round__c = :lstUploadedDoc[0].roundId];
        }else{
            lstBidder = [SELECT id, Sourcing_Event__r.Bid_Due_Date__c,Sourcing_Event__c                                              
                        FROM Bidder__c
                        WHERE Sourcing_Event__c =:recordId];
        }

        lstCD = [SELECT Id, contentSize, FileExtension, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN :mapDocWrap.keySet()];
        if(lstCD.size() > 0){
            for(ContentDocument cd: lstCD){
                DocumentWrapper doc = mapDocWrap.get(cd.Id);
                String type = doc.type;
                // Changing file description with user entered description
                if(cd.Title.toLowercase().contains('_sow')){
                    mapOfResult.put('error', System.Label.LWC2_ContainsSOW);
                }else if(type == System.Label.LWC03_DocumentTypeExternal && (cd.contentSize > 10485760 || cd.FileExtension != 'pdf')){
                    mapOfResult.put('error', System.Label.LWC03_ExternalFileSize);
                }else if(type == System.Label.LWC03_DocumentTypeInternal && cd.contentSize > 52428800){
                    mapOfResult.put('error', System.Label.LWC03_InternalFileSize);
                }else{
                    cd.description = type;// Changing file description with user entered description
                    // For specific vendor
                    if(doc.sharingLogic == 'Specific Vendor'){
                        lstCDLs.add(new contentDocumentLink(LinkedEntityId = doc.participantId ,ContentDocumentId = doc.documentId, Visibility='AllUsers'));
                    }
                    if(doc.sharingLogic == 'All Vendors' && lstBidder.size()>0){
                        for(Bidder__c bidder: lstBidder){
                            lstCDLs.add(new contentDocumentLink(LinkedEntityId = bidder.Id ,ContentDocumentId = doc.documentId, Visibility='AllUsers'));
                        }
                    }
                }
            }

            if(mapOfResult.containsKey('error')){
                mapOfResult.put('data',mapDocWrap.values());
                try{
                    delete lstCD;
                }catch(Exception ex){}
            }else{
                // add document
                lstCV = [SELECT Id, contentDocumentId, Sourcing_Event__c,Sourcing_Event__r.ownerid,Sourcing_Event__r.Sourcing_Status__c,Sourcing_Event__r.Name,Sourcing_Event__r.Owner.Email, ownerid, Negotiation_Round__c, Participant__c, Participant__r.Contact_Bidder__c,Participant__r.TECH_ParticipantName__c FROM ContentVersion WHERE contentDocumentId IN :mapDocWrap.keySet()];
                for(ContentVersion cv: lstCV){
                    mapCD.put(cv.contentDocumentId, cv);
                }

                lstCV = new List<ContentVersion>();
                for(DocumentWrapper doc: lstUploadedDoc){
                    ContentVersion cv = mapCD.get(doc.documentId);
                    cv.Sing_DocumentName__c = doc.name;
                    cv.Sourcing_Event__c = recordId;
                    if(doc.participantId != null){
                        cv.Participant__c = doc.participantId;
                    }
                    // 10-MAR-2022  ARA SP-03276
                    if(doc.roundId != null && !lstRFXDocType.contains(doc.type)){
                        cv.Negotiation_Round__c = doc.roundId;
                    }
                    if(doc.sharingLogic != null){
                        cv.Sharing_Logic__c = doc.sharingLogic;
                    }
                    lstCV.add(cv);
                }

                system.debug('## lstCD '+lstCD);
                system.debug('## lstCV '+lstCV);
                system.debug('## lstCDLs '+lstCDLs);
                if(lstCD.size() > 0){
                    try{
                        update lstCV;
                        update lstCD;

                        //AMA 07/12/2022
                        AP75_ManageNotificationSE_ctin.sendNotif(lstCV,lstCD,false);

                        if(lstCDLs.size()>0){
                            insert lstCDLs;
                        }
                        map<String,Object> mapResult= getAllDocuments(recordId);
                        List<DocumentWrapper> lstDocument = (List<DocumentWrapper>)mapResult.get('data');
                        mapOfResult.put('data', lstDocument);
                        mapOfResult.put('success', System.label.LWC03_UploadedSuccess);
                    }  
                    catch(DMLException e){
                        mapOfResult.put('error', e.getMessage());  
                    }
                }
            }
        }
        return mapOfResult;
    }

    @AuraEnabled
    public static map<String,Object> addParticipantDocuments(List<DocumentWrapper> lstUploadedDoc, String recordId){
        map<String,Object> mapOfResult = new map<String,Object>();
        map<String,String> mapEmailData = new map<String,String>();
        map<Id,ContentVersion> mapCD = new map<Id,ContentVersion>();
        map<Id,DocumentWrapper> mapDocWrap = new map<Id,DocumentWrapper>();
        List<ContentDocument> lstCD = new List<ContentDocument>();
        List<ContentVersion> lstCV = new List<ContentVersion>();
        List<ContentDocumentLink> lstCDLs = new List<ContentDocumentLink>();
        Map<Id, ContentDocumentLink> mapCDL = new Map<Id, ContentDocumentLink>();
        List<String> lstRFXDocType = new List<String>{AP_Constant.DOCUMENT_TYPE_RFX_REQUIREMENTS, AP_Constant.DOCUMENT_TYPE_RFX_RESULTS};
        system.debug('## lstUploadedDoc '+lstUploadedDoc);
        //mra 24/11/2021 : copy file on all particpant with visibility = all Users if shring logic=All vendors
		Map<Id, Bidder__c> mapBidder = new Map<Id, Bidder__c>([SELECT id, Sourcing_Event__r.Bid_Due_Date__c,Sourcing_Event__c                                              
                                    FROM Bidder__c
                                    WHERE Id =:recordId]);

                                    system.debug('## mapBidder '+mapBidder);
        for(DocumentWrapper doc: lstUploadedDoc){
            mapDocWrap.put(doc.documentId, doc);
        }
        lstCD = [SELECT Id, contentSize, FileExtension, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN :mapDocWrap.keySet()];
        for(ContentDocumentLink cdl : [SELECT id,LinkedEntityId,ContentDocumentId, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]){
            mapCDL.put(cdl.ContentDocumentId, cdl);
        }
        system.debug('## lstCD '+lstCD);
        system.debug('### mapCDL '+mapCDL);
        if(lstCD.size() > 0){
            for(ContentDocument cd: lstCD){
                system.debug('### cd.Id '+cd.Id);
                ContentDocumentLink cdl = mapCDL.get(cd.Id);
                DocumentWrapper doc = mapDocWrap.get(cd.Id);
                String type = doc.type;
                // Changing file description with user entered description
                if(cd.Title != mapDocWrap.get(cd.Id).Name){
                    cd.Title = mapDocWrap.get(cd.Id).Name.replace('.'+cd.FileExtension, '');
                }
                if(cd.Title.toLowercase().contains('_sow')){
                    mapOfResult.put('error', System.Label.LWC2_ContainsSOW);
                }else if(type == System.Label.LWC03_DocumentTypeExternal && (cd.contentSize > 10485760 || cd.FileExtension != 'pdf')){
                    mapOfResult.put('error', System.Label.LWC03_ExternalFileSize);
                }else if(type == System.Label.LWC03_DocumentTypeInternal && cd.contentSize > 52428800){
                    mapOfResult.put('error', System.Label.LWC03_InternalFileSize);
                }else{
                    cd.description = type;// Changing file description with user entered description
                    // For specific vendor
                    if(doc.sharingLogic == 'Specific Vendor'){
                        cdl.Visibility='AllUsers';
                    }
                    if(doc.sharingLogic == 'All Vendors' && mapBidder.size()>0){
                        cdl.Visibility='AllUsers';
                    }
                    lstCDLs.add(cdl);
                }
                Decimal contentSize = cd.contentSize<1048576 ? Decimal.ValueOf(cd.contentSize)/1024 : Decimal.ValueOf(cd.contentSize)/1048576;
                contentSize = contentSize.setScale(2, RoundingMode.HALF_UP);
                DocumentWrapper dw = mapDocWrap.get(cd.Id);
                dw.description = cd.Title + '.'+ cd.FileExtension + ' ' + (cd.contentSize<1048576 ? '('+ contentSize + 'Kb)' : '('+contentSize + 'Mb)');
                mapDocWrap.put(cd.Id, dw);
            }

            if(mapOfResult.containsKey('error')){
                system.debug('## error ');
                mapOfResult.put('data',mapDocWrap.values());
                try{
                    delete lstCD;
                }catch(Exception ex){}
            }else{
                system.debug('## success ');
                // add document
                lstCV = [SELECT Id, contentDocumentId, Sourcing_Event__c,Sourcing_Event__r.ownerid,Sourcing_Event__r.Sourcing_Status__c, ownerid, Sourcing_Event__r.Name,Sourcing_Event__r.Owner.Email, Negotiation_Round__c, Negotiation_Round__r.Name, Participant__c, Participant__r.Name, Participant__r.TECH_ParticipantName__c,Participant__r.Contact_Bidder__c FROM ContentVersion WHERE contentDocumentId IN :mapDocWrap.keySet()];
                for(ContentVersion cv: lstCV){
                    mapCD.put(cv.contentDocumentId, cv);
                    mapEmailData.put('sourcing_event_name', cv.Sourcing_Event__r.Name);
                    mapEmailData.put('negotiation_round_name', cv.Negotiation_Round__r.Name);
                    mapEmailData.put('participant_name', cv.Participant__r.TECH_ParticipantName__c +' ('+cv.Participant__r.Name+')');
                    mapEmailData.put('document_url', URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/ContentDocument/'+cv.contentDocumentId+'/view');
                }

                lstCV = new List<ContentVersion>();
                for(DocumentWrapper doc: lstUploadedDoc){
                    ContentVersion cv = mapCD.get(doc.documentId);
                    cv.Sing_DocumentName__c = doc.name;
                    if(doc.participantId != null){
                        cv.Sourcing_Event__c = mapBidder.get(doc.participantId).Sourcing_Event__c;
                        cv.Participant__c = doc.participantId;
                    }
                    if(doc.sharingLogic != null){
                        cv.Sharing_Logic__c = doc.sharingLogic;
                    }
                    lstCV.add(cv);
                }

                system.debug('## lstCD '+lstCD);
                system.debug('## lstCV '+lstCV);
                system.debug('## lstCDLs '+lstCDLs);
                if(lstCD.size() > 0){
                    try{
                        update lstCV;
                        update lstCD;
                        
                        //AMA 07/12/2022
                        AP75_ManageNotificationSE_ctin.sendNotif(lstCV,lstCD,true);

                        if(lstCDLs.size()>0){
                            update lstCDLs;
                        }
                        map<String,Object> mapResult= getAllDocuments(recordId);
                        List<DocumentWrapper> lstDocument = (List<DocumentWrapper>)mapResult.get('data');
                        mapOfResult.put('data', lstDocument);
                        mapOfResult.put('success', System.label.LWC03_UploadedSuccess);
                    }  
                    catch(DMLException e){
                        mapOfResult.put('error', e.getMessage());  
                    }
                }
            }
        }
        //18-AUG-2022  ARA  SP-03701
        if(mapOfResult.containsKey('data')){
            Map<String, Messaging.SingleEmailMessage> mapEmail = new Map<String, Messaging.SingleEmailMessage>();
            //Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emToParticipant = [SELECT id , HtmlValue, Subject, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName =: 'Portal_new_document_uploaded'];
            List<Sourcing_Event_Team__c> lstTeamMember = [SELECT Id, Name, Tech_TeamMemberName__c, Sourcing_Event__r.Name, Team_Member__c,Team_Member__r.email, Team_Member__r.Name FROM Sourcing_Event_Team__c WHERE Sourcing_Event__c = :mapBidder.get(recordId).Sourcing_Event__c];

            if(emToParticipant != null && lstTeamMember.size() > 0){
                String subject = string.valueOf(emToParticipant.Subject).replace('{sourcing_event_name}', mapEmailData.get('sourcing_event_name'));
                String body = string.valueOf(emToParticipant.HtmlValue);
                body = body.replace('{participant_name}', mapEmailData.get('participant_name'));
                body = body.replace('{sourcing_event_name}', mapEmailData.get('sourcing_event_name'));
                body = body.replace('{negotiation_round_name}', mapEmailData.get('negotiation_round_name'));
                body = body.replace('{document_url}', mapEmailData.get('document_url'));

                String editedBody = body;
                for(Sourcing_Event_Team__c team : lstTeamMember){
                    List<String> lstDestinataire = new List<String>();
                    lstDestinataire.add(team.Team_Member__r.Email);
                    body = editedBody.replace('{team_member_name}',  team.Tech_TeamMemberName__c);
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToaddresses(lstDestinataire);
                    //email.setCcaddresses(lstCcDestinataire);
                    email.setTemplateId(emToParticipant.Id);
                    email.setSubject(subject);
                    email.setHtmlBody(body);
    
                    mapEmail.put(team.Team_Member__r.Email, email);
                }

                if(!test.isRunningTest()){
                    if(mapEmail.size() > 0){
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(mapEmail.values());
                        if (results[0].success) {
                            mapOfResult.put('success', System.label.LWC03_UploadedSuccess + ' The sourcing teams are notified.');
                        } else {
                            mapOfResult.put('success', System.label.LWC03_UploadedSuccess +'But an error occurs when notifying the Sourcing teams.');
                        }
                    }            
                }else{
                    mapOfResult.put('success', System.label.LWC03_UploadedSuccess + ' The sourcing teams are notified.'); 
                }
            }
        }

        system.debug('## mapOfResult '+mapOfResult);
        return mapOfResult;
    }

    @AuraEnabled
    public static map<String, Object> replaceDocument(DocumentWrapper newDoc, String originDocId, String recordId){
        map<String,Object> mapOfResult = new map<String,Object>();
        Map<Id, DocumentWrapper> mapDocWrap = new Map<Id, DocumentWrapper>();
        ContentVersion oldCV;
        List<ContentVersion> lstCV = new List<ContentVersion>();
        List<ContentDocument> lstCD = new List<ContentDocument>();
        ContentDocumentLink cdl;
        String type = newDoc.type;
        
        lstCD = [SELECT Id, contentSize, FileExtension, Title, createdDate, LatestPublishedVersionId FROM ContentDocument WHERE Id = :newDoc.documentId];
        for(ContentDocument cd : lstCD){
            if(cd.Title.toLowercase().contains('_sow')){
                mapOfResult.put('error', System.Label.LWC2_ContainsSOW);
            }else if(type == System.Label.LWC03_DocumentTypeExternal && (cd.contentSize > 10485760 || cd.FileExtension != 'pdf')){
                mapOfResult.put('error', System.Label.LWC03_ExternalFileSize);
            }else if(type == System.Label.LWC03_DocumentTypeInternal && cd.contentSize > 52428800){
                mapOfResult.put('error', System.Label.LWC03_InternalFileSize);
            }else{
                cd.description = newDoc.type;// Changing file description with user entered description
                newDoc.createdDate = cd.createdDate;
            }
            Decimal contentSize = cd.contentSize<1048576 ? Decimal.ValueOf(cd.contentSize)/1024 : Decimal.ValueOf(cd.contentSize)/1048576;
            contentSize = contentSize.setScale(2, RoundingMode.HALF_UP);
            newDoc.description = cd.Title + '.'+ cd.FileExtension + ' ' + (cd.contentSize<1048576 ? '('+ contentSize + 'Kb)' : '('+contentSize + 'Mb)');
            mapDocWrap.put(cd.Id, newDoc);
        }

        if(mapOfResult.containsKey('error')){
            mapOfResult.put('data',mapDocWrap.values());
            try{
                delete lstCD;
            }catch(Exception ex){}
        }else{
            //mra 24/11/2021 : copy file on all particpant with visibility = all Users if shring logic=All vendors
            list<contentDocumentLink> lstCDLs = new list<contentDocumentLink>();
        
            list<Bidder__c> lstBidder = [SELECT id, Sourcing_Event__r.Bid_Due_Date__c, Sourcing_Event__c                                              
                                        FROM Bidder__c
                                        WHERE Sourcing_Event__c =:recordId];
            
            // Changing file description with user entered description
            ContentDocument doc = new ContentDocument(Id = newDoc.documentId);
            doc.description = newDoc.type;

            /*// For specific vendor
            if(newDoc.sharingLogic == 'Specific Vendor'){
                cdl = new contentDocumentLink(LinkedEntityId = newDoc.participantId ,ContentDocumentId = newDoc.documentId, Visibility='AllUsers');
            }
            //mra 24/11/2021
            if(newDoc.sharingLogic == 'All Vendors' && lstBidder.size()>0){
                for(Bidder__c bidder: lstBidder){
                    lstCDLs.add(new contentDocumentLink(LinkedEntityId = bidder.Id ,ContentDocumentId = newDoc.documentId, Visibility='AllUsers'));
                }
            }*/

            oldCV = [SELECT Id, contentDocumentId, Negotiation_Round__c, Participant__c, Sharing_Logic__c FROM ContentVersion WHERE contentDocumentId = :originDocId LIMIT 1];
            lstCV = [SELECT Id, contentDocumentId, Negotiation_Round__c, Participant__c FROM ContentVersion WHERE contentDocumentId = :newDoc.documentId];

            for(ContentVersion cv : lstCV){
                cv.Sing_DocumentName__c = newDoc.name;
                cv.Negotiation_Round__c = oldCV.Negotiation_Round__c;
                cv.Participant__c = oldCV.Participant__c;
                cv.Sharing_Logic__c = oldCV.Sharing_Logic__c;
                cv.Sourcing_Event__c = recordId;
            }

            try{
                update doc;
                if(lstCV.size() > 0){
                    update lstCV;
                    Map<Id, contentDocumentLink> mapCDLtoUpdate  = new Map<Id, contentDocumentLink>();
                    List<contentDocumentLink> lstCDLtoAdd  = new List<contentDocumentLink>();
                    List<contentDocumentLink> lstCDLtoDelete  = new List<contentDocumentLink>();
                    Map<Id, contentDocumentLink> mapCDLink = new Map<Id, contentDocumentLink>();

                    for(contentDocumentLink cdlink : [SELECT LinkedEntityId, Visibility, ContentDocumentId FROM contentDocumentLink WHERE ContentDocumentId =: doc.Id]){
                        mapCDLink.put(cdlink.LinkedEntityId, cdlink);
                    }
                    
                    for(contentDocumentLink cdlink : [SELECT LinkedEntityId, Visibility, ContentDocumentId FROM contentDocumentLink WHERE ContentDocumentId =: originDocId]){
                        if(mapCDLink.containsKey(cdlink.LinkedEntityId)){
                            mapCDLtoUpdate.put(mapCDLink.get(cdlink.LinkedEntityId).Id, new contentDocumentLink(Id = mapCDLink.get(cdlink.LinkedEntityId).Id, Visibility = cdlink.Visibility));
                        }else{
                            lstCDLtoAdd.add(new contentDocumentLink(ContentDocumentId = doc.Id, LinkedEntityId = cdlink.LinkedEntityId, Visibility = cdlink.Visibility));
                        }
                    }

                    for(contentDocumentLink cdlink : mapCDLink.values()){
                        if(!mapCDLtoUpdate.containsKey(cdlink.Id)){
                            lstCDLtoDelete.add(new contentDocumentLink(Id = cdlink.Id));
                        }
                    }
                
                    //mra 24/11/2021
                    if(mapCDLtoUpdate.size()>0){
                        update mapCDLtoUpdate.values();
                    }
                    if(lstCDLtoAdd.size()>0){
                        insert lstCDLtoAdd;
                    }
                    if(lstCDLtoDelete.size()>0){
                        delete lstCDLtoDelete;
                    }
                }

                Map<Id, Negotiation_Round__c> mapNegotiationRound = new Map<Id, Negotiation_Round__c>([SELECT Id, Name FROM Negotiation_Round__c WHERE Sourcing_Event__c = :recordId]);
                Map<Id, Bidder__c> mapParticipant = new Map<Id, Bidder__c>([SELECT Id, Name, TECH_ParticipantName__c FROM Bidder__c WHERE Sourcing_Event__c = :recordId]);
                
                if(newDoc.roundId != null && mapNegotiationRound.containsKey(newDoc.roundId)){
                    newDoc.round = mapNegotiationRound.get(newDoc.roundId);
                }
                if(newDoc.participantId != null && mapParticipant.containsKey(newDoc.participantId)){
                    newDoc.participant = mapParticipant.get(newDoc.participantId);
                }

                // Delete old document
                ContentDocument oldDoc = new ContentDocument(Id = originDocId);
                delete oldDoc;

                mapOfResult.put('data', newDoc);  
            }  
            catch(DMLException e){
                if(e.getMessage().contains(System.Label.Sing_ErrorMessageUpdateDoc)){
                    mapOfResult.put('error', System.Label.Sing_ErrorMessageUpdateDoc);
                }else{
                    mapOfResult.put('error', e.getMessage());  
                }
            }
        }
        system.debug('********** '+mapOfResult);
        return mapOfResult;
    }

    @AuraEnabled
    public static Map<String,String> deleteDocument(List<String> documentId){
        Map<String,String> mapResult = new Map<String,String>();
        //ContentDocument doc = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id=:documentId];
        List<ContentVersion> lstCV = [SELECT Id, contentDocumentId, Title, ContentDocument.description, Sourcing_Event__r.Sourcing_Status__c, OwnerId
                            FROM ContentVersion 
                            WHERE contentDocumentId = :documentId];

        if(lstCV.size() > 0){
            ContentVersion cv = lstCV[0];
            if(UserInfo.getUserId() != cv.OwnerId){
                mapResult.put('error', Label.Error_NoRightToDeleteDocument);
            }else if(cv.ContentDocument.description == 'RFX Requirements' && cv.Sourcing_Event__r.Sourcing_Status__c != AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS && cv.Sourcing_Event__r.Sourcing_Status__c != AP_Constant.SOURCING_EVENT_STATUS_CANCELLED){
                mapResult.put('error', Label.ErrorMessage_CannotDeleteRFXRequirementsDoc);
            }

            if(!mapResult.containsKey('error')){
                try{
                    delete new ContentDocument(Id = cv.contentDocumentId);
                }catch(Exception e){
                    if(e.getMessage().contains(Label.AP03_Sing_ErrorDocumentUploadedDeletion)){
                        mapResult.put('error', Label.AP03_Sing_ErrorDocumentUploadedDeletion);
                    }else if(e.getMessage().contains(Label.ErrorMessage_CannotDeleteRFXRequirementsDoc)){
                        mapResult.put('error', Label.ErrorMessage_CannotDeleteRFXRequirementsDoc);
                    }
                }
                if(!mapResult.containsKey('error')){
                    mapResult.put('success', Label.LWC2_TheDocument+' "'+ cv.Title +'" '+Label.LWC2_IsDeleted);
                }
            }
        }else{
            mapResult.put('error', Label.Error_DocumentNotExist);
        }
        return mapResult;
    }

    @AuraEnabled
    public static map<String, Object> updateDocument(List<DocumentWrapper> lstDocuments, String recordId){
        map<String,Object> mapOfResult = new map<String,Object>();
        map<Id,ContentVersion> mapCD = new map<Id,ContentVersion>();
        List<ContentVersion> lstCV;
        List<String> lstDocId=  new List<String>();
        for(DocumentWrapper dw: lstDocuments){
            lstDocId.add(dw.documentId);
        }
        
        for(ContentVersion cv: [SELECT Id, contentDocumentId, Negotiation_Round__c, Participant__c FROM ContentVersion WHERE contentDocumentId IN :lstDocId]){
            mapCD.put(cv.contentDocumentId, cv);
        }

        lstCV = new List<ContentVersion>();
        for(DocumentWrapper doc: lstDocuments){
            ContentVersion cv = mapCD.get(doc.documentId);
            cv.Sing_DocumentName__c = doc.name;
            lstCV.add(cv);
        }

        if(lstCV.size() > 0){
            try{
                update lstCV;
                map<String,Object> mapResult= getAllDocuments(recordId);
                List<DocumentWrapper> lstDocument = (List<DocumentWrapper>)mapResult.get('data');
                mapOfResult.put('data', lstDocument);  
            }  
            catch(DMLException e){
                if(e.getMessage().contains(System.Label.Sing_ErrorMessageDeleteDoc)){
                    mapOfResult.put('error', System.Label.Sing_ErrorMessageDeleteDoc);
                }else{
                    mapOfResult.put('error', 'Error occured while trying to delete the document.');
                }
            }
        }

        return mapOfResult;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getLoginURL(){
        String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        User userRecord = [Select Id, AccountId, ContactId FROM User Where Id = :UserInfo.getUserId()];
        if(userRecord.ContactId != null){
            baseUrl = getExperienceURL();
        }
        return baseUrl;
    }

    public static String getExperienceURL(){
        String baseUrl = Network.getLoginUrl(Network.getNetworkId());
        baseURL =  baseURL.replace('/s/login', '');
        baseURL =  baseURL.replace('/s/Login', '');
        baseURL =  baseURL.replace('/login', '');
        baseURL =  baseURL.replace('/Login', '');
        return baseURL;
    }

    // wrapper class
    public class DocumentWrapper{
        @AuraEnabled public string Id {get; set;}
        @AuraEnabled public Id cvId {get; set;}
        @AuraEnabled public Document__mdt doc {get; set;}
        @AuraEnabled public boolean inserted {get; set;}
        @AuraEnabled public boolean required {get; set;}
        @AuraEnabled public string documentId  {get; set;}
        @AuraEnabled public String stage {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String fileName {get; set;}
        @AuraEnabled public String fileType {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String roundId {get; set;}
        @AuraEnabled public Negotiation_Round__c round {get; set;}
        @AuraEnabled public String participantId {get; set;}
        @AuraEnabled public Bidder__c participant {get; set;}
        @AuraEnabled public String sharingLogic {get; set;}
        @AuraEnabled public String docURL {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public Integer size {get; set;}
        @AuraEnabled public Datetime createdDate {get; set;}
        @AuraEnabled public User owner {get; set;}
        @AuraEnabled public string LatestPublishedVersionId  {get; set;}
    }
}