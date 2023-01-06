public class AP67_ShareSEwithUser {
    
    @InvocableMethod(label='Share Event' description='Share Sourcing Event for the new user')
    public static void createSourcingEventShare(List<User> lstUser){
        AP05_Sing_mangageEventTeam.shareWithPortalNewUsers(lstUser);
    }
}