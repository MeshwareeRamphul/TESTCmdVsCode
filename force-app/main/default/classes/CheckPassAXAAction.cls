global class CheckPassAXAAction implements Auth.RegistrationHandler {

@InvocableMethod(label='Is valid login' description='Will indicate if non pass axa login, if used, is authorized. It will also indicate if a 2fa must be enforced or if the access must only be allowed from an internal network')
global static List<string> isValidAccess() {
User usr = [select No_PassAXA__c, Allow_Internet_Access__c from user where id=:userinfo.getUserId()];
Map<String, String> currentSession = tryGetCurrentSession();
return new List<string>{getAccessType(usr, currentSession)};
}

global User createUser(Id portalId, Auth.UserData data){
List<User> users = [select Id, No_Passaxa__c, Allow_Internet_Access__c from user where FederationIdentifier=:data.email and No_PassAXA__c=false];
    if(users.size()==0){
        system.debug('User with email' + data.email + ' was not found.');
        return null;
    }
    return users[0];
}
    
global void updateUser(Id userId, Id portalId, Auth.UserData data){
    //do not update user's data
}

global static string getAccessType(User usr, Map<String, String> currentSession){
if(!validatePassAXAAccess(usr, currentSession)){
system.debug('INVALID_ATTEMPT_TO_ACCESS_WITHOUT_PASSAXA');
return 'INVALID_ATTEMPT_TO_ACCESS_WITHOUT_PASSAXA';
}
if(usr.Allow_Internet_Access__c){
system.debug('MUST_ENFORCE_2FA_REGISTRATION');
return 'MUST_ENFORCE_2FA_REGISTRATION';
}
system.debug('MUST_ENSURE_INTERNAL_NETWORK');
return 'MUST_ENSURE_INTERNAL_NETWORK';
}
global static boolean validatePassAXAAccess(User usr, Map<String, String> currentSession){
boolean isPassAXA = currentSession.get('LoginType') == 'Third Party SSO';
boolean noPassAXAFlag = usr.No_PassAXA__c;
return isPassAXA || noPassAXAFlag;
}
private static Map<String, String> tryGetCurrentSession(){
//As it cannot be mocked, send hardcoded session variables when in the context of a test
if(Test.isRunningTest()){
Map<String, String> currentSession = new Map<String, String>();
currentSession.put('LoginType', 'dummy');
return currentSession;
}
return Auth.SessionManagement.getCurrentSession();
}
}