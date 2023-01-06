public with sharing class VFC13_SOWEditor {
	
	public Contract__c mContract { get; set; }
	
	public static Integer MAX_LENGTH_RICHTEXT = 131072;
	
	public VFC13_SOWEditor(ApexPages.StandardController pController) {		
		if (!Test.isRunningTest()) {pController.addFields(new List<String>{'SOW_Operational__c', 'SLA__c'}); 
		}
    	this.mContract = (Contract__c) pController.getRecord();
	}
	
	/**
	* Save SOW field
	*/
	public PageReference saveSOW() {
		try { 
			update mContract;
		} catch (Exception ex) { ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error: ' +  ex.getMessage()));return null;			
		}
		
		// To avoid view state limit exceeded, reload the page
		PageReference redirectPage = Page.VFP13_SOWEditor;
	    redirectPage.setRedirect(true);
	    redirectPage.getParameters().put('id', mContract.Id);
	    return redirectPage;
	}
		
	/**
	* Save SLA field
	*/
	public PageReference saveSLA() {
		try { 
			update mContract; 
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Error : ' + e.getMessage()));
			return null;
		}
		
		// To avoid view state limit exceeded, reload the page
		PageReference redirectPage = Page.VFP13_SLAEditor;
	    redirectPage.setRedirect(true);
	    redirectPage.getParameters().put('id', mContract.Id);
	    return redirectPage;
	}
	 
}