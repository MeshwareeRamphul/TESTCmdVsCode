import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { subscribe,unsubscribe,APPLICATION_SCOPE,MessageContext } from 'lightning/messageService';
import sourcingMessage from '@salesforce/messageChannel/sourcingMessageChannel__c';
// Apex
import getAllDocuments from '@salesforce/apex/LWC2_DocumentToUpload_Sing.getAllDocuments';
import getDocumentType from '@salesforce/apex/LWC2_DocumentToUpload_Sing.getDocumentType';
import replaceDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.replaceDocument';
import deleteDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.deleteDocument';
import updateDocument from '@salesforce/apex/LWC2_DocumentToUpload_Sing.updateDocument';
import addDocuments from '@salesforce/apex/LWC2_DocumentToUpload_Sing.addDocuments';
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
import LWC2_FileName from '@salesforce/label/c.LWC2_FileName';
import LWC2_RelatedRound from '@salesforce/label/c.LWC2_RelatedRound';
import LWC2_SharingLogic from '@salesforce/label/c.LWC2_SharingLogic';
import LWC2_Account from '@salesforce/label/c.LWC2_Account';
import LWC2_Participant from '@salesforce/label/c.LWC2_Participant';
import LWC2_Owner from '@salesforce/label/c.LWC2_Owner';
import LWC2_CreatedDate from '@salesforce/label/c.LWC2_CreatedDate';
import LWC2_Of from '@salesforce/label/c.LWC2_Of';
import LWC2_Showing from '@salesforce/label/c.LWC2_Showing';
import LWC2_To from '@salesforce/label/c.LWC2_To';
import LWC2_Records from '@salesforce/label/c.LWC2_Records';
import LWC2_Preview from '@salesforce/label/c.LWC2_Preview';
import LWC2_ReplaceFile from '@salesforce/label/c.LWC2_ReplaceFile'; 
import LWC2_Delete from '@salesforce/label/c.LWC2_Delete';
import LWC2_AttachReceipt from '@salesforce/label/c.LWC2_AttachReceipt';
import LWC2_ContainsSOW from '@salesforce/label/c.LWC2_ContainsSOW';
import LWC2_NameUpdated from '@salesforce/label/c.LWC2_NameUpdated';
import LWC2_File from '@salesforce/label/c.LWC2_File';
import LWC2_UploadedSuccess from '@salesforce/label/c.LWC2_UploadedSuccess';
import LWC03_AddFiles from '@salesforce/label/c.LWC03_AddFiles';
import LWC03_DeleteFile from '@salesforce/label/c.LWC03_DeleteFile';
import LWC03_DeleteConfirmation from '@salesforce/label/c.LWC03_DeleteConfirmation';
import labelCancel from '@salesforce/label/c.labelCancel';
import titleSuccess from '@salesforce/label/c.titleSuccess';
import titleError from '@salesforce/label/c.titleError';
import LWC2_TheDocument from '@salesforce/label/c.LWC2_TheDocument';
import LWC2_IsDeleted from '@salesforce/label/c.LWC2_IsDeleted';
import LWC2_DeleteDocumentError from '@salesforce/label/c.LWC2_DeleteDocumentError';
import LWC2_SourcingDocumentsCompletedNo from '@salesforce/label/c.LWC2_SourcingDocumentsCompletedNo';
import LWC2_DocumentsCompletedError from '@salesforce/label/c.LWC2_DocumentsCompletedError';
import LWC03_No from '@salesforce/label/c.LWC03_No';
import LWC03_Yes from '@salesforce/label/c.LWC03_Yes';
import LWC03_ReplacedBy from '@salesforce/label/c.LWC03_ReplacedBy';
import LWC03_WithSuccess from '@salesforce/label/c.LWC03_WithSuccess';

const COLUMNS1 = [
    {label:LWC2_DocumentType, fieldName:'type', type:'string', initialWidth: 150},
    {label:LWC2_DocumentName, fieldName:'name', type:'string', editable: true},
    {label:LWC2_FileName, fieldName:'docURL', type: 'url', typeAttributes: {label: { fieldName: 'fileName' }}},
    {label:LWC2_RelatedRound, fieldName:'roundURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'roundName' }}},
    {label:LWC2_SharingLogic, fieldName:'sharingLogic', type:'string'/*, editable: true*/, initialWidth: 200},
    {label:LWC2_Account, fieldName:'accountURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'accountName' }}},
    {label:LWC2_Participant, fieldName:'participantURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'participantName' }}},
    {label:LWC2_Owner, fieldName:'ownerURL', initialWidth: 150, type: 'url', typeAttributes: {label: { fieldName: 'ownerName' }}},
    /*{label:'Size', fieldName:'size', initialWidth: 100, cellAttributes: {alignment: 'center'}},*/
    {label:LWC2_CreatedDate, fieldName:'createdDate', type: 'date', initialWidth: 150, cellAttributes: {alignment: 'center'}, typeAttributes: {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    }},
    {type: 'action', wrapText: true, typeAttributes: { rowActions: {fieldName: 'rowActions'} }, cellAttributes: { class: { fieldName: 'actionClass' }}}
]
const COLUMNS2 = [
    {label:LWC2_DocumentType, fieldName:'type', type:'string', initialWidth: 150},
    {label:LWC2_DocumentName, fieldName:'name', type:'string', editable: true},
    {label:LWC2_FileName, fieldName:'docURL', type: 'url', typeAttributes: {label: { fieldName: 'fileName' }}},
    {label:LWC2_RelatedRound, fieldName:'roundURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'roundName' }}},
    {label:LWC2_SharingLogic, fieldName:'sharingLogic', type:'string'/*, editable: true*/, initialWidth: 200},
    {label:LWC2_Account, fieldName:'accountURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'accountName' }}},
    {label:LWC2_Participant, fieldName:'participantURL', initialWidth: 200, type: 'url', typeAttributes: {label: { fieldName: 'participantName' }}},
    {label:LWC2_Owner, fieldName:'ownerURL', initialWidth: 150, type: 'url', typeAttributes: {label: { fieldName: 'ownerName' }}},
    /*{label:'Size', fieldName:'size', initialWidth: 100, cellAttributes: {alignment: 'center'}},*/
    {label:LWC2_CreatedDate, fieldName:'createdDate', type: 'date', initialWidth: 150, cellAttributes: {alignment: 'center'}, typeAttributes: {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    }}
]

const BASE_DOWNLOAD_PATH = '/sfc/servlet.shepherd/version/download';

export default class LWC_UploadedDocument_Sing extends NavigationMixin(LightningElement) {
    subscription = null;
    @api recordId;
    @track error;
    @api sortedDirection = 'asc';
    @api sortedBy = 'Name';
    @api searchKey = '';
    @track user;
    @api isLoading = false;
    @track isAddFile = false;
    @track isReplaceFile = false;
    @track isDeleteFile = false;
    @track isModalOpen = false;
    @track isRender = false;
    @track isRoundReady = false;
    @track isAttachReceipt = false;
    @track columns = COLUMNS1;
    @track multiple = true;
    @track cancelButton = 'Cancel';
    @track selectedRowId;
    @track selectedDocId;
    @track actionName;
    @track optionDocumentType;
    @track optionSharingLogic;
    @track selectedDocName
    @track selectedDocType;
    @track selectedSharingLogic;
    @track selectedRound;
    @track selectedRoundId;
    @track selectedParticipant;
    @track selectedParticipantId;
    @track isPicklistDisabled = false;
    @track divUpload = 'slds-form-element disabled';
    @track participantClass = 'slds-var-m-top_small slds-var-m-bottom_small disabledParticipant';
    @track countDoc = 1;
    @track currentRound;
    @track roundFields = ['Name', 'Round_Status__c'];
    @track roundDisplayFields = 'Name, Round_Status__c';
    @track roundConditions = [];
    @track participantFields = ['TECH_ParticipantName__c', 'Name', 'TECH_AccountName__c'];
    @track participantDisplayFields = 'TECH_ParticipantName__c, Name, TECH_AccountName__c';
    @track participantConditions = ['TECH_ParticipantName__c', 'TECH_AccountName__c','Negotiation_Round__c'];
    @track currentObject;
    @track currentRecordId;
    @track wrongFiles = [];
    @track draftValues = [];
    @track isPreviousDisabled = 'isDisabled';
    @track isNextDisabled = 'isDisabled';
    @track requiredParticipant = false;
    result;
    @track disabledBtn = true;
    
    @track page = 1; 
    @track preSelectedRows = [];
    @track mapSelectedRows = {};
    @track mapLatestPublishedVersionId = {};
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

    @wire(MessageContext) messageContext;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                sourcingMessage,
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

    connectedCallback() {
        this.getDocuments();
        this.subscribeToMessageChannel();
    }
    
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
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

    getDocuments(){
        var profilePStakeHolder = 'cTin - Stakeholder / Legal / Audit';

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getAllDocuments({ recordId: this.recordId })
                .then(result => {
                    if(result){
                        this.user = result.user;
                        var data = result.data;
                        // Not display action column for profile PStakeHolder
                        if(this.user.cTin_Profile__c == profilePStakeHolder ){
                            this.columns = COLUMNS2;
                        }

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
                            if(doc.hasOwnProperty('round')){
                                doc.roundName = doc.round.Name;
                                doc.roundURL = '/lightning/r/' + doc.round.Id +'/view';
                            }
                            if(doc.hasOwnProperty('participant')){
                                doc.participantName = doc.participant.TECH_ParticipantName__c;
                                doc.participantURL = '/lightning/r/' + doc.participant.Id +'/view';
                                doc.accountName = doc.participant.TECH_AccountName__c;
                                doc.accountURL = '/lightning/r/' + doc.participant.Sing_Account__c +'/view';
                            }
                        });

                        // Pagination
                        this.totalRecountCount = data.length; 

                        if(this.totalRecountCount > 0){
                            this.items = data;
                            this.page = 1;
                            this.pageSize = 5;
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
        this.type = '';
        this.isLoading = true;
        this.optionDocumentType = [];
        this.currentRecordId = this.recordId;
        this.isModalOpen = true;
        this.isAddFile = true;
        this.isAttachReceipt = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getDocumentType({ recordId: this.recordId })
                .then(result => {
                    this.optionDocumentType = result.document;
                    this.currentObject = result.currentObject;
                    if(result.currentRound){
                        this.currentRound = result.currentRound;
                        //this.selectedRound = this.currentRound;
                    }
                    this.isRoundReady = true;
                    this.isLoading = false;
                })
                .catch(error => {
                });
            }
        }, 300);
    }

    handleOnSelect(event){
        switch (event.detail.value) {
            case 'add_files':
                this.openAddfile();
            break;
        }
    }

    handleDocumentType(event){
        this.selectedDocType = event.detail.value;
        this.divUpload = 'slds-form-element';
        this.fileUploadClass = 'enabledUpload';
        this.requiredParticipant = false;
        // Set Sharing logic list
        this.optionSharingLogic = null;
        if(this.selectedDocType == 'RFX Requirements' || this.selectedDocType == 'Contract Templates'){
            this.optionSharingLogic = [{'label' : 'All Vendors', 'value' : 'All Vendors'}];
        }else if(this.selectedDocType == 'Management Summary' || this.selectedDocType == 'Other Document Internal' || this.selectedDocType == 'RFX Results'){
            this.optionSharingLogic = [{'label' : 'AXA Internal', 'value' : 'AXA Internal'}];
        }else if(this.selectedDocType == 'Other Document External'){
            this.optionSharingLogic = [{'label' : 'All Vendors', 'value' : 'All Vendors'},
            {'label' : 'Specific Vendor', 'value' : 'Specific Vendor'}];
        }else if(this.selectedDocType == 'NDA Signed'){
            this.optionSharingLogic = [{'label' : 'Specific Vendor', 'value' : 'Specific Vendor'}];
        }

        // Set default Sharing Logic
        if(this.optionSharingLogic){
            this.selectedSharingLogic = this.optionSharingLogic[0].value;
        }else{
            this.selectedSharingLogic = null;
        }

        // Disable Participant when SharingLogic is Specific Vendor
        if(this.selectedSharingLogic == 'Specific Vendor'){
            this.participantClass = 'slds-m-top_small slds-m-bottom_small';
            this.requiredParticipant = true;
            if(typeof this.selectedParticipant == 'undefined' || this.selectedParticipant == null){
                //this.divUpload = 'slds-form-element disabled';
                this.fileUploadClass = 'disabledUpload';
            }
        }else{
            this.participantClass = 'slds-m-top_small slds-m-bottom_small disabledParticipant';
        }
    }

    handleDocumentName(event){
        this.selectedDocName = event.detail.value;
    }

    handleSharingLogic(event){
        this.selectedSharingLogic = event.detail.value;
        //this.divUpload = 'slds-form-element';
        if(this.selectedSharingLogic == 'Specific Vendor'){
            this.requiredParticipant = true;
            this.participantClass = 'slds-m-top_small slds-m-bottom_small';
            if(this.selectedParticipant == null){
                //this.divUpload = 'slds-form-element disabled';
                this.fileUploadClass = 'enabledUpload';
            }
        }else{
            this.requiredParticipant = false;
            this.participantClass = 'slds-m-top_small slds-m-bottom_small disabledParticipant';
        }
    }
    
    handleRoundLookup(event){
        //console.log( JSON.stringify ( event.detail) );
        if(typeof event.detail.data == 'undefined'){
            this.selectedRound = null;
        }else if(typeof event.detail.data.recordId != 'undefined'){
            this.selectedRound = event.detail.data.recordId;
        }else if(typeof event.detail.data.record != 'undefined'){
            this.selectedRound = event.detail.data.record.Id;
        }
        console.log('0*******this.selectedRound ',this.selectedRound);
    }

    handleParticipantLookup(event){
        var participant = event.detail.data;
        this.isAttachReceipt = false;
        if(typeof participant == 'undefined'){
            this.selectedParticipant = null;
            this.divUpload = 'slds-form-element disabled';
            this.fileUploadClass = 'disabledUpload';
        }else{
            this.selectedParticipant = participant.recordId;
            this.divUpload = 'slds-form-element';
            this.fileUploadClass = 'enabledUpload';
        }
        this.isAttachReceipt = true;
    }

    handleSave(event) {
        var data = event.detail.draftValues;
        //console.log('*** ', data);
        var lstDocuments = new Array();
        var lstId = new Array();
        for(let i=0; i<data.length; i++){
            console.log('*** ',JSON.stringify(data[i]));
            var doc = new Object();
            doc.name = data[i].name;
            doc.documentId = data[i].Id;

            lstId.push(doc.documentId);
            lstDocuments.push(doc);
        }
        
        updateDocument({ lstDocuments: lstDocuments, recordId: this.recordId })
        .then(result => {
            if(result){
                if(result.data){
                    var data = result.data;
                    for(let i=0; i<lstId.length; i++){
                        for(let j=0; j<data.length; j++){
                            if(lstId[i] == data[j].Id)
                            this.items[i].name = data[j].name;
                        }
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
    }


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
  
    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.result);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        var selectedRow = event.detail.row;
        var documentId = selectedRow.documentId;

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
        this.wrongFiles = new Array();
        this.isLoading = true;
        var uploadedFile;
        for(let i = 0; i < uploadedFiles.length; i++) {
            uploadedFile = uploadedFiles[i];
            if(uploadedFile.name.toLowerCase().includes('_sow')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleError,
                        message: LWC2_ContainsSOW,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                this.wrongFiles.push(uploadedFile);
                this.fileDetailClass = 'errorFile';
                this.isLoading = false;
                break;
            }else{
                var doc = new Object();
                doc.documentId = uploadedFile.documentId;
                doc.type = this.selectedDocType;
                doc.name = this.selectedDocName;
                doc.fileName = uploadedFile.name;
                doc.sharingLogic = this.selectedSharingLogic;
                if(this.selectedSharingLogic != 'Specific Vendor'){
                    this.selectedParticipant = null;
                }
                console.log('*******this.selectedRound ',this.selectedRound);
                doc.roundId = this.selectedRound;
                doc.participantId = this.selectedParticipant;
                doc.size = uploadedFile.size;
                doc.optionSharingLogic = this.optionSharingLogic;

                lstDoc.push(doc);
            }
        }

        if(lstDoc.length > 0){
            addDocuments({ lstUploadedDoc: lstDoc, recordId: this.recordId }).then(result => {
                if(result){
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
                        this.isLoading = false;
                    }else if(result.data){   
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: titleSuccess,
                                message: LWC2_File + ' ' + uploadedFile.name + ' ' + LWC2_UploadedSuccess,
                                variant: 'success',
                                mode: 'dismissable'
                            })
                        );
                        this.closeModal();
                        this.getDocuments();
                    }
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
            doc.Id = this.selectedRowId;
            doc.documentId = uploadedFile.documentId;
            doc.type = this.selectedDocType;
            doc.name = this.selectedDocName;
            doc.fileName = uploadedFile.name;
            doc.sharingLogic = this.selectedSharingLogic;
            doc.roundId = this.selectedRoundId;
            doc.participantId = this.selectedParticipantId;
            doc.docURL = '/lightning/r/' + doc.documentId +'/view';
            doc.owner = this.user;
        }
        
        replaceDocument({ newDoc: doc, originDocId: this.selectedDocId,  recordId: this.recordId })
        .then(result => {
            console.log('*******result ', JSON.stringify(result));
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
                console.log('****data ', JSON.stringify(data));
                if(data){
                    data.rowActions = [
                        { label: LWC2_Preview, name: 'preview_file' },
                        { label: LWC2_ReplaceFile, name: 'replace_file' },
                        { label: LWC2_Delete, name: 'delete_file' }
                    ];
                    if(data.hasOwnProperty('size')){
                        data.size = this.roundToThree(data.size/1048576) + ' Mb';
                    }
                    data.actionClass = 'slds-visible';
                    if(data.hasOwnProperty('owner')){
                        data.ownerName = data.owner.Name;
                        data.ownerURL = '/lightning/r/' + data.owner.Id +'/view';
                    }
                    if(data.hasOwnProperty('round')){
                        data.roundName = data.round.Name;
                        data.roundURL = '/lightning/r/' + data.round.Id +'/view';
                    }
                    if(data.hasOwnProperty('participant')){
                        data.participantName = data.participant.TECH_ParticipantName__c;
                        data.participantURL = '/lightning/r/' + data.participant.Id +'/view';
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
                    //this.displayRecordPerPage(this.page);

                    this.getDocuments();
                    this.closeModal();
                }
            }
            this.isLoading = false;
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: titleError,
                    message: error,
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

        docIds.push(documentId);

        deleteDocument({ documentId: docIds })
        .then(result => {
            if(result.success){
                this.items = this.items.filter(function(doc) { return doc.documentId !== documentId });
                this.totalRecountCount = this.items.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.displayRecordPerPage(this.page);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleSuccess,
                        message: LWC2_TheDocument+' "'+ fileName +'" '+LWC2_IsDeleted ,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.dispatchEvent(new CustomEvent("valuechange"));
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
            this.isLoading = false;
        });
    }

    handleCancel = event => this.dispatchEvent(new CustomEvent('cancel', { detail: event.detail }));

    handleResize = event => this.dispatchEvent(new CustomEvent('resize', { detail: event.detail }));

    closeModal() {
        this.wrongFiles = [];
        this.selectedDocType = null;
        this.selectedRowId = null;
        this.selectedDocName = null;
        this.isRoundReady = false;
        this.isModalOpen = false;
        this.isAddFile = false;
        this.isReplaceFile = false;
        this.isDeleteFile = false;
        this.isLoading = false;
        this.updateRecordView();
    }

    handleRefreshTable(){
        this.preSelectedRows = [];
        for (let index = 1; index <= this.totalPage; index++) {
            this.mapSelectedRows[index] = [];
            this.mapLatestPublishedVersionId[index] = [];
        }
        this.disabledBtn = true;
        this.getDocuments();
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

        if (this.preSelectedRows.length > 0) {
            this.disabledBtn = false;
        } else {
            this.disabledBtn = true;
        }
    }
 
    updateRecordView() {
       setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
       }, 1000); 
    }
}