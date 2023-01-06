/**
 * This class is generic and can be called from Opportunity or case or any object with a process (business or support)
 */
public with sharing class VFC10_ContractProgressTracker {

    private sObject mSObject { get; set; } // sObject from the controller  
    public List<ProgressTrackerStatus__c> mStatusByProcess { get; set; } // List of CS depending on the support process
    // Id of the salesforce object from the page passed in parameter
    public Id mId { 
    	get; 
    	set {
    		mId = value;
	    	retrieveRecordFromId();
	    	retrieveCSConfiguration();    		
    	}
    }
    private String statusField { get; set; } // Status for case, stage for opportunity
    
    /*
    * Do nothing in constructor because actions must be done when id is set.
    */
    public VFC10_ContractProgressTracker() { }
    
    /**
    * Retrieve the record with the good fields
    */ 
    private void retrieveRecordFromId() {
    	System.debug('#################### mId : ' + mId);
    	Schema.SObjectType vsObjectType = mId.getSObjectType();
    	String vsObjectName = vsObjectType.getDescribe().getName();
		statusField = 'Status__c'; // TODO modify it if the need to share this controller between multiple object is done
        String vQuery = 'SELECT Id, RecordType.DeveloperName, RecordTypeId, ' + statusField + ' FROM ' + vsObjectName + ' WHERE Id = :mId';
		System.debug('############### vQuery : ' + vQuery);
        try{
            mSObject = database.query(vQuery);
        } catch(Exception e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical Error : Impossible to retrieve sObject : ' + mId));
        }
    }
    
    /*
    * Retrieve the custom setting configuration
    */
    public void retrieveCSConfiguration() { 
        RecordType vRT = (Recordtype)mSObject.getSObject('RecordType');
        System.debug('#################### RT : ' +  vRT);
    	if (mSObject != null && vRT != null) {  
            //System.debug('##EWA## Init status list');
	    	initStatusList(vRT.developerName);    		 
    	}
    }
    
    /**
    * Get status list from the custom setting 
    * @param : pRecordTypeId the record type Id  
    */
    public void initStatusList(String pRecordTypeName) {
    	mStatusByProcess = [SELECT Name, StatusMasterLabel__c, StatusOrder__c, IsFinalStage__c, DisplayOnlyOnMatch__c
                                FROM ProgressTrackerStatus__c 
                                WHERE RecordTypeName__c = :pRecordTypeName 
                                ORDER BY StatusOrder__c];
    	if (mSObject == null || mSObject.get(statusField) == null || mStatusByProcess == null || mStatusByProcess.size() == 0) {
            System.debug('##EWA## Error - mSObject : ' + mSObject + ' - mSObject.get(statusField) : ' + mSObject.get(statusField)
                + ' - mStatusByProcess : ' + mStatusByProcess + ' - mStatusByProcess.size() : ' + mStatusByProcess.size()
                + ' - pRecordTypeName : ' + pRecordTypeName );
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical Error : Status name in CS doesn\'t match with case status'));
    	} else {
            //removeUselessStatusAndReorder(mSObject.get(statusField) + '');
        } 
    }

    /*
    * Remove the useless status
    */
    /*public void removeUselessStatusAndReorder(String pCurrentStatusName) { 
        // First build the list of the status to keep (that's to say not display only on match and not final)
        List<ProgressTrackerStatus__c> vStatusToKeep = new List<ProgressTrackerStatus__c>();
        for (ProgressTrackerStatus__c vPTS : mStatusByProcess) {
            if (vPTS.DisplayOnlyOnMatch__c == false && vPTS.IsFinalStage__c == false) {
                vStatusToKeep.add(vPTS);
            }
        }
        System.debug('###################### vStatusToKeep : ' + vStatusToKeep);
        // Then check the status to check if it must be displayed
        ProgressTrackerStatus__c vCurrentStatus = getProgressStatusByName(pCurrentStatusName);
        System.debug('###################### vCurrentStatus : ' + vCurrentStatus);
        // First add the Display only on match status and reorder
        if (vCurrentStatus.DisplayOnlyOnMatch__c == true) {
            List<ProgressTrackerStatus__c> vAllStatusToKeep = vStatusToKeep.clone();
            vStatusToKeep.clear();
            for (ProgressTrackerStatus__c vPTS : vAllStatusToKeep) {
                if (vPTS.StatusOrder__c == vCurrentStatus.StatusOrder__c) { vStatusToKeep.add(vCurrentStatus);vPTS.StatusOrder__c++;vStatusToKeep.add(vPTS);
                } else {
                    if (vPTS.StatusOrder__c > vCurrentStatus.StatusOrder__c) { vPTS.StatusOrder__c++;
                    }
                    vStatusToKeep.add(vPTS);
                } 
            }
        }
        // Then add the final status
        if (vCurrentStatus.IsFinalStage__c == true) {
            vStatusToKeep.add(vCurrentStatus);
        } 
        System.debug('###################### vStatusToKeep : ' + vStatusToKeep);
        mStatusByProcess = vStatusToKeep;
    }*/
    
    /*
    * Return current status order
    */
    public Integer getCurrentStatusOrder() {
        String vCurrentStatus = mSObject.get(statusField) + '';
        ProgressTrackerStatus__c vCurrentPTStatus = getProgressStatusByName(vCurrentStatus);
        if (vCurrentPTStatus != null) {
            return Integer.valueOf(vCurrentPTStatus.StatusOrder__c);
        }
    	return -1;
    }
 
    
     /*
    * Return current status order
    */
    /*public Integer getLastStepOrder() {
    	if (mStatusByProcess == null) {	return 0;}
    	return mStatusByProcess.size(); // Because order Status start to 1
    }*/

    /*
    * Return the CS object from the name of the status
    */
    public ProgressTrackerStatus__c getProgressStatusByName(String pStatusName) {
        if (pStatusName == null) {return null;
        }

        for (ProgressTrackerStatus__c vStatusProcessLink : mStatusByProcess) {
            if (pStatusName == vStatusProcessLink.StatusMasterLabel__c) {return vStatusProcessLink;
            }
        }

        return null;
    }
    
}