/**
 * <b>Class POSConfiguraiton</b>: a class to store the configuration of the POS
 * @author Eric Wartelle
 * @version 1.1 - Change the type of the properties to String
 *			1.0 - Initial
 */
public with sharing class POSConfiguration {
	//Attributs of the class POSConfiguration
	/**
	 * <b>statusList </b>: a list of EROStatusConfig object that will store the status for each EROs
	 */
	public List<EROStatusConfig> statusList { get; set; }

	/**
	 * <b>isBuildingBlockDisplayed </b>: a flag to know if we need to display the building block
	 */
    public Boolean isBuildingBlockDisplayed { get; set; }

    /**
     * <b>isOfferPurposeDisplayed </b>: a flag to know if we need to display the building block
     */
    public Boolean isOfferPurposeDisplayed { get; set; }

    /**
     * <b>pdfPageFormat </b>: store the expected page format for the PDF we want to generate
     */
    public String pdfPageFormat { get; set; }

    /**
     * <b>pdfPageDirection </b>: store the expected page direction for the PDF we want to generate
     */
    public String pdfPageDirection { get; set; }

    /**
     * <b>pdfColumnsSize </b>: store the size of the current columns
     */
    public Integer pdfColumnsSize { get; set; }

    /**
     * <b>isYearDisplayed </b>: a flag to know if you displayed the year in the POS
     */
    public Boolean isYearDisplayed { get; set; }

    /**
     * <b>pdfColumnsSizeReduction </b>: store the reduction applied to the standard columns size
     */
    public String pdfColumnsSizeReduction { get; set; }


	//Constructors for the class POSConfiguration 
	/**
	 * <b>Constructor with four arguments</b>
	 * @param statusList (List<EROStatusConfig>) : list of EROs status configuration
	 * @param isBuildingBlockDisplayed (Boolean) : flag for the displaying of building blocks
	 * @param isOfferPurposeDisplayed (Boolean) : flag for the displaying of the offer purpose
	 * @param pdfPageFormat (String) : the expected format for the PDF
	 * @param pdfPageDirection (String) : the expected direciton for the PDF
	 * @param pdfColumnsSize (Integer) : the size of the pdf columns
	 * @param pdfColumnsSizeReduction (String) : the reduction of the pdf columns
	 * @param isYearDisplayed (Boolean) : flag for the displaying of the year in a POS Cell
	 */
	public POSConfiguration(List<EROStatusConfig> statusList, Boolean isBuildingBlockDisplayed,
		Boolean isOfferPurposeDisplayed, String pdfPageFormat, String pdfPageDirection,
		Integer pdfColumnsSize, String pdfColumnsSizeReduction, Boolean isYearDisplayed) {
		this.statusList = (statusList == null) ? new List<EROStatusConfig>() : statusList;
		this.isBuildingBlockDisplayed = isBuildingBlockDisplayed;
		this.isOfferPurposeDisplayed = isOfferPurposeDisplayed;		
		this.pdfPageFormat = pdfPageFormat;
		this.pdfPageDirection = pdfPageDirection;
		this.pdfColumnsSize = pdfColumnsSize;
		this.pdfColumnsSizeReduction = pdfColumnsSizeReduction;
		this.isYearDisplayed = isYearDisplayed;
	}

	/**
	 * <b>Constructor with no argument</b>
	 */
	public POSConfiguration(){
		this(new List<EROStatusConfig>(), false, false, 'A4', 'portrait', 83, 
			'100', true);
	}

	//Methods for the class POSConfiguration
	/**
	 * <b>Method setPdfPageFormat </b>: set the page format for the PDF
	 * @param pdfPageFormat String : a string that will contains the page format
	 */
	public String setPdfPageFormat(String pdfPageFormat){
		// System.debug call for debug log purpose
		System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfPageFormat - Start');

		// Testing the argument pdfPageFormat and setting the attribut pdfPageFormat
		System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageFormat - pdfPageFormat : ' + pdfPageFormat);
		if(pdfPageFormat.startsWith('A4')){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageFormat - Selected A4');
			return this.pdfPageFormat = 'A4';
		}
		else if(pdfPageFormat.startsWith('A5')){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageFormat - Selected A5');
			return this.pdfPageFormat = 'A5';
		}
		else if(pdfPageFormat.startsWith('A3')){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageFormat - Selected A3');
			return this.pdfPageFormat = 'A3';
		}

		// System.debug call for debug log purpose
		System.debug(LoggingLevel.ERROR, '## POSConfiguration.setPdfPageFormat - No valid page format detected - A4 selected by default');
		System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfPageFormat - End');
		return this.pdfPageFormat = 'A4';
	}

	/**
	 * <b>Methode setPdfPageDirection </>b: set the page direction for the PDF
	 * @param pdfPageDirection String : a string that will contains the page direction
	 */
	public String setPdfPageDirection(String pdfPageDirection){
		// System.debug call for debug log purpose
		System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfPageDirection - Start');

		// Testing the argument pdfPageDirection and setting the attribut pdfPageDirection
		System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageDirection - pdfPageDirection : ' + pdfPageDirection);
		if(pdfPageDirection == 'portrait'){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageDirection - Selected portrait');
			return this.pdfPageDirection = 'portrait';
		}
		else if(pdfPageDirection == 'landscape'){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfPageDirection - Selected landscape');
			return this.pdfPageDirection = 'landscape';
		}

		// System.debug call for debug log purpose
		System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfPageDirection - End');
		System.debug(LoggingLevel.ERROR, '## POSConfiguration.setPdfPageDirection - No valid page direction detected - portrait selected by default');
		return this.pdfPageDirection = 'portrait';
	}

	/**
	 * <b>Method setPdfColumnsSideReduction </b>: set the reduction of the pdf columns
	 * @param pdfColumnsSizeReduction (String) : Reduction of the columns Size
	 * @return ColumnsSizeReduction : the reduction
	 */
    public String setPdfColumnsSideReduction(String pdfColumnsSizeReduction){
    	// System.debug call for debug log purpose
    	System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfColumnsSideReduction - Start');

    	// Testing the argument pdfColumnsSizeReduction and setting the attribut pdfColumnsSizeReduction
    	System.debug(LoggingLevel.DEBUG, '## POSConfiguration.setPdfColumnsSideReduction - pdfColumnsSizeReduction : ' + pdfColumnsSizeReduction);
    	if(pdfColumnsSizeReduction == '100'){
    		System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 100%');
    		return this.pdfColumnsSizeReduction = '100';
    	}
    	else if(pdfColumnsSizeReduction == '75'){
    		System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 75%');
    		return this.pdfColumnsSizeReduction = '75';
    	}
    	else if(pdfColumnsSizeReduction == '50'){
    		System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 50%');
    		return this.pdfColumnsSizeReduction = '50';
    	}
		else if(pdfColumnsSizeReduction == '25'){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 25%');
			return this.pdfColumnsSizeReduction = '25';
		}
		else if(pdfColumnsSizeReduction == '10'){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 10%');
			return this.pdfColumnsSizeReduction = '10';
		}
		else if(pdfColumnsSizeReduction == '5'){
			System.debug(LoggingLevel.DEBUG, '## POSConfiguraiton.setPdfColumnsSideReduction - 5%');
			return this.pdfColumnsSizeReduction = '5';
		}

		// System.debug call for debug log purpose
    	System.debug(LoggingLevel.INFO, '## POSConfiguration.setPdfColumnsSideReduction - End');
    	System.debug(LoggingLevel.ERROR, '## POSConfiguration.setPdfColumnsSideReduction - No valid columns size reduction detected - 100%');
    	return this.pdfColumnsSizeReduction = '100';
    }

    /**
     * <b>Method applyColumnSizeReduction </b>: will reduce the size of the column
     */
    public void applyColumnSizeReduction(){
    	// System.Debug call for debug log purpose
    	System.debug(LoggingLevel.INFO, '## POSConfiguration.applyColumnSizeReduction - Start');

    	// System.Debug call for debug log purpose
    	System.debug(LoggingLevel.DEBUG, '## POSConfiguration.applyColumnSizeReduction - this.pdfColumnsSize : ' + this.pdfColumnsSize);
    	// Going to apply the reduction to the column
    	this.pdfColumnsSize = (integer) (83.0 * Integer.valueOf(this.pdfColumnsSizeReduction) / 100.0);
		// System.Debug call for debug log purpose
    	System.debug(LoggingLevel.DEBUG, '## POSConfiguration.applyColumnSizeReduction - this.pdfColumnsSize : ' + this.pdfColumnsSize);

    	// System.Debug call for debug log purpose
    	System.debug(LoggingLevel.INFO, '## POSConfiguration.applyColumnSizeReduction - End');
    }
}