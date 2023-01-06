@isTest
public without sharing class VFC_SingTermsPolicy_TEST {
/*----------------------------------------------------------------------
-- - Name          : VFC_SingTermsPolicy_TEST
-- - Author        : Spoon
-- - Description   : test class for VFC_SingTermsPolicy
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 06-JAN-2022  HSO  1.0      Initial version 
-------------------------------------------------------------------------*/

    static User userAdmin;
    static Site site;
    static List<User> lstUser = new List<User>();
    static List<Account> lstAccount, lstAccount2;
    static List<Contact> lstContact = new list<Contact>();
    static Map<String, RecordType> mapSE;
    static Map<String, RecordType> mapRT;
	static Map<String, RecordType> mapContactRT;
    static String buttonAction;

    static{
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name = 'AXA GO France'].Id;
        
        userAdmin = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        userAdmin.UserRoleId = userRoleId;

        insert userAdmin;

        System.runAs(userAdmin){
            // RecordType
            mapSE = AP_Constant.getRecordTypes('Sourcing_Event__c');
            mapRT = AP_Constant.getRecordTypes('Account');
            mapContactRT = AP_Constant.getRecordTypes('Contact');

            // Accounts
            lstAccount = TestFactory.createAccount(5, mapRT.get('cTin_Supplier').id);
            lstAccount2 = TestFactory.createAccount(3, mapRT.get('cTin_AXA').id);

            // Contacts
            Contact con1 = TestFactory.createContact(lstAccount[0],'James','Brown');
            con1.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con1.Email = 'test1jamesbrown@gmail.com';
            
            Contact con2 = TestFactory.createContact(lstAccount[1],'Kim','Jah');
            con2.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con2.Email = 'test2kimjah@gmail.com';

            Contact con3 = TestFactory.createContact(lstAccount[2],'agrad','skaiz');
            con3.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con3.Email = 'test3agradskaiz@gmail.com';

            Contact con4 = TestFactory.createContact(lstAccount[3],'Jay','Jay');
            con4.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con4.Email = 'test4jayjay@gmail.com';

            Contact con5 = TestFactory.createContact(lstAccount[4],'John','cena');
            con5.recordTypeId = mapContactRT.get('cTin_Supplier').Id;
            con5.Email = 'test5johncena@gmail.com';
            

            lstContact.add(con1);
            lstContact.add(con2);
            lstContact.add(con3);
            lstContact.add(con4);
            lstContact.add(con5);

            insert lstContact;

            //Profile
            Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :AP_Constant.esourcingVendorProfile];

            //Users
            lstUser.add(TestFactory.createUser('Testuser1', profile.Id, true));
            lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser3', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser4', UserInfo.getProfileId(), true));
            lstUser.add(TestFactory.createUser('Testuser4', UserInfo.getProfileId(), true));
            
            lstUser[0].ContactId = lstContact[0].Id;
            lstUser[0].IsActive = true;

            insert lstUser;
        }
    }

    @isTest
    static void processCommandLink_NextButton_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                 VFC_SingTermsPolicy st = new VFC_SingTermsPolicy();
                st.buttonAction = 'Next_TermCondition';
                st.agree = true;
                PageReference pg = st.processCommandLink();
            Test.stopTest();

            User user = [SELECT Id, TermsOfService__c FROM User WHERE Id = :lstUser[0].Id];
            System.assertEquals(true, user.TermsOfService__c);

            String redirectTo = st.portalURL + '/VFP_Sing_PrivacyPolicy';
            System.assertEquals(redirectTo, pg.getUrl());
        }
    }

    @isTest
    static void processCommandLink_FinishButton_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                VFC_SingTermsPolicy st = new VFC_SingTermsPolicy();
                st.buttonAction = 'Next_PrivacyPolicy';
                st.agree = true;
                PageReference pg = st.processCommandLink();
            Test.stopTest();

            User user = [SELECT Id, AgreedToPolicy__c FROM User WHERE Id = :lstUser[0].Id];
            String redirectTo = st.portalURL;

            System.assertNotEquals(null, user);
            System.assertEquals(true, user.AgreedToPolicy__c);
            System.assertEquals(redirectTo, pg.getUrl());
        }
    }

    @isTest
    static void processCommandLink_NoButton_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                VFC_SingTermsPolicy st = new VFC_SingTermsPolicy();
                st.buttonAction = '';
                PageReference pg = st.processCommandLink();
            Test.stopTest();

            String redirectTo = st.portalURL + '/VFC_SingTermsPolicyDecline';

            System.assertEquals(redirectTo, pg.getUrl());
        }
    }

    @isTest
    static void checkTerm_Agree_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                VFC_SingTermsPolicy st = new VFC_SingTermsPolicy();
                st.checkbox = 'agree1';
                st.agree = true;
                PageReference pg = st.checkTerm();
            Test.stopTest();

            String redirectTo = st.portalURL + '/VFP_SingTermsPolicy';

            System.assertEquals(redirectTo, pg.getUrl());
            System.assertEquals(false, st.agree);
        }
    }

    @isTest
    static void checkTerm_NotAggree_Test(){
        System.runAs(lstUser[0]){
            Test.startTest();
                VFC_SingTermsPolicy st = new VFC_SingTermsPolicy();
                st.checkbox = 'agree1';
                st.agree = false;
                PageReference pg = st.checkTerm();
            Test.stopTest();

            String redirectTo = st.portalURL + '/VFP_SingTermsPolicy';

            System.assertEquals(redirectTo, pg.getUrl());
            System.assertEquals(true, st.agree);
        }
    }
}