// class from Lucy Project (VFC18_UploadDocument_Test )
@isTest
public class VFC15_UploadDocument_Test {
    Static User testUser;
    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.Company__c = AP_Constant.GS_ENTITY_AXA_GR_OP_BG;
        insert testUser;
    }

    @isTest
    static void VFC18_UploadDocument_Test() {
        System.runAs(testUser){
        // Create AM user
        User vUserAM = AP05_TestDataFactory.createAMUser();

        // Create the account related to the offer
        Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserAM);

        // Create the entity account
        Account vEAccount = AP05_TestDataFactory.createEntityAccount(vUserAM);

        // Create the couple Entity - Billing Entity on Parent Entity 
        vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

        // Create the entity contact related to the account
        Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vEAccount);

        // Create the entity contact related to the account
        User vAXAGSUser = AP05_TestDataFactory.createAXAGSUser(vAccount);

        // Create OO user
        User vUserOO = AP05_TestDataFactory.createOOUser();

        // Create Opty owner user
        User vUserOptyUser = AP05_TestDataFactory.createOptyOwnerUser();

        //Quartile (business area)
        /*Quartile__c vQuartile = AP05_TestDataFactory.createBusinessArea(vUserOO);

        //Petal (Domain)
        Petal__c vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserOO);

        // Offer
        Offer__c vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserOO);*/
        
        //Produc
        Product__c vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);

        // Create the Opportunity
        Opportunity vOpportunity = AP05_TestDataFactory.createOpportunityStageCollect(vEAccount, vProduct);
        User vUserAXA = [SELECT Name, Id FROM User WHERE UserName = :AP05_TestDataFactory.USER_AM_USERNAME];
        //System.runAS(vUserAXA) {
            Opportunity vOpp = vOpportunity;
            vOpp.Category__c = Label.OptyCategory_Project;

            Test.startTest();

            ApexPages.StandardController sc = new ApexPages.standardController(vOpp);
            VFC15_UploadDocument vController = new VFC15_UploadDocument(sc);
            vController.selectedOption = 'PAS';

            vController.loadData();
            System.assert(vController.Opp.Id != null, 'vController.Opp.Id should be different from null but it is : ' + vController.Opp.Id);

            vController.getItems();
            //System.assert(vController.getItems().size() == 4, 'vController.getItems().size() should be 4 but it is : ' + vController.getItems().size());            

            Attachment vAttachment = new Attachment();
            vAttachment.Name = 'Test Name';
            vAttachment.Description = 'PAS';
            vAttachment.Body = Blob.valueOF('Test Body');
            vController.uploadeddocument = vAttachment;
            vController.uploadDocument();
            
            // optional document
            vOpp.AXA_GO_Entity__c = Label.Opty_AxaGSEntity_Asia;

            vController.loadData();

            Test.stopTest();
        }
    }
}