public class LC02_OppAddDocument {
	@AuraEnabled
	public static List<DocumentWrapper> loadData(Id oppId){
	    map<string, Document__mdt> mapDoc = new Map<string, Document__mdt>();
	    map<string,DocumentWrapper> mapDocumentWrapper = new map<string,DocumentWrapper>();
	    map<string,DocumentWrapper> mapDocumentWrapperDisplay = new map<string,DocumentWrapper>();
	    list<DocumentWrapper> listDocumentWrapperDisplay = new list<DocumentWrapper>();
	    map<string,string> mapAttachment = new map<string,string>(); 
	    Attachment uploadeddocument = new Attachment();

        Opportunity opp = [select Id, AXA_GO_Entity__c, Category__c from Opportunity where Id = : oppId];

        for(Document__mdt doc : [SELECT DeveloperName, MasterLabel FROM Document__mdt]){
            mapDoc.put(doc.DeveloperName, doc);
        }

        Set<Id> documentIds = new Set<Id>();  
        List<ContentDocumentLink> cdl=[select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:oppId];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }      
  
        for(ContentDocument att:[select Id,Title,FileType,ContentSize,Description from ContentDocument where id IN: documentIds]){
            mapAttachment.put(att.description,att.id);
        }

        for(RequiredDocuments__mdt rd: [SELECT Stage__c, RequiredDocuments__c, OptionalDocuments__c
                                        FROM RequiredDocuments__mdt
                                        WHERE ObjectName__c = 'Opportunity'
                                        AND Stage__c <> null
                                        AND AXA_GS_Entity__c = :opp.AXA_GO_Entity__c
                                        ] ){


            // required doc
            if(string.isNotBlank(rd.RequiredDocuments__c)){
                for(string docName:rd.RequiredDocuments__c.split(';')){
                    if(string.isNotBlank(docName) && mapDoc.containsKey(docName)){
                        DocumentWrapper dw = new DocumentWrapper();
                        dw.doc = mapDoc.get(docName);
                        
                        if (Label.OptyCategory_Project.equals(opp.Category__c)) {
                            dw.required = true;
                        }
                        dw.stage = rd.Stage__c;
                        dw.inserted = mapAttachment.containsKey(docName);
                        dw.attachmentId = mapAttachment.get(docName);
                        mapDocumentWrapperDisplay.put(docName,dw);
                        listDocumentWrapperDisplay.add(dw);
                        //System.debug('@@ listDocumentWrapperDisplay' + listDocumentWrapperDisplay);
                        
                    }
                }
            }
                
            // optional doc
            if(string.isNotBlank(rd.OptionalDocuments__c)){
                for(string docName:rd.OptionalDocuments__c.split(';')){
                    if(string.isNotBlank(docName) && mapDoc.containsKey(docName) && !mapDocumentWrapperDisplay.containsKey(docName)){
                        DocumentWrapper dw = new DocumentWrapper();
                        dw.doc = mapDoc.get(docName);
                        dw.required = false;
                        dw.stage = rd.Stage__c;
                        dw.inserted = mapAttachment.containsKey(docName);
                        dw.attachmentId = mapAttachment.get(docName);
                        mapDocumentWrapperDisplay.put(docName,dw);
                        listDocumentWrapperDisplay.add(dw);
                        //System.debug('@@ listDocumentWrapperDisplay' + listDocumentWrapperDisplay);
                        
                    }
                }
            }
        }
        //System.debug('@@ listDocumentWrapperDisplay=' + listDocumentWrapperDisplay);  
        return listDocumentWrapperDisplay;
    }
    @AuraEnabled
    public static void UpdateFiles(string documentId,string description,Id oppId){
        ContentDocument cd = [select id,description from ContentDocument where Id=:documentId]; // Getting files from Parent record 
        cd.description = description;  // Changing file description with user entered description
        try{
            update cd;
        }  
        catch(DMLException e){
            system.debug('Exception has occurred! ' +e.getMessage());  
        }
    } 
    // wrapper class
    public class DocumentWrapper{
        @AuraEnabled public Document__mdt doc {get; set;}
        @AuraEnabled public boolean inserted {get; set;}
        @AuraEnabled public boolean required {get; set;}
        @AuraEnabled public string attachmentId  {get; set;}
        @AuraEnabled  public String stage {get; private set;}
    }
}