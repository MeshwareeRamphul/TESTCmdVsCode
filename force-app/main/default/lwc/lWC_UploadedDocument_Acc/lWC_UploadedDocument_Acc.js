import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
// Apex
import getAllDocuments from '@salesforce/apex/LWC03_DocumentToUpload_Acc.getAllDocuments';
import replaceDocument from '@salesforce/apex/LWC03_DocumentToUpload_Acc.replaceDocument';
import deleteDocument from '@salesforce/apex/LWC03_DocumentToUpload_Acc.deleteDocument';
import getDocumentType from '@salesforce/apex/LWC03_DocumentToUpload_Acc.getDocumentType';
import addDocuments from '@salesforce/apex/LWC03_DocumentToUpload_Acc.addDocuments';
//import updateDocument from '@salesforce/apex/LWC03_DocumentToUpload_Acc.updateDocument';
// Resource
import DataTableCSS from '@salesforce/resourceUrl/DataTableCSS';
// Label
import LWC2_DocumentType from '@salesforce/label/c.LWC2_DocumentType';
import LWC2_SubType from '@salesforce/label/c.LWC2_SubType';
import LWC2_ChooseType from '@salesforce/label/c.LWC2_ChooseType';
import LWC2_ChooseSubType from '@salesforce/label/c.LWC2_ChooseSubType';
import LWC2_DocumentName from '@salesforce/label/c.LWC2_DocumentName';
import LWC2_FileName from '@salesforce/label/c.LWC2_FileName';
import LWC2_Owner from '@salesforce/label/c.LWC2_Owner';
import LWC2_CreatedDate from '@salesforce/label/c.LWC2_CreatedDate';
import LWC2_Of from '@salesforce/label/c.LWC2_Of';
import LWC2_Showing from '@salesforce/label/c.LWC2_Showing';
import LWC2_To from '@salesforce/label/c.LWC2_To';
import LWC2_Records from '@salesforce/label/c.LWC2_Records';
import LWC2_Preview from '@salesforce/label/c.LWC2_Preview';
import LWC2_ReplaceFile from '@salesforce/label/c.LWC2_ReplaceFile'; 
import LWC2_Delete from '@salesforce/label/c.LWC2_Delete';
import LWC2_AttachReceipt from '@salesforce/label/c.LWC2_AttachReceipt';LWC03_DeleteConfirmation
import LWC03_DeleteConfirmation from '@salesforce/label/c.LWC03_DeleteConfirmation';
import LWC03_SendForEsignature from '@salesforce/label/c.LWC03_SendForEsignature';
import LWC03_WithSuccess from '@salesforce/label/c.LWC03_WithSuccess';
import LWC03_ReplacedBy from '@salesforce/label/c.LWC03_ReplacedBy';
import LWC03_AddFiles from '@salesforce/label/c.LWC03_AddFiles';
import LWC03_AddFilesAction from '@salesforce/label/c.LWC03_AddFilesAction';
import LWC03_DeleteFile from '@salesforce/label/c.LWC03_DeleteFile';
import LWC03_FileType from '@salesforce/label/c.LWC03_FileType';
import LWC03_Files from '@salesforce/label/c.LWC03_Files';
import LWC2_File from '@salesforce/label/c.LWC2_File';
import labelCancel from '@salesforce/label/c.labelCancel';
import labelOk from '@salesforce/label/c.labelOK';
import titleSuccess from '@salesforce/label/c.titleSuccess';
import titleError from '@salesforce/label/c.titleError';
import LWC2_TheDocument from '@salesforce/label/c.LWC2_TheDocument';
import LWC2_IsDeleted from '@salesforce/label/c.LWC2_IsDeleted';
import LWC2_DeleteDocumentError from '@salesforce/label/c.LWC2_DeleteDocumentError';
import LWC2_SourcingDocumentsCompletedNo from '@salesforce/label/c.LWC2_SourcingDocumentsCompletedNo';
import LWC2_DocumentsCompletedError from '@salesforce/label/c.LWC2_DocumentsCompletedError';
import LWC03_Yes from '@salesforce/label/c.LWC03_Yes';
import LWC03_No from '@salesforce/label/c.LWC03_No';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';
import accountMessage from '@salesforce/messageChannel/accountMessageChannel__c';

const COLUMNS1 = [
    {label:LWC2_FileName, fieldName:'docURL', type: 'url', typeAttributes: {label: { fieldName: 'fileName' }}},
    {label:LWC03_FileType, fieldName:'type', type:'string', initialWidth: 150},
    {label:LWC2_SubType, fieldName:'subtype', type: 'string', initialWidth: 150},
    {label:LWC2_Owner, fieldName:'ownerURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'ownerName' }}},
    {label:LWC2_CreatedDate, fieldName:'createdDate', type: 'date', initialWidth: 150, cellAttributes: {alignment: 'center'}, typeAttributes: {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    }},
    {type: 'action', wrapText: true, typeAttributes: { rowActions: {fieldName: 'rowActions'} }, cellAttributes: { class: { fieldName: 'actionClass' }}}
]

export default class LWC_UploadedDocument_Acc extends NavigationMixin(LightningElement) {
    subscription = null;
    @api recordId;
    @api isLoading = false;
    @track user;
    @track isModalOpen = false;
    @track isAddFile = false;
    @track isReplaceFile = false;
    @track isDeleteFile = false;
    @track isRender = false;
    @track columns = COLUMNS1;
    @track multiple = true;
    @track headerTitle;
    @track selectedRowId;
    @track selectedDocId;
    @track actionName;
    @track optionDocumentType;
    @track optionDocumentSubType;
    @track optionDocumentSubTypeAccDoc;
    @track optionDocumentSubTypeAddDoc;
    @track selectedDocName;
    @track selectedFileName;
    @track selectedDocType;
    @track selectedDocSubType;
    @track isPicklistDisabled = false;
    @track divUpload = 'slds-form-element disabled';
    @track fileDetailClass;
    @track wrongFiles = [];
    @track draftValues = [];
    @track currentObject;
    @track currentRecordId;
    @track isRendered = false;
    @track fileUploadClass = 'disabledUpload';
    @track documentName;
    @track fileSize;
    @track isPreviousDisabled = 'isDisabled';
    @track isNextDisabled = 'isDisabled';

    @api sortedDirection = 'asc';
    @api sortedBy = 'Name';
    @api searchKey = '';
    result;
    subscription = null;
    @track page = 1; 
    @track data = [];
    @track items = [];
    @track startingRecord = 1;
    @track endingRecord = 0; 
    @track pageSize = 5; 
    @track totalRecountCount = 0;
    @track totalPage = 0;
    @track startFromIndex = 0;
    @track endIndex = 0;
    @track label = {
        LWC2_Of,
        LWC2_ReplaceFile,
        LWC2_DocumentType,
        LWC2_SubType,
        LWC2_ChooseType,
        LWC2_ChooseSubType,
        LWC2_DocumentName,
        LWC2_AttachReceipt,
        LWC03_SendForEsignature,
        LWC03_AddFiles,
        LWC03_AddFilesAction,
        LWC03_DeleteConfirmation,
        LWC03_Files,
        labelCancel,
        labelOk,
        LWC03_No,
        LWC03_Yes
    };

    @wire(MessageContext) messageContext;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                accountMessage,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        if(message.action == 'add_Files'){
            this.openAddfile();
        }
    }

    get acceptedFormats() {
        return ['.TXT','.PDF','.DOC','.DOCX','.XLS','.XLSX','.XLSM','.CSV','.JPG','.JPEG','.PNG','.PPT','.PPTX','.MSG'];
    }

    connectedCallback() {
        this.getDocuments();
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    renderedCallback() {  
        Promise.all([
            loadStyle( this, DataTableCSS )]).then()
            .catch(error => {
        });
    }

    initializeData(){
        this.type = '';
        this.optionDocumentType = [];
        this.optionDocumentSubType = [];
        this.optionDocumentSubTypeAccDoc = [];
        this.optionDocumentSubTypeAddDoc = [];
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                this.currentRecordId = this.recordId;
                getDocumentType({ recordId: this.recordId })
                .then(result => {
                    this.optionDocumentType = result.document;
                    this.optionDocumentSubTypeAccDoc = result.subtypeAccDoc;
                    this.optionDocumentSubTypeAddDoc = result.subtypeAddDoc;
                    this.currentObject = result.currentObject;
                    this.isLoading = false;
                })
                .catch(error => {
                });
            }
        }, 0);
    }

    getDocuments(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getAllDocuments({ recordId: this.recordId })
                .then(result => {
                    if(result){
                        this.user = result.user;
                        var data = result.data;

                        data.forEach(doc => {
                            doc.rowActions = [
                                { label: LWC2_Preview, name: 'preview_file' },
                                { label: LWC2_ReplaceFile, name: 'replace_file' },
                                { label: LWC2_Delete, name: 'delete_file' }
                            ];
                            //doc.size = this.roundToThree(doc.size/1048576) + ' Mb';
                            doc.actionClass = 'slds-visible';
                            if(doc.hasOwnProperty('owner')){
                                doc.ownerName = doc.owner.Name;
                                doc.ownerURL = '/lightning/r/' + doc.owner.Id +'/view';
                            }
                        });

                        // Pagination
                        this.totalRecountCount = data.length; 

                        if(this.totalRecountCount > 0){
                            this.items = data;
                            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                            this.data = this.items.slice(0,this.pageSize); 
                            this.endingRecord = this.pageSize;
                            this.isRender = true;
                            if(this.totalRecountCount > this.pageSize){
                                this.hidePagination = false;
                                this.isNextDisabled = '';
                            }
                        }
                    }else{
                        this.data = undefined;
                    }
                })
                .catch(error => {
                });
            }
        }, 0);
    }

    handleDocumentType(event){
        this.selectedDocType = event.detail.value;
        this.divUpload = 'slds-form-element';
        this.selectedDocSubType = null;
        if (this.selectedDocType == 'Accreditation Documents') {
            this.optionDocumentSubType = this.optionDocumentSubTypeAccDoc;
        } 
        else if(this.selectedDocType == 'Additional Documents'){
            this.optionDocumentSubType = this.optionDocumentSubTypeAddDoc;
        }
        
        this.fileUploadClass = 'disabledUpload';
    }

    handleDocumentSubType(event){
        this.selectedDocSubType = event.detail.value;
        this.divUpload = 'slds-form-element';
        this.fileUploadClass = '';
        if((typeof this.selectedDocType == 'undefined' || this.selectedDocType == null) || (typeof this.selectedDocSubType == 'undefined' || this.selectedDocSubType == null)){
            this.fileUploadClass = 'disabledUpload';
        } else{
            this.fileUploadClass = '';
        }
    }

    formatBytes(bytes,decimals) {
        if(bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
    
    roundToThree(num) {
        return Math.round((num + Number.EPSILON) * 1000) / 1000;
    }

    openAddfile(){
        this.headerTitle = LWC03_AddFiles;
        this.isModalOpen = true;
        this.isAddFile = true;
        this.isLoading = true;
        this.initializeData();
    }

    handleOnSelect(event){
        switch (event.detail.value) {
            case 'add_files':
                this.openAddfile();
            break;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        var selectedRow = event.detail.row;
        var documentId = selectedRow.documentId;

        this.actionName = action.name;
        this.selectedDocId = documentId;
        this.selectedRowId = selectedRow.Id;
        this.selectedDocType = selectedRow.type;
        this.selectedDocSubType = selectedRow.subtype;
        this.selectedFileName = selectedRow.fileName;

        switch (this.actionName) {
            case 'preview_file':
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state : {
                        recordIds: selectedRow.documentId,
                        selectedRecordId: selectedRow.documentId
                    }
                });
            break;
            case 'replace_file':
                this.headerTitle = LWC2_ReplaceFile;
                this.isReplaceFile = true;
                this.isModalOpen = true;
            break;
            case 'delete_file':
                this.headerTitle = LWC03_DeleteFile;
                this.isDeleteFile = true;
                this.isModalOpen = true;
            break;
        }
    }

    handleAddFile(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        var lstDoc = new Array();
        this.wrongFiles = [];
        this.isLoading = true;

        for(let i = 0; i < uploadedFiles.length; i++) {
            var doc = new Object();
            doc.documentId = uploadedFiles[i].documentId;
            doc.type = this.selectedDocType;
            doc.subtype = this.selectedDocSubType;
            doc.fileName = uploadedFiles[i].name;
            doc.size = uploadedFiles[i].size;

            lstDoc.push(doc);
        }

        if(lstDoc.length > 0){
            addDocuments({ lstUploadedDoc: lstDoc, recordId: this.recordId }).then(result => {
                console.log('****result ', JSON.stringify(result));
                var data = result.data;
                console.log('****data ', JSON.stringify(data));
                if(result.error){
                    this.fileDetailClass = 'errorFile';
                    if(data){
                        this.wrongFiles = data;
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleError,
                            message: result.error,
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleSuccess,
                            message: result.success,
                            variant: 'success',
                            mode: 'dismissable'
                        })
                    );
                    //let message = { data: result.data };
                    this.closeModal();
                    this.getDocuments();
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                this.isLoading = false;
            });
        }
    }

    handleReplaceFile(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        var doc = new Object();
        this.isLoading = true;
        this.wrongFiles = [];
        var oldFileName = this.selectedFileName;

        for(let i = 0; i < uploadedFiles.length; i++) {
            var uploadedFile = uploadedFiles[i];
            doc.Id = this.selectedRowId;
            doc.documentId = uploadedFile.documentId;
            doc.type = this.selectedDocType;
            doc.subtype = this.selectedDocSubType;
            doc.fileName = uploadedFile.name;
            doc.docURL = '/lightning/r/' + doc.documentId +'/view';
            doc.owner = this.user;
        }
        
        replaceDocument({ newDoc: doc, originDocId: this.selectedDocId,  recordId: this.recordId })
        .then(result => {
            var data = result.data;
            console.log('###',JSON.stringify(result));
            if(result.error){
                this.fileDetailClass = 'errorFile';
                if(data){
                    this.wrongFiles = data;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }else{
                console.log('****data ', JSON.stringify(data));
                if(data){
                    data.rowActions = [
                        { label: LWC2_Preview, name: 'preview_file' },
                        { label: LWC2_ReplaceFile, name: 'replace_file' },
                        { label: LWC2_Delete, name: 'delete_file' }
                    ];
                    //data.size = this.roundToThree(data.size/1048576) + ' Mb';
                    data.actionClass = 'slds-visible';
                    if(data.hasOwnProperty('owner')){
                        data.ownerName = data.owner.Name;
                        data.ownerURL = '/lightning/r/' + data.owner.Id +'/view';
                    }
                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleSuccess,
                            message: LWC2_File +' "'+ oldFileName +'" '+ LWC03_ReplacedBy +' "'+data.fileName+'" '+LWC03_WithSuccess,
                            variant: 'success',
                            mode: 'dismissable'
                        })
                    );
                    this.items[data.Id] = data;
                    this.displayRecordPerPage(this.page);

                    this.closeModal();
                }
            }
            this.isLoading = false;
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: titleError,
                    message: result.error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            this.isLoading = false;
        });
    }

    handleDelete(){
        var documentId = this.selectedDocId;
        var fileName = this.selectedFileName;
        var docIds = [];
        docIds.push(this.selectedDocId);
        this.isLoading = true;

        deleteDocument({ documentId: docIds })
        .then(result => {
            if(result == 'success'){
                this.items = this.items.filter(function(doc) { return doc.documentId !== documentId });
                this.totalRecountCount = this.items.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.displayRecordPerPage(this.page);
                if(this.totalRecountCount == 0){
                    this.isRender = false;
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleSuccess,
                        message: LWC2_TheDocument+' "'+ fileName +'" '+LWC2_IsDeleted  ,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.isDeleteFile = false;
            }else if(result == LWC2_DocumentsCompletedError){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: LWC2_SourcingDocumentsCompletedNo,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: LWC2_DeleteDocumentError,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            this.isLoading = false;
            this.closeModal();
        })
        .catch(error => {
            this.isLoading = false;
        });
    }

    handlePreviewFile(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                recordIds: event.target.dataset.id,
                selectedRecordId: event.target.dataset.id
            }
        });
    }
    //clicking on previous button this method will be called
    handlePreviousPage() {
        if (this.startFromIndex > 0) {
            this.startFromIndex = this.startFromIndex - this.pageSize;
            if (this.page > 1) {
                this.page = this.page - 1; //decrease page by 1
                this.displayRecordPerPage(this.page);
                
                if(this.page == 1){
                    this.isPreviousDisabled = 'isDisabled';
                }
            }
            this.isNextDisabled = '';
        }
        
    }

    //clicking on next button this method will be called
    handleNextPage() {
        if (this.startFromIndex + this.pageSize < this.totalRecountCount) {
            this.startFromIndex = this.startFromIndex + this.pageSize;
            if((this.page<this.totalPage) && this.page !== this.totalPage){
                this.page = this.page + 1; //increase page by 1
                this.displayRecordPerPage(this.page);
                if(this.page == this.totalPage){
                    this.isNextDisabled = 'isDisabled';
                }         
            }
            this.isPreviousDisabled = '';
        }           
    }

    get recordsInfo() {
        if (this.totalRecountCount > 0) {
            this.endIndex = this.startFromIndex + this.pageSize;
            return LWC2_Showing+' ' + (this.startFromIndex + 1) + ' '+LWC2_To+' ' + ((this.endIndex > this.totalRecountCount) ? this.totalRecountCount : this.endIndex) +' '+ LWC2_Of +' '+ this.totalRecountCount + ' '+LWC2_Records;
        }
        return 'Showing 0 '+ LWC2_Of +' 0';
    }

    //this method displays records page by page
    displayRecordPerPage(page){
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) ? this.totalRecountCount : this.endingRecord; 
        this.data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }    

    handleCancel = event => this.dispatchEvent(new CustomEvent('cancel', { detail: event.detail }));

    handleResize = event => this.dispatchEvent(new CustomEvent('resize', { detail: event.detail }));

    closeModal() {
        this.selectedDocType = null;
        this.selectedDocSubType = null;
        this.wrongFiles = [];
        this.selectedRowId = null;
        this.isModalOpen = false;
        this.isAddFile = false;
        this.isReplaceFile = false;
        this.isDeleteFile = false;
        this.updateRecordView();
        this.fileUploadClass = 'disabledUpload';
    }
 
    updateRecordView() {
       setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
       }, 1000); 
    }
}