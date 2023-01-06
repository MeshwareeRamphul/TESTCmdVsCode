public without sharing class VFC22_SetStatus {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Apex class controller for VFP22_SetStatus
-- --NOTE: class is set to without sharing to allow non-admin + non submitters to recall approval process
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 10-MAY-2017  DMU/MRA   1.0     Initial version 
-- 01-NOV-2017  MRA       1.1     Updated method to cater for status updates when a transaction has multiple signatories   
-- 23-JUL-2018  USA       1.2     Updated method to cater for status updates when a transaction has multiple signatories (ALL IN & ATS)        
-- 26-JUL-2018  USA       1.3     ALLINFIN-528 : Notif de rejet de signature 
-- 29-APR-2020  MRA       1.4     SP-00239 (capture refusal comments on esignatory) - Applicable for cTin only
-- 30-MARS-2021 MRA       1.5     SP-01470 (capture rejection comments on esignature) - Applicable for opCo
-- 28-APR-2021  ARA       1.6     OpCo : SP-01470 (Add possibility for a signatory to reject a contract & indicate a comment)
--------------------------------------------------------------------------------------
**************************************************************************************/
    public string setCookie{get;set;}
    public Boolean isUpdCompleted {get;set;}    
    public String msgDisplay {get;set;} 
    public string tranId{get;set;}
    public string status{get;set;}
    public string signer{get;set;}
    public static id esignatoryId = 'a0SO0xxxxxxxxxx'; 
    public static boolean testError=false;
   /* public PageReference processEsgt (){
       system.debug('###### enter processEsgt ');
       system.debug('## parameters '+ apexpages.currentpage().getparameters());
       return null;
    }*/
   
   public PageReference processEsgt (){

        //setCookie='<script>setCookie()</script>';
        system.debug('###### enter processEsgt ');
        //cookie paraneters: name,value

       //  Cookie debug_logs = new Cookie('debug_logs','debug_logs=debug_logs,domain=.force.com',null,-1,false);
       //  ApexPages.currentPage().setCookies(new Cookie[]{debug_logs});
    

        //used to map esignatory and esignature status w.r.t to params received in url
        map<string,string> statusEsignatureMap=new map<string,string>{'0'=>'Created','1'=>'Expired','2'=>'Completed','3'=>'Cancelled','4'=>'Failed','5'=>'Pending-Validation'};
        map<string,string> statusEsignatoryMap=new map<string,string>{'1'=>'Cancelled','2'=>'Signed','3'=>'Cancelled','4'=>'Failed'};

        //ALLINFIN-528 : new map defined for status Rejected which applies only for AGS and ATS 
        map<string,string> statusEsignatureMapAGS=new map<string,string>{'0'=>'Created','1'=>'Expired','2'=>'Completed','3'=>'Rejected','4'=>'Failed','5'=>'Pending-Validation'};
        map<string,string> statusEsignatoryMapAGS=new map<string,string>{'1'=>'Cancelled','2'=>'Signed','3'=>'Rejected','4'=>'Failed'};
         
        list <eSignatory__c> esignatoryLst = new list<eSignatory__c>();
        map <id,eSignature__c> esignatureMap = new map<id,eSignature__c>();
        
         system.debug('## parameters '+ apexpages.currentpage().getparameters());
        //system.debug('## parameters '+ apexpages.currentpage().getparameters().get('refusalComment'));
        
        //the transaction id of the esignature
        tranId = apexpages.currentpage().getparameters().get('id'); 
        // the status of the esignature : 0-> ready, 1 ->expired, 2->completed , 3- Canceled , 4->Failed,  5->Pending
        status = apexpages.currentpage().getparameters().get('status'); 
        //the number of signers who signed
        signer = apexpages.currentpage().getparameters().get('signer'); 
        //error returned
        string errorMsg = apexpages.currentpage().getparameters().get('error'); 
        
        eSignatureLog__c esLog = new eSignatureLog__c(StepName__c = 'Updating Status', DateCall__c = Datetime.now());
        
        system.debug('## tranId '+ tranId );
        system.debug('## status '+ status );
        system.debug('## signer '+ signer );
         
        map<string, RecordType> rtEsignatureMap=AP_Constant.getRecordTypes('esignature__c');

        Id recordtypeIdReadOnly=(rtEsignatureMap.get(AP_Constant.recordTypeRO)).Id;
        Id recordtypeIdcTin_ReadOnly=(rtEsignatureMap.get(AP_Constant.cTin_recordTypecTinRO)).Id;//contractIn
        string esignatureId;
        string contractId;
        integer countSignatories; 
        
        if (string.isNotBlank(tranId) && string.isNotBlank(status) && string.isNotBlank(signer)){

            try{
                for(esignatory__c esignatory:[Select id, Status__c, eSignature__r.Status__c,cTin_RefusalComment__c,
                                             Order__c,eSignature__r.contract__c,eSignature__c, cTin_Role__c,
                                             esignature__r.cTin_TECH_IsContractIn__c,esignature__r.Number_of_signatories__c ,
                                             ContractAxaGOLegalEntity__c,Name__c,Contract_number__c,Contract_name__c,Contract__r.cTin_Owner__c,
                                             Contract__r.Global_Amount__c,Contract__r.Service_Type__c,Contract__r.StartDate__c,Contract__r.EndDate__c,
                                             Contract__r.Account__r.Name,SignURL__c,cTin_EntityNameTxt__c
                                             from eSignatory__c 
                                             where eSignature__r.ExternalId__c =: tranId 
                                             order by Order__c]){
                   //######## to delete
                   system.debug('##vfc22_usa## eSignatory__c ' + esignatory.Order__c);
                   if (esignatory.esignature__r.cTin_TECH_IsContractIn__c){
                    system.debug('##vfc22_usa## eSignatory__c is cTin');
                   }
                   else{
                    system.debug('##vfc22_usa## eSignatory__c is not cTin');
                   }
                   //########

                   //Setting status for All-In
                   if(!esignatory.esignature__r.cTin_TECH_IsContractIn__c){
                        system.debug('## VFC22_setStatus: status updates for All In');
                        system.debug('## VFC22_setStatus: status : ' + status);
                        system.debug('## VFC22_setStatus: esignatory.order__c : ' + esignatory.order__c);
                        system.debug('## VFC22_setStatus: signer : ' + signer);
                        if(status=='1' || status =='3' || status=='4'){
                            if(status=='3'){
                                if (esignatory.order__c==(integer.valueOf(signer)+1)){                                   
                                    esignatory.status__c=statusEsignatoryMapAGS.get(status);
                                    //set esignature status to failed if validator rejects, else set to Rejected
                                    if(esignatory.cTin_Role__c== 'Validator')
                                      esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMapAGS.get('3'), SignatureDateTime__c=system.now()));  
                                    else
                                        esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMapAGS.get(status), RejectionComment__c= AP22_XmlRpcWrapper.GetRefusalComment(tranId), SignatureDateTime__c=system.now()));  
                                }
                                else{
                                    esignatory.status__c=AP_Constant.esignatoryStatusCancelled;
                                }
                                //if(esignatory.status__c!=AP_Constant.esignatoryStatusSigned){
                                //    esignatory.status__c=statusEsignatoryMapAGS.get(status);                                   
                                //    esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMapAGS.get(status),SignatureDateTime__c=system.now()));                     
                                //}
                            }else{
                                esignatory.status__c=statusEsignatoryMapAGS.get(status);                                   
                                esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMapAGS.get(status),SignatureDateTime__c=system.now()));                     
                            }
                        } 
                        //update 
                        else if(status=='2') {
                              if(esignatory.cTin_role__c != 'Validator')
                                esignatory.status__c=statusEsignatoryMapAGS.get(status); 
                            
                               esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMapAGS.get(status), recordtypeId=recordtypeIdReadOnly,SignatureDateTime__c=system.now(),cTin_SignatureDate__c=system.today()));
                        }
                        else{
                            //update signatory status to signed if signer=signatory.order
                            if(status=='0' && esignatory.order__c==integer.valueOf(signer)){
                                if(esignatory.cTin_role__c == 'Validator'){
                                    esignatory.status__c='Validated';
                                }else{
                                    esignatory.status__c=AP_Constant.esignatoryStatusSigned;
                                }
                               
                            }
                            //update signatory.status at order (signer+1) to ready if next signer
                            if(status=='0' && esignatory.order__c==(integer.valueOf(signer)+1)){
                              esignatory.status__c = AP_Constant.esignatoryStatusReady;
                              esignatory.NextReminder__c = Date.today().addDays(20);
                            }
                            //update signatory.status at order (signer+2) to Awaiting if previous signer is Ready 
                            if(status=='0' && esignatory.order__c==(integer.valueOf(signer)+2) && (integer.valueOf(signer)+2)
                                <=esignatory.eSignature__r.Number_of_signatories__c){
                              esignatory.status__c=AP_Constant.esignatoryStatusAwaiting; 
                            }
                        }
                    }else{
                          system.debug('## VFC22_setStatus: status updates for Contract-In');
                         if(status=='1' || status =='3' || status=='4'){
                            if(status=='3'){
                                if(esignatory.status__c!=AP_Constant.esignatoryStatusSigned){ 
                                    
                                system.debug('## VFC22_setStatus: esignatory1 : ' + esignatory.order__c+'****'+(integer.valueOf(signer)+1));
                                    if(esignatory.order__c==(integer.valueOf(signer)+1)){
                                        if (esignatory.cTin_Role__c== 'Validator'){
                                            esignatory.status__c='Rejected';
                                        }
                                        else {
                                            esignatory.status__c=statusEsignatoryMap.get(status);
                                            AP22_XmlRpcWrapper.CreateXmlRpcForRefusalComment(tranId ,esignatory.eSignature__c,esignatory);
                                        }
                                    }                                       
                                    else{                                       
                                        esignatory.status__c=statusEsignatoryMap.get(status);                                                                                                                                                        
                                    }
                                    esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMap.get(status),SignatureDateTime__c=system.now()));
                                        //AP22_XmlRpcWrapper.CreateXmlRpcForRefusalComment(tranId ,esignatory.eSignature__c,esignatory);
                                   
                                }
                                    
                            }else{
                                esignatory.status__c=statusEsignatoryMap.get(status);                                   
                                esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMap.get(status),SignatureDateTime__c=system.now()));                     
                            }
                         } 
                         //update 
                         else if(status=='2') {
                               if(esignatory.cTin_Role__c== 'Validator')
                                 esignatory.status__c='Validated';
                               else
                                 esignatory.status__c=statusEsignatoryMap.get(status); 
                               esignatureMap.put(esignatory.eSignature__c,new Esignature__c (id = esignatory.eSignature__c, Status__c = statusEsignatureMap.get(status), recordtypeId=recordtypeIdcTin_ReadOnly,SignatureDateTime__c=system.now(),cTin_SignatureDate__c=system.today()));
                         }
                         else{
                            //update signatory status to signed if signer=signatory.order
                            if(status=='0' && esignatory.order__c==integer.valueOf(signer)){
                                if(esignatory.cTin_Role__c== 'Validator')
                                    esignatory.status__c='Validated';
                                else
                                  esignatory.status__c=AP_Constant.esignatoryStatusSigned; 
                            }
                            //update signatory.status at order (signer+1) to ready if next signer
                            if(status=='0' && esignatory.order__c==(integer.valueOf(signer)+1)){
                              esignatory.status__c=AP_Constant.esignatoryStatusReady; 
                            }
                            //update signatory.status at order (signer+2) to Awaiting if previous signer is Ready 
                            if(status=='0' && esignatory.order__c==(integer.valueOf(signer)+2) && (integer.valueOf(signer)+2)
                                <=esignatory.eSignature__r.Number_of_signatories__c){
                              esignatory.status__c=AP_Constant.esignatoryStatusAwaiting; 
                            }

                         }

                    }
                    esignatoryLst.add(esignatory); 
                    esignatureId=esignatory.eSignature__c; 
                    contractId= esignatory.eSignature__r.contract__c;              
                }
                
                update esignatoryLst;
                update esignatureMap.values();
 
                msgDisplay = 'OK';  
                esLog.ErrorMessages__c = 'OK'; 
                esLog.Response__c= 'params received: [ id: ' + tranId +' ] , [ status : '+ status + ' ] , [ signer: ' + signer + ' ] '; 

                if(testError == true && Test.isRunningTest()){
                    map<id,esignatory__c> esignatoryMap=new map<id,esignatory__c>();
                    esignatoryMap.put(esignatoryId,new esignatory__c());
                     update esignatoryMap.values();
                }
            }catch(Exception e){            
                msgDisplay = 'ERROR: ' + e.getMessage();
                esLog.ErrorMessages__c = 'ERROR: ' + e.getMessage();  
                esLog.Response__c= 'params received: [ id: ' + tranId +' ] , [ status : '+ status + ' ] , [ signer: ' + signer + ' ] ';               
            }
            esLog.eSignatureId__c=esignatureId;
            esLog.Contract_Id__c=contractId;
            insert esLog; 
        }
        else{           
            msgDisplay = 'ERROR: URL parameters cannot be blank. '+ (string.isNotBlank(tranId) ? '' : ' [transaction Id = null ] ')  + (string.isNotBlank(status) ? '' : ' [status = null] ')  + (string.isNotBlank(signer) ? '' : ' [signer = null ]');
        }       
        isUpdCompleted = true;  
        
       
        return null;
    }

}