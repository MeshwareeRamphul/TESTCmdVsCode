public with sharing class AP13_Attachment {
	
	/*
	* Prevent deletion of attachment if is last pdf generated in contract
	*/
	public static void preventDeletion(Map<Id, Attachment> pAttachments) {
		System.debug('############# preventDeletion ');
		System.debug('############# pAttachments : ' + pAttachments);
		// Map of contracts attachments
		Map<Id, Attachment> vContractsAttachments = new Map<ID, Attachment>();
		// List of contracts scope
 		Set<Id> vContractsId = new Set<Id>();

		// FIll in the map of contracts attachments
		for (Attachment vAttachment : pAttachments.values()) {
			if (vAttachment.parentId != null) {
				if (vAttachment.parentID.getSObjectType() == Schema.Contract__c.getSObjectType()) {
					vContractsAttachments.put(vAttachment.Id, vAttachment);
					vContractsId.add(vAttachment.parentId);
				}
			}
		}

		// Get all contracts with their last uploaded attachment
		Map<Id, Contract__c> vContracts = new Map<Id, Contract__c>([SELECT Id, PDFContrAtt__r.Id, PDFContrAtt__r.TECH_AttachmentCreatedDate__c FROM Contract__c WHERE ID IN :vContractsId]);

		// Loop on contracts attachment and check if the attachment retrieved is the last one
		for (Attachment vAttachment : vContractsAttachments.values()) {
			// If attachment is the last one, then add error
			Contract__c vCurrentContract = vContracts.get(vAttachment.parentId);
			if (vCurrentContract.PDFContrAtt__c != null && vCurrentContract.PDFContrAtt__r.TECH_AttachmentCreatedDate__c != null) {
				System.debug('######################### vAttachment.CreatedDate : ' + vAttachment.CreatedDate);
				System.debug('######################### vCurrentContract.PDFContrAtt__r.TECH_AttachmentCreatedDate__c : ' + vCurrentContract.PDFContrAtt__r.TECH_AttachmentCreatedDate__c);
				if (vAttachment.CreatedDate == vCurrentContract.PDFContrAtt__r.TECH_AttachmentCreatedDate__c) {
					pAttachments.get(vAttachment.Id).addError(System.Label.Attachment_Err_DeletionForbidden);
				}
			}
		}
		System.debug('############# preventDeletion END ');
	}
}