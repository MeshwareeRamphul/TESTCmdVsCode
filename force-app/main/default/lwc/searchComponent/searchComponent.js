import { LightningElement, api, track, wire } from 'lwc';
import search from '@salesforce/apex/LWC4_SearchController.search';
import searchWithCondition from '@salesforce/apex/LWC4_SearchController.searchWithCondition';
const DELAY = 300;
export default class SearchComponent extends LightningElement {

    @api objName = 'Account';
    @api iconName = 'standard:account';
    @api labelName;
    @api labelRequired;
    @api readOnly = false;
    @api currentObject;
    @api currentRecordId;
    @api currentRound;
    @api selectedRound;
    @api rejectedEmails;
    @api exceptActivityCode;
    @api axaGoLegalEntity;
    @api serviceType;
    @api placeholder = 'Search';
    @api createRecord;
    @api fields = ['Name'];
    @api displayFields = 'Name';
    @api conditions = [];
    @api isMouseOver = false;
    @api currentActivityCode;

    @track error;
    @track defaultRound;

    searchTerm;
    delayTimeout;

    labelrequired;
    searchRecords;
    selectedRecord;
    objectLabel;
    isLoading = false;

    field;
    field1;
    field2;

    ICON_URL = '/apexpages/slds/latest/assets/icons/{0}-sprite/svg/symbols.svg#{1}';

    connectedCallback(){

        let icons           = this.iconName.split(':');
        this.ICON_URL       = this.ICON_URL.replace('{0}',icons[0]);
        this.ICON_URL       = this.ICON_URL.replace('{1}',icons[1]);
        if(this.objName.includes('__c')){
            let obj = this.objName.substring(0, this.objName.length-3);
            this.objectLabel = obj.replaceAll('_',' ');
        }else{
            this.objectLabel = this.objName;
        }
        //this.objectLabel    = this.titleCase(this.objectLabel);
        let fieldList;
        if( !Array.isArray(this.displayFields)){
            fieldList       = this.displayFields.split(',');
        }else{
            fieldList       = this.displayFields;
        }
        
        if(fieldList.length > 1){
            this.field  = fieldList[0].trim();
            this.field1 = fieldList[1].trim();
        }
        if(fieldList.length > 2){
            this.field2 = fieldList[2].trim();
        }
        let combinedFields = [];
        fieldList.forEach(field => {
            if( !this.fields.includes(field.trim()) ){
                combinedFields.push( field.trim() );
            }
        });

        this.fields = combinedFields.concat( JSON.parse(JSON.stringify(this.fields)) );
        
        // Set default value for round
        if(this.objName == 'Negotiation_Round__c'){
            if(this.currentRound){
                var result = new Array();
                result.push(this.currentRound);
                let allResult    = JSON.parse(JSON.stringify(result));
                allResult.forEach( record => {
                    record.FIELD1 = record[this.field];
                    record.FIELD2 = record[this.field1];
                    if( this.field2 ){
                        record.FIELD3 = record[this.field2];
                    }else{
                        record.FIELD3 = '';
                    }
                });

                let selectRecord = allResult[0];
                let recordId = selectRecord.Id;
                this.selectedRecord = selectRecord;
                if(selectRecord !== 'undefined'){
                    const selectedEvent = new CustomEvent('lookup', {
                        bubbles    : true,
                        composed   : true,
                        cancelable : false,
                        detail: {  
                            data : {
                                record : selectRecord,
                                recordId : recordId
                            }
                        }
                    });
                    this.dispatchEvent(selectedEvent);
                }
            }
        }

        // Set default value for Activity code
        if(this.objName == 'Master_WBS_Structure__c'){
            if(this.currentActivityCode){
                var result = new Array();
                result.push(this.currentActivityCode);
                let allResult    = JSON.parse(JSON.stringify(result));
                allResult.forEach( record => {
                    record.FIELD1 = record[this.field];
                    record.FIELD2 = record[this.field1];
                    if( this.field2 ){
                        record.FIELD3 = record[this.field2];
                    }else{
                        record.FIELD3 = '';
                    }
                });

                let selectRecord = allResult[0];
                let recordId = selectRecord.Id;
                this.selectedRecord = selectRecord;
                if(selectRecord !== 'undefined'){
                    const selectedEvent = new CustomEvent('lookup', {
                        bubbles    : true,
                        composed   : true,
                        cancelable : true,
                        detail: {  
                            data : {
                                record : selectRecord,
                                recordId : recordId
                            }
                        }
                    });
                    this.dispatchEvent(selectedEvent);
                }
            }
        }
    }

    handleInputChange(event){
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        //this.isLoading = true;
        this.delayTimeout = setTimeout(() => {
            
            this.searchRecords = null;
            var params = new Object();
            params.searchTerm          = searchKey;
            params.objectName          = this.objName;
            params.currentObject       = this.currentObject;
            params.currentRecordId     = this.currentRecordId;
            params.selectedRound       = this.selectedRound;
            params.fields              = this.fields;
            params.conditions          = this.conditions;
            params.rejectedEmails      = this.rejectedEmails;
            params.axaGoLegalEntity    = this.axaGoLegalEntity;
            params.serviceType         = this.serviceType;
            params.exceptActivityCode  = this.exceptActivityCode;

            if(this.conditions && this.conditions.length>0){
                //console.log('****searchWithCondition ');
                searchWithCondition({
                    params : JSON.stringify(params)
                })
                .then(result => {
                    if(result){
                        let stringResult = JSON.stringify(result);
                        let allResult    = JSON.parse(stringResult);
                        allResult.forEach( record => {
                            record.FIELD1 = record[this.field];
                            record.FIELD2 = record[this.field1];
                            if( this.field2 ){
                                record.FIELD3 = record[this.field2];
                            }else{
                                record.FIELD3 = '';
                            }
                        });
                        this.searchRecords = allResult;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                })
                .finally( ()=>{
                    //this.isLoading = false;
                });
            }else{
                search({ 
                    objectName      : this.objName,
                    currentObject   : this.currentObject,
                    currentRecordId : this.currentRecordId,
                    fields          : this.fields,
                    searchTerm      : searchKey
                })
                .then(result => {
                    if(result){
                        let stringResult = JSON.stringify(result);
                        let allResult    = JSON.parse(stringResult);
                        allResult.forEach( record => {
                            record.FIELD1 = record[this.field];
                            record.FIELD2 = record[this.field1];
                            if( this.field2 ){
                                record.FIELD3 = record[this.field2];
                            }else{
                                record.FIELD3 = '';
                            }
                        });
                        this.searchRecords = allResult;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                })
                .finally( ()=>{
                    //this.isLoading = false;
                });
            }
        }, DELAY);
    }

    handleListMouseOver(event){
        this.isMouseOver = true;
    }

    handleListMouseLeave(event){
        this.isMouseOver = false;
    }

    handleInputBlur(event){
        if(!this.isMouseOver){
            this.searchRecords = null;
        }
    }

    handleSelect(event){
        
        let recordId = event.currentTarget.dataset.recordId;
        
        let selectRecord = this.searchRecords.find((item) => {
            return item.Id === recordId;
        });
        this.selectedRecord = selectRecord;
        
        const selectedEvent = new CustomEvent('lookup', {
            bubbles    : true,
            composed   : true,
            cancelable : true,
            detail: {  
                data : {
                    record          : selectRecord,
                    recordId        : recordId,
                    currentRecordId : this.currentRecordId
                }
            }
        });
        this.dispatchEvent(selectedEvent);
        this.isMouseOver = false;
    }

    handleClose(){
        this.selectedRecord = undefined;
        this.searchRecords  = undefined;
        const selectedEvent = new CustomEvent('lookup', {
            bubbles    : true,
            composed   : true,
            cancelable : true,
            detail: {  
                record : null,
                recordId : null,
                currentRecordId : this.currentRecordId
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    titleCase(string) {
        var sentence = string.toLowerCase().split(" ");
        for(var i = 0; i< sentence.length; i++){
            sentence[i] = sentence[i][0].toUpperCase() + sentence[i].slice(1);
        }
        return sentence;
    }
}