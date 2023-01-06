/**
 * Created by Urvashi on 27/04/2020.
 */

public with sharing class AP32_ManageContractResiliation {
/*
--------------------------------------------------------------------------------------
-- - Name          : AP32_ManageContractResiliation
-- - Author        : Spoon Consulting
-- - Description   : Cancel invoicing lines and eSignatures when contract is resiliated
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 27-APR-2020  USA    1.0     Initial version [SP-00221]
--------------------------------------------------------------------------------------*/
    public static void manageContractResiliation(Map<id,Contract__c> mapCtr){
        //update ILs
        String strResultIL = '';
        String strResultESig = '';
        Set<Id> seteSigID = new Set<Id>();
        map<Id, Planned_Invoicing_Line__c> mapILtoUpdate = new map<Id, Planned_Invoicing_Line__c>(
            [SELECT id, status__c, contract2__c
            FROM Planned_Invoicing_Line__c
            WHERE contract2__c IN :mapCtr.KeySet()
            AND status__c IN ('01', '02')]);

        if (mapILtoUpdate.size() > 0){
            strResultIL = cancelInvLines(mapILtoUpdate);
        }
        //update eSignatures
//        map<Id, eSignature__c> mapESig = new map<Id, eSignature__c>(
//        [SELECT Id, Status__c, transactionId__c, Contract__c, (SELECT Id, status__c FROM eSignatories__r)
//            FROM eSignature__c
//            WHERE Contract__c IN :mapCtr.KeySet()
//            AND Status__c != 'Completed']);

        for (eSignature__c esig :[SELECT Id, Status__c, transactionId__c, Contract__c FROM eSignature__c
                                        WHERE Contract__c IN :mapCtr.KeySet()
                                        AND Status__c != 'Completed'
                                        AND Status__c != 'Cancelled']){
            seteSigID.add(esig.Id);
        }

        if (seteSigID.size() > 0){
            cancelEsignature(seteSigID);
        }
    }

    public static String cancelInvLines(map<Id, Planned_Invoicing_Line__c> mapIL){
        for (Planned_Invoicing_Line__c pil :mapIl.values()){
            pil.Status__c = '99';
        }
        try {
            update mapIL.values();
            return null;
        }
        catch (exception e) {
            return e.getMessage();
        }
    }

    @future(callout=true)
    public static void cancelEsignature(Set<Id> seteSig){
        String message = '';
        map<Id,List<eSignatory__c>> mapeSigSiglst = new map<Id,List<eSignatory__c>>();
        List<esignature__c> lstEsig = new List<esignature__c>();
        List<esignature__c> lstEsigUpdate = new List<esignature__c>();
        List<eSignatory__c> lstEsignatoryUpdate = new List<eSignatory__c>();

        list<eSignatory__c> eSignatoryLst = [SELECT Id, status__c,esignature__r.status__c, esignature__r.transactionId__c,
                                                esignature__r.Contract__c,esignature__r.Language__c, esignature__c,
                                                esignature__r.CreatedById,esignature__r.HandWrittenSignatureMode__c
                                        FROM eSignatory__c
                                        WHERE eSignature__c  IN :seteSig];
        for (eSignatory__c eSignatory :eSignatoryLst){
            if (mapeSigSiglst.containsKey(eSignatory.eSignature__c)){
                mapeSigSiglst.get(eSignatory.eSignature__c).add(eSignatory);
            }
            else {
                mapeSigSiglst.put(eSignatory.eSignature__c, new list<eSignatory__c>{eSignatory});
                eSignature__c eSignature = new eSignature__c(Id = eSignatory.eSignature__c, transactionId__c = eSignatory.esignature__r.transactionId__c, Contract__c = eSignatory.esignature__r.Contract__c);
                lstEsig.add(eSignature);
            }
        }

        for(eSignature__c eSig :lstEsig) {
            if (eSig.transactionId__c != null) {
                try {
                    AP22_XmlRpcWrapper.WrapperResponse res = AP22_XmlRpcWrapper.CreateXmlRpcForCancel(eSig, eSig.TransactionID__c, mapeSigSiglst.get(eSig.Id));
                    if (res.FaultMessage == '') {
                        message = null;
                    } else {
                        message = res.FaultMessage;
                    }
                }
                Catch (Exception xmlERR) {
                    message = xmlERR.getMessage();
                }
            }
            else {
                eSig.Status__c = Ap_Constant.eSignatureCancelledStatus;
                lstEsigUpdate.add(eSig);
                for (eSignatory__c eSigUpdate :mapeSigSiglst.get(eSig.Id)){
                    eSigUpdate.Status__c = Ap_Constant.eSignatureCancelledStatus;
                    lstEsignatoryUpdate.add(eSigUpdate);
                }
            }
        }
        if (lstEsigUpdate.size() > 0){
            update lstEsigUpdate;
        }
        if (lstEsignatoryUpdate.size()>0){
            update lstEsignatoryUpdate;
        }
    }
}