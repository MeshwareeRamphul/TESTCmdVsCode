/**
 * <b>Class AP27_CreateUpdateMERO_TEST </b>: test class for AP27_CreateUpdateMERO
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */
@isTest
public class AP27_CreateUpdateMERO_TEST {
    

    static Account childEntity;
    static Account vEntity1;
    static Account vMEntity1;
    static User vUserPM1;
    static User vUserPM;
    static Product__c produit;
    static User adminUser;
    static User currentUser;
    
    static {
        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName(); //'userAdmin@User.com';
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        insert adminUser;
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        vUserPM.PAD_BypassWorkflows__c = true;
        update vUserPM;

        currentUser = [SELECT PAD_BypassValidationRules__c from User where Id = :adminUser.Id limit 1];
        currentUser.PAD_BypassValidationRules__c = true;
        update currentUser;  
		System.runAs(currentUser) {
            //product
            produit = AP05_TestDataFactory.createProduct(vUserPM);
            
            // Create the entity account
            vEntity1 = AP05_TestDataFactory.createEntityAccount(adminUser, 'testEntity');
            // Create the master entity account
            vMEntity1 = AP05_TestDataFactory.createMasterEntityAccount(adminUser, 'Master Entity');
            childEntity = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vEntity1);

        }
    }

    @isTest
    static void testCreateUpdateMero() {
        system.runAs(adminUser){

            Test.startTest();
                AP05_TestDataFactory.createEro(childEntity.Id , produit.Id , null , null);
            Test.stopTest();

        }
    }
}