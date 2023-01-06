import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// Apex
import getAllSignatories from '@salesforce/apex/LC50_ManageEsignature.getAllSignatories';
import saveChanges from '@salesforce/apex/LC50_ManageEsignature.saveChanges';
// Resource
import EditSignature_CSS from '@salesforce/resourceUrl/EditSignature_CSS';

const COLUMNS = [
    {label:'Order', fieldName:'Order__c', type: 'string', initialWidth: 80, cellAttributes: {alignment: 'center'}},
    {label:'Esignatory name', fieldName:'EsignatoryURL', type: 'url', initialWidth: 200, typeAttributes: {disabled: { fieldName: 'disabled' },label: { fieldName: 'Name' },target: '_blank'}},
    {label:'Entity name', fieldName:'EntityURL', type: 'url', initialWidth: 200, typeAttributes: {label: { fieldName: 'EntityName' },target: '_blank'}},
    {label:'Role', fieldName:'cTin_Role__c', type: 'string', initialWidth: 100},
    {label:'Code', fieldName:'Code', type: 'string', initialWidth: 100},
    {label:'Email', fieldName:'EmailTxt__c', type: 'email', initialWidth: 250},
    {label:'Phone', fieldName:'MobileTxt__c', type: 'string', initialWidth: 130},
    {type: 'button-icon', typeAttributes:{iconName: 'utility:arrowdown',name: 'arrowdown', title:'Move down',variant:'bare',size: 'x-small',class: { fieldName: 'arrowdownClass' }}},
    {type: 'button-icon', typeAttributes:{iconName: 'utility:arrowup',name: 'arrowup', title:'Move up',variant:'bare',size: 'x-small',class: { fieldName: 'arrowupClass' }}},
    {type: 'button-icon', fieldName:'iconAction', typeAttributes:{iconName: { fieldName: 'iconName' }, title:{ fieldName: 'iconTitle' },variant:'bare',size: 'x-small',class: { fieldName: 'iconClass' }}}/*,
    /*{type: 'button-icon', fieldName:'editEsignatory', typeAttributes:{iconName: 'utility:edit',name: 'editEsignatory',variant:'bare',size: 'x-small',class: { fieldName: 'editClass' }}},
    {type: 'button-icon', fieldName:'deleteValidator', typeAttributes:{iconName: 'utility:delete',name: 'deleteValidator',variant:'bare',size: 'x-small',class: { fieldName: 'deleteClass' }}}*/
];

export default class LWC_EditSignature extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isLoading = false;
    @api isSaving = false;
    @track isRendered = false;
    @track isAddValidator = false;
    @track isValidChange = false
    @track isEditSignatory = false
    @track isValSelected = false;
    @track isEdited = false;
    @track columns = COLUMNS;
    @track data  = new Array();
    @track dragStart;
    @track contactFields = ['Name', 'Email', 'AccountId', 'EntityName__c'];
    @track contactDisplayFields = 'Name, EntityName__c';
    @track contactConditions = ['Name','Email','Active__c','RecordTypeId'];
    @track selectedContact;
    @track selectedType;
    @track validatorType;
    @track validatorEmail;
    @track validatorEntity;
    @track rejectedEmails  = new Array();
    @track signatoryName;
    @track signatoryEntity;
    @track signatoryPhone;
    @track signatoryEmail;
    @track signatoryRole;
    @track selectedSignatory;
    @track isRequiredPhone = false;
    @track invalidPhoneMessage = 'Please enter a valid phone number (+, Country code, Number => Eg: +331234567890)';

    get typeOptions() {
        return [{ label: 'AXA', value: 'axa' },{ label: 'Customer', value: 'customer' }];
    }
    get codeOptions() {
        return [{ label: 'SMS', value: 'sms' },{ label: 'Email', value: 'email' }];
    }

    connectedCallback() {
        this.isLoading = true;
        this.getAllData();
    }

    renderedCallback() {
        Promise.all([
            loadStyle( this, EditSignature_CSS )
        ]).then().catch(error => {
            if(error && error.body)
            console.log( error.body.message );
        });
    }

    getAllData(){
        this.type = '';
        this.validatorType  = new Array();
        this.optionDocumentType  = new Array();
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getAllSignatories({ recordId: this.recordId }).then(result => {
                    if(result.data){
                        // format data to be displayed
                        this.dataSetting(result.data);
                    }
                    this.isLoading = false;
                    this.isRendered = true;
                }).catch(error => {});
            }
        }, 0);
    }

    addValidator() {
        this.isRendered = false;
        this.isAddValidator = true;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        this.selectedSignatory = event.detail.row;
        var rowIndex = this.selectedSignatory.Order__c - 1;
        var iconName = action.name;
        var esignContact = this.selectedSignatory.Contact__c;
        iconName = (iconName == 'arrowup' || iconName =='arrowdown' ? iconName : this.selectedSignatory.iconAction);
        switch (iconName) {
            case 'arrowup':
                var temp = new Object();
                temp = this.data[rowIndex];
                this.data[rowIndex] = this.data[rowIndex - 1];
                this.data[rowIndex - 1] = temp;
                this.isEdited = true;
            break;
            case 'arrowdown':
                var temp = new Object();
                temp = this.data[rowIndex];
                this.data[rowIndex] = this.data[rowIndex + 1];
                this.data[rowIndex + 1] = temp;
                this.isEdited = true;
            break;
            case 'edit':
                this.signatoryName = this.selectedSignatory.Name;
                this.signatoryEntity = this.selectedSignatory.EntityName;
                this.signatoryCode = this.selectedSignatory.Code__c;
                this.signatoryPhone = this.selectedSignatory.MobileTxt__c;
                this.signatoryEmail = this.selectedSignatory.EmailTxt__c;
                this.signatoryRole = this.selectedSignatory.cTin_Role__c;
                this.isRequiredPhone = this.signatoryCode == 'sms' ? true : false;
                this.isRendered = false;
                this.isEditSignatory = true;
            break;
            case 'delete':
                this.data = this.data.filter(function(esign) { return esign.Contact__c !== esignContact });
                this.isEdited = true;
            break;
        }
        // format data to be displayed
        this.dataSetting(this.data);
    }

    handleContactLookup(event){
        if(typeof event.detail.data == 'undefined'){
            this.selectedContact = null;
            this.validatorEntity = null;
            this.validatorEmail = null;
            this.isValSelected = false;
        }else{
            this.selectedContact = event.detail.data.record;
            this.validatorEntity = event.detail.data.record.EntityName__c;
            this.validatorEmail = event.detail.data.record.Email;
            if(this.selectedType){
                this.isValSelected = true;
            }
        }
    }

    handleTypeChange(event){
        this.selectedType = event.detail.value;
        this.isValSelected = this.selectedContact ? true : false;
    }

    handleCodeChange(event){
        this.signatoryCode = event.detail.value;
        this.isRequiredPhone = this.signatoryCode == 'sms' ? true : false;
        this.fieldsValidation();
    }

    handleEmailChange(event) {
        this.signatoryEmail = event.detail.value;
        console.log('***** ',this.signatoryEmail);
        this.fieldsValidation();
    }

    handlePhoneChange(event){
        this.signatoryPhone = event.detail.value;        
        this.fieldsValidation();
    }

    fieldsValidation(){
        this.isValidChange = false;
        if(this.signatoryCode && this.isEmailValid() && this.isPhoneValid()){
            this.isValidChange = true;
        }
    }

    isEmailValid(){
        var isValid = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let email = this.template.querySelector('[data-id="txtEmailAddress"]');
        let emailVal = email.value;
        if (emailVal.match(emailRegex)) {
            email.setCustomValidity('');
        } else {
            isValid = false;
            email.setCustomValidity('Please enter a valid email');
        }
        email.reportValidity();
        return isValid;
    }

    isPhoneValid() {
        let isValid = true;
        const phoneRegex = /^\+[0-9]{1,3} ?[0-9]{9,10}$/;
        let phone = this.template.querySelector('[data-id="txtPhoneNumber"]');
        phone.reportValidity();
        let phoneVal = phone.value;
        if((this.isRequiredPhone && !this.signatoryPhone) || (this.signatoryPhone && !phoneVal.match(phoneRegex))){
            isValid = false;
            phone.setCustomValidity('Please enter a valid number with Country code (Eg: +33.......)');
        }else{
            phone.setCustomValidity('');
        }
        phone.reportValidity();
        return isValid;
    }

    handleAddValidator(){
        var validator = new Object();
        validator.Code__c = 'email';
        validator.Order__c = 0;
        validator.Name = this.selectedContact.Name;
        validator.EntityName__c = this.selectedContact.AccountId;
        validator.EntityName = this.selectedContact.EntityName__c;
        validator.cTin_Role__c = 'Validator';
        validator.EmailTxt__c = this.selectedContact.Email;
        validator.Contact__c = this.selectedContact.Id;
        validator.EsignatoryType__c = this.selectedType;
        this.data.unshift(validator);
        // format data to be displayed
        this.dataSetting(this.data);
        this.isEdited = true;
        this.handleCancelValidator();
    }

    handleSaveSignatory(){
        this.data = this.data.map(esign => {
            if (esign.Order__c == this.selectedSignatory.Order__c) {
                return {...esign, Code__c : this.signatoryCode, MobileTxt__c: this.signatoryPhone, EmailTxt__c: this.signatoryEmail};
            }
            return esign;
        });
        this.dataSetting(this.data);
        this.isEdited = true;
        this.handleCancelEdit();
    }

    handleCancelValidator(){
        this.selectedContact = null;
        this.selectedType = null;
        this.validatorEntity = null;
        this.validatorEmail = null;
        this.isValSelected = false;
        this.isAddValidator = false;
        this.isRendered = true;
    }

    handleCancelEdit(){
        this.signatoryName = null;
        this.signatoryEntity = null;
        this.signatoryRole = null;
        this.signatoryEmail = null;
        this.signatoryPhone = null;
        this.signatoryCode = null;
        this.isRequiredPhone = false;
        this.isValidChange = false;
        this.isEditSignatory = false;
        this.isRendered = true;
    }
    
    handleSave(){
        this.isSaving = true;
        saveChanges({ eSignatureId: this.recordId, lstEsignatories: this.data })
        .then(result => {
            if(result){
                if(result.success){  
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success!',
                        message: result.success,
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                    this.refreshPage();
                }else{
                    this.dispatchEvent(new ShowToastEvent({
                        title: titleError,
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.isSaving = false;
                }
            }else{
                this.dispatchEvent(new ShowToastEvent({
                    title: titleError,
                    message: 'An error occured during the process.',
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.isSaving = false;
            }
        })
        .catch(error => {
        });
    }
    
    dataSetting(data){
        var isValidator = false;
        var nbrValidator = 0;
        var nbrSigner = 0;
        var order = 1;
        this.data  = new Array();
        this.rejectedEmails  = new Array();
        if(data){
            data.forEach(esign => {
                esign.Order__c = order++;
                if(esign.Id){
                    esign.EsignatoryURL = '/lightning/r/' + esign.Id +'/view';
                    esign.disabled = true;
                }else{
                    esign.EsignatoryURL = '/lightning/r/#/view';
                }
                esign.EntityURL = '/lightning/r/' + esign.EntityName__c +'/view';
                esign.EntityName = esign.EntityName__r ? esign.EntityName__r.Name : ((esign.EntityName) ? esign.EntityName : null);
                if(esign.cTin_Role__c == 'Validator'){
                    nbrValidator ++;
                    esign.iconName = 'utility:delete';
                    esign.iconAction = 'delete';
                    esign.iconTitle = 'Delete';
                    esign.iconClass = 'slds-visible';
                    isValidator = true;
                }else{
                    nbrSigner ++;
                    esign.iconName = 'utility:edit';
                    esign.iconAction = 'edit';
                    esign.iconClass = 'slds-visible';
                    esign.iconTitle = 'Edit';
                }

                esign.Code = esign.Code__c == 'email' ? 'Email': 'SMS';
                this.rejectedEmails.push(esign.EmailTxt__c);
            });

            // Display arrows (up/down) on each row
            data.forEach(esign => {
                if(esign.cTin_Role__c == 'Validator'){
                    esign.arrowupClass = (esign.Order__c == 1) ? 'slds-hide' : 'slds-visible';
                    esign.arrowdownClass = (nbrValidator == esign.Order__c) ? 'slds-hide' : 'slds-visible';
                }else{
                    esign.arrowupClass = (nbrValidator+1 == esign.Order__c) ? 'slds-hide': 'slds-visible';
                    esign.arrowdownClass = (nbrValidator+nbrSigner == esign.Order__c) ? 'slds-hide': 'slds-visible';
                }
                this.data.push(esign);
            });
        }
    }
    
    closeModal() {
        this.isRendered = false;
        this.isSaving = false;
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    refreshPage(){
        setTimeout(()=>{
            eval("$A.get('e.force:refreshView').fire();"); 
            this.dispatchEvent(new CloseActionScreenEvent());
        },0);
    }
}