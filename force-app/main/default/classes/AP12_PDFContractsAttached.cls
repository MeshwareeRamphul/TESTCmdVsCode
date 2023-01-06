public with sharing class AP12_PDFContractsAttached {	
	
	public static void updatePDFContractsAttachedCurrentValue(List<ID> pContractsToUpdate) {		

        Map<ID, String> vIdValuePDF = new Map<ID, String>();		
		
		//retrieves all relevant fields from contracts to be updated
	    List<Contract__c> vContrWithPInLi = [SELECT Account__r.BillingCity, Account__r.BillingCountry, Account__r.BillingPostalCode, Account__r.BillingStreet, Account__r.name, 
		     									Account__r.MSA__c, AXA_GS_Signed_By__r.Name, AXA_GS_Signed_By__r.Title, AXA_GO_Legal_Entity__c, CurrencyIsoCode, 
		     									CustomerSignedBy__r.Name, CustomerSignedBy__r.Title, EndDate__c, Global_Amount__c, Invoicing_Condition__c, 
		     									Invoicing_Method__c, Name, PDFContrAtt__c, /*product__r.Name, */Service_Started__c, Service_Type__c, InvoicingMethod__c,
		     									SOW_Operational__c, StartDate__c, Account__r.MSA_ATS_Reference__c, 
		     									(SELECT AmountIL__c, Description__c, Invoicing_Date__c, Percent__c, CurrencyIsoCode 
		     										FROM Planned_Invoicing_Lines2__r) 
	     									FROM Contract__c 
	     									WHERE Id IN :pContractsToUpdate
	     									AND Status__c !='Signed' AND Status__c !='Ended' AND Status__c !='Terminated']; //added this line of filter to eliminate an SOQL in previous class
	     
	    //serializes PDF and saves related PDFContractAttached Id on map
	    for (Contract__c contr: vContrWithPInLi){
		    vIdValuePDF.put(contr.PDFContrAtt__c,serializePDFContract(contr));		     
	     }
											
		//retrieves all records to be updated 
		List<PDFContractAttached__c> vPDFContractsAttRetrieved = new List<PDFContractAttached__c>([SELECT Id, CurrentValue__c, LastPDFValue__c, PDFStatus__c 
																								   FROM PDFContractAttached__c WHERE ID IN :vIdValuePDF.keySet()]);
		
		//changes lastPDFValue status changes 	
		for (PDFContractAttached__c p: vPDFContractsAttRetrieved){
			p.CurrentValue__c = vIdValuePDF.get(p.Id);
			if (p.LastPDFValue__c != vIdValuePDF.get(p.Id))	{
				system.debug('##updateAccountCurrentValuePDF## LastPDFValue__c not equal');
				p.PDFStatus__c='Not updated!';
			} else {
				system.debug('##updateAccountCurrentValuePDF## LastPDFValue__c equal');
				p.PDFStatus__c='Updated';
			}
		}
		update(vPDFContractsAttRetrieved);											     													
	}


	public static string serializePDFContract(Contract__c c) {
		string s;
		s = c.Account__r.BillingCity+'|'+c.Account__r.BillingCountry+'|'+c.Account__r.BillingPostalCode+'|'+c.Account__r.BillingStreet+'|'+c.Account__r.Name+'|'+c.Account__r.MSA__c+
		     	'|'+c.AXA_GS_Signed_By__r.Name+'|'+c.AXA_GS_Signed_By__r.Title+'|'+c.AXA_GO_Legal_Entity__c+'|'+c.CurrencyIsoCode+'|'+c.CustomerSignedBy__r.Name+
		     	'|'+c.CustomerSignedBy__r.Title+'|'+c.EndDate__c+'|'+c.Global_Amount__c+'|'+c.Invoicing_Condition__c+'|'+c.InvoicingMethod__c+'|'+c.Name+
		     	/*'|'+c.Product__r.name+*/'|'+c.Service_Started__c+'|'+c.Service_Type__c+'|'+c.SOW_Operational__c+'|'+c.StartDate__c+'|';
		    for (Planned_Invoicing_Line__c pils: c.Planned_Invoicing_Lines2__r){
		     	s = s + pils.AmountIL__c+'|'+ pils.Description__c+'|'+pils.Invoicing_Date__c+'|'+pils.Percent__c+'|'+pils.CurrencyIsoCode+'|';		
		    }
		return s;    
	}	   
}