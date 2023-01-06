import { LightningElement,api,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

import getContractHierarchy from '@salesforce/apex/lWC_ContractHierarchy.getContractHierarchy';

import basicCss from '@salesforce/resourceUrl/basic';

export default class LWC_ContractHierarchy extends NavigationMixin(LightningElement) {
    @api recordId;

    //Default settings values
    @track keyField = 'id';

    @track ContractName='';
    @track ContractLink='';
    @track currentExpanded='';

    // definition of columns for the tree grid
    gridColumns = [
        {
            type: 'url',
            fieldName: 'contractUrl',
            label: 'Contract Name',
            typeAttributes: {
                label: { fieldName: 'contractName' },
            },
            //initialWidth: 300,
        },
        {
            type: 'text',
            fieldName: 'ContractReference',
            label: 'Contract Reference',
            //initialWidth: 300,
        },
        {
            type: 'text',
            fieldName: 'Status',
            label: 'Status',
            //initialWidth: 300,
        },
        {
            type: 'text',
            fieldName: 'TypeDocuemnt',
            label: 'Type of Document',
            //initialWidth: 300,
        },
        {
            type: 'date-local',
            fieldName: 'ContractEnddate',
            label: 'Contract End date',
            typeAttributes:{
                month: "2-digit",
                day: "2-digit"
            }
            //initialWidth: 300,
        },
        {
            type: 'text',
            fieldName: 'OwnerEntity',
            label: 'Owner entity',
            //initialWidth: 300,
        },
        {
            type: 'text',
            fieldName: 'SupplierLegalSignatoryEntity',
            label: 'Supplier legal signatory entity',
            //initialWidth: 300,
        },
    ];

    // data provided to the tree grid
    gridData = '';

    connectedCallback() {
        this.ContractsLink = window.location.origin;
        this.initializeData();
    }

    renderedCallback() {  
        Promise.all([
            loadStyle( this, basicCss )]).then()
            .catch(error => {
        });
    }

    initializeData(){
        this.gridData='';
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (this.recordId) {
                this.currentRecordId = this.recordId;
                getContractHierarchy({ ctrID: this.recordId })
                .then(result => {

                    this.parseContractWrapper(result.hierarchy);
                    this.gridData = result.hierarchy;
                    //this.currentExpanded=result.hierarchy[0].id;
                    this.ContractName = result.contractName;
                    this.currentExpanded = result.lstIdCtr;
                    console.log('currentExpanded',this.currentExpanded);
                    
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            actionName: 'view',
                        },
                    }).then((url) => {
                        this.ContractLink = url;
                    });
                    /////////////////////////////////////////////////////////////////
                    //const grid = this.template.querySelector('lightning-tree-grid');
                    //this.currentExpanded = grid.getCurrentExpandedRows();
                })
                .catch(error => {
                });
            }
        }, 0);
    }

    parseContractWrapper(lstCtrWrap){
        for (let i = 0; i < lstCtrWrap.length; i++) {
            if ((typeof lstCtrWrap[i].children !== "undefined" || lstCtrWrap[i].children != null) && lstCtrWrap[i].children.length > 0) {
                lstCtrWrap[i]._children = lstCtrWrap[i].children;
                this.parseContractWrapper(lstCtrWrap[i].children);
            }
        }
    }

    navigateContractHome() {
        // Navigate to the Account home page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contract__c',
                actionName: 'home',
            },
        });
    }
}