public without sharing class UserTriggerHandler {
    /*----------------------------------------------------------------------
    -- - Name          : UserTriggerHandler
    -- - Author        : Spoon
    -- - Description   : trigger handler for UserTrigger
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 18-JAN-2021  ARA    1.0      Initial version (SP-3219)
    -------------------------------------------------------------------------*/

    public static void afterUpdateHandler(map<Id,User> mapOldUser, map<Id,User> mapNewUser){
        List<User> lstUser = new List<User>();
        Profile vendorProfile = [SELECT Id FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile limit 1];

        //  18-JAN-2021 ARA Share Sourcing Event for new/activated user
        if(vendorProfile != null){
            for(User newUser : mapNewUser.values()){
                User oldUser = mapOldUser.get(newUser.Id);
                if((oldUser.AgreedToPolicy__c != newUser.AgreedToPolicy__c || oldUser.TermsOfService__c != newUser.TermsOfService__c) && newUser.IsActive && newUser.AgreedToPolicy__c && newUser.TermsOfService__c && newUser.ProfileId == vendorProfile.Id){
                    lstUser.add(newUser);
                }
            }
            if(lstUser.size() > 0){
                AP05_Sing_mangageEventTeam.shareWithPortalNewUsers(lstUser);
            }
        }
    }
}