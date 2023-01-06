/**
 * @description       : 
 * @author            : ARA(anthony)
 * @group             : 
 * @last modified on  : 10-28-2021
 * @last modified by  : VMU
**/
@isTest
public class WS06_MaaMCallout_Test {
    
    static User adminUser;
    static CS_MAAMAuthentication__c cs;
    static MaaMAuthToken__c maam;    
    
    static{
        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName();
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();

        insert adminUser;
        system.runAs(adminUser){
            cs = new CS_MAAMAuthentication__c();
            cs.AUD__c = 'https://maam-dev.axa.com/maam/v2/token';
            cs.client_id__c = 'abcdef12';
            cs.client_secret__c = 'PJjSwhMDolnS1pmNSo9C032Bfb7olCLP0qzCSoALWyMyrwTYvvq7Mg';
            cs.ISS__c = 'abcdef12';
            cs.SUB__c = 'abcdef12';
            cs.Scope__c = 'urn:axa:france:salesforce'; 
            cs.SetupOwnerId = adminUser.Id;            
            insert cs;

            //now insert a maam record
            maam = new MaaMAuthToken__c();
            maam.ClientID__c = 'abcdef12';
            maam.Endpoint__c = 'https//axa.dev/test/endpoint';
            insert maam;            
        }
    }
    
    @isTest
    static void testPostCallout(){
        system.runAs(adminUser){
            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new WS06_MaaMCalloutMock());
            
                WS06_BatchRenewMaamToken b = new WS06_BatchRenewMaamToken (); 
                database.executebatch(b);
            Test.stopTest();
            //retrieved the generated access token
            MaaMAuthToken__c maamrecord = [select Access_token__c from MaaMAuthToken__c limit 1];
            System.assertEquals(maamrecord.Access_token__c, 'theaccesstoken');
        }
    }
}