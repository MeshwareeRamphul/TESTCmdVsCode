public with sharing class AP12_Accounts {

	/**
    * Calculates and updates the CurrentValue__c of the PDFContractAttached object when a relevant Contract field is updated
    */
    
    public static void updateAccountCurrentValuePDF(Map<Id, Account> pOldAccountMap, Map<Id, Account> pAccountMap) {
        List<Id> lstIdRec = new List<Id>();
        for(RecordType rec : [SELECT Id FROM RecordType WHERE sObjectType = 'Contract__c' AND DeveloperName LIKE 'AXA_ATS%']){
            lstIdRec.add(rec.Id);
        }

        List<ID> vAccountsToUpdate = new List<ID>();         
        List<Id> vContractsToUpdate = new List<Id>();       
        //20180322 USA : ATS contracts 
        List<ID> vAccAtsToUpdate = new List<ID>(); 
        List<ID> vAllAccToUpdate = new List<ID>();        
		
		// Selects Account records where at least one of the fields on the PDF has changed 
		for (Account vAccount : pAccountMap.values()) {	            
            if (vAccount.BillingCity != pOldAccountMap.get(vAccount.Id).BillingCity || 
           		vAccount.BillingCountry != pOldAccountMap.get(vAccount.Id).BillingCountry || 
            	vAccount.BillingPostalCode != pOldAccountMap.get(vAccount.Id).BillingPostalCode || 
            	vAccount.BillingStreet != pOldAccountMap.get(vAccount.Id).BillingStreet ||
             	vAccount.MSA__c != pOldAccountMap.get(vAccount.Id).MSA__c) {	
             		vAccountsToUpdate.add(vAccount.Id);
            }
            if (vAccount.MSA_ATS_Reference__c != pOldAccountMap.get(vAccount.Id).MSA_ATS_Reference__c){
                vAccAtsToUpdate.add(vAccount.Id);
            }
		}
        system.debug('##updateAccountCurrentValuePDF## vAccountsToUpdate : ' + vAccountsToUpdate);
        system.debug('##updateAccountCurrentValuePDF## vAccAtsToUpdate : ' + vAccAtsToUpdate);

        vAllAccToUpdate.addAll(vAccountsToUpdate);
        vAllAccToUpdate.addAll(vAccAtsToUpdate);
        //vAccountsToUpdate.addAll(vAccAtsToUpdate);

        String strCtrQuery= '';
        strCtrQuery += 'SELECT id';
        strCtrQuery += ' FROM Contract__c';
        strCtrQuery += ' WHERE PDFContrAtt__c != null';
        strCtrQuery += ' AND Account__c IN ' +  '(\''+String.join(vAllAccToUpdate,'\',\'')+'\')' ;
        strCtrQuery += ' AND Status__c !=\'Signed\'';
        strCtrQuery += ' AND Status__c !=\'Ended\'';
        strCtrQuery += ' AND Status__c !=\'Terminated\'';
        if (vAccountsToUpdate.size() < 1){
            strCtrQuery += ' AND recordTypeId IN ' + '(\''+String.join(lstIdRec,'\',\'')+'\')'; 
        }
        if (vAccAtsToUpdate.size() < 1){
            strCtrQuery += ' AND recordTypeId NOT IN ' + '(\''+String.join(lstIdRec,'\',\'')+'\')'; 
        }

        system.debug('##updateAccountCurrentValuePDF## strCtrQuery : ' + strCtrQuery);
        for (contract__c ctr :database.query(strCtrQuery)){
            vContractsToUpdate.add(ctr.Id);
        }

		// Selects related Contract records with a PDF Attachment record and with editable status
		//for (Contract__c vContract : [SELECT Id 
  //                                    FROM Contract__c 
  //                                    WHERE PDFContrAtt__c != null 
  //                                    AND Account__c IN :vAccountsToUpdate 
  //                                    AND Status__c !='Signed' 
  //                                    AND Status__c !='Ended' 
  //                                    AND Status__c !='Terminated']){
		//	vContractsToUpdate.add(vContract.Id);
		//}
        system.debug('##updateAccountCurrentValuePDF## vContractsToUpdate : ' + vContractsToUpdate);
		
		AP12_PDFContractsAttached.updatePDFContractsAttachedCurrentValue (vContractsToUpdate);                 
    }
}