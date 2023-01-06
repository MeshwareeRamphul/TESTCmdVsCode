public without sharing class AP65_NotifExpiredEsig{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP65_NotifExpiredEsig
-- - Author        : Spoon Consulting 
-- - Description   : send reminder to contract owners 60 days after esignature is expired
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
--28-SEP-2021  MRA    1.0     SP-00273 - notification to contract owner when esignature expires
************************************************************************************/
   
    public static void notifyCtrOwners(set<id>setCtinExpiredEsign){
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            list<esignature__c > lstEsignature=new list<esignature__c >();
            map<string,string> mapAXAEsignatoryStatus=new map<string,string>();// key =>AXA + esignatureId , value => AXA esignatory status
            map<string,string> mapSupplierEsignatoryStatus=new map<string,string>();// key =>Supplier + esignatureId , value =>Supplier esignatory status
            map<id,esignature__c> mapEsignIdObj=new map<id,esignature__c>();// key =>esignatureId , value =>esignature
            
            for(esignature__c esign: [select Contract__r.id,Contract__r.cTin_OwnerEntityLocalCode__c,Contract__r.cTin_Reference__c, Contract__r.Owner.email,Contract__r.OwnerId,id,CreatedDate,Contract__c,Contract__r.Owner.name,Contract__r.name,Contract__r.startDate__c,Contract__r.endDate__c,
            Contract__r.cTin_AXAMainLegalSignatoryEntity__r.name,Contract__r.cTin_AXASignatoryRepresentative__r.name,Contract__r.cTin_SupplierSignatoryRepresentative__r.name,
            Contract__r.cTin_SupplierAccount__r.name from esignature__c where id IN:setCtinExpiredEsign]){
                mapEsignIdObj.put(esign.id,esign);
            }
            
            for(eSignatory__c esignatory: [select eSignature__c,status__c,eSignature__r.CreatedDate,Contract__c,Contract__r.Owner.name,Contract__r.name,Contract__r.startDate__c,Contract__r.endDate__c,
                                            Contract__r.cTin_AXAMainLegalSignatoryEntity__r.name,Contract__r.cTin_AXASignatoryRepresentative__r.name,Contract__r.cTin_SupplierSignatoryRepresentative__r.name,
                                            Contract__r.cTin_SupplierAccount__r.name from eSignatory__c where eSignature__c IN:setCtinExpiredEsign
                                            and cTin_OriginalRepresentative__c=:true]){
                   if(esignatory.Contract__r.cTin_AXASignatoryRepresentative__c!=null)                       
                     mapAXAEsignatoryStatus.put('AXA'+esignatory.eSignature__c,esignatory.status__c);    
                     
                   if(esignatory.Contract__r.cTin_SupplierSignatoryRepresentative__r!=null)                       
                     mapAXAEsignatoryStatus.put('Supplier'+esignatory.eSignature__c,esignatory.status__c);                     
            }
            
            list<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress where address=:'admin.contract-in@axa.com' limit 1];
             
            for(id esignId:setCtinExpiredEsign){
                    string esignStartDate= mapEsignIdObj.get(esignId).CreatedDate.day() + '/' + mapEsignIdObj.get(esignId).CreatedDate.month() + '/' + mapEsignIdObj.get(esignId).CreatedDate.year();
                    string esignEndDate= system.today().day() + '/' + system.today().month() + '/' + system.today().year();
                    string ctEndDate= mapEsignIdObj.get(esignId).Contract__r.EndDate__c.day() + '/' + mapEsignIdObj.get(esignId).Contract__r.EndDate__c.month() + '/' + mapEsignIdObj.get(esignId).Contract__r.EndDate__c.year();
                    string ctstartdDate= mapEsignIdObj.get(esignId).Contract__r.StartDate__c.day() + '/' + mapEsignIdObj.get(esignId).Contract__r.StartDate__c.month() + '/' +mapEsignIdObj.get(esignId).Contract__r.StartDate__c.year();
                    list<string>lstAddresses=new list<string>();
                    lstAddresses.add(mapEsignIdObj.get(esignId).Contract__r.Owner.email);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(lstAddresses);                   
                    mail.setTargetObjectId(mapEsignIdObj.get(esignId).contract__r.OwnerId);
                    mail.setOrgWideEmailAddressId(owa[0].id); 
                    string mailsubject='Expired Esignature';
                    string mailsubjectADE='Contract-In Warnung: Die Gültigkeit der elektronische Unterschrift des Vertrags'+ mapEsignIdObj.get(esignId).contract__r.name +'ist abgelaufen.';
                    //string mailsubject=string.format(system.label.cTin_EmailSubjectExpiredEsignature, new string[]{string.valueOf(mapEsignIdObj.get(esignId).Contract__r.name)});
                      
                   
                  
                    mail.setSaveAsActivity(false);
                
                    string body='';
                   //string linkToContract= URL.getSalesforceBaseUrl().toExternalForm() + '/'+ cteam.cTin_contract__c;
                   if (mapEsignIdObj.get(esignId).Contract__r.cTin_OwnerEntityLocalCode__c == 'ACH') {
                    mail.setSubject(mailsubject);
                    body = string.format(system.label.cTin_EmailBodyExpiredEsignature, 
                    new string[]{string.valueOf(mapEsignIdObj.get(esignId).Contract__r.Owner.name),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.name),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.cTin_Reference__c),
                    string.valueOf(ctEndDate),
                    string.valueOf(ctstartdDate),
                    string.valueOf(esignStartDate),
                    string.valueOf(esignEndDate),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.cTin_AXAMainLegalSignatoryEntity__r.name),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.cTin_AXASignatoryRepresentative__r.name),
                    string.valueOf(mapAXAEsignatoryStatus.get('AXA'+esignId)),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.cTin_SupplierAccount__r.name),
                    string.valueOf(mapEsignIdObj.get(esignId).Contract__r.cTin_SupplierSignatoryRepresentative__r.name)
                    //string.valueOf(mapAXAEsignatoryStatus.get('Supplier'+esignId))
                    });
                   } else if (mapEsignIdObj.get(esignId).Contract__r.cTin_OwnerEntityLocalCode__c == 'ADE') {
                    mail.setSubject(mailsubjectADE);
                    body = string.format(system.label.cTin_EmailBodyExpiredEsignature_ADE, 
                    new string[]{string.valueOf(mapEsignIdObj.get(esignId).Contract__r.Owner.name),string.valueOf(mapEsignIdObj.get(esignId).Contract__r.name),string.valueOf(mapEsignIdObj.get(esignId).Contract__r.id)
                    });
                   }    
                   mail.setHTMLBody(body);
                   allmsg.add(mail);
            
            }
            
            if(allmsg.size()>0) {
            try{
            Messaging.sendEmail(allmsg,false);} 
            catch (exception e){system.debug('## exception' + e.getmessage());}
            }
           
           
            
            
    }
}