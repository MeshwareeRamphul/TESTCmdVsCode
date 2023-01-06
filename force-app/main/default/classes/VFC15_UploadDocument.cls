public with sharing class VFC15_UploadDocument {
/* 
------------------------------------------------------------
-- - Name          : VFC15_UploadDocument
-- - Author        : Niccolo Giaccone
-- - Description   : Controller for page VFP18_UploadDocument
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -----------------------------
-- 01-APR-2016  NGI   1.0      Initial version from Singapour Spoon 
-- 11-APR-2016  NGI   1.1      Customized for Lucy
-- 29-JUL-2016  ABU   1.2      Code from Lucy (VFC18_UploadDocument.cls) adapted for AllIn (no LoB__c, Custom Settings Document__c and RequiredDocuments__c replaced by Custom Metadata Type)
-- 07-SEP-2016  DLA   1.3      Modification of "public List<SelectOption> getItems()" Return Function to avoid the Document Asc Sorting in the Doc Picklist within the Pop Up (keep same order Picklist values vs list of doc in the Array)

------------------------------------------------------------
*///   
    public Opportunity opp;
    public set<string> DocumentToLoad;
    public map<string, Document__mdt> mapDoc;
    public map<string,DocumentWrapper> DocumentWrapperMap {get; set;}
    public map<string,DocumentWrapper> DocumentWrapperMapDisplay {get; set;}
    public list<DocumentWrapper> listDocumentWrapperDisplay {get; set;}
    public map<string,string> mapAttachment;
    public string selectedOption {get; set;}
    public string msg {get; set;}
    public boolean hideAddDocument {get; set;}
    public Pagereference popupUrl {get; set;}
    public Blob uploadedDoc {get;set;}
    public Attachment uploadeddocument {get;set;}
    public set<String> requiredDocSet;
    public set<String> insertedSubDocSet;
    public set<String> MandatoryDocumentsSet;
    public set<String> doubleCopyDocumentsSet;
    public decimal Counter;
    
    public boolean showUploadDocument{get;set;}
    public boolean showDone{get;set;}
    public string userType;
    
    //Constructor
    public VFC15_UploadDocument(ApexPages.StandardController controller)
    {
        System.Debug('#### >>> Start of  controller VFC15_UploadDocument <<< ');
        opp=(Opportunity)controller.getRecord();
        uploadeddocument = new Attachment();
        // get the custom metadata type "Documents" details
        mapDoc = new Map<string, Document__mdt>();
        for (Document__mdt doc : [SELECT DeveloperName, MasterLabel FROM Document__mdt]) {
            mapDoc.put(doc.DeveloperName, doc);
        }
        // call loadData
        loaddata();
        showUploadDocument=true;
        showDone=false;
        hideAddDocument = true;
        
        if (String.ISNOTBLANK(ApexPages.currentPage().getParameters().get('hideadddocument')) ){
              hideAddDocument = false;
        }
        //userType=UserInfo.getUserType();
        popupUrl = Page.VFP15_UploadDocument;
        popupUrl.getParameters().put('id', String.valueOf(opp.Id));
        popupUrl.getParameters().put('hideadddocument', 'false');
   
        System.Debug('#### >>> End of  controller VFC15_UploadDocument <<< ');
    }
    
    
    public void loadData(){
        DocumentWrapperMap = new map<string,DocumentWrapper>();
        DocumentWrapperMapDisplay = new map<string,DocumentWrapper>();
        listDocumentWrapperDisplay = new list<DocumentWrapper>();
        uploadeddocument = new Attachment();
        mapAttachment = new map<string,string>(); 
  
        for(Attachment att:[SELECT id, description 
                            FROM Attachment 
                            WHERE parentid = :opp.id
                            AND description <> null
                            ORDER BY createddate ASC]){
            mapAttachment.put(att.description,att.id);
        }
        System.debug('mapAttachment=' + mapAttachment);

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
                        DocumentWrapperMapDisplay.put(docName,dw);
                        listDocumentWrapperDisplay.add(dw);
                    }
                }
            }
            
            // optional doc
            if(string.isNotBlank(rd.OptionalDocuments__c)){
                for(string docName:rd.OptionalDocuments__c.split(';')){
                    if(string.isNotBlank(docName) && mapDoc.containsKey(docName) && !DocumentWrapperMapDisplay.containsKey(docName)){
                        DocumentWrapper dw = new DocumentWrapper();
                        dw.doc = mapDoc.get(docName);
                        dw.required = false;
                        dw.stage = rd.Stage__c;
                        dw.inserted = mapAttachment.containsKey(docName);
                        dw.attachmentId = mapAttachment.get(docName);
                        DocumentWrapperMapDisplay.put(docName,dw);
                        listDocumentWrapperDisplay.add(dw);
                    }
                }
            }
        }
        System.debug('listDocumentWrapperDisplay=' + listDocumentWrapperDisplay);     
    }
    
    public List<SelectOption> getItems() 
    {
        System.Debug('#### >>> Start of  method VFC05_UploadDocument.getItems <<< ');
        List<SelectOption> options = new List<SelectOption>();

        for(string num:DocumentWrapperMapDisplay.keyset()){
            options.add(new SelectOption(num,(mapDoc.get(num).MasterLabel))); 
        }
        
        System.Debug('#### >>> End of  method VFC05_UploadDocument.getItems <<< ');
        return options;
    }      

    /*public List<selectOption> sortSelectOptionByLabel(list<selectOption> selectOptionsToSort) {
        system.Debug('#### >>> AP_Constant.sortSelectOptionByLabel : START <<< ');
        // Used to sort the labels of a selectOption
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
        
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getLabel() <= pivotValue.getLabel()){
                lessSelectOption.add(SO);
            }else if(SO.getLabel() > pivotValue.getLabel()){
                greaterSelectOption.add(SO);   
            }
        }
        list<selectOption> sortedSelectOptions = new list<selectOption>(); 
        sortedSelectOptions.addAll(sortSelectOptionByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(sortSelectOptionByLabel(greaterSelectOption));
        system.Debug('#### >>> AP_Constant.sortSelectOptionByLabel : END <<< ');
        return SortedSelectOptions;
    }*/

    public Pagereference uploadDocument(){
        System.Debug('#### >>> Start of  method VFC05_UploadDocument.uploadDocument <<< ');
        system.debug('##### Selected option:'+selectedOption);
        system.debug('##### Selected document:'+uploadeddocument);
        system.debug('##### Selected document:'+uploadeddocument.body);
        showDone=false;
        if(uploadeddocument.name<>null){            
            if(uploadeddocument.body<>null){
                showDone=true;
                uploadeddocument.parentid=opp.id;
                uploadeddocument.description = selectedOption;
                insert uploadeddocument;
                loaddata();
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Attachment_UploadSuccessful);                                                         
                ApexPages.addMessage(myMsg); 
            }
            
        }
        else{
            //display error msg if no file is chosen
            showDone=false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Attachment_MissingDocument);                                                          
            ApexPages.addMessage(myMsg);   
        }    
        System.Debug('#### >>> End of  method VFC05_UploadDocument.uploadDocument <<< ');
        return null;
    }
    
    // wrapper class
    public class DocumentWrapper{
        public Document__mdt doc {get; set;}
        public boolean inserted {get; set;}
        public boolean required {get; set;}
        public string attachmentId  {get; set;}
        public String stage {get; private set;}
    }
}