/**
 * <b>Class POSCell</b>: a cell of the POS Table
 * @author Eric Wartelle
 * @version 1.0
 */
public with sharing class POSCell {
	//Attributs of the POSCell table
	/**
	 * <b>posStatus </b>: storing the status of the corresponding ERO
	 */
	public String posStatus { get; set; }

	/**
	 * <b>posStatusColor </b>: storing the color corresponding of the status for the corresponding ERO
	 */
    public String posStatusColor { get; set; }

    /**
     * <b>posStatusFontColor </b>: Storing the font color corresponding of the status for the corresponding ERO
     */
    public String posStatusFontColor { get; set; }

    /**
     * <b>posFirstReleaseDate </b>: Storing the first release date for the corresponding ERO
     */
    public Date posFirstReleaseDate { get; set; }

    /**
     * <b>order </b>: storing the actual order for the ERO
     */
    public Integer order { get; set; }

    /**
     * <b>isPartial </b>: storing the fact that the current status of the ERO is partial
     */
    public Boolean isPartial { get; set; }

	//Constructors for the POSCell 
	/**
	 * Constructor with 6 arguments
	 * @param posStatus (String) 
	 * @param posStatusColor (String)
	 * @param posStatusFontColor (String)
	 * @param posFirstReleaseDate (Date)
	 * @param order (Integer)
	 * @param isPartial (Boolean)
	 */
	public POSCell(String posStatus, String posStatusColor, String posStatusFontColor,
					Date posFirstReleaseDate, Integer order, Boolean isPartial) {
		this.posStatus = posStatus;
		this.posStatusColor = posStatusColor;
		this.posStatusFontColor = posStatusFontColor;
		this.posFirstReleaseDate = posFirstReleaseDate;
		this.order = order;
		this.isPartial = isPartial;
	}

    /**
	 * Constructor with 6 arguments
	 * @param posStatus (String) 
	 * @param posStatusColor (String)
	 * @param posStatusFontColor (String)
	 */
	public POSCell(String posStatus, String posStatusColor, String posStatusFontColor){
		this(posStatus, posStatusColor, posStatusFontColor, null, 0, false);
	}

    /**
	 * Constructor with 6 arguments
	 * @param posStatus (String) 
	 * @param posStatusColor (String)
	 * @param posStatusFontColor (String)
	 * @param order (Integer)
	 */
	public POSCell(String posStatus, String posStatusColor, String posStatusFontColor, Integer order){
		this(posStatus, posStatusColor, posStatusFontColor, null, order, false);
	}

	/**
	 * Constructor without arguments
	 */
	public POSCell(){

	}

	//Methods for the POSCell
}