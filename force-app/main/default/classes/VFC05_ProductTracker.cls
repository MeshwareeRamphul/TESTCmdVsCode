public with sharing class VFC05_ProductTracker {

    // Inner class
    public class ProductStage {
        public string stageName { get; set; }
        public Integer stageNumber { get; set; }
        public boolean isSelected { get; set; }
    }

    // Current stage
    public String currentStage { get; set; }

    // Current Product
	private final Product__c mProduct;

    // Current Status
    public Integer currentStageNumber { get; set; }

    // Last open stage
    public Integer lastOpenStage { get; set; }

    // List of status
    public List<ProductStage> mStatusList { get; set; }

    public VFC05_ProductTracker(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
        stdController.addFields(new List<String>{'Status__c'/*, 'Stopped_in_Stage__c'*/});
        }
        mProduct = (Product__c)stdController.getRecord();
        initProductStages();
    }

    /**
    * Load all the picklist values and set the current status (is ordered)
    */
    public void initProductStages() {
        mStatusList = new List<ProductStage>();

        List<Schema.PicklistEntry> vStatusValues = Product__c.Status__c.getDescribe().getPicklistValues();

        Integer i = 1;
        for (Schema.PicklistEntry vStatus : vStatusValues) {
            ProductStage vProductStage = new ProductStage();
            vProductStage.stageName = vStatus.getLabel();
            vProductStage.stageNumber = i;
            if (mProduct.Status__c == vStatus.getValue()) {
                vProductStage.isSelected = true;
                currentStageNumber = i;
                currentStage = vStatus.getValue();
            } else {
                vProductStage.isSelected = false;
            }
            i++;
            mStatusList.add(vProductStage);
        }
        //lastOpenStage = getStageNumberByName(mProduct.Stopped_in_Stage__c);

        // Case of stopped product : reorder
        reorderStages();
    }

    /*
    * Reorder stages in case of stopped product
    */
    public void reorderStages() {
        System.debug('############## reorderStages');
        /*if (getIsStopped() && mProduct.Stopped_in_stage__c != null) {
            Integer vLastOpenStage = getStageNumberByName(mProduct.Stopped_in_stage__c);            
            Integer vProductStoppedStage = getStageNumberByName(AP_Constant.PRODUCT_STATUS_STOPPED);
            
            Integer vSizeList = mStatusList.size();
            List<ProductStage> vProductStageReordered = new ProductStage[vSizeList];
            for (Integer i = 0; i < mStatusList.size(); i++) {
                if (mStatusList[i].stageNumber <= vLastOpenStage) {
                    vProductStageReordered[i] = mStatusList[i];
                } else if (mStatusList[i].stageNumber == vProductStoppedStage) {
                    vProductStageReordered[vLastOpenStage] = mStatusList[i];
                } else if (mStatusList[i].stageNumber > vLastOpenStage) {
                    vProductStageReordered [(i + 1)] = mStatusList[i];
                } 
            }
            mStatusList.clear();
            mStatusList = new List<ProductStage>(vProductStageReordered);
        }*/

        System.debug('############## END reorderStages');
    }

    /*
    *   Returns true if product is stopped, false otherwise
    */  
    public Boolean getIsStopped() {
        return currentStage == AP_Constant.PRODUCT_STATUS_STOPPED;
    }

    /**
    * Get the stage of the product by name
    * Returns -1 if product stage is not in the configuration
    */
    /*public Integer getStageNumberByName(string pStageName) {
        System.Debug('############ getStageNumberByName ' + pStageName);
        if (pStageName != null && mStatusList != null) {
            for (ProductStage vStage : mStatusList) {
                if (pStageName == vStage.stageName) {
                    return vStage.stageNumber;
                }
            }
        }

        return -1;
    }*/

    /**
    * Returns the number of status
    */
    public Integer getNumberOfStatus() {
        return mStatusList.size();
    }


    /*
    * Return the number of stages to display (stopped is displayed only if stopped)
    */
    public Integer getNumberOfStagesToDisplay() {
        return  getIsStopped() ? getNumberOfStatus() : (getNumberOfStatus() - 1);
    }
}