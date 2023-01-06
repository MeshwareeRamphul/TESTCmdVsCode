public class AP55_UncheckPeopleSoftSync {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP55_UncheckPeopleSoftSync
-- - Author        : ARA
-- - Description   : unchecks PeopleSoft Sync on contract
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 30-APR-2019  ARA    1.0     Update contract to be resend to People Soft
*****************************************************************************************/
	
	//method unchecks the option "PeopleSoftSync" after updating on status or Customer legal entity 
    public static void uncheckPeopleSoftSync(list<Contract__c> lstCtr){
        for (Contract__c ctr : lstCtr){
            ctr.Peoplesoft_Sync__c = false;
        }
    }
}