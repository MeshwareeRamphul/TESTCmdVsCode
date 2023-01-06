@isTest
private class InvoiceLineTriggerHandler_TEST {

  static user testUser;
    static ContentWorkspace workspace;
    static User vUserPM;
    static User vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Planned_Invoicing_Line__c vPInvLine1;
    static Planned_Invoicing_Line__c vPInvLine2;
    static Id InvDateRecordTypeId;
    static Id InvLinRecordTypeId;
    static Id InvCondRecordTypeId;
    static Invoicing_Parameter__c a1ParmInvLin,a1ParmInvCond,a2ParmInvCond,a2ParmInvLin,a3ParmInvCond,a3ParmInvLin,a4ParmInvLin,aParmInvDate,a5ParmInvLin;  
    static List <Invoicing_Parameter__c> ParmLineList;  
    static Master_WBS_Structure__c vMasterWBS_2; 

    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>(); 
    static invoicing_parameter__c invParam;
  static{         
      // Create PM user
      vUserPM = new User();
      vUserPM.Alias = 'Admin';
      vUserPM.FirstName = 'userAdmin';
      vUserPM.LastName = 'userAdmin';
      vUserPM.Username = 'serADMINinvhdl@test.com';
      vUserPM.Email = 'userAdmin@Account.com';
      vUserPM.EmailEncodingKey = 'ISO-8859-1';
      vUserPM.TimeZoneSidKey = 'Europe/Paris';
      vUserPM.LanguageLocaleKey = 'en_US';
      vUserPM.LocaleSidKey = 'fr_FR_EURO';
      vUserPM.ProfileId = AP_Constant.getProfileIdAdmin();
      vUserPM.PAD_BypassValidationRules__c = true;
      insert vUserPM;

      vUserPM.PAD_BypassTrigger__c = 'AP412;AP52;AP1012;AP22;';
      update vUserPM;

      System.runAs(vUserPM) {
          // Create OO user
          User vUserOO = AP05_TestDataFactory.createOOUser();

          // Create the legal entity (aka billing entity) account
          vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

          // Create the entity account
          vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

          // Create the couple Entity - Billing Entity on Parent Entity
          vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

          // Create the entity contact related to the account
          vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
          
          //Product
          vProduct = AP05_TestDataFactory.createProduct(vUserOO);

          //Invoicing parameter 
          invParam = new invoicing_parameter__c(parameter_type__c = 'Invoicing Date', invoicing_date__c = Date.today(), name = String.valueOf(Date.today()));
          insert invParam;

          //Master WBS
          Master_WBS_Structure__c vMasterWBS = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', 'AXA Group Operations SAS', 'CSS', 'Digital', '2016', true);
          vMasterWBS_2 = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', 'AXA Group Operations SAS', 'CSS', 'Digital', '2016', true);

          //Contract
          vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT); 
          update vContract;        

          lstPIL.add(AP05_TestDataFactory.createIL(vContract, 50,'Description 1', '02', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
          lstPIL.add(AP05_TestDataFactory.createIL(vContract, 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
          insert lstPIL;
    }
  }  
  
  @isTest static void test_method_one() {
    Set<Id> setPIL = new set<Id>();
    setPIL.add(lstPIL[0].Id);
    setPIL.add(lstPIL[1].Id);

    InvoiceLineTriggerHandler.handleBeforeUpdate(setPIL);
  }
}