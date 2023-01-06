public with sharing class LC03_GenerateInvoicingLines {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC03_GenerateInvoicingLines
    -- - Author        : Spoon Consulting 
    -- - Description   : LC03_GenerateInvoicingLines                                    
    --                                       
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 26-APR-2019  ZHE    1.0      Initial version
    -- 20-AVR-2020  USA    1.1      SP-00258
    -- 11-MAY-2020  USA    1.2      SP-00260
    -- 30-NOV-2020  ARA    1.3      SP-00992
    -- 14-DEC-2020  USA    1.4      SP-00294
    -- 09-MAR-2021  ARA    1.5      SP-01472
    -- 04-MAY-2021  ARA    1.6      SP-01408
    -- 25-MAR-2022  ARA    1.7      SP-03319
    -- 27-MAY-2022  ARA    1.8      SP-03382
    -- 18-JUL-2022  ARA    1.9      SP-01927 (Invoicing Lines - Review of the automation for creation of IL)
    ----------------------------------------------------------------------
    **********************************************************************
    */


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to get contract record and check data validity
    * ----------------------------------------------------------------------------------------------
    * @param    recordId                             [Type = Id] Id of the current contract
    * @return   Map<String, Object> returns a map of error/Contract
    * ----------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Map<String, Object> getAllData(Id recordId) {
        Map<String, Object> mapResult = new Map<String, Object>();
        String recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
        Contract__c contract = [
                SELECT Id, Status__c, Invoicing_condition__c, Customer_Operational_Contact__c, CustomerSignedBy__c, CustomerSignedBy2__c, AXA_GS_Signed_By__c, AXA_GO_Signed_By_2__c, 
                Account__c, Language__c, Global_Amount__c, Name, StartDate__c, EndDate__c, CurrencyIsoCode, Tech_countILsUpdatedByPS__c, Tech_isSendingToPS__c,
                Customer_Operational_Contact__r.RecordTypeId, Customer_Operational_Contact__r.Active__c, Customer_Operational_Contact__r.TECH_Name__c, 
                CustomerSignedBy__r.RecordTypeId, CustomerSignedBy__r.Active__c,AXA_GO_Legal_Entity__c,ServiceType__c,
                CustomerSignedBy2__r.RecordTypeId, CustomerSignedBy2__r.Active__c, Master_WBS_2__c,
                AXA_GO_Signed_By_2__r.RecordTypeId, AXA_GO_Signed_By_2__r.Active__c, AXA_GO_Signed_By_2__r.AXA_GO_Signatory__c,
                AXA_GS_Signed_By__r.RecordTypeId, AXA_GS_Signed_By__r.Active__c, AXA_GS_Signed_By__r.AXA_GO_Signatory__c,
                Account__r.Active__c, Signature_Type__c, Tech_countILsInvoiced__c
                FROM Contract__c
                WHERE Id = :recordId];

        if(contract.Tech_countILsInvoiced__c > 0){
            mapResult.put('error', System.Label.LC03_ExistingILsInvoiced);
        }else if(contract.Tech_countILsUpdatedByPS__c > 0 || contract.Tech_isSendingToPS__c){
            mapResult.put('error', System.Label.LC03_ContractAlreadySentToPS);
        }else if(contract.Invoicing_Condition__c == System.Label.InvoicingCondition_GETDQuarterlyBAUBegin) {
            mapResult.put('error', System.Label.LC03_GETDQuarterlyBAU);
        }else if (contract.Global_Amount__c == 0) {
            mapResult.put('error', System.Label.LC03_AmountZero);
        }else if (contract.Invoicing_Condition__c == System.Label.InvoicingCondition_PerDeliverable) {
            mapResult.put('error', System.Label.LC03_PerDeliverable);
        }else if(contract.Signature_Type__c == System.Label.Contract_Signature_Type_Specific){
            mapResult.put('error', System.Label.Error_Signature_Type_Specific);
        }else if(contract.Customer_Operational_Contact__c != null && (contract.Customer_Operational_Contact__r.RecordTypeId != recordTypeId || !contract.Customer_Operational_Contact__r.Active__c)){
            mapResult.put('error', System.Label.Contract_Operational_Contact);
        }else if(contract.CustomerSignedBy__c != null && (contract.CustomerSignedBy__r.RecordTypeId != recordTypeId || !contract.CustomerSignedBy__r.Active__c)){
            mapResult.put('error', System.Label.Customer_Signed_By_Error);
        }else if(contract.CustomerSignedBy2__c != null && (contract.CustomerSignedBy2__r.RecordTypeId != recordTypeId || !contract.CustomerSignedBy2__r.Active__c)){
            mapResult.put('error', System.Label.Customer_Signed_By_2_Error);
        }else if(contract.AXA_GS_Signed_By__c != null && (contract.AXA_GS_Signed_By__r.RecordTypeId != recordTypeId || !contract.AXA_GS_Signed_By__r.Active__c || !contract.AXA_GS_Signed_By__r.AXA_GO_Signatory__c)){
            mapResult.put('error', System.Label.Contract_AXA_Go_Signed_By_Error);
        }else if(contract.AXA_GO_Signed_By_2__c != null && (contract.AXA_GO_Signed_By_2__r.RecordTypeId != recordTypeId || !contract.AXA_GO_Signed_By_2__r.Active__c || !contract.AXA_GO_Signed_By_2__r.AXA_GO_Signatory__c)){
            mapResult.put('error', System.Label.Contract_AXA_Go_Signed_By_2_Error);
        }else if(contract.Account__c != null && !contract.Account__r.Active__c){
            mapResult.put('error', System.Label.Contract_Customer_Legal_Entity_Error);
        }else if(contract.Status__c == AP_Constant.CONTRACT_STATUS_CUSTOMER_VALIDATION){
            Integer countInvoicingIL = [SELECT count() FROM Planned_Invoicing_Line__c WHERE Contract2__c = :recordId AND Status__c = :AP_Constant.INVLINE_STATUS_INVOICING_VALIDATION];
            if(countInvoicingIL > 0){
                mapResult.put('error', System.Label.LC03_CustomerValidation);
            }
        }else{
            String strMsg = AP10_ContractHandler.CheckContract(contract);
            if (strMsg != '') {
                mapResult.put('error', strMsg);
            }
        }
        if(!mapResult.containsKey('error')){
            mapResult.put('contract', contract);
            if(contract.Master_WBS_2__c != null){
                mapResult.put('activityCode', [SELECT Id, Name, Activity_Level_2__c FROM Master_WBS_Structure__c WHERE Id = :contract.Master_WBS_2__c][0]);
            }
        }
        return mapResult;
    }

    @AuraEnabled
    public static Map<String, Object> generateInvoicingLines(String lines) {
        Map<String, Object> mapResult = new Map<String, Object>();
        Map<Id,Contract__c> mapCtr = new Map<Id,Contract__c>();
        List<WrapperLine> lstLines = new List<WrapperLine>();
        try{
            lstLines = parseJSONToTLinesObject(lines);
        }catch(Exception e){
            mapResult.put('error', 'Error during the process');
            System.debug('##Exception deserialization '+ e.getMessage());
        }
        Set<Id> setContractId = new Set<Id>();

        if(lstlines.size() > 0 && !mapResult.containsKey('error')){
            List<Planned_Invoicing_Line__c> lstILGenerated = new List<Planned_Invoicing_Line__c>();
            for(WrapperLine line: lstlines){
                if(line.ContractId != null){
                    setContractId.add(line.ContractId);
                }
            }
            if(setContractId.size() > 0){
                for(Contract__c ctr : [SELECT Id, Invoicing_condition__c, StartDate__c, EndDate__c, CurrencyIsoCode, Customer_Operational_Contact__c, Customer_Operational_Contact__r.TECH_Name__c, Tech_isSendingToPS__c, Tech_countILsInvoiced__c FROM Contract__c WHERE Id IN :setContractId]){
                    if(ctr.Tech_countILsInvoiced__c > 0){
                        mapResult.put('error', System.Label.LC03_ExistingILsInvoiced);
                        break;
                    }else if(ctr.Tech_isSendingToPS__c){
                        mapResult.put('error', System.Label.ErrorMessage_SentToPS);
                        break;
                    }
                    mapCtr.put(ctr.Id, ctr);
                }

                if(mapCtr.size() > 0 && !mapResult.containsKey('error')){
                    // create IL(s) for each line according to his activity code and contract data
                    for(WrapperLine line: lstlines){
                        if(mapCtr.containsKey(line.ContractId)){
                            line.Contract = mapCtr.get(line.ContractId);
                            lstILGenerated.addAll(generateForEachLine(line));
                        }
                    }

                    // Insert new Invoicing lines
                    if(lstILGenerated.size() > 0){
                        try {
                            // Not allow user to Send to PS during the process
                            for (Contract__c ctr : mapCtr.values()) {
                                ctr.Tech_isSendingToPS__c = true;
                            }
                            update mapCtr.values();
                            
                            // To update with [SP-00219] Retrieves and deletes old Invoicing lines no invoiced
                            List<Planned_Invoicing_Line__c> CtrPInvoicingLineListToDel = [SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c in:mapCtr.keySet() AND Type__c = 'Invoicing Line' AND Status__c != '03' AND Status__c != '04' AND isInPS__c = false];
                            if (CtrPInvoicingLineListToDel.size() > 0) {
                                delete CtrPInvoicingLineListToDel;
                            }

                            // Insert new ILs
                            try{
                                insert lstILGenerated;
                            }catch(Exception e){
                                if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                                    mapResult.put('error', e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ['));
                                }else{
                                    mapResult.put('error', 'An error occured during the process, please contact your Admin.');
                                }
                                for (Contract__c ctr : mapCtr.values()) {
                                    ctr.Tech_isSendingToPS__c = false;
                                }
                            }

                            // Allow user to Send to PS after ILs are generated
                            for (Contract__c ctr : mapCtr.values()) {
                                ctr.Tech_isSendingToPS__c = false;
                            }
                            update mapCtr.values();

                            if(!mapResult.containsKey('error')){
                                mapResult.put('success', lstILGenerated.size() + ' ' + System.Label.LC03_SuccessfulGeneration);
                            }
                        } catch (Exception e) {
                            mapResult.put('error', e.getMessage());
                        }
                    }else{
                        mapResult.put('error', System.Label.LC03_ContractDatesInvoicingCondition);
                    }
                }
            }
        }
        return mapResult;
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * Method to generate n ILs depending on Invoicing condition and invoicing dates
    * ----------------------------------------------------------------------------------------------
    * @param    line                             [Type = WrapperLine] line
    * @return   list<Planned_Invoicing_Line__c> returns list of ILs to create
    * ----------------------------------------------------------------------------------------------
    */
    public static list<Planned_Invoicing_Line__c> generateForEachLine(WrapperLine line) {
        Contract__c ctr = line.Contract;
        Decimal decKeptILAmount;
        Decimal countedFirstMonth;
        Decimal countedLastMonth;
        Decimal culmulatedAmount = 0;
        Decimal nbrTotalMonth = 0;
        Decimal nbrMonthLastQ = 0;
        List<Planned_Invoicing_Line__c> lstILsGenerated = new List<Planned_Invoicing_Line__c>();
        List<Integer> lstFirstMonthQuaterly = new List<Integer>{1, 4, 7, 10};
        List<Integer> lstMonth30Days = new List<Integer>{4, 6, 9, 11};
        List<Integer> lstMonth31Days = new List<Integer>{1, 3, 5, 7, 8, 10, 12};

        // get invoicing dates for each IL
        map<Integer, Date> mapInvDateOrder = getInvoicingDates(ctr);
        Integer countILs = mapInvDateOrder.size();

        if(countILs > 0){
            if(countILs == 1){
                nbrTotalMonth = mapInvDateOrder.get(countILs).monthsBetween(ctr.EndDate__c.addMonths(1));
            }else{
                Date firstInv = mapInvDateOrder.get(1);
                Date lastInv = mapInvDateOrder.get(mapInvDateOrder.size());
                if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
                    countedFirstMonth = (firstInv.Day() > 10) ? .5 : 1;
                    countedLastMonth = ((ctr.EndDate__c.Day() < 11) ? 0 : ((ctr.EndDate__c.Day() < 21) ? .5 : 1));
                    if(mapInvDateOrder.get(1).Day() > 20){
                        firstInv = date.newinstance(mapInvDateOrder.get(1).addMonths(1).Year(), mapInvDateOrder.get(1).addMonths(1).Month(), AP_Constant.INT_INVDATE);
                    }
                    nbrTotalMonth = (countedFirstMonth == 1 ? 0 : -.5) + firstInv.monthsBetween(ctr.EndDate__c) + countedLastMonth;
                }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning || ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){
                    nbrMonthLastQ = (mapInvDateOrder.get(countILs).monthsBetween(ctr.EndDate__c.Day() > 20 ? ctr.EndDate__c.addMonths(1) : ctr.EndDate__c)) 
                                + ((ctr.EndDate__c.Day() > 10 && ctr.EndDate__c.Day() <= 20) ? .5 : 0);
                    if(mapInvDateOrder.get(1).Day() > 20){
                        firstInv = date.newinstance(mapInvDateOrder.get(1).addMonths(1).Year(), mapInvDateOrder.get(1).addMonths(1).Month(), AP_Constant.INT_INVDATE);
                    }
                    nbrTotalMonth = firstInv.monthsBetween(mapInvDateOrder.get(countILs)) + nbrMonthLastQ;
                }
            }

            //System.debug('***nbrTotalMonth : '+nbrTotalMonth);
            for (Integer lineOrder : mapInvDateOrder.keySet()){
                Decimal invPercent;
                Planned_Invoicing_Line__c newIL    = new Planned_Invoicing_Line__c();
                newIL.RecordTypeId                 = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
                newIL.Type__c                      = 'Invoicing Line';
                newIL.Master_WBS_Structure__c      = line.ActivityCode.Id;
                newIL.Contract2__c                 = ctr.Id;
                newIL.Customer_contact_name__c     = ctr.Customer_Operational_Contact__c != null ? ctr.Customer_Operational_Contact__r.TECH_Name__c.replace('-',' ') : null;//27-MAY-2022 ARA SP-03382
                newIL.CurrencyIsoCode              = ctr.CurrencyIsoCode;

                //set newIL.Inv_Predefined_Date__c
                if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){
                    for (Integer i=1; i<4; i++){
                        Date invDate = mapInvDateOrder.get(lineOrder).addMonths(i);
                        if(lstFirstMonthQuaterly.contains(invDate.month())){
                            Integer invYear = mapInvDateOrder.get(lineOrder).Year();
                            // Predefined Date
                            if(invDate.Year() != invYear){
                                newIL.Inv_Predefined_Date__c = date.newinstance(invYear, 12, 31);
                            }else{
                                newIL.Inv_Predefined_Date__c = date.newinstance(invDate.Year(), invDate.Month(), AP_Constant.INT_INVDATE);
                            }
                            
                            //-- 04-MAY-2021  ARA    SP-01408 (Set start date and end date)
                            // Start date
                            if(lineOrder == 1){
                                newIL.StartDate__c = ctr.StartDate__c;
                            }else{
                                newIL.StartDate__c = date.newinstance(invYear, mapInvDateOrder.get(lineOrder).Month(), 01);
                            }
                            // End date
                            if(lineOrder == mapInvDateOrder.size()){
                                newIL.EndDate__c = ctr.EndDate__c;
                            }else{
                                Integer invMonth = newIL.Inv_Predefined_Date__c.Month();
                                if(newIL.Inv_Predefined_Date__c.Month() == 12){
                                    newIL.EndDate__c = date.newinstance(invYear, 12, 31);// 31 Dec
                                }else if(invMonth == 4){
                                    newIL.EndDate__c = date.newinstance(invYear, invMonth-1, 31);// 31 March
                                }else{
                                    newIL.EndDate__c = date.newinstance(invYear, invMonth-1, 30);// 30 june, 30 Sept
                                }
                            }
                            break;
                        }
                    }
                }else{
                    // Predefined Date
                    newIL.Inv_Predefined_Date__c = mapInvDateOrder.get(lineOrder);
                    //System.debug('***Inv_Predefined_Date__c : '+newIL.Inv_Predefined_Date__c);

                    //-- 04-MAY-2021  ARA    SP-01408 (Set start date and end date)
                    // Set Start date and End date
                    if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_100BeginningOfService){
                        newIL.StartDate__c = ctr.StartDate__c;
                        newIL.EndDate__c = ctr.EndDate__c;
                    }else{
                        Integer invMonth = newIL.Inv_Predefined_Date__c.Month();
                        Integer invYear = newIL.Inv_Predefined_Date__c.Year();
                        // Start date for each IL
                        if(lineOrder == 1){
                            if(ctr.StartDate__c < newIL.Inv_Predefined_Date__c){
                                newIL.StartDate__c = ctr.StartDate__c;
                            }else{
                                newIL.StartDate__c = newIL.Inv_Predefined_Date__c;
                            }
                        }else{
                            newIL.StartDate__c = date.newinstance(invYear, invMonth, 01);
                        }
                        // End date for each IL
                        if(lineOrder == mapInvDateOrder.size()){
                            newIL.EndDate__c = ctr.EndDate__c;
                        }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
                            Date invDate = mapInvDateOrder.get(lineOrder).addMonths(1);
                            invMonth = (invDate.month() - 1 == 0) ? 12 : invDate.month() - 1;
                            invYear = mapInvDateOrder.get(lineOrder).Year();
                            if(invMonth == 2){
                                if(Date.isLeapYear(invYear)){
                                    newIL.EndDate__c = date.newinstance(invYear, invMonth, 29);
                                }else{
                                    newIL.EndDate__c = date.newinstance(invYear, invMonth, 28);
                                }
                            }else if(lstMonth30Days.contains(invMonth)){
                                newIL.EndDate__c = date.newinstance(invYear, invMonth, 30);
                            }else if(lstMonth31Days.contains(invMonth)){
                                newIL.EndDate__c = date.newinstance(invYear, invMonth, 31);
                            }
                        }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning){
                            for (Integer i=1; i<4; i++){
                                Date invDate = mapInvDateOrder.get(lineOrder).addMonths(i);
                                if(lstFirstMonthQuaterly.contains(invDate.month())){
                                    invMonth = (invDate.month() - 1 == 0) ? 12 : invDate.month() - 1;
                                    invYear = invDate.Year();
                                    if(invMonth == 6 || invMonth == 9){
                                        newIL.EndDate__c = date.newinstance(invYear, invMonth, 30);// 30 june, 30 Sept
                                    }else{
                                        newIL.EndDate__c = date.newinstance(invYear, invMonth, 31);// 31 March, 31 Dec
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }

                //System.debug('***StartDate__c : '+newIL.StartDate__c);
                //System.debug('***EndDate__c : '+newIL.EndDate__c);
                //set newIL.Percent__c & newIL.AmountIL__c
                if(lineOrder < mapInvDateOrder.size()){
                    if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
                        invPercent = (lineOrder == 1) ? (100 * (countedFirstMonth == .5 ? .5 : 1)).divide(nbrTotalMonth, 2).setScale(2, RoundingMode.HALF_DOWN) : ((Decimal)100).divide(nbrTotalMonth, 2).setScale(2, RoundingMode.HALF_DOWN);
                    }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning || ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){
                        if(mapInvDateOrder.get(lineOrder).Day() > 20){
                            Date firstInv = mapInvDateOrder.get(lineOrder).addMonths(1);
                            invPercent = Decimal.valueOf(100 * date.newinstance(firstInv.Year(), firstInv.Month(), 05).monthsBetween(mapInvDateOrder.get(lineOrder+1))).divide(nbrTotalMonth, 2);
                        }else{
                            invPercent = Decimal.valueOf(100 * mapInvDateOrder.get(lineOrder).monthsBetween(mapInvDateOrder.get(lineOrder+1))).divide(nbrTotalMonth, 2);
                        }
                    }
                }else{
                    if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_100BeginningOfService){
                        invPercent = 100;
                    }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
                        invPercent = (100 * (countedLastMonth == .5 ? .5 : 1)).divide(nbrTotalMonth, 2).setScale(2, RoundingMode.HALF_DOWN);
                    }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning || ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){
                        invPercent = (100 * nbrMonthLastQ).divide(nbrTotalMonth, 2).setScale(2, RoundingMode.HALF_DOWN);
                    }
                }
                newIL.Percent__c = invPercent;
                newIL.AmountIL__c = (line.Amount * newIL.Percent__c/100).setScale(2, RoundingMode.HALF_UP);

                culmulatedAmount = culmulatedAmount + newIL.AmountIL__c;
                lstILsGenerated.add(newIL);
            }
            // handle rounding issues of decimal numbers
            if ((line.Amount - culmulatedAmount) != 0.00){
                lstILsGenerated[lstILsGenerated.size()-1].AmountIL__c = lstILsGenerated[lstILsGenerated.size()-1].AmountIL__c + (line.Amount - culmulatedAmount);
            }
        }
        return lstILsGenerated;
    }

    /**
    * ----------------------------------------------------------------------------------------------
    * Method to generate invoicing date based on contract start date and end date
    * ----------------------------------------------------------------------------------------------
    * @param    ctr                           [Type = Contract__c] contract
    * @return   map<Integer,Date> returns map of invoicing parameter dates in order
    * ----------------------------------------------------------------------------------------------
    */
    Public Static  map<Integer,Date> getInvoicingDates(Contract__c ctr) {
        map<Integer,Date> mapInvDates = new map<Integer,Date>();
        Integer countILs = 0;
        Date dateStart = ctr.StartDate__c;
        Date dateEnd = ctr.EndDate__c;
        Date nextInvDate;
        Date firstMonth;
        Date firstQuarter;
        List<Integer> lstFirstMonthQuaterly = new List<Integer>{1, 4, 7, 10};

        if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_100BeginningOfService){
            // Condition details : only one invoicing line should be generated from contract start date
            countILs = 1;
            for(Integer i=0; i<4; i++){
                nextInvDate = dateStart.addMonths(i);
                if(lstFirstMonthQuaterly.contains(nextInvDate.Month())){
                    if(nextInvDate.Day() <= 5){
                        nextInvDate = date.newinstance(nextInvDate.Year(), nextInvDate.Month(), AP_Constant.INT_INVDATE); 
                    }else if(nextInvDate.Month() == 10){
                        nextInvDate = date.newinstance(nextInvDate.Year(), 12, 31);
                    }else{
                        nextInvDate = date.newinstance(nextInvDate.Year(), nextInvDate.Month(), AP_Constant.INT_INVDATE); 
                    }
                    break;
                }else if(nextInvDate.Month() > 10 && nextInvDate < date.newinstance(nextInvDate.Year(), 12, 20)){
                    nextInvDate = date.newinstance(nextInvDate.Year(), 12, 31);
                    break;
                }
            }
        }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
            // Condition details : 1st invoicing date = 05/01/Contract start date year
            // next IL line(s) : +1 month until contract end date
            boolean isMonth = false;
            Date lastMonth;
            if(dateStart.Day() <= 5){
                nextInvDate = date.newinstance(dateStart.Year(), dateStart.Month(), AP_Constant.INT_INVDATE);
            }else{
                nextInvDate = dateStart;
            }

            // get first month
            firstMonth = (nextInvDate.Day() <= 20) ? nextInvDate : date.newinstance(nextInvDate.addMonths(1).Year(), nextInvDate.addMonths(1).Month(), AP_Constant.INT_INVDATE);
            //System.debug('***firstMonth : '+firstMonth);

            //check if adding endDate in new month
            lastMonth = (dateEnd.Day() > 10) ? date.newinstance(dateEnd.Year(), dateEnd.Month(), AP_Constant.INT_INVDATE) : date.newinstance(dateEnd.addMonths(-1).Year(), dateEnd.addMonths(-1).Month(), AP_Constant.INT_INVDATE);

            //System.debug('***lastMonth : '+lastMonth);
            countILs = firstMonth.monthsBetween(lastMonth) + 1;
        }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning || ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){ //Quarterly (Begin) or Quarterly (End)
            // Condition details : 1st invoicing date = 05/01/Contract start date year
            // next IL line(s) : +3 months until contract end date
            boolean isQuarter = false;
            Date lastQuarter;
            if(dateStart.Day() <= 5){
                nextInvDate = date.newinstance(dateStart.Year(), dateStart.Month(), AP_Constant.INT_INVDATE);
            }else{
                nextInvDate = dateStart;
            }

            // get first quarter
            if(lstFirstMonthQuaterly.contains(nextInvDate.Month())){
                firstQuarter = nextInvDate;
            }else if(lstFirstMonthQuaterly.contains(nextInvDate.addMonths(1).Month())){
                countILs ++;
                firstQuarter = nextInvDate.addMonths(1);
            }else if(lstFirstMonthQuaterly.contains(nextInvDate.addMonths(2).Month())){
                countILs ++;
                firstQuarter = nextInvDate.addMonths(2);
            }

            //check if adding endDate in new quarter
            if(lstFirstMonthQuaterly.contains(dateEnd.Month())){
                if(dateEnd.Day() >= 10){
                    isQuarter = true;
                }
                lastQuarter = date.newinstance(dateEnd.Year(), dateEnd.Month(), AP_Constant.INT_INVDATE);
            }else if(lstFirstMonthQuaterly.contains(dateEnd.addMonths(-1).Month())){
                isQuarter = true;
                lastQuarter = date.newinstance(dateEnd.addMonths(-1).Year(), dateEnd.addMonths(-1).Month(), AP_Constant.INT_INVDATE);
            }else if(lstFirstMonthQuaterly.contains(dateEnd.addMonths(-2).Month())){
                isQuarter = true;
                lastQuarter = date.newinstance(dateEnd.addMonths(-2).Year(), dateEnd.addMonths(-2).Month(), AP_Constant.INT_INVDATE);
            }
            if(dateEnd.Day() > 10 && dateEnd.Day() <= 20){
                isQuarter = true;
            }

            countILs += (firstQuarter.monthsBetween(lastQuarter)/3) + (isQuarter ? 1: 0);
        }

        //System.debug('***countILs : '+countILs);
        if (countILs > 0){
            Date invDate;
            for(Integer i=1; i<=countILs; i++){
                if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_100BeginningOfService){
                    mapInvDates.put(i, nextInvDate);
                }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_Monthly){
                    invDate = firstMonth;
                    mapInvDates.put(i, date.newinstance(invDate.Year(), invDate.Month(), (invDate.Day() <= 5) ? AP_Constant.INT_INVDATE : invDate.Day()));
                    firstMonth = date.newinstance(invDate.Year(),invDate.Month(),AP_Constant.INT_INVDATE).addMonths(1);
                }else if(ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyBeginning || ctr.Invoicing_Condition__c == System.Label.InvoicingCondition_QuarterlyEnd){
                    if(i == 1){
                        mapInvDates.put(1, nextInvDate);
                    }else{
                        if(firstQuarter == nextInvDate){
                            invDate = nextInvDate.addMonths(3);
                        }else{
                            invDate = firstQuarter;
                        }
                        mapInvDates.put(i, date.newinstance(invDate.Year(), invDate.Month(), AP_Constant.INT_INVDATE));
                        firstQuarter = invDate.addMonths(3);
                    }
                }
            }
        }
        return mapInvDates;
    }

    public static List<WrapperLine> parseJSONToTLinesObject(String json){
        List<WrapperLine> lstLines = new List<WrapperLine>();
        try{
            lstLines = (List<WrapperLine>) System.JSON.deserialize(json, List<WrapperLine>.class);
        }catch(Exception e){
            return null;
        }
        return lstLines;
    }
    
    public class WrapperLine {
        public Id ContractId;
        public Integer Index;
        public Contract__c Contract;
        public Decimal Amount;
        public Master_WBS_Structure__c ActivityCode;
    }
}