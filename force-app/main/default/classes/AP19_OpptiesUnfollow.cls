public without sharing class AP19_OpptiesUnfollow {
	/*
	----------------------------------------------------------------------
	-- - Name          : AP19_OpptiesUnfollow
	-- - Author        : Eric Wartelle
	-- - Description   : if an opportunity get to stage opportunity lost or opportunity cancel
	--                   it's unfollower by all user
	-- Maintenance History:
	--
	-- Date         Name  Version  Remarks
	-- -----------  ----  -------  ---------------------------------------
	--              Eric   1.0      Initial version
	-- 09-SEP-2020  USA    1.1      SP-00321
	----------------------------------------------------------------------
	*/


	/**
    * ----------------------------------------------------------------------------------------------
    * get subscriptions related to the opportunities
    * ----------------------------------------------------------------------------------------------
    * @param    concernOppties Set<Id>    : set of opportunity IDs
    * ----------------------------------------------------------------------------------------------
    */
	public static List<EntitySubscription> getConcernSubscription(Set<Id> concernOppties){
		//System.debug call for debug log purpose
		System.debug(LoggingLevel.INFO, '## AP19_OpptiesUnfollow ## getConcernSubscription start');

		//Variable Declaration
		List<EntitySubscription> concernSubs = [SELECT Id From EntitySubscription WHERE parentID =: concernOppties LIMIT 1000];

		//System.debug call for debug log purpose
		System.debug(LoggingLevel.INFO, '## AP19_OpptiesUnfollow ## concernSubs.size() : ' + concernSubs.size());
		System.debug(LoggingLevel.INFO, '## AP19_OpptiesUnfollow ## getConcernSubscription end');

		//return the concern subscription
		return concernSubs;
	}


	/**
    * ----------------------------------------------------------------------------------------------
    * method deletes subscriptions to unfollow opportunities
    * ----------------------------------------------------------------------------------------------
    * @param    oppties Map<Id, Opportunity>    : list of oppties with status lost or cancelled
    * ----------------------------------------------------------------------------------------------
    */
	public static void unfollowOpportunities(Set<Id> setOppId){
		//list of all subscription concern by the oppties
		List<EntitySubscription> concernSubs = getConcernSubscription(setOppId);
		System.debug(LoggingLevel.INFO, '## AP19_OpptiesUnfollow ## unfollowOpportunities - concernSubs.size() : ' + concernSubs.size());	

		//Delete the select subs
		delete concernSubs;
	}
}