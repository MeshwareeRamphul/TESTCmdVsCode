/*----------------------------------------------------------------------
-- - Name          : SourcingEventTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for Sourcing_Event__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
--                     1.0      Initial version
-- 29-SEP-2021  ARA    1.1      SP-02598 check justification document before changing the sourcing event status to completed
-- 11-OCT-2021  MRA    1.2      Add business owner to sourcing team (on create of event / update of  BO)
-------------------------------------------------------------------------*/
public without sharing class AP60_ActivateParticipantUser {
    
    public static void handleActivation(String emailAdd, Account accId) {
        
        list<User> lstUsr = [SELECT id, email, isActive, contactId FROM User 
                             WHERE email = :emailAdd 
                             AND contactId != NULL 
                             AND isActive = true LIMIT 1];
        
        if(lstUsr.size() == 0){
            
            //break email for firstname and lastname
            String username = emailAdd;
            String leftPart = emailAdd.substringBefore('@');
            String[] leftPartSplitted = leftPart.split('\\.');
            String firstName = leftPartSplitted[0];
            String lastName = leftPartSplitted[1];
            
            
            Profile profCommunity = [SELECT id FROM profile WHERE name = :AP_Constant.userCommunity];
            
            User usrCommunity = new User(Username = username, Email = emailAdd, FirstName = firstname, LastName = lastname, 
                                         ProfileId = profCommunity.Id, TimeZoneSidKey = 'Europe/Paris');
            
            String networkId = Network.getNetworkId();
            
            //If using site to host the community the user should not hit s1 after logging in from mobile.
            if (networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                usrCommunity.put('UserPreferencesHideS1BrowserUI', true);
            }
            
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0, 1) : '') + lastname.substring(0, 1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1, 7);
            usrCommunity.put('CommunityNickname', nickname);
            
            String userId = '';
            
            try {
                //userId = Site.createExternalUser(usrCommunity, accId);
            }catch (Site.ExternalUserCreateException ex) {
                List<String> errors = ex.getDisplayMessages();
                for (String error : errors) {
                    System.debug(LoggingLevel.Error, 'Errrors:' + error);
                }
            }
        }
        
        
    }
    
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl, '');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
}