import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
// Resource
import ConfirmationDialog_CSS from '@salesforce/resourceUrl/ConfirmationDialog_CSS';
// Apex
import cancelESignature from '@salesforce/apex/LC13_CancelESignature.cancelESignature';

export default class LWC_CancelEsignature extends LightningElement {
    @api recordId;
    @track isLoading = false;

    renderedCallback() {
        Promise.all([
            loadStyle( this, ConfirmationDialog_CSS )
        ]).then().catch(error => {
            if(error && error.body)
            console.log( error.body.message );
        });
    }

    confirmCancel() {
        this.isLoading = true;
        cancelESignature({ ctrId: this.recordId })
        .then(result => {
            console.log(result);
            if (result.success){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!',
                    message: result.success,
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.refreshPage();
            }else{
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!',
                    message: result.error,
                    variant: 'error',
                    mode: 'sticky'
                }));
            }
            this.closeModal();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!',
                message: error,
                variant: 'error',
                mode: 'sticky'
            }));
            this.closeModal();
        });
    }

    refreshPage(){
        setTimeout(()=>{
            eval("$A.get('e.force:refreshView').fire();"); 
            this.dispatchEvent(new CloseActionScreenEvent());
        },0);
    }
    
    closeModal() {
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}