/*
    About
    -----
    Description: Class Test_Ctrl_ContractsToSign 
    Created for: Axa Project
    Create date: 03/ 2015
    Created by Jamal Rida

    Details
    -------
    This class is  : used as a Test class for : Ctrl_ContractsToSign
        
    
    Update History
    --------------    
*/

@isTest
private class VFC36_ContractsToSign_TEST {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
      User use = TestFactory.createUser('testUser', UserInfo.getProfileId() ,true);
      use.PAD_BypassValidationRules__c = true;
      use.cTin_LegalRepresentative__c = true;
      use.IsActive = true;
      
    insert use;
    System.runAs(use){
      PageReference pageRef = Page.VFP36_ContractsToSign;
      
      Map<String,ID> MapContactRT = new Map<String,ID>(); 
      Id AxaRtId ;
      
      Map<String,ID> MapEsignatoryRT = new Map<String,ID>(); 
      Id EsignRtId ;
      
      MapContactRT = TestFactory.MapRecordType('Contact');
      AxaRtId = MapContactRT.get('cTin_AXA');
      
      MapEsignatoryRT = TestFactory.MapRecordType('eSignatory__c');
      EsignRtId = MapEsignatoryRT.get('cTin_AXA_Representative');
      
      Account supplier = TestFactory.createSupplier('TestSupplier', 'testCity','France');
      insert supplier;
      
      Contact myContact = TestFactory.createContact(supplier,'TestFirstName','TestLastName');
          myContact.RecordTypeID = AxaRtId;
          myContact.cTin_RelatedUser__c = use.Id;
          
        insert myContact;
      Contract__c contract = TestFactory.createContract(supplier.id, 'TestContractName','Draft');
            
      insert contract;
      
      eSignature__c myEsign = TestFactory.createEsignature(contract,    'TestEsign', 'Created');
        insert myEsign;
        
      eSignatory__c myEsignatory = TestFactory.createEsignatory(contract, myEsign, 'TestEsignatory',myContact.id ,'Pending');
          myEsignatory.RecordTypeId = EsignRtId;
          myEsignatory.EmailTxt__c = use.Email;
          myEsignatory.Status__c = 'Ready';
          myEsignatory.Contact__c = myContact.Id;
          myEsignatory.cTin_Role__c = 'AXA Representative';
          myEsignatory.signURL__c = 'https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';
        insert myEsignatory;
      
      VFC36_ContractsToSign controller = new VFC36_ContractsToSign();
        controller.showSignature();
        
    }
    }
}