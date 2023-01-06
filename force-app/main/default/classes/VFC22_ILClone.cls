public with sharing class VFC22_ILClone extends VFCXX_SObjectClone {
	//Attributs 
	/**
	 * <b>standardController </b>: the controller send by the visual force page
	 */
	public ApexPages.StandardController standardController {get; set;}

	//Constructors
	/**
	 * <b>Constructors of the VFC21_OpportunityClone</b>
	 * Constructors with one argument
	 * @param standardController (ApexPages.StandardController)
	 */
	public VFC22_ILClone(ApexPages.StandardController standardController) {
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
		if(this.myClonedSObject.get('Type__c') == 'Invoicing Line') {

			this.myClonedSObject.put('RecordTypeId', Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId());
			this.myClonedSObject.put('Planned_Invoicing_Line__c', null);
			this.myClonedSObject.put('Status__c', '01');
			this.myClonedSObject.put('SO__c', '');
			this.myClonedSObject.put('ITEM__c', '');
			//this.myClonedSObject.put('ADV_Comments__c', '');
			//this.myClonedSObject.put('ADV_GoNoGo__c', '');
			this.myClonedSObject.put('PS_BillingDate__c', null);
			this.myClonedSObject.put('N_Invoice__c', null);
			this.myClonedSObject.put('PS_BillingDate__c', null);
			this.myClonedSObject.put('PS_Message__c','');
			this.myClonedSObject.put('PS_ConnectionMessage__c','');
			//USA 20180802 : ALLINFIN-572 Clonage des IL
			this.myClonedSObject.put('Paid_Not_Paid__c', false);
			this.myClonedSObject.put('Payment_Document_Number__c', '');
		}
	}
}