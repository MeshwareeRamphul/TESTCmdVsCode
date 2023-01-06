public with sharing class VFC01_OptyProgressTrackerExt {

    // Available stages of the opportunities
    public static List<OpportunityStage> optyStaticStagesList { get; set; }

    // Stage messsages
    @TestVisible
    private static Map<String, String> stagesMessages = new Map<String, String>{
        AP_Constant.STAGE_LEADS_GATHERING => System.Label.Opty_Tooltip_Collect,
        AP_Constant.STAGE_COLLECT => System.Label.Opty_Tooltip_Collect,
        AP_Constant.STAGE_QUALIFY_ALIGN => System.Label.Opty_Tooltip_Qualify_Align,
        AP_Constant.STAGE_CONTRACTING => System.Label.Opty_Tooltip_Contracting
    };

    public final static String BTNWINMESSAGE = '';


    static {
        optyStaticStagesList = new List<OpportunityStage>([Select Id, IsActive, IsClosed, MasterLabel, SortOrder, IsWon, DefaultProbability
                FROM OpportunityStage 
                WHERE IsActive=true 
                ORDER BY SortOrder ASC]);
    }

    // Available stages of the opportunities that will be displayed
    public List<OpportunityStage> optyStagesList { get; set; }

    // Current Opportunity
    private final Opportunity opty;

    // Current stage number
    public Integer currentStageNumber { get; set; }
    // Last open stage number
    public Integer lastOpenStageNumber { get; set; }

    /**
    * Controller
    */
    public VFC01_OptyProgressTrackerExt(ApexPages.StandardController stdController) { 
        // If not in a test class, add the required fields to be included in the SOQL request 
        if (!Test.isRunningTest()) {stdController.addFields(new List<String>{'StageName', 'IsClosed', 'IsWon', 'Last_Open_Stage__c', 'Product__c', 'Account.Account_Manager__c', 'Product__r.Product_owner__c', 'RecordTypeId' }); }
        opty = (Opportunity)stdController.getRecord();
        initOptyStageList();

        System.Debug('############ End of init ');
        currentStageNumber = getStageNumberByName(opty.StageName);
        // Modify the list to display
        if (opty.IsClosed && !opty.IsWon) { lastOpenStageNumber = getStageNumberByName(opty.Last_Open_Stage__c); }
        System.Debug('############ currentStageNumber ' + currentStageNumber);
        System.Debug('############ lastOpenStageNumber ' + lastOpenStageNumber);
    }

    /**
    * Methods
    */
    public void initOptyStageList() {
        System.Debug('############ initOptyStageList ');
        optyStagesList = new List<OpportunityStage>();
        optyStagesList.addAll(optyStaticStagesList);
        
        // In case the opty is closed and lost, reorder stages to be displayed
        reorderStages();
        System.Debug('############ END initOptyStageList ');
    }


    public void reorderStages() {
        System.Debug('############ reorderStages ');
        if (opty.IsClosed && !opty.IsWon && opty.Last_Open_Stage__c != null) {
            Integer vOptyLastStageNumber = getStageNumberByName(opty.Last_Open_Stage__c);
            Integer vOptyLostStage = getStageNumberByName(AP_Constant.STAGE_LOST);
            Integer vOptyCancelStage = getStageNumberByName(AP_Constant.STAGE_CANCEL);  
            List<OpportunityStage> vOptyStageReordered = new OpportunityStage[optyStagesList.size()];
            for (Integer i = 0; i < optyStagesList.size(); i++) {
                if (optyStagesList[i].SortOrder <= vOptyLastStageNumber) { vOptyStageReordered.add(i, optyStagesList[i]);
                } else if (optyStagesList[i].SortOrder == vOptyLostStage) { vOptyStageReordered.add(vOptyLastStageNumber, optyStagesList[i]);vOptyStageReordered.add(vOptyLastStageNumber, optyStagesList[i]);
                } else if (optyStagesList[i].SortOrder > vOptyLastStageNumber) { vOptyStageReordered.add((i + 1), optyStagesList[i]);} 
            }

            optyStagesList = vOptyStageReordered;            
        }
        System.Debug('############ END reorderStages ');
    }

    /**
    * Get the order of the opportunity by name
    * Returns -1 if opty stage is not in the configuration
    */
    public Integer getStageNumberByName(string pStageName) {
        System.Debug('############ getStageNumberByName ' + pStageName);
        if (pStageName != null && optyStagesList != null) {
            for (OpportunityStage vOptyStage : optyStagesList) {
                if (vOptyStage != null && pStageName.equals(vOptyStage.MasterLabel)) {
                    System.Debug('############ vOptyStage.SortOrder : ' + vOptyStage.SortOrder);
                    return vOptyStage.SortOrder;
                }
            }
        }
        System.Debug('############ END getStageNumberByName ');

        return -1;
    }

    /*
    * Move to the next next
    */
    public PageReference moveToNextStage() {
        try {
            String vNextStage = getNextStageName();
            System.debug('############# moveToNextStage :  ' + vNextStage);
            if (vNextStage != null) {
                opty.StageName = vNextStage;
                update opty;
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }

        return Page.VFP01_OptyProgressTracker;
    }
    


    /*
    * Go back to the stage
    */
    public PageReference goBackToStage() {
        String vStage = ApexPages.currentPage().getParameters().get('pStage');
        if (vStage != null) {
            try {               
                opty.StageName = vStage;
                update opty;               
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured  : ' + e.getMessage()));
                return null;
            }
        }
        return Page.VFP01_OptyProgressTracker;
    }

    /*
    * Return the name of the next stage regarding to the current one
    */
    public String getNextStageName() {
        //Integer vNextStage = currentStageNumber + 1;
                Integer vNextStage = nextStageOrder();

        for (OpportunityStage vOptyStage : optyStagesList) {
            if (vOptyStage.SortOrder == vNextStage) {
                return vOptyStage.MasterLabel;
            }
        }

        return null;
    }

    /*
    * Return the number of opty stages
    */
    public Integer getNumberOfOptyStages() {
        return optyStaticStagesList.size();
    }

    /**
    * return true if the opportunity is lost
    */
    public Boolean getIsLost() {
        return opty.IsClosed && !opty.IsWon;
    }
    
    /**
    * return true if the opportunity is won
    */
    public Boolean getIsWon() {
        return opty.IsClosed && opty.IsWon;
    }

    /**
    * return true if the opportunity is won
    */
    public Boolean getIsClosed() {
        return opty.IsClosed;
    }
   
    /*
    * Return the number of stages to display (close is displayed only if closed)
    */
    public Integer getNumberOfStagesToDisplay() {
        return (!opty.IsWon && opty.IsClosed) ? optyStaticStagesList.size() - 1 : (optyStaticStagesList.size() - 2);
    }

    /**
    * Get tooltip depending on stage
    */
    public String getTooltip() {
        String vCurrentStage = opty.StageName;
        if (stagesMessages.containsKey(vCurrentStage)) {
            return stagesMessages.get(vCurrentStage);
        }

        return '';
    }

    /*
    * return true if the opportunity was won then lost
    */
    public Boolean getIsWonToLostOpty() {
        return opty.Last_Open_Stage__c == AP_Constant.STAGE_WON && opty.IsClosed && !opty.IsWon;
    }

    /*
    * Returns true if AMO exists, false otherwise
    */
    public Boolean getIsAMOExists() {
        return opty.Account != null && opty.Account.Account_Manager__c != null;
    }

    /*
    * Returns true if PO exists, false otherwise
    */
    public Boolean getIsPOExists() {
        return opty.Product__c != null && opty.Product__r.Product_owner__c != null;
    }

    public Boolean getIsRecordTypeClose() {
        String rtCloseId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppReadOnly).getRecordTypeId();
        return opty.RecordTypeId == rtCloseId ? true : false;
    }

    /*
    * Returns true if Product exists, false otherwise
    */
    public Boolean getIsProductFilledIn() {
        return opty.Product__c != null;
    }

     public Integer nextStageOrder(){
        boolean selectNext = optyStagesList.get(0).SortOrder == currentStageNumber;

        for(OpportunityStage opptyStage: optyStagesList){
            if(selectNext){
                return Integer.valueOf(opptyStage.SortOrder);
            }
        }
        return 0;
    }



    public Integer getWonStageSortOrder(){
        for(OpportunityStage opptyStage: optyStaticStagesList){
            if(opptyStage.MasterLabel == 'Opportunity Won'){
                return Integer.valueOf(opptyStage.SortOrder);
            }
        }
        return 0;
    }

    public Integer getLostStageSortOrder(){
        for(OpportunityStage opptyStage: optyStaticStagesList){
            if(opptyStage.MasterLabel == 'Opportunity Lost'){
                return Integer.valueOf(opptyStage.SortOrder);
            }
        }
        return 0;
    }

}