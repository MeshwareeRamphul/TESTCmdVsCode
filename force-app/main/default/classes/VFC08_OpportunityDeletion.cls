public class VFC08_OpportunityDeletion {

    // Current opportunity to delete
    public Opportunity mOpty { get; set; }

    // Ret url
    public String mRetURL { get; set; }

    public VFC08_OpportunityDeletion(ApexPages.StandardController pStdController) {
        if (!Test.isRunningTest()) {
            pStdController.addFields(new List<String>{'AccountId', 'Product__c'});
        }
        this.mOpty = (Opportunity)pStdController.getRecord();
        mRetURL = ApexPages.currentPage().getParameters().get('retURL');
    }


    /*
    * Check if duplicate records exist
    */
    public boolean checkDuplicate() {       
        List<Opportunity> vDuplicateRecords = null;
        if (mOpty.Product__c != null) {
            vDuplicateRecords = [SELECT Id, Product__c, IsClosed, AccountId
                                                     FROM Opportunity
                                                     WHERE AccountId = :mOpty.AccountId   
                                                     AND Product__r.Id = :mOpty.Product__c              
                                                     AND Id != :mOpty.Id
                                                     AND IsClosed = false];
        } else {
        System.debug('############## checkDuplicate - mOpty.Product__c = null');
            return false;
        }

        return vDuplicateRecords != null && vDuplicateRecords.size() > 0;
    }

    /**
    * deletion method
    */
    public PageReference deleteTheRecord() {
        System.debug('############## deleteTheRecord');
        Boolean vDuplicateExists = checkDuplicate();
        System.debug('############## vDuplicateExists - ' + vDuplicateExists);

        if (vDuplicateExists) {
            try {
                delete mOpty;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Opty_Confirm_Deleted));
            return null;
        } 
        // Go back to the opportunity
        mRetURL = '/' + mOpty.Id;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Opty_Err_CannotDelete));
        return null;
    }

}