/**
 * Classe VFC14_POS : Contrôleur pour les pages visualforces qui suivent :
 *      - VFP14_POS
 *      - VFP14_POSXls
 *      - VFP16_POSPDF
 */
public without sharing class VFC14_POS {
    //Variables utilisés dans le cas d'un test unitaire
    @testVisible
    private Map<String, String> posStatusColor { get; set; }
    @testVisible
    private Map<String, String> posStatusFontColor { get; set; }

    // legend
    public Map<String, POSCell> allEROStatus { get; set; }

    // Entities to display
    public List<Account> entities { get; set; }

    // Offers
    //public List<Offer__c> offers { get; set; }
    // Entities rolled out values
    public Map<String, POSCell> eROvalues  { get; set; }

    //Config
    public POSConfiguration posConfig { get; set; }
    public Integer nbColumns { get; set; }

        public String pdfPageFormat {get; set; }

    //Constructors for the VFC14_POS
    public VFC14_POS() {

        retrieveConfig();
        initData();
    }

    public void retrieveConfig() {
        System.debug(LoggingLevel.DEBUG, '## VFC14_POS.retrieveConfig() has been called');
        if (ApexPages.currentPage().getParameters().get('pConfig') != null) {
            posConfig = (POSConfiguration) JSON.deserialize(ApexPages.currentPage().getParameters().get('pConfig'), POSConfiguration.class);
        }

    }


    // Quartiles to display
    //public Map<Id, QuartileInfo> quartileWrap { get; set; }

    /*public class QuartileInfo {
        public String quartileName { get; set; }
        public Integer quartileSize { get; set; }
    }

    // Master Entities to display
    public Map<Id, MEInfo> mEWrap { get; set; }

    public class MEInfo {
        public String mEName { get; set; }
        public Integer mESize { get; set; }
    }*/

    public PageReference reload() {


        System.debug('########################## posConfig.isBuildingBlockDisplayed : ' + posConfig.isBuildingBlockDisplayed);
        loadEntitiesAndOffers();

        return null;
    }

    public void initData() {
        if (posConfig == null) {
           setPOSStatusInCMD(true);
        } else {
           setPOSStatusInCMD(false);
        }

        loadEntitiesAndOffers();
        nbColumns = entities.size();
        if((nbColumns > 15) && (nbColumns <= 30)){
            posConfig.setPdfColumnsSideReduction('50');
        }
        else if(nbColumns > 30){
            posConfig.setPdfColumnsSideReduction('25');
        }
    }

    /*
    * Load entities and offers
    */
    public void loadEntitiesAndOffers() {
        //entities = [SELECT Id, Name, ParentId, Parent.Name, POS_Flag__c  FROM Account WHERE Show_In_POS__c = true ORDER BY Parent.Name];
        //20170601 : Update query to order by Index
        entities = [SELECT Id, Name, ParentId, Parent.Name, POS_Flag__c  FROM Account WHERE Show_In_POS__c = true AND index__c != null ORDER BY index__c];
        //offers = [SELECT Id, Name, Domain__r.Business_area__r.Name, Domain__r.Business_area__r.POS_Index__c, Building_Block__c, Offer_Purpose__c FROM Offer__c WHERE Show_In_Pos__c = true AND Domain__r.Business_area__r.POS_Index__c != null ORDER BY Domain__r.Business_area__r.POS_Index__c, Name];

        // Set quartiles information
        setQuartilesInfo();

        // Set master entities information
        setMasterEntitiesInfo();

        // In case a config object is defined, construct the list of status to retrieve
        Set<String> vAllowedStatus = new Set<String>();
        if (posConfig != null && posConfig.statusList != null) {
            for (EROStatusConfig vEROStatusConfig : posConfig.statusList) {
                if (vEROStatusConfig.mustBeDisplayed) {
                    vAllowedStatus.add(vEROStatusConfig.name);
                }
            }
        }

        // Get back link between entity and offers
        List<ProductEntityLink__c> vEROList = [SELECT ID, Is_Partial__c, Entity__c, Offer_txt__c, POS_Status__c, First_Release_Date__c FROM ProductEntityLink__c WHERE POS_Status__c IN :vAllowedStatus];
        Map<String, POSCell> vEROValuesTemp = new Map<String, POSCell>();

        for (ProductEntityLink__c vERO : vEROList) {

            /*POSCell vCurrentEroPOCO = getEROPOCOFromStatusName(vERO.POS_Status__c);

            // managing Partial
            if (vEROValuesTemp.containsKey(vERO.Entity__c + '_' +  vERO.Offer_txt__c)) {
                POSCell vEroPOCOTmp = vEROValuesTemp.get(vERO.Entity__c + '_' +  vERO.Offer_txt__c);

                if (vEroPOCOTmp.order > vCurrentEroPOCO.order) {
                    // existing is stronger
                    vEroPOCOTmp.isPartial = vEroPOCOTmp.isPartial;
                } else if (vEroPOCOTmp.order == vCurrentEroPOCO.order) {
                    if (vEroPOCOTmp.posFirstReleaseDate != null && vERO.First_Release_Date__c != null) {
                        vEroPOCOTmp.posFirstReleaseDate = (vEroPOCOTmp.posFirstReleaseDate > vERO.First_Release_Date__c) ? vERO.First_Release_Date__c: vEroPOCOTmp.posFirstReleaseDate;
                        vEroPOCOTmp.isPartial = (vEroPOCOTmp.posFirstReleaseDate > vERO.First_Release_Date__c) ? vEroPOCOTmp.isPartial: vERO.Is_Partial__c;
                    }
                } else {
                    vEroPOCOTmp.isPartial = vERO.Is_Partial__c;
                    vEroPOCOTmp.posFirstReleaseDate = vERO.First_Release_Date__c;
                    vEroPOCOTmp.order = vCurrentEroPOCO.order;

                    vEroPOCOTmp.posStatusColor = posStatusColor.containsKey(vERO.POS_Status__c) ? posStatusColor.get(vERO.POS_Status__c) : '';
                    vEroPOCOTmp.posStatusFontColor = posStatusFontColor.containsKey(vERO.POS_Status__c) ? posStatusFontColor.get(vERO.POS_Status__c) : '';

                }
            } else {
                POSCell vPOSCell = new POSCell(vERO.POS_Status__c,
                    posStatusColor.containsKey(vERO.POS_Status__c) ? posStatusColor.get(vERO.POS_Status__c) : '',
                    posStatusFontColor.containsKey(vERO.POS_Status__c) ? posStatusFontColor.get(vERO.POS_Status__c) : '',
                    vERO.First_Release_Date__c,
                    vCurrentEroPOCO.order,
                    vERO.Is_Partial__c
                    );


                vEROValuesTemp.put(vERO.Entity__c + '_' +  vERO.Offer_txt__c, vPOSCell);
            }*/
        }

        // Now fill in the values indexed in the map by id account_id offer
        eROvalues = new Map<String, POSCell>();
        String opptyPosColor = allEROStatus.get('Opportunity').posStatusColor;
        for (Account vAccount : entities) {
            /*for (Offer__c vOffer : offers) {
                if (vEROValuesTemp.containsKey(vAccount.Id + '_' + vOffer.Id)) {
                    eROvalues.put(vAccount.Id + '_' + vOffer.Id, vEROValuesTemp.get(vAccount.Id + '_' + vOffer.Id));
                } else {
                    // No mapping (no ERO) => must be considered as Opportunity ERO

                    POSCell vPOSCell = new POSCell('', 'white', '');
                    eROvalues.put(vAccount.Id + '_' + vOffer.Id, vPOSCell);
                }
            }*/
        }
    }

    /*
    * set quartile info on first offer of each quartile
    */
    public void setQuartilesInfo() {
        System.debug('##############################        setQuartilesInfo ');
        /*if (offers == null || offers.size() == 0) {
            System.debug('##############################offers.size null ');
            return;
        }
        // Create quartiles size map (in order to be able to manage quartile rowspan)
        Map<String, Integer> vQuartilesSize = new Map<String, Integer>();
        String vPreviousQuartile = offers[0].Domain__r.Business_area__r.Name;
        Integer vQuartileSizeIndex = 0;
        /*for (Offer__c vOffer : offers) {
            String vCurrentQuartile = vOffer.Domain__r.Business_area__r.Name;
            if (vCurrentQuartile != vPreviousQuartile) {
                vQuartilesSize.put(vPreviousQuartile, vQuartileSizeIndex);
                vQuartileSizeIndex = 1;
                vPreviousQuartile = vCurrentQuartile;
            } else {
                vQuartileSizeIndex++;
            }
        }
        vQuartilesSize.put(vPreviousQuartile, vQuartileSizeIndex);
        // Full map with empty values
        quartileWrap = new Map<Id, QuartileInfo>();
        //System.debug('##############################        offers: ' + offers);
        for (Offer__c vOffer : offers) {
            quartileWrap.Put(vOffer.Id, new QuartileInfo());
        }
        System.debug('##############################        quartileWrap : ' + quartileWrap);*/
        // Fill in quartile info on each first offer of each quartile
        Integer vIndex = 0;
        /*for (Integer vSize : vQuartilesSize.values()) {
            QuartileInfo vQuartileInfo = new QuartileInfo();
            vQuartileInfo.quartileSize = vSize;
            vQuartileInfo.quartileName = offers[vIndex].Domain__r.Business_area__r.Name;
            quartileWrap.Put(offers[vIndex].Id, vQuartileInfo);
            System.debug('##############################        vQuartileInfo: ' + vQuartileInfo);
            vIndex += vSize;
        }*/
        System.debug('##############################        setQuartilesInfo END');
    }

    /*
    * set master entities info on first entity of each master entity
    */
    public void setMasterEntitiesInfo() {
        if (entities == null || entities.size() == 0) {
            return;
        }
        // Create ME size map (in order to be able to manage ME rowspan)
        /*Map<String, Integer> vMasterEntitiesSize = new Map<String, Integer>();
        String vPreviousME = '';
        if(entities[0].ParentId != null)
            vPreviousME = entities[0].Parent.Name;
        Integer vMESizeIndex = 0;
        for (Account vEntity : entities) {
            String vCurrentME = '';
            if(vEntity.ParentId != null)
                vCurrentME = vEntity.Parent.Name;
            if (vCurrentME != vPreviousME) {
                vMasterEntitiesSize.put(vPreviousME, vMESizeIndex);
                vMESizeIndex = 1;
                vPreviousME = vCurrentME;
            } else {
                vMESizeIndex++;
            }
        }
        vMasterEntitiesSize.put(vPreviousME, vMESizeIndex);
        // Full map with empty values
        mEWrap = new Map<Id, MEInfo>();
        for (Account vAccount : entities) {
            mEWrap.Put(vAccount.Id, new MEInfo());
        }
        // Fill in Master entity info on each first account of this me
        Integer vIndex = 0;
        for (Integer vSize : vMasterEntitiesSize.values()) {
            MEInfo vMEInfo = new MEInfo();
            vMEInfo.mESize = vSize;
            if(entities[vIndex].ParentId != null)
                vMEInfo.mEName = entities[vIndex].Parent.Name;
            else vMEInfo.mEName = '';
            mEWrap.Put(entities[vIndex].Id, vMEInfo);
            vIndex += vSize;
        }*/
    }


    /*
    * Set POS status from custom metadata
    */
    public void setPOSStatusInCMD(Boolean pReloadConfig) {
        posStatusColor = new Map<String, String>();
        posStatusFontColor = new Map<String, String>();
        allEROStatus = new Map<String, POSCell>();
        if (pReloadConfig) {
            posConfig = new POSConfiguration();
        }

        List<POS__mdt> vPOSMdtList = [SELECT Id, MasterLabel, DeveloperName, POS_Color__c, POS_Font_Color__c, Label_Partial__c, Order__c FROM POS__mdt];
        for (POS__mdt vPOSMdt : vPOSMdtList) {
            posStatusColor.put(vPOSMdt.MasterLabel, vPOSMdt.POS_Color__c);
            posStatusFontColor.put(vPOSMdt.MasterLabel, vPOSMdt.POS_Font_Color__c);

            POSCell vPOSCell = new POSCell(vPOSMdt.MasterLabel, vPOSMdt.POS_Color__c,
                                            vPOSMdt.POS_Font_Color__c, Integer.valueOf(vPOSMdt.Order__c));

            allEROStatus.put(vPOSMdt.DeveloperName, vPOSCell);

            // Config init
            if (pReloadConfig) {
                EROStatusConfig vEROStatusConfig = new EROStatusConfig();
                vEROStatusConfig.name = vPOSMdt.MasterLabel;
                vEROStatusConfig.mustBeDisplayed= true;
                posConfig.statusList.add(vEROStatusConfig);
            }
        }

    }

    /*public POSCell getEROPOCOFromStatusName(String pStatus) {
        for (POSCell vEroPoco : allEROStatus.values()) {
            if (vEroPoco.posStatus == pStatus) {
                return vEroPoco;
            }
        }
        return null;
    }*/

    public String getConfigJSON() {
        return JSON.serialize(posConfig);
    }



    /**
     * <b>Method getPdfPageFormat </b>: give the page format for pdf
     * @return String : page format
     */
    /*public String getPdfPageFormatM(){
        System.debug(LoggingLevel.DEBUG, '## VFC14_POS.getPdfPageFormatM() has been called');
        //if (ApexPages.currentPage().getParameters().get('pConfig') != null) {
            posConfig = (POSConfiguration) JSON.deserialize(ApexPages.currentPage().getParameters().get('pConfig'), POSConfiguration.class);
        //}
        return posConfig.pdfPageFormat + ' ' + posConfig.pdfPageDirection;
    }*/

    /**
     * <b> Method getColumnsSize </b>: give the size of the columns
     * @return String : columns size
     */
    /*public String getColumnsSize(){
        System.debug(LoggingLevel.DEBUG, '## VFC14_POS.getColumnsSize() has been called');
        posConfig.applyColumnSizeReduction();
        return posConfig.pdfColumnsSize + 'px';
    }*/

    /**
     * <b>method getSelectedSizeReduction </b>: give the ordinal of the selected size reduction
     * @return String : ordinal of the column size reduction.
     */
    public String getSelectedSizeReduction(){
        return posConfig.pdfColumnsSizeReduction + '';
    }

    /**
     * <b>method setPdfFormat </b>: set the format of the PDF
     * @param pdfFormat (String) :
     */
    /*public void setPdfFormat(){
        String pdfFormat = ApexPages.CurrentPage().getParameters().get('pdfFormat');
        System.debug(LoggingLevel.DEBUG, '## VFC14_POS pdfFormat = ' + pdfFormat);
        posConfig.setPdfPageFormat(this.pdfPageFormat);
    }*/

    /**
     * <b>Method exportXLS </b>: return an xls of the current POS
     * @return (PageReference) : a page which will generate the XLS
     */
    /*public PageReference exportXLS(){
        PageReference excelPage = new PageReference('/apex/VFP14_POSXls?pConfig=' + JSON.serialize(posConfig));
        excelPage.setRedirect(true);
        return excelPage;
    }*/

    /**
     * <b>Method exportPDF </b>: return a pdf of the current POS
     * @return (PageReference) : a page which will generate the PDF
     */
    /*public PageReference exportPDF(){
        PageReference pdfPage = new PageReference('/apex/VFP16_POSPDF?pConfig=' + JSON.serialize(posConfig));
        pdfPage.setRedirect(true);
        return pdfPage;
    }*/
}