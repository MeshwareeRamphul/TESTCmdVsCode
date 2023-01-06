import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import launchParticipation from '@salesforce/apex/AP01_Sing_UpdateBidDueDateOnSourcing.launchParticipation';
import titleSuccess from '@salesforce/label/c.titleSuccess';
import titleError from '@salesforce/label/c.titleError';

export default class LWC_ParticipationConfirmation_Sing extends LightningElement {
    @api recordId;

    closeModal() {
        this.dispatchEvent(new CustomEvent('closeQuickAction'));
    }

    renderedCallback() {
        launchParticipation({ objID: this.recordId })
        .then(result => {
            if (result.success){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: titleSuccess,
                        message: result.success,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            }
            else{
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
            this.dispatchEvent(
                new ShowToastEvent({
                    title: titleError,
                    message: error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            this.closeModal();
        });
    }
}