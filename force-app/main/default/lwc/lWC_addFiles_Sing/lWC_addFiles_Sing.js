import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import sourcingMessage from '@salesforce/messageChannel/sourcingMessageChannel__c';

export default class LWC_addFiles_Sing extends LightningElement {
    @wire(MessageContext) messageContext;

    @api invoke() {
        const payload = { action: 'add_Files' };
        publish(this.messageContext, sourcingMessage, payload);
    }
}