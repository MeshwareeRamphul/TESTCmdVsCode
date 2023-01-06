/* ----- DLAM - 16/09/2016 : Modification of the Code in order to handle the Contract.Service_Type_Picklist__c = Oppty.Category__c "Contract__c getContractFromOpty()"  */

global with sharing class VFC11_OpportunityButtons {
    
    // Current Opty
    private final Opportunity mOpty { get; set; }    
    // Available stages of the opportunities
    public static List<OpportunityStage> optyStaticStagesList { get; set; }

    // Selected contract RT
    //public String mRTValue { get; set; }
    
    static {
        optyStaticStagesList = new List<OpportunityStage>([Select Id, IsActive, IsClosed, MasterLabel, SortOrder, IsWon, DefaultProbability
                FROM OpportunityStage 
                WHERE IsActive = true 
                ORDER BY SortOrder ASC]);
    }
    
    public VFC11_OpportunityButtons(ApexPages.StandardController pController) {
        if (!Test.isRunningTest()) {pController.addFields(new List<String>{ 'isWon', 'isClosed', 'StageName', 'AccountId', 'Account.AGS_Contract_Region__c', 'CurrencyIsoCode', 'Product__r.Product_owner__c', 'Account.Account_Manager__c'} );}
        this.mOpty = (Opportunity) pController.getRecord(); 
        
    }
    
    /**
    * Returns true if the opportunity stage >= Answer and opportunity is open
    */
    public Boolean getIsOpenAndAfterAlign() {
        String vCurrentStage = mOpty.StageName;
        Integer vCurrentStageNumber = getStageNumberByName(vCurrentStage);
        
        //return vCurrentStageNumber > AP_Constant.STAGE_NUMBER_ALIGN && !mOpty.isClosed;
        Integer qualifyAlignStageNumber = getStageNumberByName(AP_Constant.STAGE_QUALIFY_ALIGN);


        return vCurrentStageNumber > qualifyAlignStageNumber && !mOpty.isClosed;
    }
        
    /**
    * Get the order of the opportunity by name
    * Returns -1 if opty stage is not in the configuration
    */
    public Integer getStageNumberByName(string pStageName) {
        System.Debug('############ getStageNumberByName ' + pStageName);
        if (pStageName != null && optyStaticStagesList != null) {
            for (OpportunityStage vOptyStage : optyStaticStagesList) {
                if (vOptyStage != null && pStageName.equals(vOptyStage.MasterLabel)) {
                    System.Debug('############ vOptyStage.SortOrder : ' + vOptyStage.SortOrder);
                    return vOptyStage.SortOrder;
                }
            }
        }
        System.Debug('############ END getStageNumberByName ');

        return -1;
    }    
    
    /**
    * return true if the opportunity is won
    */
    public Boolean getIsWon() {
        return mOpty.IsClosed && mOpty.IsWon;
    }

    /**
    * return true if the opportunity is won
    */
    public Boolean getIsClosed() {
        return mOpty.IsClosed;
    }
    
    /*
    * Close and lose the opty
    */
    public PageReference cancelOpty() {
        return updateStatus(AP_Constant.STAGE_CANCEL);
    }
    /*
    * Close and lose the opty
    */
    public PageReference closeOpty() {
        return updateStatus(AP_Constant.STAGE_LOST);
    }
    /*
    * Win the opty
    */
    public PageReference winOpty() {
        return updateStatus(AP_Constant.STAGE_WON);
    }
    /*
    * Qualify/Align the opty
    */
    public PageReference qualifyAlignOpty() {
        return updateStatus(AP_Constant.STAGE_QUALIFY_ALIGN);
        }
    /*
    * Contracting the opty
    */
    public PageReference contractingOpty() {
        return updateStatus(AP_Constant.STAGE_CONTRACTING);
    }

    /*
    * Update status
    */
    private PageReference updateStatus(String newStage) {
        String actualStage = mOpty.StageName;
        try {
            if (String.isNotBlank(newStage)) {
                mOpty.StageName = newStage;
                update mOpty;
            }
        } catch (Exception e) {
            // rollback to prior stage (for VF and rendered stage buttons, VF will hide stage buttons with new stage otherwise)
            System.debug(LoggingLevel.ERROR,'##VFC11## Error when updating status : ' + e.getMessage());
            mOpty.StageName = actualStage;
            return null;
        }

        return Page.VFP11_OpportunityButtons;
    }
    
    /**********************************************************************************************
    * Contract creation
    ***********************************************************************************************/
    /**
    * Create contract from opportunity
    */
    @RemoteAction
    global static String createContracts(Id pOptyId, String pRT) {
        System.debug('##########pRT : ' + pRT);
        return createContractOnOptyWin(pOptyId, pRT);
    }

    private static String createContractOnOptyWin(Id pOptyId, String pRT) {
        System.debug('##########pRT : ' + pRT);

        Id vContractRTId = null;

        if (pRT != null) {vContractRTId = Id.valueOf(pRT);}

        /*Opportunity vOptyRetrieved = 
                [SELECT Id, OwnerId, (SELECT Id, Product__r.Id, Amount__c FROM Opportunity_Products__r), CurrencyIsoCode, AXA_GO_Entity__c, 
                        (SELECT Id FROM Contracts1__r), Project_start_Date__c, AccountId, Name, StageName, Amount, PM_works_on_the_answer__c, Product__c, RecordTypeId, Go_live_date__c, Category__c
                FROM Opportunity WHERE ID = :pOptyId];

        // Contracts mist to insert
        List<Contract__c> vContractToInsert = new List<Contract__c>();
 
        //  Create contract for all opportunities 
        Double vAmountSubProducts = 0.0; 


        /*if (vOptyRetrieved.Contracts1__r.size() <= 0 && vOptyRetrieved.Product__c != null) {
            Contract__c vContract = VFC11_OpportunityButtons.getContractFromOpty(vOptyRetrieved, null, vAmountSubProducts, vContractRTId);
            vContractToInsert.add(vContract);
        }

        try {
            insert vContractToInsert;

            // on contract insertion, update Opp in Read/Only
            vOptyRetrieved.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppReadOnly).getRecordTypeId();
            update vOptyRetrieved;

        } catch (Exception e) {
            return e.getMessage();
        }

        System.debug('###### >>> vContractToInsert : ' + vContractToInsert); 
        System.debug('###### >>> END createContractOnOptyWin');*/
        return null;
    }
 
    /**
     * Methode convertFromCategoryToServiceTypePicklist : will convert a category into
     * a service type picklist
     * @param category String : the category from oppty
     * @return String : the service typ picklist value for the contract
     */
    /*private static String convertFromCategoryToServiceTypePicklist(String category){
        //variables declaration
        String serviceTypePicklist = '';

        //
        if(category == System.Label.OptyCategory_Project){
            serviceTypePicklist = System.Label.Contract_ServiceTypePicklist_Project;
        }
        else{
            serviceTypePicklist = System.Label.Contract_ServiceTypePicklist_BAU;
        }

        //Returning the corresponding serviceTypePicklist
        return serviceTypePicklist;
    }*/


   
    
    /**
    * Returns true if there is already a contract and false otherwise
    */ 
    @RemoteAction
    global static Boolean checkThereIsAContract(Id pOptyId) {
        List<Opportunity> vOpty = [SELECT Id, Name, (SELECT Id FROM Contracts1__r) FROM Opportunity WHERE Id = :pOptyId];
       	if(vOpty.size()>0)
        	return vOpty[0].Contracts1__r != null && vOpty[0].Contracts1__r.size() > 0;
        else
            return false;
    }


    
    /*public Boolean getIsRecordTypeOpportunityContract() {
        return getIsRecordTypeByName(Label.RT_OppContract);
    }

    public Boolean getIsRecordTypeOpportunityOnly() {
        return getIsRecordTypeByName(Label.RT_OppOnly);
    }

    private Boolean getIsRecordTypeByName(String recordTypeName) {
        String rtOpptyContractId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        return mOpty.recordTypeId.equals(rtOpptyContractId) ? true : false;
    }*/

    /*private static Id getRecordTypeContractId(String entity) {
        Id rtId;
        if (Label.Opty_AxaGSEntity_Asia.equals(entity)) {
            rtId = AP_Constant.getRecordTypes('Contract__c').get(Label.RT_AGSAsiaEdit).Id;
        } else if(Label.Opty_AxaGSEntity_Spain.equals(entity)) { 
            rtId = AP_Constant.getRecordTypes('Contract__c').get(Label.RT_AGSSpainEdit).Id;
        } else {
            rtId = AP_Constant.getRecordTypes('Contract__c').get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
        }
        System.debug(LoggingLevel.INFO, 'Entity ' + entity);
        return rtId;
    }*/

    /** 
     * <b>Method getContractFromOptyV2</b>: appliquer le mapping
     */ 
    /*public void getContractFromOptyV2(Opportunity pOpty, Id pRecordType){
        //System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## VFC11_OpportunityButtons.getContractFromOptyV2 - Start');
        //Declaration des variables
        Contract__c newContract = new Contract__c();

        //Getting the corresponding mapping between the contract and opportunity
        List<Mapping_Opportunity_2_Contracts__c> fieldsMapping = [SELECT Contract_Field_API_Name__c, Opportunity_Field_API_Name__c FROM Mapping_Opportunity_2_Contracts__c];
        System.debug(LoggingLevel.DEBUG, '## VFC11_OpportunityButtons.getContractFromOptyV2 - fieldsMapping.size() : ' + fieldsMapping.size());

        //For each fields map, we're going to transfert data
        for(Mapping_Opportunity_2_Contracts__c fieldMapping : fieldsMapping){
            try{
                newContract.put(fieldMapping.Contract_Field_API_Name__c ,pOpty.get(fieldMapping.Opportunity_Field_API_Name__c));
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

        //System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## VFC11_OpportunityButtons.getContractFromOptyV2 - End');
    }*/
}