import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
// Apex
import getParticipantDocuments from '@salesforce/apex/LWC2_DocumentToUpload_Sing.getParticipantDocuments';
import replaceDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.replaceDocument';
import deleteDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.deleteDocument';
import updateDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.updateDocument';
import addParticipantDocuments from '@salesforce/apex/LWC2_DocumentToUpload_Sing.addParticipantDocuments';
import getLoginURL from '@salesforce/apex/LWC2_DocumentToUpload_Sing.getLoginURL';
// Resource
import DataTableCSS from '@salesforce/resourceUrl/DataTableCSS';
// Label
import LWC2_SourcingEventDocuments from '@salesforce/label/c.LWC2_SourcingEventDocuments';
import LWC2_Round from '@salesforce/label/c.LWC2_Round';
import LWC2_ChooseType from '@salesforce/label/c.LWC2_ChooseType';
import LWC2_ChooseSharing from '@salesforce/label/c.LWC2_ChooseSharing';
import LWC2_Search from '@salesforce/label/c.LWC2_Search';
import LWC2_DocumentType from '@salesforce/label/c.LWC2_DocumentType';
import LWC2_DocumentName from '@salesforce/label/c.LWC2_DocumentName';
import LWC2_SharingLogic from '@salesforce/label/c.LWC2_SharingLogic';
import LWC2_Participant from '@salesforce/label/c.LWC2_Participant';
import LWC2_Owner from '@salesforce/label/c.LWC2_Owner';
import LWC2_CreatedDate from '@salesforce/label/c.LWC2_CreatedDate';
import LWC2_Of from '@salesforce/label/c.LWC2_Of';
import LWC2_Showing from '@salesforce/label/c.LWC2_Showing';
import LWC2_To from '@salesforce/label/c.LWC2_To';
import LWC2_Records from '@salesforce/label/c.LWC2_Records';
import LWC2_Preview from '@salesforce/label/c.LWC2_Preview';
import LWC2_ReplaceFile from '@salesforce/label/c.LWC2_ReplaceFile';
import LWC2_Download from '@salesforce/label/c.LWC2_Download';
import LWC2_Delete from '@salesforce/label/c.LWC2_Delete';
import LWC2_AttachReceipt from '@salesforce/label/c.LWC2_AttachReceipt';
import LWC2_ContainsSOW from '@salesforce/label/c.LWC2_ContainsSOW';
import LWC2_File from '@salesforce/label/c.LWC2_File';
import LWC03_AddFiles from '@salesforce/label/c.LWC03_AddFiles';
import LWC03_DeleteFile from '@salesforce/label/c.LWC03_DeleteFile';
import LWC03_DeleteConfirmation from '@salesforce/label/c.LWC03_DeleteConfirmation';
import labelCancel from '@salesforce/label/c.labelCancel';
import titleSuccess from '@salesforce/label/c.titleSuccess';
import titleError from '@salesforce/label/c.titleError';
import LWC2_NameUpdated from '@salesforce/label/c.LWC2_NameUpdated';
import LWC2_TheDocument from '@salesforce/label/c.LWC2_TheDocument';
import LWC2_IsDeleted from '@salesforce/label/c.LWC2_IsDeleted';
import LWC2_DeleteDocumentError from '@salesforce/label/c.LWC2_DeleteDocumentError';
import LWC2_SourcingDocumentsCompletedNo from '@salesforce/label/c.LWC2_SourcingDocumentsCompletedNo';
import LWC2_DocumentsCompletedError from '@salesforce/label/c.LWC2_DocumentsCompletedError';
import LWC03_No from '@salesforce/label/c.LWC03_No';
import LWC03_Yes from '@salesforce/label/c.LWC03_Yes';
import TIME_ZONE  from '@salesforce/i18n/timeZone';

const actions = [
    { label: LWC2_Preview, name: 'preview_file' },
    { label: LWC2_Download, name: 'download_file' },
    { label: LWC2_Delete, name: 'delete_file' }
];


const COLUMNS1 = [
    {label:LWC2_DocumentName, fieldName:'docURL', type: 'url', typeAttributes: {label: { fieldName: 'name' }, tooltip: { fieldName: 'name' }}, cellAttributes: { iconName: { fieldName: 'iconName' }, iconPosition: 'left' }},
    /*{label:LWC2_DocumentName, fieldName:'name', type: 'button', typeAttributes: {label: { fieldName: 'name' }, variant:'base'}, cellAttributes: { iconName: { fieldName: 'iconName' }, iconPosition: 'left' }},*/
    {label:LWC2_DocumentType, fieldName:'type', type:'string', initialWidth: 130},
    {label:LWC2_Owner, fieldName:'ownerURL', initialWidth: 130, type: 'url', typeAttributes: {label: { fieldName: 'ownerName' }, tooltip: { fieldName: 'ownerName' }}},
    {label:LWC2_CreatedDate, fieldName:'createdDate', type: 'date', initialWidth: 120, typeAttributes: {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
        timeZone: TIME_ZONE
    }},
    {type: 'action', wrapText: true, typeAttributes: { rowActions: actions }}
];

const imageExtension = ['jpg','png','gif','webp','tiff','psd','raw','bmp','heif','indd','jpeg 2000'];
const docTypes = ['ai','attachment','audio','box_notes','csv','eps','excel','exe','flash','folder','gdoc','gdocs','gform','gpres','gsheet','html','keynote','library_folder','link','mp4','overlay','pack','pages','pdf','ppt','psd','quip_doc','quip_sheet','quip_slide','rtf','slide','stypi','txt','video','visio','webex','word','xml','zip'];

const BASE_DOWNLOAD_PATH = '/sfc/servlet.shepherd/version/download';

export default class LWC_UploadedDocumentPortal_Sing extends NavigationMixin(LightningElement) {
    @api recordId;
    @track error;
    @api sortedDirection = 'asc';
    @api sortedBy = 'Name';
    @track user;
    @track isLoading = false;
    @track isAddFile = false;
    @track isReplaceFile = false;
    @track isDeleteFile = false;
    @track isModalOpen = false;
    @track isRender = false;
    @track columns = COLUMNS1;
    @track selectedRowId;
    @track selectedDocId;
    @track actionName;
    @track selectedDocName;
    @track currentRecordId;
    @track wrongFiles = [];
    @track draftValues = [];
    @track isPreviousDisabled = 'isDisabled';
    @track isNextDisabled = 'isDisabled';
    
    @track disabledBtn = true;
    @track preSelectedRows = [];
    @track mapSelectedRows = {};
    @track mapLatestPublishedVersionId = {};

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
        LWC2_Participant, LWC2_SharingLogic, LWC2_SourcingEventDocuments, LWC2_Round, LWC2_Of, LWC2_ReplaceFile, LWC2_DocumentType, LWC2_DocumentName, LWC2_AttachReceipt, LWC03_AddFiles, LWC2_ChooseType, LWC2_Search, LWC2_ChooseSharing, labelCancel, LWC03_DeleteConfirmation, LWC03_No, LWC03_Yes
    };

    connectedCallback() {
        this.getDocuments();
    }

    renderedCallback() {  
        Promise.all([
            loadStyle( this, DataTableCSS )
            ]).then()
            .catch(error => {
                if(error && error.body)
                console.log( error.body.message );
        });
    }
    
    getBaseUrl(){
        let baseUrl = 'https://'+location.host+'/';
        getLoginURL()
        .then(result => {
            baseUrl = result;
            window.console.log(baseUrl);
        })
        .catch(error => {
            console.error('Error: \n ', error);
        });
        return baseUrl;
    }

    getDocuments(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getParticipantDocuments({ recordId: this.recordId })
                .then(result => {
                    if(result){
                        this.user = result.user;
                        var data = result.data;
                        let baseUrl = this.getBaseUrl();
                        console.log('')
                        data.forEach(doc => {
                            doc.size = this.roundToThree(doc.size/1048576) + ' Mb';
                            if(!doc.hasOwnProperty('name')){
                                doc.name = doc.fileName;
                            }
                            doc.downloadUrl = baseUrl+'sfc/servlet.shepherd/document/download/'+doc.documentId;
                            doc.fileUrl     = baseUrl+'sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+doc.cvId;
                            
                            if(doc.hasOwnProperty('fileType')){
                                if(imageExtension.includes(doc.fileType.toLowerCase())){
                                    doc.iconName = 'doctype:image';
                                }else if(docTypes.includes(doc.fileType.toLowerCase())){
                                    doc.iconName = 'doctype:'+doc.fileType.toLowerCase();
                                }else{
                                    doc.iconName = 'doctype:unknown';
                                }
                            }
                            if(doc.hasOwnProperty('owner')){
                                doc.ownerName = doc.owner.Name;
                                doc.ownerURL = '/supplier/s/detail/'+doc.owner.Id;
                            }
                            doc.rowActions = [
                                { label: LWC2_Preview, name: 'preview_file' },
                                { label: LWC2_Download, name: 'download_file' },
                                { label: LWC2_Delete, name: 'delete_file' }
                            ];
                            console.log('****', JSON.stringify(doc));
                        });

                        // Pagination
                        this.totalRecountCount = data.length; 

                        if(this.totalRecountCount > 0){
                            this.items = data;
                            this.page = 1;
                            this.startFromIndex = 0;
                            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                            this.data = this.items.slice(0,this.pageSize); 
                            this.endingRecord = this.pageSize;
                            this.isRender = true;
                            if(this.totalRecountCount > this.pageSize){
                                this.hidePagination = false;
                                this.isNextDisabled = '';
                            }
                        }
                        this.error = undefined;
                    } else if (error) {
                        this.error = error;
                        this.data = undefined;
                    }
                })
                .catch(error => {
                });
            }
        }, 0);
    }
    
    roundToThree(num) {
        return Math.round((num + Number.EPSILON) * 1000) / 1000;
    }

    openAddfile(){
        this.headerTitle = LWC03_AddFiles;
        this.selectedSharingLogic = 'Specific Vendor';
        this.selectedParticipant = this.recordId;
        this.isModalOpen = true;
        this.isAddFile = true;
        this.selectedDocName = null;
    }

    handleDocumentName(event){
        this.selectedDocName = event.detail.value;
    }

    /*handleSave(event) {
        var data = event.detail.draftValues;
        var lstDocuments = new Array();
        var lstId = new Array();
        for(let i=0; i<data.length; i++){
            var rowId = data[i]['Id-tab'];
            console.log('****',rowId);
            var id = rowId.replace('row-', '');
            var item = this.items[rowId.replace('row-', '')];
            var doc = new Object();
            doc.name = data[i].name;
            doc.documentId = item.documentId;

            lstId.push(id);
            lstDocuments.push(doc);
        }
        
        updateDocument({ lstDocuments: lstDocuments, recordId: this.recordId })
        .then(result => {
            if(result){
                if(typeof result.error === 'undefined'){
                    for(let i=0; i<lstId.length; i++){
                        this.items[lstId[i]].name = data[i].name;
                    }
                    this.draftValues = null;
                    this.template.querySelector("lightning-datatable").draftValues = [];
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleSuccess,
                            message: LWC2_NameUpdated,
                            variant: 'success',
                            mode: 'dismissable'
                        })
                    );
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleError,
                            message: result.error,
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                }
            }
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
        });
    }*/


    handlePreviewFile(event) {
        //console.log('****** ',event.target.dataset.id);
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
        let preSelectedRowsTemp = [];
        if (this.preSelectedRows.length > 0) {
            for (let index = 0; index < this.preSelectedRows.length; index++) {
                preSelectedRowsTemp.push(this.preSelectedRows[index]);
            }
            this.preSelectedRows = preSelectedRowsTemp;
        }

        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) ? this.totalRecountCount : this.endingRecord; 
        this.data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }    
    
    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.result);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        var selectedRow = event.detail.row;
        var documentId = selectedRow.documentId;
console.log('*****');
        this.actionName = action.name;
        this.selectedDocId = documentId;
        this.selectedRowId = selectedRow.Id;
        this.selectedDocType = selectedRow.type;
        this.selectedDocName = selectedRow.name;
        this.selectedSharingLogic = selectedRow.sharingLogic;
        this.selectedParticipant = selectedRow.participant;
        this.selectedFileName = selectedRow.fileName;
        if(this.selectedParticipant){
            this.selectedParticipantId = this.selectedParticipant.Id;
        }else{
            this.selectedParticipantId = null;
        }
        this.selectedRound = selectedRow.round;
        if(this.selectedRound){
            this.selectedRoundId = this.selectedRound.Id;
        }else{
            this.selectedRoundId = null;
        }

        if(this.actionName){
            switch (this.actionName) {
                case 'preview_file':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: selectedRow.fileUrl
                        }
                    }, false );
                break;
                case 'download_file':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: selectedRow.downloadUrl
                        }
                    }, false );
                break;
                case 'replace_file':
                    this.headerTitle = LWC2_ReplaceFile;
                    this.isReplaceFile = true;
                    this.isModalOpen = true;
                    this.selectedDocName = null;
                break;
                case 'delete_file':
                    this.headerTitle = LWC03_DeleteFile;
                    this.isDeleteFile = true;
                    this.isModalOpen = true;
                break;
            }
        }else if(action.label && action.label.fieldName && action.label.fieldName == 'name'){
            this.previewFile(selectedRow);
        }
    }

    previewFile(file){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: file.fileUrl
            }
        }, false );
        
    }

    handleAddFile(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        var lstDoc = new Array();
        this.wrongFiles = new Array();
        this.isLoading = true;
        for(let i = 0; i < uploadedFiles.length; i++) {
            var doc = new Object();
            doc.documentId = uploadedFiles[i].documentId;
            doc.name = this.selectedDocName == null ? uploadedFiles[i].name : this.selectedDocName;
            doc.fileName = uploadedFiles[i].name;
            doc.sharingLogic = this.selectedSharingLogic;
            doc.participantId = this.recordId;
            doc.size = uploadedFiles[i].size;
            doc.optionSharingLogic = this.optionSharingLogic;
            doc.type = 'Participant Document';
            lstDoc.push(doc);
        }

        if(lstDoc.length > 0){
            addParticipantDocuments({ lstUploadedDoc: lstDoc, recordId: this.recordId }).then(result => {
                if(result){
                    var data = result.data;
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
                        this.closeModal();
                        this.getDocuments();
                    }
                    this.isLoading = false;
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: titleError,
                            message: 'An error occured during the process.',
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                    this.isLoading = false;
                }
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
            if(uploadedFile.name.toLowerCase().includes('_sow')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: LWC2_ContainsSOW,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }else{
                doc.Id = this.selectedRowId;
                doc.documentId = uploadedFile.documentId;
                doc.type = this.selectedDocType;
                doc.name = this.selectedDocName;
                doc.fileName = uploadedFile.name;
                doc.sharingLogic = this.selectedSharingLogic;
                doc.roundId = this.selectedRoundId;
                doc.participantId = this.selectedParticipantId;
                doc.docURL = '/supplier/s/detail/' + doc.documentId;
                doc.owner = this.user;
            }
        }
        
        replaceDocument({ newDoc: doc, originDocId: this.selectedDocId,  recordId: this.recordId })
        .then(result => {
            var data = result.data;
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
                //console.log('****data ', JSON.stringify(data));
                if(data){
                    data.size = this.roundToThree(data.size/1048576) + ' Mb';
                    if(data.hasOwnProperty('owner')){
                        data.ownerName = data.owner.Name;
                        data.ownerURL = '/supplier/s/detail/' + data.owner.Id;
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
        var docIds = [];
        docIds.push(this.selectedDocId);
        this.isLoading = true;

        docIds.push(documentId);

        deleteDocument({ documentId: docIds })
        .then(result => {
            if(result.success){
                this.totalRecountCount = this.items.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.displayRecordPerPage(this.page);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleSuccess,
                        message: result.success,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.dispatchEvent(new CustomEvent("valuechange"));
                this.updateRecordView();
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            this.closeModal();
        })
        .catch(error => {
        });
    }

    handleDownloadAllFile(){
        let downloadString = '';
           
        for (let j = 0; j < this.items.length; j++) {
            downloadString += '/' + this.items[j].LatestPublishedVersionId;
        }
        window.open(BASE_DOWNLOAD_PATH + downloadString, '_blank');
    }

    handleDownloadFile(){
        let downloadString = '';
        for (let index = 1; index <= this.totalPage; index++) {
            if (this.mapLatestPublishedVersionId[index] != null) {
                for (let j = 0; j < this.mapLatestPublishedVersionId[index].length; j++) {
                    downloadString += '/' + this.mapLatestPublishedVersionId[index][j];
                }
            }
        }
        window.open(BASE_DOWNLOAD_PATH + downloadString, '_blank');
    }
    
    handleSelect(event){
        var eventDetail = event.detail;
        console.log('eventDetail ', JSON.stringify(eventDetail));
        
        if (this.mapSelectedRows[this.page] == null) {
            this.mapSelectedRows[this.page] = [];
        }
        if (this.mapLatestPublishedVersionId[this.page] == null) {
            this.mapLatestPublishedVersionId[this.page] = [];
        }
        if (eventDetail.config.selection === 'rowSelect' || eventDetail.config.selection === 'selectAllRows') {
            for (let i = 0; i < eventDetail.selectedRows.length; i++) {
                if (this.mapSelectedRows[this.page].includes(eventDetail.selectedRows[i].Id) == false) {
                    this.mapSelectedRows[this.page].push(eventDetail.selectedRows[i].Id);
                }
                if (this.mapLatestPublishedVersionId[this.page].includes(eventDetail.selectedRows[i].LatestPublishedVersionId) == false) {
                    this.mapLatestPublishedVersionId[this.page].push(eventDetail.selectedRows[i].LatestPublishedVersionId);
                }
            }
        }
        else if (eventDetail.config.selection === 'rowDeselect') {
            var id = eventDetail.config.value;
            var index = this.mapSelectedRows[this.page].indexOf(id);
            
            this.mapSelectedRows[this.page].splice(index, 1);
            var LatestPublishedVersionId = '';
            for (let index = 0; index < this.data.length; index++) {
                if (this.data.id == id) {
                    LatestPublishedVersionId = this.data.LatestPublishedVersionId;
                }
            }
            var indexLatestPublishedVersionId = this.mapLatestPublishedVersionId[this.page].indexOf(LatestPublishedVersionId);
            this.mapLatestPublishedVersionId[this.page].splice(indexLatestPublishedVersionId, 1);
        }
        else if (eventDetail.config.selection === 'deselectAllRows') {
            this.mapSelectedRows[this.page] = [];
            this.mapLatestPublishedVersionId[this.page] = [];
        }
        this.preSelectedRows = [];
        for (let index = 1; index <= this.totalPage; index++) {
            if (this.mapSelectedRows[index] != null) {
                for (let j = 0; j < this.mapSelectedRows[index].length; j++) {
                    this.preSelectedRows.push(this.mapSelectedRows[index][j]);
                }
            }
        }
        
        console.log('***preSelectedRows ', JSON.stringify(this.preSelectedRows));
        console.log('***mapLatestPublishedVersionId ', JSON.stringify(this.mapLatestPublishedVersionId));
        if (this.preSelectedRows.length > 0) {
            this.disabledBtn = false;
        } else {
            this.disabledBtn = true;
        }
    }

    handleCancel = event => this.dispatchEvent(new CustomEvent('cancel', { detail: event.detail }));

    handleResize = event => this.dispatchEvent(new CustomEvent('resize', { detail: event.detail }));

    closeModal() {
        this.wrongFiles = [];
        this.selectedRowId = null;
        this.isModalOpen = false;
        this.isAddFile = false;
        this.isReplaceFile = false;
        this.isDeleteFile = false;
        this.isLoading = false;
        this.selectedDocName = null;
    }
 
    updateRecordView() {
       setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
       }, 1000); 
    }
}