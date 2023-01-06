public with sharing class VFC24_ILCreditNote extends VFCXX_SObjectClone{
	public ApexPages.StandardController standardController {get; set;}

    public VFC24_ILCreditNote(ApexPages.StandardController standardController) {
        super(standardController);
        if (!Test.isRunningTest()) {
            // Retrieve all contracts fields (full object to clone it)
            SObjectType vContractType = Schema.getGlobalDescribe().get('Planned_Invoicing_Line__c');
            Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();
            List<String> vFieldsToRetrieve = new List<String>(vFields);
            standardController.addFields(vFieldsToRetrieve);
        }
        this.mysObject = (sObject)standardController.getRecord();
    }

    //Methods
    /**
     * <b>Methods initializeClonedObject</b>: see the abstract class for more informations.
     */
    public override void initializeClonedObject(){
        this.myClonedSObject.put('Type__c', 'Credit Note');
        this.myClonedSObject.put('RecordTypeId', Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Credit Note').getRecordTypeId());
        this.myClonedSObject.put('Planned_Invoicing_Line__c', null);
        this.myClonedSObject.put('Status__c', '01');
        this.myClonedSObject.put('AmountIL__c', Integer.valueOf(this.myClonedSObject.get('AmountIL__c')) * -1);
        //this.myClonedSObject.put('ADV_GoNoGo__c', '');
        //this.myClonedSObject.put('ADV_Comments__c', '');
        this.myClonedSObject.put('N_Invoice__c', null);
        this.myClonedSObject.put('SO__c', '');
        this.myClonedSObject.put('ITEM__c', '');
        //this.myClonedSObject.put('SAP_ID__c', this.myClonedSObject.get('SAP_ID__c'));

        //this.myClonedSObject.put('PMO_Ready_for_Invoice__c', '');
        //this.myClonedSObject.put('PMO_Comments__c', '');

        this.myClonedSObject.put('PS_BillingDate__c', null);
        this.myClonedSObject.put('PS_ExtractionDate__c', null);
        this.myClonedSObject.put('PS_Message__c','');
        this.myClonedSObject.put('PS_ConnectionMessage__c','');
        this.myClonedSObject.put('Paid_Not_Paid__c', false);
    }

    public pageReference checkRights(){
        String strCurrentStatus = (String)this.mysObject.get('Status__c');

        if(AP_Constant.hasRights(AP_Constant.strProfPMOADV) && (strCurrentStatus == AP_Constant.strPaid || strCurrentStatus == AP_Constant.strInvoiced)
            ){
            PageReference pageRef = cloneAction();
            return pageRef;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, AP_Constant.strCRCannotCreate));
            return null;
        }
    }
}