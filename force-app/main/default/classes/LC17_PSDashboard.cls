public class LC17_PSDashboard {
	/*
	----------------------------------------------------------------------
	-- - Name          : LC17_PSDashboard
	-- - Author        : ARA
	-- - Description   : Controller for lighning component LC17_PSDashboard
	--
	-- Maintenance History:
	--
	-- Date          Name   Version   Remarks
	-- -----------   ----   -------   ---------------------------------------
	-- 18/08/2020    ARA    1.0      Initial version
	-- 18/08/2020    ARA    1.1      SP-02337 Use System.Label
	--------------------------------------------------------------------------- */
	@AuraEnabled
	public static String getURL(Id objID) {
		/*String url = '';
        Contract__c ctr = [Select id, PS_Dashboard_Url__c from Contract__c where Id = :objID];
        url = ctr.PS_Dashboard_Url__c;
        
        return url;*/
		String contractId = objID;
		if(contractId.length() > 15){
			contractId = contractId.substring(0,15);
		}
		return System.Label.PSDashboardURL + contractId;
    }
}