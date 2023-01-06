public with sharing class VFC07_ContractAmendment {
    private ApexPages.StandardController standardController;

    public VFC07_ContractAmendment(ApexPages.StandardController standardController) 
    {
        this.standardController = standardController;
        // Fields being used for amendment 
        if (!Test.isRunningTest()) { 
            // Retrieve all contracts fields (full object to clone it)
            SObjectType vContractType = Schema.getGlobalDescribe().get('Contract__c');
            Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();
            this.standardController.addFields(new List<String>(vFields));
        }
    }

    public PageReference createAmendment() {
        // Record being amended
        Contract__c currentContract = (Contract__c) standardController.getRecord();
        Contract__c amendment = createAmendmentFromContract(currentContract);       

        // Redirect to the new amendment record
        return new PageReference('/' + amendment.Id);
    }
    
    
    public Contract__c createAmendmentFromContract(Contract__c pContract) {
         // Custom amendment creation logic
        Contract__c amendment = pContract.clone(false, true, false, false); //Deep clone
                         
        amendment.Global_Amount__c = 0;         
        amendment.Name = 'AMD' + string.valueof(pContract.amendments__r.Size() + 1) + '_' + pContract.Name; 
        amendment.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL).getRecordTypeId();             
        amendment.Status__c = System.Label.ContractStatus_Draft;
        amendment.SOW_Operational__c = null;
        amendment.Amendment_to__c = pContract.Id; 
        amendment.Master_WBS_2__c = null;
        amendment.TECH_IsClonedContract__c = true;
       
        Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');
        if(pContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id || pContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_READONLY).Id){
            amendment.ServiceType__c = null;
            amendment.InvoicingMethod__c = null;
            amendment.Invoicing_Condition__c = null;
        }


        try {
            insert amendment;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured : ' + e.getMessage()));
        }
        
        System.debug(LoggingLevel.INFO, amendment.Id);

        return amendment;
    }
    
}