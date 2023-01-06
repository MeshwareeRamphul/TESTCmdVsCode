@isTest
private class WS03_SAPLegalEntity_TEST
{
    /* 
--------------------------------------------------------------------------------------
-- - Name          : WS03_SAPLegalEntity_TEST
-- - Author        : SC 
-- - Description   : Test class for WS03_SAPLegalEntity
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 28-JUN-2017  MCU    1.0     Initial version
--------------------------------------------------------------------------------------
*/  


    @isTest
    static void WS01_CreateAccountSuccess()
    
    {
        list<WS03_SAPLegalEntity.wrapperParams> lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

        WS03_SAPLegalEntity.wrapperParams var = new WS03_SAPLegalEntity.wrapperParams();

        var.LegalName = 'Test';
        var.GIE = true;
        lstparams.add(var);

        List <WS03_SAPLegalEntity.wrapperResponse> lstwrapperResponse = new list <WS03_SAPLegalEntity.wrapperResponse> ();

        Test.setMock(WebServiceMock.class, new WS03_SAPLegalEntityMock());
        Test.startTest();
            lstwrapperResponse = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
        Test.stopTest();
    }

    @isTest
    static void WS01_CreateAccountError()
    
    {
        list<WS03_SAPLegalEntity.wrapperParams> lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

        WS03_SAPLegalEntity.wrapperParams var = new WS03_SAPLegalEntity.wrapperParams();

        var.GIE = true;
        lstparams.add(var);

        List <WS03_SAPLegalEntity.wrapperResponse> lstwrapperResponse = new list <WS03_SAPLegalEntity.wrapperResponse> ();

        Test.setMock(WebServiceMock.class, new WS03_SAPLegalEntityMock());
        Test.startTest();
            lstwrapperResponse = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
        Test.stopTest();
    } 
    
        @isTest
    static void WS01_CreateAccountSuccess2(){

        WS03_SAPLegalEntity.wrapperParams legal = new WS03_SAPLegalEntity.wrapperParams();
		list<WS03_SAPLegalEntity.wrapperParams> lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

	    legal.LegalName='TEST Legal SC001';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00001';
	    legal.VAT='VAT SC001';
	    legal.GIE=TRUE;
	    legal.LegalEntityId='0001';
	    lstparams.add(legal);

		list<WS03_SAPLegalEntity.wrapperResponse> response = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
		
		system.assertEquals('SC00001',response[0].Vendor);
		system.assertEquals('OK',response[0].Status);
		
		legal = new WS03_SAPLegalEntity.wrapperParams();
		lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

	    legal.LegalName='TEST Legal SC001';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00001';
	    legal.VAT='VAT SC001';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    list<WS03_SAPLegalEntity.wrapperResponse> newresponse = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
	    system.assertEquals('SC00001',newresponse[0].Vendor);
		system.assertEquals('OK',newresponse[0].Status);
		system.assertEquals(response[0].SFDCID,newresponse[0].SFDCID);
    }
    
    @isTest
    static void WS01_CreateAccountSuccess3(){

        WS03_SAPLegalEntity.wrapperParams legal = new WS03_SAPLegalEntity.wrapperParams();
		list<WS03_SAPLegalEntity.wrapperParams> lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

	    legal.LegalName='TEST Legal SC001';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00001';
	    legal.VAT='VAT SC001';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC002';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00002';
	    legal.VAT='VAT SC002';
	    legal.GIE=TRUE;
	    legal.LegalEntityId='0002';
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC003';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00003';
	    legal.VAT='VAT SC003';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC004';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00004';
	    legal.VAT='VAT SC004';
	    legal.GIE=TRUE;
	    legal.LegalEntityId='0004';
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC005';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00005';
	    legal.VAT='VAT SC005';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
		list<WS03_SAPLegalEntity.wrapperResponse> response = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
		
		system.assertEquals('SC00001',response[0].Vendor);
		system.assertEquals('SC00002',response[1].Vendor);
		system.assertEquals('SC00003',response[2].Vendor);
		system.assertEquals('SC00004',response[3].Vendor);
		system.assertEquals('SC00005',response[4].Vendor);
		system.assertEquals('OK',response[0].Status);
		system.assertEquals('OK',response[1].Status);
		system.assertEquals('OK',response[2].Status);
		system.assertEquals('OK',response[3].Status);
		system.assertEquals('OK',response[4].Status);
		
		legal = new WS03_SAPLegalEntity.wrapperParams();
		lstparams = new list<WS03_SAPLegalEntity.wrapperParams>();

	    legal.LegalName='TEST Legal SC001';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00001';
	    legal.VAT='VAT SC001';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC002';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00002';
	    legal.VAT='VAT SC002';
	    legal.GIE=TRUE;
	    legal.LegalEntityId='0002';
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC003';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00003';
	    legal.VAT='VAT SC003';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC004';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    legal.Vendor='SC00004';
	    legal.VAT='VAT SC004';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
	    
	    legal = new WS03_SAPLegalEntity.wrapperParams();
	    legal.LegalName='TEST Legal SC005';
	    legal.Country='MU';
	    legal.Street='Street Test';
	    legal.City='City Thuafd ifg';
	    legal.PostalCode ='81456';
	    legal.Language='English';
	    legal.Email='test@testco.com';
	    //legal.Vendor='SC00005';
	    legal.VAT='VAT SC005';
	    legal.GIE=TRUE;
	    lstparams.add(legal);
		list<WS03_SAPLegalEntity.wrapperResponse> newresponse = WS03_SAPLegalEntity.upsertLegalEntity(lstparams);
		system.assertEquals('SC00001',newresponse[0].Vendor);
		system.assertEquals('SC00002',newresponse[1].Vendor);
		system.assertEquals('SC00003',newresponse[2].Vendor);
		system.assertEquals('SC00004',newresponse[3].Vendor);
		system.assertEquals(null,newresponse[4].Vendor);
		system.assertEquals('OK',newresponse[0].Status);
		system.assertEquals('OK',newresponse[1].Status);
		system.assertEquals('OK',newresponse[2].Status);
		system.assertEquals('OK',newresponse[3].Status);
		system.assertEquals('KO',newresponse[4].Status);
		system.assertEquals(response[0].SFDCID,newresponse[0].SFDCID);
		system.assertEquals(response[1].SFDCID,newresponse[1].SFDCID);
		system.assertEquals(response[2].SFDCID,newresponse[2].SFDCID);
		system.assertEquals(response[3].SFDCID,newresponse[3].SFDCID);
		system.assertEquals(null,newresponse[4].SFDCID);
		//system.assertEquals('',newresponse[4].Message);
    }

}