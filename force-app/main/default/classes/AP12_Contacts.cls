public with sharing class AP12_Contacts {
	/**
    * Calculates and updates the CurrentValue__c of the PDFContractAttached object when a relevant Contact field is updated
    */
    
    public static void updateContactCurrentValuePDF(Map<Id, Contact> pOldContactMap, Map<Id, Contact> pContactMap) {
        
        List<ID> vContactsToUpdate = new List<ID>();     
        List<ID> vContractsToUpdate = new List<ID>();                
		
		// Selects Contact records where at least one of the fields on the PDF has changed 
		for (Contact vContact : pContactMap.values()) {	            
            if (vContact.Name != pOldContactMap.get(vContact.Id).Name || 
           		vContact.Title != pOldContactMap.get(vContact.Id).Title) {
             		vContactsToUpdate.add(vContact.Id);
            }
		}
		
		// Selects related Contract records with a PDF Attachment record and with editable status
		for (Contract__c vContract : [SELECT Id FROM Contract__c WHERE PDFContrAtt__c != null AND (CustomerSignedBy__c IN :vContactsToUpdate OR AXA_GS_Signed_By__c IN :vContactsToUpdate) AND Status__c !='Signed' AND Status__c !='Ended' AND Status__c !='Terminated' and Status__c !='Sent for Signature' and Status__c !='Ready for Signature']){
			vContractsToUpdate.add(vContract.Id);
		}
		
		AP12_PDFContractsAttached.updatePDFContractsAttachedCurrentValue (vContractsToUpdate);                 
    }
    
}