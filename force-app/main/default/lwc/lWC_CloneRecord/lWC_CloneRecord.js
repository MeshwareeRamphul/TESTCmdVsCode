import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import fetchRecord from '@salesforce/apex/LWC5_CloneRecord.fetchRecord';

export default class LWC_CloneRecord extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        this.isLoading = true;
        this.navigateToCreateRecord();
    }

    navigateToCreateRecord(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                fetchRecord({ recordId: this.recordId }).then(result => {
                    if(result.error){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error!',
                            message: result.error,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                    }else{
                        var obj = result.record;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__objectPage',
                            attributes: {
                                objectApiName: result.objectAPI,
                                actionName: 'new'
                            },
                            state : {
                                nooverride: '1',
                                recordTypeId: obj.RecordTypeId,
                                defaultFieldValues: encodeDefaultFieldValues(obj)
                            }
                        });
                    }
                }).catch(error => {});
            }
        }, 0);
    }
}