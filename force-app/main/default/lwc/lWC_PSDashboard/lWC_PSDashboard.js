import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getURL from '@salesforce/apex/LC17_PSDashboard.getURL';

export default class LWC_PSDashboard extends LightningElement {
    @api recordId;

    closeModal() {
        this.dispatchEvent(new CustomEvent('closeQuickAction'));
    }

    renderedCallback() {
        getURL({ objID: this.recordId })
        .then(result => {
            if (result != ""){
                window.open(result, "_blank");
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'No link available to view the dashboard.',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            this.closeModal();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    //message: 'Error in calling server side action.',
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            this.closeModal();
        });
    }
}