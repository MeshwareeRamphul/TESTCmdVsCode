import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
// Apex
import getAllData from '@salesforce/apex/LC03_GenerateInvoicingLines.getAllData';
import generateInvoicingLines from '@salesforce/apex/LC03_GenerateInvoicingLines.generateInvoicingLines';
// Resource
import GenerateIL_CSS from '@salesforce/resourceUrl/GenerateIL_CSS';

const COLUMNS1 = [
    {label:'Activity Code', fieldName:'ActivityCodeURL', type: 'url', initialWidth: 300, typeAttributes: {disabled: { fieldName: 'disabled' },label: { fieldName: 'ActivityCodeName' },target: '_blank'}},
    {label:'Amount', fieldName:'Amount', type: 'Currency', initialWidth: 252, typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 2 }},
    {type: 'button-icon', typeAttributes:{iconName: 'utility:edit',name: 'editLine', title:'Edit',variant:'bare',size: 'x-small'}},
    {type: 'button-icon', typeAttributes:{iconName: 'utility:delete',name: 'deleteLine', title:'Delete',variant:'bare',size: 'x-small'}}
];
const COLUMNS2 = [
    {label:'Activity Code', fieldName:'ActivityCodeURL', type: 'url', typeAttributes: {disabled: { fieldName: 'disabled' },label: { fieldName: 'ActivityCodeName' },target: '_blank'}},
    {label:'Amount', fieldName:'Amount', type: 'Currency', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 2 }}
];

export default class LWC_GenerateInvoicingLines extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track isSaving = false;
    @track isAddLine = false;
    @track isEditLine = false;
    @track isFieldsOK = false;
    @track isAllowGenerate = false;
    @track isActivityCodeEmpty = false;
    @track isAmountdiff = false;
    @track isRendered = false;
    @track isEmptyLines = false;
    @track invoicingCondition;
    @track contractAmount;
    @track currencyIsoCode;
    @track lineAmount;
    @track axaGoLegalEntity;
    @track serviceType;
    @track totalAmount;
    //@track invoicedAmount;
    //@track remainingAmount;
    @track contract;
    @track exceptActivityCode = new Array();
    @track lineIndex;
    @track lineActivityCode;
    @track activityCodeFields = ['Name','GIE_GO_SAS__c','Activity_Level_1__c','Activity_Level_2__c','Cost_center_description__c','Active__c'];
    @track activityCodeDisplayFields = 'Name,Activity_Level_2__c';
    @track activityCodeConditions = ['Id','Name','GIE_GO_SAS__c','Activity_Level_1__c','Activity_Level_2__c','Cost_center_description__c','Active__c'];
    @track columns = new Array();
    @track data = new Array();

    renderedCallback() {
        Promise.all([
            loadStyle( this, GenerateIL_CSS )
        ]).then().catch(error => {
            if(error && error.body)
            console.log( error.body.message );
        });
    }

    connectedCallback() {
        this.isLoading = true;
        this.getAllData();
    }

    getAllData(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                getAllData({ recordId: this.recordId }).then(result => {
                    if(result.error){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error!',
                            message: result.error,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.closeModal();
                    }else{
                        this.data  = new Array();
                        var newLine = new Object();
                        var contract = result.contract;

                        this.invoicingCondition = contract.Invoicing_Condition__c;
                        this.currencyIsoCode = contract.CurrencyIsoCode;
                        if(contract.AXA_GO_Legal_Entity__c){
                            this.axaGoLegalEntity = contract.AXA_GO_Legal_Entity__c;
                        }
                        if(contract.ServiceType__c){
                            this.serviceType = contract.ServiceType__c;
                        }

                        // set different amounts
                        this.contractAmount = parseFloat(contract.Global_Amount__c).toFixed(2);
                        /*if(result.invoicedAmount){
                            this.invoicedAmount = parseFloat(result.invoicedAmount);
                            this.remainingAmount = parseFloat(this.contractAmount) - this.invoicedAmount;
                        }else{
                            this.invoicedAmount = 0;
                            this.remainingAmount = parseFloat(this.contractAmount);
                        }*/

                        // set first line
                        if(contract.Master_WBS_2__c){
                            newLine.ActivityCode = result.activityCode;
                            newLine.ActivityCodeName = newLine.ActivityCode.Name;
                            newLine.ActivityCodeURL = '/lightning/r/' + newLine.ActivityCode.Id +'/view';
                        }
                        newLine.Amount = parseFloat(this.contractAmount).toFixed(2);
                        //newLine.Amount = this.remainingAmount;
                        newLine.Index = 0;

                        this.isLoading = false;
                        this.isRendered = true;
                        this.data.unshift(newLine);
                        this.buildData(this.data);
                    }
                }).catch(error => {});
            }
        }, 0);
    }

    addLine() {
        this.isFieldsOK = false;
        this.isRendered = false;
        this.isAddLine = true;
    }

    handleActivityCodeLookup(event){
        if(typeof event.detail.data == 'undefined'){
            this.lineActivityCode = null;
        }else{
            this.lineActivityCode = new Object();
            this.lineActivityCode = event.detail.data.record;
        }
        this.fieldsValidation();
    }

    handleAmountChange(event){
        this.lineAmount = event.detail.value;
        this.fieldsValidation();
    }

    handleRowAction(event) {
        var iconName = event.detail.action.name;
        var selectedLine = event.detail.row;
        var index = selectedLine.Index;
        var amount = selectedLine.Amount;
        var activityCode = selectedLine.ActivityCode;
        this.lineIndex = index;
        this.lineAmount = amount;
        if(activityCode){
            this.lineActivityCode = new Object();
            this.lineActivityCode.Id = activityCode.Id;
            this.lineActivityCode.Name = activityCode.Name;
        }
        switch (iconName) {
            case 'editLine':
                if(this.lineActivityCode){
                    this.exceptActivityCode = this.exceptActivityCode.filter(function(acId) { return acId !== activityCode.Id });
                }
                this.isRendered = false;
                this.isEditLine = true;
                this.isFieldsOK = false;
            break;
            case 'deleteLine':
                this.data = this.data.filter(function(line) { return line.Index !== index });
                this.handleCancelLineAction();
                this.buildData(this.data);
            break;
        }
    }

    handleSaveAdd(){
        var newLine = new Object();
        newLine.ActivityCode = this.lineActivityCode;
        newLine.Amount = parseFloat(this.lineAmount).toFixed(2);
        this.data.push(newLine);
        this.buildData(this.data);
        this.handleCancelLineAction();
    }

    handlesaveEdit(){
        this.data = this.data.map(line => {
            if (line.Index == this.lineIndex) {
                return {...line, ActivityCode : this.lineActivityCode, Amount: parseFloat(this.lineAmount).toFixed(2)};
            }
            return line;
        });
        this.buildData(this.data);
        this.handleCancelLineAction();
    }

    handleGenerateInvoicingLines(){
        this.isSaving = true;
        var lines = JSON.stringify(this.data);
        
        if(this.data){
            generateInvoicingLines({lines: lines})
            .then(result => {
                if(result){
                    if(result.success){  
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
                    this.isSaving = false;
                }else{
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error!',
                        message: 'An error occured during the process.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.isSaving = false;
                }
            })
            .catch(error => {
            });
        }
    }
    
    handleCancelLineAction(){
        this.lineIndex = null;
        this.lineAmount = null;
        this.lineActivityCode = null;
        this.isFieldsOK = false;
        this.isRendered = true;
        this.isAddLine = false;
        this.isEditLine = false;
    }

    fieldsValidation(){
        this.isFieldsOK = false;

        if(this.lineAmount && this.isAmountValid() && this.lineActivityCode){
            this.isFieldsOK = true;
        }
    }

    isAmountValid(){
        let isValid = false;
        const decimalRegex = /^(?!0*\.?0*$)\d*.(\d{1,2})?$/;//^(?!0*\.?0+$)\d*\.(\d{1,4})?$
        let amount = this.template.querySelector('[data-id="decimalNumber"]');
        if(amount){
            let amountVal = amount.value;
            if(!amountVal.match(decimalRegex) ){
                amount.setCustomValidity('Please enter a valid amount greater than 0 (two digits after the decimal point at most)');
            }else{
                amount.setCustomValidity('');
                isValid = true;
            }
            amount.reportValidity();
        }
        return isValid;
    }

    buildData(data){
        let index = 0;
        this.totalAmount = 0;
        this.isActivityCodeEmpty = false;
        this.isAmountdiff = false;
        this.data = new Array();
        this.exceptActivityCode = new Array();
        if(data){
            data.forEach(line => {
                line.Index = index;
                line.ContractId = this.recordId;
                if(!line.ActivityCode){
                    this.isActivityCodeEmpty = true;
                }else{
                    line.ActivityCodeName = line.ActivityCode.Name;
                    line.ActivityCodeURL = '/lightning/r/' + line.ActivityCode.Id +'/view';
                    this.exceptActivityCode.push(line.ActivityCode.Id);
                }
                this.totalAmount += parseFloat(line.Amount);
                this.data.push(line);
                index ++;
            });
            this.isAmountdiff = (this.data.length > 0 && this.totalAmount != this.contractAmount) ? true : false;
            this.isAllowGenerate = (this.isActivityCodeEmpty || this.isAmountdiff) ? false : true;
            this.isEmptyLines = this.data.length > 0 ? false : true;
            this.columns = this.isEmptyLines ? COLUMNS2 : COLUMNS1;
        }
    }

    refreshPage(){
        setTimeout(()=>{
            eval("$A.get('e.force:refreshView').fire();"); 
            this.dispatchEvent(new CloseActionScreenEvent());
        },0);
    }
    
    closeModal() {
        this.isRendered = false;
        this.isSaving = false;
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}