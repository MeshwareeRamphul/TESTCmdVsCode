Global class AP10_ContractHandler {
    /*
    OTC_CL_CL_ContractGeneralHandler
    ----------------------------------------------------------------------
    -- - Name          : AP10_ContractHandler
    -- - Author        : JFF
    -- - Description   : Class for managing contract
    --
    -- Invoicing date History:
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 12-JUNE-2015  JFF    1.0      Initial version
    -- 15-JULY-2015  NG     1.1      Reviewed and optimized code
    -- 27-JULY-2015  NG     1.2      Added currency consitency between Contract and Invoicing Lines
    -- 08-AUG-2015   NG     1.3      Changed code to handle renamed Object Invoicing_Lines__c into Planned_Invoicing_Lines__c
    -- 09-NOV-2015   NG     2.0      Added method attachContract as webservice
    -- 28-APR-2016   MRA    1.5      Updated method attachContract to generate content delivery for the contract when PDF is updated
    -- 19-JAN-2018   USA    1.6      Update picklist values AXA legal entity 
    -- 18-MAR-2018   USA    1.7      Manage ATS pdf templates
    -- 04-APR-2018   USA    1.8      Update getMonthlyInvDates for monthly invoicing condition
    -- 21-SEP-2018   USA    1.9      Temporarily add error message for contrats with MSA and SOW Type = Enveloppe 
    -- 24-OCT-2018   USA    2.0      Integration PeopleSoft
    -- 26-NOV-2018   USA    2.1      Convergence Template AGS FRANCE
    -- 01-JAN-2018   USA    2.2      PeopleSoft - sendCtrlightoPeopleSoft method for Send to PeopleSoft button 
    -- 04-feb-2019   USA    2.3      Mise a jour generation des ILs - monthly 
    -- 10-JUN-2019   USA    2.4      SP-00072
    -- 21-APR-2020   USA    2.5      SP-00218
    -- 25-JUN-2020   USA    2.6      SP-00320 (Code Optimisation - pushCreationToOpportunity)
    -- 13-JUL-2022   ARA    2.7      SP-01927 (Mandatory field to generate IL)
    ----------------------------------------------------------------------
    */

    /*----------------------------------------------------------------------
     Called by JavaScript button, selects relevant Contract fields, calls validation CheckContract method,
     and calls GenerateInvoicing Method
    ----------------------------------------------------------------------
    */

    // HVA 10-2017 : AXA All In - Merge ContractIn
    public static Set<String> setCtinRecTypeId = AP_Constant.getCTinRecordTypes('Contract__c');

    Webservice static string GenerateAContractPInvoicingLine(Id CtrId) {
        string Msg;
        system.debug('##Starting GenerateAContractInvoicingLine CtrId : ' + CtrId );
        List<Contract__c> CtrList = New List <Contract__c>();
        CtrList = [SELECT Id, Invoicing_condition__c, Customer_Operational_Contact__c, Language__c, Global_Amount__c, Name, StartDate__c, EndDate__c, CurrencyIsoCode, Master_WBS_2__c/*, Master_WBS__c */
                   FROM Contract__c 
                   WHERE Id = :CtrId Limit 1];

        Msg = CheckContract(CtrList[0]);
        If ( Msg != '') { return Msg; }
        Map<Id, Contract__c>  ctrMap = new Map<Id, Contract__c>() ;
        ctrMap.Put(CtrId, CtrList[0]);
        Msg = GeneratePInvoicingLine(ctrMap);
        return Msg;
    }


    /*
    /-----------------------------------------------------------------------------------------
    /Generates monthly Planned Invoicing Line(s)
    /-----------------------------------------------------------------------------------------
    */
    /*Public static list<Planned_Invoicing_Line__c> GenerateMonthlyPILs(Contract__c curCtr, list<Invoicing_Parameter__c> InvDateList) {
        system.debug('## START GenerateMonthlyPILs');
        list<Planned_Invoicing_Line__c> lstMonthlyPILs = new list<Planned_Invoicing_Line__c>();

        Integer intNoMonths = curCtr.StartDate__c.monthsBetween(curCtr.EndDate__c) + 1; 
        Decimal dividedAmt = curCtr.Global_amount__c/intNoMonths;
        Decimal culmulatedAmt = 0.00; 

        List<Invoicing_Parameter__c> lstPILDates = getMonthlyInvDates(curCtr.StartDate__c, intNoMonths, InvDateList);

        for (Integer i=0; i<intNoMonths;i++){
            Planned_Invoicing_Line__c aInvoicingLine = new Planned_Invoicing_Line__c();
            aInvoicingLine.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
            aInvoicingLine.Type__c = 'Invoicing Line';
            aInvoicingLine.Master_WBS_Structure__c = curCtr.Master_WBS_2__c;
            aInvoicingLine.Contract2__c = curCtr.Id;
            aInvoicingLine.Customer_contact__c  = curCtr.Customer_Operational_Contact__c;
            aInvoicingLine.AmountIL__c = dividedAmt.setScale(2, RoundingMode.HALF_UP);
            aInvoicingLine.CurrencyIsoCode = curCtr.CurrencyIsoCode;
            //aInvoicingLine.Invoicing_Predefined_Date__c = lstPILDates[i].Id;
            aInvoicingLine.Inv_Predefined_Date__c = lstPILDates[i].Invoicing_Date__c;
            aInvoicingLine.WBS__c = curCtr.Master_WBS__c != null ? curCtr.Master_WBS__c : aInvoicingLine.WBS__c;

            culmulatedAmt = culmulatedAmt + dividedAmt.setScale(2, RoundingMode.HALF_UP);
            lstMonthlyPILs.add(aInvoicingLine);
        }
        // handle rounding issues of decimal numbers
        if ((curCtr.Global_amount__c - culmulatedAmt) != 0.00){
            lstMonthlyPILs[lstMonthlyPILs.size()-1].AmountIL__c = lstMonthlyPILs[lstMonthlyPILs.size()-1].AmountIL__c + (curCtr.Global_amount__c - culmulatedAmt);
        }
        return lstMonthlyPILs; 
    }*/
    /*
    /-----------------------------------------------------------------------------------------
    /Generates monthly Planned Invoicing Line(s)
    /-----------------------------------------------------------------------------------------
    */

    /*public static List<Invoicing_Parameter__c> getMonthlyInvDates(Date startDate, Integer noOfPILs, list<Invoicing_Parameter__c> InvDateList){
        system.debug('## START getMonthlyInvDates');
        List<Invoicing_Parameter__c> lstPILDates = new List<Invoicing_Parameter__c>();
        Integer curMonth = startDate.day() > AP_Constant.INT_INVDATE ? startDate.month() + 1 : startDate.month();
        Integer curYear = startDate.year();
        Boolean curDateGINT_INVDATE = startDate.day() > AP_Constant.INT_INVDATE; 
        Integer doubleInvLine = 1; 
        for (Invoicing_Parameter__c invParam : InvDateList){
            if ((invParam.Invoicing_Date__c.month() > curMonth) && (invParam.Invoicing_Date__c.year() == curYear) && (invParam.Invoicing_Date__c >= startDate)){
                curMonth = invParam.Invoicing_Date__c.month();
            }
            if ((invParam.Invoicing_Date__c.month() == curMonth) && (invParam.Invoicing_Date__c >= startDate)){
                lstPILDates.add(invParam);
                if (curDateGINT_INVDATE && doubleInvLine == 1){
                    lstPILDates.add(invParam);
                    doubleInvLine++; 
                }
                curYear = invParam.Invoicing_Date__c.month() == 12? invParam.Invoicing_Date__c.year()+1 :invParam.Invoicing_Date__c.year();
                curMonth = invParam.Invoicing_Date__c.month() == 12? 1 :invParam.Invoicing_Date__c.month() + 1;
            }
            if (lstPILDates.size() == noOfPILs){
                break;
            }
        }
        system.debug('##ap10_getMonthlyInvDates## lstPILDates : ' + lstPILDates);
        return lstPILDates;
    }*/

    /*
    /-----------------------------------------------------------------------------------------
    /Generates Planned Invoicing Line(s) for invoicing condition 30% Down Payment + Quarterly
    /-----------------------------------------------------------------------------------------
    */
    /*Public static list<Planned_Invoicing_Line__c> GenerateDownPaymentQuarterly(Contract__c curCtr, list<Invoicing_Parameter__c> InvDateList) {
        system.debug('## START GenerateDownPaymentQuarterly');
        list<Planned_Invoicing_Line__c> lstPILs = new list<Planned_Invoicing_Line__c>();
        Decimal culmulatedAmt = 0.00;

        system.debug('## GenerateDownPaymentQuarterly : ' + curCtr.StartDate__c + ' - ');
        List<Invoicing_Parameter__c> lstPILDates = getDownPaymentQuarterlyInvDates(curCtr.StartDate__c, 4, InvDateList);

        for (Integer i=0; i<4;i++){
            Planned_Invoicing_Line__c aInvoicingLine = new Planned_Invoicing_Line__c();
            aInvoicingLine.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
            aInvoicingLine.Type__c = 'Invoicing Line';
            aInvoicingLine.Master_WBS_Structure__c = curCtr.Master_WBS_2__c;
            aInvoicingLine.Contract2__c = curCtr.Id;
            aInvoicingLine.Customer_contact__c  = curCtr.Customer_Operational_Contact__c;
            aInvoicingLine.CurrencyIsoCode = curCtr.CurrencyIsoCode;
            //aInvoicingLine.Invoicing_Predefined_Date__c = lstPILDates[i].Id;
            aInvoicingLine.Inv_Predefined_Date__c = lstPILDates[i].Invoicing_Date__c;
            aInvoicingLine.WBS__c = curCtr.Master_WBS__c != null ? curCtr.Master_WBS__c : aInvoicingLine.WBS__c;
            if (i==0){
                aInvoicingLine.AmountIL__c = (curCtr.Global_amount__c*0.3).setScale(2, RoundingMode.HALF_UP);
            }
            else if (i==1){
                aInvoicingLine.AmountIL__c = (curCtr.Global_amount__c*0.24).setScale(2, RoundingMode.HALF_UP);
            }
            else if (i==2){
                aInvoicingLine.AmountIL__c = (curCtr.Global_amount__c*0.23).setScale(2, RoundingMode.HALF_UP);
            }
            else if (i==3){
                aInvoicingLine.AmountIL__c = (curCtr.Global_amount__c*0.23).setScale(2, RoundingMode.HALF_UP);
            }
            culmulatedAmt = culmulatedAmt + aInvoicingLine.AmountIL__c;
            lstPILs.add(aInvoicingLine);
        }
        // handle rounding issues of decimal numbers
        if ((curCtr.Global_amount__c - culmulatedAmt) != 0.00){
            lstPILs[lstPILs.size()-1].AmountIL__c = lstPILs[lstPILs.size()-1].AmountIL__c + (curCtr.Global_amount__c - culmulatedAmt);
        }
        system.debug('##lstPILS: ' + lstPILs);
        return lstPILs;
    }*/

    /*public static List<Invoicing_Parameter__c> getDownPaymentQuarterlyInvDates(Date startDate, Integer noOfPILs, list<Invoicing_Parameter__c> InvDateList){
        system.debug('## START getDownPaymentQuarterlyInvDates');
        List<Invoicing_Parameter__c> lstPILDates = new List<Invoicing_Parameter__c>();
        Integer curMonth = startDate.day() > AP_Constant.INT_INVDATE ? startDate.month() + 1 : startDate.month();
        Integer curYear = startDate.year();

        for (Invoicing_Parameter__c invParam : InvDateList){
            system.debug('##getDownPaymentQuarterlyInvDates## : ' + invParam.Invoicing_Date__c );
            if ((invParam.Invoicing_Date__c.month() > curMonth) && (invParam.Invoicing_Date__c.year() == curYear) && (invParam.Invoicing_Date__c >= startDate)){
                curMonth = invParam.Invoicing_Date__c.month();
            }
            if ((invParam.Invoicing_Date__c.month() == curMonth) && (invParam.Invoicing_Date__c >= startDate)){
                lstPILDates.add(invParam);
                curYear = invParam.Invoicing_Date__c.month() > 9? invParam.Invoicing_Date__c.year()+1 :invParam.Invoicing_Date__c.year();
                curMonth = invParam.Invoicing_Date__c.month() > 9? (invParam.Invoicing_Date__c.month() + 3 - 12) :invParam.Invoicing_Date__c.month() + 3;
            }
            if (lstPILDates.size() == noOfPILs){
                break;
            }
        }
        system.debug('##getDownPaymentQuarterlyInvDates## lstPILDates : ' + lstPILDates);
        return lstPILDates;
    }*/


    /*
    /-----------------------------------------------------------------------------------------
    /Generates the Planned Invoicing Line(s)
    /-----------------------------------------------------------------------------------------
    */
    Public static string GeneratePInvoicingLine(Map<Id, Contract__c> CtrMap) {
        system.debug('## start GeneratePInvoicingLine');
        string Msg;
         if (!CtrMap.isEmpty()) {
            // Create the list of all contracts
            List  <Contract__c> CtrList = new List <Contract__c> (CtrMap.values());
            // Retrives and deletes existing contract line item
            list<Planned_Invoicing_Line__c> CtrPInvoicingLineListToDel = new list <Planned_Invoicing_Line__c>([SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c in:CtrMap.keySet() and Type__c = 'Invoicing Line']) ;
            //System.debug('##After instanciation delete list item: ' + CtrPInvoicingLineListToDel.size());
            if (CtrPInvoicingLineListToDel.size() > 0) {
                try { Delete CtrPInvoicingLineListToDel; }
                catch (DmlException Dmle ) { Msg = SetDmlErrorMsg (Dmle); }
            }
            // Retrieves the list of Invoicing dates
            list<Invoicing_Parameter__c> InvDateList = New list <Invoicing_Parameter__c>([SELECT Id, Name, Invoicing_Date__c FROM Invoicing_Parameter__c WHERE parameter_Type__c = 'Invoicing Date' ORDER BY Tech_InvParamName__c]);
            // Retrieves the List of all Invoicing Lines Parameters
            list<Invoicing_Parameter__c> AllInvLineList = New list <Invoicing_Parameter__c> ([SELECT Id, Invoicing_Date__c, Invoicing_Predefined_Date__r.Invoicing_Date__c, Invoicing_Predefined_Date__r.Id, Invoicing_description__c, Invoicing_description_FRA__c, Invoicing_Date_Type__c, Percent__c, Parent_For_Invoicing_Line__r.Name FROM Invoicing_Parameter__c WHERE Parameter_Type__c = 'Invoicing Line' ORDER BY Invoicing_Line_Order__c]);
            // Creates a list for the Invoicing Lines
            list<Planned_Invoicing_Line__c> CtrPInvoicingLineList = new list<Planned_Invoicing_Line__c>();
            list<Planned_Invoicing_Line__c> lstMonthlyPILsReturned = new list<Planned_Invoicing_Line__c>();
             list<Planned_Invoicing_Line__c> lstPILsReturned = new list<Planned_Invoicing_Line__c>();
            For (Contract__c ctr : CtrList) {
                system.debug('## USA GeneratePInvoicingLine ctr.Invoicing_Condition__c : ' + ctr.Invoicing_Condition__c);

                if (ctr.Invoicing_Condition__c == 'Monthly'){
                    /*lstMonthlyPILsReturned = GenerateMonthlyPILs(ctr, InvDateList);
                    if (lstMonthlyPILsReturned.size() > 0){
                        CtrPInvoicingLineList.addAll(lstMonthlyPILsReturned);
                    }*/
                }
                else if (ctr.Invoicing_Condition__c == '30% Down Payment + Quarterly'){
                    /*lstPILsReturned = GenerateDownPaymentQuarterly(ctr, InvDateList);
                    system.debug('## USA dwnMonth lstPILsReturned size : ' + lstPILsReturned.size());
                    if (lstPILsReturned.size() > 0){
                        CtrPInvoicingLineList.addAll(lstPILsReturned);
                    }*/
                }
                else{
                    for (Invoicing_Parameter__c aParmInvoicingLine : AllInvLineList) {
                        if (aParmInvoicingLine.Parent_For_Invoicing_Line__r.Name == ctr.Invoicing_Condition__c ) {
                            //Creates new line and sets parentId, Description, Amount values
                            Planned_Invoicing_Line__c aInvoicingLine = new Planned_Invoicing_Line__c();
                            aInvoicingLine.RecordTypeId            = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
                            aInvoicingLine.Type__c                 = 'Invoicing Line';
                            aInvoicingLine.Master_WBS_Structure__c = ctr.Master_WBS_2__c;
                            aInvoicingLine.Contract2__c            = ctr.Id;
                            //aInvoicingLine.Customer_contact__c     = ctr.Customer_Operational_Contact__c;
                            aInvoicingLine.Percent__c              = aParmInvoicingLine.Percent__c;
                            aInvoicingLine.Activity_Type__c        = ctr.language__c == 'French' ? aParmInvoicingLine.Invoicing_Description_FRA__c : aParmInvoicingLine.Invoicing_Description__c;
                            aInvoicingLine.AmountIL__c             = (ctr.Global_amount__c * aParmInvoicingLine.Percent__c) / 100;
                            aInvoicingLine.CurrencyIsoCode         = ctr.CurrencyIsoCode;
                            //aInvoicingLine.WBS__c                  = ctr.Master_WBS__c != null ? ctr.Master_WBS__c : aInvoicingLine.WBS__c;
                            //Sets Invoicing Predefined Date according Invoicing Date Type
                            system.debug('## USA GeneratePInvoicingLine aParmInvoicingLine.Invoicing_Date_type__c: ' + aParmInvoicingLine.Invoicing_Date_type__c);

                            if  (aParmInvoicingLine.Invoicing_Date_type__c == 'Fixed Date') {
                                //aInvoicingLine.Invoicing_Predefined_Date__c = aParmInvoicingLine.Invoicing_Predefined_Date__r.Id;
                                aInvoicingLine.Inv_Predefined_Date__c = aParmInvoicingLine.Invoicing_Predefined_Date__r.Invoicing_Date__c;
                            }

                            if  (aParmInvoicingLine.Invoicing_Date_type__c == 'Start Date') {
                                //aInvoicingLine.Invoicing_Predefined_Date__c = GetInvoicingDateId(ctr.StartDate__c, InvDateList);
                                aInvoicingLine.Inv_Predefined_Date__c = GetInvoicingDateId(ctr.StartDate__c, InvDateList);
                            }

                            if  (aParmInvoicingLine.Invoicing_Date_type__c == 'End Date') { 
                                //aInvoicingLine.Invoicing_Predefined_Date__c = GetInvoicingDateId(ctr.EndDate__c, InvDateList); 
                                aInvoicingLine.Inv_Predefined_Date__c = GetInvoicingDateId(ctr.EndDate__c, InvDateList); 
                            }

                            if  (aParmInvoicingLine.Invoicing_Date_type__c == 'Percent') {
                                Integer ContractnumberDays                  = ctr.StartDate__c.daysBetween(ctr.EndDate__c);
                                Integer MilestonenumberDays                 = Integer.valueOf((ContractnumberDays * aParmInvoicingLine.Percent__c) / 100);
                                Date MilestonesCalc                         = ctr.StartDate__c.AddDays(MilestonenumberDays);
                                //aInvoicingLine.Invoicing_Predefined_Date__c = GetInvoicingDateId(MilestonesCalc, InvDateList);
                                aInvoicingLine.Inv_Predefined_Date__c = GetInvoicingDateId(MilestonesCalc, InvDateList);
                            }
                            CtrPInvoicingLineList.add(aInvoicingLine);
                        }
                    }
                }
                // Checks if no lines were created.
                system.debug('## USA dwnMonth CtrPInvoicingLineList size : ' + CtrPInvoicingLineList.size());
                if (CtrPInvoicingLineList.size() == 0 ) {
                    Msg = 'Invoicing Parameter Error, please contact your System Admin for Contract Id : ' + ctr.id;
                    return Msg;
                }
            }
            try {
                insert CtrPInvoicingLineList;
            }
            catch (DmlException Dmle ) {
                system.debug('## USA dDmle : ' + Dmle);
                Msg = SetDmlErrorMsg (Dmle);
            }
        }
        return Msg;
    }

    /*
    /-----------------------------------------------------------------------------------------
    /Returns the earliest Invoicing date parameter, equal or after aDate
    /-----------------------------------------------------------------------------------------
    */
    /*
    Public Static id GetInvoicingDateId(Date aDate, List <Invoicing_Parameter__c> InvDateList) {
        Id aInvoicingDate;
        // Looks for the  parameter date just following received date
        for (integer i = 0; i < InvDateList.size() ; i++) {
            //system.debug('##loop InvoicingDate: ' + i + ' ' + InvDateList[i].Id + ' '  + InvDateList[i].Invoicing_Date__c) ;
            if (aDate <= InvDateList[i].Invoicing_Date__c) {
                aInvoicingDate = InvDateList[i].Id;
                break;
            }
            aInvoicingDate = InvDateList[i].Id;
        }
        return aInvoicingDate;
    }
     */
    Public Static Date GetInvoicingDateId(Date aDate, List <Invoicing_Parameter__c> InvDateList) {
        Date aInvoicingDate;
        // Looks for the  parameter date just following received date
        for (integer i = 0; i < InvDateList.size() ; i++) {
            //system.debug('##loop InvoicingDate: ' + i + ' ' + InvDateList[i].Id + ' '  + InvDateList[i].Invoicing_Date__c) ;
            if (aDate <= InvDateList[i].Invoicing_Date__c) {
                aInvoicingDate = InvDateList[i].Invoicing_Date__c;
                break;
            }
            aInvoicingDate = InvDateList[i].Invoicing_Date__c;
        }
        return aInvoicingDate;
    }

    /*
    /-----------------------------------------------------------------------------------------
    /Validates required fields to generate the planned invoicing lines (Amount,End-date,Invoicing Condition)
    /-----------------------------------------------------------------------------------------
    */
    Public static string CheckContract(Contract__c ctr) {
        string Msg = '';
        String fields = '';
        // 13-JUL-2022   ARA    SP-01927
        if (ctr.StartDate__c == Null) {fields = 'Start Date';}
        if (ctr.EndDate__c == Null) {fields += fields == '' ? 'End Date' : ', End Date';}
        if (ctr.Invoicing_Condition__c == Null) {fields += fields == '' ? 'Invoicing Condition' : ', Invoicing Condition';}

        if(fields == ''){
            return '';
        }else if(fields.contains(',')){
            return 'The fields ' + fields + ' are mandatory to generate Invoicing lines.';
        }else{
            return 'The field ' + fields + ' is mandatory to generate Invoicing lines.';
        }
        return Msg;
    }

    /*
    /-----------------------------------------------------------------------------------------
    /Formats Dmlerror
    /-----------------------------------------------------------------------------------------
    */
    Public static string SetDmlErrorMsg (DmlException Dmle ) {
        Integer numErrors = (test.isRunningTest()? 5:Dmle.getNumDml());
        System.Debug('getNumDml=' + numErrors);
        String DmlErrorMsg;
        for (Integer i = 0; i < numErrors; i++) {
            DmlErrorMsg = test.isRunningTest() ? 'DmlError': DmlErrorMsg + 'getDmlFieldNames= ' + Dmle.getDmlFieldNames(i) + 'getDmlMessage= ' + Dmle.getDmlMessage(i);
        }
        return DmlErrorMsg;
    }

    Webservice static string attachContract(Id CtrId){
        return null;
    }

    /**
     * Method pushCreationToOpportunity :
     * to a contract send by the trigger.
     * @param contracts List<Contract__c> : contracts send by the trigger
     */
    /**
    * ----------------------------------------------------------------------------------------------
    * Method to update status on opportunity
    * ----------------------------------------------------------------------------------------------
    * @param    contracts List<Contract__c> : list of contracts from Trigger.new
    * ----------------------------------------------------------------------------------------------
    */
    public static void pushCreationToOpportunity(List<Id> lstOppId){
        // Variable declaration
        List<Opportunity> opptiesToBeUpdated = new List<Opportunity>();
        boolean toBeUpdated                  = false;
        // System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## AP10_ContractHandler pushCreationToOpportunity Start.');

        // Getting all the concern opportunity
        List<Opportunity> oppties = [SELECT Id, TECH_HaveContract__c, TECH_ContractStatus__c FROM Opportunity WHERE Id IN :lstOppId];

        for(Opportunity oppty : oppties){
            toBeUpdated = false;
            System.debug(LoggingLevel.DEBUG, '## AP10_ContractHandler TECH_HaveContract__c & TECH_ContractStatus__c ' + oppty.TECH_HaveContract__c + ' | ' + oppty.TECH_ContractStatus__c );
            if(!oppty.TECH_HaveContract__c){
                toBeUpdated = true;
                oppty.TECH_HaveContract__c = true;
            }
            if(oppty.TECH_ContractStatus__c == '' || oppty.TECH_ContractStatus__c == null){
                toBeUpdated = true;
                oppty.TECH_ContractStatus__c = 'Draft';
            }
            if(toBeUpdated){
                opptiesToBeUpdated.add(oppty);
            }
        }
        System.debug(LoggingLevel.INFO, '## AP10_ContractHandler Nb Opportunities to be updated : ' + opptiesToBeUpdated.size());
        update opptiesToBeUpdated;

        // System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## AP10_ContractHandler pushCreationToOpportunity End.');
    }

    /*Webservice static String sendCtrlightoPeopleSoft(id curCtr){
        String errorMsg = '';
        if (AP_Constant.hasRights(AP_Constant.strProfPMOADV)){
            List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id,Contract2__c,SAP_Synchronisation_Error__c,Connexion_Error__c,
                                                                 SAP_Account_Number__c,N_Purchase_Order__c,PurchaseOrder__r.PO_Client__c,Customer_contact__c,
                                                                 Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Service_Type__c,Customer_contact__r.Name,
                                                                 Contract_Start_Date__c,Contract_End_Date__c,Material_SAPEXP__c,Man_days__c,Activity_Type__c,
                                                                 Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,ADV_GoNoGo__c,
                                                                 Status__c,RecordTypeId,SO__c,ITEM__c,TECH_SynchroSAP__c,Header_Text__c,Header_Text_2_SAPEXP__c,
                                                                 Header_Text_3_SAPEXP__c,Header_Text_4_SAPEXP__c, Contract2__r.TECH_PS_SalesOrganization__c, AmountIL__c,
                                                                 Inv_Predefined_Date__c, Contract2__r.Peoplesoft_Sync__c,
                                                                 Contract2__r.name, Contract2__r.ContractNumber__c, Contract2__r.Tech_MSARef__c, Contract2__r.Status__c
                                                                 FROM Planned_Invoicing_Line__c 
                                                                 WHERE Contract2__c =: curCtr 
                                                                 AND Type__c = 'Invoicing Line'
                                                                 AND status__c=: AP_Constant.INVLINE_STATUS_DRAFT];
            //display error
            if(invoicingLineList.size() == 0){
                errorMsg='At least one Draft Invoicing Line is required to complete this action';
            }
            else if (invoicingLineList[0].Contract2__r.Peoplesoft_Sync__c){
                errorMsg='This contract has already been sent to PeopleSoft.';
            }
            // call peopleSoft to send Draft IL
            else{
                try{
                    map<id, list<Planned_Invoicing_Line__c>> mapInvoiceLineInfo=new map<id, list<Planned_Invoicing_Line__c>>();
                    list<Planned_Invoicing_Line__c> lstPILUpdate = new list<Planned_Invoicing_Line__c>();
                    for(Planned_Invoicing_Line__c inv_Line: invoicingLineList){
                       if(mapInvoiceLineInfo.containsKey(inv_Line.Contract2__c)){
                         mapInvoiceLineInfo.get(inv_Line.Contract2__c).add(inv_Line);   
                       }
                       else{
                         mapInvoiceLineInfo.put(inv_Line.Contract2__c,new list<Planned_Invoicing_Line__c>{inv_Line});
                       }
                    }
                    WS02_CallSAPWS callWS = new WS02_CallSAPWS(mapInvoiceLineInfo);
                }
                catch(exception e ){
                    errorMsg=e.getMessage();
                }
            }
        }
        else{
            errorMsg='You do not have sufficient rights to send ILs to PeopleSoft';
        }
        return errorMsg;
    }*/
}