/**
 * Class AP20_EROs : will store the methods call by the ProductEntityLink Trigger
 * @Version : Draft
 * @Author : Eric Wartelle
 * @VersionHistory :
 *  - 1.0 : initial version
 */
public with sharing class AP20_EROs {
	//Constructors AP20_EROs
	public AP20_EROs() {
		
	}

	//Methods AP20_EROs
	public static void UpdateEROsByDate(List<ProductEntityLink__c> newEROs){
		//System.debug call for debug log
		System.debug(LoggingLevel.INFO, '##AP20## UpdateEROsByDate Start');

		//Variables declaration
		Date currentDate = Date.today();

		//For each new ERO, we will update the status.
		for(ProductEntityLink__c newERO : newEROs){			
			if(newERO.First_Release_Date__c != null)
				newERO.POS_Status__c = (currentDate.year() < (newERO.First_Release_Date__c.year() + 1)) ?
											'New live' :
											'Live';
		}

		//System.debug call for debug log
		System.debug(LoggingLevel.INFO, '##AP20## UpdateEROsByDate End');
	}
}