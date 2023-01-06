import { LightningElement,track,api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/LC16_AddProduct.getProducts';
import saveRecords from '@salesforce/apex/LC16_AddProduct.saveRecords';

export default class LWC_AddProduct extends LightningElement {
    @api recordId;
    @track openmodel = true;
    @track loaded = false;
    @track isDropdown = false;
    @track lstStep = ['step1', 'step2', 'step3'];
    @track isError=false;
    @track isSearching = false;
    @track isSelectAll = false;
    @track nameSearch = '';
    @track activeSectionName;
    @track stepsArray = ['step1', 'step2', 'step3'];
    @track currentSteps = 'step1';
    @track lstSubProduct = new Array();
    @track lstProductSearch = new Array();
    @track lstProductTable = new Array();
    @track lstProductSelected = new Array();
    @track lstChoosenProdLine = new Array();
    @track lstChoosenSubProd = new Array();
    @track productId = 'product-';
    @track closeProductLine = 'closeProductLine-';
    @track closeProduct = 'closeProduct-';
    @track accordianSection = '';

    get isGoToNext(){
        console.log('currentSteps', this.currentSteps);
        console.log('this.lstProductTable', this.lstProductTable.length);
        console.log('currentSteps', this.currentSteps);

        return (this.currentSteps == this.stepsArray[0] && this.lstProductTable.length > 0) || (this.currentSteps == this.stepsArray[1]  && this.isError == false);
    }

    get isOnSave(){
        return this.currentSteps == this.stepsArray[2] && this.isError == false;
    }

    get isGoToBack(){
        return this.currentSteps == this.stepsArray[1] || this.currentSteps == this.stepsArray[2];
    }

    get isProductTable(){
        return lstProductTable.length > 0;
    }

    get class02(){
        return  this.lstProductTable.length > 8 ? 'slds-table--header-fixed_container tableBody' : 'slds-table--header-fixed_container'; 
    }
    get class03(){
        return  this.lstProductTable.length>8 ? 'slds-table--header-fixed_container tableBody' : 'slds-table--header-fixed_container';
    }

    get class04(){
        return this.lstChoosenProdLine.length + this.lstChoosenSubProd.length > 15 ? 'scrollerSize fragment manyResult' : 'scrollerSize fragment';
    }

    get class05(){
        return  (this.lstProductSearch.length>0 && this.isDropdown) ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click' ;
    }

    get id01(){
        return closeProductLine + prodLine;
    }

    get id02(){
        return  closeProduct + product.Id;
    }

    init(){
        this.lstStep = ["step1", "step2", "step3"];
        this.isError = true;
        this.isSearching = false;
        this.isSelectAll = false;
        this.nameSearch = '';
        this.activeSectionName ="search";
        this.stepsArray = this.lstStep;
        this.currentSteps = this.lstStep[0];
        this.lstSubProduct = new Array();
        this.lstProductSearch = new Array();
        this.lstProductTable = new Array();
        this.lstProductSelected = new Array();
        this.lstChoosenProdLine = new Array();
        this.lstChoosenSubProd = new Array();
    }
    handleToggleSection(event) {
        if(this.accordianSection.length === 0){
          this.accordianSection =''
      }
      else{
          this.accordianSection ='Account'
      }

  }

    renderedCallback() {
        this.openmodel = true;
        //this.init();
        //this.isSearching = true;
        //this.searchProducts();     
    }

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

    handleBlur(){
        this.isDropdown = false;
    }

    handleFocus(event){
        this.searchProducts();
        if(this.lstSubProduct.length == 0){
            this.isDropdown = false;
        }else{
            this.isDropdown = true;
        }
        //todo
        event.stopPropagation();
    }

    goToBack(){
        if(this.currentSteps != this.stepsArray[0]) {
            var currIndex = this.stepsArray.indexOf(this.currentSteps);
            this.currentSteps = this.stepsArray[currIndex-1];
            if(this.currentSteps == 'step2') {
                this.activeSectionName = "products";
            } else {
                this.activeSectionName = "search";
            }
            this.isError = false;
        }
    }

    goToNext(){
        this.isError = true;
        if(this.currentSteps != this.stepsArray[this.stepsArray.length - 1]){
            var currIndex = this.stepsArray.indexOf(currentStage);
            this.currentSteps = this.stepsArray[currIndex+1];
            if(this.currentSteps == 'step2') {
                this.activeSectionName = "products";
                this.lstProductTable.forEach(product =>{
                    if(product.isChecked){
                        this.isError = false;
                    }
                });
            }else{
                this.activeSectionName = "summary";
                this.isError = false;
            }
        }
    }
    /* Remove product from table */    
    removeProduct(event) {
        this.isError = true;
        var idEvent = event.currentTarget.id;
        
        if(this.currentSteps == this.stepsArray[1] || this.currentSteps == this.stepsArray[2]) {
           this.currentSteps = this.stepsArray[0];
        }
        
        if(idEvent.startsWith('closeProductLine-')){
            /* for Product Line */
            /*var productLine = idEvent.replace('closeProductLine-', '');
        	var lstChoosenProdLine = component.get("v.lstChoosenProdLine");
        	var lstProductSearch = component.get("v.lstProductSearch");
            if(lstChoosenProdLine != null){
        		this.lstChoosenProdLine", lstChoosenProdLine.filter(e => e !== productLine));
            }
            if(lstProductSearch != null){
        		this.lstProductSearch", lstProductSearch.filter(e => e.Domain_Name__c !== productLine));
            }
            if(lstProductTable != null){
                lstProductTable = lstProductTable.filter(e => e.Domain_Name__c !== productLine);
            }*/
		}else{
            /* for Product */
            var idProduct = idEvent.replace('closeProduct-', '');
            if(this.lstChoosenSubProd != null){
        		this.lstChoosenSubProd = this.lstChoosenSubProd.filter(e => e.Id !== idProduct);
            }
            if(this.lstProductSearch != null){
        		this.lstProductSearch = this.lstProductSearch.filter(e => e.Id !== idProduct);
            }
            if(this.lstProductTable != null){
                this.lstProductTable = this.lstProductTable.filter(e => e.Id !== idProduct);
            }
 		}
        
        if(this.lstProductTable != null && this.lstProductTable.length > 0){
            this.isError = false;
        }
	}

    addToTable(event) {
        var idEvent = event.currentTarget.id;
        
        if(this.currentSteps == this.stepsArray[1] || this.currentSteps == this.stepsArray[2]) {
            this.currentSteps = this.stepsArray[0];
        }
        
        if(idEvent.startsWith('productLine-')){
            /* for Product Line */
            /*var productLine = idEvent.replace('productLine-', '');
            var lstProduct = lstProductSearch.filter(e => e.Domain_Name__c === productLine);
            if(lstProduct != null){
                if (lstChoosenProdLine.find(e => e === productLine) == null) {
                    lstChoosenProdLine.push(productLine);
                }
                lstProduct.forEach(product =>{
                    if (lstProductTable.find(e => e.Id === product.Id) == null) {
                    	product.isChecked = false;
                        lstProductTable.push(product);
                    }
                });
    		}*/
		}else{
            /* for Product */
            var idProduct = idEvent.replace('product-', '');
            var product = this.lstProductSearch.find(e => e.Id === idProduct);
            if(product != null){
                // Product default selected
                if (this.lstProductTable.find(e => e.Id === product.Id) == null) {
                    product.isChecked = true;
                    this.lstProductTable.push(product);
                    this.lstChoosenSubProd.push(product);
                }else{
                    this.lstProductTable.find(e => e.Id === product.Id).isChecked = true;
                }

                this.lstSubProduct = this.lstSubProduct.filter(e => e.Id !== idProduct);
 			}
        }
        this.isSelectAll = false;
        this.isError = false;
    }

    checkboxSelect(event) {
        //todo
        var checkbox = event.getSource();
        var isChecked = checkbox.get("v.value");
        var idProduct = checkbox.get('v.labelClass');
        this.isError = true;
        this.lstProductTable.find(e => e.Id === idProduct).isChecked = isChecked;
        if(!isChecked){
            this.lstProductTable.forEach(product =>{
                if(product.isChecked){
					this.isError = false;
                }
            });
        }else{
			this.isError = false;
        }
	}

    selectAll() {
        if(this.lstProductTable != null){
            this.lstProductTable.forEach(product =>{product.isChecked = this.isSelectAll});
        }else{
            this.isSelectAll = false;
        }
	}

	/* Save selected products */
    onSave() {
        var ltsIdProduct = new Array();
        if(this.lstProductTable != null){
        	this.lstProductSelected = this.lstProductTable.filter(e => e.isChecked === true);
            if(this.lstProductSelected != null){
                this.lstProductSelected.forEach(product =>{
                    ltsIdProduct.push(product.Id);
                });
                this.lstProductSelected = ltsIdProduct;
                addProducts();
        	}
       	}
	}

    /* Add products to a contract */
    addProducts() {
        saveRecords({  "recordId" : this.recordId, "lstIdProduct" : this.lstIdProduct })
        .then(result => {
            this.initAll();
            updateRecord({ fields: { Id: this.recordId } });
            this.closeModal();
        })
        .catch(error => {
            new ShowToastEvent({
                title: 'Error!',
                message: error,
                variant: 'error',
                mode: 'sticky'
            })
        });
    }

    searchProducts(){
        getProducts({  "nameSearch" : this.nameSearch.toLowerCase(), "recordId" : this.recordId, "lstSelectedProduct" : this.lstChoosenSubProd })
        .then(result => {
            if(component.find("nameSearch").get("v.value") != ''){
                this.lstSubProduct = result;
                this.isDropdown = true;
            }else{
                this.lstProductSearch = new Array();
            }
            this.isSearching = false;
        })
        .catch(error => {
            this.lstProduct = null;
            this.isSearching = false;
        });
    }

}