public class VFC51_SendTOPSMass {
      public List<Contract__c> selCtrLst{get;set;}
      public String ctrId{get;set;}

      // Constructor
      public VFC51_SendTOPSMass(ApexPages.StandardSetController cntlr){
           selCtrLst = cntlr.getSelected(); //get selected records from account list view
           system.debug('##selCtrLst '+selCtrLst );
           ctrId = '';  
           for(Contract__c ctr : [select id,name from Contract__c where id In: selCtrLst]){
               ctrId += ctr.Id+ ','; //build list of ids string concatenated with comma                         
            }
           //ctrId = ctrId.removeEnd(','); 
           ctrId += cntlr.cancel().getUrl();
      } 
        
      
     public PageReference redirectToLC(){
            system.debug('##ctrId '+ctrId );
            system.debug('**********'+ ctrId);
            String returnUrl = '/lightning/cmp/c__LC51_ProcessListViews?c__listOfContracts='+ctrId;
            //String returnUrl = '/one/one.app#/cmp/LC_ProcessListViews?listofContractss=ctrId' ;
            
            //String returnUrl = '/lightning/cmp/c__LC51_ProcessListViews';
            PageReference pgReturnPage = new PageReference(returnUrl);
            
            return pgReturnPage;
      }

  }