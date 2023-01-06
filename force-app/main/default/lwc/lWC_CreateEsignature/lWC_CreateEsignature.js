import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
// Resource
import ConfirmationDialog_CSS from '@salesforce/resourceUrl/ConfirmationDialog_CSS';
// Apex
import createSignature from '@salesforce/apex/LC49_CreateSignature.validateCreateSign';

export default class LWC_CreateEsignature extends NavigationMixin(LightningElement) {
    @api recordId;

    renderedCallback() {
        Promise.all([
            loadStyle( this, ConfirmationDialog_CSS )
        ]).then().catch(error => {
            if(error && error.body)
            console.log( error.body.message );
        });
    }

    connectedCallback() {
        this.createSignature();
    }

    createSignature() {
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if(this.recordId){
                createSignature({ contractId: this.recordId })
                .then(result => {
                    if(result.success){
                        console.log('***0result', result);
                        if(result.esignId){
                            this[NavigationMixin.Navigate]({
                                type:'standard__recordPage',
                                attributes:{
                                    "recordId":result.esignId,
                                    "objectApiName":"eSignature__c",
                                    "actionName": "view"
                                }
                            });
                        }
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Success!',
                            message: result.success,
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.closeModal();
                    }else{
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error!',
                            message: result.error,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.closeModal();
                    }
                });
            }
        }, 0);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}