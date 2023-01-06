import { LightningElement,track,api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setToSendingtoPS from '@salesforce/apex/LC05_SendToPeopleSoft.setToSendingtoPS';
import sendCtrlightoPeopleSoft from '@salesforce/apex/LC05_SendToPeopleSoft.sendCtrlightoPeopleSoft';

export default class LWC_SendToPeopleSoft extends LightningElement {
    @api recordId;
    @track openmodel = true;
    @track loaded = false;

    closeModal() {
        this.openmodel = false;
        if(this.loaded){     
            this.loaded = false;
            const passEvent = new CustomEvent("valuechange", {
                detail: { showSpinner:this.loaded }
            });
            this.dispatchEvent(passEvent);
        }

        this.dispatchEvent(new CustomEvent('closeQuickAction'));
    }

    async sendToPS(){
        this.loaded = true;
        const passEvent = new CustomEvent("valuechange", {
            detail: { showSpinner:this.loaded }
        });
        this.dispatchEvent(passEvent);

        const result = await setToSendingtoPS({ curCtr: this.recordId });
        if(result === ''){
            const result2 = await sendCtrlightoPeopleSoft({ curCtr: this.recordId });
            if (result2 === ''){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Your contract has been sent to People Soft.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.dispatchEvent(new CustomEvent('recordChange'));
                //updateRecord({ fields: { Id: this.recordId } });
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: result2,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
            this.closeModal();
        }else{
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: result,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            this.closeModal();
        }
    }
}