import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import accountMessage from '@salesforce/messageChannel/accountMessageChannel__c';

export default class LWC_AddFiles_Acc extends LightningElement {
    @wire(MessageContext) messageContext;

    @api invoke() {
        const payload = { action: 'add_Files' };
        publish(this.messageContext, accountMessage, payload);
    }
}