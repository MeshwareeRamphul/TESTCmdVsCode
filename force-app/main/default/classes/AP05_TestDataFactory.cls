@isTest
public class AP05_TestDataFactory {
    
    // Constant used to retrieve records
    public static String QUARTILE_NAME = 'testQuartile';
    public static String PETAL_NAME = 'testPetal';
    public static String OFFER_NAME = 'testOffer';
    public static String PRODUCT_NAME = 'testProduct';
    public static String ACCOUNT_NAME = 'AXA Group Operations'; //'GIE AXA GROUP SOLUTIONS';
    public static String ENTITY_NAME = 'AXA ENTITY';
    public static String MASTER_ENTITY_NAME = 'AXA MASTER ENTITY';
    public static String ACCOUNT_BILLINGSTREET = 'testAccountbillingstreet';
    public static String ACCOUNT_NEWBILLINGSTREET = 'ruesaintdidier';
    public static String ACCOUNT_SAPNUMBER = '234';
    public static String USER_OO_USERNAME = 'userOO@test.com';
    public static String USER_AXAGS_USERNAME = 'userAXAGS@test.com';
    public static String USER_MO_USERNAME = 'userMO@test.com';
    public static String USER_AM_USERNAME = 'userAM@test.com';
    public static String USER_PM_USERNAME = 'userPM@test.com';
    public static String USER_PMO_USERNAME = 'userPMO@test.com';
    public static String USER_PMOADV_USERNAME = 'userPMOADV@test.com';
    public static String USER_OPTYOWNER_USERNAME = 'userOptyOwner@test.com';
    public static String ATTACHMENT_NAME = 'Test attachment';
    public static String OPTY_NAME = 'OptyTest';
    public static String CONTACT_ENTITY_LAST_NAME = 'LastNameContact Entity';
    public static String CONTACT_ENTITY_TITLE = 'TitleContact Entity';
    public static String CONTACT_ENTITY_NEWTITLE = 'Freeloader';
    public static String CONTACT_EMAIL = 'entitycontact@test.com';
    public static String CONTACT_MobilePhone = '+331234567890';
    public static String CONTRACT_NAME = 'testContract';
    public static String CONTRACT_BU = 'BUContract';
    public static String CONTRACT_LEGAL_ENTITY = 'AXA Group Operations SAS'; // 'SAS';
    public static String CONTRACT_NEWLEGAL_ENTITY = 'GIE AXA Group Operations France';
    //public static String CONTRACT_STYPE_IMETHOD = 'BAU / At Cost (GIE)';
    public static String CONTRACT_STYPE_BAU = 'BAU';
    public static String CONTRACT_STYPE_PROJECT = 'Project';
    public static String CONTRACT_INVMETHOD_ATCOST = 'At Cost';
    public static String CONTRACT_INVMETHOD_FIXEDPRICE = 'Fixed Price';
    //public static String CONTRACT_STYPE_NEWIMETHOD = 'Project / At Cost (GIE)';
    public static String CONTRACT_PDFSTATUS_UPDATED = 'Updated';
    public static String CONTRACT_PDFSTATUS_NOTUPDATED = 'Not updated!';
    public static String PINVLINE_DESCRIPTION = 'Description1';
    public static Integer PINVLINE_AMOUNT = 100;
    public static Integer counter = 0;
    
    public static Date CONTRACT_INVPARAMDATE = Date.newInstance(2020, 2, 17);
    public static String CONTRACT_INVDATE = 'Invoicing Date';
    
    
    public static Opportunity createOpportunityStageCollect(Account pAccount, Product__c pProduct) {
        return createOpportunityStageCollect(pAccount, pProduct, OPTY_NAME);
    }
    
    public static Opportunity createOpportunityStageCollect(Account pAccount, Product__c pProduct, String pName) {
        Opportunity vOpty = new Opportunity();
        vOpty.AccountId = pAccount.Id;
        vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
        vOpty.closeDate = Datetime.now().date();
        vOpty.Name = pName;
        insert vOpty;
        
        if (pProduct != null) {
            vOpty.Product__c = pProduct.Id;
            update vOpty;
        }
        vOpty = [SELECT Id, AccountId, StageName, closeDate, Name, Product__c, Product__r.Id  FROM Opportunity WHERE ID = :vOpty.Id];
        
        return vOpty;
    }
    
    /* SGO - pInsert Boolean */
    public static Opportunity createOpportunity(Account pAccount, Product__c pProduct, String pName, Boolean pInsert) {
        Opportunity vOpty = new Opportunity();
        vOpty.AccountId = pAccount.Id;
        vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
        vOpty.closeDate = Datetime.now().date();
        vOpty.Name = pName;
        if (pProduct != null) {
            vOpty.Product__c = pProduct.Id;
        }
        if (pInsert){
            insert vOpty;
            //            vOpty = [SELECT Id, AccountId, StageName, closeDate, Name, Product__c, Product__r.Id  FROM Opportunity WHERE ID = :vOpty.Id];
            
        }
        
        return vOpty;
    }
    
  /*public static Opportunity createOpportunity2(Account pAccount, Offer__c pOffer, String pName, Boolean pInsert) {
        Opportunity vOpty = new Opportunity();
        vOpty.AccountId = pAccount.Id;
        vOpty.StageName = AP_Constant.STAGE_LEADS_GATHERING;
        vOpty.closeDate = Datetime.now().date();
        vOpty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(AP_Constant.RT_OPP_LIGHTNING_FULL_LABEL).getRecordTypeId(); // TODO add method with developer name
        vOpty.Name = pName;
        if (pOffer != null) {
            vOpty.Offer__c = pOffer.Id;
        }
        if (pInsert){
            insert vOpty;
            //            vOpty = [SELECT Id, AccountId, StageName, closeDate, Name, Product__c, Product__r.Id  FROM Opportunity WHERE ID = :vOpty.Id];
            
        }
        
        return vOpty;
    }*/
    
    public static User createAMUser() {
        // Get account manager profile
        Profile vProfileAM = [SELECT Id From Profile WHERE Name = :AP_Constant.ACCOUNT_MANAGER];
        
        //AccountModification_Flag__c CS; // = AccountModification_Flag__c.getValues();      
        
        // Create AM user
        User vUserAM = new User();
        vUserAM.Alias = 'user1';
        vUserAM.FirstName = 'userAM';
        vUserAM.LastName = 'test';
        vUserAM.Username = USER_AM_USERNAME;
        vUserAM.Email = 'userAM@User.com';
        vUserAM.EmailEncodingKey = 'ISO-8859-1';
        vUserAM.TimeZoneSidKey = 'Europe/Paris';
        vUserAM.LanguageLocaleKey = 'en_US';
        vUserAM.LocaleSidKey = 'fr_FR_EURO';
        vUserAM.ProfileId = vProfileAM.Id;
																												  
        insert vUserAM;
        //insert new AccountModification_Flag__c(SetupOwnerId=vUserAM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
        //insert vUserAM;

        return vUserAM;
    }
    
    public static User createOOUser() {
        // Get offer owner profile
        Profile vProfileOO = [SELECT Id From Profile WHERE Name = :AP_Constant.PRODUCT_OWNER];
        // Create OO user
        User vUserOO = new User();
        vUserOO.Alias = 'user2';
        vUserOO.FirstName = 'user_oo';
        vUserOO.LastName = 'test';
        vUserOO.Username = USER_OO_USERNAME;
        vUserOO.Email = 'user_oo@User.com';
        vUserOO.EmailEncodingKey = 'ISO-8859-1';
        vUserOO.TimeZoneSidKey = 'Europe/Paris';
        vUserOO.LanguageLocaleKey = 'en_US';
        vUserOO.LocaleSidKey = 'fr_FR_EURO';
        vUserOO.ProfileId = vProfileOO.Id;
        insert vUserOO;
        
        return vUserOO;
    }
    
    
    public static User createOOUser(String username, boolean insertFlag) {
        // Get offer owner profile
        Profile vProfileOO = [SELECT Id From Profile WHERE Name = :AP_Constant.PRODUCT_OWNER];
        // Create OO user
        User vUserOO = new User();
        vUserOO.Alias = 'user2';
        vUserOO.FirstName = 'user_oo';
        vUserOO.LastName = 'test';
        vUserOO.Username = username;
        vUserOO.Email = 'user_oo@User.com';
        vUserOO.EmailEncodingKey = 'ISO-8859-1';
        vUserOO.TimeZoneSidKey = 'Europe/Paris';
        vUserOO.LanguageLocaleKey = 'en_US';
        vUserOO.LocaleSidKey = 'fr_FR_EURO';
        vUserOO.ProfileId = vProfileOO.Id;
        if(insertFlag)
            insert vUserOO;
        
        return vUserOO;
    }
    
    public static User createPMOUser() {
        // Get offer owner profile
        Profile vProfilePMO = [SELECT Id From Profile WHERE Name = 'PMO'];
        // Create OO user
        User vUserPMO = new User();
        vUserPMO.Alias = 'userpmo';
        vUserPMO.FirstName = 'user_pmo';
        vUserPMO.LastName = 'test';
        vUserPMO.Username = USER_PMO_USERNAME;
        vUserPMO.Email = 'user_pmo@User.com';
        vUserPMO.EmailEncodingKey = 'ISO-8859-1';
        vUserPMO.TimeZoneSidKey = 'Europe/Paris';
        vUserPMO.LanguageLocaleKey = 'en_US';
        vUserPMO.LocaleSidKey = 'fr_FR_EURO';
        vUserPMO.ProfileId = vProfilePMO.Id;
        insert vUserPMO;
        
        return vUserPMO;
    }
    
    public static User createFuncAdminUser() {
        // Get offer owner profile
        Profile vProfileFAdmin = [SELECT Id From Profile WHERE Name = 'OpCo360 - Functional Admin'];
        // Create OO user
        User vUserFAdmin = new User();
        vUserFAdmin.Alias = 'userfad';
        vUserFAdmin.FirstName = 'user_funcAdmin';
        vUserFAdmin.LastName = 'test';
        vUserFAdmin.Username = 'user_funcAdmin@user.com';
        vUserFAdmin.Email = 'user_funcAdmin@user.com';
        vUserFAdmin.EmailEncodingKey = 'ISO-8859-1';
        vUserFAdmin.TimeZoneSidKey = 'Europe/Paris';
        vUserFAdmin.LanguageLocaleKey = 'en_US';
        vUserFAdmin.LocaleSidKey = 'fr_FR_EURO';
        vUserFAdmin.ProfileId = vProfileFAdmin.Id;
        insert vUserFAdmin;
        
        return vUserFAdmin;
    }
    
    public static User createPMOADVUser() {
        // Get offer owner profile
        Profile vProfilePMO = [SELECT Id From Profile WHERE Name = 'PMO - ADV'];
        // Create OO user
        User vUserPMO = new User();
        vUserPMO.Alias = 'useradv';
        vUserPMO.FirstName = 'user_adv';
        vUserPMO.LastName = 'test';
        vUserPMO.Username = USER_PMOADV_USERNAME;
        vUserPMO.Email = 'user_adv@User.com';
        vUserPMO.EmailEncodingKey = 'ISO-8859-1';
        vUserPMO.TimeZoneSidKey = 'Europe/Paris';
        vUserPMO.LanguageLocaleKey = 'en_US';
        vUserPMO.LocaleSidKey = 'fr_FR_EURO';
        vUserPMO.ProfileId = vProfilePMO.Id;
        insert vUserPMO;
        
        return vUserPMO;
    }
    
    public static User createMOUser() {
        // Get offer owner profile
        Profile vProfileMO = [SELECT Id From Profile WHERE Name = :AP_Constant.MARKETING_OFFICER];
        // Create OO user
        User vUserMO = new User();
        vUserMO.Alias = 'userMO';
        vUserMO.FirstName = 'userMO';
        vUserMO.LastName = 'userMO';
        vUserMO.Username = USER_MO_USERNAME;
        vUserMO.Email = 'userMO@Account.com';
        vUserMO.EmailEncodingKey = 'ISO-8859-1';
        vUserMO.TimeZoneSidKey = 'Europe/Paris';
        vUserMO.LanguageLocaleKey = 'en_US';
        vUserMO.LocaleSidKey = 'fr_FR_EURO';
        vUserMO.ProfileId = vProfileMO.Id;
        insert vUserMO;
        
        return vUserMO;
    }
    
    public static User createPMUser() {
        // Get offer owner profile
        Profile vProfilePM = [SELECT Id From Profile WHERE Name = :AP_Constant.PROJECT_MANAGER];
        // Create OO user
        User vUserPM = new User();
        vUserPM.Alias = 'userPM';
        vUserPM.FirstName = 'userPM';
        vUserPM.LastName = 'userPM';
        vUserPM.Username = USER_PM_USERNAME;
        vUserPM.Email = 'userPM@Account.com';
        vUserPM.EmailEncodingKey = 'ISO-8859-1';
        vUserPM.TimeZoneSidKey = 'Europe/Paris';
        vUserPM.LanguageLocaleKey = 'en_US';
        vUserPM.LocaleSidKey = 'fr_FR_EURO';
        vUserPM.ProfileId = vProfilePM.Id;
        insert vUserPM;
        
        return vUserPM;
    }
    
    //SGO - 2019/08/20 - Lightning user
    public static User createPMUserLightning(String COMPANY,Boolean bypassVR) {
        // Get offer owner profile
        Profile vProfilePM = [SELECT Id From Profile WHERE Name = :AP_Constant.PROJECT_MANAGER];
        // Create OO user
        User vUserPM = new User();
        vUserPM.Alias = 'userPM';
        vUserPM.FirstName = 'userPM';
        vUserPM.LastName = 'userPM';
        vUserPM.Username = USER_PM_USERNAME;
        vUserPM.Email = 'userPM@Account.com';
        vUserPM.EmailEncodingKey = 'ISO-8859-1';
        vUserPM.TimeZoneSidKey = 'Europe/Paris';
        vUserPM.LanguageLocaleKey = 'en_US';
        vUserPM.LocaleSidKey = 'fr_FR_EURO';
        vUserPM.ProfileId = vProfilePM.Id;
        vUserPM.PAD_BypassValidationRules__c=bypassVR;
        vUserPM.Company__c = COMPANY;
        insert vUserPM;
        
        return vUserPM;
    }
    
    public static User createPMUser(boolean PAD_BypassValidationRules) {
        // Get offer owner profile
        Profile vProfilePM = [SELECT Id From Profile WHERE Name = :AP_Constant.PROJECT_MANAGER];
        // Create OO user
        User vUserPM = new User();
        vUserPM.Alias = 'userPM';
        vUserPM.FirstName = 'userPM';
        vUserPM.LastName = 'userPM';
        vUserPM.Username = USER_PM_USERNAME;
        vUserPM.Email = 'userPM@Account.com';
        vUserPM.EmailEncodingKey = 'ISO-8859-1';
        vUserPM.TimeZoneSidKey = 'Europe/Paris';
        vUserPM.LanguageLocaleKey = 'en_US';
        vUserPM.LocaleSidKey = 'fr_FR_EURO';
        vUserPM.ProfileId = vProfilePM.Id;
        vUserPM.PAD_BypassValidationRules__c = PAD_BypassValidationRules;
        insert vUserPM;
        
        return vUserPM;
    }
    
    public static User createPMUser(String username, boolean insertFlag) {
        // Get offer owner profile
        Profile vProfilePM = [SELECT Id From Profile WHERE Name = :AP_Constant.PROJECT_MANAGER];
        // Create OO user
        User vUserPM = new User();
        vUserPM.Alias = 'userPM';
        vUserPM.FirstName = 'userPM';
        vUserPM.LastName = 'userPM';
        vUserPM.Username = username;
        vUserPM.Email = 'userPM@Account.com';
        vUserPM.EmailEncodingKey = 'ISO-8859-1';
        vUserPM.TimeZoneSidKey = 'Europe/Paris';
        vUserPM.LanguageLocaleKey = 'en_US';
        vUserPM.LocaleSidKey = 'fr_FR_EURO';
        vUserPM.ProfileId = vProfilePM.Id;
        if(insertFlag)
            insert vUserPM;
        
        return vUserPM;
    }
    
    public static User createOptyOwnerUser() {
        // Get opty owner profile
        Profile vProfileOptyOwner = [SELECT Id From Profile WHERE Name = :AP_Constant.OPTY_OWNER];
        // Create Opty O user
        User vUserOptyOwner = new User();
        vUserOptyOwner.Alias = 'userOpty';
        vUserOptyOwner.FirstName = 'userOptyOwner';
        vUserOptyOwner.LastName = 'userOptyOwner';
        vUserOptyOwner.Username = USER_OPTYOWNER_USERNAME;
        vUserOptyOwner.Email = 'userOptyOwner@Account.com';
        vUserOptyOwner.EmailEncodingKey = 'ISO-8859-1';
        vUserOptyOwner.TimeZoneSidKey = 'Europe/Paris';
        vUserOptyOwner.LanguageLocaleKey = 'en_US';
        vUserOptyOwner.LocaleSidKey = 'fr_FR_EURO';
        vUserOptyOwner.ProfileId = vProfileOptyOwner.Id;
        insert vUserOptyOwner;
        
        return vUserOptyOwner;
    }
    
    public static Account createEntityAccount(User pUserAM, String pName) {
        Account vAccount = new Account();
        vAccount.Name = (pName != null) ? pName : ENTITY_NAME;
        vAccount.OwnerId = pUserAM.Id;
        vAccount.Account_Manager__c = pUserAM.Id;
        vAccount.Active__c = true;
        vAccount.Show_In_POS__c = true;
        vAccount.Language__c = 'English';
        vAccount.GIE_AXA_GS_Member__c = 'No';
        vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
        insert vAccount;
        
        return vAccount;
    }
    
    public static list<Account> createEntityAccountList(User pUserAM, String pName,integer num) {
        list<Account> listacc = new list<Account>();
        for(integer i=0;i<num;i++){
            Account vAccount = new Account();
            vAccount.Name = pName+i;
            vAccount.OwnerId = pUserAM.Id;
            vAccount.Account_Manager__c = pUserAM.Id;
            vAccount.Active__c = true;
            vAccount.Show_In_POS__c = true;
            vAccount.Language__c = 'English';
            vAccount.GIE_AXA_GS_Member__c = 'No';
            vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
            listacc.add(vAccount);
        }
        
        return listacc;   
    }
    
    public static Account createEntityAccount(User pUserAM) {
        return createEntityAccount(pUserAM, null);
    }
    
    
    public static Account createLegalEntityAccount(User pUserPM) {
        return createLegalEntityAccount(pUserPM, null);
    }
    
    public static Account createLegalEntityAccount(User pUserPM, String pName) {
        Account vAccount = new Account();
        vAccount.Name = (pName != null) ? pName : ACCOUNT_NAME;
        vAccount.OwnerId = pUserPM.Id;
        vAccount.Account_Manager__c = pUserPM.Id;
        vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_LEGAL_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
        vAccount.SAP_Account_Number__c = ACCOUNT_SAPNUMBER;
        vAccount.Signature_Type__c = 'Manual';
        vAccount.Active__c = true;
        vAccount.Language__c = 'English';
        vAccount.GIE_AXA_GS_Member__c = 'No';
        insert vAccount;
        
        return vAccount;
    }
    
    public static Account createMasterEntityAccount(User pUserAM) {
        return createMasterEntityAccount(pUserAM, null);
    }
    
    public static Account createMasterEntityAccount(User pUserAM, String pName) {
        Account vAccount = new Account();
        vAccount.Name = (pName != null) ? pName : MASTER_ENTITY_NAME;
        vAccount.OwnerId = pUserAM.Id;
        vAccount.Account_Manager__c = pUserAM.Id;
        vAccount.GIE_AXA_GS_Member__c = 'No';
        vAccount.Active__c = true;
        vAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_MASTER_ENTITY_ACCOUNT).getRecordTypeId(); // TODO add method with developer name
        insert vAccount;
        
        return vAccount;
    }
    
    public static Account linkLEgalEntityToEntity(Account pEntityAccount, Account pLegalAccount) {
        pLegalAccount.ParentId = pEntityAccount.Id;
        pLegalAccount.Active__c = true;
        pLegalAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_ACCOUNT).getRecordTypeId();
        update pLegalAccount;
        
        return pLegalAccount;
    }
    
    public static Contact createEntityContact(Account pAccount) {
        Contact vEntityContact = new Contact();
        vEntityContact.AccountId = pAccount.Id;
        vEntityContact.LastName = CONTACT_ENTITY_LAST_NAME;
        vEntityContact.Title = CONTACT_ENTITY_TITLE;
        vEntityContact.Email = CONTACT_EMAIL;
        vEntityContact.MobilePhone = CONTACT_MobilePhone;
        vEntityContact.AXA_GO_Signatory__c = true;
        vEntityContact.Active__c = true;
        vEntityContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_CONTACT).getRecordTypeId(); // TODO add method with developer name
        insert vEntityContact;
        
        return vEntityContact;
    }
    
    public static Contact createEntityContact(Account pAccount, String email, String lastName) {
        Contact vEntityContact = new Contact();
        vEntityContact.AccountId = pAccount.Id;
        vEntityContact.LastName = lastName;
        vEntityContact.Title = CONTACT_ENTITY_TITLE;
        vEntityContact.Email = email;
        vEntityContact.MobilePhone = CONTACT_MobilePhone;
        vEntityContact.AXA_GO_Signatory__c = true;
        vEntityContact.Active__c = true;
        vEntityContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_CONTACT).getRecordTypeId(); // TODO add method with developer name
        insert vEntityContact;
        
        return vEntityContact;
    }
    
    public static User createAXAGSUser(Account pAccount) {
        // Get offer owner profile
        Profile vProfileOO = [SELECT Id From Profile WHERE Name = :AP_Constant.PRODUCT_OWNER];
        // Create OO user
        User vUserAXAGS = new User();
        vUserAXAGS.Alias = 'user2';
        vUserAXAGS.FirstName = 'axags';
        vUserAXAGS.LastName = 'user';
        vUserAXAGS.Username = USER_AXAGS_USERNAME;
        vUserAXAGS.Email = 'axags@Account.com';
        vUserAXAGS.EmailEncodingKey = 'ISO-8859-1';
        vUserAXAGS.TimeZoneSidKey = 'Europe/Paris';
        vUserAXAGS.LanguageLocaleKey = 'en_US';
        vUserAXAGS.LocaleSidKey = 'fr_FR_EURO';
        vUserAXAGS.ProfileId = vProfileOO.Id;
        insert vUserAXAGS;
        
        return vUserAXAGS;
    }
    
    /// Business area, domain, offer, product, product version
    /*public static Quartile__c createBusinessArea(User pUserOO) {
        return createBusinessArea(pUserOO, true);
    }
    
    public static Quartile__c createBusinessArea(User pUserOO, boolean pIsActive) {
        Quartile__c vQuartile = new Quartile__c();
        vQuartile.Name = QUARTILE_NAME;
        vQuartile.Head_Of__c = pUserOO.Id;
        vQuartile.Is_Active__c = pIsActive;
        insert vQuartile;
        
        return vQuartile;
    }
    
    public static Quartile__c createBusinessArea(User pUserOO, boolean pIsActive, String quartilename, boolean insertFlag) {
        Quartile__c vQuartile = new Quartile__c();
        vQuartile.Name = quartilename;
        vQuartile.Head_Of__c = pUserOO.Id;
        vQuartile.Is_Active__c = pIsActive;
        if(insertFlag)
            insert vQuartile;
        
        return vQuartile;
    }
    
    public static Petal__c createDomain(Quartile__c pQuartile, User pUserOO) {
        return createDomain(pQuartile, pUserOO, true);
    }
    
    public static Petal__c createDomain(Quartile__c pQuartile, User pUserOO, boolean pIsActive) {
        Petal__c vPetal = new Petal__c();
        vPetal.Name = PETAL_NAME;
        vPetal.Business_area__c = pQuartile.Id;
        vPetal.Is_Active__c = pIsActive;
        insert vPetal;
        
        return vPetal;
    }
    
    public static Petal__c createDomain(Quartile__c pQuartile, User pUserOO, boolean pIsActive, String petalname, boolean insertFlag) {
        Petal__c vPetal = new Petal__c();
        vPetal.Name = petalname;
        vPetal.Business_area__c = pQuartile.Id;
        vPetal.Is_Active__c = pIsActive;
        if(insertFlag){
            insert vPetal;
        }
        
        return vPetal;
    }
    
    public static Offer__c createOffer(Petal__c pPetal, User pUserOO) {
        return createOffer(pPetal, pUserOO, true);
    }
    
    public static Offer__c createOffer(Petal__c pPetal, User pUserOO, boolean pIsActive) {
        Offer__c vOffer = new Offer__c();
        vOffer.Name = OFFER_NAME;
        vOffer.OwnerId = pUserOO.Id;
        vOffer.Domain__c = pPetal.Id;
        vOffer.Is_Active__c = pIsActive;
        insert vOffer;
        
        return vOffer;
    }
    public static Offer__c createOffer(Petal__c pPetal, User pUserOO, boolean pIsActive, String offerName) {
        Offer__c vOffer = new Offer__c();
        vOffer.Name = offerName;
        vOffer.OwnerId = pUserOO.Id;
        vOffer.Domain__c = pPetal.Id;
        vOffer.Is_Active__c = pIsActive;
        insert vOffer;
        
        return vOffer;
    }*/
    
    public static Product__c createProduct(User pUserOO) {
        return createProduct(pUserOO, AP_Constant.PRODUCT_LIVE);
    }
    public static Product__c createProduct(User pUserOO, String pStatus) {
        Product__c vProduct = new Product__c();
        vProduct.Name = PRODUCT_NAME;
        vProduct.OwnerId = pUserOO.Id;
        vProduct.Product_owner__c = pUserOO.Id;
        vProduct.Product_Level_3__c = 'product level 3';
									  
        vProduct.Status__c = pStatus;
        insert vProduct;
        
        return vProduct;
    }
    public static Product__c createProduct(User pUserOO, String pStatus, String productName) {
        Product__c vProduct = new Product__c();
        vProduct.Name = productName;
        vProduct.OwnerId = pUserOO.Id;
        vProduct.Product_owner__c = pUserOO.Id;
        vProduct.Product_Level_3__c = 'product level 3';
									  
        vProduct.Status__c = pStatus;
        insert vProduct;
        
        return vProduct;
    }
    
    /* SGO - 17/09/19 */
    public static Product__c createProduct(User pUserOO, String pStatus, String productName, Boolean pInsert) {
        Product__c vProduct = new Product__c();
        vProduct.Name = productName;
        vProduct.OwnerId = pUserOO.Id;
        vProduct.Product_owner__c = pUserOO.Id;
        vProduct.Product_Level_3__c = 'product level 3';
									  
        vProduct.Status__c = pStatus;
        if (pInsert){
            insert vProduct;
        }
        
        return vProduct;
    }
    
    public static Product_Attachment__c createProductAttachment(Product__c pProduct) {
        // Insert custom attachment
        Product_Attachment__c vProductAttachment = new Product_Attachment__c();
        vProductAttachment.Product__c = pProduct.Id;
        vProductAttachment.Deliverable__c = ATTACHMENT_NAME;
        vProductAttachment.Name = ATTACHMENT_NAME;
        insert vProductAttachment;
        
        //Insert standard attachment
        Attachment vRealAttachment = new Attachment();
        vRealAttachment.Name = ATTACHMENT_NAME;
        vRealAttachment.body = Blob.valueOf('Test blob');
        vRealAttachment.ParentId = vProductAttachment.Id;
        insert vRealAttachment;
        
        // link the custom to the standard attachment
        vProductAttachment.Attachment_Id__c = vRealAttachment.Id;
        update vProductAttachment;
        
        return vProductAttachment;
    }
    
    /*public static OpportunityProduct__c createOpportunityProductLink(Opportunity pOpty, Product__c pProduct, Boolean pIsMain) {
        if (pOpty == null || pProduct == null) {
            return null;
        }
        
        OpportunityProduct__c vOptyProduct = new OpportunityProduct__c();
        vOptyProduct.Product__c = pProduct.Id;
        vOptyProduct.Opportunity__c = pOpty.Id;
        vOptyProduct.Amount_Percentage__c = 1;
        insert vOptyProduct;
        
        return vOptyProduct;
    }
    public static OpportunityProduct__c createOpportunityProductLink(Opportunity pOpty, Product__c pProduct) {
        return createOpportunityProductLink(pOpty, pProduct, true);
    }
    
    public static List<OpportunityProduct__c> createOpportunityProductLink(List<Opportunity> pOpties, Product__c pProduct) {
        if (pOpties == null || pProduct == null) {
            return null;
        }
        
        List<OpportunityProduct__c> vOptyProducts = new List<OpportunityProduct__c>();
        for (Opportunity vOpty : pOpties) {
            OpportunityProduct__c vOptyProduct = new OpportunityProduct__c();
            vOptyProduct.Product__c = pProduct.Id;
            vOptyProduct.Opportunity__c = vOpty.Id;
            vOptyProduct.Amount_Percentage__c = 1;
            vOptyProducts.add(vOptyProduct);
        }
        
        insert vOptyProducts;
        
        return vOptyProducts;
    }*/
    
    /**
* Method createInvoicingParamater : will generate and insert a new invoicing parameter
* @return Invoicing_Paramater__c : a generic Invoicing_Parameter to be used for test purpose.
*/
    public static Invoicing_Parameter__c createInvoicingParameter(){
        return createInvoicingParameter(true);
    }
    
    /**
* Methode createInvoicingParameter : will generate a new invoicing parameter. will insert if condition are
* met
* @param pInsert Boolean : if true the Invoicing Parameter is inserted, if false it is not
* @return Invoicing_Parameter__c : a generic Invoicing_Parameter to be used for test pupose.
*/
    public static Invoicing_Parameter__c createInvoicingParameter(Boolean pInsert){
        //We will get the id for the record_type Invoicing Condition
        Schema.DescribeSObjectResult invoicingParameterDescription = Invoicing_Parameter__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> invoicingParameterRecordTypeInfos = invoicingParameterDescription.getRecordTypeInfos();
        String invoicingConditionID = '';
        for(Schema.RecordTypeInfo invoicingParameterRecordTypeInfo : invoicingParameterRecordTypeInfos){
            if(invoicingParameterRecordTypeInfo.getName() == 'Invoicing Condition'){
                invoicingConditionID = invoicingParameterRecordTypeInfo.getRecordTypeId();
            }
        }
        
        //Creation of the Invoicing_Parameter
        Invoicing_Parameter__c vInvoicingCondition = new Invoicing_Parameter__c();
        vInvoicingCondition.recordTypeId = invoicingConditionID;
        vInvoicingCondition.Name = System.Label.InvoicingCondition_100BeginningOfService;
        
        if(pInsert)
            insert vInvoicingCondition;
        
        return vInvoicingCondition;
    }
    
    public static Contract__c createContract(Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact) {
        return createContract(pProduct, pAccount, pUserPM, pEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT);
    }
    
    public static Contract__c createContract(Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContract(pProduct, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, true);
    }
    
    public static Contract__c createContract(Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, boolean pInsert) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContract(pProduct, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, pInsert);
    }
    
    /**
* Method createContract : create a contract for test purpose
* @param pProduct Product__c : the product for the contract
* @param pAccount
*/
    public static Contract__c createContract(Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, Invoicing_Parameter__c pInvoicingParameter, Boolean pInsert) {
        //Get a record type ID for the current contract
        Schema.DescribeSObjectResult contractDescription = Contract__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> contractRecordTypeInfos = contractDescription.getRecordTypeInfos();
        String contractID = '';
        for(Schema.RecordTypeInfo contractRecordTypeInfo : contractRecordTypeInfos){
            if(contractRecordTypeInfo.getName() == 'AXA GS Asia'){
                contractID = contractRecordTypeInfo.getRecordTypeId();
                break;
            }
        }
        
        //Contract creation
        Contract__c vContract = new Contract__c();
        vContract.OwnerId = pUserPM.Id;
        vContract.Name = CONTRACT_NAME;
        vContract.AXA_GS_Signed_By__c = pEntityContact.Id;
        vContract.CustomerSignedBy__c = pEntityContact.Id;
        vContract.Customer_Operational_Contact__c = pEntityContact.Id;
        vContract.Account__c = pAccount.Id;
        vContract.Status__c = pStatus;
        vContract.StartDate__c = System.Today().addMonths(-5);
        vContract.EndDate__c = System.Today().addMonths(-1);
        vContract.AXA_GO_Legal_Entity__c = CONTRACT_LEGAL_ENTITY;
        vContract.ServiceType__c = CONTRACT_STYPE_BAU;
        vContract.InvoicingMethod__c = CONTRACT_INVMETHOD_FIXEDPRICE;
        vContract.Global_Amount__c = PINVLINE_AMOUNT;
        vContract.SOW_Operational__c = '123';
        vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
        vContract.Master_WBS_2__c = createActivityCode('L21FS_FM_000023', CONTRACT_LEGAL_ENTITY).Id;
        vContract.SOW_Type__c = AP_Constant.SOW_PRODUCT_TEMPLATE;
        
        if (pInsert) {
            insert vContract;
        }
        
        return vContract;
    }
    
    public static Contract__c createContract2(String recTypeName, Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact) {
        return createContract2(recTypeName, pProduct, pAccount, pUserPM, pEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT);
    }
    
    public static Contract__c createContract2(String recTypeName, Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContract2(recTypeName, pProduct, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, true);
    }
    
    
    public static Contract__c createContract2(String recTypeName, Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, boolean pInsert) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContract2(recTypeName, pProduct, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, pInsert);
    }
    
    
    public static Contract__c createContract2(String recTypeName, Product__c pProduct, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, Invoicing_Parameter__c pInvoicingParameter, Boolean pInsert) {
        //Get a record type ID for the current contract
        Schema.DescribeSObjectResult contractDescription = Contract__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> contractRecordTypeInfos = contractDescription.getRecordTypeInfos();
        String contractID = '';
        for(Schema.RecordTypeInfo contractRecordTypeInfo : contractRecordTypeInfos){
            if(contractRecordTypeInfo.getName() == recTypeName){
                contractID = contractRecordTypeInfo.getRecordTypeId();
                break;
            }
        }
        
        
        //Contract creation
        Contract__c vContract = new Contract__c();
        vContract.OwnerId = pUserPM.Id;
        vContract.Name = CONTRACT_NAME;
        vContract.AXA_GS_Signed_By__c = pEntityContact.Id;
        vContract.CustomerSignedBy__c = pEntityContact.Id;
        vContract.Customer_Operational_Contact__c = pEntityContact.Id;
										   
        vContract.Account__c = pAccount.Id;
        //vContract.Notify_Validation__c = pUserPM.Id;
        vContract.Status__c = pStatus;
        vContract.StartDate__c = System.Today().addMonths(-5);
        vContract.EndDate__c = System.Today().addMonths(-1);
        vContract.AXA_GO_Legal_Entity__c = CONTRACT_LEGAL_ENTITY;
        vContract.ServiceType__c = CONTRACT_STYPE_BAU;
        vContract.InvoicingMethod__c = CONTRACT_INVMETHOD_FIXEDPRICE;
        vContract.Global_Amount__c = PINVLINE_AMOUNT;
        vContract.SOW_Operational__c = '123';
        vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
        //vContract.Invoicing_Parameter__c = pInvoicingParameter.Id;
        //vContract.RecordTypeId = contractID;
        
        if (pInsert) {
            insert vContract;
        }
        
        return vContract;
    }
    
    public static Planned_Invoicing_Line__c createPInvoicingLine(Contract__c pContract, String pDescription) {
        // Insert custom attachment
        Planned_Invoicing_Line__c vPInvoicingLine = new Planned_Invoicing_Line__c();
        vPInvoicingLine.Contract2__c = pContract.Id;
        vPInvoicingLine.Description__c = pDescription;
        vPInvoicingLine.Amount__c = PINVLINE_AMOUNT;
        vPInvoicingLine.Invoicing_Date__c = System.Today();
        vPInvoicingLine.Type__c = AP_Constant.INVLINE_TYPE_INVLINE;
        insert vPInvoicingLine;
        
        return vPInvoicingLine;
    }
    
    /* SGO - 17/09/19 */
    public static Planned_Invoicing_Line__c createPInvoicingLine(Contract__c pContract, String pName, String pDescription, Boolean pInsert) {
        Planned_Invoicing_Line__c vPInvoicingLine = new Planned_Invoicing_Line__c();
        vPInvoicingLine.Name = pName;
        vPInvoicingLine.Contract2__c = pContract.Id;
        vPInvoicingLine.Description__c = pDescription;
        vPInvoicingLine.Amount__c = PINVLINE_AMOUNT;
        vPInvoicingLine.AmountIL__c  = PINVLINE_AMOUNT;
        vPInvoicingLine.Invoicing_Date__c = System.Today();
        vPInvoicingLine.Type__c = AP_Constant.INVLINE_TYPE_INVLINE;  
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = :AP_Constant.RT_INVLINE_Edit AND SObjectType='Planned_Invoicing_Line__c'];
        vPInvoicingLine.RecordTypeId = rt.Id;
        
        //vPInvoicingLine.Invoicing_Predefined_Date__c= createInvoicingParameterInvDate().Id; //Lookup to Invoicing Parameters
        vPInvoicingLine.Inv_Predefined_Date__c= createInvoicingParameterInvDate().Invoicing_Date__c; //Lookup to Invoicing Parameters
																										   
        
        if(pContract.Master_WBS_2__c != null)
            vPInvoicingLine.Master_WBS_Structure__c = pContract.Master_WBS_2__c;
        /*else
            vPInvoicingLine.Master_WBS_Structure__c = createActivityCode('192038').Id;//Lookup to Activity Code
        */
        if (pInsert){
            insert vPInvoicingLine;
        }
        
        return vPInvoicingLine;
    }
    
    
    public static Planned_Invoicing_Line__c createPInvoicingLine2(Contract__c pContract, String pDescription) {
        // Insert custom attachment
        Planned_Invoicing_Line__c vPInvoicingLine = new Planned_Invoicing_Line__c();
        vPInvoicingLine.Contract2__c = pContract.Id;
        vPInvoicingLIne.Description__c = pDescription;
        vPInvoicingLine.Amount__c = PINVLINE_AMOUNT;
        vPInvoicingLine.Invoicing_Date__c = System.Today(); 
        Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId(); 
        //insert vPInvoicingLine;
        
        return vPInvoicingLine;
    }
    
    public static Invoicing_Line__c createInvoicingLine(Contract__c pContract, String pDescription) {
        // Insert custom attachment
        Invoicing_Line__c vInvoicingLine = new Invoicing_Line__c();
        vInvoicingLine.Contract2__c = pContract.Id;
        insert vInvoicingLine;
        
        return vInvoicingLine;
    }
    
    public static Planned_Invoicing_Line__c createNInvoicingLine(Contract__c pContract, String pDescription) {
        // Insert custom attachment
        Planned_Invoicing_Line__c vInvoicingLine = new Planned_Invoicing_Line__c();
        vInvoicingLine.Contract2__c = pContract.Id;
        insert vInvoicingLine;
        
        return vInvoicingLine;
    }
    
    public static Planned_Invoicing_Line__c createIL(Contract__c pContract, String pDescription, String pStatus) {
        // Insert custom attachment
        Planned_Invoicing_Line__c vIL = new Planned_Invoicing_Line__c();
        vIL.Contract2__c = pContract.Id;
        vIL.Description__c = pDescription;
        vIL.AmountIL__c = PINVLINE_AMOUNT;
        vIL.status__c = pStatus;
        vIL.recordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
        
        return vIL;
    }
    
    public static Planned_Invoicing_Line__c createIL(Contract__c pContract, Double amount, String pDescription, String pStatus, Date startDate, Date endDate, Id entityContact) {
        // Insert custom attachment
        Planned_Invoicing_Line__c vIL = new Planned_Invoicing_Line__c();
        vIL.Contract2__c = pContract.Id;
        vIL.Description__c = pDescription;
        vIL.AmountIL__c = amount;
        vIL.status__c = pStatus;
        vIL.StartDate__c = startDate;
        vIL.EndDate__c = endDate;
        vIL.Master_WBS_Structure__c = pContract.Master_WBS_2__c;
        //vIL.Customer_Contact__c = entityContact;
        vIL.Customer_contact_name__c = 'test_name';
        vIL.Inv_Predefined_Date__c = System.Today();
        vIL.recordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
        
        return vIL;
    }
    
    // Lucy project
    public static Attachment createAttachment(String pDocName, Opportunity pOpty, Boolean pInsert) {
        Attachment vAtt = new Attachment();
        vAtt.Name = pDocName + '_test_attachment.txt';
        vAtt.Description = pDocName;
        vAtt.Body = Blob.valueof('123');
        vAtt.ParentId = pOpty.Id;
        
        if (pInsert) insert vAtt;
        
        return vAtt;
    }
    
    /**
* <b>Method createMasterWBSStructure </b>: will generate a Master WBS Structure for test purpose
*/
    public static Master_WBS_Structure__c createMasterWBSStructure(String AL1, String AL2, String GIESAS,
    String Scope, String Solution, String Year, Boolean insertFlag){
        //Variable declaration
        Master_WBS_Structure__c testMasterWBS = new Master_WBS_Structure__c();
                                                                       
        //Field initialisation
        testMasterWBS.Activity_Level_1__c = AL1;
        testMasterWBS.Activity_Level_2__c = AL2;
        //testMasterWBS.GIE_GO_SAS__c = GIESAS;
        testMasterWBS.GIE_GO_SAS__c ='AXA Group Operations SAS';
        testMasterWBS.Scope__c = Scope;
        testMasterWBS.Solution__c = Solution;
        testMasterWBS.Year__c = Year;
        
        
        //If asked, insert the Master WBS
        if(insertFlag){
            insert testMasterWBS;
        }
        
        return testMasterWBS;
    }
    
    public static ProductEntityLink__c createEro(Id accId, Id prodId, String strStatus, Date goLiveDate) {
        ProductEntityLink__c vNewEro = new ProductEntityLink__c();
        vNewEro.entity__c = accId;
        vNewEro.product__c = prodId;
        vNewEro.POS_Status__c = strStatus;
        vNewEro.First_Release_Date__c = goLiveDate;
        
        insert vNewEro;
        return vNewEro;
    }
    
    public static ProductEntityLink__c createMEro(Id accId, Id prodId, Id MasterEntityRolledOutId, String strStatus, Date goLiveDate) {
        ProductEntityLink__c vNewEro = new ProductEntityLink__c();
        vNewEro.entity__c = accId;
        vNewEro.product__c = prodId;
        vNewEro.MasterEntityRolledOut__c = MasterEntityRolledOutId;
        vNewEro.POS_Status__c = strStatus;
        vNewEro.First_Release_Date__c = goLiveDate;
        
        insert vNewEro;
        return vNewEro;
    }
    
    public static String getUniqueUserName(){
        //adding an incremental counter because when inserting multiple users the getTime() method can return same value for 2 user record
        counter++ ;
        return UserInfo.getOrganizationId() + System.now().getTime() + counter + 'user@testorg.com';
    }
    
    
    /* Create product items for opportunity */
    // public static Opp_ProductItem__c createProdItems(Offer__c pOffer,User pUserOO, Product__c pProduct, Opportunity pOpty ) {
    //     return createProdItems(pProduct, pOpty);
    // }
    
    public static Opp_ProductItem__c createProdItems(User pUserOO,Product__c pProduct, Opportunity pOpty){
        Opp_ProductItem__c vItem = new Opp_ProductItem__c();
        vItem.Opportunity__c = pOpty.Id;
        vItem.Product__c = pProduct.Id;
        insert vItem;
        vItem = [SELECT Id, Name, Opportunity__c,Opportunity__r.Name, Product__c,Product__r.Name   FROM Opp_ProductItem__c WHERE ID = :vItem.Id];
        
        return vItem;
    }
    
    /* pInsert Boolean */
    public static Opp_ProductItem__c createOppProdItems(User pUserOO,Product__c pProduct, Opportunity pOpty, Boolean pInsert){
        Opp_ProductItem__c vItem = new Opp_ProductItem__c();
        vItem.Opportunity__c = pOpty.Id;
        vItem.Product__c = pProduct.Id;
        vItem.Status__c = pProduct.status__c;
        
        if (pInsert){
            insert vItem;
            vItem = [SELECT Id, Name, Opportunity__c,Opportunity__r.Name, Product__c,Product__r.Name   FROM Opp_ProductItem__c WHERE ID = :vItem.Id];
        }
        
        return vItem;
    }
    
    public static Contract__c createContractAdmin(String pProdName, Product__c pProduct, Account pAccount, User pUserOO, Contact pEntityContact){
        Contract__c vContract = new Contract__c();
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE DeveloperName = :AP_Constant.RT_CONTRACT_EDIT_LIGHTNING AND SObjectType='Contract__c'];
        vContract.RecordTypeId = rt.Id;
        vContract.Name = pProdName;
        vContract.Status__c = AP_Constant.CONTRACT_STATUS_DRAFT;
        vContract.AXA_GO_Legal_Entity__c = CONTRACT_LEGAL_ENTITY;
        //vContract.SOW_Type__c = AP_Constant.SOW_CESAMEPRO;
        //vContract.OfferATS__c = pOffer.Id;
        
        //insert vContract;
        return vContract;
        
        
    }
    
    //used for test class
    public static Planned_Invoicing_Line__c createPInvoicingLineAdmin(Contract__c pContract, String pINVNAME, String pDescription) {
        Planned_Invoicing_Line__c vPInvoicingLine = new Planned_Invoicing_Line__c();
        //RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = :AP_Constant.RT_INVLINE_Edit AND SObjectType='Planned_Invoicing_Line__c'];
        vPInvoicingLine.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
        
        vPInvoicingLine.Name = pINVNAME;
        //vPInvoicingLine.Invoicing_Predefined_Date__c= createInvoicingParameterInvDate().Id; //Lookup to Invoicing Parameters
        vPInvoicingLine.Inv_Predefined_Date__c= createInvoicingParameterInvDate().Invoicing_Date__c; //Lookup to Invoicing Parameters

																			
																	  
							
        vPInvoicingLine.Master_WBS_Structure__c = pContract.Master_WBS_2__c;//Lookup to Activity Code
        vPInvoicingLine.Contract2__c = pContract.Id;
        vPInvoicingLine.Description__c = pDescription;
        vPInvoicingLine.Amount__c = PINVLINE_AMOUNT;
        vPInvoicingLine.AmountIL__c  = PINVLINE_AMOUNT;
        vPInvoicingLine.Invoicing_Date__c = System.Today();
        vPInvoicingLine.Type__c = AP_Constant.INVLINE_TYPE_INVLINE;
        
        //insert vPInvoicingLine;
        return vPInvoicingLine;
    }
    
    //For AP29_ContractStatusControls_Test, used in Method createPInvoicingLine
    public static Master_WBS_Structure__c createActivityCode(String pACTCODE){
        Master_WBS_Structure__c vActCode = new Master_WBS_Structure__c();
        vActCode.Name=pACTCODE;
        
        insert vActCode;
        return vActCode;
    }
    
    public static Invoicing_Parameter__c createInvoicingParameterInvDate(){
        return createInvoicingParameterInvDate(true);
    }
    
    /* Invoicing Parameter with recordtype Invoicing Date */ 
    public static Invoicing_Parameter__c createInvoicingParameterInvDate(Boolean pInsert){
        //Get id for the record_type Invoicing Date
        Schema.DescribeSObjectResult invoicingParameterDescription = Invoicing_Parameter__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> invoicingParameterRecordTypeInfos = invoicingParameterDescription.getRecordTypeInfos();
        String invoicingDateID = '';
        for(Schema.RecordTypeInfo invoicingParameterRecordTypeInfo : invoicingParameterRecordTypeInfos){
            if(invoicingParameterRecordTypeInfo.getName() == 'Invoicing Date'){
                invoicingDateID = invoicingParameterRecordTypeInfo.getRecordTypeId();
                break;
            }
        }
        //Creation of the Invoicing_Parameter
        Invoicing_Parameter__c vInvoicingDate = new Invoicing_Parameter__c();
        vInvoicingDate.recordTypeId = invoicingDateID;
        vInvoicingDate.Name = 'CONTRACT_INVPARAMDATE';
        vInvoicingDate.Invoicing_Date__c = CONTRACT_INVPARAMDATE;
        vInvoicingDate.Parameter_Type__c = CONTRACT_INVDATE;
        
        if(pInsert)
            insert vInvoicingDate;
        
        return vInvoicingDate;
    }
    
    //SGO - 2019/08/30
    /*Create contract prod item*/
    public static ProductItem__c createCtrProdItems(Contract__c pCtr, Product__c pProduct, String pDescrip){
        ProductItem__c vItem = new ProductItem__c();
        vItem.Contract__c = pCtr.Id;
        vItem.Product__c = pProduct.Id;
        vItem.ProductDescription__c = pDescrip;
        //insert vItem;
        // vItem = [SELECT Id, Name, Contract__c,Contract__r.Name, Product__c,Product__r.Name   FROM ProductItem__c WHERE ID = :vItem.Id];
        
        return vItem;
    }
    
    
    // SGO - 2019/09/04
    /* CREATE CONTRACT WITHOUT INSERT STATEMENT DUE TO GOVERNOR LIMITS - USED IN AP12_CONTRACT_TEST */
    public static Contract__c createContractNotInsert(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact) {
        return createContractNotInsert(recTypeName, pAccount, pUserPM, pEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT);
    }
    
    public static Contract__c createContractNotInsert(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContractNotInsert(recTypeName, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, true);
    }
    
    
    public static Contract__c createContractNotInsert(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, boolean pInsert) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContractNotInsert(recTypeName, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, pInsert);
    }
    
    
    public static Contract__c createContractNotInsert(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, Invoicing_Parameter__c pInvoicingParameter, Boolean pInsert) {
        //Get a record type ID for the current contract
        Schema.DescribeSObjectResult contractDescription = Contract__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> contractRecordTypeInfos = contractDescription.getRecordTypeInfos();
        String contractID = '';
        for(Schema.RecordTypeInfo contractRecordTypeInfo : contractRecordTypeInfos){
            if(contractRecordTypeInfo.getName() == recTypeName){
                contractID = contractRecordTypeInfo.getRecordTypeId();
            }
        }
        
        //Contract creation
        Contract__c vContract = new Contract__c();
        vContract.OwnerId = pUserPM.Id;
        vContract.Name = CONTRACT_NAME;
        vContract.AXA_GS_Signed_By__c = pEntityContact.Id;
        vContract.CustomerSignedBy__c = pEntityContact.Id;
        vContract.Customer_Operational_Contact__c = pEntityContact.Id;
										   
        vContract.Account__c = pAccount.Id;
       // vContract.Notify_Validation__c = pUserPM.Id;
        vContract.Status__c = pStatus;
        vContract.StartDate__c = System.Today().addMonths(-5);
        vContract.EndDate__c = System.Today().addMonths(-1);
        vContract.AXA_GO_Legal_Entity__c = CONTRACT_LEGAL_ENTITY;
        vContract.ServiceType__c = CONTRACT_STYPE_BAU;
        vContract.InvoicingMethod__c = CONTRACT_INVMETHOD_FIXEDPRICE;
        vContract.Global_Amount__c = PINVLINE_AMOUNT;
        vContract.SOW_Operational__c = '123';
        vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
        //vContract.Invoicing_Parameter__c = pInvoicingParameter.Id;
        vContract.RecordTypeId = contractID;
        
        //if (pInsert) {
        return vContract;
        //}
        
    }
    
    // SGO - 2019/09/04 - AP12_Contract_Test
    public static Master_WBS_Structure__c createActivityCode(String pACTCODE, String pLENTITY){
        Master_WBS_Structure__c vActCode = new Master_WBS_Structure__c();
        vActCode.Name=pACTCODE;
        vActCode.GIE_GO_SAS__c = pLENTITY;
        
        insert vActCode;
        return vActCode;
    }
    
    
    // SGO - 2019/09/19
    @future
    public static void customSettingDelete(Id profId){
        DeletionPermissionFlag__c contractDeletionFlag= new DeletionPermissionFlag__c(SetupOwnerId=profId, ContractDelete__c=true);
        insert contractDeletionFlag;
        
        Boolean contractDeletionFlagRet = DeletionPermissionFlag__c.getInstance(profId).ContractDelete__c;
        
    }
    
    @future
    public static void createCustomSettingDelete(Id userId){
        DeletionPermissionFlag__c contractDeletionFlag= new DeletionPermissionFlag__c(SetupOwnerId=userId, ContractDelete__c=true);
        insert contractDeletionFlag;
        
        Boolean contractDeletionFlagRet = DeletionPermissionFlag__c.getInstance(userId).ContractDelete__c;
    }
    
    public static Contract__c createContractLEX(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContractLEX(recTypeName, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, true);
    }
    
    
    public static Contract__c createContractLEX(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, boolean pInsert) {
        Invoicing_Parameter__c invoicingParameter = createInvoicingParameter();
        return createContractLEX(recTypeName, pAccount, pUserPM, pEntityContact, pStatus, invoicingParameter, pInsert);
    }
    
    
    public static Contract__c createContractLEX(String recTypeName, Account pAccount, User pUserPM, Contact pEntityContact, String pStatus, Invoicing_Parameter__c pInvoicingParameter, Boolean pInsert) {
        //Get a record type ID for the current contract
        Schema.DescribeSObjectResult contractDescription = Contract__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> contractRecordTypeInfos = contractDescription.getRecordTypeInfos();
        String contractID = '';
        for(Schema.RecordTypeInfo contractRecordTypeInfo : contractRecordTypeInfos){
            if(contractRecordTypeInfo.getName() == recTypeName){
                contractID = contractRecordTypeInfo.getRecordTypeId();
                break;
            }
        }
        
        
        //Contract creation
        Contract__c vContract = new Contract__c();
        vContract.OwnerId = pUserPM.Id;
        vContract.Name = CONTRACT_NAME;
        vContract.AXA_GS_Signed_By__c = pEntityContact.Id;
        vContract.CustomerSignedBy__c = pEntityContact.Id;
        vContract.Customer_Operational_Contact__c = pEntityContact.Id;
        vContract.Account__c = pAccount.Id;
        vContract.Status__c = pStatus;
        vContract.StartDate__c = System.Today().addMonths(-5);
        vContract.EndDate__c = System.Today().addMonths(-1);
        vContract.AXA_GO_Legal_Entity__c = CONTRACT_LEGAL_ENTITY;
        vContract.ServiceType__c = CONTRACT_STYPE_BAU;
        vContract.InvoicingMethod__c = CONTRACT_INVMETHOD_FIXEDPRICE;
        vContract.Global_Amount__c = PINVLINE_AMOUNT;
        vContract.SOW_Operational__c = '123';
        vContract.Master_WBS_2__c = createActivityCode('L21FS_FM_000023', CONTRACT_LEGAL_ENTITY).Id;
        vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
        vContract.RecordTypeId = contractID;
        
        if (pInsert) {
            insert vContract;
        }
        
        return vContract;
    }
}