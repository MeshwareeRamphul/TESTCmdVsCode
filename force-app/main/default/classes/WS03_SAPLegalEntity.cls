global class WS03_SAPLegalEntity {
/* 
--------------------------------------------------------------------------------------
-- - Name          : WS03_SAPLegalEntity
-- - Author        : NAP 
-- - Description   : Webservice to be called by EIP to create/update Legal Entity
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 27-JUN-2016  NAP    1.0     Initial version
-- 
--------------------------------------------------------------------------------------
*/
    webservice static List<wrapperResponse> upsertLegalEntity(list<wrapperParams> lstparams) {
        system.debug('##### Start of WS03_SAPLegalEntity.upsertLegalEntity');
        system.debug('##### lstparams: '+lstparams);
        List<wrapperResponse> lstResponses = new List<wrapperResponse>();
        wrapperResponse response;
        List<Account> lstLegalEntity = new List<Account>();
        List<Account> lstLegalEntitySAP = new List<Account>();
        List<Account> lstLegalEntityMDM = new List<Account>();
        map<integer,integer> mapType = new map<integer,integer>();
        Account acc; 
        integer counter = 0, counterSAP = 0, counterMDM = 0;
        for (wrapperParams wp: lstparams){
            acc = new Account(
                                Name = wp.LegalName,
                               // MDMLegalEntityCode__c = wp.LegalEntityId,
                                billingCountryCode = wp.Country,
                                billingStreet = wp.Street,
                                billingCity = wp.City,
                                billingPostalCode = wp.PostalCode, 
                                Language__c = wp.Language,
                                Email__c = wp.Email, // to be created
                                SAP_Account_Number__c = wp.Vendor,
                                VAT__c = wp.VAT,// to extent
                                GIE_AXA_GS_Member__c = ((wp.GIE==null)?'':((wp.GIE)?'Yes':'No')),
                                // = wp.TradingPartner;
                                Type = 'Legal Entity',
                                //Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC ,
                                recordtypeid = AP_Constant.getRecordTypes('Account').get('Legal_Entity').id
            );
            
            /////////////

		 	if(string.isNotBlank(wp.LegalEntityId)){
			    acc.MDMLegalEntityCode__c = wp.LegalEntityId.replaceall('&#39;','');
			    system.debug(acc.MDMLegalEntityCode__c);
			    acc.MDMLegalEntityCode__c = acc.MDMLegalEntityCode__c.replaceall('./LegalEntityID=','');
			    acc.MDMLegalEntityCode__c = acc.MDMLegalEntityCode__c.replaceall('\'','');
			    system.debug(acc.MDMLegalEntityCode__c);
			    lstLegalEntityMDM.add(acc);
			    mapType.put(counter,counterSAP);
			    counterSAP++;
		 	} 
		 	else{
		 		lstLegalEntitySAP.add(acc);
		 		mapType.put(counter,counterMDM);
		 		counterMDM++;
		 	}
            
            lstLegalEntity.add(acc);
            counter++;
            //////////////
         
            

        }
        
        if (lstLegalEntity.size() > 0){
                
            Database.UpsertResult[] lstLegalSAPUpdated,lstLegalMDMUpdated;
            if (lstLegalEntityMDM.size() > 0 ){
            	lstLegalMDMUpdated = Database.upsert(lstLegalEntityMDM,Account.MDMLegalEntityCode__c,false);
            }
            if (lstLegalEntitySAP.size() > 0 ){
            	lstLegalSAPUpdated = Database.upsert(lstLegalEntitySAP,Account.SAP_Account_Number__c,false);
            }

            for(integer j=0;j<lstLegalEntity.size();j++){
                response = new wrapperResponse();
                response.Vendor = lstLegalEntity[j].SAP_Account_Number__c;
				Database.UpsertResult updatedResult;
				
				if(string.isNotBlank(lstLegalEntity[j].MDMLegalEntityCode__c)){
					updatedResult = lstLegalMDMUpdated[mapType.get(j)]; 
				}
				else{
					updatedResult = lstLegalSAPUpdated[mapType.get(j)];
				}
			    	
				
                if(updatedResult.isSuccess()){
                    response.Status = 'OK';
                    response.Message = 'Legal entity created/updated in Salesforce';
                    response.SFDCID = updatedResult.Id;
                    System.debug('##sucess');
                }
                else{
                    string errorMessage ='';
                    for(Database.Error err : updatedResult.getErrors()) {
                        errorMessage +=err.getMessage()+' ';
                        System.debug('The following error has occurred.');                   
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                    response.Status = 'KO';
                    response.Message = errorMessage;
                }
                System.debug('response: '+response);
                lstResponses.add(response);
            }
            
        }
        System.debug('lstResponses: '+lstResponses);
        system.debug('##### End of WS03_SAPLegalEntity.upsertLegalEntity');
        return lstResponses;
    }
    
    global class wrapperParams{
        webservice String LegalName;
        webservice String LegalEntityId;
        webservice String Country;
        webservice String Street;
        webservice String City;
        webservice String PostalCode;
        webservice String Language;
        webservice String Email;
        webservice String Vendor;
        webservice String VAT;
        webservice boolean GIE;
        webservice String Trading;
    }
    
    global class wrapperResponse{
        webservice String Vendor;
        webservice String Status;
        webservice String Message;
        webservice String SFDCID; 
    }
    
    /*
WS03_SAPLegalEntity.wrapperParams legal = new WS03_SAPLegalEntity.wrapperParams();
list<WS03_SAPLegalEntity.wrapperParams> lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

    legal.LegalName='TEST Legal SC001';
    legal.Country='Mauritius';
    legal.Street='Street Test';
    legal.City='City Thuafd ifg';
    legal.PostalCode ='81456';
    legal.Language='English';
    legal.Email='test@testco.com';
    legal.Vendor='SC00001';
    legal.VAT='VAT SC001';
    legal.GIE=TRUE;
    legal.Trading='Trading';
    lstparams.add(legal);
list<WS03_SAPLegalEntity.wrapperResponse> response = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
    */
}