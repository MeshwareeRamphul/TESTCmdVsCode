import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
// Resource
import ConfirmationDialog_CSS from '@salesforce/resourceUrl/ConfirmationDialog_CSS';
// Apex
import submitESignature from '@salesforce/apex/LC50_ManageEsignature.submitEsignature';

export default class LWC_SubmitEsignature extends NavigationMixin(LightningElement)  {
    @api recordId;
    @track openmodel = true;
    @track isLoading = false;

    renderedCallback() {
        Promise.all([
            loadStyle( this, ConfirmationDialog_CSS )
        ]).then().catch(error => {
            if(error && error.body)
            console.log( error.body.message );
        });
    }

    confirmSubmit() {
        this.isLoading = true;
        submitESignature({ esignId: this.recordId })
        .then(result => {
            if(result.success){
                if(result.contractId){
                    this[NavigationMixin.Navigate]({
                        type:'standard__recordPage',
                        attributes:{
                            "recordId":result.contractId,
                            "objectApiName":"Contract__c",
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
            this.closeModal();
            eval("$A.get('e.force:refreshView').fire();");
        },0);
    }

    closeModal() {
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}