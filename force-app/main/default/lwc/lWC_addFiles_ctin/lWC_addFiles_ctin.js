import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import contractMessage from '@salesforce/messageChannel/contractMessageChannel__c';

export default class LWC_AddFiles_ctin extends LightningElement {
    @wire(MessageContext) messageContext;

    @api invoke() {
        /*const successToast = new ShowToastEvent({
            title : "Headless Quick Action!",
            message : "Headless Quick Action executed successfully.",
            variant : 'success'
        });
        this.dispatchEvent(successToast);*/
        console.log('******');
        const payload = { action: 'add_Files' };
        publish(this.messageContext, contractMessage, payload);
    }
}