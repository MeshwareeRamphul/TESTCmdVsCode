public with sharing class LC07_CtrCreateESignature {
    
    @AuraEnabled
    public static Object getStatut(Id cID) {
    	Contract__c c = New Contract__c();

   		try{
            c = [SELECT Id, Status__c, Signature_Type__c, PDF_Status__c
                            FROM Contract__c
                            WHERE ID =:cID
                            LIMIT 1];     
            
           
            return c;
            
            
    	}
    	catch(Exception ex){
    		throw new AuraHandledException(ex.getMessage()); 
        }
	}
}