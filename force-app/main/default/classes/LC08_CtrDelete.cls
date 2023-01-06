public with sharing class LC08_CtrDelete {  
	public static Boolean canDelete(Contract__c currentContract){
		System.debug('## VFC20_ContractDelete.canDelete - Start');
		Boolean contractDeletionFlag = DeletionPermissionFlag__c.getInstance(UserInfo.getUserId()).ContractDelete__c;
		System.debug( '## VFC20_ContractDelete.canDelete - End');
		return contractDeletionFlag;
	}

    @AuraEnabled   
	public static void deleteContract(String ctrId){
		System.debug('## LC08_CtrDelete.deleteContract - Start');

        Contract__c currentContract = new Contract__c();
   		try{
            currentContract = [SELECT Id, Status__c
                            FROM Contract__c
                            WHERE ID = :ctrId
                            LIMIT 1];     
    	}
    	catch(Exception ex){
    		system.debug('## error is ex :' + ex.getMessage());
    		system.debug('## error is ex :' + ex.getLineNumber());
    		system.debug('## error is ex type :' + ex.getTypeName());
    		throw new AuraHandledException(ex.getMessage()); 
        }

		if(canDelete(currentContract)){
            System.debug('## canDelete');
			try {
                delete currentContract;
                System.debug('## LC08_CtrDelete.deleteContract - Deleted');

            } catch (Exception e) {
                System.debug('catch');
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                throw new AuraHandledException(e.getMessage()); 
            }
		}
        else{
            System.debug('You don\'t have the right to delete that contract');
            throw new AuraHandledException( 'You don\'t have the right to delete that contract. You must used the Cancelled status instead.');
        }
	}
}