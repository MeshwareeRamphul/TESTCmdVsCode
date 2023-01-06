import { getRecord } from 'lightning/uiRecordApi';
import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import UserNameFld from '@salesforce/schema/User.Name';
import userEmailFld from '@salesforce/schema/User.Email';
import userIsActiveFld from '@salesforce/schema/User.IsActive';
import userAliasFld from '@salesforce/schema/User.Alias';
import DataTableCSS from '@salesforce/resourceUrl/DataTableCSS';
import getEsignatory from '@salesforce/apex/LWC3_eSignatureFollowUp.getEsignatory';
import sendReminder from '@salesforce/apex/LC15_SendReminder.sendReminder';

const COLUMNS = [
    {label:'eSignatory Role', fieldName:'Role', initialWidth: 200},
    {label:'Name', fieldName:'viewURL', type: 'url', typeAttributes: {label: { fieldName: 'Name' }}},
    {label:'Status', fieldName:'Status__c', initialWidth: 120, cellAttributes: {alignment: 'center', class: { fieldName: 'statusClass' }}},
    {label: 'Date/Time', fieldName: 'SignedDate__c', type: 'date', initialWidth: 200, cellAttributes: {alignment: 'center'}, typeAttributes: {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit"
    }}
]

export default class LWC_EsignatureFollowUp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track renderedTable = false;
    @track isSigner = false;
    @track isValidator = false;
    @track isNotSigner = false;
    @track lstEsignatory=[];
    @track contract;
    @track esignature;
    @track readyEsignatory;
    @track signURL;
    @track disabled = false;
    @track columns = COLUMNS;

    @wire(getRecord, { recordId: Id, fields: [UserNameFld, userEmailFld, userIsActiveFld, userAliasFld ]}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.currentUserEmailId = data.fields.Email.value;
            this.currentIsActive = data.fields.IsActive.value;
            this.currentUserAlias = data.fields.Alias.value;
        } else if (error) {
            this.error = error ;
        }
    }

    connectedCallback() {
        this.getEsignatories();
    }

    renderedCallback() {  
        Promise.all([
            loadStyle( this, DataTableCSS )
            ]).then(() => {
                console.log( 'Files loaded' );
            })
            .catch(error => {
                console.log( error.body.message );
        });
    }

    getEsignatories(){

        this.lstDocument = new Array();
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getEsignatory({ recordId: this.recordId })
                .then(result => {
                    var lstEsign = result.esignatory;
                    this.contract = result.contract;
                    this.esignature = result.esignature;
                    if(lstEsign){
                        lstEsign.forEach(esignatory => {
                            if(esignatory.hasOwnProperty('Tech_Role__c')){
                                if(esignatory.Tech_Role__c == 'Validator'){
                                    esignatory.Role = 'Validator ' + esignatory.Order__c;
                                }else if(this.contract.AXA_GS_Signed_By__c && esignatory.Name == this.contract.AXA_GS_Signed_By__r.Name){
                                    esignatory.Role = 'AXA GO Signed By 1';
                                }else if(this.contract.AXA_GO_Signed_By_2__c && esignatory.Name == this.contract.AXA_GO_Signed_By_2__r.Name){
                                    esignatory.Role = 'AXA GO Signed By 2';
                                }else if(this.contract.CustomerSignedBy__c && esignatory.Name == this.contract.CustomerSignedBy__r.Name){
                                    esignatory.Role = 'Customer Signed By 1';
                                }else if(this.contract.CustomerSignedBy2__c && esignatory.Name == this.contract.CustomerSignedBy2__r.Name){
                                    esignatory.Role = 'Customer Signed By 2';
                                }
                            }

                            if(esignatory.hasOwnProperty('Status__c')){
                                if(esignatory.Status__c == 'Signed' || esignatory.Status__c == 'Validated'){
                                    esignatory.statusClass = 'greenText';
                                }else {
                                    esignatory.statusClass = 'orangeText';
                                    if(esignatory.Status__c == 'Ready'){
                                        this.readyEsignatory = esignatory.Id;
                                        esignatory.SignedDate__c = this.contract.PendingSince__c;
                                        //esignatory.statusClass = 'redText';
                                        if(esignatory.hasOwnProperty('Contact__r') && esignatory.Contact__r.Email == this.currentUserEmailId){
                                            if(esignatory.hasOwnProperty('cTin_Role__c')){
                                                this.signURL = esignatory.SignURL__c;
                                                if(esignatory.cTin_Role__c == 'Signer'){
                                                    this.isSigner = true;
                                                }else if(esignatory.cTin_Role__c == 'Validator'){
                                                    this.isValidator = true;
                                                }
                                            }
                                        }else{
                                            this.isNotSigner = true;
                                        }
                                    }
                                }
                            }
                            
                            esignatory.viewURL = '/lightning/r/' + esignatory.Id +'/view';
                        });
                        this.lstEsignatory = lstEsign;
                        this.renderedTable = true;
                    }
                })
                .catch(error => {
                });
            }
        }, 0);
    }

    viewDetails() {
        //this.dispatchEvent(new CustomEvent("valuechange", {detail: { esignId:this.esignature.Id }}));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.esignature.Id,
                objectApiName: 'eSignature__c',
                actionName: 'view'
            }
        });
    }

    goToSign() {
        window.open(this.signURL, "_blank");
    }

    sendReminderEmail() {
        this.disabled = true;
        sendReminder({ eSignatoryId: this.readyEsignatory })
        .then(result => {
            if(typeof result.success !== 'undefined'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: result.success,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            }else if(typeof result.error !== 'undefined'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            this.disabled = false;   
        })
        .catch(error => {
            this.disabled = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });
    }

    closeModal() {
        if(this.loaded){     
            this.loaded = false;
            this.dispatchEvent(new CustomEvent("valuechange", {detail: { showSpinner:this.loaded }}));
        }
        this.dispatchEvent(new CustomEvent('closeQuickAction'));
    }
}