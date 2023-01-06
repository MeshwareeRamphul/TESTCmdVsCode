public class VFC_SingLoginFlowController {
    public string currUserId{get;set;}
    public boolean AllowPortalAccess{get;set;}
    public list<User> lstUsr{get;set;}
    
    public VFC_SingLoginFlowController(){
        system.debug('## controller'+ UserInfo.getUserId());
        currUserId=UserInfo.getUserId();               
        lstUsr=[SELECT Id,TermsOfService__c, AgreedToPolicy__c, Sing_LegalNotice__c FROM User WHERE Id=:currUserId];
        
        system.debug('##TermsOfService__c'+lstUsr[0].TermsOfService__c);
        system.debug('##AgreedToPolicy__c '+lstUsr[0].AgreedToPolicy__c );
        system.debug('##Sing_LegalNotice__c '+lstUsr[0].Sing_LegalNotice__c );
        
        //FinishLoginFlowStartUrl();
    }
    
    
    public PageReference FinishLoginFlowStartUrl() {
        system.debug('## starting method FinishLoginFlowStartUrl');
        pageReference pg ;
        
        //redirect to portal home page if user has already accepted terms & policy
        if (lstusr[0].TermsOfService__c && lstusr[0].AgreedToPolicy__c/* && lstusr[0].Sing_LegalNotice__c*/){
           system.debug('## 1');
           // pg = new pageReference('https://esourcing-portalexperience.cs129.force.com/supplier/s');
           pg= Auth.SessionManagement.finishLoginFlow();

        }
        //redirect to terms and policy page if user has not yet accepted 
        else{
          system.debug('## 2');
          pg=Auth.SessionManagement.finishLoginFlow('/apex/VFP_Sing_TermsConditions');
        }
     
       return pg.setRedirect(true);
    }


    public PageReference FinishLoginFlowHome() {
        //do stuff
        
        //finish the login flow and send you the default homepage
        return Auth.SessionManagement.finishLoginFlow();
        //return new PageREference('https://esourcing-portalexperience.cs129.force.com/supplier');
    }
}