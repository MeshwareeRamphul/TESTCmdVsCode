@isTest
public class WS06_BatchRenewMaamToken_Test {

    static User adminUser;
    static MaaMAuthToken__c maamTokenTest;
    static String access_token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkFUMjAxODA0MjMifQ.eyJhdWQiOiJzYWxlc2ZvcmNlX3Blb3BsZXNvZnQiLCJybG0iOiJjbGllbnQiLCJjZWkiOiIxMThhNjdlZSIsInNjb3BlIjoidXJuOmF4YTpmcmFuY2U6c2FsZXNmb3JjZSIsImlzcyI6Imh0dHBzOlwvXC9tYWFtLWRldi5heGEuY29tXC9tYWFtXC92MiIsImV4cCI6MTYzNTQxNzkxNSwiaWF0IjoxNjM1NDE0MzE1LCJqdGkiOiJmYzYzNjU3MC0xYTc5LTQwZjctODIyYy05YTk4YmFlNjAyNDIiLCJjbGllbnRfaWQiOiIxOWQ1MDY5ZiJ9.dS9KiS8oxGpWMjHYtHJVbtMhP4jdfrZJuIBrxMkAodOWBV7Mvlf2xR0l0ZZ_fzaAN8Q813BgzWwEQbib6r1TrVK60UfGqup_yIlA_Lp09agtUi7DRK344aVPW85ZSbTs6qqSFC0e2tB6et7L8xMsRiDfki75e-aZCt_bDFoHL8lB3TlCeE8kcYfJtJJmCsnKUcJK-pIDuphVRWRCqeHPFJcrCRzVZNaj7qsycXSM_O1sX_8jyKaxVmgcuvPuueWUU64zkWqZcUFTNjzk-D8Sbcghd6Jh1lIkWNgdKdzB_n6WiPvzNC7TWdn2t-Nbfav2GRcAclL3LPElLTP0YcpfbQ';
    static String token = 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&scope=urn:axa:france:salesforce&grant_type=client_credentials&client_id=19d5069f&client_assertion=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxOWQ1MDY5ZiIsInN1YiI6IjE5ZDUwNjlmIiwiYXVkIjoiaHR0cHM6Ly9tYWFtLWRldi5heGEuY29tL21hYW0vdjIvdG9rZW4iLCJqdGkiOiJNanl1Q2U0MUc0U2ltTGwwIiwiZXhwIjoxNjM1NDIwMzE2fQ.NuqU87mReer4M6yjhJbeAgQF6o516ewitCPILkvWsFM';
    static CS_MAAMAuthentication__c cs;
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

        System.runAs(adminUser){
            //Create maam token
            maamTokenTest = new MaaMAuthToken__c(Access_token__c = access_token,Token__c = token, ClientID__c = 'abcdef12', Endpoint__c = 'https//axa.dev/test/endpoint');
            insert maamTokenTest;
            
            cs = new CS_MAAMAuthentication__c();
            cs.AUD__c = 'https://maam-dev.axa.com/maam/v2/token';
            cs.client_id__c = 'abcdef12';
            cs.client_secret__c = 'PJjSwhMDolnS1pmNSo9C032Bfb7olCLP0qzCSoALWyMyrwTYvvq7Mg';
            cs.ISS__c = 'abcdef12';
            cs.SUB__c = 'abcdef12';
            cs.Scope__c = 'urn:axa:france:salesforce'; 
            cs.SetupOwnerId = adminUser.Id;            
            insert cs;
        }
    }

    // start test
    @isTest 
    Public static void renewMaamTokenTest() {
        Test.setMock(HttpCalloutMock.class, new WS06_BatchRenewMaamTokenMock(200));
        System.runAs(adminUser) {        
            Test.startTest();
                
                WS06_BatchRenewMaamToken csStatus = new WS06_BatchRenewMaamToken();
                Database.executeBatch(csStatus);
                
            Test.stopTest();      
            
            MaaMAuthToken__c c = [SELECT Access_token__c, Token__c, Endpoint__c, TokenRenewalMessage__c FROM MaaMAuthToken__c][0];
            System.assertNotEquals(access_token ,c.access_token__c);
        }
    }

    // start test
    @isTest 
    Public static void renewMaamTokenErrorTest() {
        Test.setMock(HttpCalloutMock.class, new WS06_BatchRenewMaamTokenMock(501));
        System.runAs(adminUser) {        
            Test.startTest();
                
                WS06_BatchRenewMaamToken csStatus = new WS06_BatchRenewMaamToken();
                Database.executeBatch(csStatus);
                
            Test.stopTest();      
            
            MaaMAuthToken__c c = [SELECT Access_token__c, Token__c, Endpoint__c, TokenRenewalMessage__c FROM MaaMAuthToken__c][0];
            System.assert(c.TokenRenewalMessage__c.contains('Failed to renew token'));
        }
    }
}