public with sharing class VFC23_CancelIL {
	//Attributs 
	/**
	 * <b>standardController </b>: the controller send by the visual force page
	 */
	public ApexPages.StandardController standardController {get; set;}

	/**
     * <b>myClonedSObject </b>: the cloned SObject 
     */
    protected sObject mySObject;

	public VFC23_CancelIL(ApexPages.StandardController stdController) {
		this.standardController = stdController;
		if (!Test.isRunningTest()) { 
            // Retrieve all contracts fields (full object to clone it)
            SObjectType vContractType = Schema.getGlobalDescribe().get('Planned_Invoicing_Line__c');
            Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();
            List<String> vFieldsToRetrieve = new List<String>(vFields);
            standardController.addFields(vFieldsToRetrieve);
        }
		this.mySObject =(sObject)standardController.getRecord();
	}

	public PageReference CancelILAction(){
		String ilStatus = (String) this.mySObject.get('Status__c');
		if(ilStatus == '05-INVOICED' || ilStatus == '06-PAID' || ilStatus == '99-CANCELLED'){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can\'t cancel an Invoicine Line if its status is 05-INVOICED or 06-PAID or 99-CANCELLED'));
			return null;
		}
		this.mySObject.put('PMO_Ready_for_Invoice__c','CANCELLATION REQUESTED');
		this.mySObject.put('ADV_GoNoGo__c','CANCELLED');
		update this.mySObject;
		 return new PageReference('/' + this.mySObject.Id);
	}
}