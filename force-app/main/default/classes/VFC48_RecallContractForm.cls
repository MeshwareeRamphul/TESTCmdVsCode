public without sharing class VFC48_RecallContractForm{
/* 
  --------------------------------------------------------------------------------------
  -- - Name          : VFC48_RecallContractForm
  -- - Author        : Spoon
  -- - Description   : When esignature is cancelled => resets contract status to In Progress and recalls transactions
  --
  -- Maintenance History: 
  --
  -- Date         Name  Version  Remarks 
  -- -----------  ----  -------  -------------------------------------------------------
  -- 05-MAY-2020  MRA    1.0     Initial version (Bundle 3.3 => SP-00185)
  -- 11-Jun-2020  MRA    1.1     CR: Cancel esignature if not submitted yet (Bundle 3.4 =>SP-00319)
  *************************************************************************************/
  public boolean isLex{get;set;}
  public Id contractId {get; set;}
  public list<cTin_ContractForm__c > cform {get;set;}
  
  public VFC48_RecallContractForm(ApexPages.StandardController stdController) {
        isLex=false;            
        contractId= Apexpages.currentpage().getparameters().get('contractId');       
  }
  
  //for LEX 
  public VFC48_RecallContractForm(string ctrId){
        isLex=true;            
        contractId= ctrId;
  }

  public void processRecall(){
       list<contract__c> lstCtr=new list<contract__c>();
       
       list<cTin_ContractForm__c > cform = [select id, recordtypeId, cTin_Contract__c,cTin_ContractStatus__c,cTin_FinalApprovalStatus__c,cTin_ApprovalStatus1__c,cTin_ApprovalStatus2__c,cTin_ApprovalStatus3__c,cTin_ApprovalStatus4__c,cTin_ApprovalStatus5__c,cTin_ApprovalStatus6__c,cTin_ApprovalStatus7__c,cTin_ApprovalStatus8__c,cTin_ApprovalStatus9__c,cTin_ApprovalStatus10__c from  cTin_ContractForm__c where cTin_Contract__c=:contractId];
       list<esignature__c> lstesignature =[select id, Contract__c,status__c from esignature__c where Contract__c=:contractId and status__c=:'Created'];
       
       Contract__c ctr=new Contract__c(id=contractId , status__c='In Progress');
       lstCtr.add(ctr);
       
       cform[0].cTin_ContractStatus__c ='In Progress';
       cform[0].cTin_FinalApprovalStatus__c='';
       cform[0].cTin_ApprovalStatus1__c='';
       cform[0].cTin_ApprovalStatus2__c='';
       cform[0].cTin_ApprovalStatus3__c='';
       cform[0].cTin_ApprovalStatus4__c='';
       cform[0].cTin_ApprovalStatus5__c='';
       cform[0].cTin_ApprovalStatus6__c='';
       cform[0].cTin_ApprovalStatus7__c='';
       cform[0].cTin_ApprovalStatus8__c='';
       cform[0].cTin_ApprovalStatus9__c='';
       cform[0].cTin_ApprovalStatus10__c='';
       cform[0].recordtypeId=Schema.SObjectType.cTin_ContractForm__c .getRecordTypeInfosByName().get('In Progress').getRecordTypeId();
       update cform[0];
       
       if(lstCtr.size()>0){
       
          if(lstesignature.size()>0){
              lstesignature[0].status__c='Cancelled';
              update lstesignature[0];
              
              list<esignatory__c> lstesignatories=new list<esignatory__c>();
              
              for(esignatory__c esig :[select id,status__c,esignature__c from esignatory__c where esignature__c=:lstesignature[0].id]){
                  esig.status__c='Canceled';
                  lstesignatories.add(esig);
              }
              if(lstesignatories.size()>0)
                  update lstesignatories;
          }
          
          update lstCtr;
          ProcessInstanceWorkitem[] workItems = [SELECT Id
                                                 FROM ProcessInstanceWorkitem 
                                                 WHERE ProcessInstance.TargetObjectId = :cform[0].id
                                                 AND ProcessInstance.Status =: 'Pending'];
                if(workItems.size()>0){
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                    pwr.setComments('Rejected automatically due to the option "Back to In Progress');
                    pwr.setAction('Reject');
                    pwr.setWorkItemId(workItems[0].id);
                    Approval.ProcessResult result = Approval.process(pwr);
                } 
       }
  
  }
  
  public pageReference recallApproval(){
       processRecall();
       PageReference pageRef = new PageReference('/'+contractId);
       return pageRef;
  }
}