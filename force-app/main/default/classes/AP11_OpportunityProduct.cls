public class AP11_OpportunityProduct {
	
	public AP11_OpportunityProduct(){}

	/*
	* Check if the user is already a follower 
	*/
	/*public static boolean isSubscriptionAlreadyExist(Map<Id, EntitySubscription> pEntitySubscriptionList, Id pUserId, Id pParentId) {
		for (EntitySubscription vEntitySub : pEntitySubscriptionList.values()) {
			if (vEntitySub.subscriberId == pUserId && vEntitySub.parentId == pParentId) {
				return true;
			}
		}
		return false;
	}*/


	/*
	* Add the PO of the sub product to the followers of the opportunity
	*/
	/*public static void addPOAsFollowers(List<OpportunityProduct__c> pOpportunityProducts) {
		System.debug('###### >>> Starting addPOAsFollowers');
		List<Id> vOpportunityList = new List<Id>();
		List<Id> vProductList = new List<Id>();

		System.debug('###### >>> pOpportunityProducts : ' + pOpportunityProducts);

		for (OpportunityProduct__c vOptyProduct : pOpportunityProducts) {
			if (vOptyProduct.Opportunity__c != null) {
				vOpportunityList.add(vOptyProduct.Opportunity__c);
			}
			if (vOptyProduct.Product__c != null) {
				vProductList.add(vOptyProduct.Product__c);
			}
		}
		System.debug('###### >>> vOpportunityList : ' + vOpportunityList);

		if (vOpportunityList != null && vOpportunityList.size() > 0) {
			// Exisiting subscriptions for the opportunities
			Map<Id, EntitySubscription> vExistingSubscriptions = new Map<Id, EntitySubscription>(
					[SELECT ID, subscriberId, parentId FROM EntitySubscription WHERE parentID IN :vOpportunityList]);
			// Entity list to create
			List<EntitySubscription> vEntitySubsList = new List<EntitySubscription>();

			// Retrieve product owners
			Map<Id, Product__c> vProductsRetrieved = new Map<Id, Product__c>([SELECT Id, Product_Owner__c, Product_Owner__r.IsActive FROM Product__c WHERE ID IN:vProductList]);

			for (OpportunityProduct__c vOptyProduct : pOpportunityProducts) {
				
				System.debug('###### >>> vOptyProduct.Product__r.Product_Owner__c : ' + vOptyProduct.Product__r.Product_Owner__c);

				if (vOptyProduct.Product__c != null && vProductsRetrieved.get(vOptyProduct.Product__c).Product_Owner__c != null) {
					Id vProductOwnerId = vProductsRetrieved.get(vOptyProduct.Product__c).Product_Owner__c;

					System.debug('###### >>> vProductOwnerId : ' + vProductOwnerId);
					if (!isSubscriptionAlreadyExist(vExistingSubscriptions, vProductOwnerId, vOptyProduct.Opportunity__c) 
							&& vProductsRetrieved.get(vOptyProduct.Product__c).Product_Owner__r.IsActive) {
						EntitySubscription vEntitySubAssigned = new EntitySubscription();

						vEntitySubAssigned.parentId = vOptyProduct.Opportunity__c; 
						vEntitySubAssigned.subscriberId = vProductOwnerId;
						vEntitySubsList.add(vEntitySubAssigned);
					}
				}
			}

			System.debug('###### >>> vEntitySubsList : ' + vEntitySubsList);

			insert vEntitySubsList;
		}

		System.debug('###### >>> ENDING addPOAsFollowers');		
	}*/

}