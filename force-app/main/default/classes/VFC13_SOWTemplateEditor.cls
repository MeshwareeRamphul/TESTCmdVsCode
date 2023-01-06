public with sharing class VFC13_SOWTemplateEditor {
	
	public SOW_Template__c mTemplate { get; set; }
	
	public VFC13_SOWTemplateEditor(ApexPages.StandardController pController) {		
		if (!Test.isRunningTest()) {
			pController.addFields(new List<String>{'Body__c'}); 
		}
    	this.mTemplate = (SOW_Template__c) pController.getRecord();
	}
	
	
	public PageReference saveSOWTemplate() {
		try {
			update mTemplate;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
			return null;
		}
		PageReference redirectPage = Page.VFP13_SOWTemplateEditor;
	    redirectPage.setRedirect(true);
	    redirectPage.getParameters().put('id', mTemplate.Id);
	    
	    return redirectPage;
	}
}