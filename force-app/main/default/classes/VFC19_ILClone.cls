/**
 * <b>Class VFC19_ILClone </b>: Clone management
 */
public with sharing class VFC19_ILClone {
	//Attributs 
	/**
	 * <b>standardController </b>: will store the current Standard Controller
	 */
	private ApexPages.StandardController standardController;

	//Constructors
	/**
	 * <b>Constructor with one argument</b>
	 * @param standardController (ApexPages.StandardController) : element send by the visualforce page
	 */
	public VFC19_ILClone(ApexPages.StandardController standardController) {
		this.standardController = standardController;
		if (!Test.isRunningTest()) { SObjectType vContractType = Schema.getGlobalDescribe().get('Invoicing_Line__c');Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();List<String> vFieldsToRetrieve = new List<String>(vFields);
            //vFieldsToRetrieve.add('Amendment_to__r.Name');
            this.standardController.addFields(vFieldsToRetrieve);
		}
	}

	//Methods
	/**
	 * <b>Method static canBeCloned </b>: test if we can cloned this invoicing line
	 * @param invoicingLine (Invoicing_Line__c) : the invoicing we want to clone
	 * @return Boolean
	 */
	private static boolean canBeCloned(Invoicing_Line__c invoicingLine){
		return true;
	}

	/**
	 * <b>Method cloneInvoicingLine </b>: return a page reference send to a clone invoicing line
	 * @return PageReference : send the corresponding page refernece
	 */
	public PageReference cloneInvoicingLine(){
		Invoicing_Line__c currentInvoicingLine = (Invoicing_Line__c) standardController.getRecord();
		if(canBeCloned(currentInvoicingLine)){
			//CLoned of the new Invoicing Line
			Invoicing_Line__c clonedInvoicingLine = currentInvoicingLine.clone(false, true, false, false);
			clonedInvoicingLine.Planned_Invoicing_Line__c = null;
			clonedInvoicingLine.Status__c = '00-DRAFT';
			clonedInvoicingLine.SO__c = '';
			clonedInvoicingLine.ITEM__c = '';
			clonedInvoicingLine.ADV_Comments__c = '';
			clonedInvoicingLine.ADV_GoNoGo__c = '';
			clonedInvoicingLine.Billing_date_SAP__c = null;
			clonedInvoicingLine.N_Invoice__c = null;
			clonedInvoicingLine.SAP_Extracting_Date__c = null;
			clonedInvoicingLine.RecordTypeId = '01224000000FAzGAAW';
			insert clonedInvoicingLine;
			return new PageReference('/' + clonedInvoicingLine.Id);
		}
		else{ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot cloned the following Invoicing Line : ' + currentInvoicingLine.Name));return null;
		}
	}
}