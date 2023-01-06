/**
 * Schedulable class SCH01_AnnualEROsUpdate : a schedulable class to be run each year 
 * @Version : 1.0
 * @Author : Eric Wartelle
 * @VersionHistory :
 * 		- 1.0 : Initial Version 
 */
global class SCH01_AnnualEROsUpdate implements Schedulable {
	//Methods for the Schedulable Class
	/**
	 * Method execute : 
	 * @param sc SchedulaleContext :
	 */
	global void execute(SchedulableContext sc) {
		//What does the schedulable class need to do :
		//  -- Get all the ERO which have the New Live status
		//  -- Change the status of these EROs to Live
		//  -- Update in the database the EROs

		//System.debug call for debug logs
		System.debug(LoggingLevel.INFO, '##SCH01## SCH01_AnnualEROsUpdate Start');

		//Variables declarations
		List<ProductEntityLink__c> EROs = [SELECT Id, POS_Status__c, First_Release_Date__c FROM ProductEntityLink__c
							WHERE POS_Status__c = 'New live'];
		Date today = Date.today();					

		//For each ERO, we change the POS_Status__c if necessary.
		for(ProductEntityLink__c ERO : EROs){
			ERO.POS_Status__c = (today.year() >= (ERO.First_Release_Date__c.year() + 1)) ? 'Live' : 'New live';
		}

		//Database call
		update EROs;

		//System.debug call for debug logs
		System.debug(LoggingLevel.INFO, '##SCH01## SCH01_AnnualEROsUpdate End');
	}
}