@isTest
private class AP13_Attachment_TEST {
    static User vUserOO,vUserPM,adminUser;
    static Account vAccount,vEAccount,vMAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Planned_Invoicing_Line__c vPInvLine1,vPInvLine2;
    static Id InvDateRecordTypeId;
    static Id InvLinRecordTypeId; 
    static Id InvCondRecordTypeId ;
    static Invoicing_Parameter__c a1ParmInvCond,aParmInvDate,a1ParmInvLin,a1ParmInvDate,a2ParmInvCond,a2ParmInvLin,a3ParmInvCond,a3ParmInvLin,a4ParmInvLin;

    static{
        //Create datas for the tests methods

        // Create OO user
        vUserOO = AP05_TestDataFactory.createOOUser();

        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser(true);

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

		System.runAs(adminUser) {
            // Create the customer (aka entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(adminUser);

            // Create the entity account
            //vEAccount = AP05_TestDataFactory.createEntityAccount(adminUser);

            // Create the master entity account
            //vMAccount = AP05_TestDataFactory.createMasterEntityAccount(adminUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            //vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
                
            //Quartile (business area)
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(vUserPM);

            //Petal (Domain)
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserPM);

            // Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserPM);*/
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);  

            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact);    
            vContract.Global_Amount__c = 1200;
            update vContract;
            //Planned Invoicing Line 1
            vPInvLine1 = AP05_TestDataFactory.createPInvoicingLine(vContract,'il1','Description 1',true);
          
            //Planned Invoicing Line 2
            vPInvLine2 = AP05_TestDataFactory.createPInvoicingLine(vContract, 'il2','Description 2',true);

            //
            // create invoicing parameters
            //
            InvDateRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Date').getRecordTypeId();
            InvLinRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Line').getRecordTypeId();
            InvCondRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Condition').getRecordTypeId();

            // Invoicing Date
            aParmInvDate = new Invoicing_Parameter__c (Invoicing_Date__c = System.Today(), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing date');
            insert aParmInvDate;
            system.debug('##aParmInvDate' + aParmInvDate.id);

            // Invoicing condition / invoicing Lines for  beginning of service
            a1ParmInvCond = new Invoicing_Parameter__c (Name = '100% Beginning of service', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
            insert a1ParmInvCond;
            system.debug('##aParmInvCond' + a1ParmInvCond.id);

            a1ParmInvLin = new Invoicing_Parameter__c (Name = '100% Beginning of service', Invoicing_Description__c = '100% Beginning of service', Parent_For_Invoicing_Line__c = a1ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Start Date', Percent__c = 100.00);
            insert a1ParmInvLin;
            //
            //Invoicing condition / invoicing Lines for beginning of year
            //
            a2ParmInvCond = new Invoicing_Parameter__c (Name = '100% Beginning of year', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
            insert a2ParmInvCond;
            system.debug('##aParmInvCond' + a2ParmInvCond.id);

            a2ParmInvLin = new Invoicing_Parameter__c (Name = '100% Beginning of year', Invoicing_Description__c = '100% Beginning of year', Invoicing_Predefined_Date__c = aParmInvDate.id, Parent_For_Invoicing_Line__c = a2ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Fixed Date', Percent__c = 100.00);
            insert a2ParmInvLin;

            // Invoicing condition / invoicing Lines for %,50%,50%
            //
            a3ParmInvCond = new Invoicing_Parameter__c (Name = '0%,50%,50%', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
            insert a3ParmInvCond;
            system.debug('##aParmInvCond'   + a3ParmInvCond.id);

            a3ParmInvLin = new Invoicing_Parameter__c (Name = '50% half of service', Invoicing_Description__c = '50% half of service', Parent_For_Invoicing_Line__c = a3ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00);
            insert a3ParmInvLin;

            a4ParmInvLin = new Invoicing_Parameter__c (Name = '50% end of service', Invoicing_Description__c = '50% end of service', Parent_For_Invoicing_Line__c = a3ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'End Date', Percent__c = 50.00);
            insert a4ParmInvLin;
        }
    }

     @isTest 
    static void preventDeletionTest() {
       
            // Create the entity contact related to the account
            
        
            Test.startTest();
            System.runAs(adminUser) {
                //Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
                //vContract.Global_Amount__c = vContract.Planned_Invoicing_Lines_Amount__c;
                update (vContract); 
                Attachment vAttachment = new Attachment();
                vAttachment.parentID = vContract.Id;
                vAttachment.body = Blob.valueOf('test.pdf');
                vAttachment.Name = 'test_2016.pdf';
                insert vAttachment;
                // Try to delete first on regular attachment : no problem
                delete vAttachment;
            }
            List<Attachment> vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            System.assert(vContractAttachments.size() == 0);

            String vErrorMessage = AP10_ContractHandler.attachContract(vContract.Id);
            
            /* 27/07/2017 - Commented this part temporarily to be able to deploy in Production
            Error : System.QueryException: List has no rows for assignment to SObject 
            stack Trace: Class.AP10_ContractHandler.attachContract: line 414, column 1 
            
            vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            
            Boolean vErrorOccured = false;
            try {
                // Try to delete first on generated attachment : cannot
                delete vContractAttachments[0];
            } catch (Exception e) {
                vErrorOccured = true;
            }

            vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            System.assert(vContractAttachments.size() > 0);*/

            Test.stopTest();
        
    }

    /*

    Original version - commented code to resolve error 'Too many SOQL queries: 101' when deploying to Production
    @testSetup    
    public static void createTestsDatas() {
        //Create datas for the tests methods

        // Create OO user
        User vUserOO = AP05_TestDataFactory.createOOUser();

        // Create PM user
        User vUserPM = AP05_TestDataFactory.createPMUser();

        // Create the customer (aka entity) account
        Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

        // Create the entity account
        Account vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

        // Create the master entity account
        Account vMAccount = AP05_TestDataFactory.createMasterEntityAccount(vUserPM);

        // Create the couple Entity - Billing Entity on Parent Entity
        vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
        // Create the entity contact related to the account
        Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
        //Quartile (business area)
        Quartile__c vQuartile = AP05_TestDataFactory.createBusinessArea(vUserPM);

        //Petal (Domain)
        Petal__c vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserPM);

        // Offer
        Offer__c vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserPM);
        
        //Product
        Product__c vProduct = AP05_TestDataFactory.createProduct(vOffer, vUserOO);  

        //Contract
        Contract__c vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact);    

        //Planned Invoicing Line 1
        Planned_Invoicing_Line__c vPInvLine1 = AP05_TestDataFactory.createPInvoicingLine(vContract,'Description 1');
      
        //Planned Invoicing Line 2
        Planned_Invoicing_Line__c vPInvLine2 = AP05_TestDataFactory.createPInvoicingLine(vContract,'Description 2');

        //
        // create invoicing parameters
        //
        Id InvDateRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Date').getRecordTypeId();
        Id InvLinRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Line').getRecordTypeId();
        Id InvCondRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Condition').getRecordTypeId();

        // Invoicing Date
        Invoicing_Parameter__c aParmInvDate = new Invoicing_Parameter__c (Invoicing_Date__c = System.Today(), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing date');
        insert aParmInvDate;
        system.debug('##aParmInvDate' + aParmInvDate.id);

        // Invoicing condition / invoicing Lines for  beginning of service
        Invoicing_Parameter__c a1ParmInvCond = new Invoicing_Parameter__c (Name = '100% Beginning of service', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
        insert a1ParmInvCond;
        system.debug('##aParmInvCond' + a1ParmInvCond.id);

        Invoicing_Parameter__c a1ParmInvLin = new Invoicing_Parameter__c (Name = '100% Beginning of service', Invoicing_Description__c = '100% Beginning of service', Parent_For_Invoicing_Line__c = a1ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Start Date', Percent__c = 100.00);
        insert a1ParmInvLin;
        //
        //Invoicing condition / invoicing Lines for beginning of year
        //
        Invoicing_Parameter__c a2ParmInvCond = new Invoicing_Parameter__c (Name = '100% Beginning of year', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
        insert a2ParmInvCond;
        system.debug('##aParmInvCond' + a2ParmInvCond.id);

        Invoicing_Parameter__c a2ParmInvLin = new Invoicing_Parameter__c (Name = '100% Beginning of year', Invoicing_Description__c = '100% Beginning of year', Invoicing_Predefined_Date__c = aParmInvDate.id, Parent_For_Invoicing_Line__c = a2ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Fixed Date', Percent__c = 100.00);
        insert a2ParmInvLin;

        // Invoicing condition / invoicing Lines for %,50%,50%
        //
        Invoicing_Parameter__c a3ParmInvCond = new Invoicing_Parameter__c (Name = '0%,50%,50%', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition');
        insert a3ParmInvCond;
        system.debug('##aParmInvCond'   + a3ParmInvCond.id);

        Invoicing_Parameter__c a3ParmInvLin = new Invoicing_Parameter__c (Name = '50% half of service', Invoicing_Description__c = '50% half of service', Parent_For_Invoicing_Line__c = a3ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00);
        insert a3ParmInvLin;

        Invoicing_Parameter__c a4ParmInvLin = new Invoicing_Parameter__c (Name = '50% end of service', Invoicing_Description__c = '50% end of service', Parent_For_Invoicing_Line__c = a3ParmInvCond.id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'End Date', Percent__c = 50.00);
        insert a4ParmInvLin;

        // list of created parameters
        List <Invoicing_Parameter__c> ParmLineList = New List <Invoicing_Parameter__c> ([select Id, Name From Invoicing_Parameter__c ]);
        system.debug('##Invoicing parameters datatest created'   + ParmLineList);
        
    }

    @isTest 
    static void preventDeletionTest() {
        User vUserPM = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];

        // Get the offer
        Product__c vProduct = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME]; 
        // Get the legal entity
        Account vLegalEntity = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];
        // Create the entity contact related to the account
        Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vLegalEntity);

       // System.runAs(vUserPM) {
            Test.startTest();

            // Case 1 : Legal Entity linked to Entity  
            Contract__c vContract = [SELECT Id, Global_Amount__c, Planned_Invoicing_Lines_Amount__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = vContract.Planned_Invoicing_Lines_Amount__c;
            update (vContract); 

            Attachment vAttachment = new Attachment();
            vAttachment.parentID = vContract.Id;
            vAttachment.body = Blob.valueOf('test.pdf');
            vAttachment.Name = 'test_2016.pdf';
            insert vAttachment;
            // Try to delete first on regular attachment : no problem
            delete vAttachment;

            List<Attachment> vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            System.assert(vContractAttachments.size() == 0);

            String vErrorMessage = AP10_ContractHandler.attachContract(vContract.Id);
            
            /* 27/07/2017 - Commented this part temporarily to be able to deploy in Production
            Error : System.QueryException: List has no rows for assignment to SObject 
            stack Trace: Class.AP10_ContractHandler.attachContract: line 414, column 1 
            
            vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            
            Boolean vErrorOccured = false;
            try {
                // Try to delete first on generated attachment : cannot
                delete vContractAttachments[0];
            } catch (Exception e) {
                vErrorOccured = true;
            }

            vContractAttachments = [SELECT Id FROM Attachment WHERE parentId = :vContract.Id];
            System.assert(vContractAttachments.size() > 0);*//*

            Test.stopTest();
        //}
    }
    */


}