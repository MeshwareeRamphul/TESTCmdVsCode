public with sharing class VFC02_IdCard {

	private final Opportunity mOpty;

    public List<String> risksLow { get; set; }
    public List<String> risksMedium { get; set; }
    public List<String> risksHigh { get; set; }

    public VFC02_IdCard(ApexPages.StandardController stdController) {
    	if (!Test.isRunningTest()) {
    		stdController.addFields(
                new List<String>{'Product__c','Product__r.Name','Product__r.Product_Owner__r.Name', 
                        'Engagement_Committee_Lookup__r.Risks_Low__c', 'Engagement_Committee_Lookup__r.Risks_Medium__c', 'Engagement_Committee_Lookup__r.Risks_High__c', 'Engagement_Committee_Lookup__r.Total_cost__c', 'Engagement_Committee_Lookup__r.Total_Revenue__c'
                    }
            );
    	}
        this.mOpty = (Opportunity)stdController.getRecord();

        risksLow = splitStringInList(mOpty.Engagement_Committee_Lookup__r.Risks_Low__c);
        risksMedium = splitStringInList(mOpty.Engagement_Committee_Lookup__r.Risks_Medium__c);
        risksHigh = splitStringInList(mOpty.Engagement_Committee_Lookup__r.Risks_High__c);
    }

    /*
    *   Split a string separated by \n in a list of string
    */
    private List<String> splitStringInList(String pString) {
        List<String> vStringPieces = new List<String>();
        if (String.isEmpty(pString)) {
            return vStringPieces;
        }

        return pString.split('\n');
    }


    /*
    *  Get total revenue formatted
    */
    public String getTotalRevenue() {
        if (mOpty.Engagement_Committee_Lookup__r.Total_Revenue__c == null) {
            return '';
        }

        return mOpty.Engagement_Committee_Lookup__r.Total_Revenue__c.format();
    }

    /*
    * get total cost formatted
    */
    public String getTotalCost() {
        if (mOpty.Engagement_Committee_Lookup__r.Total_cost__c == null) {
            return '';
        }

        return mOpty.Engagement_Committee_Lookup__r.Total_cost__c.format();
    }
}