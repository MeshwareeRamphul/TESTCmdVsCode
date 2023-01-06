public without sharing class VFC38_ReminderToAprovers {
/*
----------------------------------------------------------------------
-- - Name          : VFC38_ReminderToAprovers 
-- - Author        : Spoon Consulting 
-- - Description   : class implements logic to query and send reminder to approvers who have pending approvals
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 08-AUG-2019  MRA    1.0      Intitial version 
(note cannot use existing email template because recipient is user and custom object not supported for whatid)
-- 29-JAN-2020  SGO     1.1     Lightning version
----------------------------------------------------------------------
**********************************************************************
*/

    public id contractFrmId{get;set;}
    public boolean isLightning{get;set;}
    public  list<cTin_contractForm__c> lstCF{get;set;}
    public boolean sendReminderSuccess{get;set;} // used to complete assertion in test class
     

    public String remindError{get;set;}

    // SGO - 29/01/2020 - Constructor for classic
    public VFC38_ReminderToAprovers (ApexPages.StandardController stdController) {
        sendReminderSuccess=false;
        contractFrmId=stdController.getId();
         
        lstCF=[select id,name,cTin_Reference__c,cTin_AXAMainSignatoryRepresentative__c,
                cTin_AXAMainLegalSignatoryEntity__c,cTin_SupplierSignatoryRepresentative__c,
                cTin_ShortDescription__c,cTin_KeyPoints__c,cTin_StartDate__c,cTin_EndDate__c,
                cTin_TotalSpendExcVAT__c,cTin_SupplierLegalSignatoryEntity__c,cTin_ParentContractName__c,
                Owner.Name,Owner.Title,Owner.Phone,Owner.Email,cTin_BusinessOwner__c,cTin_FinancialSpecificTerms__c,cTin_ParentContractReference__c,
                cTin_FinalApproval1__c,cTin_FinalApproval2__c,cTin_FinalApproval3__c,cTin_FinalApproval4__c,
                cTin_FinalApproval5__c,cTin_FinalApproval6__c,cTin_FinalApproval7__c,cTin_FinalApproval8__c,cTin_FinalApproval9__c,cTin_FinalApproval10__c
             from cTin_ContractForm__c where id =:contractFrmId];

         isLightning=false;
    }

    // SGO - 29/01/2020 - Constructor for LEX
    public VFC38_ReminderToAprovers(String contractFormId){
        this.sendReminderSuccess=false;
        this.contractFrmId=contractFormId;

        lstCF=[SELECT id,name,cTin_Reference__c,cTin_AXAMainSignatoryRepresentative__c,
                cTin_AXAMainLegalSignatoryEntity__c,cTin_SupplierSignatoryRepresentative__c,
                cTin_ShortDescription__c,cTin_KeyPoints__c,cTin_StartDate__c,cTin_EndDate__c,
                cTin_TotalSpendExcVAT__c,cTin_SupplierLegalSignatoryEntity__c,cTin_ParentContractName__c,
                Owner.Name,Owner.Title,Owner.Phone,Owner.Email,cTin_BusinessOwner__c,cTin_FinancialSpecificTerms__c,cTin_ParentContractReference__c,
                cTin_FinalApproval1__c,cTin_FinalApproval2__c,cTin_FinalApproval3__c,cTin_FinalApproval4__c,
                cTin_FinalApproval5__c,cTin_FinalApproval6__c,cTin_FinalApproval7__c,cTin_FinalApproval8__c,cTin_FinalApproval9__c,cTin_FinalApproval10__c
             FROM cTin_ContractForm__c WHERE id =:contractFrmId];

        isLightning=true;

    }

    //method queries pending approvals for specific contract form and notifies the approvers by email
    public PageReference sendReminder(){
        system.debug('### Starting method sendReminder');
        system.debug('### method sendReminder executed for contract form id'+contractFrmId);

        map<id, list<Id>> mapCfIdUserId= new map<id, list<Id>>();
        map<id, cTin_ContractForm__c> mapIdContractFrm=new map<id, cTin_ContractForm__c>();
        map<id, user> mapUsrIdEmail=new map<id, User>();
        set<id>setActorId=new set<id>();
        List<string> toAddress = new List<string>();
        List<ProcessInstanceWorkItem> lstProcessItems = new List<ProcessInstanceWorkItem>();
        AuraHandledException ex = new AuraHandledException(remindError);
        map<id,id> mapcfIdProcessId=new map<id,id>();
        try{
            lstProcessItems = [SELECT id, ProcessInstance.Status,ProcessInstance.TargetObjectId,ActorId
                                                FROM ProcessInstanceWorkItem
                                                WHERE ProcessInstance.TargetObjectId =: contractFrmId
                                                AND  ProcessInstance.Status = 'Pending'];
            if (lstProcessItems.size() < 1){
                if (isLightning){
                    remindError=System.label.cTin_NoPendingApproval;
                    ex.setMessage(remindError);
                    throw ex;
                }
                else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.label.cTin_NoPendingApproval));
                }
            }
        
            for(ProcessInstanceWorkItem  process: lstProcessItems){
                
                if(mapCfIdUserId.containsKey(process.ProcessInstance.TargetObjectId)) {   
                    List<Id> lstUsersId = mapCfIdUserId.get(process.ProcessInstance.TargetObjectId);        
                    lstUsersId.add(process.ActorId);       
                    mapCfIdUserId.put(process.ProcessInstance.TargetObjectId, lstUsersId );
                } 
                else {   
                    mapCfIdUserId.put(process.ProcessInstance.TargetObjectId, new List<Id> { process.ActorId });   
                }                 
                setActorId.add(process.ActorId);   
                mapcfIdProcessId.put(process.ActorId,process.Id);                                                          
            }
            
    
                
            for(User usr: [select id,email,name from User where id IN:setActorId]) {
                mapUsrIdEmail.put(usr.id,usr);
            }   
            
            List<Messaging.SingleEmailMessage> lstAllEmails = new List<Messaging.SingleEmailMessage>();
        
            Messaging.SingleEmailMessage mail; 
            //send reminder email to each approver with pending approvals
            if(setActorId.size()>0){
                for(Id cfId:mapCfIdUserId.keyset()){
                    list<id> lstUserId=new list<id>();
                    lstUserId=mapCfIdUserId.get(cfId);
                    //loop in list of users
                    for(Id userId: lstUserId){
                    
                        mail = new Messaging.SingleEmailMessage();
                        //toAddress.add(mapUsrIdEmail.get(userId).email);
                        mail.setToAddresses(new String[]{mapUsrIdEmail.get(userId).email});
                        mail.setSubject('Contract-in: Please review and approve the contract with '+ lstCF[0].cTin_SupplierLegalSignatoryEntity__c);
                        mail.setHTMLBody('<table style="border-collapse:collapse;border:none;mso-border-alt:solid windowtext .3pt;mso-yfti-tbllook:1184;"><tbody><tbody><tr><td style="width: 479.3pt; background: #a6a6a6; mso-background-themecolor: background1; mso-background-themeshade: 166; border: #f0f0f0; padding: 0cm 5.4pt 0cm 5.4pt;border:solid #A6A6A6 6.0pt;" width="689" valign="top"><p><img src="https://axags--AllInFull--c.cs108.content.force.com/servlet/servlet.ImageServer?id=0151p000004coYx&oid=00D1l0000000Q5r&lastMod=1518077321000" height="92"/> </td></p><tr><td style="padding: 0cm; border: 6pt solid #a6a6a6; width: 689pt; height: 13.55pt; background-color: transparent; mso-border-themecolor: background1; mso-border-themeshade: 166;" width="919" valign="top">'+
    string.format(system.label.cTin_ReminderEmail, 
                        new List<String>{String.valueOf(mapUsrIdEmail.get(userId).name),
                        string.valueOf(mapcfIdProcessId.get(userId)),                                       
                        string.valueOf(lstCF[0].cTin_SupplierLegalSignatoryEntity__c==''?'':lstCF[0].cTin_SupplierLegalSignatoryEntity__c),
                        String.valueOf(lstCF[0].name),
                        string.valueOf(lstCF[0].cTin_Reference__c == null ? '' : lstCF[0].cTin_Reference__c ),            
                        string.valueOf(lstCF[0].cTin_ShortDescription__c==null ? '' : lstCF[0].cTin_ShortDescription__c),
                        string.valueOf(lstCF[0].cTin_KeyPoints__c==null ? '':lstCF[0].cTin_KeyPoints__c ),
                        string.valueOf(lstCF[0].cTin_StartDate__c),
                        string.valueOf(lstCF[0].cTin_EndDate__c),
                        string.valueOf(lstCF[0].cTin_TotalSpendExcVAT__c )}) + '<tr><td style="padding: 0cm; border: 6pt solid #a6a6a6; width: 689pt; height: 13.55pt; background-color: transparent; mso-border-themecolor: background1; mso-border-themeshade: 166;" width="919" valign="top">'+
                        string.format(system.label.cTin_ReminderEmail_part2, new List<String>{
                        String.valueOf(lstCF[0].cTin_FinalApproval1__c== null? ' ' : lstCF[0].cTin_FinalApproval1__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval2__c==null? ' ' :lstCF[0].cTin_FinalApproval2__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval3__c==null ? ' ':lstCF[0].cTin_FinalApproval3__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval4__c==null? ' ' :lstCF[0].cTin_FinalApproval4__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval5__c==null? ' ':lstCF[0].cTin_FinalApproval5__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval6__c==null?' ' :lstCF[0].cTin_FinalApproval6__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval7__c==null? ' ' :lstCF[0].cTin_FinalApproval7__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval8__c==null? ' ':lstCF[0].cTin_FinalApproval8__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval9__c==null?' ': lstCF[0].cTin_FinalApproval9__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval10__c==null? ' ' :lstCF[0].cTin_FinalApproval10__c),
                        String.valueOf(lstCF[0].cTin_AXAMainSignatoryRepresentative__c==null? '' : '<p style="margin: 9pt 12pt;"> <b>AXA Signatory Representative: </b>' + lstCF[0].cTin_AXAMainSignatoryRepresentative__c ),
                        String.valueOf(lstCF[0].cTin_AXAMainLegalSignatoryEntity__c==null? '' : ' <b>representing </b>' +lstCF[0].cTin_AXAMainLegalSignatoryEntity__c),
                        String.valueOf(lstCF[0].cTin_SupplierSignatoryRepresentative__c ==null? '' :  '<b> Supplier Signatory Representative: ' +lstCF[0].cTin_SupplierSignatoryRepresentative__c + '</p>')
                        }) + '<p style="margin: 9pt 12pt;"><b>Contracting party: </b>'+lstCF[0].cTin_SupplierLegalSignatoryEntity__c +'</p><p style="margin: 9pt 12pt;"><b>Contracting Business owner: </b>'+lstCF[0].cTin_BusinessOwner__c+'</p><p style="margin: 9pt 12pt;"><b>Procurement owner: </b>'+lstCF[0].Owner.Name+'</p> <p style="margin: 9pt 12pt;"><b>Financial & Specific terms comments: </b>'+lstCF[0].cTin_FinancialSpecificTerms__c+'</p><p style="margin: 9pt 12pt;"><b>Parent contract Reference:  </b>'+lstCF[0].cTin_ParentContractName__c+'</p>'+
                        string.format(system.label.cTin_ReminderEmail_Part3, new List<String>{
                        string.valueOf(lstCF[0].Owner.Name==null? '': lstCF[0].Owner.Name), 
                        string.valueOf(lstCF[0].Owner.Title==null? '': lstCF[0].Owner.Title),
                        string.valueOf(lstCF[0].Owner.Phone==null? '': lstCF[0].Owner.Phone),
                        string.valueOf(lstCF[0].Owner.Email==null? '': lstCF[0].Owner.Email) })
                        /*string.format(system.label.cTin_ReminderEmail_part2, new List<String>{
                        String.valueOf(lstCF[0].cTin_FinalApproval1__c== null? ' ' : lstCF[0].cTin_FinalApproval1__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval2__c==null? ' ' :lstCF[0].cTin_FinalApproval2__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval3__c==null ? ' ':lstCF[0].cTin_FinalApproval3__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval4__c==null? ' ' :lstCF[0].cTin_FinalApproval4__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval5__c==null? ' ':lstCF[0].cTin_FinalApproval5__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval6__c==null?' ' :lstCF[0].cTin_FinalApproval6__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval7__c==null? ' ' :lstCF[0].cTin_FinalApproval7__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval8__c==null? ' ':lstCF[0].cTin_FinalApproval8__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval9__c==null?' ': lstCF[0].cTin_FinalApproval9__c),
                        String.valueOf(lstCF[0].cTin_FinalApproval10__c==null? ' ' :lstCF[0].cTin_FinalApproval10__c),
                        String.valueOf(lstCF[0].cTin_AXAMainSignatoryRepresentative__c==null? '' : lstCF[0].cTin_AXAMainSignatoryRepresentative__c ),
                        String.valueOf(lstCF[0].cTin_AXAMainLegalSignatoryEntity__c==null? '' : lstCF[0].cTin_AXAMainLegalSignatoryEntity__c),
                        String.valueOf(lstCF[0].cTin_SupplierSignatoryRepresentative__c ==null? '' :  lstCF[0].cTin_SupplierSignatoryRepresentative__c ),
                        string.valueOf(lstCF[0].Owner.Name==null? '': lstCF[0].Owner.Name),
                        string.valueOf(lstCF[0].Owner.Title==null? '': lstCF[0].Owner.Title),
                        string.valueOf(lstCF[0].Owner.Phone==null? '': lstCF[0].Owner.Phone),
                        string.valueOf(lstCF[0].Owner.Email==null? '': lstCF[0].Owner.Email) 
                        })*/
                    + '</td></tr></tbody></table>' );
        
                        
                        lstAllEmails.add(mail); 
                        
                        
                    
                    }
                    
                }
                
            }    
            
        
            
            if(lstAllEmails.size()>0){
                Messaging.sendEmail(lstAllEmails,true);
                sendReminderSuccess=true;
                if (!isLightning){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,System.label.cTin_ReminderSent));
                }
            }

        }
        catch(Exception e){      
            system.debug('###exception thrown' + e.getMessage());
            if (isLightning){
                remindError=e.getMessage();
                ex.setMessage(remindError);
                throw ex;
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Cannot send reminder'));
            }
            
        }
         
          
    PageReference pgRef=new PageReference ('/'+contractFrmId);
    pgRef.setredirect(true);
    return pgRef;
    }   
}