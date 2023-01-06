public with sharing class VFC09_OpportunityPrePopulate {
	public VFC09_OpportunityPrePopulate(ApexPages.StandardController stdController) {}

	/*
	* Redirect to opty with parameters to populate it
	*/
	public PageReference redirectToOptyPopulated() {
		System.debug('############ start redirectToOptyPopulated');
		Schema.DescribeSObjectResult vDescObject = Opportunity.SObjectType.getDescribe();
		
		// Get parameters 
		Map<String, String> vParameters = ApexPages.currentPage().getParameters();		
		PageReference vOptyPage = new PageReference('/' + vDescObject.getKeyPrefix() + '/e');
		vOptyPage.getParameters().putAll(vParameters);
		vOptyPage.getParameters().put('opp11', AP_Constant.STAGE_COLLECT);
		vOptyPage.getParameters().put('nooverride', '1');
		// spring 16 known issue (waiting the patch)
		if (vOptyPage.getParameters().containsKey('save_new')) {
			vOptyPage.getParameters().remove('save_new');
		}
		vOptyPage.setRedirect(true);
		System.debug('############ end redirectToOptyPopulated');
		
		return vOptyPage;
	}
}