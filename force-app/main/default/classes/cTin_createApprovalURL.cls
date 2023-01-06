public class cTin_createApprovalURL{
       public static String generateApprovalURL(String recordID){
         String url='';
         List<ProcessInstanceWorkitem > workItemLst = [SELECT id FROM ProcessInstanceWorkitem WHERE processInstance.TargetObjectId=:recordID];
            if(workItemLst.size() > 0){
               url='https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemLst[0].id;
            }
        return url;
      }
}