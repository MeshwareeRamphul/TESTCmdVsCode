/**
 * Class AP18_UpdateEROsOnOpptiesWon : will pass all EROs concern by won oppties to planned if the EROs's
 * status is not Planned, New Lived or Lived
 * @Version Draft
 * @Author Eric Wartelle
 * @VersionHistory
 * - 1.0 : Initial Version
 * - 1.1 : Upgrade to take into account a finer grain.
 */
public with sharing class AP18_UpdateEROsOnOpptiesWon {
	//Attributs of AP18_UpdateEROsOnOpptiesWon


	//Constructors of AP18_UpdateEROsOnOpptiesWon
	public AP18_UpdateEROsOnOpptiesWon() {

	}

	//Methods of AP18_UpdateEROsOnOpptiesWon
	/**
	 * Method getConcernedEntitiesForOpptiesWon : will send the entity corresponding to the oppties with won status
	 * @param oppties List<Opportunity> : opportunities send by the trigger
	 * @return Set<Account> : Entities link to opportunities
	 */
	private static Set<Id> getConcernedEntitiesForOpptiesWon(List<Opportunity> oppties){
		//System.debug for debug logs
		System.debug(Logginglevel.INFO, '##AP18## getConcernedEntitiesForOpptiesWon Start');

		//Variables declaration
		Set<Id> concernedEntities = new Set<Id>();

		//For each oppties, we're putting the entity in the set
		for(Opportunity oppty : oppties){
			if(oppty.StageName == 'Opportunity Won'){
				concernedEntities.add(oppty.AccountId);
			}
		}

		//System.debug for debug logs
		System.debug(LoggingLevel.INFO, '##AP18## getConcernedEntitiesForOpptiesWon - concernedEntities.size ' + concernedEntities.size());
		System.debug(LoggingLevel.INFO, '##AP18## getConcernedEntitiesForOpptiesWon End');

		//Returning the concernedEntities
		return concernedEntities;
	}

	/**
	 * Method getConcernedEntitiesForOpptiesContracting : will send the entity corresponding to the oppties with
	 * contracting status.
	 * @param oppties
	 */
	private static Set<Id> getConcernedEntitiesForOpptiesContracting(List<Opportunity> oppties){
		//System.debug for debug logs
		System.debug(LoggingLevel.INFO, '##AP18## getConcernedEntitiesForOpptiesContracting Start');

		//Variables declaration
		Set<Id> concernedEntities = new Set<Id>();

		//For each oppties, we're putting the entity in the set
		for(Opportunity oppty : oppties){
			if(oppty.StageName == 'Contracting'){
				concernedEntities.add(oppty.AccountId);
			}
		}

		//System.debug for debug logs
		System.debug(LoggingLevel.INFO, '##AP18## getConcernedEntitiesForOpptiesWon - concernedEntities.size ' + concernedEntities.size());
		System.debug(LoggingLevel.INFO, '##AP18## getConcernedEntitiesForOpptiesContracting End');

		//Returning the concernedEntities
		return concernedEntities;
	}

	/**
	 * Method getConcernedProducts : return a product set corresponding to the opportunities
	 * @param oppties Map<Id, Opportunity> : opportunities send by the trigger
	 * @return set<Product__c> : the concerned product
	 */
	private static set<Id> getConcernedProducts(List<Opportunity> oppties){
		//Variables declaration
		Set<Id> productsSet = new Set<Id>();

		//For each oppty, will get the corresponding produc
		for(Opportunity oppty : oppties){
			productsSet.add(oppty.Product__c);
		}

		//Returning the products set
		return productsSet;
	}

	/**
	 * Method updateEROs : will update the corresponding ERO
	 * @param oppties Map<Id, Opportunity> : opportunities send by the trigger
	 * @return List<ProductEntityLink__c> : Updated ERO corresponding to the opportunities
	 */
	public static List<ProductEntityLink__c> updateEROs(List<Opportunity> oppties){
		//System.debug call for debug logs
		System.debug(LoggingLevel.INFO, '##AP18## updateEROs Start');

		//Variables declaration
		List<ProductEntityLink__c> updatedEROs = new List<ProductEntityLink__c>();

		//Will get the offers and the entities concern by the oppties
		Set<Id> concernedEntitiesForOpptiesWon = getConcernedEntitiesForOpptiesWon(oppties);
		Set<Id> concernedEntitiesForOpptiesContracting = getConcernedEntitiesForOpptiesContracting(oppties);
		Set<Id> concernedProducts = getConcernedProducts(oppties);

		//Will get all the ERO concern by the oppties at won status
		List<ProductEntityLink__c> EROsToBeUpdated = [SELECT Id, Product__c, Entity__c, POS_Status__c FROM ProductEntityLink__c
							WHERE Product__c IN :concernedProducts AND Entity__c IN :concernedEntitiesForOpptiesWon];
		//System.debug(Logginglevel.INFO, '##AP18## updateEROs - EROsToBeUpdated.size : ' + EROsToBeUpdated.size());
		for(ProductEntityLink__c ERO : EROsToBeUpdated){
			if((ERO.POS_Status__c != 'New live') || (ERO.POS_Status__c != 'Live')){
				ERO.POS_Status__c = 'New live';
				ERO.First_Release_Date__c = Date.today();
				updatedEROs.add(ERO);
			}
		}

		EROsToBeUpdated = [SELECT Id, Product__c, Entity__c, POS_Status__c FROM ProductEntityLink__c
							WHERE Product__c IN :concernedProducts AND Entity__c IN :concernedEntitiesForOpptiesContracting];
		//System.debug(Logginglevel.INFO, '##AP18## updateEROs - EROsToBeUpdated.size : ' + EROsToBeUpdated.size());
		for(ProductEntityLink__c ERO : EROsToBeUpdated){
			if((ERO.POS_Status__c != 'Planned') || (ERO.POS_Status__c != 'New live') || (ERO.POS_Status__c != 'Live')){
				ERO.POS_Status__c = 'Planned';
				updatedEROs.add(ERO);
			}
		}

		//System.debugs calls for debug log
		//System.debug(LoggingLevel.INFO, '##AP18## updateEROs - updatedEROs.size : ' + updatedEROs.size());

		//Will update the corresponding ERO
		Update updatedEROs;

		//System.debug call for debug logs
		//System.debug(LoggingLevel.INFO, '##AP18## udpateEROs End');

		//Returning the updated EROs
		return updatedEROs;
	}
}