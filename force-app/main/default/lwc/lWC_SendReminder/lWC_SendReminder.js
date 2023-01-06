import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendReminder from '@salesforce/apex/LC15_SendReminder.sendReminder';

export default class LWC_SendReminder extends LightningElement {
    @api recordId;
    @api contractId;

    closeModal() {
        this.dispatchEvent(new CustomEvent('closeQuickAction'));
    }

    renderedCallback() {
        sendReminder({ eSignatoryId: this.recordId })
        .then(result => {
            if(typeof result.error !== 'undefined'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            else if(typeof result.success !== 'undefined'){    
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: result.success,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            }
            if(typeof this.contractId === 'string'){
                this.dispatchEvent(new CustomEvent("valuechange", {detail: { contractId:this.contractId }}));
            }
            this.closeModal();
        })
        .catch(error => {
            //var errorMsg = result.getError()[0].message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            if(typeof this.contractId === 'string'){
                this.dispatchEvent(new CustomEvent("valuechange", {detail: { contractId:this.contractId }}));
            }
            this.closeModal();
        });
    }
}