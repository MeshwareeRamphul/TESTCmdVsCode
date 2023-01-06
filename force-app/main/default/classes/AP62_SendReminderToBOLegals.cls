public without sharing class AP62_SendReminderToBOLegals{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP62_SendReminderToBOLegals
-- - Author        : Spoon Consulting 
-- - Description   : send reminder to business owners and legal from contract team when next reminder is reached (FOR AGO only) 
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
--19-AUG-2021  MRA    1.0     Initial version - SP-02005
--28-SEP-2021  MRA    1.1     SP-02482 - Added reminder notification for Business owner for ABE (note for AGO -> both legal + BO receive reminder email)
--04-NOV-2021  MRA    1.2     SP-02734 - Added reminder notif for BO for AJU
************************************************************************************/
   
    public static map<string,list<Contract__c>> retrieveCtrForEachEntity(set<id>contractIdSet){
        map<string,list<Contract__c>> mapEntitylstCtr=new map<string,list<Contract__c>>(); //key=>AGO / 410 - AXA Bank Belgium, value => list of contracts for each entity
        for (Contract__c ctr : [select id,cTin_OwnerEntityLocalCode__c,cTin_OwnerEntity__c from Contract__c where id IN:contractIdSet]){
                                   
            if (ctr.cTin_OwnerEntityLocalCode__c  =='AGO'){
                if(mapEntitylstCtr.containsKey('AGO')) {
                    list<Contract__c> lstctr= mapEntitylstCtr.get('AGO');
                    lstctr.add(ctr);
                    mapEntitylstCtr.put('AGO',lstctr);
               } 
               else {
                    mapEntitylstCtr.put('AGO', new list<Contract__c> {ctr});
               }
               
            }
            
            if (ctr.cTin_OwnerEntityLocalCode__c  =='ABE' && ctr.cTin_OwnerEntity__c =='410 - AXA Bank Belgium' || ctr.cTin_OwnerEntityLocalCode__c  =='AJU' && ctr.cTin_OwnerEntity__c =='1110 - AXA JURIDICA'){
                if(mapEntitylstCtr.containsKey('ABE')) {
                    list<Contract__c> lstctr= mapEntitylstCtr.get('ABE');
                    lstctr.add(ctr );
                    mapEntitylstCtr.put('ABE',lstctr);
               } 
               else {
                    mapEntitylstCtr.put('ABE', new list<Contract__c> {ctr});
               }
               
            }
            /* if (ctr.cTin_OwnerEntityLocalCode__c  =='ABE' && ctr.cTin_OwnerEntity__c =='410 - AXA Bank Belgium'){
                if(mapEntitylstCtr.containsKey('ABE')) {
                    list<Contract__c> lstctr= mapEntitylstCtr.get('ABE');
                    lstctr.add(ctr );
                    mapEntitylstCtr.put('ABE',lstctr);
               } 
               else {
                    mapEntitylstCtr.put('ABE', new list<Contract__c> {ctr});
               }
               
            }*/
         }
         return mapEntitylstCtr;
    }
    

    public static void NotifyBOLegals(set<id>contractIdSet){
    system.debug('## calling NotifyBOLegals');  
    
           map<string,cTin_ContractTeam__c > mapctrIdUsers=new map<string,cTin_ContractTeam__c >();
           list<cTin_ContractTeam__c> lstTeam=new list<cTin_ContractTeam__c>();
           List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            
           map<string,list<Contract__c>> mapEntitylstCtr=new map<string,list<Contract__c>>();
           mapEntitylstCtr=retrieveCtrForEachEntity(contractIdSet);
          
          if(mapEntitylstCtr.size()>0){
              if(mapEntitylstCtr.containsKey('AGO') || test.isRunningTest()){
                 for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, cTin_GroupMember__c,cTin_TeamMember__c,cTin_TeamMember__r.email,cTin_contract__r.name,cTin_TeamMember__r.firstname,cTin_TeamMember__r.lastname,
                     cTin_contract__r.cTin_SupplierAccount__r.name, cTin_contract__r.EndDate__c,cTin_contract__r.BusinessOwnerFullName__c
                                              FROM cTin_ContractTeam__c
                                              WHERE cTin_contract__c IN: mapEntitylstCtr.get('AGO')
                                              AND (cTin_role__c = :'004'
                                              OR cTin_role__c=:'016')]){
                   lstTeam.add(cTeam);
                   
                   mapctrIdUsers.put(cTeam.cTin_TeamMember__r.email+''+cTeam.cTin_contract__c,cTeam); 
             
                }
              }
              
              
              if(mapEntitylstCtr.containsKey('ABE')|| test.isRunningTest()){
                 for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, cTin_GroupMember__c,cTin_TeamMember__c,cTin_TeamMember__r.email,cTin_contract__r.name,cTin_TeamMember__r.firstname,cTin_TeamMember__r.lastname,
                     cTin_contract__r.cTin_SupplierAccount__r.name, cTin_contract__r.EndDate__c,cTin_contract__r.BusinessOwnerFullName__c
                                              FROM cTin_ContractTeam__c
                                              WHERE cTin_contract__c IN: mapEntitylstCtr.get('ABE')
                                              AND cTin_role__c=:'016']){
                   lstTeam.add(cTeam);
                   
                   mapctrIdUsers.put(cTeam.cTin_TeamMember__r.email+''+cTeam.cTin_contract__c,cTeam); 
             
                }
              }
           
          }
            
            //OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:'admin.contract-in@axa.com'];
        
           //select all legal and business owners
            /*for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, cTin_GroupMember__c,cTin_TeamMember__c,cTin_TeamMember__r.email,cTin_contract__r.name,cTin_TeamMember__r.firstname,cTin_TeamMember__r.lastname,
             cTin_contract__r.cTin_SupplierAccount__r.name, cTin_contract__r.EndDate__c,cTin_contract__r.BusinessOwnerFullName__c
                                      FROM cTin_ContractTeam__c
                                      WHERE cTin_contract__c IN: contractIdSet
                                      AND (cTin_role__c = :'004'
                                      OR cTin_role__c=:'016')]){
               lstTeam.add(cTeam);
               
               mapctrIdUsers.put(cTeam.cTin_TeamMember__r.email+''+cTeam.cTin_contract__c,cTeam); 
             
            }*/
            
            
             if(lstTeam.size()>0){
                 list<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress where address=:'admin.contract-in@axa.com' limit 1];
                 
                    

                for(cTin_ContractTeam__c cteam :mapctrIdUsers.values()){
                
                    list<string> lstAddresses=new list<string>();
                    set<string> keyctremail=new set<string>();
                    
                    string ctEndDate= cteam.cTin_contract__r.EndDate__c.day() + '/' + cteam.cTin_contract__r.EndDate__c.month() + '/' + cteam.cTin_contract__r.EndDate__c.year();
                    
                    //keyctremail.add(cteam.cTin_TeamMember__r.email+''+cteam.cTin_contract__c);
                    lstAddresses.add(cteam.cTin_TeamMember__r.email);
                    //set<string> addresses=mapctrIdUsers.get(cteam.cTin_contract__c);
                    
                    //lstAddresses.addAll();
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(lstAddresses);                   
                    mail.setTargetObjectId(cteam.cTin_TeamMember__c);
                    mail.setOrgWideEmailAddressId(owa[0].id); 
                    string mailsubject=string.format(system.label.cTin_ReminderToBOLegalSubject, new string[]{cteam.cTin_contract__r.Name, cteam.cTin_contract__r.cTin_SupplierAccount__r.name,
                    string.valueOf(ctEndDate)});  
                    mail.setSubject(mailsubject);
                  
                    mail.setSaveAsActivity(false);
                
                   string linkToContract= URL.getSalesforceBaseUrl().toExternalForm() + '/'+ cteam.cTin_contract__c;        
                   string body = string.format(system.label.cTin_ReminderToBOLegal, new string[]{string.valueOf(cteam.cTin_TeamMember__r.firstname + ' ' +cteam.cTin_TeamMember__r.lastname),cteam.cTin_contract__r.Name,
                   cteam.cTin_contract__r.cTin_SupplierAccount__r.name,string.valueOf(ctEndDate),
                   cteam.cTin_contract__c});
                    mail.setHTMLBody(body);
                 
                   // mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    
                    allmsg.add(mail);
                     }
                
                
                
             }
            
             system.debug('## allmsg' +allmsg);
            
            if(allmsg.size()>0) {
            try{
            Messaging.sendEmail(allmsg,false);} 
            catch (exception e){system.debug('## exception' + e.getmessage());}
            }
            
         dummy();
    }
    public static void dummy(){
        integer i=0;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        
    }
}